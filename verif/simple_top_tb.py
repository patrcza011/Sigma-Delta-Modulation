# Cocotb
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, FallingEdge
# Utils
import numpy as np
import sys
import os
# Adding main_repo to path to use relative imports
parent_path = os.path.abspath(os.path.join(os.path.dirname(__file__),".."))

if parent_path not in sys.path:
    sys.path.append(parent_path)
# Model
from model.SDM import convert_audio_to_sdm, sigma_delta_demodulator_fir
sys.setrecursionlimit(10000000)

@cocotb.test()
async def base_test(top):
    # Generate a test 16-bit sine wave audio signal at 44.1 kHz
    duration = 1.0  # 1 second
    sample_rate = 44100  # 44.1 kHz
    target_rate = 2822400  # 2.8224 MHz
    t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
    frequency = 100
    audio_data = (0.9 * np.sin(2 * np.pi * frequency * t) * 32767).astype(dtype='int16')
    sdm_signal_from_design = []
    # Python model
    sdm_signal = convert_audio_to_sdm(audio_data, sample_rate, target_rate)
    demodulated_audio_fir = sigma_delta_demodulator_fir(sdm_signal, target_rate, sample_rate)
    with open("sdm_signal_from_model.txt", "w") as file:
        for val in sdm_signal:
            file.write(f"{val}\n")

    # HDL implementation
    # Generate clock 2.8224 MHz (period = 354.6 ns)
    cocotb.start_soon(Clock(top.clk, 354.6, units='ns').start())

    top.rst_n.value = 0
    await Timer(500, units='ns')
    top.rst_n.value = 1
    top.valid_in_dac1.value = 1
    #print(f"type: {type(-16384)}")
    #for val in audio_data:
    #    top.audio_in1.value = int(val)
    #    await RisingEdge(top.clk)
    #top.audio_in1.value = -16384
    #await RisingEdge(top.sdm_out1)
    #for _ in range(len(sdm_signal)):
    #    sdm_signal_from_design.append(top.sdm_out1)
    #    await FallingEdge(top.clk)

    #with open("sdm_signal_from_design.txt", "w") as file:
    #    for val in sdm_signal_from_design:
    #        file.write(f"{val}\n")

    #await Timer(45000, units='ns')

    # Function to write data from the DUT
    async def write_data():
        for val in audio_data:
            top.audio_in1.value = int(val)
            await RisingEdge(top.clk)
            await Timer(10, units="ns")  # Small delay between writes

    # Function to read data from the DUT
    async def read_data():
        await RisingEdge(top.sdm_out1)
        for _ in range(len(sdm_signal)):
            await RisingEdge(top.clk)
            sdm_signal_from_design.append(top.sdm_out1)
            await Timer(10, units="ns")  # Small delay between reads

    # Perform write and read operations simultaneously
    write_task = cocotb.start_soon(write_data())
    read_task = cocotb.start_soon(read_data())

    # Wait for both tasks to complete
    await write_task
    await read_task

    with open("sdm_signal_from_design.txt", "w") as file:
        for val in sdm_signal_from_design:
            file.write(f"{val}\n")