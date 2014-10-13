a = 10000000;
b = gpuArray.zeros(a, 1);
r1 = gpuArray.rand(a, 1);
r2 = gpuArray.rand(a, 1);
r3 = gpuArray.rand(a, 1);

r1 = arrayfun(@(
b = gather(sqrt(r1.^2 + r2.^2 + r3.^2));
