function [s] = structFunct(fun, struct, scalar)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
    s.x = fun(struct.x, scalar);
    s.y = fun(struct.y, scalar);
    s.z = fun(struct.z, scalar);
end

