PROC $sc_$cpu_ds_resetnocds
;*******************************************************************************
;  Test Name:  ds_resetnocds
;  Test Level: Build Verification
;  Test Type:  Functional
;
;  Test Description
;	This test verifies that the CFS Data Storage(DS) application initializes
;	the appropriate data items based upon the type of initialization that
;	occurs (Application Reset, Processor Reset, or Power-On Reset). This 
;	test also verifies that the proper notifications occur if any anomalies
;	exist with the data items stated in the requirements.
;
;	NOTE: This test SHOULD NOT be executed if the Make Tables Critical
;	configuration parameter is set to YES by the Mission.
;
;  Requirements Tested
;    cDS8000	DS shall generate a housekeeping message containing the
;		following:
;			a. Valid Ground Command Counter
;			b. Command Rejected Counter
;			c. Packets discarded (DS was disabled) Counter
;			d. Packets discarded (pkt has no filter) Counter
;			e. Packets discarded (failed filter test) Counter
;			f. Packets that passed filter test Counter
;			g. Good destination file I/O Counter
;			h. Bad destination file I/O Counter
;			i. Good updates to secondary header Counter
;			j. Bad updates to secondary header Counter
;			k. Destination file table loads Counter
;			l. Failed attempts to get table data pointer Counter
;			m. Packet filter table loads Counter
;			n. Failed attempts to get table data pointer Counter
;			o. Application State
;			p. Destinatation file(s) state:
;				1. File age
;				2. File size
;				3. File rate
;				4. Sequence count
;				5. Enable State
;				6. Open State
;				7. Filename
;    cDS9000	Upon initialization of the DS Application, DS shall initialize
;		the following data to Zero:
;			a. Valid Ground Command Counter
;			b. Command Rejected Counter
;			c. Packets discarded (DS was disabled) Counter
;			d. Packets discarded (pkt has no filter) Counter
;			e. Packets discarded (failed filter test) Counter
;			f. Packets that passed filter test Counter
;			g. Good destination file I/O Counter
;			h. Bad destination file I/O Counter
;			i. Good updates to secondary header Counter
;			j. Bad updates to secondary header Counter
;			k. Destination file table loads Counter
;			l. Failed attempts to get table data pointer Counter
;			m. Packet filter table loads Counter
;			n. Failed attempts to get table data pointer Counter
;    cDS9001	Upon cFE Power-On, DS shall initialize the DS tables from the
;		default files.
;    cDS9002	Upon cFE Processor Reset or DS Application Reset, DS shall close
;		all files.
;    cDS9004	Upon a cFE Processor Reset or DS Application Reset, DS shall
;		restore the following if the associated <PLATFORM_DEFINED> 
;		Preserve State set to FALSE:
;			a. File Sequence Counters
;                       b. <PLATFORM_DEFINED> Packet Processing State
;    cDS9005	Upon any initialization and/or Packet Filter Table Update, DS
;		shall validate the Packet Filter Table:
;			a. Table descriptor text
;			For each packet entry:
;			b. Message ID (0 = unused, else ok)
;			c. Destination File table index
;			d. Filter Type (time/sequence)
;			e. Filter parms (N,X,O)
;    cDS9006	Upon any initialization and/or Packet Filter Table Update, DS
;		shall subscribe to the messages defined in the Data Storage
;		Packet Filter Table.
;    cDS9007	Upon any initialization and/or Destination File Table Update, DS
;		will validate the Destination File Table:
;			a. Table descriptor tesxt for each destination file
;			   entry
;			b. Pathname
;			c. Basename
;			d. Extension
;			e. Filename type
;			f. File enable/disable state
;			g. Max file size
;			h. Max file age
;			i. Sequence count
;    cDS9008    Upon cFE Power-On, DS shall set the Packet Processing State to
;               the <PLATFORM_DEFINED> state (ENABLED or DISABLED).
;
;  Prerequisite Conditions
;	The cFE is up and running and ready to accept commands.
;	The DS commands and telemetry items exist in the GSE database.
;	The display pages exist for the DS Housekeeping.
;	A DS Test application (TST_DS) exists in order to fully test the DS
;		Application.
;
;  Assumptions and Constraints
;	None.
;
;  Change History
;	Date		   Name		Description
;	10/05/09	Walt Moleski	Original Procedure.
;       12/08/10        Walt Moleski    Modified the procedure to use variables
;                                       for the application name and ram disk.
;       01/22/15        Walt Moleski    Removed DS9001.1 from this procedure
;					since it was deleted for 2.4.0.0
;       07/24/15        Walt Moleski    Added DS9008 and tests for 2.4.1.0
;       01/31/17        Walt Moleski    Updated for DS 2.5.0.0 using CPU1 for
;                                       commanding and added a hostCPU variable
;                                       for the utility procs to connect to the
;                                       proper host IP address.
;
;  Arguments
;	None.
;
;  Procedures Called
;	Name			Description
;       ut_tlmwait	Wait for a specified telemetry point to update to a
;			specified value. 
;       ut_pfindicate	Print the pass fail status of a particular requirement
;			number.
;       ut_setupevents	Performs setup to verify that a particular event
;			message was received by ASIST.
;	ut_setrequirements	A directive to set the status of the cFE
;			requirements array.
;
;  Expected Test Results and Analysis
;
;**********************************************************************
;; Turn off logging for the includes
local logging = %liv (log_procedure)
%liv (log_procedure) = FALSE

#include "ut_statusdefs.h"
#include "ut_cfe_info.h"
#include "cfe_platform_cfg.h"
#include "cfe_evs_events.h"
#include "cfe_es_events.h"
#include "cfe_tbl_events.h"
#include "to_lab_events.h"
#include "ds_platform_cfg.h"
#include "ds_appdefs.h"
#include "ds_events.h"
#include "tst_ds_events.h"

%liv (log_procedure) = logging

#define DS_8000		0
#define DS_9000		1
#define DS_9001		2
#define DS_9002		3
#define DS_9004		4
#define DS_9005		5
#define DS_9006		6
#define DS_9007		7
#define DS_9008		8

global ut_req_array_size = 8
global ut_requirement[0 .. ut_req_array_size]

for i = 0 to ut_req_array_size DO
  ut_requirement[i] = "U"
enddo

;**********************************************************************
; Set the local values
;**********************************************************************
local cfe_requirements[0 .. ut_req_array_size] = ["DS_8000", "DS_9000", "DS_9001", "DS_9002", "DS_9004", "DS_9005", "DS_9006", "DS_9007", "DS_9008" ]

;**********************************************************************
; Define local variables
;**********************************************************************
LOCAL rawcmd
LOCAL fileTblPktId, fileTblAppId
LOCAL filterTblPktId, filterTblAppId
local DSAppName = "DS"  
local fileTblName = DSAppName & "." & DS_DESTINATION_TBL_NAME
local filterTblName = DSAppName & "." & DS_FILTER_TBL_NAME
local ramDir = "RAM:0"
local hostCPU = "$CPU"

;; Set the pkt and app Ids for the appropriate CPU
;; CPU1 is the default
fileTblPktId = "0F76"
fileTblAppId = 3958
filterTblPktId = "0F77"
filterTblAppId = 3959

write ";***********************************************************************"
write ";  Step 1.0: Data Storage Test Setup."
write ";***********************************************************************"
write ";  Step 1.1: Command a Power-on Reset on $CPU."
write ";***********************************************************************"
/$SC_$CPU_ES_POWERONRESET
wait 10

close_data_center
wait 60

cfe_startup {hostCPU}
wait 5

write ";***********************************************************************"
write ";  Step 1.2: Upload the default DS table load images to $CPU."
write ";***********************************************************************"
;; Create the initial tables for this procedure
s $sc_$cpu_ds_tbl3

;; Parse the filename configuration parameters for the default table filenames
local destFileName = DS_DEF_DEST_FILENAME
local filterFileName = DS_DEF_FILTER_FILENAME
local slashLoc = %locate(destFileName,"/")

;; loop until all slashes are found for the Destination File Table Name
while (slashLoc <> 0) do
  destFileName = %substring(destFileName,slashLoc+1,%length(destFileName))
  slashLoc = %locate(destFileName,"/")
enddo

write "==> Default Destination File Table filename = '",destFileName,"'"

slashLoc = %locate(filterFileName,"/")
;; loop until all slashes are found for the Filter Table Name
while (slashLoc <> 0) do
  filterFileName = %substring(filterFileName,slashLoc+1,%length(filterFileName))
  slashLoc = %locate(filterFileName,"/")
enddo

write "==> Default Filter Table filename = '",filterFileName,"'"

;; Upload the files to $CPU
s ftp_file("CF:0/apps", "ds_filtfile.tbl", destFileName, hostCPU, "P")
s ftp_file("CF:0/apps", "ds_filtfilter.tbl", filterFileName, hostCPU, "P")

wait 5

write ";***********************************************************************"
write ";  Step 1.3: Display the Housekeeping pages "
write ";***********************************************************************"
page $SC_$CPU_DS_HK
page $SC_$CPU_TST_DS_HK
page $SC_$CPU_DS_FILTER_TBL
page $SC_$CPU_DS_FILE_TBL

write ";***********************************************************************"
write ";  Step 1.4:  Start the Data Storage (DS) and Test Applications.     "
write ";***********************************************************************"
s $sc_$cpu_ds_start_apps("1.4")
wait 5

;; Verify the Housekeeping Packet is being generated
local hkPktId = "p0B8"

;; Wait for the sequencecount to increment twice
local seqTlmItem = hkPktId & "scnt"
local currSCnt = {seqTlmItem}
local expectedSCnt = currSCnt + 2

ut_tlmwait {seqTlmItem}, {expectedSCnt}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed (8000) - Housekeeping packet is being generated."
  ut_setrequirements DS_8000, "P"
else
  write "<!> Failed (8000) - Housekeeping packet sequence count did not increment. Housekeeping packet is not being recieved."
  ut_setrequirements DS_8000, "F"
endif

;; Check the HK tlm items to see if they are initialized properly
if ($SC_$CPU_DS_CMDPC = 0) AND ($SC_$CPU_DS_CMDEC = 0) AND ;;
   ($SC_$CPU_DS_DisabledPktCnt = 0) AND ;;
   ($SC_$CPU_DS_FilteredPktCnt = 0) AND ($SC_$CPU_DS_PassedPktCnt = 0) AND ;;
   ($SC_$CPU_DS_FileWriteCnt = 0) AND ($SC_$CPU_DS_FileWriteErrCnt = 0) AND ;;
   ($SC_$CPU_DS_FileUpdCnt = 0) AND ($SC_$CPU_DS_FileUpdErrCnt = 0) AND ;;
   ($SC_$CPU_DS_DestLoadCnt = 1) AND ($SC_$CPU_DS_DestPtrErrCnt = 0) AND ;;
   ($SC_$CPU_DS_FilterLoadCnt = 1) AND ($SC_$CPU_DS_FilterPtrErrCnt = 0) then
  write "<*> Passed (9000) - Housekeeping telemetry initialized properly."
  ut_setrequirements DS_9000, "P"
else
  write "<!> Failed (9000) - Housekeeping telemetry NOT initialized properly at startup."
  write "CMDPC                = ", $SC_$CPU_DS_CMDPC
  write "CMDEC                = ", $SC_$CPU_DS_CMDEC
  write "Disabled Pkts        = ", $SC_$CPU_DS_DisabledPktCnt
  write "Failed Filter Pkts   = ", $SC_$CPU_DS_FilteredPktCnt
  write "Passed Filter Pkts   = ", $SC_$CPU_DS_PassedPktCnt
  write "Good i/o writes      = ", $SC_$CPU_DS_FileWriteCnt
  write "Bad i/o writes       = ", $SC_$CPU_DS_FileWriteErrCnt
  write "Good hdr writes      = ", $SC_$CPU_DS_FileUpdCnt
  write "Bad hdr writes       = ", $SC_$CPU_DS_FileUpdErrCnt
  write "Dest Tbl Loads       = ", $SC_$CPU_DS_DestLoadCnt
  write "Dest Tbl ptr fails   = ", $SC_$CPU_DS_DestPtrErrCnt
  write "Filter Tbl Loads     = ", $SC_$CPU_DS_FilterLoadCnt
  write "Filter Tbl ptr fails = ", $SC_$CPU_DS_FilterPtrErrCnt
  ut_setrequirements DS_9000, "F"
endif

;; Verify 9005, and 9007
if ($SC_$CPU_DS_DestLoadCnt = 1) AND ($SC_$CPU_DS_FilterLoadCnt = 1) then
  write "<*> Passed (9005;9007) - The tables were validated properly."
  ut_setrequirements DS_9005, "P"
  ut_setrequirements DS_9007, "P"
else
  if ($SC_$CPU_DS_DestLoadCnt = 0) then
    write "<!> Failed (9005) - The Destination File table was not validated properly at startup."
    ut_setrequirements DS_9005, "P"
  endif
  if ($SC_$CPU_DS_FilterLoadCnt = 0) then
    write "<!> Failed (9007) - The Packet Filter table was not validated properly at startup."
    ut_setrequirements DS_9007, "P"
  endif
endif

;; Verify 9006
;; Dump the SB Routing table
s get_file_to_cvt (ramDir, "cfe_sb_route.dat", "$cpu_sb_route.dat", hostCPU)
wait 5

local filterMsgID
local filterEntries = 0
local foundSubscription = 0

for i = 0 to DS_PACKETS_IN_FILTER_TABLE-1 do
  filterMsgID = $SC_$CPU_DS_PF_TBL[i].MessageID
  if (filterMsgID <> 0) then
    filterEntries = filterEntries + 1
    write "== Looking for msgID = ", %hex(filterMsgId,4)
    for sbIndex = 1 to 16320 do
      if  ($SC_$CPU_SB_RouteEntry[sbIndex].SB_AppName = DSAppName) AND ;;
          ($SC_$CPU_SB_RouteEntry[sbIndex].SB_MsgID = filterMsgID) then
        foundSubscription = foundSubscription + 1
        break
      elseif ($SC_$CPU_SB_RouteEntry[sbIndex].SB_AppName = "") then
        break
      endif
    enddo
  endif
enddo

if (foundSubscription = filterEntries) then
  write "<*> Passed (9006) - All message IDs in the Packet Filter Table have subscriptions."
  ut_setrequirements DS_9006, "P"
else
  write "<!> Failed (9006) - Expected ",filterEntries," message ID subscriptions. Found ",foundSubscription
  ut_setrequirements DS_9006, "F"
endif

;; Verify DS_DEF_ENABLE_STATE
if (DS_DEF_ENABLE_STATE = 1) then
  if (p@$SC_$CPU_DS_AppEnaState = "Enabled") then
    write "<*> Passed (9008) - DS Application State is enabled as expected."
    ut_setrequirements DS_9008, "P"
  else
    write "<!> Failed (9008) - DS Application State is NOT enabled as expected.  State = '",p@$SC_$CPU_DS_AppEnaState,"'"
    ut_setrequirements DS_9008, "F"
  endif
else
  if (p@$SC_$CPU_DS_AppEnaState = "Disabled") then
    write "<*> Passed (9008) - DS Application State is disabled as expected."
    ut_setrequirements DS_9008, "P"
  else
    write "<!> Failed (9008) - DS Application State is NOT disabled as expected.  State = '",p@$SC_$CPU_DS_AppEnaState,"'"
    ut_setrequirements DS_9008, "F"
  endif
endif

wait 5

write ";***********************************************************************"
write ";  Step 1.5: Enable DEBUG Event Messages "
write ";***********************************************************************"
local cmdCtr = $SC_$CPU_EVS_CMDPC + 1

;; Enable DEBUG events for the DS application ONLY
/$SC_$CPU_EVS_EnaAppEVTType Application=DSAppName DEBUG

ut_tlmwait $SC_$CPU_EVS_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Enable Debug events command sent properly."
else
  write "<!> Failed - Enable Debug events command."
endif

write ";***********************************************************************"
write ";  Step 1.6: Dump the Destination File and Packet Filter tables. "
write ";***********************************************************************"
;; Dump the Packet Filter Tables
s get_tbl_to_cvt (ramDir,filterTblName,"A","$cpu_filtertbl16",hostCPU,filterTblPktId)

local filterEntryCount = 0
;; Verify the table contents loaded in Step 1.2
for i = 0 to DS_PACKETS_IN_FILTER_TABLE-1 do
  if ($SC_$CPU_DS_PF_TBL[i].MessageID <> DS_UNUSED) then
    filterEntryCount = filterEntryCount + 1
    write "==> MessageID = ",%hex($SC_$CPU_DS_PF_TBL[i].MessageID,4)
    for j = 0 to DS_FILTERS_PER_PACKET-1 do
      if ($SC_$CPU_DS_PF_TBL[i].FilterParams[j].FilterType <> DS_UNUSED) then
        write "==> File Index = ",$SC_$CPU_DS_PF_TBL[i].FilterParams[j].Index
	write "==> Filter Type = ",$SC_$CPU_DS_PF_TBL[i].FilterParams[j].FilterType     
        write "==> N Value = ",$SC_$CPU_DS_PF_TBL[i].FilterParams[j].N_Value
        write "==> X Value = ",$SC_$CPU_DS_PF_TBL[i].FilterParams[j].X_Value
        write "==> O Value = ",$SC_$CPU_DS_PF_TBL[i].FilterParams[j].O_Value
      endif
    enddo
  else
    i = DS_PACKETS_IN_FILTER_TABLE
  endif
enddo

;; Dump the Destination File Table
s get_tbl_to_cvt (ramDir,fileTblName,"A","$cpu_filetbl17",hostCPU,fileTblPktId)

local fileEntryCount = 0
;; Verify the table contents loaded in Step 1.2
for i = 0 to DS_DEST_FILE_CNT-1 do
  if ($SC_$CPU_DS_DF_TBL[i].FileNameType <> DS_UNUSED) then
    fileEntryCount = fileEntryCount + 1
    write "==> Pathname = '",$SC_$CPU_DS_DF_TBL[i].Pathname,"'"
    write "==> Basename = '",$SC_$CPU_DS_DF_TBL[i].Basename,"'"
    write "==> Extension = '",$SC_$CPU_DS_DF_TBL[i].Extension,"'"
    write "==> Name Type = ",p@$SC_$CPU_DS_DF_TBL[i].FileNameType
    write "==> State     = ",p@$SC_$CPU_DS_DF_TBL[i].FileState
    write "==> Max Size = ",$SC_$CPU_DS_DF_TBL[i].FileSize
    write "==> Max Age = ",$SC_$CPU_DS_DF_TBL[i].FileAge
    write "==> Seq Count = ",$SC_$CPU_DS_DF_TBL[i].SeqCnt
  else
    i = DS_DEST_FILE_CNT
  endif
enddo

if (filterEntryCount > 0) AND (fileEntryCount > 0) then
  write "<*> Passed (9001) - The Destination File and Packet Filter Table were loaded with ",fileEntryCount," and ",filterEntryCount," valid entries."
  ut_setrequirements DS_9001, "P"
else
  write "<!> Failed (9001) - The Packet Filter Table is empty."
  ut_setrequirements DS_9001, "F"
endif

wait 5

write ";***********************************************************************"
write ";  Step 2.0: Power-On Reset Tests."
write ";***********************************************************************"
write ";  Step 2.1: Remove the default Packet Filter table file."
write ";***********************************************************************"
s ftp_file("CF:0/apps", "na", filterFileName, hostCPU, "R")
wait 5

write ";***********************************************************************"
write ";  Step 2.2: Perform a Power-On Reset on $CPU."
write ";***********************************************************************"
/$SC_$CPU_ES_POWERONRESET
wait 10

close_data_center
wait 60

cfe_startup {hostCPU}
wait 5

write ";***********************************************************************"
write ";  Step 2.3:  Start the Data Storage (DS) and Test Applications.     "
write ";***********************************************************************"
;; Setup the error events into slots that will not get overwritten by the
;; start_apps procedure
ut_setupevents "$SC","$CPU","CFE_TBL",CFE_TBL_LOAD_ERR_EID, "ERROR", 3
ut_setupevents "$SC","$CPU",{DSAppName},DS_INIT_TBL_ERR_EID, "ERROR", 4

;; Start the apps
s $sc_$cpu_ds_start_apps("2.3")
wait 5

;; Check for the error events
if ($SC_$CPU_find_event[3].num_found_messages = 1) AND ;;
   ($SC_$CPU_find_event[4].num_found_messages = 1) then
  write "<*> Passed - Table Load Error message rcvd."
else
  write "<!> Failed - Table Load Error messages were NOT rcvd."
endif

write ";***********************************************************************"
write ";  Step 2.4: Enable DEBUG Event Messages "
write ";***********************************************************************"
local cmdCtr = $SC_$CPU_EVS_CMDPC + 1

;; Enable DEBUG events for the DS application ONLY
/$SC_$CPU_EVS_EnaAppEVTType Application=DSAppName DEBUG
  
ut_tlmwait $SC_$CPU_EVS_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Enable Debug events command sent properly."
else
  write "<!> Failed - Enable Debug events command."
endif

write ";***********************************************************************"
write ";  Step 2.5: Restore the default Packet Filter Table file."
write ";***********************************************************************"
s ftp_file("CF:0/apps", "ds_filtfilter.tbl", filterFileName, hostCPU, "P")
wait 5

write ";***********************************************************************"
write ";  Step 2.6: Remove the default Destination File Table file."
write ";***********************************************************************"
s ftp_file("CF:0/apps", "na", destFileName, hostCPU, "R")
wait 5

write ";***********************************************************************"
write ";  Step 2.7: Perform a Power-On Reset on $CPU."
write ";***********************************************************************"
/$SC_$CPU_ES_POWERONRESET
wait 10

close_data_center
wait 60

cfe_startup {hostCPU}
wait 5

write ";***********************************************************************"
write ";  Step 2.8: Start the Data Storage (DS) and Test Applications.     "
write ";***********************************************************************"
;; Setup the error events into slots that will not get overwritten by the
;; start_apps procedure
ut_setupevents "$SC","$CPU","CFE_TBL",CFE_TBL_LOAD_ERR_EID, "ERROR", 3
ut_setupevents "$SC","$CPU",{DSAppName},DS_INIT_TBL_ERR_EID, "ERROR", 4

;; Start the apps
s $sc_$cpu_ds_start_apps("2.8")
wait 5

;; Check for the error events
if ($SC_$CPU_find_event[3].num_found_messages = 1) AND ;;
   ($SC_$CPU_find_event[4].num_found_messages = 1) then
  write "<*> Passed - Table Load Error message rcvd."
else
  write "<!> Failed - Table Load Error messages were NOT rcvd."
endif

write ";***********************************************************************"
write ";  Step 2.9: Enable DEBUG Event Messages "
write ";***********************************************************************"
local cmdCtr = $SC_$CPU_EVS_CMDPC + 1

;; Enable DEBUG events for the DS application ONLY
/$SC_$CPU_EVS_EnaAppEVTType Application=DSAppName DEBUG
  
ut_tlmwait $SC_$CPU_EVS_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Enable Debug events command sent properly."
else
  write "<!> Failed - Enable Debug events command."
endif

write ";***********************************************************************"
write ";  Step 2.10: Remove the default Packet Filter table file."
write ";***********************************************************************"
s ftp_file("CF:0/apps", "na", filterFileName, hostCPU, "R")
wait 5

write ";***********************************************************************"
write ";  Step 2.11: Perform a Power-On Reset on $CPU."
write ";***********************************************************************"
/$SC_$CPU_ES_POWERONRESET
wait 10

close_data_center
wait 60

cfe_startup {hostCPU}
wait 5

write ";***********************************************************************"
write ";  Step 2.12: Start the Data Storage (DS) and Test Applications.     "
write ";***********************************************************************"
;; Setup the error events into slots that will not get overwritten by the
;; start_apps procedure
ut_setupevents "$SC","$CPU","CFE_TBL",CFE_TBL_LOAD_ERR_EID, "ERROR", 3
ut_setupevents "$SC","$CPU",{DSAppName},DS_INIT_TBL_ERR_EID, "ERROR", 4

;; Start the apps
s $sc_$cpu_ds_start_apps("2.12")
wait 5

;; Check for the error events
if ($SC_$CPU_find_event[3].num_found_messages = 2) AND ;;
   ($SC_$CPU_find_event[4].num_found_messages = 2) then
  write "<*> Passed - Table Load Error message rcvd."
else
  write "<!> Failed - Table Load Error messages were NOT rcvd."
endif

write ";***********************************************************************"
write ";  Step 2.13: Restore the default Table files."
write ";***********************************************************************"
s ftp_file("CF:0/apps", "ds_filtfile.tbl", destFileName, hostCPU, "P")
wait 5
s ftp_file("CF:0/apps", "ds_filtfilter.tbl", filterFileName, hostCPU, "P")
wait 5

write ";***********************************************************************"
write ";  Step 2.14: Utilizing the TST_DS application, send the command that  "
write ";  will set all the counters that get reset to zero (0) by the Reset  "
write ";  command to a non-zero value."                                      
write ";***********************************************************************"
ut_setupevents "$SC", "$CPU", "TST_DS", TST_DS_SET_COUNTERS_INF_EID, "INFO", 1

/$SC_$CPU_TST_DS_SetCounters

;; Check for the event message 
ut_tlmwait  $SC_$CPU_find_event[1].num_found_messages, 1
if (UT_TW_Status = UT_Success) then 
  write "<*> Passed - Expected Event Msg ",TST_DS_SET_COUNTERS_INF_EID," rcv'd."
else
  write "<!> Failed - Event message ", $SC_$CPU_evs_eventid," rcv'd. Expected Event Msg ",TST_DS_SET_COUNTERS_INF_EID,"."
endif

wait 5

;; Check the HK telemetry
if ($SC_$CPU_DS_CMDPC > 0) AND ($SC_$CPU_DS_CMDEC > 0) AND ;;
   ($SC_$CPU_DS_DisabledPktCnt > 0) AND ($SC_$CPU_DS_IgnoredPktCnt > 0) AND ;;
   ($SC_$CPU_DS_FilteredPktCnt > 0) AND ($SC_$CPU_DS_PassedPktCnt > 0) AND ;;
   ($SC_$CPU_DS_FileWriteCnt > 0) AND ($SC_$CPU_DS_FileWriteErrCnt > 0) AND ;;
   ($SC_$CPU_DS_FileUpdCnt > 0) AND ($SC_$CPU_DS_FileUpdErrCnt > 0) AND ;;
   ($SC_$CPU_DS_DestLoadCnt > 0) AND ($SC_$CPU_DS_DestPtrErrCnt > 0) AND ;;
   ($SC_$CPU_DS_FilterLoadCnt > 0) AND ($SC_$CPU_DS_FilterPtrErrCnt > 0) then
  write "<*> Passed - Counters are all non-zero. Sending reset command."
else
  write "<*> Failed - At least one counter is still 0."
endif

wait 5

write ";***********************************************************************"
write ";  Step 2.15: Perform a Power-On Reset on $CPU."
write ";***********************************************************************"
/$SC_$CPU_ES_POWERONRESET
wait 10

close_data_center
wait 60

cfe_startup {hostCPU}
wait 5

write ";***********************************************************************"
write ";  Step 2.16: Start the Data Storage (DS) and Test Applications.     "
write ";***********************************************************************"
s $sc_$cpu_ds_start_apps("2.13")
wait 5

;; Wait until at least 2 Housekeeping packets are rcv'd
expectedSCnt = currSCnt + 2

ut_tlmwait {seqTlmItem}, {expectedSCnt}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed (8000) - Housekeeping packet is being generated."
  ut_setrequirements DS_8000, "P"
else
  write "<!> Failed (8000) - Housekeeping packet sequence count did not increment. Housekeeping packet is not being recieved."
  ut_setrequirements DS_8000, "F"
endif

;; Check the HK tlm items to see if they are initialized properly
if ($SC_$CPU_DS_CMDPC = 0) AND ($SC_$CPU_DS_CMDEC = 0) AND ;;
   ($SC_$CPU_DS_DisabledPktCnt = 0) AND ;;
   ($SC_$CPU_DS_FilteredPktCnt = 0) AND ($SC_$CPU_DS_PassedPktCnt = 0) AND ;;
   ($SC_$CPU_DS_FileWriteCnt = 0) AND ($SC_$CPU_DS_FileWriteErrCnt = 0) AND ;;
   ($SC_$CPU_DS_FileUpdCnt = 0) AND ($SC_$CPU_DS_FileUpdErrCnt = 0) AND ;;
   ($SC_$CPU_DS_DestLoadCnt = 1) AND ($SC_$CPU_DS_DestPtrErrCnt = 0) AND ;;
   ($SC_$CPU_DS_FilterLoadCnt = 1) AND ($SC_$CPU_DS_FilterPtrErrCnt = 0) then
  write "<*> Passed (9000) - Housekeeping telemetry initialized properly."
  ut_setrequirements DS_9000, "P"
else
  write "<!> Failed (9000) - Housekeeping telemetry NOT initialized properly at startup."
  write "CMDPC                = ", $SC_$CPU_DS_CMDPC
  write "CMDEC                = ", $SC_$CPU_DS_CMDEC
  write "Disabled Pkts        = ", $SC_$CPU_DS_DisabledPktCnt
  write "Failed Filter Pkts   = ", $SC_$CPU_DS_FilteredPktCnt
  write "Passed Filter Pkts   = ", $SC_$CPU_DS_PassedPktCnt
  write "Good i/o writes      = ", $SC_$CPU_DS_FileWriteCnt
  write "Bad i/o writes       = ", $SC_$CPU_DS_FileWriteErrCnt
  write "Good hdr writes      = ", $SC_$CPU_DS_FileUpdCnt
  write "Bad hdr writes       = ", $SC_$CPU_DS_FileUpdErrCnt
  write "Dest Tbl Loads       = ", $SC_$CPU_DS_DestLoadCnt
  write "Dest Tbl ptr fails   = ", $SC_$CPU_DS_DestPtrErrCnt
  write "Filter Tbl Loads     = ", $SC_$CPU_DS_FilterLoadCnt
  write "Filter Tbl ptr fails = ", $SC_$CPU_DS_FilterPtrErrCnt
  ut_setrequirements DS_9000, "F"
endif

write ";***********************************************************************"
write ";  Step 2.17: Enable DEBUG Event Messages "
write ";***********************************************************************"
local cmdCtr = $SC_$CPU_EVS_CMDPC + 1

;; Enable DEBUG events for the DS application ONLY
/$SC_$CPU_EVS_EnaAppEVTType Application=DSAppName DEBUG
  
ut_tlmwait $SC_$CPU_EVS_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Enable Debug events command sent properly."
else
  write "<!> Failed - Enable Debug events command."
endif

write ";***********************************************************************"
write ";  Step 3.0: Processor Reset Tests."
write ";***********************************************************************"
write ";  Step 3.1: Utilizing the TST_DS application, send several messages to"
write ";  the DS application so that files can be created and opened. "
write ";***********************************************************************"
write ";  Step 3.1.1: Parse the Packet Filter table to find several entries to "
write ";  send messages to. "
write ";***********************************************************************"
;; Turn off logging for this step
logging = %liv (log_procedure)
%liv (log_procedure) = FALSE

;; Parse the Packet Filter Table to find the desired number of MessageIDs
local entryCount = 0
local msgIDs[3]
for i = 1 to DS_PACKETS_IN_FILTER_TABLE-1 do
  if ($SC_$CPU_DS_PF_TBL[i].MessageID <> 0) then
    msgIDs[i] = $SC_$CPU_DS_PF_TBL[i].MessageID
    entryCount = entryCount + 1
  endif
  ;; Quit the loop if we have found the desired entry count
  if (entryCount = 3) then
    i = DS_PACKETS_IN_FILTER_TABLE
  endif
enddo

%liv (log_procedure) = logging

write ";***********************************************************************"
write ";  Step 3.1.2: Send the TST_DS command to send messages to DS using the "
write ";  message IDs found in the previous step. "
write ";***********************************************************************"
;; Setup the event capture
ut_setupevents "$SC", "$CPU", "TST_DS", TST_DS_MSG1_SENT_INF_EID, "INFO", 1

;; Send the command for each messageID
for i = 1 to 3 do 
  ;; Send the command to
  /$SC_$CPU_TST_DS_SENDMESSAGE MsgID=msgIDs[i] MsgType=1 Pattern=x'A5'
  wait 5 
enddo

;; Check for the event messages
if ($SC_$CPU_find_event[1].num_found_messages = 3) then
  write "<*> Passed - Rcv'd the expected number of Send events."
else
  write "<!> Failed - Expected 3 Send events. Rcv'd ",$SC_$CPU_find_event[1].num_found_messages
endif 

wait 5

write ";***********************************************************************"
write ";  Step 3.2: Save the file sequence counters and slots of all 'open' "
write ";  destination files. "
write ";***********************************************************************"
;; Since the File State HK does not display the current sequence count, each
;; open "file" will need to be parsed in order to verify them 
local seqCnt[DS_DEST_FILE_CNT]
local openFiles[DS_DEST_FILE_CNT]
local openCount = 0
local seqCount = 0
local dotLoc = 0

;; Send the Get File Info command to check the File Status
cmdCtr = $SC_$CPU_DS_CMDPC + 1

/$SC_$CPU_DS_GetFileInfo

ut_tlmwait $SC_$CPU_DS_CMDPC, {cmdCtr}

;; Parse the File State telemetry to find the current sequence count for each
local fileName
for i = 0 to DS_DEST_FILE_CNT-1 do
  if ($SC_$CPU_DS_FileState[i].FileName <> "") then
    fileName = $SC_$CPU_DS_FileState[i].FileName
    write "<*> Passed - A file was created with name '",fileName,"'"
    openCount = openCount + 1
    openFiles[openCount] = i
    ;; Parse the file name to get the current sequence count
    if (p@$SC_$CPU_DS_DF_TBL[i].FileNameType = "Count") then
      seqCount = seqCount + 1
      dotLoc = %locate(fileName,".")
      seqCnt[seqCount] = %substring(fileName,dotLoc-3,dotLoc-1)
      write "==> SeqCount = '",seqCnt[seqCount],"'"
    endif
  endif
enddo

;; Change the DS Application before the reset
local expectedState
cmdCtr = $SC_$CPU_DS_CMDPC + 1
if (p@$SC_$CPU_DS_AppEnaState = "Enabled") then
  expectedState = "Disabled"
  ;; Send the command
  /$SC_$CPU_DS_Disable
else
  expectedState = "Enabled"
  ;; Send the command
  /$SC_$CPU_DS_Enable
endif

ut_tlmwait $SC_$CPU_DS_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - DS Application State command sent properly."
else
  write "<!> Failed - DS Application State command did not increment CMDPC."
endif

wait 5

write ";*********************************************************************"
write ";  Step 3.3: Perform a Processor Reset. "
write ";*********************************************************************"
/$SC_$CPU_ES_PROCESSORRESET
wait 10

close_data_center
wait 60

cfe_startup {hostCPU}
wait 5

write ";***********************************************************************"
write ";  Step 3.4: Start the Data Storage (DS) and Test Applications.     "
write ";***********************************************************************"
s $sc_$cpu_ds_start_apps("3.4")
wait 5

;; Verify 9005, and 9007
if ($SC_$CPU_DS_DestLoadCnt = 1) AND ($SC_$CPU_DS_FilterLoadCnt = 1) then
  write "<*> Passed (9005;9007) - The tables were validated properly."
  ut_setrequirements DS_9005, "P"
  ut_setrequirements DS_9007, "P"
else
  if ($SC_$CPU_DS_DestLoadCnt = 0) then
    write "<!> Failed (9005) - The Destination File table was not validated properly at startup."
    ut_setrequirements DS_9005, "F"
  endif
  if ($SC_$CPU_DS_FilterLoadCnt = 0) then
    write "<!> Failed (9007) - The Packet Filter table was not validated properly at startup."
    ut_setrequirements DS_9007, "F"
  endif
endif

;; Verify 9006
;; Dump the SB Routing table
s get_file_to_cvt (ramDir, "cfe_sb_route.dat", "$cpu_sb_route.dat", hostCPU)
wait 5

filterEntries = 0
foundSubscription = 0

for i = 0 to DS_PACKETS_IN_FILTER_TABLE-1 do
  filterMsgID = $SC_$CPU_DS_PF_TBL[i].MessageID
  if (filterMsgID <> 0) then
    filterEntries = filterEntries + 1
    write "== Looking for msgID = ", %hex(filterMsgId,4)
    for sbIndex = 1 to CFE_SB_HIGHEST_VALID_MSGID do
      if  ($SC_$CPU_SB_RouteEntry[sbIndex].SB_AppName = DSAppName) AND ;;
          ($SC_$CPU_SB_RouteEntry[sbIndex].SB_MsgID = filterMsgID) then
        foundSubscription = foundSubscription + 1
        break
      elseif ($SC_$CPU_SB_RouteEntry[sbIndex].SB_AppName = "") then
        break
      endif
    enddo
  endif
enddo

if (foundSubscription = filterEntries) then
  write "<*> Passed (9006) - All message IDs in the Packet Filter Table have subscriptions."
  ut_setrequirements DS_9006, "P"
else
  write "<!> Failed (9006) - Expected ",filterEntries," message ID subscriptions. Found ",foundSubscription
  ut_setrequirements DS_9006, "F"
endif

;; Check the DS state based upon the DS_CDS_ENABLE_STATE parameter 
;; If this parameter is set to 1, the DS Application State is preserved.
;; Otherwise, the Default state should be set
if (DS_CDS_ENABLE_STATE = 1) then
  if (p@$SC_$CPU_DS_AppEnaState = expectedState) then
    write "<*> Passed (9004) - DS Application State is set as expected."
    ut_setrequirements DS_9004, "P"
  else
    write "<!> Failed (9004) - DS Application State is NOT as expected. State = '",p@$SC_$CPU_DS_AppEnaState,"'. Expected '",expectedState,"'"
    ut_setrequirements DS_9004, "F"
  endif
else
  if (DS_DEF_ENABLE_STATE = 1) then
    if (p@$SC_$CPU_DS_AppEnaState = "Enabled") then
      write "<*> Passed (9008) - DS Application State is enabled as expected."
      ut_setrequirements DS_9008, "P"
    else
      write "<!> Failed (9008) - DS Application State is NOT enabled as expected. State = '",p@$SC_$CPU_DS_AppEnaState,"'"
      ut_setrequirements DS_9008, "F"
    endif
  else
    if (p@$SC_$CPU_DS_AppEnaState = "Disabled") then
     write "<*> Passed (9008) - DS Application State is disabled as expected."
      ut_setrequirements DS_9008, "P"
    else
      write "<!> Failed (9008) - DS Application State is NOT disabled as expected. State = '",p@$SC_$CPU_DS_AppEnaState,"'"
      ut_setrequirements DS_9008, "F"
    endif
  endif
endif

;; Enable DS if the state is Disabled
if (p@$SC_$CPU_DS_AppEnaState = "Disabled") then
  cmdCtr = $SC_$CPU_DS_CMDPC + 1
  ;; Send the command
  /$SC_$CPU_DS_Enable

  ut_tlmwait $SC_$CPU_DS_CMDPC, {cmdCtr}
  if (UT_TW_Status = UT_Success) then
    write "<*> Passed - DS Application State command sent properly."
  else
    write "<!> Failed - DS Application State command did not increment CMDPC."
  endif
endif

wait 5

write ";***********************************************************************"
write ";  Step 3.5: Enable DEBUG Event Messages "
write ";***********************************************************************"
local cmdCtr = $SC_$CPU_EVS_CMDPC + 1

;; Enable DEBUG events for the DS application ONLY
/$SC_$CPU_EVS_EnaAppEVTType Application=DSAppName DEBUG
  
ut_tlmwait $SC_$CPU_EVS_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Enable Debug events command sent properly."
else
  write "<!> Failed - Enable Debug events command."
endif

write ";***********************************************************************"
write ";  Step 3.6: Parse the File State HK information in order to verify that"
write ";  the open Files saved in Step 3.2 have been closed. "
write ";***********************************************************************"
;; Send the Get File Info command to check the File Status
cmdCtr = $SC_$CPU_DS_CMDPC + 1

/$SC_$CPU_DS_GetFileInfo

ut_tlmwait $SC_$CPU_DS_CMDPC, {cmdCtr}

;; Parse the File State tlm to determine if the proper information was saved
for i = 1 to openCount do
  if ($SC_$CPU_DS_FileState[openFiles[i]].FileName = "") then
    write "<*> Passed (9002) - The file at slot ",openFiles[i]," has been closed."
    ut_setrequirements DS_9002, "P"
  else
    write "<!> Failed (9002) - There is still an open file at slot ",openFiles[i]
    ut_setrequirements DS_9002, "F"
  endif
enddo

write ";***********************************************************************"
write ";  Step 3.7: Verify that the File Sequence counters were restored after "
write ";  the Processor Reset. "
write ";***********************************************************************"
write ";  Step 3.7.1: Send the TST_DS command to send the same messages to DS "
write ";  that were sent in Step 3.1.2. "
write ";***********************************************************************"
;; Setup the event capture
ut_setupevents "$SC", "$CPU", "TST_DS", TST_DS_MSG1_SENT_INF_EID, "INFO", 1

;; Send the command for each messageID
for i = 1 to 3 do 
  ;; Send the command to
  /$SC_$CPU_TST_DS_SENDMESSAGE MsgID=msgIDs[i] MsgType=1 Pattern=x'A5'
  wait 5 
enddo

;; Check for the event messages
if ($SC_$CPU_find_event[1].num_found_messages = 3) then
  write "<*> Passed - Rcv'd the expected number of Send events."
else
  write "<!> Failed - Expected 3 Send events. Rcv'd ",$SC_$CPU_find_event[1].num_found_messages
endif 

wait 5

write ";***********************************************************************"
write ";  Step 3.7.2: Parse the File State HK information in order to verify "
write ";  that the File Sequence Counters saved in Step 3.2 have been restored."
write ";***********************************************************************"
local seqCntAR[DS_DEST_FILE_CNT]
seqCount = 0

;; Send the Get File Info command to check the File Status
cmdCtr = $SC_$CPU_DS_CMDPC + 1

/$SC_$CPU_DS_GetFileInfo

ut_tlmwait $SC_$CPU_DS_CMDPC, {cmdCtr}

;; Parse the File State tlm to determine the current sequence count for each
for i = 0 to DS_DEST_FILE_CNT-1 do
  if ($SC_$CPU_DS_FileState[i].FileName <> "") then
    fileName = $SC_$CPU_DS_FileState[i].FileName
    write "<*> Passed - A file was created with name '",fileName,"'"
    ;; Parse the file name to get the current sequence count
    if (p@$SC_$CPU_DS_DF_TBL[i].FileNameType = "Count") then
      seqCount = seqCount + 1
      dotLoc = %locate(fileName,".")
      seqCntAR[seqCount] = %substring(fileName,dotLoc-3,dotLoc-1)
      write "==> SeqCount After Reset = '",seqCntAR[seqCount],"'"
      if (seqCnt[seqCount] < seqCntAR[seqCount]) then
        write "<*> Passed (9004) - Sequence Count was preserved across reset"
        ut_setrequirements DS_9004, "P"
      else
        write "<!> Failed (9004) - Sequence Count before reset ='",seqCnt[i+1],"'; After reset ='",seqCntAR[i+1],"'."
        ut_setrequirements DS_9004, "F"
      endif
    endif
  endif
enddo

wait 5

write ";***********************************************************************"
write ";  Step 4.0: Application Reset Tests."
write ";***********************************************************************"
write ";  Step 4.1: Save the file sequence counters and slots of all 'open' "
write ";  destination files. "
write ";***********************************************************************"
openCount = 0
seqCount = 0

;; Send the Get File Info command to check the File Status
cmdCtr = $SC_$CPU_DS_CMDPC + 1

/$SC_$CPU_DS_GetFileInfo

ut_tlmwait $SC_$CPU_DS_CMDPC, {cmdCtr}

;; Parse the File State tlm to determine the current sequence count for each
local fileName
for i = 0 to DS_DEST_FILE_CNT-1 do
  if ($SC_$CPU_DS_FileState[i].FileName <> "") then
    fileName = $SC_$CPU_DS_FileState[i].FileName
    write "<*> Passed - A file was created with name '",fileName,"'"
    openCount = openCount + 1
    openFiles[openCount] = i
    ;; Parse the file name to get the current sequence count
    if (p@$SC_$CPU_DS_DF_TBL[i].FileNameType = "Count") then
      seqCount = seqCount + 1
      dotLoc = %locate(fileName,".")
      seqCnt[seqCount] = %substring(fileName,dotLoc-3,dotLoc-1)
      write "==> SeqCount = '",seqCnt[seqCount],"'"
    endif
  endif
enddo

write ";*********************************************************************"
write ";  Step 4.2: Restart the DS and TST_DS Applications. "
write ";*********************************************************************"
write ";  Step 4.2.1: Stop the DS and TST_DS Applications. "
write ";*********************************************************************"
local cmdCtr = $SC_$CPU_ES_CMDPC + 2

/$SC_$CPU_ES_DELETEAPP Application="TST_DS"
wait 4
/$SC_$CPU_ES_DELETEAPP Application=DSAppName
wait 4

ut_tlmwait  $SC_$CPU_ES_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - DS and TST_DS stop app commands sent properly."
else
  write "<!> Failed - Stop App commands did not increment CMDPC."
endif

wait 5

write ";*********************************************************************"
write ";  Step 4.2.2: Start the DS and TST_DS Applications. "
write ";*********************************************************************"
s $sc_$cpu_ds_start_apps("4.2.2")
wait 5

;; Verify 9005, and 9007
if ($SC_$CPU_DS_DestLoadCnt = 1) AND ($SC_$CPU_DS_FilterLoadCnt = 1) then
  write "<*> Passed (9005;9007) - The tables were validated properly."
  ut_setrequirements DS_9005, "P"
  ut_setrequirements DS_9007, "P"
else
  if ($SC_$CPU_DS_DestLoadCnt = 0) then
    write "<!> Failed (9005) - The Destination File table was not validated properly at startup."
    ut_setrequirements DS_9005, "F"
  endif
  if ($SC_$CPU_DS_FilterLoadCnt = 0) then
    write "<!> Failed (9007) - The Packet Filter table was not validated properly at startup."
    ut_setrequirements DS_9007, "F"
  endif
endif

;; Verify 9006
;; Dump the SB Routing table
s get_file_to_cvt (ramDir, "cfe_sb_route.dat", "$cpu_sb_route.dat", hostCPU)
wait 5

filterEntries = 0
foundSubscription = 0

for i = 0 to DS_PACKETS_IN_FILTER_TABLE-1 do
  filterMsgID = $SC_$CPU_DS_PF_TBL[i].MessageID
  if (filterMsgID <> 0) then
    filterEntries = filterEntries + 1
    write "== Looking for msgID = ", %hex(filterMsgId,4)
    for sbIndex = 1 to CFE_SB_HIGHEST_VALID_MSGID do
      if  ($SC_$CPU_SB_RouteEntry[sbIndex].SB_AppName = DSAppName) AND ;;
          ($SC_$CPU_SB_RouteEntry[sbIndex].SB_MsgID = filterMsgID) then
        foundSubscription = foundSubscription + 1
        break
      elseif ($SC_$CPU_SB_RouteEntry[sbIndex].SB_AppName = "") then
        break
      endif
    enddo
  endif
enddo

if (foundSubscription = filterEntries) then
  write "<*> Passed (9006) - All message IDs in the Packet Filter Table have subscriptions."
  ut_setrequirements DS_9006, "P"
else
  write "<!> Failed (9006) - Expected ",filterEntries," message ID subscriptions. Found ",foundSubscription
  ut_setrequirements DS_9006, "F"
endif

;; Enable DS if the state is Disabled
if (p@$SC_$CPU_DS_AppEnaState = "Disabled") then
  cmdCtr = $SC_$CPU_DS_CMDPC + 1
  ;; Send the command
  /$SC_$CPU_DS_Enable

  ut_tlmwait $SC_$CPU_DS_CMDPC, {cmdCtr}
  if (UT_TW_Status = UT_Success) then
    write "<*> Passed - DS Application State command sent properly."
  else
    write "<!> Failed - DS Application State command did not increment CMDPC."
  endif
endif

wait 5

write ";***********************************************************************"
write ";  Step 4.3: Enable DEBUG Event Messages "
write ";***********************************************************************"
local cmdCtr = $SC_$CPU_EVS_CMDPC + 2

;; Enable DEBUG events for the DS application ONLY
/$SC_$CPU_EVS_EnaAppEVTType Application=DSAppName DEBUG
wait 2
/$SC_$CPU_EVS_EnaAppEVTType Application="CFE_TBL" DEBUG
  
ut_tlmwait $SC_$CPU_EVS_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Enable Debug events command sent properly."
else
  write "<!> Failed - Enable Debug events command."
endif

write ";***********************************************************************"
write ";  Step 4.4: Parse the File State HK to determine if the open files have"
write ";  been closed. "
write ";***********************************************************************"
;; Send the Get File Info command to check the File Status
cmdCtr = $SC_$CPU_DS_CMDPC + 1

/$SC_$CPU_DS_GetFileInfo

ut_tlmwait $SC_$CPU_DS_CMDPC, {cmdCtr}

;; Parse the File State tlm to determine if the proper information was saved
for i = 1 to openCount do
  if ($SC_$CPU_DS_FileState[openFiles[i]].FileName = "") then
    write "<*> Passed (9002) - The file at slot ",openFiles[i]," has been closed."
    ut_setrequirements DS_9002, "P"
  else
    write "<!> Failed (9002) - There is still an open file at slot ",openFiles[i]
    ut_setrequirements DS_9002, "F"
  endif
enddo

write ";***********************************************************************"
write ";  Step 4.5: Verify that the File Sequence counters were restored after "
write ";  the Processor Reset. "
write ";***********************************************************************"
write ";  Step 4.5.1: Send the TST_DS command to send the same messages to DS "
write ";  that were sent in previous steps."
write ";***********************************************************************"
;; Setup the event capture
ut_setupevents "$SC", "$CPU", "TST_DS", TST_DS_MSG1_SENT_INF_EID, "INFO", 1

;; Send the command for each messageID
for i = 1 to 3 do 
  ;; Send the command to
  /$SC_$CPU_TST_DS_SENDMESSAGE MsgID=msgIDs[i] MsgType=1 Pattern=x'BB'
  wait 5 
enddo

;; Check for the event messages
if ($SC_$CPU_find_event[1].num_found_messages = 3) then
  write "<*> Passed - Rcv'd the expected number of Send events."
else
  write "<!> Failed - Expected 3 Send events. Rcv'd ",$SC_$CPU_find_event[1].num_found_messages
endif 

wait 5

write ";***********************************************************************"
write ";  Step 4.5.2: Parse the File State HK information in order to verify "
write ";  that the File Sequence Counters saved in Step 3.2 have been restored."
write ";***********************************************************************"
seqCount = 0

;; Send the Get File Info command to check the File Status
cmdCtr = $SC_$CPU_DS_CMDPC + 1

/$SC_$CPU_DS_GetFileInfo

ut_tlmwait $SC_$CPU_DS_CMDPC, {cmdCtr}

;; Parse the File State HK to determine the current sequence count for each
for i = 0 to DS_DEST_FILE_CNT-1 do
  if ($SC_$CPU_DS_FileState[i].FileName <> "") then
    fileName = $SC_$CPU_DS_FileState[i].FileName
    write "<*> Passed - A file was created with name '",fileName,"'"
    ;; Parse the file name to get the current sequence count
    if (p@$SC_$CPU_DS_DF_TBL[i].FileNameType = "Count") then
      seqCount = seqCount + 1
      dotLoc = %locate(fileName,".")
      seqCntAR[seqCount] = %substring(fileName,dotLoc-3,dotLoc-1)
      write "==> SeqCount After Reset = '",seqCntAR[seqCount],"'"
      if (seqCnt[seqCount] < seqCntAR[seqCount]) then
        write "<*> Passed (9004) - Sequence Count was preserved across reset"
        ut_setrequirements DS_9004, "P"
      else
        write "<!> Failed (9004) - Sequence Count before reset ='",seqCnt[i+1],"'; After reset ='",seqCntAR[i+1],"'."
        ut_setrequirements DS_9004, "F"
      endif
    endif
  endif
enddo

wait 5

write ";***********************************************************************"
write ";  Step 5.0: Table Validation Failure Tests"
write ";***********************************************************************"
write ";  Step 5.1: Create five Packet Filter Table load images with each "
write ";  containing one of the possible five content errors. "
write ";***********************************************************************"
;; Create the invalid Packet Filter table
s $sc_$cpu_ds_badfiltertbls
wait 5

write ";***********************************************************************"
write ";  Step 5.2: Loop for each file created above. "
write ";***********************************************************************"
for i = 1 to 5 do
  write ";***********************************************************************"
  write ";  Load the invalid table image."
  write ";***********************************************************************"
  ;; Load the table
  ut_setupevents "$SC", "$CPU", "CFE_TBL",CFE_TBL_FILE_LOADED_INF_EID,"INFO", 1

  cmdCtr = $SC_$CPU_TBL_CMDPC + 1
  
  start load_table ("ds_badfilter" & i & ".tbl", hostCPU)

  ut_tlmwait $SC_$CPU_TBL_CMDPC, {cmdCtr}
  if (UT_TW_Status = UT_Success) then
    write "<*> Passed - Load command for Invalid Packet Filter Table sent successfully."
  else
    write "<!> Failed - Load command for Invalid Packet Filter Table did not execute successfully."
  endif

  if ($SC_$CPU_find_event[1].num_found_messages = 1) then
    write "<*> Passed - Event Msg ",$SC_$CPU_find_event[1].eventid," Found!"
  else
    write "<!> Failed - Event Message not received for Load command."
  endif

  write ";***********************************************************************"
  write ";  Send the Table Services command to validate the inactive buffer."
  write ";***********************************************************************"
  ut_setupevents "$SC","$CPU","CFE_TBL",CFE_TBL_VAL_REQ_MADE_INF_EID, "DEBUG", 1
  ut_setupevents "$SC","$CPU","CFE_TBL",CFE_TBL_VALIDATION_ERR_EID, "ERROR", 2
  ut_setupevents "$SC","$CPU",{DSAppName},DS_FLT_TBL_ERR_EID, "ERROR", 3
  ut_setupevents "$SC","$CPU",{DSAppName},DS_FLT_TBL_EID, "INFO", 4

  cmdCtr = $SC_$CPU_TBL_CMDPC + 1

  /$SC_$CPU_TBL_VALIDATE INACTIVE VTABLENAME=filterTblName

  ut_tlmwait $SC_$CPU_TBL_CMDPC, {cmdCtr}
  if (UT_TW_Status = UT_Success) then
    write "<*> Passed - Packet Filter Table validate command sent."
  else
    write "<!> Failed - Packet Filter Table validation failed."
  endif

  ;; Wait for the validation message
  ut_tlmwait $SC_$CPU_find_event[2].num_found_messages, 1
  if (UT_TW_Status = UT_Success) then
    write "<*> Passed (9005) - Packet Filter Table validation failed as expected."
    ut_setrequirements DS_9005, "P"
  else
    write "<!> Failed (9005) - Packet Filter Table validation was successful with invalid entries."
    ut_setrequirements DS_9005, "F"
  endif

  ;; Verify the debug event was generated
  if ($SC_$CPU_find_event[1].num_found_messages = 1) then
    write "<*> Passed - Event Msg ",$SC_$CPU_find_event[1].eventid," Found!"
  else
    write "<!> Failed - Event Message not received for Validate command."
  endif

  ;; Verify the Validation Error event was generated by DS
  if ($SC_$CPU_find_event[3].num_found_messages > 0) then
    write "<*> Passed - Validation Event Msg rcv'd"
  else
    write "<!> Failed - Validation Event Msg was not received."
  endif

  ;; Verify the Validation Error event was generated by DS
  if ($SC_$CPU_find_event[4].num_found_messages > 0) then
    write "<*> Passed - Validation Summary Event Msg rcv'd"
  else
    write "<!> Failed - Validation Summary Event Msg was not received."
  endif

  write ";***********************************************************************"
  write ";  Send the Table Services Load Abort command to release the buffer."
  write ";***********************************************************************"
  ut_setupevents "$SC","$CPU","CFE_TBL",CFE_TBL_LOAD_ABORT_INF_EID,"INFO", 1

  cmdCtr = $SC_$CPU_TBL_CMDPC + 1

  /$SC_$CPU_TBL_LOADABORT ABTABLENAME=filterTblName

  ut_tlmwait $SC_$CPU_TBL_CMDPC, {cmdCtr}
  if (UT_TW_Status = UT_Success) then
    write "<*> Passed - Load abort command sent successfully."
  else
    write "<!> Failed - Load abort command did not execute successfully."
  endif

  ;; Check for the Event message generation
  if ($SC_$CPU_find_event[1].num_found_messages = 1) then
    write "<*> Passed - Event Msg ",$SC_$CPU_find_event[1].eventid," Found!"
  else
    write "<!> Failed - Event Message not received for Load Abort command."
  endif
enddo

wait 5

write ";***********************************************************************"
write ";  Step 5.3: Create invalid Destination File Table load images each "
write ";  containing one of the possible content errors. "
write ";***********************************************************************"
;; Create the invalid Destination File table
s $sc_$cpu_ds_badfiletbls
wait 5

write ";***********************************************************************"
write ";  Step 5.4: Loop for each file created above. "
write ";***********************************************************************"
write ";  Step 5.4.1: Send the Table Services command to load the next file."
write ";***********************************************************************"
for i = 1 to 9 do
  ;; Load the table
  ut_setupevents "$SC","$CPU","CFE_TBL",CFE_TBL_FILE_LOADED_INF_EID,"INFO", 1

  cmdCtr = $SC_$CPU_TBL_CMDPC + 1

  start load_table ("ds_badfile" & i & ".tbl", hostCPU)

  ut_tlmwait $SC_$CPU_TBL_CMDPC, {cmdCtr}
  if (UT_TW_Status = UT_Success) then
    write "<*> Passed - Load command for Invalid Destination File Table sent successfully."
  else
    write "<!> Failed - Load command for Invalid Destination File Table did not execute successfully."
  endif

  if ($SC_$CPU_find_event[1].num_found_messages = 1) then
    write "<*> Passed - Event Msg ",$SC_$CPU_find_event[1].eventid," Found!"
  else
    write "<!> Failed - Event Message not received for Load command."
  endif

  write ";***********************************************************************"
  write ";  Send the Table Services command to validate the inactive buffer."
  write ";***********************************************************************"
  ut_setupevents "$SC","$CPU","CFE_TBL",CFE_TBL_VAL_REQ_MADE_INF_EID, "DEBUG", 1
  ut_setupevents "$SC","$CPU","CFE_TBL",CFE_TBL_VALIDATION_ERR_EID, "ERROR", 2
  ut_setupevents "$SC","$CPU",{DSAppName},DS_FIL_TBL_ERR_EID, "ERROR", 3
  ut_setupevents "$SC","$CPU",{DSAppName},DS_FIL_TBL_EID, "INFO", 4

  cmdCtr = $SC_$CPU_TBL_CMDPC + 1

  /$SC_$CPU_TBL_VALIDATE INACTIVE VTABLENAME=fileTblName

  ut_tlmwait $SC_$CPU_TBL_CMDPC, {cmdCtr}
  if (UT_TW_Status = UT_Success) then
    write "<*> Passed - Packet Filter Table validate command sent."
    if ($SC_$CPU_find_event[1].num_found_messages = 1) then
      write "<*> Passed - Event Msg ",$SC_$CPU_find_event[1].eventid," Found!"
    else
      write "<!> Failed - Event Message not received for Validate command."
    endif
  else
    write "<!> Failed - Destination File Table validation failed."
  endif

  ;; Wait for the validation message
  ut_tlmwait $SC_$CPU_find_event[2].num_found_messages, 1
  if (UT_TW_Status = UT_Success) then
    write "<*> Passed (9007) - Destination File Table validation failed as expected."
    ut_setrequirements DS_9007, "P"
  else
    write "<!> Failed (9007) - Packet Filter Table validation was successful with invalid entries."
    ut_setrequirements DS_9007, "F"
  endif

  ;; Verify the Validation Error event was generated by DS
  if ($SC_$CPU_find_event[3].num_found_messages > 0) then
    write "<*> Passed - Validation Event Msg rcv'd"
  else
    write "<!> Failed - Validation Event Msg was not received."
  endif

  ;; Verify the Validation Error event was generated by DS
  if ($SC_$CPU_find_event[4].num_found_messages > 0) then
    write "<*> Passed - Validation Summary Event Msg rcv'd"
  else
    write "<!> Failed - Validation Summary Event Msg was not received."
  endif

  write ";***********************************************************************"
  write ";  Send the Table Services Load Abort command to release the buffer."
  write ";***********************************************************************"
  ut_setupevents "$SC", "$CPU", "CFE_TBL", CFE_TBL_LOAD_ABORT_INF_EID, "INFO", 1

  cmdCtr = $SC_$CPU_TBL_CMDPC + 1

  /$SC_$CPU_TBL_LOADABORT ABTABLENAME=fileTblName

  ut_tlmwait $SC_$CPU_TBL_CMDPC, {cmdCtr}
  if (UT_TW_Status = UT_Success) then
    write "<*> Passed - Load abort command sent successfully."
  else
    write "<!> Failed - Load abort command did not execute successfully."
  endif

  ;; Check for the Event message generation
  if ($SC_$CPU_find_event[1].num_found_messages = 1) then
    write "<*> Passed - Event Msg ",$SC_$CPU_find_event[1].eventid," Found!"
  else
    write "<!> Failed - Event Message not received for Load Abort command."
  endif
enddo

wait 5

write ";*********************************************************************"
write ";  Step 6.0: Clean-up - Send the Processor Reset command.             "
write ";*********************************************************************"
/$SC_$CPU_ES_PROCESSORRESET
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
write ";  End procedure $SC_$CPU_ds_resetnocds"
write ";*********************************************************************"
ENDPROC
