
# Cocotb
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, FallingEdge, ClockCycles, ReadOnly
from cocotb.triggers import Combine

# Cocotb-bus
from cocotb_bus.drivers import Driver
from cocotb_bus.monitors import Monitor
from cocotb_bus.scoreboard import Scoreboard

# pyuvm
from pyuvm import *

# Utils
import random
import numpy as np
import sys
import os
import matplotlib.pyplot as plt
from scipy.signal import resample
from scipy.signal import firwin, lfilter, decimate
import collections
# Adding main_repo to path to use relative imports
parent_path = os.path.abspath(os.path.join(os.path.dirname(__file__),".."))

if parent_path not in sys.path:
    sys.path.append(parent_path)

# Model
from model.SDM import convert_audio_to_sdm, sigma_delta_demodulator_fir

# Misc
sys.setrecursionlimit(10000000)

# Sequence item
class SDM_seq_item(uvm_sequence_item):
    def __init__(self, name, data, valid):
        super().__init__(name)
        self.data = data
        self.valid = valid
    
    def __str__(self) -> str:
        ''' defines output string when printing sequence item. '''
        if self.data is None:
            self.data = 0

        return (f" SDM_SEQ_ITEM | data = {self.data}, valid = {self.valid}")

# Sequence
class SDM_base_seq(uvm_sequence):
    def __init__(self, name):
        super().__init__(name)
    
    async def body(self):
        sdm_transaction = SDM_seq_item("sdm_transaction", 0, 0)
        await self.start_item(sdm_transaction)
        self.log.debug(f"SDM_BASE_SEQUENCE | CREATED ITEM: {str(sdm_transaction)}")
        await self.finish_item(sdm_transaction)

    #TODO: ADD RANDOMIZATION

# Driver
class SDM_driver(uvm_driver):
    def build_phase(self):
        self.ap = uvm_analysis_port("ap", self)

    async def run_phase(self):
        while True:
            tx_transaction_item = await self.seq_item_port.get_next_item()
            
            # Drive signals to DUT
            self.data_in.value = int(tx_transaction_item.data)
            self.valid.value = int(tx_transaction_item.valid)
            self.ap.write(tx_transaction_item)
            self.seq_item_port.item_done()

# Monitor
class SDM_monitor(uvm_component):
    def build_phase(self):
        self.ap = uvm_analysis_port("ap", self)

    async def run_phase(self):
        while True:
            rx_transaction_item = SDM_seq_item ("rx_transaction", None, None)            
            rx_transaction_item.data = int(self.data_out.value)
            rx_transaction_item.valid = int(self.valid)
            self.ap.write(rx_transaction_item)

# Scoreboard
class SDM_scoreboard(uvm_component):
    def build_phase(self):
        self.rx_fifo = uvm_tlm_analysis_fifo("rx_fifo", self)
        self.tx_fifo = uvm_tlm_analysis_fifo("tx_fifo", self)
        self.model_fifo = uvm_tlm_analysis_fifo("model_fifo", self)
        self.rx_get_port = uvm_get_port("rx_get_port", self)
        self.tx_get_port = uvm_get_port("tx_get_port", self)
        self.model_get_port = uvm_get_port("model_get_port", self)
        self.rx_export = self.rx_fifo.analysis_export
        self.tx_export = self.tx_fifo.analysis_export
        self.model_export = self.model_fifo.analysis_export

    def connect_phase(self):
        self.rx_get_port.connect(self.rx_fifo.get_export)
        self.tx_get_port.connect(self.rx_fifo.get_export)
        self.model_get_port.connect(self.model_fifo.get_export)

    def compare(self, got, exp, log, strict_type=False):
        self.val_got = got
        self.val_exp = exp
        self.averaged_got = np.convolve(self.val_got, np.ones(256)/256, mode='valid') * 2 - 1
        self.averaged_exp = np.convolve(self.val_exp, np.ones(256)/256, mode='valid') * 2 - 1
        if np.average(np.abs(self.averaged_exp - self.averaged_got)) >= 0.1:
            return False
        return True

    def report(self, input_data):
        self.log.debug(f"Len got: {len(self.val_got)}, got: {self.val_got}, type: {type(self.val_got)}; Len exp: {len(self.val_exp)}, exp: {self.val_exp}, type: {type(self.val_exp)}")
        num_of_elements = np.arange(len(self.val_got))
        num_of_elements_input = np.arange(len(input_data))
        int_input = list(map(int, input_data))
        
        num_of_elements_avg = np.arange(len(self.averaged_got))


        fig, axs = plt.subplots(2,3) # Two rows and three cols
        axs[0, 0].plot(num_of_elements, self.val_got, color='r', label='dut', alpha=0.7, linestyle='-')
        axs[0, 0].set_title('DUT')
        axs[1, 0].plot(num_of_elements, self.val_exp, color='b', label='model', alpha=0.7, linestyle='-')
        axs[1, 0].set_title('Model')

        axs[0, 1].plot(num_of_elements_input, input_data, color='b', label='model', alpha=0.7, linestyle='-')
        axs[0, 1].set_title('input dut')
        axs[1, 1].plot(num_of_elements_input, int_input, color='b', label='model', alpha=0.7, linestyle='-')
        axs[1, 1].set_title('input model')

        axs[0, 2].plot(num_of_elements_avg, self.averaged_got, color='b', label='model', alpha=0.7, linestyle='-')
        axs[0, 2].set_title('avg filtered dut')
        axs[1, 2].plot(num_of_elements_avg, self.averaged_exp, color='b', label='model', alpha=0.7, linestyle='-')
        axs[1, 2].set_title('avg filtered model')
        plt.show()


# Scoreboard
class MyScoreboard(uvm_component):
    def compare_results(self, actual, expected):
        assert actual == expected, f"Mismatch: {actual} != {expected}"

# Environment
class MyEnv(uvm_env):
    def build_phase(self):
        self.driver = MyDriver("driver", self)
        self.monitor = MyMonitor("monitor", self)
        self.scoreboard = MyScoreboard("scoreboard", self)

# Test
class MyTest(uvm_test):
    def build_phase(self):
        self.env = MyEnv("env", self)

    async def run_phase(self):
        await self.raise_objection()
        # Sequence or stimulus generation
        self.drop_objection()
