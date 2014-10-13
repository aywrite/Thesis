
global N;
global xmin;
global xmax;
global ymin;
global ymax;
global zmin;
global zmax;

%Setup, Generate N entities at random Locations
%Endtime
Endtime = 100;
%time step size
delta = 1;
%noTimeSteps
TimeSteps = Endtime/delta;

%number of entities
N = 200;
%generate random gaussian positions
X = 10;
x = X*randn(N, 3);
%generate random gaussian velocities
V = 1;
v = V*randn(N, 3);
%this is the basic acceleration value
a = zeros(N, 3);
%arand = zeros(N, 3);

%axis constants
maxVal = 15;
xmin = -maxVal;
xmax = maxVal;
ymin = -maxVal;
ymax = maxVal;
zmin = -maxVal;
zmax = maxVal;

%Begin Main loop
for k=0:TimeSteps
    
    %function to get a
    a = GetAccelerationGPU(x, v);
    %a = GetAcceleration(x, v);
    %calculate new positions etc
    v_new = v + a*0.0001*delta;
    x_new = x + v_new*delta;
    v = v_new;
    x = x_new;
    %cacl current time
    currentTime = k*delta;
    %check none of the birds are out of position
    x = checkPosition(x);
    %Plot the results
    plot3(x(:, 1), x(:, 2), x(:, 3), 'k+', 'Markersize', 5);
    title(['Boids Swarm, Current Time: ',  num2str(currentTime), ' Number of Boids: ', num2str(N)]);
    axis([xmin,xmax,ymin,ymax,zmin,zmax]);
    drawnow;
end


