function analyzeDiodeWbtCameraCalibration(filePath)
filePath = 'C:\Data\20170228\20170228_130945\00\/00_0001.h5';

if ~exist('filePath','var')
    oldPwd = cd('Z:\Exp_Data\David\Data');
    [filename,pathname] = uigetfile({'*.h5'},'Select Data file');
    cd(oldPwd);
else
    [pathname,filename,ext] = fileparts(filePath);
    filename=strcat(filename,ext);
end
filename = sprintf('%s/%s',pathname,filename);

info = h5info(filename);

sweepName = info.Groups(2).Name;
sensorPath = sprintf('%s/digitalScans',sweepName);
analogPath = sprintf('%s/analogScans',sweepName);

digitalData = uint8(h5read(filename,sensorPath));
analogData = h5read(filename,analogPath);
sensorData = bitand(digitalData,uint8(1));
camData = bitand(digitalData,uint8(2));
diodeData = analogData(:,1);
wbtData = analogData(:,2);
sampleRate = h5read(filename,'/header/Acquisition/SampleRate');
sweepTimestamp = seconds(h5read(filename,'/sweep_0001/timestamp'));
clockAtRunStart = datetime(h5read(filename,'/header/ClockAtRunStart'));

runStartTime = clockAtRunStart+sweepTimestamp;
nTrials = length(camData);

%Load in calibration time point
wsT0Data = load(sprintf('%s/../%s',pathname,'wsT0.mat'));
tmp = load(sprintf('%s/../%s',pathname,'frameTiming.mat'));
frameTimings = tmp.frameTimings;
tmp = load(sprintf('%s/../%s',pathname,'meanLuminance.mat'));
meanImageLuminanceArray = tmp.meanImageLuminanceArray;
%Calculate the number of times the metadata counter has rolled over since
%calibration
wsT0 = wsT0Data.wsT0;
timeDelta = (clockAtRunStart+sweepTimestamp)-wsT0;
cycles = floor(seconds(timeDelta)/128);

oversampledCamData = double(repelem(meanImageLuminanceArray,3));
oversampledCamData = oversampledCamData/max(oversampledCamData);
diodeData = double(diodeData)/max(double(diodeData));
wbtData = double(wbtData)/max(double(wbtData));
frameDeltas = frameTimings(2:end)-frameTimings(1:end-1);

cameraRate = 1/mean(frameDeltas);
wsCameraTime = seconds(frameTimings)+wsT0;
luminanceIndices = seconds(wsCameraTime-runStartTime)*sampleRate;
luminanceDerivatives = [0;meanImageLuminanceArray(2:end)-meanImageLuminanceArray(1:end-1)];

diodeIncrementPeaks = find(luminanceDerivatives>1);
earlyEdges = [];
lateEdges = [];
earlyEdges(1) = diodeIncrementPeaks(1)-1;
for n = 1:length(diodeIncrementPeaks)-1
    if(diodeIncrementPeaks(n+1)-diodeIncrementPeaks(n)>1)
        lateEdges(end+1) = diodeIncrementPeaks(n);
        earlyEdges(end+1) = diodeIncrementPeaks(n+1)-1;
    end
end
lateEdges(end+1) = diodeIncrementPeaks(end);
cameraMidpoints = earlyEdges+(lateEdges-earlyEdges)/2;
wsCameraMidpoints = luminanceIndices(earlyEdges)+(luminanceIndices(lateEdges)-luminanceIndices(earlyEdges))/2;

[peak, diodePeaks] = findpeaks(diodeData,'MinPeakProminence',.05);
diodePeaks = diodePeaks(peak<.6);
[idx, wbtPeaks] = findpeaks(wbtData*-1,'MinPeakProminence',.2, 'Threshold',.03);
%diff(loc)
% figure
% subplot(3,1,1)
% hold on
% arrayfun(@(x) plot(meanImageLuminanceArray((floor(x)-5):(floor(x)+5))),cameraMidpoints);
% subplot(3,1,2)
% hold on
% arrayfun(@(x) plot(diodeData((floor(x)-5):(floor(x)+5))),diodePeaks);
% subplot(3,1,3)
% hold on
% arrayfun(@(x) plot(wbtData((floor(x)-5):(floor(x)+5))),wbtPeaks);
% plot(1:100,diodeData(1951:2050),1:100,oversampledCamData(1960:2059),1:100,wbtData(1951:2050))
%disp(sampleRate/cameraRate);

cameraDiodeDeltas = arrayfun(@(x) min(abs(wsCameraMidpoints-x)),diodePeaks);
% wbtDiodeDeltas = arrayfun(@(x) min(abs(wbtPeaks-x)),diodePeaks);
plot((cameraDiodeDeltas-mean(cameraDiodeDeltas))/sampleRate)
cameraDiodeDelta = mean(cameraDiodeDeltas)/sampleRate;
wbtDiodeDelta = 0;
save('ConfigData/offsetValues.mat','cameraDiodeDelta','wbtDiodeDelta');


