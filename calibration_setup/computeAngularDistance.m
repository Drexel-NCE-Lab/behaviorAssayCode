function angularDistance = computeAngularDistance(imageMap, params)
% load imageMap
% params = [0,0,2,-2.5,-1,1];
%stim bounds: azimuth, elevation image bounds:top,bot,left,right
elevation = params(1);
azimuth = params(2);
top = params(3);
bot = params(4);
left = params(5);
right = params(6);


center = [elevation,azimuth];
radius = 2.25;
zeroVector = [sin(center(2))*cos(center(1)) ...
    sin(center(1)) cos(center(2))*cos(center(1))];
x = imageMap(:,:,1);
x(radius*asin(x/radius)>right | radius*asin(x/radius)<left) = NaN(1);
y = imageMap(:,:,2);
y(y>top|y<bot) = NaN(1);
z = radius*cos(asin(x/radius));
getAngle = @(a,b) atan2(norm(cross(a,b,2)),dot(a,b,2));
%vectors =  [sin(elevation(:)) ...
    %cos(azimuth(:)).*cos(elevation(:)) ...
    %cos(elevation(:)).*sin(azimuth(:))];
vectors = [x(:) y(:) z(:)];
zeroVector = repmat(zeroVector,size(vectors,1),1);
angularDistance = zeros(size(y));
angularDistance(:) = getAngle(vectors,zeroVector);
cProd = cross(vectors,zeroVector,2);
dProd = dot(vectors,zeroVector,2);
cProdNorm = arrayfun(@(x) norm(cProd(x,:)),1:numel(dProd));
angularDistance(:) = atan2(cProdNorm',dProd);
% for n=1:size(vectors,1)
%     angularDistance(ind2sub(size(y),n)) = getAngle(vectors(n,:),zeroVector);
% end
angularDistance(angularDistance>47*pi/180) = nan;
save ConfigData/centeredDistance.mat angularDistance
end