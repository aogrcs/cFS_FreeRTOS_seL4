# frama-c-path.mk contains variables which are specific to each
# user and should not be versioned, such as the path to the
# frama-c binaries (e.g. FRAMAC and FRAMAC_GUI).
# It is an optional include, unnecessary if frama-c is in the PATH.
-include frama-c-path.mk

FRAMAC_CONFIG ?= frama-c-config
include $(shell $(FRAMAC_CONFIG) -print-share-path)/analysis-scripts/frama-c.mk

# Define global parameters
CPPFLAGS     = -I$(OSAL_SRC)/inc \
-I$(CFE_CORE_SRC)/inc \
-I$(CFE_PSP_SRC)/inc \
-I$(CFE_PSP_SRC)/$(PSP)/inc \
-I$(CFS_APP_SRC)/inc \
-I$(CFS_APP_SRC)/$(APPTARGET)/fsw/src \
-I$(CFS_APP_SRC)/$(APPTARGET)/fsw/src/PRI \
-I$(CFS_APP_SRC)/$(APPTARGET)/fsw/src/PUB \
-I$(CFS_MISSION_INC) \
-I../cfe/inc \
-I../fsw/platform_inc \
-I/home/simulink/cFS_FreeRTOS_seL4/apps/cf/fsw/src/ \
-I/home/simulink/cFS_FreeRTOS_seL4/apps/cf/fsw/src/PUB \
-I/home/simulink/cFS_FreeRTOS_seL4/apps/cf/fsw/platform_inc \
-I/home/simulink/cFS_FreeRTOS_seL4/apps/cf/fsw/mission_inc \
-I/home/simulink/cFS_FreeRTOS_seL4/build/cpu1/inc \
-I/home/simulink/cFS_FreeRTOS_seL4/psp/fsw/mcf5235-rtems/inc

FCFLAGS     +=
EVAFLAGS    += -slevel 500 -no-val-malloc-returns-null 
# EVAFLAGS    += $(shell cat main.slevel | tr '\\' ' ')

export FRAMA_C_MEMORY_FOOTPRINT = 8

all: main.eva
main.parse: ../src/*.c
