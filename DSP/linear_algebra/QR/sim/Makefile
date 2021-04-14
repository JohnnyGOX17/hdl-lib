## 'verilog' (includes SystemVerilog) or 'vhdl'
#TOPLEVEL_LANG ?= vhdl
## Simulator executable
#SIM ?= ghdl
#
#PWD=$(shell pwd)
#
## Name of Python cocotb testbench file
#MODULE   := cocotb_tb_QR
## Name of toplevel target module in HDL file
#TOPLEVEL := todo
#
## DUT generics/parameters (exported for test)
#ITERATIONS ?= 16
#export ITERATIONS
#
## Set different parameters based on target language & simulator
#ifeq ($(TOPLEVEL_LANG),vhdl)
#	VHDL_SOURCES = $(PWD)/../hdl/$(TOPLEVEL).vhd
#
#	# Set VHDL DUT Generic's
#	# ghdl, questa, and aldec all use SIM_ARGS with '-g' for setting generics
#	ifneq ($(filter $(SIM),ghdl questa modelsim riviera activehdl),)
#		SIM_ARGS += -gG_ITERATIONS=$(ITERATIONS)
#	else ifneq ($(filter $(SIM),ius xcelium),)
#		SIM_ARGS += -generic "$(TOPLEVEL):G_ITERATIONS=>$(ITERATIONS)"
#	endif
#
#	ifeq ($(SIM),ghdl)
#		EXTRA_ARGS += --std=08
#		SIM_ARGS += --wave=wave.ghw
#	else ifneq ($(filter $(SIM),questa modelsim riviera activehdl),)
#		COMPILE_ARGS += -2008
#	endif
#
##else ifeq($(TOPLEVEL_LANG),verilog)
#	# Set verilog specific params, like: https://github.com/cocotb/cocotb/blob/master/examples/matrix_multiplier/tests/Makefile
#else
#	$(error "A valid language (verilog or vhdl) was not provided for TOPLEVEL_LANG=$(TOPLEVEL_LANG)")
#endif
#
#include $(shell cocotb-config --makefiles)/Makefile.sim

# Seperate clean for GHDL specific outputs & other cocotb outputs
#clean-all: clean
clean-all:
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
	rm -f tb_$(TOPLEVEL)
	rm -f tb_boundary_cell

ghdl-bc:
	ghdl -a --std=08 $(PWD)/../../../CORDIC/vectoring_mode/hdl/cordic_vec.vhd $(PWD)/../hdl/boundary_cell.vhd $(PWD)/tb_boundary_cell.vhd
	ghdl -e --std=08 tb_boundary_cell
	ghdl -r tb_boundary_cell --wave=output.ghw
	gtkwave output.ghw

# Profiling of test execution (copied from https://github.com/cocotb/cocotb/blob/master/examples/matrix_multiplier/tests/Makefile)
DOT_BINARY ?= dot

test_profile.pstat: sim

callgraph.svg: test_profile.pstat
	$(shell cocotb-config --python-bin) -m gprof2dot -f pstats ./$< | $(DOT_BINARY) -Tsvg -o $@

.PHONY: profile
profile:
	COCOTB_ENABLE_PROFILING=1 $(MAKE) callgraph.svg
