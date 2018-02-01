PROC $sc_$cpu_hk_missingdata
;*******************************************************************************
;  Test Name:  hk_missingdata
;  Test Level: Build Verification
;  Test Type:  Functional
;
;  Test Description
;	The purpose of this test is to verify that Housekeeping (HK) correctly
;       handles missing housekeeping packets.  It also tests the collection of 
;       housekeeping data from an average number input message streams (20).  
;       It will also test that HK can combine input message data into an average
;       number of output messages (3).
;
;  Requirements Tested
;       HK2000	 HK shall collect flight software housekeeping data from table
;                -specified input messages
;       HK2001	 HK shall output up to a maximum <Mission-Defined> table-defined
;                messages, at the scheduled rate, by combining input message 
;                data starting at the table-defined offset and table-defined 
;                number of bytes to the table-defined offset in the output
;		 message.
;       HK2001.2 If HK does not receive a message from an application, HK shall
;                use all values associated with last received message for that
;		 application in the combined message for that telemetry 
;		 collection period. 
;       HK2001.3 If HK does not receive a message from an application, HK app
;                shall increment the missing data count and send and event
;		 specifying the message ID for the missing data
;       HK2001.5 If the <PLATFORM_DEFINED> parameter Discard Combo Packets is
;		 set to NO and the input message offset + bytes for any input
;		 message specified in the HK table is greater than the received
;		 message length then HK shall use the last received data
;		 associated with that message and issue no more than one event
;		 per input message.
;       HK2001.6 If the <PLATFORM_DEFINED> parameter Discard Combo Packets is
;		 set to YES and HK does not receive a message from an
;		 application, HK shall discard the combined message containing
;		 the values associated with the missing application message for
;		 that telemetry collection period.
;       HK2001.7 If the <PLATFORM_DEFINED> parameter Discard Combo Packets is
;		 set to YES and the input message offset + bytes for any input
;		 message specified in the HK table is greater than the received
;		 message length then HK shall discard the combined message
;		 containing the values associated with the illegal length
;		 application message for that telemetry collection period.
;       HK3000	 HK shall generate a housekeeping message containing the
;		 following:
;                    a)	Valid Command Counter
;                    b)	Command Rejected Counter
;                    c)	Number of Output Messages Sent
;                    d)	Missing Data Counter
;       HK4000	Upon initialization of the HK Application, HK shall initialize
;               the following data to Zero
;                    a)	Valid Command Counter
;                    b)	Command Rejected Counter
;                    c)	Number of Output Messages Sent
;                    d)	Missing Data Counter
;
;  Prerequisite Conditions
;	The cFE is up and running and ready to accept commands. 
;	The HK commands and TLM items exist in the GSE database. 
;	A display page exists for the HK Housekeeping telemetry packet. 
;	HK Test application loaded and running
;
;  Assumptions and Constraints
;	None.
;
;  Change History
;
;	Date		   Name		Description
;	06/2/08	       Barbie Medina	Original Procedure.
;       06/4/08        Barbie Medina    Removed us to ut_tlmupdate from
;                                       waiting for output packets to update
;       07/02/10        Walt Moleski    Updated to use the default table name
;                                       and to call $sc_$cpu_hk_start_apps
;       03/08/11        Walt Moleski    Added variables for app and table names
;       04/03/12        Walt Moleski    Added Step 4.5 to test the 2.3.0.0 fix
;					of recursive event messages. Replaced
;					ut_tlmupdate with hard waits
;       01/30/14        Walt Moleski    Updated to use raw commands for sending
;                                       input messages rather than TST_HK.
;       11/08/16        Walt Moleski    Updated for HK 2.4.1.0 using CPU1 for
;                                       commanding and added a hostCPU variable
;                                       for the utility procs to connect to the
;                                       proper host IP address.
;       11/09/16        Walt Moleski    Added use of global requirements array
;                                       that was removed previously
;
;  Arguments
;	None.
;
;  Procedures Called
;	Name			Description
;       ut_tlmwait      Wait for a specified telemetry point to update to
;                       a specified value. 
;       ut_sendcmd      Send commands to the spacecraft. Verifies command
;                       processed and command error counters.
;       ut_sendrawcmd   Send raw commands to the spacecraft. Verifies command
;                       processed and command error counters.
;       ut_pfindicate   Print the pass fail status of a particular requirement
;                       number.
;       ut_setupevents  Performs setup to verify that a particular event
;                       message was received by ASIST.
;	ut_setrequirements	A directive to set the status of the cFE
;			requirements array.
;
;  Expected Test Results and Analysis
;
;**********************************************************************
local logging = %liv (log_procedure)    
%liv (log_procedure) = FALSE            

#include "ut_statusdefs.h"
#include "ut_cfe_info.h"
#include "cfe_platform_cfg.h"
#include "cfe_evs_events.h"
#include "cfe_es_events.h"
#include "to_lab_events.h"
#include "hk_platform_cfg.h"
#include "hk_events.h"
#include "tst_hk_events.h"
#include "cfs_hk_requirements.h"

%liv (log_procedure) = logging

;; These are the requirements tested by this procedure
;;#define HK_2000        0
;;#define HK_2001        1
;;#define HK_20012       2
;;#define HK_20013       3
;;#define HK_20015       4
;;#define HK_20016       5
;;#define HK_20017       6
;;#define HK_3000        7
;;#define HK_4000        8

;;global ut_req_array_size = 8
;;global ut_requirement[0 .. ut_req_array_size]

for i = 0 to ut_req_array_size DO
  ut_requirement[i] = "U"
enddo

;; Set 2001.2 to "N" if the DISCARD configuration parameter is set
if (HK_DISCARD_INCOMPLETE_COMBO = 1) then
  ut_requirement[HK_20012] = "N"
else
  ut_requirement[HK_20016] = "N"
  ut_requirement[HK_20017] = "N"
endif

;; Mark the other requirements NOT tested by this procedure
ut_requirement[HK_20011] = "N"

;**********************************************************************
; Set the local values
;**********************************************************************
LOCAL cfe_requirements[0 .. ut_req_array_size] = ["HK_2000","HK_2001", ;;
	"HK_2001.1","HK_2001.2","HK_2001.3","HK_2001.5","HK_2001.6", ;;
	"HK_2001.7","HK_3000","HK_4000"]

;**********************************************************************
; Define local variables
;**********************************************************************
LOCAL rawcmd
LOCAL stream1
LOCAL entry
LOCAL appid
LOCAL OutputPacket1
LOCAL OutputPacket2
LOCAL OutputPacket3
LOCAL OutputPacket4
LOCAL InputPacket1
LOCAL InputPacket2
LOCAL InputPacket3
LOCAL InputPacket4
LOCAL InputPacket5
LOCAL InputPacket6
LOCAL InputPacket7
LOCAL InputPacket8
LOCAL InputPacket9
LOCAL InputPacket10
LOCAL InputPacket11
LOCAL InputPacket12
LOCAL InputPacket13
LOCAL InputPacket14
LOCAL InputPacket15
LOCAL InputPacket16
LOCAL InputPacket17
LOCAL InputPacket18
LOCAL InputPacket19
LOCAL InputPacket20
LOCAL InputPacket21
LOCAL DataBytePattern[0 .. 80]

local HKAppName = "HK"
local HKCopyTblName = HKAppName & "." & HK_COPY_TABLE_NAME
local hostCPU = "$CPU"

write ";*********************************************************************"
write ";  Step 1.0:  Initialize the CPU for this test. "
write ";*********************************************************************"
write ";  Step 1.1:  Command a Power-On Reset on $CPU. "
write ";********************************************************************"
/$SC_$CPU_ES_POWERONRESET
wait 10

close_data_center
wait 60

cfe_startup {hostCPU}
wait 5

;; Display the pages
page $SC_$CPU_HK_HK
page $SC_$CPU_TST_HK_HK
page $SC_$CPU_HK_COMBINED_PKT1
page $SC_$CPU_HK_COMBINED_PKT2
page $SC_$CPU_HK_COMBINED_PKT3
page $SC_$CPU_HK_COMBINED_PKT4

write ";*********************************************************************"
write ";  Step 1.2: Creating the copy table used for testing and upload it"
write ";********************************************************************"
s $SC_$CPU_hk_copytable1
;; Parse the filename configuration parameters for the default table filenames
local tableFileName = HK_COPY_TABLE_FILENAME
local slashLoc = %locate(tableFileName,"/")

;; loop until all slashes are found for the Destination File Table Name
while (slashLoc <> 0) do
  tableFileName = %substring(tableFileName,slashLoc+1,%length(tableFileName))
  slashLoc = %locate(tableFileName,"/")
enddo

write "==> Default Copy Table filename = '",tableFileName,"'"

s ftp_file("CF:0/apps", "hk_cpy_tbl.tbl", tableFileName, hostCPU, "P")

write ";*********************************************************************"
write ";  Step 1.3:  Start the Housekeeping (HK) and Test Applications. "
write ";********************************************************************"
s $sc_$cpu_hk_start_apps("1.3")
wait 5

write ";*********************************************************************"
write ";  Step 1.4: Verify that the HK Housekeeping telemetry items are "
write ";  initialized to zero (0). "
write ";*********************************************************************"
;; Check the HK tlm items to see if they are 0 or NULL
;; the TST_HK application sends its HK packet
if ($SC_$CPU_HK_CMDPC = 0) AND ($SC_$CPU_HK_CMDEC = 0) AND ;;
   ($SC_$CPU_HK_CMBPKTSSENT = 0) AND ($SC_$CPU_HK_MISSDATACTR = 0) THEN
  write "<*> Passed (9000) - Housekeeping telemetry initialized properly."
  ut_setrequirements HK_4000, "P"
else
  write "<!> Failed (4000) - Housekeeping telemetry NOT initialized at startup."
  write "  CMDPC                    = ",$SC_$CPU_HK_CMDPC
  write "  CMDEC                    = ",$SC_$CPU_HK_CMDEC
  write "  Combined Packets Sent    = ",$SC_$CPU_HK_CMBPKTSSENT
  write "  Missing Data Counter     = ",$SC_$CPU_HK_MISSDATACTR
  write "  Memory Pool Handle       = ",$SC_$CPU_HK_MEMPOOLHNDL
  ut_setrequirements HK_4000, "F"
endif

wait 5

write ";*********************************************************************"
write ";  Step 1.5: Enable DEBUG Event Messages "
write ";*********************************************************************"
local cmdCtr = $SC_$CPU_EVS_CMDPC + 1

;; Enable DEBUG events for the HK application ONLY
/$SC_$CPU_EVS_EnaAppEVTType Application=HKAppName DEBUG

ut_tlmwait $SC_$CPU_EVS_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Enable Debug events command sent properly."
else
  write "<!> Failed - Enable Debug events command."
endif

write ";*********************************************************************"
write ";  Step 2.0: Basic housekeeping collection and output message sending."
write ";*********************************************************************"
write ";  Step 2.1: Send 20 input messages as per the copy table."
write ";*********************************************************************"
;; CPU1 is the default
appid = 0xfa6
OutputPacket1 = 0x89c  
OutputPacket2 = 0x89d
OutputPacket3 = 0x89e
;; Use CPU2 IDs
InputPacket1 = 0x987
InputPacket2 = 0x988
InputPacket3 = 0x989
InputPacket4 = 0x98a
InputPacket5 = 0x98b
InputPacket6 = 0x98c
InputPacket7 = 0x98d
InputPacket8 = 0x98e
InputPacket9 = 0x98f
InputPacket10 = 0x990
InputPacket11 = 0x991
InputPacket12 = 0x992
InputPacket13 = 0x993
InputPacket14 = 0x994
InputPacket15 = 0x995
InputPacket16 = 0x996
InputPacket17 = 0x997
InputPacket18 = 0x998
InputPacket19 = 0x999
InputPacket20 = 0x99a

if ("$CPU" = "CPU2") then
   appid = 0xfc4
   OutputPacket1 = 0x99c  
   OutputPacket2 = 0x99d
   OutputPacket3 = 0x99e
   ;; Use CPU3 IDs
   InputPacket1 = 0xa87
   InputPacket2 = 0xa88
   InputPacket3 = 0xa89
   InputPacket4 = 0xa8a
   InputPacket5 = 0xa8b
   InputPacket6 = 0xa8c
   InputPacket7 = 0xa8d
   InputPacket8 = 0xa8e
   InputPacket9 = 0xa8f
   InputPacket10 = 0xa90
   InputPacket11 = 0xa91
   InputPacket12 = 0xa92
   InputPacket13 = 0xa93
   InputPacket14 = 0xa94
   InputPacket15 = 0xa95
   InputPacket16 = 0xa96
   InputPacket17 = 0xa97
   InputPacket18 = 0xa98
   InputPacket19 = 0xa99
   InputPacket20 = 0xa9a
elseif ("$CPU" = "CPU3") then
   appid = 0xfe4
   OutputPacket1 = 0xa9c  
   OutputPacket2 = 0xa9d
   OutputPacket3 = 0xa9e
   ;; Use CPU1 IDs
   InputPacket1 = 0x887
   InputPacket2 = 0x888
   InputPacket3 = 0x889
   InputPacket4 = 0x88a
   InputPacket5 = 0x88b
   InputPacket6 = 0x88c
   InputPacket7 = 0x88d
   InputPacket8 = 0x88e
   InputPacket9 = 0x88f
   InputPacket10 = 0x890
   InputPacket11 = 0x891
   InputPacket12 = 0x892
   InputPacket13 = 0x893
   InputPacket14 = 0x894
   InputPacket15 = 0x895
   InputPacket16 = 0x896
   InputPacket17 = 0x897
   InputPacket18 = 0x898
   InputPacket19 = 0x899
   InputPacket20 = 0x89a
endif 

/$SC_$CPU_TO_ADDPACKET Stream=OutputPacket1 Pkt_Size=x'0' Priority=x'0' Reliability=x'1' Buflimit=x'4'
/$SC_$CPU_TO_ADDPACKET Stream=OutputPacket2 Pkt_Size=x'0' Priority=x'0' Reliability=x'1' Buflimit=x'4'
/$SC_$CPU_TO_ADDPACKET Stream=OutputPacket3 Pkt_Size=x'0' Priority=x'0' Reliability=x'1' Buflimit=x'4'

local size, pktLen

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket1 DataSize=4 DataPattern =0x01234567
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket1,4) & "C000" & %hex(pktLen,4) & "00000000000001234567"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket2 DataSize=8 DataPattern =0x12345678
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket2,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "12345678"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket3 DataSize=16 DataPattern =0x23456789
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket3,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "23456789"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket4 DataSize=32 DataPattern =0x3456789a
;;wait 2
size = 32
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket4,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "3456789a"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket5 DataSize=32 DataPattern =0x456789ab
;;wait 2
rawCmd = %hex(InputPacket5,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "456789ab"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket6 DataSize=16 DataPattern =0x56789abc
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket6,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "56789abc"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket7 DataSize=8 DataPattern =0x6789abcd
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket7,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "6789abcd"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket8 DataSize=4 DataPattern =0x789abcde
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket8,4) & "C000" & %hex(pktLen,4) & "000000000000789abcde"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket9 DataSize=4 DataPattern =0x89abcdef
;;wait 2
rawCmd = %hex(InputPacket9,4) & "C000" & %hex(pktLen,4) & "00000000000089abcdef"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket10 DataSize=8 DataPattern =0x9abcdef0
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket10,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "9abcdef0"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket11 DataSize=8 DataPattern =0xabcdef01
;;wait 2
rawCmd = %hex(InputPacket11,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "abcdef01"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket12 DataSize=4 DataPattern =0xbcdef012
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket12,4) & "C000" & %hex(pktLen,4) & "000000000000bcdef012"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket13 DataSize=4 DataPattern =0xcdef0123
;;wait 2
rawCmd = %hex(InputPacket13,4) & "C000" & %hex(pktLen,4) & "000000000000cdef0123"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket14 DataSize=8 DataPattern =0xdef01234
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket14,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "def01234"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket15 DataSize=16 DataPattern =0xef012345
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket15,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "ef012345"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket16 DataSize=32 DataPattern =0xf0123456
;;wait 2
size = 32
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket16,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "f0123456"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket17 DataSize=32 DataPattern =0x76543210
;;wait 2
rawCmd = %hex(InputPacket17,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "76543210"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket18 DataSize=16 DataPattern =0x87654321
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket18,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "87654321"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket19 DataSize=8 DataPattern =0x98765432
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket19,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "98765432"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket20 DataSize=4 DataPattern =0xa9876543
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket20,4) & "C000" & %hex(pktLen,4) & "000000000000a9876543"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

write ";*********************************************************************"
write ";  Step 2.2: Send Output Message 1 command and check data"
write ";*********************************************************************"
;;setup data expected packet byte data pattern
DataBytePattern[0] = 0x01
DataBytePattern[1] = 0x23 
DataBytePattern[2] = 0x45
DataBytePattern[3] = 0x67 
DataBytePattern[4] = 0x12
DataBytePattern[5] = 0x34 
DataBytePattern[6] = 0x56
DataBytePattern[7] = 0x78 
DataBytePattern[8] = 0x23
DataBytePattern[9] = 0x45 
DataBytePattern[10] = 0x67
DataBytePattern[11] = 0x89 
DataBytePattern[12] = 0x34
DataBytePattern[13] = 0x56 
DataBytePattern[14] = 0x78
DataBytePattern[15] = 0x9a 
DataBytePattern[16] = 0x45
DataBytePattern[17] = 0x67 
DataBytePattern[18] = 0x89
DataBytePattern[19] = 0xab 
DataBytePattern[20] = 0x56
DataBytePattern[21] = 0x78 
DataBytePattern[22] = 0x9a
DataBytePattern[23] = 0xbc 
DataBytePattern[24] = 0x67
DataBytePattern[25] = 0x89 
DataBytePattern[26] = 0xab
DataBytePattern[27] = 0xcd 
DataBytePattern[28] = 0x78
DataBytePattern[29] = 0x9a 
DataBytePattern[30] = 0xbc
DataBytePattern[31] = 0xde 
DataBytePattern[32] = 0x89
DataBytePattern[33] = 0xab 
DataBytePattern[34] = 0xcd
DataBytePattern[35] = 0xef 
DataBytePattern[36] = 0x9a
DataBytePattern[37] = 0xbc 
DataBytePattern[38] = 0xde
DataBytePattern[39] = 0xf0 
DataBytePattern[40] = 0xab
DataBytePattern[41] = 0xcd 
DataBytePattern[42] = 0xef
DataBytePattern[43] = 0x01 
DataBytePattern[44] = 0xbc
DataBytePattern[45] = 0xde 
DataBytePattern[46] = 0xf0
DataBytePattern[47] = 0x12 
DataBytePattern[48] = 0xcd
DataBytePattern[49] = 0xef 
DataBytePattern[50] = 0x01
DataBytePattern[51] = 0x23 
DataBytePattern[52] = 0xde
DataBytePattern[53] = 0xf0 
DataBytePattern[54] = 0x12
DataBytePattern[55] = 0x34 
DataBytePattern[56] = 0xef
DataBytePattern[57] = 0x01 
DataBytePattern[58] = 0x23
DataBytePattern[59] = 0x45 
DataBytePattern[60] = 0xf0
DataBytePattern[61] = 0x12 
DataBytePattern[62] = 0x34
DataBytePattern[63] = 0x56 
DataBytePattern[64] = 0x76
DataBytePattern[65] = 0x54 
DataBytePattern[66] = 0x32
DataBytePattern[67] = 0x10 
DataBytePattern[68] = 0x87
DataBytePattern[69] = 0x65 
DataBytePattern[70] = 0x43
DataBytePattern[71] = 0x21 
DataBytePattern[72] = 0x98
DataBytePattern[73] = 0x76 
DataBytePattern[74] = 0x54
DataBytePattern[75] = 0x32 
DataBytePattern[76] = 0xa9
DataBytePattern[77] = 0x87 
DataBytePattern[78] = 0x65
DataBytePattern[79] = 0x43

s $SC_$CPU_hk_sendoutmsg(OutputPacket1, DataBytePattern, Pkt1, NoChecks, 0)

write ";*********************************************************************"
write ";  Step 2.3: Send Output Message 2 command and check data"
write ";*********************************************************************"
;;setup data expected packet byte data pattern
DataBytePattern[0] = 0x65
DataBytePattern[1] = 0x43 
DataBytePattern[2] = 0x54
DataBytePattern[3] = 0x32 
DataBytePattern[4] = 0x43
DataBytePattern[5] = 0x21 
DataBytePattern[6] = 0x32
DataBytePattern[7] = 0x10
DataBytePattern[8] = 0x12
DataBytePattern[9] = 0x34 
DataBytePattern[10] = 0x01
DataBytePattern[11] = 0x23 
DataBytePattern[12] = 0xf0
DataBytePattern[13] = 0x12 
DataBytePattern[14] = 0xef
DataBytePattern[15] = 0x01 
DataBytePattern[16] = 0xf0
DataBytePattern[17] = 0x12 
DataBytePattern[18] = 0xef
DataBytePattern[19] = 0x01 
DataBytePattern[20] = 0xbc
DataBytePattern[21] = 0xde 
DataBytePattern[22] = 0xab
DataBytePattern[23] = 0xcd 
DataBytePattern[24] = 0xbc
DataBytePattern[25] = 0xde 
DataBytePattern[26] = 0xab
DataBytePattern[27] = 0xcd 
DataBytePattern[28] = 0x9a
DataBytePattern[29] = 0xbc 
DataBytePattern[30] = 0x89
DataBytePattern[31] = 0xab 
DataBytePattern[32] = 0x56
DataBytePattern[33] = 0x78 
DataBytePattern[34] = 0x45
DataBytePattern[35] = 0x67 
DataBytePattern[36] = 0x34
DataBytePattern[37] = 0x56 
DataBytePattern[38] = 0x23
DataBytePattern[39] = 0x45

for entry = 40 to 80 do
   DataBytePattern[entry] = 0	
enddo

s $SC_$CPU_hk_sendoutmsg(OutputPacket2, DataBytePattern, Pkt2, NoChecks, 0)

write ";*********************************************************************"
write ";  Step 2.4: Send Output Message 3 command and check data"
write ";*********************************************************************"
;;setup data expected packet byte data pattern
DataBytePattern[0] = 0xf0
DataBytePattern[1] = 0x01 
DataBytePattern[2] = 0xef
DataBytePattern[3] = 0x12 
DataBytePattern[4] = 0xde
DataBytePattern[5] = 0x23 
DataBytePattern[6] = 0xcd
DataBytePattern[7] = 0x34 
DataBytePattern[8] = 0xbc
DataBytePattern[9] = 0x45 
DataBytePattern[10] = 0xab
DataBytePattern[11] = 0x56 
DataBytePattern[12] = 0x9a
DataBytePattern[13] = 0x10 
DataBytePattern[14] = 0x89
DataBytePattern[15] = 0x21 
DataBytePattern[16] = 0x78
DataBytePattern[17] = 0x32 
DataBytePattern[18] = 0x67
DataBytePattern[19] = 0x43

for entry = 20 to 80 do
   DataBytePattern[entry] = 0	
enddo

s $SC_$CPU_hk_sendoutmsg(OutputPacket3, DataBytePattern, Pkt3, NoChecks, 0)

write ";*********************************************************************"
write ";  Step 3.0: Turn off 1 input packet."
write ";*********************************************************************"
write ";  Step 3.1: Send 19 input messages as per the copy table."
write ";*********************************************************************"

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket1 DataSize=4 DataPattern =0xa9876543
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket1,4) & "C000" & %hex(pktLen,4) & "000000000000a9876543"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket2 DataSize=8 DataPattern =0x98765432
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket2,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "98765432"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket3 DataSize=16 DataPattern =0x87654321
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket3,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "87654321"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket4 DataSize=32 DataPattern =0x76543210
;;wait 2
size = 32
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket4,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "76543210"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket5 DataSize=32 DataPattern =0xf0123456
;;wait 2
rawCmd = %hex(InputPacket5,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "f0123456"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket6 DataSize=16 DataPattern =0xef012345
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket6,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "ef012345"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket7 DataSize=8 DataPattern =0xdef01234
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket7,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "def01234"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket8 DataSize=4 DataPattern =0xcdef0123
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket8,4) & "C000" & %hex(pktLen,4) & "000000000000cdef0123"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket9 DataSize=4 DataPattern =0xbcdef012
;;wait 2
rawCmd = %hex(InputPacket9,4) & "C000" & %hex(pktLen,4) & "000000000000bcdef012"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket10 DataSize=8 DataPattern =0xabcdef01
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket10,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "abcdef01"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

write ";*********************************************************************"
write ";  Don't send InputPacket11 so there will be missing data"
write ";*********************************************************************"

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket12 DataSize=4 DataPattern =0x89abcdef
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket12,4) & "C000" & %hex(pktLen,4) & "00000000000089abcdef"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket13 DataSize=4 DataPattern =0x789abcde
;;wait 2
rawCmd = %hex(InputPacket13,4) & "C000" & %hex(pktLen,4) & "000000000000789abcde"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket14 DataSize=8 DataPattern =0x6789abcd
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket14,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "6789abcd"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket15 DataSize=16 DataPattern =0x56789abc
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket15,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "56789abc"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket16 DataSize=32 DataPattern =0x456789ab
;;wait 2
size = 32
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket16,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "456789ab"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket17 DataSize=32 DataPattern =0x3456789a
;;wait 2
rawCmd = %hex(InputPacket17,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "3456789a"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket18 DataSize=16 DataPattern =0x23456789
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket18,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "23456789"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket19 DataSize=8 DataPattern =0x12345678
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket19,4) & "C000" & %hex(pktLen,4) & "000000000000"
for i = 1 to size/4 do
  rawCmd = rawCmd & "12345678"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket20 DataSize=4 DataPattern =0x01234567
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket20,4) & "C000" & %hex(pktLen,4) & "00000000000001234567"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

write ";*********************************************************************"
write ";  Step 3.2: Send Output Message 1 command."
write ";*********************************************************************"
;;setup data expected packet byte data pattern
DataBytePattern[0] = 0xa9
DataBytePattern[1] = 0x87 
DataBytePattern[2] = 0x65
DataBytePattern[3] = 0x43 
DataBytePattern[4] = 0x98
DataBytePattern[5] = 0x76 
DataBytePattern[6] = 0x54
DataBytePattern[7] = 0x32 
DataBytePattern[8] = 0x87
DataBytePattern[9] = 0x65
DataBytePattern[10] = 0x43
DataBytePattern[11] = 0x21 
DataBytePattern[12] = 0x76
DataBytePattern[13] = 0x54 
DataBytePattern[14] = 0x32
DataBytePattern[15] = 0x10 
DataBytePattern[16] = 0xf0
DataBytePattern[17] = 0x12 
DataBytePattern[18] = 0x34
DataBytePattern[19] = 0x56 
DataBytePattern[20] = 0xef
DataBytePattern[21] = 0x01 
DataBytePattern[22] = 0x23
DataBytePattern[23] = 0x45
DataBytePattern[24] = 0xde
DataBytePattern[25] = 0xf0 
DataBytePattern[26] = 0x12
DataBytePattern[27] = 0x34 
DataBytePattern[28] = 0xcd
DataBytePattern[29] = 0xef 
DataBytePattern[30] = 0x01
DataBytePattern[31] = 0x23 
DataBytePattern[32] = 0xbc
DataBytePattern[33] = 0xde 
DataBytePattern[34] = 0xf0
DataBytePattern[35] = 0x12 
DataBytePattern[36] = 0xab
DataBytePattern[37] = 0xcd 
DataBytePattern[38] = 0xef
DataBytePattern[39] = 0x01  
DataBytePattern[40] = 0xab
DataBytePattern[41] = 0xcd 
DataBytePattern[42] = 0xef
DataBytePattern[43] = 0x01  
DataBytePattern[44] = 0x89
DataBytePattern[45] = 0xab 
DataBytePattern[46] = 0xcd
DataBytePattern[47] = 0xef 
DataBytePattern[48] = 0x78
DataBytePattern[49] = 0x9a 
DataBytePattern[50] = 0xbc
DataBytePattern[51] = 0xde 
DataBytePattern[52] = 0x67
DataBytePattern[53] = 0x89 
DataBytePattern[54] = 0xab
DataBytePattern[55] = 0xcd 
DataBytePattern[56] = 0x56
DataBytePattern[57] = 0x78 
DataBytePattern[58] = 0x9a
DataBytePattern[59] = 0xbc 
DataBytePattern[60] = 0x45
DataBytePattern[61] = 0x67 
DataBytePattern[62] = 0x89
DataBytePattern[63] = 0xab 
DataBytePattern[64] = 0x34
DataBytePattern[65] = 0x56 
DataBytePattern[66] = 0x78
DataBytePattern[67] = 0x9a 
DataBytePattern[68] = 0x23
DataBytePattern[69] = 0x45 
DataBytePattern[70] = 0x67
DataBytePattern[71] = 0x89 
DataBytePattern[72] = 0x12
DataBytePattern[73] = 0x34 
DataBytePattern[74] = 0x56
DataBytePattern[75] = 0x78 
DataBytePattern[76] = 0x01
DataBytePattern[77] = 0x23 
DataBytePattern[78] = 0x45
DataBytePattern[79] = 0x67

s $SC_$CPU_hk_sendoutmsg(OutputPacket1, DataBytePattern, Pkt1, MissingYes, 40)

write ";*********************************************************************"
write ";  Step 3.3: Send Output Message 2 command."
write ";*********************************************************************"
;;setup data expected packet byte data pattern
DataBytePattern[0] = 0x45
DataBytePattern[1] = 0x67 
DataBytePattern[2] = 0x56
DataBytePattern[3] = 0x78 
DataBytePattern[4] = 0x67
DataBytePattern[5] = 0x89 
DataBytePattern[6] = 0x78
DataBytePattern[7] = 0x9a 
DataBytePattern[8] = 0x67
DataBytePattern[9] = 0x89 
DataBytePattern[10] = 0x78
DataBytePattern[11] = 0x9a 
DataBytePattern[12] = 0x89
DataBytePattern[13] = 0xab 
DataBytePattern[14] = 0x9a
DataBytePattern[15] = 0xbc 
DataBytePattern[16] = 0xcd
DataBytePattern[17] = 0xef 
DataBytePattern[18] = 0xef
DataBytePattern[19] = 0x01
DataBytePattern[20] = 0xcd
DataBytePattern[21] = 0xef 
DataBytePattern[22] = 0xde
DataBytePattern[23] = 0xf0 
DataBytePattern[24] = 0x01
DataBytePattern[25] = 0x23 
DataBytePattern[26] = 0x12
DataBytePattern[27] = 0x34 
DataBytePattern[28] = 0x23
DataBytePattern[29] = 0x45 
DataBytePattern[30] = 0x34
DataBytePattern[31] = 0x56 
DataBytePattern[32] = 0x54
DataBytePattern[33] = 0x32 
DataBytePattern[34] = 0x65
DataBytePattern[35] = 0x43 
DataBytePattern[36] = 0x76
DataBytePattern[37] = 0x54 
DataBytePattern[38] = 0x87
DataBytePattern[39] = 0x65

for entry = 40 to 80 do
   DataBytePattern[entry] = 0	
enddo							

s $SC_$CPU_hk_sendoutmsg(OutputPacket2, DataBytePattern, Pkt2, MissingYes, 18)

write ";*********************************************************************"
write ";  Step 3.4: Send Output Message 3 command."
write ";********************************************************************"
;;setup data expected packet byte data pattern
DataBytePattern[0] = 0x01
DataBytePattern[1] = 0x01 
DataBytePattern[2] = 0x12
DataBytePattern[3] = 0xef 
DataBytePattern[4] = 0x23
DataBytePattern[5] = 0xde 
DataBytePattern[6] = 0x34
DataBytePattern[7] = 0xcd
DataBytePattern[8] = 0x45
DataBytePattern[9] = 0xbc 
DataBytePattern[10] = 0x56
DataBytePattern[11] = 0xab 
DataBytePattern[12] = 0x10
DataBytePattern[13] = 0x9a 
DataBytePattern[14] = 0x21
DataBytePattern[15] = 0x89 
DataBytePattern[16] = 0x32
DataBytePattern[17] = 0x78 
DataBytePattern[18] = 0x43
DataBytePattern[19] = 0x67

for entry = 20 to 80 do
   DataBytePattern[entry] = 0	
enddo

s $SC_$CPU_hk_sendoutmsg(OutputPacket3, DataBytePattern, Pkt3, MissingYes, 1)

write ";*********************************************************************"
write ";  Step 4.0: Turn all input packets back on."
write ";*********************************************************************"
write ";  Step 4.1: Send 20 input messages as per the copy table."
write ";*********************************************************************"

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket1 DataSize=4 DataPattern =0x11111111
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket1,4) & "C000" & %hex(pktLen,4) & "00000000000011111111"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket2 DataSize=8 DataPattern =0x12121212
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket2,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "12121212"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket3 DataSize=16 DataPattern =0x13131313
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket3,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "13131313"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket4 DataSize=32 DataPattern =0x14141414
;;wait 2
size = 32
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket4,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "14141414"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket5 DataSize=32 DataPattern =0x15151515
;;wait 2
rawCmd = %hex(InputPacket5,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "15151515"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket6 DataSize=16 DataPattern =0x16161616
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket6,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "16161616"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket7 DataSize=8 DataPattern =0x17171717
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket7,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "17171717"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket8 DataSize=4 DataPattern =0x18181818
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket8,4) & "C000" & %hex(pktLen,4) & "00000000000018181818"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket9 DataSize=4 DataPattern =0x19191919
;;wait 2
rawCmd = %hex(InputPacket9,4) & "C000" & %hex(pktLen,4) & "00000000000019191919"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket10 DataSize=8 DataPattern =0x1a1a1a1a
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket10,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "1a1a1a1a"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket11 DataSize=8 DataPattern =0x1b1b1b1b
;;wait 2
rawCmd = %hex(InputPacket11,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "1b1b1b1b"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket12 DataSize=4 DataPattern =0x1c1c1c1c
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket12,4) & "C000" & %hex(pktLen,4) & "0000000000001c1c1c1c"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket13 DataSize=4 DataPattern =0x1d1d1d1d
;;wait 2
rawCmd = %hex(InputPacket13,4) & "C000" & %hex(pktLen,4) & "0000000000001d1d1d1d"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket14 DataSize=8 DataPattern =0x1e1e1e1e
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket14,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "1e1e1e1e"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket15 DataSize=16 DataPattern =0x1f1f1f1f
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket15,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "1f1f1f1f"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket16 DataSize=32 DataPattern =0x20202020
;;wait 2
size = 32
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket16,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "20202020"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket17 DataSize=32 DataPattern =0x21212121
;;wait 2
rawCmd = %hex(InputPacket17,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "21212121"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket18 DataSize=16 DataPattern =0x22222222
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket18,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "22222222"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket19 DataSize=8 DataPattern =0x23232323
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket19,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "23232323"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket20 DataSize=4 DataPattern =0x24242424
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket20,4) & "C000" & %hex(pktLen,4) & "00000000000024242424"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

write ";*********************************************************************"
write ";  Step 4.2: Send Output Message 1 command and check data"
write ";*********************************************************************"
;;setup data expected packet byte data pattern
DataBytePattern[0] = 0x11
DataBytePattern[1] = 0x11 
DataBytePattern[2] = 0x11
DataBytePattern[3] = 0x11 
DataBytePattern[4] = 0x12
DataBytePattern[5] = 0x12 
DataBytePattern[6] = 0x12
DataBytePattern[7] = 0x12 
DataBytePattern[8] = 0x13
DataBytePattern[9] = 0x13 
DataBytePattern[10] = 0x13
DataBytePattern[11] = 0x13 
DataBytePattern[12] = 0x14
DataBytePattern[13] = 0x14 
DataBytePattern[14] = 0x14
DataBytePattern[15] = 0x14 
DataBytePattern[16] = 0x15
DataBytePattern[17] = 0x15 
DataBytePattern[18] = 0x15
DataBytePattern[19] = 0x15 
DataBytePattern[20] = 0x16
DataBytePattern[21] = 0x16 
DataBytePattern[22] = 0x16
DataBytePattern[23] = 0x16 
DataBytePattern[24] = 0x17
DataBytePattern[25] = 0x17 
DataBytePattern[26] = 0x17
DataBytePattern[27] = 0x17 
DataBytePattern[28] = 0x18
DataBytePattern[29] = 0x18 
DataBytePattern[30] = 0x18
DataBytePattern[31] = 0x18 
DataBytePattern[32] = 0x19
DataBytePattern[33] = 0x19 
DataBytePattern[34] = 0x19
DataBytePattern[35] = 0x19 
DataBytePattern[36] = 0x1a
DataBytePattern[37] = 0x1a 
DataBytePattern[38] = 0x1a
DataBytePattern[39] = 0x1a 
DataBytePattern[40] = 0x1b
DataBytePattern[41] = 0x1b
DataBytePattern[42] = 0x1b
DataBytePattern[43] = 0x1b 
DataBytePattern[44] = 0x1c
DataBytePattern[45] = 0x1c 
DataBytePattern[46] = 0x1c
DataBytePattern[47] = 0x1c 
DataBytePattern[48] = 0x1d
DataBytePattern[49] = 0x1d 
DataBytePattern[50] = 0x1d
DataBytePattern[51] = 0x1d 
DataBytePattern[52] = 0x1e
DataBytePattern[53] = 0x1e
DataBytePattern[54] = 0x1e
DataBytePattern[55] = 0x1e 
DataBytePattern[56] = 0x1f
DataBytePattern[57] = 0x1f
DataBytePattern[58] = 0x1f
DataBytePattern[59] = 0x1f  
DataBytePattern[60] = 0x20
DataBytePattern[61] = 0x20 
DataBytePattern[62] = 0x20
DataBytePattern[63] = 0x20 
DataBytePattern[64] = 0x21
DataBytePattern[65] = 0x21 
DataBytePattern[66] = 0x21
DataBytePattern[67] = 0x21 
DataBytePattern[68] = 0x22
DataBytePattern[69] = 0x22 
DataBytePattern[70] = 0x22
DataBytePattern[71] = 0x22
DataBytePattern[72] = 0x23
DataBytePattern[73] = 0x23 
DataBytePattern[74] = 0x23
DataBytePattern[75] = 0x23 
DataBytePattern[76] = 0x24
DataBytePattern[77] = 0x24 
DataBytePattern[78] = 0x24
DataBytePattern[79] = 0x24															
s $SC_$CPU_hk_sendoutmsg(OutputPacket1, DataBytePattern, Pkt1, NoChecks, 0)

write ";*********************************************************************"
write ";  Step 4.3: Send Output Message 2 command and check data"
write ";*********************************************************************"
;;setup data expected packet byte data pattern
DataBytePattern[0] = 0x24
DataBytePattern[1] = 0x24 
DataBytePattern[2] = 0x23
DataBytePattern[3] = 0x23 
DataBytePattern[4] = 0x22
DataBytePattern[5] = 0x22 
DataBytePattern[6] = 0x21
DataBytePattern[7] = 0x21 
DataBytePattern[8] = 0x20
DataBytePattern[9] = 0x20 
DataBytePattern[10] = 0x1f
DataBytePattern[11] = 0x1f 
DataBytePattern[12] = 0x1e
DataBytePattern[13] = 0x1e 
DataBytePattern[14] = 0x1d
DataBytePattern[15] = 0x1d 
DataBytePattern[16] = 0x1c
DataBytePattern[17] = 0x1c 
DataBytePattern[18] = 0x1b
DataBytePattern[19] = 0x1b 
DataBytePattern[20] = 0x1a
DataBytePattern[21] = 0x1a 
DataBytePattern[22] = 0x19
DataBytePattern[23] = 0x19 
DataBytePattern[24] = 0x18
DataBytePattern[25] = 0x18 
DataBytePattern[26] = 0x17
DataBytePattern[27] = 0x17 
DataBytePattern[28] = 0x16
DataBytePattern[29] = 0x16 
DataBytePattern[30] = 0x15
DataBytePattern[31] = 0x15 
DataBytePattern[32] = 0x14
DataBytePattern[33] = 0x14 
DataBytePattern[34] = 0x13
DataBytePattern[35] = 0x13 
DataBytePattern[36] = 0x12
DataBytePattern[37] = 0x12 
DataBytePattern[38] = 0x11
DataBytePattern[39] = 0x11

for entry = 40 to 80 do
   DataBytePattern[entry] = 0	
enddo

s $SC_$CPU_hk_sendoutmsg(OutputPacket2, DataBytePattern, Pkt2, NoChecks, 0)

write ";*********************************************************************"
write ";  Step 4.4: Send Output Message 3 command and check data"
write ";*********************************************************************"
;;setup data expected packet byte data pattern
DataBytePattern[0] = 0x1a
DataBytePattern[1] = 0x1b 
DataBytePattern[2] = 0x19
DataBytePattern[3] = 0x1c 
DataBytePattern[4] = 0x18
DataBytePattern[5] = 0x1d 
DataBytePattern[6] = 0x17
DataBytePattern[7] = 0x1e 
DataBytePattern[8] = 0x16
DataBytePattern[9] = 0x1f 
DataBytePattern[10] = 0x15
DataBytePattern[11] = 0x20 
DataBytePattern[12] = 0x14
DataBytePattern[13] = 0x21 
DataBytePattern[14] = 0x13
DataBytePattern[15] = 0x22 
DataBytePattern[16] = 0x12
DataBytePattern[17] = 0x23 
DataBytePattern[18] = 0x11
DataBytePattern[19] = 0x24

for entry = 20 to 80 do
   DataBytePattern[entry] = 0	
enddo

s $SC_$CPU_hk_sendoutmsg(OutputPacket3, DataBytePattern, Pkt3, NoChecks, 0)

write ";*********************************************************************"
write ";  Step 4.5: Send Input packets that do not contain all their expected"
write ";  data. I.E., the packets will be short and generate an event message."
write ";*********************************************************************"
ut_setupevents "$SC","$CPU",{HKAppName},HK_ACCESSING_PAST_PACKET_END_EID,"ERROR", 1

;; Ensure that 1 event message per MsgID is generated
;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket2 DataSize=4 DataPattern =0x12121212
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket2,4) & "C000" & %hex(pktLen,4) & "00000000000012121212"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket3 DataSize=4 DataPattern =0x13131313
rawCmd = %hex(InputPacket3,4) & "C000" & %hex(pktLen,4) & "00000000000013131313"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket4 DataSize=4 DataPattern =0x14141414
rawCmd = %hex(InputPacket4,4) & "C000" & %hex(pktLen,4) & "00000000000014141414"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket5 DataSize=4 DataPattern =0x15151515
rawCmd = %hex(InputPacket5,4) & "C000" & %hex(pktLen,4) & "00000000000015151515"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket6 DataSize=4 DataPattern =0x16161616
rawCmd = %hex(InputPacket6,4) & "C000" & %hex(pktLen,4) & "00000000000016161616"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket7 DataSize=4 DataPattern =0x17171717
rawCmd = %hex(InputPacket7,4) & "C000" & %hex(pktLen,4) & "00000000000017171717"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket10 DataSize=4 DataPattern =0x1a1a1a1a
rawCmd = %hex(InputPacket10,4) & "C000" & %hex(pktLen,4) & "0000000000001a1a1a1a"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket11 DataSize=4 DataPattern =0x1b1b1b1b
rawCmd = %hex(InputPacket11,4) & "C000" & %hex(pktLen,4) & "0000000000001b1b1b1b"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket14 DataSize=4 DataPattern =0x1e1e1e1e
rawCmd = %hex(InputPacket14,4) & "C000" & %hex(pktLen,4) & "0000000000001e1e1e1e"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket15 DataSize=4 DataPattern =0x1f1f1f1f
rawCmd = %hex(InputPacket15,4) & "C000" & %hex(pktLen,4) & "0000000000001f1f1f1f"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket16 DataSize=4 DataPattern =0x20202020
rawCmd = %hex(InputPacket16,4) & "C000" & %hex(pktLen,4) & "00000000000020202020"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket17 DataSize=4 DataPattern =0x21212121
rawCmd = %hex(InputPacket17,4) & "C000" & %hex(pktLen,4) & "00000000000021212121"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket18 DataSize=4 DataPattern =0x22222222
rawCmd = %hex(InputPacket18,4) & "C000" & %hex(pktLen,4) & "00000000000022222222"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket19 DataSize=4 DataPattern =0x23232323
rawCmd = %hex(InputPacket19,4) & "C000" & %hex(pktLen,4) & "00000000000023232323"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;; This tests 2001.5
;; Check to see if the correct error events were rcv'd
ut_tlmwait $SC_$CPU_find_event[1].num_found_messages, 14
if (UT_TW_Status = UT_Success) then
  write "<*> Passed (2001.5) - Rcv'd the expected error events for short packets"
  ut_setrequirements HK_20015, "P"
else
  write "<!> Failed (2001.5) - Did not rcv the expected error events for short packets. Expected 14; Got ",$SC_$CPU_find_event[1].num_found_messages
  ut_setrequirements HK_20015, "F"
endif

if (HK_DISCARD_INCOMPLETE_COMBO = 1) then
  local currentCnt = $SC_$CPU_HK_CMBPKTSSENT
  s $SC_$CPU_hk_sendoutmsg(OutputPacket1, DataBytePattern, Pkt1, MissingYes, 40)

  if (currentCnt = $SC_$CPU_HK_CMBPKTSSENT) then
    write "<*> Passed (2001.7) - Combined Packet Sent Counter did not increment"
    ut_setrequirements HK_20017, "P"
  else
    write "<!> Failed (2001.7) - Combined Packet Sent Counter incremented when not expected."
    ut_setrequirements HK_20017, "F"
  endif
endif

write ";*********************************************************************"
write ";  Step 5.0: Test stale data in only 1 output packet."
write ";*********************************************************************"
write ";  Step 5.1: Update copy table."
write ";*********************************************************************"
s $SC_$CPU_hk_copytable2

start load_table("hk_cpy_tbl.tbl", hostCPU)
wait 20

ut_sendcmd "$SC_$CPU_TBL_VALIDATE INACTIVE VTABLENAME=HKCopyTblName"
wait 20

ut_sendcmd "$SC_$CPU_TBL_ACTIVATE ATABLENAME=HKCopyTblName"
wait 10

write ";*********************************************************************"
write ";  Step 5.2: Send 19 input messages as per the copy table."
write ";*********************************************************************"
OutputPacket4 = 0x89f
InputPacket21 = 0x9a2

if ("$CPU" = "CPU2") then
   OutputPacket4 = 0x99f
   InputPacket21 = 0xaa2
elseif ("$CPU" = "CPU3") then
   OutputPacket4 = 0xa9f
   InputPacket21 = 0x8a2
endif 

/$SC_$CPU_TO_ADDPACKET Stream=OutputPacket4 Pkt_Size=x'0' Priority=x'0' Reliability=x'1' Buflimit=x'4'

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket1 DataSize=4 DataPattern =0x11111111
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket1,4) & "C000" & %hex(pktLen,4) & "00000000000011111111"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket2 DataSize=8 DataPattern =0x22222222
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket2,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "22222222"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket3 DataSize=16 DataPattern =0x33333333
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket3,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "33333333"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket4 DataSize=32 DataPattern =0x44444444
;;wait 2
size = 32
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket4,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "44444444"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket5 DataSize=32 DataPattern =0x55555555
;;wait 2
rawCmd = %hex(InputPacket5,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "55555555"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket6 DataSize=16 DataPattern =0x66666666
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket6,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "66666666"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket7 DataSize=8 DataPattern =0x77777777
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket7,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "77777777"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket8 DataSize=4 DataPattern =0x88888888
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket8,4) & "C000" & %hex(pktLen,4) & "00000000000088888888"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket9 DataSize=4 DataPattern =0x99999999
;;wait 2
rawCmd = %hex(InputPacket9,4) & "C000" & %hex(pktLen,4) & "00000000000099999999"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket10 DataSize=8 DataPattern =0xaaaaaaaa
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket10,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "aaaaaaaa"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket11 DataSize=8 DataPattern =0xbbbbbbbb
;;wait 2
rawCmd = %hex(InputPacket11,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "bbbbbbbb"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket12 DataSize=4 DataPattern =0xcccccccc
;;wait 2
size = 4
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket12,4) & "C000" & %hex(pktLen,4) & "000000000000cccccccc"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket13 DataSize=4 DataPattern =0xdddddddd
;;wait 2
rawCmd = %hex(InputPacket13,4) & "C000" & %hex(pktLen,4) & "000000000000dddddddd"
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket14 DataSize=8 DataPattern =0xeeeeeeee
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket14,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "eeeeeeee"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket16 DataSize=32 DataPattern =0x16161616
;;wait 2
size = 32
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket16,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "16161616"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket17 DataSize=32 DataPattern =0x17171717
;;wait 2
rawCmd = %hex(InputPacket17,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "17171717"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket18 DataSize=16 DataPattern =0x18181818
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket18,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "18181818"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket19 DataSize=8 DataPattern =0x19191919
;;wait 2
size = 8
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket19,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "19191919"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

write ";*********************************************************************"
write ";  Don't send InputPacket20 so there will be missing data in Output2"
write ";*********************************************************************"

;;/$SC_$CPU_TST_HK_SENDINMSG MsgId=InputPacket21 DataSize=16 DataPattern =0xffffffff
;;wait 2
size = 16
pktLen = (12 + size) - 7
rawCmd = %hex(InputPacket21,4) & "C000" & %hex(pktLen,4) & "000000000000"
;; Add the data
for i = 1 to size/4 do
  rawCmd = rawCmd & "ffffffff"
enddo
write ">> RawCmd = '",rawCmd,"'"
/RAW {rawCmd}
wait 1

write ";*********************************************************************"
write ";  Step 5.3: Send Output Message 1 command and check data"
write ";*********************************************************************"

;;setup data expected packet byte data pattern
DataBytePattern[0] = 0x11
DataBytePattern[1] = 0x11
DataBytePattern[2] = 0x11
DataBytePattern[3] = 0x11 
DataBytePattern[4] = 0x22
DataBytePattern[5] = 0x22 
DataBytePattern[6] = 0x22
DataBytePattern[7] = 0x22 
DataBytePattern[8] = 0x33
DataBytePattern[9] = 0x33 
DataBytePattern[10] = 0x33
DataBytePattern[11] = 0x33
DataBytePattern[12] = 0x44
DataBytePattern[13] = 0x44 
DataBytePattern[14] = 0x44
DataBytePattern[15] = 0x44 
DataBytePattern[16] = 0x55
DataBytePattern[17] = 0x55 
DataBytePattern[18] = 0x55
DataBytePattern[19] = 0x55 
DataBytePattern[20] = 0x66
DataBytePattern[21] = 0x66 
DataBytePattern[22] = 0x66
DataBytePattern[23] = 0x66 
DataBytePattern[24] = 0x77
DataBytePattern[25] = 0x77 
DataBytePattern[26] = 0x77 
DataBytePattern[27] = 0x77  
DataBytePattern[28] = 0x88 
DataBytePattern[29] = 0x88  
DataBytePattern[30] = 0x88 
DataBytePattern[31] = 0x88  
DataBytePattern[32] = 0x99 
DataBytePattern[33] = 0x99 
DataBytePattern[34] = 0x99
DataBytePattern[35] = 0x99 
DataBytePattern[36] = 0xaa
DataBytePattern[37] = 0xaa 
DataBytePattern[38] = 0xaa
DataBytePattern[39] = 0xaa
DataBytePattern[40] = 0xbb
DataBytePattern[41] = 0xbb 
DataBytePattern[42] = 0xbb
DataBytePattern[43] = 0xbb 
DataBytePattern[44] = 0xcc
DataBytePattern[45] = 0xcc
DataBytePattern[46] = 0xcc
DataBytePattern[47] = 0xcc 
DataBytePattern[48] = 0xdd
DataBytePattern[49] = 0xdd 
DataBytePattern[50] = 0xdd
DataBytePattern[51] = 0xdd 
DataBytePattern[52] = 0xee
DataBytePattern[53] = 0xee 
DataBytePattern[54] = 0xee
DataBytePattern[55] = 0xee 
DataBytePattern[56] = 0xff
DataBytePattern[57] = 0xff
DataBytePattern[58] = 0xff
DataBytePattern[59] = 0xff 
DataBytePattern[60] = 0x16
DataBytePattern[61] = 0x16 
DataBytePattern[62] = 0x16
DataBytePattern[63] = 0x16
DataBytePattern[64] = 0x17
DataBytePattern[65] = 0x17 
DataBytePattern[66] = 0x17
DataBytePattern[67] = 0x17 
DataBytePattern[68] = 0x18
DataBytePattern[69] = 0x18 
DataBytePattern[70] = 0x18
DataBytePattern[71] = 0x18 
DataBytePattern[72] = 0x19
DataBytePattern[73] = 0x19 
DataBytePattern[74] = 0x19
DataBytePattern[75] = 0x19 								

for entry = 76 to 80 do
   DataBytePattern[entry] = 0	
enddo

s $SC_$CPU_hk_sendoutmsg(OutputPacket1, DataBytePattern, Pkt1, NoChecks, 0)

write ";*********************************************************************"
write ";  Step 5.4: Send Output Message 2 command and check data"
write ";*********************************************************************"

;;setup data expected packet byte data pattern
DataBytePattern[0] = 0x00
DataBytePattern[1] = 0x00 
DataBytePattern[2] = 0x19
DataBytePattern[3] = 0x19 
DataBytePattern[4] = 0x18
DataBytePattern[5] = 0x18 
DataBytePattern[6] = 0x17
DataBytePattern[7] = 0x17 
DataBytePattern[8] = 0x16
DataBytePattern[9] = 0x16 
DataBytePattern[10] = 0xff
DataBytePattern[11] = 0xff 
DataBytePattern[12] = 0xee
DataBytePattern[13] = 0xee 
DataBytePattern[14] = 0xdd
DataBytePattern[15] = 0xdd 
DataBytePattern[16] = 0xcc
DataBytePattern[17] = 0xcc 
DataBytePattern[18] = 0xbb
DataBytePattern[19] = 0xbb 
DataBytePattern[20] = 0xaa
DataBytePattern[21] = 0xaa 
DataBytePattern[22] = 0x99
DataBytePattern[23] = 0x99 
DataBytePattern[24] = 0x88
DataBytePattern[25] = 0x88 
DataBytePattern[26] = 0x77
DataBytePattern[27] = 0x77 
DataBytePattern[28] = 0x66
DataBytePattern[29] = 0x66 
DataBytePattern[30] = 0x55
DataBytePattern[31] = 0x55 
DataBytePattern[32] = 0x44
DataBytePattern[33] = 0x44 
DataBytePattern[34] = 0x33
DataBytePattern[35] = 0x33 
DataBytePattern[36] = 0x22
DataBytePattern[37] = 0x22 
DataBytePattern[38] = 0x11
DataBytePattern[39] = 0x11

for entry = 40 to 80 do
   DataBytePattern[entry] = 0	
enddo

s $SC_$CPU_hk_sendoutmsg(OutputPacket2, DataBytePattern, Pkt2, MissingYes, 1)

write ";*********************************************************************"
write ";  Step 5.5: Send Output Message 4 command and check data"
write ";*********************************************************************"
;;setup data expected packet byte data pattern
DataBytePattern[0] = 0xaa
DataBytePattern[1] = 0xbb 
DataBytePattern[2] = 0x99
DataBytePattern[3] = 0xcc 
DataBytePattern[4] = 0x88
DataBytePattern[5] = 0xdd 
DataBytePattern[6] = 0x77
DataBytePattern[7] = 0xee 
DataBytePattern[8] = 0x66
DataBytePattern[9] = 0xff 
DataBytePattern[10] = 0x55
DataBytePattern[11] = 0x16 
DataBytePattern[12] = 0x44
DataBytePattern[13] = 0x17 
DataBytePattern[14] = 0x33
DataBytePattern[15] = 0x18 
DataBytePattern[16] = 0x22
DataBytePattern[17] = 0x19 
DataBytePattern[18] = 0x19
DataBytePattern[19] = 0x11

for entry = 20 to 80 do
   DataBytePattern[entry] = 0	
enddo						

s $SC_$CPU_hk_sendoutmsg(OutputPacket4, DataBytePattern, Pkt4, NoChecks, 0)

write ";*********************************************************************"
write ";  Step 6.0:  Perform a Power-on Reset to clean-up from this test."
write ";*********************************************************************"
/$SC_$CPU_ES_POWERONRESET
wait 10

close_data_center
wait 60
                                                                                
cfe_startup {hostCPU}
wait 5

write "**** Requirements Status Reporting"
                                                                                
write "--------------------------"
write "   Requirement(s) Report"
write "--------------------------"
                                                                                
FOR i = 0 to ut_req_array_size DO
  ut_pfindicate {cfe_requirements[i]} {ut_requirement[i]}
ENDDO
 
drop ut_requirement ; needed to clear global variables
drop ut_req_array_size ; needed to clear global variables

write ";*********************************************************************"
write ";  End procedure $SC_$CPU_hk_missingdata                        "
write ";*********************************************************************"
ENDPROC
