# Cocotb
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, FallingEdge, ClockCycles

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
# Adding main_repo to path to use relative imports
parent_path = os.path.abspath(os.path.join(os.path.dirname(__file__),".."))

if parent_path not in sys.path:
    sys.path.append(parent_path)
# Model
from model.SDM import convert_audio_to_sdm, sigma_delta_demodulator_fir
# Misc
sys.setrecursionlimit(10000000)

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
        self.valid_in.value = sdm_transaction.valid
        for val in sdm_transaction.data:
            self.data_in.value = int(val)
            await RisingEdge(self.clk)

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
    def __init__(self, clk, data_out, valid_out, num_of_probes, callback=None, event=None):
        self.clk = clk
        self.data_out = data_out
        self.valid_out = valid_out
        self.num_of_probes = num_of_probes
        self.trans = SDM_transaction()
        self.temp_list_of_probes = []
        Monitor.__init__(self, callback, event)

    async def _monitor_recv(self):
        await RisingEdge(self.valid_out)
        for _ in range(self.num_of_probes):
            await RisingEdge(self.clk)
            self.temp_list_of_probes.append(self.data_out.value)
        self.trans.data = self.temp_list_of_probes
        self.trans.valid = self.valid_out
        self._recv(self.trans)

class SDM_model_wrapper():
    def __init__(self,duration, sample_rate=44100, target_rate=2822400, frequency=100):
        self.duration = duration
        self.sample_rate = sample_rate
        self.target_rate = target_rate
        self.frequency = frequency
        self.generate_data()

    def generate_data(self):
        self.time = np.linspace(0, self.duration, int(self.sample_rate * self.duration), endpoint=False)
        self.audio_data = (0.9 * np.sin(2 * np.pi * self.frequency * self.time) * 32767).astype(dtype='int16')
        self.sdm_signal = convert_audio_to_sdm(self.audio_data, self.sample_rate, self.target_rate)
        with open("sdm_signal_from_model_class_gen.txt", "w") as file:
            for val in self.sdm_signal:
                file.write(f"{val}\n")

def wrapp_trans(SDM_transaction):
    with open("sdm_signal_from_design_mntr.txt", "w") as file:
        SDM_transaction.data.reverse()
        for val in SDM_transaction.data:
            file.write(f"{val}\n")
            #print(f"[Monitor] val: {val}")

@cocotb.test()
async def functionality(top):
    duration = 1.0  # 1 second
    duration2 = 0.1
    sdm_signal_from_design = []    
    
    model = SDM_model_wrapper(duration2)
    #print(f"model_data: {model.sdm_signal}")

    test = SDM_transaction(model.audio_data, valid=1)
    #print(test)
    cocotb.start_soon(Clock(top.clk, 354.6, units='ns').start())
    cocotb.start_soon(Clock(top.dummy_clk, 22675.73, units='ns').start())

    rst_drv = SDM_reset_driver(top.clk, top.rst_n)
    drv = SDM_driver(top.dummy_clk, top.audio_in1, top.valid_in_dac1)
    mon = SDM_monitor(top.clk, top.sdm_out1, top.valid_out_dac1, num_of_probes=len(model.sdm_signal), callback=None)
    scb = Scoreboard(top)
    scb.add_interface(mon, model.sdm_signal, reorder_depth=len(model.sdm_signal))

    #top.rst_n.value = 0
    #await Timer(500, units='ns')
    #top.rst_n.value = 1
    #await RisingEdge(top.clk)
    #top.valid_in_dac1.value = 1
    await rst_drv.send(500)
    await drv.send(test)
    print(f"mon: {mon.trans}")
    
    ## Plot the results
    #plt.figure(figsize=(12, 9))
#
    ## Plot original audio signal
    #plt.subplot(3, 1, 1)
    #plt.plot(model.time[:1000], model.audio_data[:1000], label="Original Audio Signal")
    #plt.title("Original Audio Signal (44.1 kHz)")
    #plt.grid(True)
    #plt.legend()
#
    ## Plot Sigma-Delta Modulated Signal
    #oversampled_t = np.linspace(0, duration, len(model.sdm_signal), endpoint=False)
    #plt.subplot(3, 1, 2)
    #plt.step(oversampled_t[:64000], model.sdm_signal[:64000], label="Sigma-Delta Modulated Signal", where="mid")
    #plt.title("Sigma-Delta Modulated Signal (2.8224 MHz)")
    #plt.grid(True)
    #plt.legend()
#
    ## Plot Sigma-Delta Modulated Signal from design
    #oversampled_t = np.linspace(0, duration, len(model.sdm_signal), endpoint=False)
    #plt.subplot(3, 1, 2)
    #plt.step(oversampled_t[:64000], mon.trans.data[:64000], label="Sigma-Delta Modulated Signal from design")
    #plt.title("Sigma-Delta Modulated Signal (2.8224 MHz)")
    #plt.grid(True)
    #plt.legend()
#
    ## Adjust layout
    #plt.tight_layout()
    #plt.show()