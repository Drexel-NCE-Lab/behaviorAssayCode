function [f,Cz] = adjustParameterValues()
K = @(f) [f*1.948*243.2 0 0;0 f*243.2 0;1140/2 456 1];
Rz = @(gamma) [cos(gamma) -sin(gamma) 0;sin(gamma) cos(gamma) 0;0 0 1];
Ry = @(beta) [cos(beta) 0 sin(beta);0 1 0; -sin(beta) 0 cos(beta)];
Rx = @(alpha) [1 0 0;0 cos(alpha) -sin(alpha); 0 sin(alpha) cos(alpha)];
R = @(alpha,beta,gamma) Rz(gamma)*Ry(beta)*Rx(alpha);
hom2euk = @(x) x(:, 1 : 2) ./ x(:, [3 3]);

TL = load('camParameters.mat');
parameters = TL.parameters;
TL = load('configData\calibrationPoints.mat');
calibrationPoints = TL.calibrationPoints;
alpha = parameters(1);
beta = parameters(2);
gamma = parameters(3);
Cx = parameters(4);
Cy = parameters(5);
Cz = parameters(6);
f = parameters(7);

KbName('UnifyKeyNames');
UpArrow = KbName('UpArrow');
DownArrow = KbName('DownArrow');
LeftArrow = KbName('LeftArrow');
RightArrow = KbName('RightArrow');
doneKey = KbName('return');

PsychDefaultSetup(2);

Screen('Preference', 'SkipSyncTests', 1);

% Draw to the external screen if avaliable
% screenNumber = max(screens);
screenNumber = 1;



% Define black and white
white = WhiteIndex(screenNumber);
grey = white / 2;

% Open an on screen window
[window, ~] = PsychImaging('OpenWindow', screenNumber, grey);
%Blend (anti-aliasing)
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
%Screen('ColorRange', window, white);
I = 255*ones(1140,912,'uint8');

% Make the image into a texture
imageTexture = Screen('MakeTexture', window, I, [],2);

% Draw the image to the screen, unless otherwise specified PTB will draw
% the texture full size in the center of the screen. We first draw the
% image in its correct orientation.
Screen('DrawTexture', window, imageTexture, [], [], 0);

% Flip to the screen
Screen('Flip', window);
Screen('close',imageTexture);

%Calculate how long the function runs - used for timing the redraw
%of the screen to improve performance and diminish flicker effects
tic;
done = 0;
while done == 0
    %Approximation of the pixel location of the requested point -
    %should be swapped to calculate this from initially requested
    %points at corner of image prior to loop start
    
    fprintf('Z: %3.1f, f %2.1f\n:',Cz,f);
    %Only redraw the screen once every second
    if toc > 1
        
        cameraMatrix = [R(alpha,beta,gamma); Cx Cy Cz]*K(f);
        worldPoints = [calibrationPoints{1} calibrationPoints{1}(:,[1 2])];
        cameraPoints = [hom2euk([worldPoints(:,1:3) ...
            ones(size(worldPoints,1),1)]*cameraMatrix) worldPoints(:,4:5)];
        I = point2imageMapping(cameraPoints);
        
        %                 I = clean;
        %                 I(center(1)-1:center(1)+1,:) = 0;
        %                 I(:,center(2)-1:center(2)+1) = 0;
        % Make the image into a texture
        imageTexture = Screen('MakeTexture', window, I, [],2);
        
        % Draw the image to the screen, unless otherwise specified PTB will draw
        % the texture full size in the center of the screen. We first draw the
        % image in its correct orientation.
        Screen('DrawTexture', window, imageTexture, [], [], 0);
        
        % Flip to the screen
        Screen('Flip', window);
        Screen('close',imageTexture);
        tic;
    end
    % Check for keypress, get the keycode and update the proper
    % coordinate, or move onto next point on 'enter'
    [down, ~, keyCode] = KbCheck;
    if down
        if keyCode(UpArrow)
            Cz = Cz*1.005;
            f = f*1.005;
            %'upArrow'
        elseif keyCode(DownArrow)
            Cz = Cz*.995;
            f = f*.995;
            %'downArrow'
        elseif keyCode(RightArrow)
            f = f*1.005;
            %'rightArrow'
        elseif keyCode(LeftArrow)
            f = f*.995;
            %'leftArrow'
        elseif keyCode(doneKey)
            
            done = 1;
            %Save the world point and its image point pair
            cornerPoints(index,:) = center;
            %Insert a wait period before letting the loop check for
            %keypress again to ensure it doesn't skip a coordinate
            %inadvertantly due to longish keypress
            WaitSecs(1.5);
            %'doneKey'
        end
        %Timeout to make it possible to actually update by single
        %pixels
        WaitSecs(0.1);
    else
        %Timeout to diminish excess resource consumption while
        %awaiting input
        WaitSecs(0.01);
    end
end
fprintf('Final parameters:\n');
fprintf('Z: %3.1f, f %2.1f\n:',Cz,f);
save ConfigData/parameters.mat Cz f
