# verilog (includes SystemVerilog) or vhdl
TOPLEVEL_LANG ?= vhdl
# Simulator executable
SIM ?= ghdl

PWD=$(shell pwd)

# Name of Python cocotb testbench file
MODULE   := cocotb_tb_complex_multiply
# Name of toplevel target module in HDL file
TOPLEVEL := complex_multiply_mult4

# DUT generics/parameters (exported for test)
AWIDTH ?= 16
BWIDTH ?= 16
export AWIDTH
export BWIDTH

# Set different parameters based on target language & simulator
ifeq ($(TOPLEVEL_LANG),vhdl)
	VHDL_SOURCES = $(PWD)/../hdl/complex_multiply_mult4.vhd

	# Set VHDL DUT Generic's
	# ghdl, questa, and aldec all use SIM_ARGS with '-g' for setting generics
	ifneq ($(filter $(SIM),ghdl questa modelsim riviera activehdl),)
		SIM_ARGS += -gG_AWIDTH=$(AWIDTH) -gG_BWIDTH=$(BWIDTH)
	else ifneq ($(filter $(SIM),ius xcelium),)
		SIM_ARGS += -generic "$(TOPLEVEL):G_AWIDTH=>$(AWIDTH)" -generic "$(TOPLEVEL):G_BWIDTH=>$(BWIDTH)"
	endif

	ifeq ($(SIM),ghdl)
		EXTRA_ARGS += --std=08
		SIM_ARGS += --wave=wave.ghw
	else ifneq ($(filter $(SIM),questa modelsim riviera activehdl),)
		COMPILE_ARGS += -2008
	endif

#else ifeq($(TOPLEVEL_LANG),verilog)
	# Set verilog specific params, like: https://github.com/cocotb/cocotb/blob/master/examples/matrix_multiplier/tests/Makefile
else
	$(error "A valid language (verilog or vhdl) was not provided for TOPLEVEL_LANG=$(TOPLEVEL_LANG)")
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

# Seperate clean for GHDL specific outputs & other cocotb outputs
clean-all: clean
	rm -rf ./__pycache__
	rm -rf ./sim_build
	rm -f results.xml
	rm -f *.pstat
	rm -f *.svg
	rm -f *.o
	rm -f *.cf
	rm -f *.lst
	rm -f *.ghw
	rm -f $(TOPLEVEL)

# Profiling of test execution (copied from https://github.com/cocotb/cocotb/blob/master/examples/matrix_multiplier/tests/Makefile)
DOT_BINARY ?= dot

test_profile.pstat: sim

callgraph.svg: test_profile.pstat
	$(shell cocotb-config --python-bin) -m gprof2dot -f pstats ./$< | $(DOT_BINARY) -Tsvg -o $@

.PHONY: profile
profile:
	COCOTB_ENABLE_PROFILING=1 $(MAKE) callgraph.svg
