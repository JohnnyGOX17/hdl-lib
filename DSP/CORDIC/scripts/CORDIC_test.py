#!/usr/bin/python3
import numpy as np

ang_bitwidth  = 32 # based on atan2 LUT
data_bitwidth = 16 # also the number of CORDIC rotations to perform
# CORDIC processing gain: https://en.wikipedia.org/wiki/CORDIC#Rotation_mode
processing_gain = 1
for i in range(data_bitwidth):
    processing_gain *= np.sqrt(1.0 + (2.0**(-2.0*i)))

print('CORDIC Processing Gain of component: %0.8f' % processing_gain)
fxp_scale_factor = int(np.floor((1/processing_gain)*(2**data_bitwidth)))
print('\tTo cancel gain (scale of %0.8f) for %d bit outputs:\n\t\t- Multiply by 0x%X (%d unsigned)\n\t\t- Then shift right by %d bits' % (1/processing_gain, data_bitwidth, fxp_scale_factor, fxp_scale_factor, data_bitwidth))

# Convert angle (in degrees) to unsigned integer value for input to CORDIC block
def degree_to_unsigned_fxp( angle, bitwidth ):
    # Python mod operator works with FP and constrains to positive values:
    #   e.x. -45deg input angle -> 315deg wrapped angle
    wrapped_angle = angle % 360.0
    return int(np.floor( (wrapped_angle/360.0) * (2**bitwidth) ))

# Rotation Mode Tests ---------------------------------------------------------
# https://en.wikipedia.org/wiki/CORDIC#Rotation_mode
# this is an efficient way to compute trigonometric functions & rotations of a vector
#   Mag/Phase -> I/Q (https://en.wikipedia.org/wiki/Polar_coordinate_system#Converting_between_polar_and_Cartesian_coordinates)
#     X = r*cos(theta)
#     Y = r*sin(theta)
print('Testing Rotation Mode: Polar format (Mag & Phase) -> Rectangular (X & Y)')
magnitudes  = [19429, 5000]
test_angles = [45, 60]
for x_in, ang in zip(magnitudes, test_angles):
    print('%d deg input angle value: %d' % (ang,
        degree_to_unsigned_fxp(ang, ang_bitwidth)) )
    cos_est = round(processing_gain*x_in*np.cos(np.deg2rad(ang)))
    sin_est = round(processing_gain*x_in*np.sin(np.deg2rad(ang)))
    print('\t%d*Cos(%d) [X] ~= %d' % (x_in, ang, cos_est))
    print('\t%d*Sin(%d) [Y] ~= %d' % (x_in, ang, sin_est))


# Vectoring Mode Tests --------------------------------------------------------
# https://en.wikipedia.org/wiki/CORDIC#Vectoring_mode
# this is an efficient way to compute magnitude and phase of a complex signal
#   I/Q -> Mag/Phase (https://en.wikipedia.org/wiki/Polar_coordinate_system#Converting_between_polar_and_Cartesian_coordinates)
#     where Mag = sqrt(X**2 + Y**2)
#         Phase = atan2(Y,X)

# CORDIC processing gain: https://www.xilinx.com/support/documentation/ip_documentation/cordic/v6_0/pg105-cordic.pdf

print('Testing Vectoring Mode: Rectangular (X & Y) -> Polar format (Mag & Phase)')
test_x = [5000]
test_y = [2000]
for x_in, y_in in zip(test_x, test_y):
    print('X: %d, Y: %d' % (x_in, y_in))
    print('Mag: %d' % round(processing_gain*np.sqrt(x_in**2 + y_in**2)))
    phase = degree_to_unsigned_fxp(np.rad2deg(np.arctan2(y_in, x_in)), ang_bitwidth)
    print(phase)
    print( hex(phase) )

