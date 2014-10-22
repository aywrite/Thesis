function [A] = combineAccelerationsCPU(A1, A2, A3, A4)
% UNTITLED Summary of this function goes here
%   Detailed explanation goes here
global N;
A = zeros(1, 3, N);
Amax = 1*ones(1,1,N);
relFactor = 0.7;


%A1
normA1 = sqrt(A1(:,1,:).^2 + A1(:,2,:).^2 + A1(:,3,:).^2);
normA = sqrt(A(:,1,:).^2 + A(:,2,:).^2 + A(:,3,:).^2);
temp = (normA+normA1) > Amax;
tempA1 = relFactor*bsxfun(@times, bsxfun(@safteyRDivide, A1, normA1), (Amax-normA));
A = A + bsxfun(@times, tempA1, temp) + bsxfun(@times, A1, not(temp));
clear temp
clear tempA1
clear normA1
%A2
normA2 = sqrt(A2(:,1,:).^2 + A2(:,2,:).^2 + A2(:,3,:).^2);
normA = sqrt(A(:,1,:).^2 + A(:,2,:).^2 + A(:,3,:).^2);
temp = (normA+normA2) > Amax;
tempA2 = relFactor*bsxfun(@times, bsxfun(@safteyRDivide, A2, normA2), (Amax-normA));
A = A + bsxfun(@times, tempA2, temp) + bsxfun(@times, A2, not(temp));
clear temp
clear tempA2
clear normA2
%A3
normA3 = sqrt(A3(:,1,:).^2 + A3(:,2,:).^2 + A3(:,3,:).^2);
normA = sqrt(A(:,1,:).^2 + A(:,2,:).^2 + A(:,3,:).^2);
temp = (normA+normA3) > Amax;
tempA3 = relFactor*bsxfun(@times, bsxfun(@safteyRDivide, A3, normA3), (Amax-normA));
A = A + bsxfun(@times, tempA3, temp) + bsxfun(@times, A3, not(temp));
clear temp
clear tempA3
clear normA3
%A4
normA4 = sqrt(A4(:,1,:).^2 + A4(:,2,:).^2 + A4(:,3,:).^2);
normA = sqrt(A(:,1,:).^2 + A(:,2,:).^2 + A(:,3,:).^2);
temp = (normA+normA4) > Amax;
tempA4 = relFactor*bsxfun(@times, bsxfun(@safteyRDivide, A4, normA4), (Amax-normA));
A = A + bsxfun(@times, tempA4, temp) + bsxfun(@times, A4, not(temp));
clear temp
clear tempA4
clear normA4
clear normA

end

