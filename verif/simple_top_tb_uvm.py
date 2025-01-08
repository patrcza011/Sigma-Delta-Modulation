
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

class SDM_model_wrapper():
    def __init__(self, periods=2, samples_per_period=20, target_rate=2822400, frequency=1):
        self.periods = periods
        self.samples_per_period = samples_per_period
        self.frequency = frequency
        self.target_rate = target_rate
        self.generate_audio_data()

    def generate_audio_data(self):
        # Calculate the duration for periods
        self.duration = self.periods / self.frequency

        # Total number of samples
        self.total_samples = self.periods * self.samples_per_period

        # Time array with 5 samples per period
        self.time = np.linspace(0, self.duration, int(self.total_samples), endpoint=False)
        print(f"time: {self.time}, len: {len(self.time)}")

        # Generate sine wave with the desired properties
        #self.audio_data = (0.9 * np.sin(2 * np.pi * self.frequency * self.time) * 32767).astype(dtype='int16')

        self.audio_data = (0.5 * np.sin(2 * np.pi * self.frequency * self.time) * 32767).astype(dtype='int16')
        return self.audio_data

    def generate_data(self, audio_data):
        print(f"audio_data: {audio_data}, len: {len(audio_data)}")
        # Convert to SDM signal
        self.sdm_signal = convert_audio_to_sdm(audio_data, self.total_samples, self.target_rate)

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
        print(f"SDM_BASE_SEQUENCE | CREATED ITEM: {str(sdm_transaction)}")
        await self.finish_item(sdm_transaction)

    #TODO: ADD RANDOMIZATION

class SDM_sinus_sequence(uvm_sequence):
    def __init__(self, name):
        super().__init__(name)

    async def body(self):
        model = SDM_model_wrapper()
        self.audio_data = model.generate_audio_data()
        for audio_chunk in self.audio_data:
            sdm_transaction = SDM_seq_item("sdm_transaction", audio_chunk, 1)
            await self.start_item(sdm_transaction)
            print(f"SDM_BASE_SEQUENCE | CREATED ITEM: {str(sdm_transaction)}")
            await self.finish_item(sdm_transaction)

# Driver
class SDM_driver(uvm_driver):
    def __init__(self, clk, name, parent):
        super().__init__(name, parent)
        self.clkc = clk

    def connect_phase(self):
        print(f"SDM_DRIVER | CONNECT_PHASE")
        self.valid = cocotb.top.valid_in_dac1
        self.data_in = cocotb.top.audio_in1
        #self.clk = cocotb.top.dummy_clk
        self.clk = cocotb.top.dummy_clk

    def build_phase(self):
        print(f"SDM_DRIVER | BUILD_PHASE")
        self.ap = uvm_analysis_port("ap", self)

    async def run_phase(self):
        print(f"SDM_DRIVER | RUN_PHASE")
        while True:
            print(f"SDM_DRIVER | BEFORE WAIT FOR DUMMY_CLK")
            #await cocotb.triggers.RisingEdge(self.clk)
            print(f"SDM_DRIVER | AFTER WAIT FOR DUMMY_CLK")
            tx_transaction_item = await self.seq_item_port.get_next_item()
            print(f"SDM_DRIVER | AFTER WAIT FOR self.seq_item_port.get_next_item")
            # Drive signals to DUT
            self.valid.value = int(tx_transaction_item.valid)
            self.data_in.value = int(tx_transaction_item.data)
            self.ap.write(tx_transaction_item)
            self.seq_item_port.item_done()

# Monitor
class SDM_monitor(uvm_component):
    def build_phase(self):
        print(f"SDM_MONITOR | BUILD_PHASE")
        self.ap = uvm_analysis_port("ap", self)

    def connect_phase(self):
        print(f"SDM_MONITOR | CONNECT_PHASE")
        self.data_out = cocotb.top.sdm_out1
        self.valid = cocotb.top.valid_out_dac1
        self.clk = cocotb.top.clk


    async def run_phase(self):
        print(f"SDM_MONITOR | RUN_PHASE")
        while True:
            rx_transaction_item = SDM_seq_item ("rx_transaction", None, None)
            rx_transaction_item.data = self.data_out.value
            rx_transaction_item.valid = self.valid
            self.ap.write(rx_transaction_item)

# Scoreboard
class SDM_scoreboard(uvm_component):
    def build_phase(self):
        print(f"SDM_SCOREBOARD | BUILD_PHASE")
        self.rx_fifo = uvm_tlm_analysis_fifo("rx_fifo", self)
        self.tx_fifo = uvm_tlm_analysis_fifo("tx_fifo", self)
        self.rx_get_port = uvm_get_port("rx_get_port", self)
        self.tx_get_port = uvm_get_port("tx_get_port", self)
        self.rx_export = self.rx_fifo.analysis_export
        self.tx_export = self.tx_fifo.analysis_export
        self.received_audio_data = []
        self.received_sdm_data = []

    def connect_phase(self):
        print(f"SDM_SCOREBOARD | CONNECT_PHASE")
        self.rx_get_port.connect(self.rx_fifo.get_export)
        self.tx_get_port.connect(self.rx_fifo.get_export)

    def check_phase(self):
        print(f"SDM_SCOREBOARD | CHECK_PHASE")
        while self.rx_get_port.can_get():
            self.received_sdm_data.append(self.rx_get_port.try_get())

        while self.tx_get_port.can_get():
            self.received_audio_data.append(self.tx_get_port.try_get())
        model = SDM_model_wrapper()
        model_data = model.generate_data(self.received_audio_data)
        self.compare(self.received_sdm_data, model.sdm_signal)
        self.report(self.received_audio_data)

    def compare(self, got, exp, log, strict_type=False):
        self.val_got = got
        self.val_exp = exp
        self.averaged_got = np.convolve(self.val_got, np.ones(256)/256, mode='valid') * 2 - 1
        self.averaged_exp = np.convolve(self.val_exp, np.ones(256)/256, mode='valid') * 2 - 1
        if np.average(np.abs(self.averaged_exp - self.averaged_got)) >= 0.1:
            return False
        return True

    def report(self, input_data):
        print(f"Len got: {len(self.val_got)}, got: {self.val_got}, type: {type(self.val_got)}; Len exp: {len(self.val_exp)}, exp: {self.val_exp}, type: {type(self.val_exp)}")
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


# Environment
class SDM_env(uvm_env):
    def build_phase(self):
        self.seqr = uvm_sequencer("seqr", self)
        dummy_clk_ = cocotb.top.dummy_clk
        cocotb.start_soon(Clock(dummy_clk_, 22675.73, units='ns').start())
        self.driver = SDM_driver(dummy_clk_, "driver", self)
        self.monitor = SDM_monitor("monitor", self)
        self.scoreboard = SDM_scoreboard("scoreboard", self)

    def connect_phase(self):
        self.driver.seq_item_port.connect(self.seqr.seq_item_export)
        self.monitor.ap.connect(self.scoreboard.rx_export)
        self.driver.ap.connect(self.scoreboard.tx_export)

# Test
@test()
class SDM_base_test(uvm_test):
    def build_phase(self):
        self.env = SDM_env("env", self)
        self.seq = SDM_sinus_sequence.create("sin_stimulus")

    async def run_phase(self):
        await self.raise_objection()
        dummy_clk = cocotb.top.dummy_clk
        cocotb.start_soon(Clock(dummy_clk, 22675.73, units='ns').start())
        # Sequence or stimulus generation
        self.drop_objection()
