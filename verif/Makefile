# Makefile
# We assume that everything is run from the verif dir

DESIGN_DIR := ../hdl
VERIF_DIR := ../verif
PYTHON_MODELS_DIR := ../model
FILTERS_DIR := ../filters
# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

COCOTB_HDL_TIMEUNIT=1us
COCOTB_HDL_TIMEPRECISION=1ps

VERILOG_SOURCES += $(PWD)/$(FILTERS_DIR)/CIC_filter.v
VERILOG_SOURCES += $(PWD)/$(FILTERS_DIR)/FIR_comb.v
VERILOG_SOURCES += $(PWD)/$(DESIGN_DIR)/sdm_adc.sv
VERILOG_SOURCES += $(PWD)/$(DESIGN_DIR)/sdm_dac_1st.sv
VERILOG_SOURCES += $(PWD)/$(DESIGN_DIR)/sdm_dac_2nd.sv
VERILOG_SOURCES += $(PWD)/$(DESIGN_DIR)/avg_filter.sv
#VERILOG_SOURCES += $(PWD)/$(DESIGN_DIR)/downsample.sv
VERILOG_SOURCES += $(PWD)/$(DESIGN_DIR)/top.sv

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = top

# MODULE is the basename of the Python test file
MODULE = simple_top_tb

# Append the define parameter to SIM_ARGS
COMPILE_ARGS += -DORDER=$(ORDERA)

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
