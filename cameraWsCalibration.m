function wsT0 = cameraWsCalibration(subjectVars)
model = subjectVars.model;
controller = subjectVars.controller;
subjectFolder = subjectVars.subjectFolder;
scriptBasePath = subjectVars.scriptBasePath;

%Run a configuration routine on the camera to get the offset between
%the PC and camera clocks
calibrationFolder = [subjectFolder '/calibration'];
tmpFolder = sprintf('D:/%s',datestr(now,'yyyymmdd_HHMMSS'));
try
    imageTmpFolder = [tmpFolder '/tmp'];
    status = mkdir(imageTmpFolder);
    assert(status==1,'Unable to create directory: %s\n',imageTmpFolder);
    status = mkdir(calibrationFolder);
    assert(status==1,'Unable to create directory: %s\n',calibrationFolder);
    sourcePath = [scriptBasePath '/calibrateTimestamps.exe'];
    targetPath = [tmpFolder '/calibrateTimestamps.exe'];
    status = copyfile(sourcePath,targetPath);
    assert(status==1,'Copy operation failed - source: %s target: %s\n',sourcePath,targetPath);
catch ME
    fprintf(2,'Unable to setup temporary files in memory.\n');
    rethrow(ME);
end

%Load settings for camera calibration run
model.openProtocolFileGivenFileName([scriptBasePath '/calibrationProtocol.cfg']);
model.Logging.FileLocation = calibrationFolder;
model.Logging.FileBaseName = 'calibration';

numImages = 0;
count = 1;
while numImages<8
    pwd = cd(tmpFolder);
    system(sprintf('calibrateTimestamps.exe %d %0.0f &',8,0));
    cd(pwd);
    %start acquisition
    controller.record;
    
    numImages = size(dir(imageTmpFolder),1)-2;
    if numImages<8
        count = count+1;
        ME = MException('CalibrationError:InvalidFileNumber','Calibration failed. Check device status and configuration and restart.');
        ME.throw
    end
end
processTrialImageStack(imageTmpFolder,calibrationFolder);
timingData = load([calibrationFolder '/frameTiming.mat']);
timeInSeconds = timingData.timeInSeconds;
filename = sprintf('%s/calibration_%04d.h5',calibrationFolder,count);
wsTimestamp = datetime(h5read(filename,'/header/ClockAtRunStart'));
runStart = seconds(h5read(filename,sprintf('/sweep_%04d/timestamp',count)));
%Depending on framerate, the camera either buffers the first trigger or
%uses it.  I have no idea why, but this checks which it did and adjusts
%the calibration accordingly
if timeInSeconds(8)-timeInSeconds(7)>1.5
    offset = seconds(median(timeInSeconds(1:7)'-(3:9)));
else
    offset = seconds(median(timeInSeconds(1:7)'-(2:8)));
end
wsT0 = (wsTimestamp+runStart)-offset; %#ok<NASGU>
save([subjectFolder,'/wsT0.mat'],'wsT0');
end