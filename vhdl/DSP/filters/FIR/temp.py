#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt

fs = 30
t = np.arange(0, 100, 1/fs)
x = np.sin(2*np.pi*4*t) + np.sin(2*np.pi*7*t) + np.random.randn(len(t))*0.2
p = 20*np.log10(np.abs(np.fft.rfft(x)))
f = np.linspace(0, fs/2, len(p))

fig, ax = plt.subplots()
ax.plot(f, p, c='b', linewidth=0.5)

ax.set(xlabel='Frequency (Hz)', ylabel='Magnitude (dB)',
        title='FFT Spectrum')
ax.grid()

plt.show()
