function [c] = safteyRDivide(a, b)
if b == 0
    b=0.001;
end
c = rdivide(a, b); 
end