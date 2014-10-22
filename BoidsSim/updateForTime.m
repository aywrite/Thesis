function [struct_new] = updateForTime(struct, structPrime, delta)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
struct_new.x = struct.x + structPrime.x*delta;
struct_new.y = struct.y + structPrime.y*delta;
struct_new.z = struct.z + structPrime.z*delta;
end

