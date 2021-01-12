# Simulation tesbench using Cocotb

import os
import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.triggers import Timer

# get generic values exported from Makefile
AWIDTH = int(os.environ['AWIDTH'])
BWIDTH = int(os.environ['BWIDTH'])
# for random input values, find min & max range based on generic bit widths
A_MIN  = -(2**(AWIDTH-1))
A_MAX  =  (2**(AWIDTH-1) - 1)
B_MIN  = -(2**(BWIDTH-1))
B_MAX  =  (2**(BWIDTH-1) - 1)


@cocotb.test()
async def test_complex_multiply(dut):
    """ Validate complex multiply math"""

    clk = Clock(dut.clk, 10, units="ns") # create 10ns period clock on input port `clk`
    cocotb.fork(clk.start()) # start clk

    dut._log.info("DUT generics: AWIDTH={} | BWIDTH={}".format(AWIDTH, BWIDTH))
    await RisingEdge(dut.clk) # synchronous with input clk
    # Verify 10x random signed integers
    for i in range(10):
        # create random I/Q values
        a_real = random.randint(A_MIN, A_MAX)
        a_imag = random.randint(A_MIN, A_MAX)
        a_val  = complex( a_real, a_imag )
        b_real = random.randint(B_MIN, B_MAX)
        b_imag = random.randint(B_MIN, B_MAX)
        b_val  = complex( b_real, b_imag )
        dut._log.info("Inputs: A = {}, B = {}".format(a_val, b_val))
        expected_out  = a_val * b_val
        expected_real = expected_out.real
        expected_imag = expected_out.imag
        dut._log.info("Expected Output: {}".format(expected_out))

        # assign complex values to DUT inputs
        dut.ar <= a_real
        dut.ai <= a_imag
        dut.br <= b_real
        dut.bi <= b_imag

        dut.ab_valid <= 1 # assert data valid
        await RisingEdge(dut.clk)
        dut.ab_valid <= 0 # deassert data valid

        # wait for output data valid and compare to model
        while True:
            await RisingEdge(dut.clk) # synchronous with input clk
            if dut.p_valid == 1:
                break
        # NOTE: *.value.integer is interpreted as an unsigned integer
        p_real = dut.pr.value.signed_integer
        p_imag = dut.pi.value.signed_integer
        dut._log.info("DUT Output: {}".format(complex(p_real, p_imag)))
        assert p_real == expected_real, "Randomized test failed! DUT real output {} doesn't match expected {}".format(p_real, expected_real)
        assert p_imag == expected_imag, "Randomized test failed! DUT imag output {} doesn't match expected {}".format(p_imag, expected_imag)

    await Timer(1, units='ns') # example of waiting 1ns
    dut._log.info("Test complete!")
