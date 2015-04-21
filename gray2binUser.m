function b = gray2binUser(g)
b(1) = g(1);
for i = 2 : length(g);
    x = xor(str2num(b(i-1)), str2num(g(i)));
    b(i) = num2str(x);
end