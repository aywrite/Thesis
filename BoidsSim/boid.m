function boid(Endtime, delta, DisplayWorld, maxVal)
%This script runs a multi-agent simulation
%%Setup up the enviroment
%reset local and GPU Memory


%create global variables
global N;
global useGPU;
global xmin;
global xmax;
global ymin;
global ymax;
global zmin;
global zmax;

TimeSteps = Endtime/delta; %noTimeSteps


%%Generate the Agents
%Generate N entities with random locations and velocities
X = 90;     %Distance Spread
V = 3;      %Velocity Spread
 
%generate random gaussian positions
position.x = X*randn(N, 1);
position.y = X*randn(N, 1);
position.z = X*randn(N, 1);

%generate random gaussian velocities
velocity.x = V*randn(N, 1);
velocity.y = V*randn(N, 1);
velocity.z = V*randn(N, 1);

%%Generate the world

xmin = -maxVal; 
xmax = maxVal;
ymin = -maxVal;
ymax = maxVal;
zmin = -maxVal;
zmax = maxVal;

%Prepare the World for display
if DisplayWorld == true
    %cacl current time
    currentTime = 0;
    %Plot the results
    plot3(position.x, position.y, position.z, 'k+', 'Markersize', 5);
    title(['Boids Swarm, Current Time: ',  num2str(currentTime), ' Number of Boids: ', num2str(N)]);
    axis([xmin,xmax,ymin,ymax,zmin,zmax]);
    drawnow;
end

%Begin Main loop
for k=0:TimeSteps
    
    %function to get a
    if useGPU == true
        acceleration = GetAccelerationGPU(position, velocity);
    else
       acceleration = GetAccelerationCPU(position, velocity); 
    end

    %calculate new positions etc
    velocity_new = updateForTime(velocity, acceleration, delta);
    position_new = updateForTime(position, velocity, delta);
    velocity = velocity_new;
    position = position_new;
    %cacl current time
    currentTime = k*delta;
    %check none of the birds are out of position
    position = checkPosition(position);
    if DisplayWorld == true
        %Plot the results
        plot3(position.x, position.y, position.z, 'k+', 'Markersize', 5);
        title(['Boids Swarm, Current Time: ',  num2str(currentTime), ' Number of Boids: ', num2str(N)]);
        axis([xmin,xmax,ymin,ymax,zmin,zmax]);
        drawnow;
    end
end


