/******************************************************************************/
/** \file  to_platform_cfg.h
*
*   \author Guy de Carufel (Odyssey Space Research), NASA, JSC, ER6
*
*   \brief Sample config file for TO Application with Multi device
*
*   \par Limitations, Assumptions, External Events, and Notes:
*       - Make use of the setup.sh script to move / link this file to the 
*       {MISSION_HOME}/apps/to/fsw/platform_inc folder.
*
*   \par Modification History:
*     - 2015-01-09 | Guy de Carufel | Code Started
*******************************************************************************/
    
#ifndef _TO_PLATFORM_CFG_H_
#define _TO_PLATFORM_CFG_H_

#ifdef __cplusplus
extern "C" {
#endif

/*
** Pragmas
*/

/*
** Local Defines
*/
#define TO_FRAMING_ENABLED 1

#define TO_SCH_PIPE_DEPTH  10
#define TO_CMD_PIPE_DEPTH  10
#define TO_TLM_PIPE_DEPTH  10

#define TO_NUM_CRITICAL_MIDS   3

#define TO_MAX_TBL_ENTRIES    100
#define TO_WAKEUP_TIMEOUT     500

#define TO_CONFIG_TABLENAME "to_config"
#define TO_CONFIG_FILENAME "/cf/apps/to_config.tbl"

#define TO_GROUP_NUMBER_MASK    0xFF000000
#define TO_MULTI_GROUP_MASK     0x00FFFFFF

#define TO_DEFAULT_DEST_PORT 5011 

#define TO_CF_THROTTLE_SEM_NAME "CFTOSemId"

#define TO_CUSTOM_TF_SIZE   1000
#define TO_CUSTOM_TF_OVERFLOW_SIZE TO_CUSTOM_TF_SIZE
#define TO_CUSTOM_TF_IDLE_SIZE TO_CUSTOM_TF_SIZE

#define TO_CUSTOM_NUM_CHNL      2
#define TO_CUSTOM_TF_SCID       0
#define TO_CUSTOM_TF_ERR_CTRL   0
#define TO_CUSTOM_TF_RANDOMIZE  0


/*
** Include Files
*/

/*
** Local Structure Declarations
*/

/*
** External Global Variables
*/

/*
** Global Variables
*/

/*
** Local Variables
*/

/*
** Local Function Prototypes
*/

#ifdef __cplusplus
}
#endif

#endif /* _TO_PLATFORM_CFG_H_ */

/*==============================================================================
** End of file to_platform_cfg.h
**============================================================================*/
    
