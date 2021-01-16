import numpy as np
import random

N = 3 # number of channels
M = 5 # samples per channel to estimate, where M ≥ N
# form MxN complex sample matrix
x = np.matrix( np.arange(N*M).reshape((N,M)) )
z = x - 1j*x
# create differing imag() parts to show Hermitian response
for i in range(0, N):
    for j in range(0, M):
        z[i,j] = x[i,j] - (random.randint(-5,5)*1j*x[i,j])
print("Sample Data & Complex Transpose:")
print(z)
print()
print(z.H)
print()
# Sample covariance matrix estimation (https://en.wikipedia.org/wiki/Estimation_of_covariance_matrices)
covar = np.matmul(z, z.H)/M
print("Direct Covariance Response:")
print(covar)
print()

# show manual model of covariance calc (for HDL implementation)
ct = np.zeros((3,3), dtype=np.complex_)
for i in range(0, N):         # rows
    for j in range(0, i+1):   # columns
        for k in range(0, M): # sample in row
            # MAC input sample vector at each time step based on output position
            # Only need to calculate lower triangle of covariance matrix since
            # output is always Hermitian positive semi-definite (lower == upper
            # triangle)
            ct[i,j] = z[i,k]*np.conjugate( z[j,k] ) + ct[i,j]
            # copy conj() in upper triangle for output
            if i != j:
                ct[j,i] = np.conjugate( ct[i,j] )

# when M = pow2, can use simple lsh bitwise op (FXP) for divide-by-M, and
# use seperate wrapper component to do /div & give option to either stream/double-buffer
# output covar matrix, or just output 3D signed array directly for use somewhere else
ct = ct/M
print("Dataflow model output:")
print(ct)
