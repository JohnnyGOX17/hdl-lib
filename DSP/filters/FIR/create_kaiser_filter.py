#!python
# based on example: https://scipy-cookbook.readthedocs.io/items/FIRFilter.html
from numpy import cos, sin, pi, absolute, arange, log10, maximum
from scipy.signal import kaiserord, lfilter, firwin, freqz
from pylab import figure, clf, plot, xlabel, ylabel, xlim, ylim, title, grid, axes, show

# Sample rate (Hz)
sample_rate = 100.0
nyq_rate = sample_rate / 2.0

# The desired width of the transition from pass to stop,
# relative to the Nyquist rate.  We'll design the filter
# with a 5 Hz transition width.
width = 5.0/nyq_rate
# The desired attenuation in the stop band, in dB.
ripple_db = 30.0
# Compute the order and Kaiser parameter for the FIR filter.
N, beta = kaiserord(ripple_db, width)
# The cutoff frequency of the filter.
cutoff_hz = 10.0
# Use firwin with a Kaiser window to create a lowpass FIR filter.
b = firwin(N, cutoff_hz/nyq_rate, window=('kaiser', beta))

# Plot the FIR filter coefficients.
figure(1)
plot(b, 'bo-', linewidth=2)
title('Filter Coefficients (%d taps)' % N)
grid(True)

# Plot the magnitude response of the filter.
figure(2)
clf()
w, h = freqz(b, worN=8000)
plot((w/pi)*nyq_rate, 20*log10(absolute(h)), linewidth=0.5)
xlabel('Frequency (Hz)')
ylabel('Gain (dB)')
title('Frequency Response')
grid(True)
show()

# quantize filter coefficients
n_bits = 16
k = (2**(n_bits - 1))/max(absolute(b))
# scaled integer coefficients
b_scaled = b * k
b_fxp = [round(x) for x in b_scaled]

print(bin(b_fxp[0] & 0b1111111111111111)[2:].zfill(n_bits))
print(bin(b_fxp[1] & 0b1111111111111111)[2:].zfill(n_bits))

# write out coef to file
fd = open("coef.txt", "w")
for bin_val in b_fxp:
    fd.write(str((bin(bin_val & 0b1111111111111111)[2:].zfill(n_bits))) + "\n")
fd.close()

