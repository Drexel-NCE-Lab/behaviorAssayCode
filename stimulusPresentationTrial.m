function [targetVbl,dataFilePath] = stimulusPresentationTrial(params,subjectVars,data,targetVbl,sweepCount)
model = subjectVars.model;
controller = subjectVars.controller;
subjectFolder = subjectVars.subjectFolder;
scriptBasePath = subjectVars.scriptBasePath;
debugOn = subjectVars.debugOn;
intertrialInterval = params.ITI;
capturePeriod = params.capturePeriod;

nFrames = 1300*capturePeriod;
wsCapturePeriod = capturePeriod+2;

stopCondition = false;

baseName = sprintf('%02d',sweepCount);
trialFolder = [subjectFolder filesep baseName];
dataFilePath = [trialFolder filesep baseName '_0001.h5'];
tmpLocation = sprintf('%s/%s','D:',datestr(now,'yyyymmdd_HHMMSS'));

data.dataLocations{sweepCount+1} = {tmpLocation;trialFolder}; %#ok<*AGROW>
    if debugOn
        fprintf('Sweep Count: %02d\nTemporary path: %s\nPermanent Path: %s\n'...
            ,sweepCount,tmpLocation,trialFolder);
    end
try
    status = mkdir(trialFolder);
    assert(status==1,'Unable to create directory: %s\n',trialFolder);
    imageTmpFolder = [tmpLocation '/tmp'];
    status = mkdir(imageTmpFolder);
    assert(status==1,'Unable to create directory: %s\n',imageTmpFolder);
    sourcePath = [scriptBasePath '/grabFrames.exe'];
    targetPath = [tmpLocation '/grabFrames.exe'];
    status = copyfile(sourcePath,targetPath);
    assert(status==1,'Copy operation failed - source: %s target: %s\n',sourcePath,targetPath);
catch ME
    fprintf(2,'Unable to setup temporary files in memory.\n');
    rethrow(ME);
end
model.Logging.FileLocation = trialFolder;
model.Logging.FileBaseName = baseName;
if debugOn
    fprintf('Temporary folder setup - time since loop start: %0.2f\n',toc());
end

%We're now ready to start the sweep - release the semaphore
if targetVbl == 0
    targetVbl = GetSecs();
    currentTime = GetSecs();
    targetVbl = targetVbl+intertrialInterval;
    if debugOn
        fprintf('Target VBL set - Target: %0.2f, Current: %0.2f, Delta: %0.2f\n'...
            ,targetVbl,currentTime,targetVbl-currentTime);
    end
else
    currentTime = GetSecs();
    targetVbl = targetVbl+intertrialInterval;
    if debugOn
        fprintf('Target VBL set - Target: %0.2f, Current: %0.2f, Delta: %0.2f\n'...
            ,targetVbl,currentTime,targetVbl-currentTime);
    end
    if currentTime>targetVbl-wsCapturePeriod
        if debugOn
            fprintf('TargetVbl window too short - extended\n');
        end
        targetVbl = currentTime+wsCapturePeriod;
        data.missedTrials(end+1) = sweepCount;
    end
end
save([scriptBasePath '/acquisitionData.mat'],'stopCondition','targetVbl');
id = fopen([scriptBasePath '/WSDone.mutex'],'wt');
fclose(id);

if debugOn
    fprintf('WS mutex released: %0.2f\n',toc());
end
%Wait until ready to start acquisition - about 1-2s before
%presentation start
wsTarget = targetVbl-2;

%Set the pwd to our temp folder before the run then switch back -
%script saves tmp images based on relative path
pwd = cd(tmpLocation);
sysCommand = sprintf('grabFrames.exe %d %d &',nFrames,uint32(wsTarget*1000));
if debugOn
    fprintf('Current Time: %0.2f Target WS start: %0.2f Target VBL: %0.2f\n',currentTime,wsTarget,targetVbl);
    fprintf('WS delta: %0.2f VBL delta: %0.2f\n',wsTarget-currentTime,targetVbl-currentTime);
    fprintf('Camera capture system command: %s\n',sysCommand);
end
system(sysCommand);
cd(pwd);
%start acquisition
if debugOn
    fprintf('Camera capture command sent, pre recording: %0.2f\n',toc());
end
controller.record;
terminalTime = toc();
if debugOn
    fprintf('Recording completed, pre data parsing: %0.2f\n',terminalTime);
end
if terminalTime<intertrialInterval-wsCapturePeriod
    data.missedTrials(end+1) = sweepCount;
end

end