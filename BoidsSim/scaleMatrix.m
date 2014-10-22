function [Aout] = scaleMatrix(A, B)
%scaleMatrix scales the Matrix A by the magnitude of the Matix B
%   Detailed explanation goes here
rmag = sqrt(B(:,1,:).^2 + B(:,2,:).^2 + B(:,3,:).^2);
rmag = repmat(rmag, 1, 3, 1);
Aout = bsxfun(@safteyRDivide, A, rmag);
clear rmag;
end
 
