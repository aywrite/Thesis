function [a] = combineAccelerations(a1, a2, a3, a4)
a = [0, 0, 0];
amax = 1;


if (norm(a) + norm(a2)) > amax
    a = a + safteyRDivide(a2, norm(a2)) * (amax - norm(a))*0.85;
else
    a = a + a2;
end

if (norm(a) + norm(a1)) > amax
    a = a + safteyRDivide(a1, norm(a1)) * (amax - norm(a))*0.85;
else
    a = a + a1;
end

if (norm(a) + norm(a3)) > amax
    a = a + safteyRDivide(a3, norm(a3)) * (amax - norm(a))*0.85;
else
    a = a + a3;
end

if (norm(a) + norm(a4)) > amax
    a = a + safteyRDivide(a4, norm(a4)) * (amax - norm(a))*0.85;
else
    a = a + a4;
end


end