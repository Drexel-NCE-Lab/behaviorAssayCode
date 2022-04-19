function tiledStimGeneration(imageMap,projectionBounds, angleBounds, stimParams)
%May be buggy - hasn't been tested since generateStimulus was reWritten


%load imageMap
%angleParams = [0,0,2,-2.5,-1,1]; %Azimuth, elevation, top, bot, left,
    %right
%stimParams = [360 3 .6 6]; %frequency, duration, maxRadius, bitDepth
%angleBounds = [-2,1.5,-0.5,0.5,.5,.5]%elevation lower, upper; azimuth
    %lower, upper; interval elevation, azimuth
angleParams = [0 0 projectionBounds];

for n = angleBounds(1):angleBounds(5):angleBounds(2)
    angleParams(2) = n;
    for m = angleBounds(3):angleBounds(6):angleBounds(4)
        angleParams(1) = m;
        filebase = strcat('azi',sprintf('%02d',m*10+10),...
            'ele',sprintf('%02d',n*10+30));
        angularDistance = computeAngularDistance(imageMap, angleParams);
        stimulusGenerator(angularDistance, stimParams, filebase);        
    end
end

end