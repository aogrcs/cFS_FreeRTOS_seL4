##
## cfe-config.mak
##
## This file specifies the OS, and PSP to build for the cFE.
##
## NOTE: Make sure each selection does not have any spaces
##       after it!
##
##---------------------------------------------------------
## Possible Settings
##
##  OS          PSP
##
##  posix       pc-linux            (fully supported)
##  rtems       mcf5235-rtems       (fully supported)
##  vxworks6    rad750-vxworks6.4   (fully supported)
##  vxworks6    mcp750-vxworks6.4   (fully supported)
##  seL4        tx2-seL4-7.0.0      (20180110 just for test now)
##  FreeRTOS    pc-FreeRTOS         (20180113 just for test now)
##
## NOTE: Please check the debug-opts.mak file to ensure
##       that the options are correct for your settings
##---------------------------------------------------------

##---------------------------------------------------------
## Operating System
## OS = The operating system selected for the Abstraction implementation
##---------------------------------------------------------
## OS = FreeRTOS
OS = posix
##20180110 test for rtems

##---------------------------------------------------------
## PSP -- CFE Platform Support Package
##---------------------------------------------------------
PSP = pc-linux
## PSP = mcf5235-rtems ##20180110 test for rtems

##---------------------------------------------------------
## BSP -- OSAL BSP/Operating system for the board
##
## Required when building OSAL Unit Tests.
##
## Current selections include:
## 
## BSP = pc-linux-ut         -- Unit test target
## BSP = pc-linux            -- Target to run on PC-linux
## BSP = genppc-vxworks6.4   -- vxWorks Power PC target
## BSP = mcf5235-rtems       -- RTEMS Coldfire evaluation board
## BSP = sis-rtems           -- RTEMS Sparc Instruction Simulator (GDB)
## BSP = tx2-seL4            -- seL4  tx2(20180110 just for test now)
##---------------------------------------------------------
BSP = pc-linux
## BSP = mcf5235-rtems ##20180110 test for rtems
