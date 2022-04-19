function [ luminanceAdjustment ] = computeLuminanceAdjustment(imageMap, projectorPosition)
%computeLuminanceAdjustment Compute the percentage of maximum luminance
%for each pixel to be adjusted to for uniform brightness
%   Calculate the necesarry brightness adjustments based on the angle of
%   incidence between the projection surface and the projection source, as
%   well as the difference due to distance variation

radius = 2.25;

%Vectors from the origin to the surface
x = imageMap(:,:,1);
y = imageMap(:,:,2);
z = radius*cos(asin(x/radius));

%Calculate the vectors from the camera point

xV = x-projectorPosition(1);
yV = y-projectorPosition(2);
zV = z-projectorPosition(3);

%Calculate the square of the distance to the closest surface point
dSquared = ((projectorPosition(1)^2 + projectorPosition(3)^2)^0.5-radius)^2;

distanceSquared = (xV.^2+yV.^2+zV.^2);
distanceCorrection = dSquared./distanceSquared;

%Normal vector to the tangent plane at each point - set elevation to 0
%y = zeros(size(y)); Just use zero for elevation in the vector...

angleCorrection = zeros(size(x));
for n=1:size(x(:))
   %normalVector = [x(n) y(n) z(n)]; Old version
   normalVector = [x(n) 0 z(n)];
   cameraToPointVector = [xV(n) yV(n) zV(n)];
   %Compute the angle between the two vectors
   angle = atan2(norm(cross(normalVector,cameraToPointVector)),dot(normalVector,cameraToPointVector));
   %Compute the %luminance of the ray on the tangent plane
   angleCorrection(n) = abs(cos(angle));
end

%Generate the composite luminance adjustment from the two matrices
luminanceAdjustment = distanceCorrection.*angleCorrection;
save ConfigData/luminanceAdjustment luminanceAdjustment
end

