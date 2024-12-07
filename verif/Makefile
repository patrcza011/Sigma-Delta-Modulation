# Makefile

# We assume that everything is run from the verif dir

DESIGN_DIR := ../hdl
VERIF_DIR := ../verif
PYTHON_MODELS_DIR := ../model
# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/$(DESIGN_DIR)/sdm_modulator.sv
VERILOG_SOURCES += $(PWD)/$(DESIGN_DIR)/filter.sv
VERILOG_SOURCES += $(PWD)/$(DESIGN_DIR)/sdm_demodulator.sv
VERILOG_SOURCES += $(PWD)/$(DESIGN_DIR)/downsample.sv
VERILOG_SOURCES += $(PWD)/$(DESIGN_DIR)/top.sv

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = top

# MODULE is the basename of the Python test file
MODULE = simple_top_tb

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim