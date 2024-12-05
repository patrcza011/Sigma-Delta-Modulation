import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def base_test(sdm_modulator):
    # Simple signal assignment
    clk = sdm_modulator.clk
    rst_n = sdm_modulator.rst_n
    din = sdm_modulator.din
    dout = sdm_modulator.dout

    # Generate clock 2.8224 MHz (period = 354.6 ns)
    cocotb.start_soon(Clock(clk, 354.6, units='ns').start())

    rst_n.value = 0
    await Timer(500, units='ns')
    rst_n.value = 1

    din.value = -16384
    await Timer(4500, units='ns')