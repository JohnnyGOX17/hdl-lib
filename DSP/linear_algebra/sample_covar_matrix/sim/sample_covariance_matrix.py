import numpy as np

N = 3 # number of channels
M = 5 # samples per channel to estimate, where M ≥ N
# form MxN complex sample matrix
x = np.matrix( np.arange(N*M).reshape((N,M)) )
#z = x - 1j*x
z = x
print(z)
print(z.H)
# Sample covariance matrix estimation (https://en.wikipedia.org/wiki/Estimation_of_covariance_matrices)
#    when M = pow2, can use simple lsh bitwise op (FXP)
#    since Hermitian positive semi-definite output, need
#    only compute upper or lower triangle of values, then
#    copy conj in other triangle for output
covar = np.matmul(z, z.H)/M
print(covar)
