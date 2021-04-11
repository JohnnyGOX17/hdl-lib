# Simulation tesbench using Cocotb

import os
import random
import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.triggers import Timer

# get generic values exported from Makefile
# the number of CORDIC rotations/iterations to perform is == to the output
# bitwidth
data_bitwidth = int(os.environ['ITERATIONS'])
# based on atan2 LUT internal to CORDIC component
ang_bitwidth  = 32
# signed int min/max values
INPUT_MIN = -(2**(data_bitwidth-1))
INPUT_MAX =  (2**(data_bitwidth-1) - 1)
# sim variables
num_tests = 20 # number of random X/Y magnitude pairs to test
tol_error = 3  # % error tolerance for CORDIC outputs (% error grows with low input magnitudes or 0/90deg angles)

# Calc CORDIC processing gain: https://en.wikipedia.org/wiki/CORDIC#Rotation_mode
processing_gain = 1
for i in range(data_bitwidth):
    processing_gain *= np.sqrt(1.0 + (2.0**(-2.0*i)))

# Convert angle (in degrees) to unsigned integer value for input to CORDIC block
def degree_to_unsigned_fxp( angle, bitwidth ):
    # Python mod operator works with FP and constrains to positive values:
    #   e.x. -45deg input angle -> 315deg wrapped angle
    wrapped_angle = angle % 360.0
    return int(np.floor( (wrapped_angle/360.0) * (2**bitwidth) ))

def to_fixed_signed_int(val, bitwidth):
    ret_val = val
    if val > (2**(bitwidth-1) - 1):
        ret_val = val % (2**(bitwidth-1) - 1)
    if val < -(2**(data_bitwidth-1)):
        ret_val = val % -(2**(bitwidth-1))
    return ret_val

@cocotb.test()
async def test_CORDIC_vectoring(dut):
    """ Validate CORDIC Vectoring functions"""

    clk = Clock(dut.clk, 10, units="ns") # create 10ns period clock on input port `clk`
    cocotb.fork(clk.start()) # start clk

    dut._log.info("DUT generic: G_ITERATIONS={}".format(data_bitwidth))
    dut._log.info("CORDIC Processing Gain of component: %0.8f" % processing_gain)
    dut.valid_in <= 0 # deassert data valid
    await RisingEdge(dut.clk) # start tests synchronous with input clk

    # Vectoring Mode Tests --------------------------------------------------------
    # https://en.wikipedia.org/wiki/CORDIC#Vectoring_mode
    # this is an efficient way to compute magnitude and phase of a complex signal
    #   I/Q -> Mag/Phase (https://en.wikipedia.org/wiki/Polar_coordinate_system#Converting_between_polar_and_Cartesian_coordinates)
    #     where Mag = sqrt(X**2 + Y**2)
    #         Phase = atan2(Y,X)
    dut._log.info('Testing Vectoring Mode: Polar format (Mag & Phase) -> Rectangular (X & Y)\n\n')

    for idx in range(num_tests):
        await RisingEdge(dut.clk) # start tests synchronous with input clk

        # use constrained random input magnitudes for tests
        input_x = random.randint(INPUT_MIN, INPUT_MAX)
        input_y = random.randint(INPUT_MIN, INPUT_MAX)
        dut.x_in <= input_x # assign value to DUT
        dut.y_in <= input_y # assign value to DUT
        dut._log.info('Input X: %d | Input Y: %d' % (input_x, input_y) )

        dut.valid_in <= 1 # assert data valid
        await RisingEdge(dut.clk)
        dut.valid_in <= 0 # deassert data valid

        # estimate the expected outputs from basic trig math
        mag_est = round(processing_gain*np.sqrt(input_x**2 + input_y**2))
        # handle roll-over for signed int given DUT precision/bitwidth
        mag_est   = to_fixed_signed_int( mag_est, data_bitwidth )
        phase_est = degree_to_unsigned_fxp(np.rad2deg(np.arctan2(input_y, input_x)), ang_bitwidth)
        dut._log.info('Expected Magnitude ~= %d' % mag_est)
        dut._log.info('Expected Phase ~= %d' % phase_est)

        # wait for output data valid and compare to model
        while not dut.valid_out.value:
            await RisingEdge(dut.clk)

        # NOTE: *.value.integer is interpreted as an unsigned integer
        dut_mag_out   = dut.mag_out.value.signed_integer
        dut_phase_out = dut.phase_out.value.integer
        # handle if estimate is 0 so we don't div by 0
        if mag_est == 0:
            mag_error = dut_mag_out # rough order of magnitude of error given no /0
        else:
            mag_error = 100*(dut_mag_out - mag_est)/mag_est
        if phase_est == 0:
            phase_error = dut_phase_out # rough order of magnitude of error given no /0
        else:
            phase_error = 100*(dut_phase_out - phase_est)/phase_est
        dut._log.info("DUT Magnitude out: %d (%0.2f%% Error)" % (dut_mag_out, mag_error))
        dut._log.info("DUT Phase out: %d (%0.2f%% Error)\n" % (dut_phase_out, phase_error))
        assert abs(mag_error) < tol_error, "Error between true & predicted magnitude value greater than tolerance of {}%!".format(tol_error)
        assert abs(phase_error) < tol_error, "Error between true & predicted phase value greater than tolerance of {}%!".format(tol_error)

    # SIM END -----------------------------------------------------------------
    await Timer(1, units='ns') # example of waiting 1ns
    dut._log.info("Test complete!")
