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
num_angles = 30 # number of subdivided angles to test from 0-360deg
tol_error  = 3  # % error tolerance for CORDIC outputs (% error grows with low input magnitudes or 0/90deg angles)

# Calc CORDIC processing gain: https://en.wikipedia.org/wiki/CORDIC#Rotation_mode
processing_gain = 1
for i in range(data_bitwidth):
    processing_gain *= np.sqrt(1.0 + (2.0**(-2.0*i)))

# Convert angle (in degrees) to signed integer value for input to CORDIC block
def degree_to_signed_fxp( angle, bitwidth ):
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
async def test_CORDIC_rotations(dut):
    """ Validate CORDIC trig functions"""

    clk = Clock(dut.clk, 10, units="ns") # create 10ns period clock on input port `clk`
    cocotb.fork(clk.start()) # start clk

    dut._log.info("DUT generic: G_ITERATIONS={}".format(data_bitwidth))
    dut._log.info("CORDIC Processing Gain of component: %0.8f" % processing_gain)
    await RisingEdge(dut.clk) # start tests synchronous with input clk

    # Rotation Mode Tests ---------------------------------------------------------
    # https://en.wikipedia.org/wiki/CORDIC#Rotation_mode
    # this is an efficient way to compute trigonometric functions & rotations of a vector
    #   Mag/Phase -> I/Q (https://en.wikipedia.org/wiki/Polar_coordinate_system#Converting_between_polar_and_Cartesian_coordinates)
    #     X = r*cos(theta)
    #     Y = r*sin(theta)
    dut._log.info('Testing Rotation Mode: Polar format (Mag & Phase) -> Rectangular (X & Y)\n\n')
    dut.y_in <= 0 # in rotation, magnitude of vector in x_in, y_in can be set to 0

    test_angles = np.linspace(0.0, 360.0, num=num_angles)
    for ang in test_angles:
        await RisingEdge(dut.clk) # start tests synchronous with input clk

        input_angle   = degree_to_signed_fxp(ang, ang_bitwidth)
        dut.angle_in <= input_angle # assign value to DUT
        dut._log.info('%0.2f deg input angle value: %d' % (ang, input_angle) )

        # use constrained random input magnitudes for tests
        input_mag = random.randint(INPUT_MIN, INPUT_MAX)
        dut.x_in <= input_mag # assign value to DUT
        dut._log.info('Input magnitude value: %d' % input_mag )

        dut.valid_in <= 1 # assert data valid
        await RisingEdge(dut.clk)
        dut.valid_in <= 0 # deassert data valid

        # estimate the expected outputs from basic trig math
        cos_est = round(processing_gain*input_mag*np.cos(np.deg2rad(ang)))
        sin_est = round(processing_gain*input_mag*np.sin(np.deg2rad(ang)))
        # handle roll-over for signed int given DUT precision/bitwidth
        cos_est = to_fixed_signed_int( cos_est, data_bitwidth )
        sin_est = to_fixed_signed_int( sin_est, data_bitwidth )
        dut._log.info('Expected %d*Cos(%0.2f) [X_out] ~= %d' % (input_mag, ang, cos_est))
        dut._log.info('Expected %d*Sin(%0.2f) [Y_out] ~= %d' % (input_mag, ang, sin_est))

        # wait for output data valid and compare to model
        while not dut.valid_out.value:
            await RisingEdge(dut.clk)

        # NOTE: *.value.integer is interpreted as an unsigned integer
        dut_x_out = dut.cos_out.value.signed_integer
        dut_y_out = dut.sin_out.value.signed_integer
        # handle if estimate is 0 so we don't div by 0
        if cos_est == 0:
            x_error = dut_x_out/input_mag # rough order of magnitude of error given no /0
        else:
            x_error   = 100*(dut_x_out - cos_est)/cos_est
        if sin_est == 0:
            y_error = dut_y_out/input_mag # rough order of magnitude of error given no /0
        else:
            y_error   = 100*(dut_y_out - sin_est)/sin_est
        dut._log.info("DUT X_out: %d (%0.2f%% Error)" % (dut_x_out, x_error))
        dut._log.info("DUT Y_out: %d (%0.2f%% Error)\n" % (dut_y_out, y_error))
        assert x_error < tol_error, "Error between true & predicted X_out value greater than tolerance of {}%!".format(tol_error)
        assert y_error < tol_error, "Error between true & predicted Y_out value greater than tolerance of {}%!".format(tol_error)

    # SIM END -----------------------------------------------------------------
    await Timer(1, units='ns') # example of waiting 1ns
    dut._log.info("Test complete!")
