# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0


 
PWDD := $(shell pwd)
BLOCKS := $(shell basename $(PWDD))
SRC_DIR := $(addsuffix /src,$(PWDD))
SRC_FILES := $(wildcard src/*.c)
OBJ_FILES := $(notdir $(SRC_FILES:.c=.o))

# ---- Include Partitioned Makefiles ----

CONFIG = caravel_user_project


include $(MCW_ROOT)/verilog/dv/make/env.makefile
include $(MCW_ROOT)/verilog/dv/make/var.makefile
include $(MCW_ROOT)/verilog/dv/make/cpu.makefile
# include $(MCW_ROOT)/verilog/dv/make/sim.makefile

# Manually include sim.makefile

export IVERILOG_DUMPER = fst

# RTL/GL/GL_SDF
SIM?=RTL


.SUFFIXES: .o .c


all:  clean $(OBJ_FILES) ${BLOCKS:=.vcd} ${BLOCKS:=.lst}
	@echo -e "${PURPLE} - Moving build files to $(PWDD)/build${RESET}"
	@mv -f *.elf *.hex *.vvp *.vcd *.lst *.hexe *.o ./build/

hex:  ${BLOCKS:=.hex}

#.SUFFIXES:

##############################################################################
# Build rules for object files
##############################################################################

### Set colors because I like pretty colors
BLUE  =\033[0;34m
PURPLE=\033[0;35m
GREEN =\033[0;32m
RED   =\033[0;31m
ORANGE=\033[0;33m
CYAN  =\033[0;36m
RESET =\033[0m

%.o : src/%.c
	@echo -e "${CYAN} - Building object: $(shell basename $@)${RESET}"
	@${GCC_PATH}/${GCC_PREFIX}-gcc -g \
	-I$(FIRMWARE_PATH) \
	-I$(VERILOG_PATH)/dv/generated \
	-I$(VERILOG_PATH)/dv/ \
	-I$(VERILOG_PATH)/common \
	-I$(PWDD)/src \
	  $(CPUFLAGS) \
	-Wl,-Bstatic,-T,--strip-debug \
	-ffreestanding -nostdlib -c -o $@ $<

##############################################################################
# Compile firmeware
##############################################################################

%.elf: %.c $(LINKER_SCRIPT) $(SOURCE_FILES) $(OBJ_FILES)
	@echo -e "${ORANGE} - Building binary: $(shell basename $@)${RESET}"
	@${GCC_PATH}/${GCC_PREFIX}-gcc -g \
	-I$(FIRMWARE_PATH) \
	-I$(VERILOG_PATH)/dv/generated \
	-I$(VERILOG_PATH)/dv/ \
	-I$(VERILOG_PATH)/common \
	-I$(PWDD) \
	-I$(PWDD)/src \
	  $(CPUFLAGS) \
	-Wl,-Bstatic,-T,$(LINKER_SCRIPT),--strip-debug \
	-ffreestanding -nostdlib -o $@ $(SOURCE_FILES) $(OBJ_FILES) $<

%.lst: %.elf
	@echo -e "${ORANGE} - Dumping binary: $(shell basename $@)${RESET}"
	@${GCC_PATH}/${GCC_PREFIX}-objdump -d -S $< > $@

%.hex: %.elf
	@echo -e "${ORANGE} - Generating firmware: $(shell basename $@)${RESET}"
	@${GCC_PATH}/${GCC_PREFIX}-objcopy -O verilog $< $@ 
	@# to fix flash base address
	@sed -ie 's/@10/@00/g' $@

%.bin: %.elf
	${GCC_PATH}/${GCC_PREFIX}-objcopy -O binary $< /dev/stdout | tail -c +1048577 > $@
	
	
##############################################################################
# Runing the simulations
##############################################################################

%.vvp: %_tb.v %.hex
	@echo -e "${GREEN} - Simulating ($(SIM))${RESET}"

## RTL
ifeq ($(SIM),RTL)
    ifeq ($(CONFIG),caravel_user_project)
		@iverilog -Ttyp -DFUNCTIONAL -DSIM -DUSE_POWER_PINS -DUNIT_DELAY=#1 \
        -f$(VERILOG_PATH)/includes/includes.rtl.caravel \
        -f$(USER_PROJECT_VERILOG)/includes/includes.rtl.$(CONFIG) -o $@ $<
    else
		@iverilog -Ttyp -DFUNCTIONAL -DSIM -DUSE_POWER_PINS -DUNIT_DELAY=#1 \
		-f$(VERILOG_PATH)/includes/includes.rtl.$(CONFIG) \
		-f$(CARAVEL_PATH)/rtl/__user_project_wrapper.v -o $@ $<
    endif
endif 

## GL
ifeq ($(SIM),GL)
    ifeq ($(CONFIG),caravel_user_project)
		@iverilog -Ttyp -DFUNCTIONAL -DGL -DUSE_POWER_PINS -DUNIT_DELAY=#1 \
        -f$(VERILOG_PATH)/includes/includes.gl.caravel \
        -f$(USER_PROJECT_VERILOG)/includes/includes.gl.$(CONFIG) -o $@ $<
    else
		@iverilog -Ttyp -DFUNCTIONAL -DGL -DUSE_POWER_PINS -DUNIT_DELAY=#1 \
        -f$(VERILOG_PATH)/includes/includes.gl.$(CONFIG) \
		-f$(CARAVEL_PATH)/gl/__user_project_wrapper.v -o $@ $<
    endif
endif 

## GL+SDF
ifeq ($(SIM),GL_SDF)
    ifeq ($(CONFIG),caravel_user_project)
		@cvc64  +interp \
		+define+SIM +define+FUNCTIONAL +define+GL +define+USE_POWER_PINS +define+UNIT_DELAY +define+ENABLE_SDF \
		+change_port_type +dump2fst +fst+parallel2=on   +nointeractive +notimingchecks +mipdopt \
		-f $(VERILOG_PATH)/includes/includes.gl+sdf.caravel \
		-f $(USER_PROJECT_VERILOG)/includes/includes.gl+sdf.$(CONFIG) $<
	else
		@cvc64  +interp \
		+define+SIM +define+FUNCTIONAL +define+GL +define+USE_POWER_PINS +define+UNIT_DELAY +define+ENABLE_SDF \
		+change_port_type +dump2fst +fst+parallel2=on   +nointeractive +notimingchecks +mipdopt \
		-f $(VERILOG_PATH)/includes/includes.gl+sdf.$(CONFIG) \
		-f $CARAVEL_PATH/gl/__user_project_wrapper.v $<
    endif
endif

%.vcd: %.vvp

ifeq ($(SIM),RTL)
	vvp  $<
	@mv $@ RTL-$@
endif
ifeq ($(SIM),GL)
	vvp  $<
	@mv $@ GL-$@
endif
ifeq ($(SIM),GL_SDF)
	@mv $@ GL_SDF-$@
endif
	@echo -e "${GREEN} - Dumping waveform: $(SIM)-$@${RESET}"

# twinwave: RTL-%.vcd GL-%.vcd
#     twinwave RTL-$@ * + GL-$@ *

check-env:
ifndef PDK_ROOT
	$(error PDK_ROOT is undefined, please export it before running make)
endif
ifeq (,$(wildcard $(PDK_ROOT)/$(PDK)))
	$(error $(PDK_ROOT)/$(PDK) not found, please install pdk before running make)
endif
ifeq (,$(wildcard $(GCC_PATH)/$(GCC_PREFIX)-gcc ))
	$(error $(GCC_PATH)/$(GCC_PREFIX)-gcc is not found, please export GCC_PATH and GCC_PREFIX before running make)
endif
# check for efabless style installation
ifeq (,$(wildcard $(PDK_ROOT)/$(PDK)/libs.ref/*/verilog))
SIM_DEFINES := ${SIM_DEFINES} -DEF_STYLE
endif


# ---- Clean ----

clean:
	@echo -e "${PURPLE} - Cleaning build directory${RESET}"
	@rm  -f *.elf *.hex *.bin *.vvp *.log *.vcd *.lst *.hexe *.o
	@rm -rf build
	@mkdir build

.PHONY: clean hex all

#-------------------------------------------------------------------------
# Makefile debugging
#-------------------------------------------------------------------------
# This handy rule will display the contents of any make variable by
# using the target debug-<varname>. So for example, make debug-junk will
# display the contents of the junk variable.

debug-% :
	@echo $* = $($*)


