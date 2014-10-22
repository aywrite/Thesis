function [A] = GetAccelerationCPU(position, velocity)
%%This is the function description
%Boids are stored in an Nx3xN array, pages store each boid, coloums represent x,y,z values,
%rows store the Current Boids perspective on all other Boids, arrays with
%only one row store just the Boids description of itself.
global N;


%Acceleration parameters
c1=1000; %seperation
c2 = 1000; %cohesion
c3 = 5000; %alignment
c4 = 1000; %random
proxWarn = 0.5; %range at which seperation kicks in
sightRange = 5; %range for which the agents consider others for their claculations

%%Distance
PositionTemp = [position.x, position.y, position.z];
Distance = (repmat(PositionTemp, 1, 1, N));
MyPosition = reshape(PositionTemp', 1, 3, N); 
clear PositionTemp
Position = (repmat(MyPosition, N, 1, 1));
Distance = Distance-Position;
temp = abs(Distance) < (sightRange*ones(N,3,N));
A2New = temp.*Distance*c2;
clear temp
temp = abs(Distance) < (proxWarn*ones(N,3,N));
A1New = temp.*(scaleMatrix(Distance, Distance)*(-c1));
clear temp
clear MyPosition
clear Position
% Distance;



%%Velocity
VelocityTemp = [velocity.x, velocity.y, velocity.z];
VelocityVector = (repmat(VelocityTemp, 1, 1, N));
MyVelocity = reshape(VelocityTemp', 1, 3, N);
clear VelocityTemp
Velocity = (repmat(MyVelocity, N, 1, 1));
VelocityVector = VelocityVector-Velocity;
Drag = bsxfun(@power, MyVelocity, 2);
temp = abs(Distance) < (sightRange*ones(N,3,N));
A3New = temp.*VelocityVector*c3;
clear temp
clear MyVelocity
clear Velocity
clear VelocityVector
clear Distance
% VelocityVector;


%%Totals
A4Total = randn(1, 3, N);
A1Total = sum(A1New, 1);
clear A1New
A2Total = sum(A2New, 1);
clear A2New
A3Total = sum(A3New, 1);
clear A3New
ATotalTemp = combineAccelerationsCPU(A1Total, A2Total, A3Total, A4Total);%-Drag;
ATotal = reshape(squeeze(ATotalTemp)', N,3);

clear Drag
clear A1Total
clear A2Total
clear A3Total
clear A4Total
clear ATotalTemp

%%Return
A.x = ATotal(:,1);
A.y = ATotal(:,2);
A.z = ATotal(:,3);
clear ATotal
end

