  
scriptBasePath = fileparts(mfilename('fullpath'));
cleanupObj = onCleanup(@() cleanup(scriptBasePath));

%Image presentation path retrieval from controller
wsData = load([scriptBasePath '/acquisitionData.mat']);
imageIdStr = wsData.imageFolder;
imageBasePath = [scriptBasePath '/stimulusImageStacks/' imageIdStr];
nFrames = size(dir(imageBasePath),1)-2;
    
Screen('Preference', 'SkipSyncTests', 1);
%Default setup for the toolbox
PsychDefaultSetup(2);

%Setup PTB to run on the GPU
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask','AllViews','UseGPGPUCompute','Auto');

% Get the screen numbers
screens = Screen('Screens');
%I'm pretty sure this option was related to possible sync issues
Screen('Preference', 'ConserveVRAM', 256);

% Draw to the external screen if avaliable
%screenNumber = max(screens); %Seems to assign main monitor to screen 2
screenNumber = 1;

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;
inc = white - grey;

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);
%Blend (anti-aliasing)
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%House keeping - get the interframe interval and specifiy frame update
%frequency, as well as what priority to elevate to when presenting
waitframes = 1;
ifi = Screen('GetFlipInterval', window);
topPriorityLevel = MaxPriority(window);

%Grab the luminance corrected blank white image for 6 bit depth - should
%likely be switch to path or argument in call instead of hard coded
I = imread([scriptBasePath '/stimulusImageStacks/blank6bit.bmp'],'bmp');
blankTexture = Screen('MakeTexture',window,I,[],4);

imageTexture = repmat(blankTexture,nFrames,1);

% Render the images into a texture stack in memory for rapid drawing to the
% buffer
for n = 0:nFrames-1
    I = imread(sprintf('%s/%s%05d.bmp',imageBasePath,imageIdStr,n),'bmp');
    imageTexture(n+1) = Screen('MakeTexture', window, I, [],4);
end

%Draw the blank texture to the screen and get the current clock timing
Screen('DrawTexture', window, blankTexture, [], [], 0);
vbl = Screen('Flip', window);
ListenChar();

%Loop for testing flip timing under various conditions
%missedPresentations = zeros(3000,1);
% count = 1;
while true
    %Allow keyboard input while PTB is running
    ListenChar();
    %Loop here until the acquisition control script finishes writing to the
    %acquisitionData file and creates the mutex to signal this script to
    %continue
    while exist([scriptBasePath '\WSDone.mutex'],'file') == 0
        Screen('DrawTexture', window, blankTexture, [], [], 0);
        [vbl,~,~,missed,~] = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        %missedPresentations(count) = missed;
%         if count==3000
%            save missedFrames missedPresentations;
%            break;
%         end
%         count = count+1;        
    end
    %Remove the mutex once we've recieved the signal, and load in the
    %settings and data in acquisitionData - specifies if the script should
    %terminate and the target time of the next stimulus initiation
    %currently - can be expanded as needed, eg)stim stack to display
    delete([scriptBasePath '\WSDone.mutex']);
    wsData = load([scriptBasePath '/acquisitionData.mat']);
    try
    targetVbl = wsData.targetVbl;
    stopCondition = wsData.stopCondition;
    catch ME
        disp([scriptBasePath '/acquisitionData.mat'])
        disp(wsData)
    end
    missed = zeros(nFrames,1);
    Priority(topPriorityLevel);
    %Terminate script if the stop bit is set
    if stopCondition
        break
    end
    
    vbl = targetVbl;
    % Draw the first texture to the buffer, the flip to the screen at
    % specified VBL timing
    Screen('DrawTexture', window, imageTexture(1), [], [], 0);
    [vbl,~,~,missed(1),~] = Screen('Flip', window, vbl);
    
    startVBL = vbl;
    
    for n = 2:nFrames  
        % Draw the next texture to buffer, then flip to screen at the next
        % timing interval
        Screen('DrawTexture', window, imageTexture(n), [], [], 0);
        [vbl,~,~,missed(n),~] = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    end
    
    %Pause for 1 sec with the stimulus on screen before resetting
%     pause(1);
pause(4);
    
    %return to grey background after each trial
    Screen('DrawTexture', window, blankTexture, [], [], 0);
    Screen('Flip', window);
    Priority(0);
    save([scriptBasePath '/acquisitionData.mat'],'startVBL','missed');
    id = fopen('PTBDone.mutex','wt');
    fclose(id);
end
cleanup(scriptBasePath)
function cleanup(scriptBasePath)
system(['"' scriptBasePath '\MultiMonitorTool.exe" /SetPrimary \\.\DISPLAY6 &']);
Priority(0);
Screen('CloseAll');
clear
end