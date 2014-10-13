% Setup
t = tic();
x = linspace(xlim(1), xlim(2), gridSize);
y = linspace(ylim(1), ylim(2), gridSize);
[xGrid,yGrid] = meshgrid(x, y);
z0 = xGrid + 1i*yGrid;
count = ones(size(z0));

% Calculate
z = z0;
for n = 0:maxIterations
    z = z.*z + z0;
    inside = abs(z)<=2;
    count = count + inside;
end
count = log(count);

% Show
cpuTime = toc(t);
fig = gcf;
fig.Position = [200 200 600 600];
imagesc( x, y, count);
axis image
colormap( [jet();flipud( jet() );0 0 0]);
title( sprintf( '%1.2fsecs (without GPU)', cpuTime));