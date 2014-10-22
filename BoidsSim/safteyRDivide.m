function [c] = safteyRDivide(a, b)
b = b+eps;
c = rdivide(a, b); 
end