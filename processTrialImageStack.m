%Script to transfer the image files from the specified source folder to the
%specified destination, extracting and processing the timestamp metadata in
%the process
function processTrialImageStack(sourceFolder, destinationFolder)
%save images to 'image' folder under the destination base directory
[status, ~, ~] = mkdir(destinationFolder);
assert(status==1,'Failed to create destination folder: %s',destinationFolder);
%Get the number of images to process
numImages = size(dir(sourceFolder),1)-2;
%Pre-allocate the timestamp array
timeValues = zeros(numImages,3);
secs = 0;

v = VideoWriter([destinationFolder filesep 'movie.mj2'],'Archival');
v.FrameRate = 500;
v.open;
try
for index = 0:numImages-1
    %Read in the raw image data
    filename = strcat(sourceFolder,'/FlyCapture2Test-16283804-',sprintf('%d',index),'.raw');
    fid = fopen(filename,'r');
    %Convert the raw binary to an image matrix of the proper dimensions
    I = uint8(fread(fid,[160 120],'uint8')');
    fclose(fid);
    %Write the processed image out to the destination directory
%     imwrite(I,sprintf('%s/%04d.%s',destinationFolder,index,'pgm'));
    v.writeVideo(I);
    delete(filename);
    
    %Extract the 4 metadata bytes
    timeArray = I(1,1:4);
    
    %Convert the 4 bytes into a single 32 bit integer
    time = zeros(1,'uint32');
    for n = 1:4
        time = bitsll(time,8)+uint32(timeArray(n));
    end
    max32 = uint32(4294967295);
    %Extract the 12 cycle offset bits
    cycleOffset = bitsrl(bitand(bitsrl(max32,20),time),4);
    time = bitsrl(time,12);
    
    %Extract the 13 cycleCount bits and teh remaining 7 second bits
    cycleCount = bitand(bitsrl(max32,19),time);
    newSeconds = bitsrl(time,13);
    %If the seconds counter resets mid collection, add 128 to it - could
    %need modification if data collection ever extended past 2 minutes for
    %a single frame sequence
    if newSeconds<secs
        secs = newSeconds+128;
    else
        secs = newSeconds;
    end
    
    %Save the raw time counters to an array
    timeArray = [secs cycleCount cycleOffset];
    
    timeValues(index+1,:) = timeArray;
end
catch ME
    v.close
    rethrow(ME)
end
v.close
rmdir(sourceFolder,'s');
%Convert the raw counters to a seconds value and save at destination root
%folder
timeInSeconds = double(timeValues(:,1))+0.000125*(double(timeValues(:,2))...
    +.005*double(timeValues(:,3))); %#ok<NASGU>
save(sprintf('%s/frameTiming.mat',destinationFolder),'timeInSeconds');
end