function [a] = GetAccelerationGPU(x, v)

global N;
c1=0.3;
c2 = 0.3;
c3 = 5;
c4 = 30;

a1=zeros(N, 3);
a2=zeros(N, 3);
a3=zeros(N, 3);
a4=zeros(N, 3);

%loop through all boids
for n=1:N
    X1 = x(n, 1);
    X2 = x(n, 2);
    X3 = x(n, 3);
    
    V1 = v(n, 1);
    V2 = v(n, 2);
    V3 = v(n, 3);
    
    r1 = bsxfun(@minus, x(:, 1), X1);
    r2 = bsxfun(@minus, x(:, 2), X2);
    r3 = bsxfun(@minus, x(:, 3), X3);
    
    vr1 = bsxfun(@minus, v(:, 1), V1);
    vr2 = bsxfun(@minus, v(:, 2), V2);
    vr3 = bsxfun(@minus, v(:, 3), V3);
    
    rmag = sqrt(r1.^2 + r2.^2 + r3.^2);
    r = [r1, r2, r3];
    vr = [vr1, vr2, vr3];
    
    A1 = bsxfun(@rdivide,r,rmag);
    A1 = bsxfun(@times, A1, c1);
    A1(n, :) = [0,0,0];
    A2 = bsxfun(@times, r, c2);
    A3 = bsxfun(@times, vr, c3);
        
    for m=1:N
        if m ~= n
            a1(n, :) = a1(n, :) - A1(m);
            a2(n, :) = a2(n, :) + A2(m);
            a3(n, :) = a3(n, :) + A3(m);
        end
    end
    
%     a1(n, :) = [sum(A1(:, 1)), sum(A1(:, 2)), sum(A1(:, 3))];
%     a2(n, :) = [sum(A2(:, 1)), sum(A2(:, 2)), sum(A2(:, 3))];
%     a3(n, :) = [sum(A3(:, 1)), sum(A3(:, 2)), sum(A3(:, 3))];
end

%a4(n, :) = c4*randn(1, 3);
a = a1+a2+a3+a4;
end

