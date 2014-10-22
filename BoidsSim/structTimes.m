function [s] = structTimes(struct, scalar)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
    s.x = struct.x.*scalar;
    s.y = struct.x.*scalar;
    s.z = struct.x.*scalar;
end

