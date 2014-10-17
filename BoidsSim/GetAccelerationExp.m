function [a] = GetAccelerationExp(x, v)

global N;
c1=0.3;
c2 = 0.3;
c3 = 5;
c4 = 30;

a1=zeros(N, 3);
a2=zeros(N, 3);
a3=zeros(N, 3);
a4=c4*randn(N, 3);

x1 = (x(:,1));
x2 = (x(:,2));
x3 = (x(:,3));
v1 = (v(:, 1));
v2 = (v(:, 2));
v3 = (v(:, 3));

%loop through all boids
parfor n=1:N  
[a1(n, :), a2(n, :), a3(n, :)] = ArrayCalcs(n, x1, x2, x3, v1, v2, v3);
end


a = gather(a1+a2+a3+a4);
end

