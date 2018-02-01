PROC $sc_$cpu_lc_adt2
;*******************************************************************************
;  Test Name:  lc_adt2
;  Test Level: Build Verification
;  Test Type:  Functional
;
;  Test Description
;	The purpose of this procedure is to generate the ActionPoint Definition
;	Table (ADT). 
;       Note that the message ids used are borrowed from the other CFS 
;	applications (MM, FM, MD, and SCH). 
;
;  Adt2:  Used by TableTesting and Initialization procedures.  
;         Contains 9 APs, uses all event types and RPN operators;  
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
;     09/27/12          W.Moleski	Initial release for LCX
;     05/10/17          W. Moleski      Updated to use CPU1 for commanding and
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
;  Expected Test Results and Analysis
;
;**********************************************************************
local logging = %liv (log_procedure)
%liv (log_procedure) = FALSE

#include "ut_statusdefs.h"
#include "ut_cfe_info.h"
#include "cfe_platform_cfg.h"
#include "lc_platform_cfg.h"
#include "lc_msgdefs.h"
#include "lc_tbldefs.h"
#include "lc_events.h"

write ";*********************************************************************"
write ";  define local variables "
write ";*********************************************************************"

LOCAL entry
LOCAL i
LOCAL appid
LOCAL RTS1
LOCAL RTS2
LOCAL RTS3
LOCAL RTS4
LOCAL RTS5
LOCAL RTS6
LOCAL RTS7
LOCAL RTS8
LOCAL RTS9
LOCAL RTS10
local ADTTblName = LC_APP_NAME & ".LC_ADT"
local hostCPU = "$CPU"

;; CPU1 is the default
appid = 0xfb6
;; Use CPU3 IDs
RTS1 = 0xa9d
RTS2 = 0xaa0
RTS3 = 0xaa7
RTS4 = 0xa9e
RTS5 = 0xaa1
RTS6 = 0xaa2  
RTS7 = 0xaa4
RTS8 = 0xaa5
RTS9 = 0xaa6

if ("$CPU" = "CPU2") then
  appid = 0xfd4
  ;; Use CPU1 IDs
  RTS1 = 0x89d
  RTS2 = 0x8a0
  RTS3 = 0x8a7
  RTS4 = 0x89e
  RTS5 = 0x8a1
  RTS6 = 0x8a2
  RTS7 = 0x8a4
  RTS8 = 0x8a5
  RTS9 = 0x8a6
elseif ("$CPU" = "CPU3") then
  appid = 0xff4
  ;; Use CPU1 IDs
  RTS1 = 0x99d
  RTS2 = 0x9a0
  RTS3 = 0x9a7
  RTS4 = 0x99e
  RTS5 = 0x9a1
  RTS6 = 0x9a2
  RTS7 = 0x9a4
  RTS8 = 0x9a5
  RTS9 = 0x9a6  
endif 

write ";*********************************************************************"
write ";  Step 1.0:  Define Action Point Definition Table 1. "
write ";*********************************************************************"

; Entry 1
entry = 0
$SC_$CPU_LC_ADT[entry].DefaultState = LC_APSTATE_DISABLED
$SC_$CPU_LC_ADT[entry].RTSId = RTS1
$SC_$CPU_LC_ADT[entry].MaxPassiveEvents  = 1
$SC_$CPU_LC_ADT[entry].MaxPassFailEvents = 1
$SC_$CPU_LC_ADT[entry].MaxFailPassEvents = 1
$SC_$CPU_LC_ADT[entry].MaxFailsBefRTS = 1
$SC_$CPU_LC_ADT[entry].RPNEquation[1] = 0
$SC_$CPU_LC_ADT[entry].RPNEquation[2] = LC_RPN_EQUAL
for i = 3 to LC_MAX_RPN_EQU_SIZE do
  $SC_$CPU_LC_ADT[entry].RPNEquation[i] = 0
enddo
$SC_$CPU_LC_ADT[entry].EventType = 2
$SC_$CPU_LC_ADT[entry].EventId = LC_BASE_AP_EID + 1
$SC_$CPU_LC_ADT[entry].EventText = "AP 1 Fired RTS"

; Entry 2
entry = entry + 1
$SC_$CPU_LC_ADT[entry].DefaultState = LC_APSTATE_DISABLED
$SC_$CPU_LC_ADT[entry].RTSId = RTS2
$SC_$CPU_LC_ADT[entry].MaxPassiveEvents  = 2
$SC_$CPU_LC_ADT[entry].MaxPassFailEvents = 2
$SC_$CPU_LC_ADT[entry].MaxFailPassEvents = 2
$SC_$CPU_LC_ADT[entry].MaxFailsBefRTS = 2 
$SC_$CPU_LC_ADT[entry].RPNEquation[1] = 4
$SC_$CPU_LC_ADT[entry].RPNEquation[2] = 10
$SC_$CPU_LC_ADT[entry].RPNEquation[3] = LC_RPN_XOR
$SC_$CPU_LC_ADT[entry].RPNEquation[4] = LC_RPN_EQUAL
for i = 5 to LC_MAX_RPN_EQU_SIZE do
  $SC_$CPU_LC_ADT[entry].RPNEquation[i] = 0
enddo
$SC_$CPU_LC_ADT[entry].EventType = 4
$SC_$CPU_LC_ADT[entry].EventId = LC_BASE_AP_EID + 4
$SC_$CPU_LC_ADT[entry].EventText = "AP 2 Fired RTS"

; Entry 3
entry = entry +1
$SC_$CPU_LC_ADT[entry].DefaultState = LC_APSTATE_DISABLED
$SC_$CPU_LC_ADT[entry].RTSId = RTS3
$SC_$CPU_LC_ADT[entry].MaxPassiveEvents  = 5
$SC_$CPU_LC_ADT[entry].MaxPassFailEvents = 5
$SC_$CPU_LC_ADT[entry].MaxFailPassEvents = 5
$SC_$CPU_LC_ADT[entry].MaxFailsBefRTS = 5
$SC_$CPU_LC_ADT[entry].RPNEquation[1] = 9
$SC_$CPU_LC_ADT[entry].RPNEquation[2] = 3
$SC_$CPU_LC_ADT[entry].RPNEquation[3] = LC_RPN_NOT
$SC_$CPU_LC_ADT[entry].RPNEquation[4] = LC_RPN_OR
$SC_$CPU_LC_ADT[entry].RPNEquation[5] = LC_RPN_NOT
$SC_$CPU_LC_ADT[entry].RPNEquation[6] = LC_RPN_EQUAL
for i = 9 to LC_MAX_RPN_EQU_SIZE do
  $SC_$CPU_LC_ADT[entry].RPNEquation[i] = 0
enddo
$SC_$CPU_LC_ADT[entry].EventType = 3
$SC_$CPU_LC_ADT[entry].EventId = LC_BASE_AP_EID + 3
$SC_$CPU_LC_ADT[entry].EventText = "AP 3 Fired RTS"

; Entry 4
entry = entry + 1
$SC_$CPU_LC_ADT[entry].DefaultState = LC_APSTATE_DISABLED
$SC_$CPU_LC_ADT[entry].RTSId = RTS4
$SC_$CPU_LC_ADT[entry].MaxPassiveEvents  = 3
$SC_$CPU_LC_ADT[entry].MaxPassFailEvents = 3
$SC_$CPU_LC_ADT[entry].MaxFailPassEvents = 3
$SC_$CPU_LC_ADT[entry].MaxFailsBefRTS = 3
$SC_$CPU_LC_ADT[entry].RPNEquation[1] = 1
$SC_$CPU_LC_ADT[entry].RPNEquation[2] = 29
$SC_$CPU_LC_ADT[entry].RPNEquation[3] = LC_RPN_AND
$SC_$CPU_LC_ADT[entry].RPNEquation[4] = LC_RPN_EQUAL
for i = 5 to LC_MAX_RPN_EQU_SIZE do
  $SC_$CPU_LC_ADT[entry].RPNEquation[i] = 0
enddo
$SC_$CPU_LC_ADT[entry].EventType = 1
$SC_$CPU_LC_ADT[entry].EventId = LC_BASE_AP_EID + 2
$SC_$CPU_LC_ADT[entry].EventText = "AP 4 Fired RTS"

; Entry 5
entry = entry + 1
$SC_$CPU_LC_ADT[entry].DefaultState = LC_APSTATE_DISABLED
$SC_$CPU_LC_ADT[entry].RTSId = RTS5
$SC_$CPU_LC_ADT[entry].MaxPassiveEvents  = 4
$SC_$CPU_LC_ADT[entry].MaxPassFailEvents = 4
$SC_$CPU_LC_ADT[entry].MaxFailPassEvents = 4
$SC_$CPU_LC_ADT[entry].MaxFailsBefRTS = 4
$SC_$CPU_LC_ADT[entry].RPNEquation[1] = 20
$SC_$CPU_LC_ADT[entry].RPNEquation[2] = LC_RPN_NOT
$SC_$CPU_LC_ADT[entry].RPNEquation[3] = LC_RPN_EQUAL
for i = 4 to LC_MAX_RPN_EQU_SIZE do
  $SC_$CPU_LC_ADT[entry].RPNEquation[i] = 0
enddo
$SC_$CPU_LC_ADT[entry].EventType = 2
$SC_$CPU_LC_ADT[entry].EventId = LC_BASE_AP_EID + 5
$SC_$CPU_LC_ADT[entry].EventText = "AP 5 Fired RTS"

; Entry 6
entry = entry + 1
$SC_$CPU_LC_ADT[entry].DefaultState = LC_APSTATE_DISABLED
$SC_$CPU_LC_ADT[entry].RTSId = RTS6
$SC_$CPU_LC_ADT[entry].MaxPassiveEvents  = 6
$SC_$CPU_LC_ADT[entry].MaxPassFailEvents = 6
$SC_$CPU_LC_ADT[entry].MaxFailPassEvents = 6
$SC_$CPU_LC_ADT[entry].MaxFailsBefRTS = 6
$SC_$CPU_LC_ADT[entry].RPNEquation[1] = 2
$SC_$CPU_LC_ADT[entry].RPNEquation[2] = LC_RPN_NOT
$SC_$CPU_LC_ADT[entry].RPNEquation[3] = 28
$SC_$CPU_LC_ADT[entry].RPNEquation[4] = LC_RPN_AND
$SC_$CPU_LC_ADT[entry].RPNEquation[5] = 27
$SC_$CPU_LC_ADT[entry].RPNEquation[6] = LC_RPN_OR
$SC_$CPU_LC_ADT[entry].RPNEquation[7] = LC_RPN_EQUAL
for i = 8 to LC_MAX_RPN_EQU_SIZE do
  $SC_$CPU_LC_ADT[entry].RPNEquation[i] = 0
enddo
$SC_$CPU_LC_ADT[entry].EventType = 1
$SC_$CPU_LC_ADT[entry].EventId = LC_BASE_AP_EID + 6
$SC_$CPU_LC_ADT[entry].EventText = "AP 6 Fired RTS"

; Entry 7
entry = entry + 1
$SC_$CPU_LC_ADT[entry].DefaultState = LC_APSTATE_DISABLED
$SC_$CPU_LC_ADT[entry].RTSId = RTS7
$SC_$CPU_LC_ADT[entry].MaxPassiveEvents  = 5
$SC_$CPU_LC_ADT[entry].MaxPassFailEvents = 5
$SC_$CPU_LC_ADT[entry].MaxFailPassEvents = 5
$SC_$CPU_LC_ADT[entry].MaxFailsBefRTS = 5
$SC_$CPU_LC_ADT[entry].RPNEquation[1] = 5 
$SC_$CPU_LC_ADT[entry].RPNEquation[2] = 6
$SC_$CPU_LC_ADT[entry].RPNEquation[3] = LC_RPN_OR
$SC_$CPU_LC_ADT[entry].RPNEquation[4] = 8
$SC_$CPU_LC_ADT[entry].RPNEquation[5] = LC_RPN_AND
$SC_$CPU_LC_ADT[entry].RPNEquation[6] = 12
$SC_$CPU_LC_ADT[entry].RPNEquation[7] = LC_RPN_XOR
$SC_$CPU_LC_ADT[entry].RPNEquation[8] = LC_RPN_EQUAL
for i = 9 to LC_MAX_RPN_EQU_SIZE do
  $SC_$CPU_LC_ADT[entry].RPNEquation[i] = 0
enddo
$SC_$CPU_LC_ADT[entry].EventType = 4
$SC_$CPU_LC_ADT[entry].EventId = LC_BASE_AP_EID + 8
$SC_$CPU_LC_ADT[entry].EventText = "AP 7 Fired RTS"

; Entry 8
entry = entry + 1
$SC_$CPU_LC_ADT[entry].DefaultState = LC_APSTATE_DISABLED
$SC_$CPU_LC_ADT[entry].RTSId = RTS8
$SC_$CPU_LC_ADT[entry].MaxPassiveEvents  = 3
$SC_$CPU_LC_ADT[entry].MaxPassFailEvents = 3
$SC_$CPU_LC_ADT[entry].MaxFailPassEvents = 3
$SC_$CPU_LC_ADT[entry].MaxFailsBefRTS =  3
$SC_$CPU_LC_ADT[entry].RPNEquation[1] = 19
$SC_$CPU_LC_ADT[entry].RPNEquation[2] = LC_RPN_EQUAL
for i = 3 to LC_MAX_RPN_EQU_SIZE do
  $SC_$CPU_LC_ADT[entry].RPNEquation[i] = 0
enddo
$SC_$CPU_LC_ADT[entry].EventType = 2
$SC_$CPU_LC_ADT[entry].EventId = LC_BASE_AP_EID + 9
$SC_$CPU_LC_ADT[entry].EventText = "AP 8 Fired RTS"

; Entry 9
entry = entry + 1
$SC_$CPU_LC_ADT[entry].DefaultState = LC_APSTATE_DISABLED
$SC_$CPU_LC_ADT[entry].RTSId = RTS9
$SC_$CPU_LC_ADT[entry].MaxPassiveEvents  = 2
$SC_$CPU_LC_ADT[entry].MaxPassFailEvents = 2
$SC_$CPU_LC_ADT[entry].MaxFailPassEvents = 2
$SC_$CPU_LC_ADT[entry].MaxFailsBefRTS = 2 
$SC_$CPU_LC_ADT[entry].RPNEquation[1] = 21
$SC_$CPU_LC_ADT[entry].RPNEquation[2] = 22
$SC_$CPU_LC_ADT[entry].RPNEquation[3] = 23
$SC_$CPU_LC_ADT[entry].RPNEquation[4] = LC_RPN_NOT
$SC_$CPU_LC_ADT[entry].RPNEquation[5] = LC_RPN_XOR
$SC_$CPU_LC_ADT[entry].RPNEquation[6] = LC_RPN_AND
$SC_$CPU_LC_ADT[entry].RPNEquation[7] = LC_RPN_EQUAL
for i = 8 to LC_MAX_RPN_EQU_SIZE do
  $SC_$CPU_LC_ADT[entry].RPNEquation[i] = 0
enddo
$SC_$CPU_LC_ADT[entry].EventType = 2
$SC_$CPU_LC_ADT[entry].EventId = LC_BASE_AP_EID + 10
$SC_$CPU_LC_ADT[entry].EventText = "AP 9 Fired RTS"

;zero out the rest of the table
for entry=9 to LC_MAX_ACTIONPOINTS-1 do
  $SC_$CPU_LC_ADT[entry].DefaultState = LC_ACTION_NOT_USED
  $SC_$CPU_LC_ADT[entry].RTSId = 0
  $SC_$CPU_LC_ADT[entry].MaxPassiveEvents  = 0
  $SC_$CPU_LC_ADT[entry].MaxPassFailEvents = 0
  $SC_$CPU_LC_ADT[entry].MaxFailPassEvents = 0
  $SC_$CPU_LC_ADT[entry].MaxFailsBefRTS = 0
  for i = 1 to LC_MAX_RPN_EQU_SIZE do
    $SC_$CPU_LC_ADT[entry].RPNEquation[i] = 0
  enddo
  $SC_$CPU_LC_ADT[entry].EventType= 0
  $SC_$CPU_LC_ADT[entry].EventId = LC_BASE_AP_EID
  $SC_$CPU_LC_ADT[entry].EventText = " "
enddo 
;; Restore procedure logging
%liv (log_procedure) = logging

local maxAPIndex = LC_MAX_ACTIONPOINTS - 1
local startMnemonic = "$SC_$CPU_LC_ADT[0]"
local endMnemonic = "$SC_$CPU_LC_ADT[" & maxAPIndex & "]"

s create_tbl_file_from_cvt(hostCPU,appid,"ADTTable2","lc_def_adt2.tbl",ADTTblName,startMnemonic,endMnemonic)

write ";*********************************************************************"
write ";  End procedure $SC_$CPU_lc_adt2                                     "
write ";*********************************************************************"
ENDPROC
