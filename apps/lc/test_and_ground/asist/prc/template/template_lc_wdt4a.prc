PROC $sc_$cpu_lc_wdt4a
;*******************************************************************************
;  Test Name:  lc_wdt4
;  Test Level: Build Verification
;  Test Type:  Functional
;
;  Test Description
;	The purpose of this procedure is to generate the WatchPoint Definition
;	Table (WDT) containing one WatchPoint containing an offset that is
;       beyond the end of the packet data.
;
;	Note that the message id used is borrowed from the xxx CFS application.
;
;  Requirements Tested
;       None
;
;  Prerequisite Conditions
;	The cFE is up and running and ready to accept commands.	
;       The LC commands and TLM items exist in the GSE database. 
;	A display page exists for the LC Housekeeping telemetry packet
;       LC Test application loaded and running;
;
;  Assumptions and Constraints
;	None.
;
;  Change History
;
;	Date		   Name		Description
;      08/10/12         W. Moleski      Initial release for LCX
;       05/10/17        W. Moleski      Updated to use CPU1 for commanding and
;                                       added a hostCPU variable for the utility
;                                       procs to connect to the proper host.
;
;  Arguments
;	None.
;
;  Procedures Called
;	Name			 Description
;       create_tbl_file_from_cvt Procedure that creates a load file from
;                                the specified arguments and cvt
;                                
;
;  Expected Test Results and Analysis
;
;**********************************************************************
local logging = %liv (log_procedure)
%liv (log_procedure) = FALSE

#include "ut_statusdefs.h"
#include "ut_cfe_info.h"
#include "lc_platform_cfg.h"
#include "lc_tbldefs.h"

write ";*********************************************************************"
write ";  define local variables "
write ";*********************************************************************"

LOCAL entry
LOCAL apid
LOCAL MessageID
local hostCPU = "$CPU"

;; CPU1 is the default
apid = 0xfb7
;; Use CPU2 Message ID
MessageID = 0x989

write ";*********************************************************************"
write ";  Define the Watch Point Definition Table "
write ";*********************************************************************"
;; Setup the first entry
$SC_$CPU_LC_WDT[0].DataType = LC_DATA_WORD_BE
$SC_$CPU_LC_WDT[0].OperatorID = LC_OPER_NE
$SC_$CPU_LC_WDT[0].MessageID = MessageID
$SC_$CPU_LC_WDT[0].WPOffset = 45
$SC_$CPU_LC_WDT[0].Bitmask = 0xFFFFFFFF
;;$SC_$CPU_LC_WDT[0].ComparisonValue.Signed32 = 0x00001345
$SC_$CPU_LC_WDT[0].ComparisonValue.Signed16 = 0x1345
$SC_$CPU_LC_WDT[0].CustFctArgument = 0
$SC_$CPU_LC_WDT[0].StaleAge = 0

; zero out all but the first watchpoint
for entry = 1 to LC_MAX_WATCHPOINTS-1 do
  $SC_$CPU_LC_WDT[entry].DataType = LC_WATCH_NOT_USED
  $SC_$CPU_LC_WDT[entry].OperatorID = LC_NO_OPER
  $SC_$CPU_LC_WDT[entry].MessageID = 0
  $SC_$CPU_LC_WDT[entry].WPOffset = 0
  $SC_$CPU_LC_WDT[entry].Bitmask = 0xFFFFFFFF
  $SC_$CPU_LC_WDT[entry].ComparisonValue.Signed32 = 0
  $SC_$CPU_LC_WDT[entry].CustFctArgument = 0
  $SC_$CPU_LC_WDT[0].StaleAge = 0
enddo

;; Restore procedure logging
%liv (log_procedure) = logging
 
local wpIndex = LC_MAX_WATCHPOINTS - 1
local startMnemonic = "$SC_$CPU_LC_WDT[0]"
local endMnemonic = "$SC_$CPU_LC_WDT[" & wpIndex & "]"
local tableName = LC_APP_NAME & ".LC_WDT"

s create_tbl_file_from_cvt(hostCPU,apid,"WDTTable4a","lc_def_wdt4a.tbl",tableName,startMnemonic,endMnemonic)

write ";*********************************************************************"
write ";  End procedure $SC_$CPU_lc_wdt4a                                    "
write ";*********************************************************************"
ENDPROC
