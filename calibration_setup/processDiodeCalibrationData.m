%%Function for calculating the appropriate camera offset from luminance
%%recorded from reflected projection screen during stimulus presentation

function diodeOffset = processDiodeCalibrationData(calibrationDataFolder)
%pwd = cd(calibrationDataFolder);
if ~exist('calibrationDataFolder','var');calibrationDataFolder = uigetdir('Z:\Exp_Data\David\Data');end
% tmp = load('ConfigData/diodeOffsetValue');
% diodeOffset = tmp.diodeOffsetValue;
tmp = load([calibrationDataFolder '/dataSummary.mat']);
dataTable = struct2table(tmp.dataList);
tmp = load([calibrationDataFolder '/parameters.mat']);
diodeOffset = tmp.metadata.cameraDiodeOffset;
files = dir(calibrationDataFolder);
nDirectories = length(find([files.isdir]))-3;
meanLuminances = cell(nDirectories,1);
frameTimings = cell(nDirectories,1);
frameDelta = zeros(nDirectories,1);

%For each directory, read in each image stack, get mean luminances, and
%load in frame timings - create mean luminance, time series, and frameDelta
%arrays for processing function
for trial = 0:nDirectories-1
    sourceFolder = sprintf('%s/%02d/images',calibrationDataFolder,trial);
    nImages = size(dir(sourceFolder),1)-2;
    meanImageLuminanceArray = zeros(nImages,1);
    for index = 0:nImages-1
        filename = sprintf('%s/%04d.pgm',sourceFolder,index);
%         fid = fopen(filename,'r');
        I = uint8(imread(filename,'pgm')');
%         fclose(fid);
        
        I = I(41:120,31:90);
        meanImageLuminanceArray(index+1) = mean(I(5:end));
    end
    timeInSeconds = [];
    load(sprintf('%s/../frameTiming.mat',sourceFolder),'timeInSeconds');
    save(sprintf('%s/../meanLuminance.mat',sourceFolder),'meanImageLuminanceArray');
    frameTimings{trial+1} = timeInSeconds;
    meanLuminances{trial+1} = meanImageLuminanceArray;
    frameDelta(trial+1) = mean(timeInSeconds(2:end)-timeInSeconds(1:end-1));
end
        
% for trial = 0:nDirectories-1
%     destinationFolder = sprintf('%s/%02d/images',calibrationDataFolder,trial);
%     sourceFolder = sprintf('%s/%02d/raw',calibrationDataFolder,trial);
%     %save images to 'image' folder under the destination base directory
%     mkdir(destinationFolder);
%     %Get the number of images to process
%     nImages = size(dir(sourceFolder),1)-2;
%     %Pre-allocate the timestamp array
%     rawTimeArray = zeros(nImages,3);
%     meanImageLuminanceArray = zeros(nImages,1);
%     seconds = 0;
%     for index = 0:nImages-1
%         %Read in the raw image data
%         filename = sprintf('%s/FlyCapture2Test-16283804-%d.raw',sourceFolder,index);
%         %filename = strcat(sourceFolder,'/FlyCapture2Test-16283804-',sprintf('%d',index),'.raw');
%         fid = fopen(filename,'r');
%         %Convert the raw binary to an image matrix of the proper dimensions
%         I = uint8(fread(fid,[160 120],'uint8')');
%         fclose(fid);
%         %Extract the 4 metadata bytes
%         rawTimestampTuple = I(1,1:4);
%         %Write the processed image out to the destination directory
%         imwrite(I,sprintf('%s/%04d.%s',destinationFolder,index,'pgm'));
%         delete(filename);
%         
%         %Reduce to ROI
%         I = I(41:120,31:90);
%         pixelMean = mean(I(:));
%         meanImageLuminanceArray(index+1) = pixelMean;
%         
%         
%         %Convert the 4 bytes into a single 32 bit integer
%         time = zeros(1,'uint32');
%         for n = 1:4
%             time = bitsll(time,8)+uint32(rawTimestampTuple(n));
%         end
%         max32 = uint32(4294967295);
%         %Extract the 12 cycle offset bits
%         cycleOffset = bitsrl(bitand(bitsrl(max32,20),time),4);
%         time = bitsrl(time,12);
%         
%         %Extract the 13 cycleCount bits and teh remaining 7 second bits
%         cycleCount = bitand(bitsrl(max32,19),time);
%         newSeconds = bitsrl(time,13);
%         %If the seconds counter resets mid collection, add 128 to it - could
%         %need modification if data collection ever extended past 2 minutes for
%         %a single frame sequence
%         if newSeconds<seconds
%             seconds = newSeconds+128;
%         else
%             seconds = newSeconds;
%         end
%         
%         %Save the raw time counters to an array
%         rawTimestampTuple = [seconds cycleCount cycleOffset];
%         
%         rawTimeArray(index+1,:) = rawTimestampTuple;
%     end
%     %Convert the raw counters to a seconds value and save at destination root
%     %folder
%     timeInSeconds = double(rawTimeArray(:,1))+0.000125*(double(rawTimeArray(:,2))...
%         +.005*double(rawTimeArray(:,3))); 
%     save(sprintf('%s/../frameTiming.mat',destinationFolder),'timeInSeconds');
%     save(sprintf('%s/../meanLuminance.mat',destinationFolder),'meanImageLuminanceArray');
%     frameTimings{trial+1} = timeInSeconds;
%     meanLuminances{trial+1} = meanImageLuminanceArray;
%     frameDelta(trial+1) = mean(timeInSeconds(2:end)-timeInSeconds(1:end-1));
%     rmdir(sourceFolder);
% end

frameDelta = mean(frameDelta);
save('programState.mat');
frameFrequency = 1/frameDelta;
% lowPassFilt = designfilt('lowpassfir','PassbandFrequency', ...
%     30*2*pi/frameFrequency,'StopbandFrequency',40*2*pi/frameFrequency,...
%     'PassbandRipple',.2,'StopbandAttenuation',95,'DesignMethod','kaiserwin');
% notchFilter2 = designfilt('bandstopiir','FilterOrder',2, ...
%     'HalfPowerFrequency1',70,'HalfPowerFrequency2',138, ...
%     'DesignMethod','butter','SampleRate',frameFrequency);

% notchFilter100 = designfilt('bandstopiir','FilterOrder',2, ...
% 'HalfPowerFrequency1',94,'HalfPowerFrequency2',106, ...
% 'DesignMethod','butter','SampleRate',frameFrequency);
% notchFilter200 = designfilt('bandstopiir','FilterOrder',2, ...
% 'HalfPowerFrequency1',194,'HalfPowerFrequency2',206, ...
% 'DesignMethod','butter','SampleRate',frameFrequency);
% notchFilter300 = designfilt('bandstopiir','FilterOrder',2, ...
% 'HalfPowerFrequency1',294,'HalfPowerFrequency2',306, ...
% 'DesignMethod','butter','SampleRate',frameFrequency);
% notchFilter400 = designfilt('bandstopiir','FilterOrder',2, ...
% 'HalfPowerFrequency1',360,'HalfPowerFrequency2',440, ...
% 'DesignMethod','butter','SampleRate',frameFrequency);
% notchFilter500 = designfilt('bandstopiir','FilterOrder',2, ...
% 'HalfPowerFrequency1',494,'HalfPowerFrequency2',506, ...
% 'DesignMethod','butter','SampleRate',frameFrequency);
% notchFilter600 = designfilt('bandstopiir','FilterOrder',2, ...
% 'HalfPowerFrequency1',594,'HalfPowerFrequency2',606, ...
% 'DesignMethod','butter','SampleRate',frameFrequency);

notchFilter100 = fdesign.notch('N,F0,BW',2,100,12,frameFrequency);
notchFilter200 = fdesign.notch('N,F0,BW',2,200,12,frameFrequency);
notchFilter300 = fdesign.notch('N,F0,BW',2,300,12,frameFrequency);
notchFilter400 = fdesign.notch('N,F0,BW',2,400,80,frameFrequency);
notchFilter500 = fdesign.notch('N,F0,BW',2,500,12,frameFrequency);
notchFilter600 = fdesign.notch('N,F0,BW',2,600,12,frameFrequency);
signalFilter = dfilt.cascade(...
    design(notchFilter100), ...
    design(notchFilter200), ...
    design(notchFilter300), ...
    design(notchFilter400), ...
    design(notchFilter500), ...
    design(notchFilter600));

adjustedLuminanceSeries = zeros(nDirectories,400);
filteredData = cell(nDirectories);
for trial = 1:nDirectories
%     filteredData{trial} = filtfilt(notchFilter400,filtfilt(notchFilter100,...
%         filtfilt(notchFilter500,filtfilt(notchFilter600,filtfilt(notchFilter200,...
%         filtfilt(notchFilter300,meanLuminances{trial}))))));

    filteredData{trial} = filtfilt(signalFilter,meanLuminances{trial});    
    
    %filteredData{trial} = filtfilt(notchFilter2,filtfilt(lowPassFilt,meanLuminances{trial}));
    %Remove previously incorporated diode offset - may need to subtract 1
    %sec to correct for old wsT0 calculation bug
    cameraTimeOnset = dataTable.stimulusOnsetCameraTime(trial)+diodeOffset;
    onsetFrame = find(frameTimings{trial}>cameraTimeOnset,1);
    intervalPosition = frameTimings{trial}(onsetFrame)-cameraTimeOnset;
    frameOneRatio = intervalPosition/frameDelta;
    frameTwoRatio = 1-frameOneRatio;
    adjustedSeries = frameOneRatio * filteredData{trial}(onsetFrame-100:onsetFrame+299) + ...
                     frameTwoRatio * filteredData{trial}(onsetFrame-99:onsetFrame+300);
    adjustedLuminanceSeries(trial,:) = adjustedSeries';
end

processedSeries = mean(adjustedLuminanceSeries);
processedSeriesDerivatives = processedSeries(2:end)-processedSeries(1:end-1);
baselineStd = std(processedSeriesDerivatives(1:80));
baselineMean = mean(processedSeriesDerivatives(1:80));
threshold = baselineMean-3*baselineStd;
firstDeflection = find(processedSeriesDerivatives<threshold,1);
diodeOffset = (firstDeflection-99.5)*frameDelta*-1;
%cd(pwd);
end