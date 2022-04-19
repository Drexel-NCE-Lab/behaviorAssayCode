function [meanImageLuminanceArray, frameTimings] = getMeanImageLuminances(sourceFolder,targetFolder)


%Get the number of images to process
nImages = size(dir(sourceFolder),1)-2;
%Pre-allocate the timestamp array
rawTimeArray = zeros(nImages,3);
meanImageLuminanceArray = zeros(nImages,1);
seconds = 0;
for index = 0:nImages-1
    %Read in the raw image data
    filename = sprintf('%s/FlyCapture2Test-16283804-%d.raw',sourceFolder,index);
    %filename = strcat(sourceFolder,'/FlyCapture2Test-16283804-',sprintf('%d',index),'.raw');
    fid = fopen(filename,'r');
    %Convert the raw binary to an image matrix of the proper dimensions
    pixels = uint8(fread(fid,[160 120],'uint8')');
    fclose(fid);
    %Extract the 4 metadata bytes
    rawTimestampTuple = pixels(1,1:4);
    
    pixelMean = mean(pixels(5:end));
    meanImageLuminanceArray(index+1) = pixelMean;
    
    
    %Convert the 4 bytes into a single 32 bit integer
    time = zeros(1,'uint32');
    for n = 1:4
        time = bitsll(time,8)+uint32(rawTimestampTuple(n));
    end
    max32 = uint32(4294967295);
    %Extract the 12 cycle offset bits
    cycleOffset = bitsrl(bitand(bitsrl(max32,20),time),4);
    time = bitsrl(time,12);
    
    %Extract the 13 cycleCount bits and the remaining 7 second bits
    cycleCount = bitand(bitsrl(max32,19),time);
    newSeconds = bitsrl(time,13);
    %If the seconds counter resets mid collection, add 128 to it - could
    %need modification if data collection ever extended past 2 minutes for
    %a single frame sequence
    if newSeconds<seconds
        seconds = newSeconds+128;
    else
        seconds = newSeconds;
    end
    
    %Save the raw time counters to an array
    rawTimestampTuple = [seconds cycleCount cycleOffset];
    
    rawTimeArray(index+1,:) = rawTimestampTuple;
end
frameTimings = double(rawTimeArray(:,1))+0.000125*(double(rawTimeArray(:,2))...
    +.005*double(rawTimeArray(:,3)));
save(sprintf('%s/frameTiming.mat',targetFolder),'frameTimings');
save(sprintf('%s/meanLuminance.mat',targetFolder),'meanImageLuminanceArray');



end