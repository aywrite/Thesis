function [A] = unitVector(a1, a2, a3)
%     b1 = gpuArray(a1);
%     b2 = gpuArray(a2);
%     b3 = gpuArray(a3);
    
    rmag = sqrt(a1.^2 + a2.^2 + a3.^2);
    
    ua1 = bsxfun(@safteyRDivide,a1,rmag);
    ua2 = bsxfun(@safteyRDivide,a2,rmag);
    ua3 = bsxfun(@safteyRDivide,a3,rmag);
    
    A = [ua1, ua2, ua3];
end