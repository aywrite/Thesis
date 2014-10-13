function [a] = GetAcceleration(x, v)

global N;
global r;
c1=0.3;
c2 = 0.3;
c3 = 5;
c4 = 30;

a1=zeros(N, 3);
a2=zeros(N ,3);
a3=zeros(N, 3);
a4=zeros(N, 3);

for n=1:N
    for m=1:N
        if m ~= n
            r = x(m, :)-x(n, :);
            vr = v(m, :)-v(n, :);
            rmag=sqrt(r(1,1)^2+r(1, 2)^2+r(1, 3)^2);
            a1(n, :) = a1(n, :) - c1*r/rmag^2;
            a2(n, :) = a2(n, :) + c2*r ;
            a3(n, :) = a3(n, :) + c3*vr;
        end
    end
end

a4(n, :) = c4*randn(3,1);
a = a1+a2+a3+a4;
end

