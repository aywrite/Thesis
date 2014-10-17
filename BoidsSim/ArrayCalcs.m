function [a1, a2, a3] = ArrayCalcs(n , x1, x2, x3, v1, v2, v3)
c1=0.3;
c2 = 0.3;
c3 = 5;
c4 = 30;

r1 = bsxfun(@minus, x1, x1(n));
r2 = bsxfun(@minus, x2, x2(n));
r3 = bsxfun(@minus, x3, x3(n));

vr1 = bsxfun(@minus, v1, v1(n));
vr2 = bsxfun(@minus, v2, v2(n));
vr3 = bsxfun(@minus, v3, v3(n));

rmag = sqrt(r1.^2 + r2.^2 + r3.^2);
r = [r1, r2, r3];
vr = [vr1, vr2, vr3];

r1A1 = bsxfun(@rdivide,r1,rmag);
r2A1 = bsxfun(@rdivide,r2,rmag);
r3A1 = bsxfun(@rdivide,r3,rmag);
A1 = [r1A1, r2A1, r3A1];
%   A1 = bsxfun(@rdivide,r,rmag);
A1 = bsxfun(@times, A1, -c1);
A1(n, :) = [0,0,0];

A2 = bsxfun(@times, r, c2);
A2(n, :) = [0,0,0];

A3 = bsxfun(@times, vr, c3);
A3(n, :) = [0,0,0];

a1 = [sum(A1(:, 1)), sum(A1(:, 2)), sum(A1(:, 3))];
a2 = [sum(A2(:, 1)), sum(A2(:, 2)), sum(A2(:, 3))];
a3 = [sum(A3(:, 1)), sum(A3(:, 2)), sum(A3(:, 3))];
end