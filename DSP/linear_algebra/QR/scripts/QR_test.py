#!/usr/bin/python3
import numpy as np

ang_bitwidth  = 32 # based on atan2 LUT
data_bitwidth = 16 # also the number of CORDIC rotations to perform
# CORDIC processing gain: https://en.wikipedia.org/wiki/CORDIC#Rotation_mode
processing_gain = 1
for i in range(data_bitwidth):
    processing_gain *= np.sqrt(1.0 + (2.0**(-2.0*i)))

print('CORDIC Processing Gain of component: %0.8f' % processing_gain)
fxp_scale_factor = int(np.floor((1/processing_gain)*(2**(data_bitwidth-1))))
print('\tTo cancel gain (scale of %0.8f) for %d bit outputs:\n\t\t- Multiply by 0x%X (%d signed)\n\t\t- Then shift right by %d bits' % (1/processing_gain, data_bitwidth, fxp_scale_factor, fxp_scale_factor, data_bitwidth-1))

lambda_factor = 0.99
print('Lambda/forgetting factor of: %0.2f' % lambda_factor)
fxp_scale_factor = int(np.floor(lambda_factor*(2**(data_bitwidth-1))))
print('Lambda/forgetting factor signed int (same rules as CORDIC gain above): %d [0x%X]' % (fxp_scale_factor, fxp_scale_factor))

# Convert angle (in degrees) to unsigned integer value for input to CORDIC block
def degree_to_unsigned_fxp( angle, bitwidth ):
    # Python mod operator works with FP and constrains to positive values:
    #   e.x. -45deg input angle -> 315deg wrapped angle
    wrapped_angle = angle % 360.0
    return int(np.floor( (wrapped_angle/360.0) * (2**bitwidth) ))


print('Testing Vectoring Mode: Rectangular (X & Y) -> Polar format (Mag & Phase)')
test_I = [4000]
test_Q = [-2000]
mag_feedback = 0
for I_in, Q_in in zip(test_I, test_Q):
    print('I: %d, Q: %d' % (I_in, Q_in))
    # 1st CORDIC vectoring engine
    input_vec_mag = round(np.sqrt(I_in**2 + Q_in**2))
    print("Input Vector Magnitude: %d" % input_vec_mag)
    phi = degree_to_unsigned_fxp(np.rad2deg(np.arctan2(Q_in, I_in)), data_bitwidth)
    print("Input Vector Phase: %d" % phi)

    # 2nd CORDIC vectoring engine
    theta = degree_to_unsigned_fxp(np.rad2deg(np.arctan2(input_vec_mag, mag_feedback)),
                                   data_bitwidth)
    mag_feedback = round(np.sqrt(mag_feedback**2 + input_vec_mag**2))

    print("Phi: 0x%X" % phi)
    print("Theta: 0x%X" % theta)

