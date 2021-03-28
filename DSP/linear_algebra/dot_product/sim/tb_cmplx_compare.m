% compare result from testbench to expected Matlab model

a = zeros(1,8)
b = zeros(1,8)
for i = 0:7
  a(i+1) =  i + 1i*(i-5)
  b(i+1) = -i + 1i*(i*2)
end

conj(a)*b.'
