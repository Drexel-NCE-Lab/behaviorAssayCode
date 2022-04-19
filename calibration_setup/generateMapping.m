function [imageMap,luminanceAdjustment] = generateMapping(cameraMatrix, projectorPosition)
%load cameraMatrix
radius = 2.25;
gridSize = 1500;
worldPoints = zeros(gridSize^2,5);
count = 1;

xRange = [-2.2 2.2];
yRange = [-2.6 2.1];
xVals = linspace(xRange(1),xRange(2),gridSize);
yVals = linspace(yRange(1),yRange(2),gridSize);

[xMesh,yMesh] = meshgrid(xVals,yVals);

worldPoints = [xMesh(:), yMesh(:), radius*cos(asin(xMesh(:)/radius)),xMesh(:),yMesh(:)];

% for x = -2.2:2.4/1500:2.2
%     for y = -2.6:4.7/1500:2.1
%         point = [x,y,radius*cos(asin(x/radius)),x,y];
%         worldPoints(count,:) = point;
%         count = count+1;
%     end
% end

%Project the generated world points onto the image plane
hom2euk = @(x) x(:, 1 : 2) ./ x(:, [3 3]);
cameraPoints = [hom2euk([worldPoints(:,1:3) ...
    ones(size(worldPoints,1),1)]*cameraMatrix) worldPoints(:,4:5)];

%size of output image
pixelHeight = 912;
pixelWidth = 1140;
imageMap = zeros(pixelWidth,pixelHeight,2);
pixel = [1 1];

%Improve performance by evaluating only those pixels w/in a certain
%expected width of the current pixel
sliceSize = 2;
for X = 1:pixelWidth
    %Find the points on either side of current pixel's X coordinate
    subX = find(cameraPoints(:,1)>(X-sliceSize) &...
        cameraPoints(:,1)<(X+sliceSize));
    for Y = 1:pixelHeight
        %Find the points on either side of current pixel's Y coordinate
        subset = find(cameraPoints(subX,2)>(Y-sliceSize) &...
        cameraPoints(subX,2)<(Y+sliceSize));
        %Get the distance to each point in the subset
        distance = sum(bsxfun(@minus,cameraPoints(subX(subset),1:2),[X Y])...
            .^2,2).^0.5;
        %Find points in the 4 quadrants - indices into the subset of
        %intersections
        quadrant{1} = find(cameraPoints(subX(subset),1)>X & cameraPoints(subX(subset),2)>Y);
        quadrant{2} = find(cameraPoints(subX(subset),1)>X & cameraPoints(subX(subset),2)<Y);
        quadrant{3} = find(cameraPoints(subX(subset),1)<X & cameraPoints(subX(subset),2)>Y);
        quadrant{4} = find(cameraPoints(subX(subset),1)<X & cameraPoints(subX(subset),2)<Y);
        %Find the closest point in each corner
        bounds = zeros(4,1);
        for x=1:4
            if isempty(quadrant{x})
                %If a pixel has no neighbors in a given coordinate, set it
                %to incalculable - NaN
                bounds(x) = NaN(1);
            else
                %get index into the quadrant array of min distance in that
                %quadrant
                [~,bounds(x)] = min(distance(quadrant{x}));
                %get index back into full intersection point matrix
                bounds(x) = subX(subset(quadrant{x}(bounds(x))));
            end
        end
        %Interpolate angular values - on each side of the X axis,
        %interpolate both the Y values and the surface coordinate values, 
        %then interpolate surface coordinates along the X axis
        
        %first y axis interpolation point
        if any(isnan(bounds))
            worldPointCoordinates = NaN(1,2);
        else
            range = cameraPoints(bounds(1),2)-...
                cameraPoints(bounds(2),2);
            if range == 0
                firstInterp = (cameraPoints(bounds(1),[1 3:4])+...
                    cameraPoints(bounds(2),[1 3:4]))/2;
            else
                weight1 = (cameraPoints(bounds(1),2)-Y)/range;
                weight2 = (Y-cameraPoints(bounds(2),2))/range;
                firstInterp = (weight1*cameraPoints(bounds(1),[1 3:4])+...
                    weight2*cameraPoints(bounds(2),[1 3:4]));
            end
            %second y axis interpolation point
            range = cameraPoints(bounds(3),2)-...
                cameraPoints(bounds(4),2);
            if range == 0
                secondInterp = (cameraPoints(bounds(3),[1 3:4])+...
                    cameraPoints(bounds(4),[1 3:4]))/2;
            else
                weight1 = (cameraPoints(bounds(3),2)-Y)/range;
                weight2 = (Y-cameraPoints(bounds(4),2))/range;
                secondInterp = (weight1*cameraPoints(bounds(3),[1 3:4])+...
                    weight2*cameraPoints(bounds(4),[1 3:4]));
            end
            
            %X axis interpolation
            range = firstInterp(1)-secondInterp(1);
            if range ==0
                worldPointCoordinates = (firstInterp(2:3)+...
                    secondInterp(2:3))/2;
            else
                weight1 = (firstInterp(1)-X)/range;
                weight2 = (X-secondInterp(1))/range;
                worldPointCoordinates = (weight1*firstInterp(2:3)+...
                    weight2*secondInterp(2:3));
            end
        end
        
        %Layer 1: azimuth(in), layer 2: elevation(in)
        imageMap(pixel(2),pixel(1),:) = worldPointCoordinates;
        pixel(1) = pixel(1)+1;
    end
    pixel(2) = pixel(2)+1;
    pixel(1) = 1;
end

luminanceAdjustment = computeLuminanceAdjustment(imageMap,projectorPosition);

save ConfigData/imageMap.mat imageMap
save ConfigData/luminanceAdjustment.mat luminanceAdjustment
end



