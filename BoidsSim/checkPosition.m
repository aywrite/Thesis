function [NewPosition] = checkPosition(x)
%This function checks if the boids go out of bounds, if so they wrap aroud
%   Detailed explanation goes here
%import global variables
global N;
global xmin;
global xmax;
global ymin;
global ymax;
global zmin;
global zmax;
%initialise the matrix to store check positions
NewPosition = zeros(N, 3);
%loop through all boids and check they are in bounds
for i=1:N
   position = x(i, :);
   if position(1) > xmax
      position(1) = xmin+(position(1)-xmax); 
   end
   if position(1) < xmin
      position(1) = xmax-(position(1)-xmax); 
   end
   
   if position(2) > ymax
      position(2) = ymin+(position(2)-ymax); 
   end
   if position(2) < ymin
      position(2) = ymax-(position(2)-ymax); 
   end
   
   if position(3) > zmax
      position(3) = zmin+(position(3)-zmax); 
   end
   if position(3) < zmin
      position(3) = zmax-(position(3)-zmax); 
   end
   NewPosition(i, 1) = position(1);
   NewPosition(i, 2) = position(2);
   NewPosition(i, 3) = position(3);
end

end

