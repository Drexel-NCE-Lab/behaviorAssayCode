function params = getTrialParams

scriptBasePath = fileparts(mfilename('fullpath'));

params = struct;

experimentPathList = {...
    'C:\linda_data\exp1';...
    'C:\hjData\exp1';
    'C:\Local Data\Data\labValidationExperiment_shamal';};

accurateEntry = false;
while(~accurateEntry)
    for n = 1:length(experimentPathList)
        fprintf('%2d: %s\n',n,experimentPathList{n});
    end
    idxStr = input('Select experiment path (#): ','s');
    try
        pathEntry = experimentPathList{str2double(idxStr)};
    catch
        disp('Invalid entry: please make another selection.');
        continue;
    end
    fprintf('Is the following information correct?\n%20s%s\n'...
        ,'Experiment path: ', pathEntry);
    entry = input('(y/N):','s');
    try
        accurateEntry = any(strcmp(entry,{'Y','y'}));
    catch
    end
end
params.rootDataDirectory = pathEntry;

params.capturePeriod = 4; %Number of seconds for WS to capture
params.fixedTrialTermination = true; %Run until fixed number of trials or until consecutive failures
imageFolder = '40rv00az00el6bd10st090end';
params.imageFolder = imageFolder;

diodeOffsetLoad = load([scriptBasePath '\calibration_parameters\diodeOffsetValue']);
params.cameraDiodeOffset = diodeOffsetLoad.diodeOffsetValue;
params.wbtDiodeOffset = diodeOffsetLoad.wbtOffsetValue;

params.rvRatio=str2double(imageFolder(1:2));
params.azimuth=str2double(imageFolder(5:6));
params.elevation=str2double(imageFolder(9:10));
params.bitDepth=str2double(imageFolder(13));
params.startSize=str2double(imageFolder(16:17));
params.endSize=str2double(imageFolder(20:22));
params.ITI = 15; %Seconds between trial initiations
params.TTC = 20; %Number of trials to run, or number of failures

% validInput = false;
% while ~validInput
%     paramInput = input('Specify platfor condition (b/s/f): ','s');
%     if strcmp('b',paramInput)
%         params.stance = 'bent';
%         validInput = true;
%     elseif strcmp('s',paramInput)
%         params.stance = 'stretched';
%         validInput = true;
%     elseif strcmp('f',paramInput)
%         params.stance = 'free';
%         validInput = true;
%     elseif strcmp('e',paramInput)
%         assert(false,'exit code entered');
%     else
%         validInput = false;
%         sprintf('Invalid Input.  ');
%     end
% end
while true
    try
        [femaleGenotype,maleGenotype] = retrieveGenotypes([params.rootDataDirectory '\genotypeDatabase']);
        params.femaleGenotype = femaleGenotype;
        params.maleGenotype = maleGenotype;
    catch ME
        if regexp(ME.identifier,'unattendedRetrieval')
            disp(ME.message)
            fprintf('Invalid entry - please choose again.\n');
            continue;
        else
            ME.rethrow;
        end
    end
    break;
end
end