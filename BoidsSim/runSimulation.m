function runSimulation()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
clear;
reset(gpuDevice);

global N;
global useGPU;

maxVal = 100; %world Size
EndTime = 500; %Endtime
delta = 0.1; %time step size
DisplayWorld = false;
useGPU = false;
N = 20;   %Number of entities

boid(EndTime, delta, DisplayWorld, maxVal)
end

