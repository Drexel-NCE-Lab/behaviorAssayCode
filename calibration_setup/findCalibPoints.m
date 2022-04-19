function calibrationPoints = findCalibPoints()
KbName('UnifyKeyNames');
UpArrow = KbName('UpArrow');
DownArrow = KbName('DownArrow');
LeftArrow = KbName('LeftArrow');
RightArrow = KbName('RightArrow');
doneKey = KbName('return');

PsychDefaultSetup(2);

Screen('Preference', 'SkipSyncTests', 1);

% Get the screen numbers
screens = Screen('Screens');

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
clean = I;
center = [570 456];
%imshow(I);
I(center(1)-1:center(1)+1,:) = 0;
I(:,center(2)-1:center(2)+1) = 0;

% Make the image into a texture
imageTexture = Screen('MakeTexture', window, I, [],2);

% Draw the image to the screen, unless otherwise specified PTB will draw
% the texture full size in the center of the screen. We first draw the
% image in its correct orientation.
Screen('DrawTexture', window, imageTexture, [], [], 0);

% Flip to the screen
Screen('Flip', window);
Screen('close',imageTexture);

%Generate matrices to hold coordinates of world and camera point pairs -
%Currently hard coded interval and range - could be swapped for param call
%here
yMin = -2;
yMax = 2;
xMin = -1.5;
xMax = 1.5;
step = 0.5;
yRange = yMin:step:yMax;
arcRange = xMin:step:xMax;
dataSize = length(yRange)*length(arcRange);

cameraPoints = zeros(dataSize,2);
worldPoints = zeros(dataSize,3);
cornerPoints = zeros(4,2);

index = 0;
for Y = [yMin yMax]
    for arc = [xMin xMax]
        index = index+1;
        
        %Approximation of the pixel location of the requested point -
        %should be swapped to calculate this from initially requested
        %points at corner of image prior to loop start
        center = uint64([(arc-xMin)*345+65 (Y-yMin)*198+18]);
        fprintf('Location of azimuth %02d, elevation %02d\n:',arc,Y);
        
        %Calculate how long the function runs - used for timing the redraw
        %of the screen to improve performance and diminish flicker effects
        tic;
        done = 0;
        while done == 0
            %Only redraw the screen once every second
            if toc > 1
                I = clean;
                I(center(1)-1:center(1)+1,:) = 0;
                I(:,center(2)-1:center(2)+1) = 0;
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
                    center(2) = center(2)+1;
                    %'upArrow'
                elseif keyCode(DownArrow)
                    center(2) = center(2)-1;
                    %'downArrow'
                elseif keyCode(RightArrow)
                    center(1) = center(1)+1;
                    %'rightArrow'
                elseif keyCode(LeftArrow)
                    center(1) = center(1)-1;
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
    end
end

%use the specified corners to generate a bilinear interpolation
%approximation of there the remaining gridpoints are
yLength = length(yRange);
xLength = length(arcRange);
yMinRange = floor(linspace(cornerPoints(1,1),cornerPoints(2,1),xLength));
yMaxRange = floor(linspace(cornerPoints(3,1),cornerPoints(4,1),xLength));
xMinRange = floor(linspace(cornerPoints(1,2),cornerPoints(3,2),yLength));
xMaxRange = floor(linspace(cornerPoints(2,2),cornerPoints(4,2),yLength));

radius = 2.25;
index = 0;
for n = 1:yLength
    Y = yRange(n);
    for m = 1:xLength
        arc = arcRange(m);
        index = index+1;
        
        %Approximation of the pixel location of the requested point -
        %should be swapped to calculate this from initially requested
        %points at corner of image prior to loop start
        center(1) = (yMinRange(m)*(yLength-n)+yMaxRange(m)*(n-1))/(yLength-1);
        center(2) = (xMinRange(n)*(xLength-m)+xMaxRange(n)*(m-1))/(xLength-1);
        fprintf('Location of azimuth %02d, elevation %02d\n:',arc,Y);
        
        %Calculate how long the function runs - used for timing the redraw
        %of the screen to improve performance and diminish flicker effects
        tic;
        done = 0;
        while done == 0
            %Only redraw the screen once every second
            if toc > 1
                I = clean;
                I(center(1)-1:center(1)+1,:) = 0;
                I(:,center(2)-1:center(2)+1) = 0;
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
                    center(2) = center(2)+1;
                    %'upArrow'
                elseif keyCode(DownArrow)
                    center(2) = center(2)-1;
                    %'downArrow'
                elseif keyCode(RightArrow)
                    center(1) = center(1)+1;
                    %'rightArrow'
                elseif keyCode(LeftArrow)
                    center(1) = center(1)-1;
                    %'leftArrow'
                elseif keyCode(doneKey)

                    done = 1;
                    %Save the world point and its image point pair
                    worldPoints(index, :) = [radius*sin(arc/radius),Y,...
                        radius*cos(arc/radius)];
                    cameraPoints(index,:) = center;
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
    end
end
calibrationPoints{1} = worldPoints;
calibrationPoints{2} = cameraPoints;
save ConfigData/calibrationPoints.mat calibrationPoints
