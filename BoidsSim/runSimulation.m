function [b, b2, Ycpu, Ygpu, Yloop, delta, EndTime] = runSimulation()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
clear;
reset(gpuDevice);


global useGPU;

maxVal = 100; %world Size
EndTime = 10; %Endtime
delta = 0.1; %time step size
DisplayWorld = false;

%Grpahing Variables
top = 500;
b = 0:1:top;
b2 = 0:1:100;
Ycpu = zeros(1, top);
Ygpu = zeros(1, top);
Yloop = zeros(1, top);

for k=1:(top+1)
useGPU = false;
n = b(k); 
Ycpu(k) = boid(EndTime, delta, n, DisplayWorld, maxVal);
useGPU = true;
Ygpu(k) = boid(EndTime, delta, n, DisplayWorld, maxVal);
end

for k=1:(101)
useGPU = false;
n = b2(k); 
Yloop(k) = boid2(EndTime, delta, n, DisplayWorld, maxVal);
end

% plot(b, Ycpu, b, Ygpu, b2, Yloop); %plot data
% title(['Computation Time vs. Number of Agents, delta: ',  num2str(delta), ' end time: ', num2str(EndTime)]); %title
% xlabel('Number of Agents') % x-axis label
% ylabel('Time to Compute Simulation (seconds)') % y-axis label
% legend('CPU','GPU', 'Loop', 'Location','northeast')
end

