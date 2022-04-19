%Before running, ensure:
%Projector is on, pattern presentation started
%DAQ board is on
%Window focus is returned to PTB after sequence initiation


function runDataAcquisitionController(params,debugFlag)
fprintf('Running data acquisition with the following parameters:\n');
disp(params);
fprintf('Cross ID: %s\n\n',generateUniqueGenotypeString(params));
inString = input('Is this accurate? (y/N): ','s');
if ~strcmp('y',inString)
    error('Incorrect parameter values.  Run ''getTrialParams'' and try again.')
end


if exist('debugFlag','var')
    debugOn = strcmp(debugFlag,'debug');
else
    debugOn = false;
end

trialNumber = params.TTC;
imageFolder = params.imageFolder;
fixedTrialTermination = params.fixedTrialTermination;
rootDataDirectory = params.rootDataDirectory;
scriptBasePath = fileparts(mfilename('fullpath'));

data = dataStorage();

data.scriptBasePath = scriptBasePath;
data.debugOn = debugOn;
cleanupObj = onCleanup(@() cleanup(data));

%Setup acquisition run
%Setup the base data directory for this acquisition run
subjectFolder = setupExperimentDirectory(rootDataDirectory);
data.subjectFolder = subjectFolder;
metadata = params;
save([subjectFolder,'/parameters.mat'],'metadata');

%Set the projector is the primary monitor - important for proper image
%presentation timings in PTB
system(['"' scriptBasePath '\MultiMonitorTool.exe" /SetPrimary \\.\DISPLAY5']);

%Check if the logical drive is created - if not, set it up
if((exist('D:/','file')~=7))
    system(['"' scriptBasePath '\createLogicalDrive.exe" &']);
end

%Setup data to transfer to image presentation subprocess
stopCondition = false;
targetVbl = 0;
save([scriptBasePath '/acquisitionData.mat'],'stopCondition','targetVbl','imageFolder');
sweepCount = 0;

%Run the image presentation script - currently hard coded to just run
%through a designated image folder, but should be easy to transition to
%being able to pass the desired image stack to present

data.jobHandle = batch('runPtbStimulusPresentation','CurrentFolder',scriptBasePath);
%jobHandle = batch('flashingBlankLoop','CurrentFolder','Y:\Project resources\Scripts');

%Start up wavesurfer, and run a test sweep - gets WS loaded into memory
%to prevent timing issues later
subjectVars = struct;

[model,controller] = wavesurfer;
%Move our display windows back to the now secondary monitor
system(['"' scriptBasePath '\MultiMonitorTool.exe" /MoveWindow 5 Title "Wavesurfer" /WindowLeft -1208 /WindowTop 8']);
system(['"' scriptBasePath '\MultiMonitorTool.exe" /MoveWindow 5 Title "Display" /WindowLeft -1918 /WindowTop 8 /WindowHeight 1000']);
controller.play;

data.controller = controller;
subjectVars.model = model;
subjectVars.controller = controller;
subjectVars.subjectFolder = subjectFolder;
subjectVars.scriptBasePath = scriptBasePath;
subjectVars.debugOn = debugOn;



% Run a configuration routine on the camera to get the offset between
% the PC and camera clocks
wsT0 = cameraWsCalibration(subjectVars);

% Load up our configuration settings for acquisition sweeps
model.openProtocolFileGivenFileName([scriptBasePath '/wavesurferAcquisitionProtocol_001.cfg']);

% Acquisition loop - currently configured to run until terminated, but
% reconfiguration for programmed acquisition sequences should be a
% trivial transformation of the stop condition logic
input('start acquisition?');
disp('Starting data acquisition...');
pause(8);
failure = 0;


while ~stopCondition
    tic();
    % If we're going to do an sweep, setup the folders for data storage
    % and the tmp folders for images, to ensure we don't overlap with
    % previous runs
    
    [targetVbl,dataFilePath] = stimulusPresentationTrial(params,subjectVars,data,targetVbl,sweepCount);
    
    count = 0;
    dataExists = exist(dataFilePath,'file');
    while ~dataExists
        pause(0.5);
        count = count+1;
        dataExists = exist(dataFilePath,'file');
        if count>3
            error('File does not exist: %s',dataFilePath);
        end
    end
    results = analyzeTrialData(dataFilePath);
    if debugOn
        fprintf('Post data analysis, pre failure check: %0.2f\n',toc());
    end
    % increment our failure counter, or reset it based on behavior,
    % ignoring preflight trials
    if ~results.preflight
        if results.likelyTakeoff
            failure = 0;
        else
            failure = failure+1;
        end
    end
    fprintf('Sequential failed flight initiations: %02d\n',failure);
    %Append the results to data summary array
    if isempty(data.dataList); data.dataList = results;
    else; data.dataList(end+1,1) = results;end
    %Wait for the presentation script to pass back the semaphore before
    %continuing, then load the data it passed back
    if debugOn
        fprintf('Post dataList append, pre PTB mutex hold: %0.2f\n',toc());
    end
    while exist([scriptBasePath '\PTBDone.mutex'],'file') == 0
        pause(0.2);
    end
    delete([scriptBasePath '\PTBDone.mutex']);
    PTBdata = load([scriptBasePath '/acquisitionData.mat']);
    if debugOn
        fprintf('Post PTB mutex hold, pre stop condition check: %0.2f\n',toc());
    end
    
    sweepCount = sweepCount + 1;
    
    % Habituation protocol
    if failure>=trialNumber
        stopCondition = true;
    end
    % Fixed trial number protocol
    if fixedTrialTermination && sweepCount>=trialNumber
        stopCondition = true;
    end
end
end

function cleanup(varIn)
if varIn.debugOn == 1
    disp(varIn)
end
%Save the data summaries to disk
if ~isempty(varIn.subjectFolder) && ~isempty(varIn.dataList)
    dataList = varIn.dataList;
    missedTrials =  varIn.missedTrials;
    save([varIn.subjectFolder '/dataSummary.mat'],'dataList','missedTrials');
end
if ~isempty(varIn.controller);varIn.controller.quit;end
if ~varIn.debugOn && ~isempty(varIn.dataLocations)
    tmp = load([varIn.scriptBasePath '\memDataLocations.mat'],'dataLocations');
    dataLocations = [tmp.dataLocations,varIn.dataLocations];
    save([varIn.scriptBasePath '\memDataLocations.mat'], 'dataLocations');
    warning('UNSAVED DATA WILL BE LOST.  Run ''transferTemporaryFiles'' if last subject is completed');
end
if exist([varIn.scriptBasePath '\PTBDone.mutex'],'file')
    delete([varIn.scriptBasePath '\PTBDone.mutex']);
end
if exist([varIn.scriptBasePath '/acquisitionData.mat'],'file')
    delete([varIn.scriptBasePath '/acquisitionData.mat']);
end
if exist([varIn.scriptBasePath '\WSDone.mutex'],'file')
    delete([varIn.scriptBasePath '\WSDone.mutex']);
end
system(['"' varIn.scriptBasePath '\MultiMonitorTool.exe" /SetPrimary \\.\DISPLAY6 &']);
if ~isempty(varIn.jobHandle)
    varIn.jobHandle.cancel;
end

end

