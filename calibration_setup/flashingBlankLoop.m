try
    %!ConfigData/MultiMonitorTool.exe /SetPrimary \\.\DISPLAY5
    PsychDefaultSetup(2);
    
    %Screen('Preference', 'SkipSyncTests', 1);
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask','AllViews','UseGPGPUCompute','Auto');
    
    % Get the screen numbers
    screens = Screen('Screens');
    Screen('Preference', 'ConserveVRAM', 256);
    
    % Draw to the external screen if avaliable
    screenNumber = max(screens);
    
    % Define black and white
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    grey = white / 2;
    inc = white - grey;
    
    % Open an on screen window
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);
    %Blend (anti-aliasing)
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    %Screen('ColorRange', window, white);
    
    %Set the array of parameters - Can be reworked as input arg for stim gen
    %load savedParameters
    fileStem = 'test09';
    folderString = sprintf('Images/%s',fileStem);
    numFrames = size(dir(folderString),1)-2;
    waitframes = 1;
    ifi = Screen('GetFlipInterval', window);
    topPriorityLevel = MaxPriority(window);
    
    I = imread('Images/blank6bit.bmp','bmp');
    whiteTexture = Screen('MakeTexture',window,I,[],4);
    I = imread('Images/diodeBlank.bmp','bmp');
    blackTexture = Screen('MakeTexture',window,I,[],4);
    
    Priority(topPriorityLevel);
    vbl = Screen('Flip', window);
    
    % while true
    % Screen('DrawTexture', window, whiteTexture, [], [], 0);
    % Screen('Flip', window);
    % pause(0.2);
    % Screen('DrawTexture', window, blackTexture, [], [], 0);
    % Screen('Flip', window);
    % pause(0.2);
    % end
    runs = 0;
    while true
        %runs = runs+1;
        ListenChar();
        while exist('Y:\Project resources\Scripts\finished.mutex','file') == 0
            pause(0.002);
        end
        delete('Y:\Project resources\Scripts\finished.mutex');
        load acquisitionData
        pause(3.5);
        Priority(topPriorityLevel);
        %pause(1.5);
        %specify if loop should end, whitch image stack to run, etc.
        if stopCondition
            break
        end
        Screen('DrawTexture', window, whiteTexture, [], [], 0);
        vbl = Screen('Flip', window);
        
        for n = 0:10
            Screen('DrawTexture', window, blackTexture, [], [], 0);
            Screen('Flip', window);
            pause(0.2);
            Screen('DrawTexture', window, whiteTexture, [], [], 0);
            Screen('Flip', window);
            pause(0.2);
        end
        
        %return to grey background after each trial
        Screen('DrawTexture', window, whiteTexture, [], [], 0);
        Screen('Flip', window);
        Priority(0);
        semaphore = 1;
        save acquisitionData.mat stopCondition semaphore;
        id = fopen('finished.mutex','wt');
        fclose(id);
        pause(6);
    end
catch ME
    %!ConfigData/MultiMonitorTool.exe /SetPrimary \\.\DISPLAY1
    disp(ME.identifier);
    disp(ME.message);
    Priority(0);
    Screen('CloseAll');
    rethrow(ME);
    clear
end
%!ConfigData/MultiMonitorTool.exe /SetPrimary \\.\DISPLAY1
Priority(0);
Screen('CloseAll');
clear