# Cocotb
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, FallingEdge, ClockCycles, ReadOnly

# Cocotb-bus
from cocotb_bus.drivers import Driver
from cocotb_bus.monitors import Monitor
from cocotb_bus.scoreboard import Scoreboard

# Utils
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
# TODO: SIGMA DELtA DRUGIEgo RZEDU 

class SDM_transaction:
    def __init__(self, data=[], valid=0):
        self.data = data
        self.valid = valid

    def __str__(self):
        return f"data: {self.data}, valid: {self.valid}"

class SDM_driver(Driver):
    def __init__(self, clk, data_in, valid_in):
        super().__init__()
        self.clk = clk
        self.data_in = data_in
        self.valid_in = valid_in
    
    async def _driver_send(self, sdm_transaction, sync=False):
        self.valid_in.value = 1#sdm_transaction.valid
        for val in sdm_transaction:
            self.data_in.value = int(val)
            await RisingEdge(self.clk)
        self.valid_in.value = 0

class SDM_reset_driver(Driver):
    def __init__(self, clk, reset_in):
        super().__init__()
        self.clk = clk
        self.reset_in = reset_in
    
    async def _driver_send(self, duration, sync=False):
        self.reset_in.value = 0
        await Timer(duration, units='ns')
        self.reset_in.value = 1
        await RisingEdge(self.clk)

class SDM_monitor(Monitor):
    def __init__(self, clk, name, data_out, valid_out, num_of_probes, callback=None, event=None):
        self.clk = clk
        self.name = name
        self.data_out = data_out
        self.valid_out = valid_out
        self.num_of_probes = num_of_probes
        self.trans = SDM_transaction()
        self.temp_list_of_probes = []
        super().__init__(callback=callback, event=event)

    async def _monitor_recv(self):
        while True:
            await RisingEdge(self.valid_out)
            await ReadOnly()
            for _ in range(self.num_of_probes):
                await ReadOnly()
                self.temp_list_of_probes.append(int(self.data_out.value))
                await RisingEdge(self.clk)
            self._recv(self.temp_list_of_probes)


class SDM_scoreboard(Scoreboard):
    def __init__(self, dut, reorder_depth=0, fail_immediately=False):  # FIXME: reorder_depth needed here?
        super().__init__(dut, reorder_depth, fail_immediately)
        self.val_got = []
        self.val_exp = []
    
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
        

class SDM_model_wrapper():
    def __init__(self, periods=2, samples_per_period=20, target_rate=2822400, frequency=1):
        self.periods = periods
        self.samples_per_period = samples_per_period
        self.frequency = frequency
        self.target_rate = target_rate
        self.generate_data()

    def generate_data(self):
        # Calculate the duration for periods
        self.duration = self.periods / self.frequency
        
        # Total number of samples
        self.total_samples = self.periods * self.samples_per_period
        
        # Time array with 5 samples per period
        self.time = np.linspace(0, self.duration, int(self.total_samples), endpoint=False)
        self.log.debug(f"time: {self.time}, len: {len(self.time)}")
        
        # Generate sine wave with the desired properties
        #self.audio_data = (0.9 * np.sin(2 * np.pi * self.frequency * self.time) * 32767).astype(dtype='int16')
        
        self.audio_data = (0.5 * np.sin(2 * np.pi * self.frequency * self.time) * 32767).astype(dtype='int16')
        self.log.debug(f"audio_data: {self.audio_data}, len: {len(self.audio_data)}")
        # Convert to SDM signal
        self.sdm_signal = convert_audio_to_sdm(self.audio_data, self.total_samples, self.target_rate)

@cocotb.test()
async def functionality(top):
    duration = 1.0  # 1 second
    duration2 = 0.1
    sdm_signal_from_design = []    
    
    model = SDM_model_wrapper()

    cocotb.start_soon(Clock(top.clk, 354.6, units='ns').start())
    cocotb.start_soon(Clock(top.dummy_clk, 22675.73, units='ns').start())

    rst_drv = SDM_reset_driver(top.clk, top.rst_n)
    drv = SDM_driver(top.dummy_clk, top.audio_in1, top.valid_in_dac1)
    mon = SDM_monitor(top.clk, "mon", top.sdm_out1, top.valid_out_dac1, num_of_probes=len(model.sdm_signal), callback=None)
    scb = SDM_scoreboard(top, fail_immediately=False)
    scb.add_interface(mon, [model.sdm_signal], reorder_depth=0)

    await rst_drv.send(500)
    await drv.send(model.audio_data)
    await mon.wait_for_recv()
    scb.report(model.audio_data)
