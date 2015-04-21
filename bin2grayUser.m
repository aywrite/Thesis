function g = bin2grayUser(b)
g(1) = b(1);
for i = 2 : length(b);
    x = xor(str2num(b(i-1)), str2num(b(i)));
    g(i) = num2str(x);
end