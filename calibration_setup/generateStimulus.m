function generateStimulus(angularDistance, luminanceAdjustment, stimulusParams, filebase,diodeBounds)
% load centeredDistance
% load luminanceAdjustment
% filebase = 'centered';
% stimulusParams = [240, 8, 1/2.25, 6];
% %stimulusParams = [400, 40, 2.5/2, 2];

% filebase = '40rv00az00el6bd10st090end'
% stimulusParams = [400, 40, 1.5/2.25,6]
%frequency(Hz), r/v ratio(ms), end radius(rad), bit depth
mkdir(strcat('Images/',filebase));

%initial value of t at 15 degrees visual angle
bitDepth = stimulusParams(4);
framesPerImage = 24/bitDepth;
maxStimRadius = stimulusParams(3);
%Set max time point to occur at 10 degrees, or pi/36 radians
tMax = stimulusParams(2)/tan(pi/36);
tMin = stimulusParams(2)/tan(maxStimRadius);%time of max stim size (ms)
duration = tMax-tMin;
frames = round(stimulusParams(1)*(duration)*.001);%refresh frequency times presentation duration
deltaT = 1000/stimulusParams(1);
%save centeredDistance angularDistance

framesCounter = 0;
imageCounter = 0;
clearBuffer = zeros(1140,912,'uint32');
imageBuffer = clearBuffer;

%Generate blank image


output = ones(size(angularDistance));
output(isnan(angularDistance)) = 0;
%Adjust the pixels to percent max luminance
output = output./luminanceAdjustment;
%Normalize values to the max within the display area, then convert to
%unsigned integers
output = uint8(255*(output/max(output(:))));
output(diodeBounds(1,1):diodeBounds(1,2),diodeBounds(2,1):diodeBounds(2,2)) = uint8(255);
for n=1:framesPerImage
    imageBuffer = imageBuffer.*(2^bitDepth)+...
        uint32(bitsrl(output,(8-bitDepth)));
end
%Projector remaps bytes to GRB order
nPixels = numel(imageBuffer);
rgbBuffer = zeros([size(imageBuffer),4],'uint8');

% for n = 1:nPixels
%     [row,col] = ind2sub(size(imageBuffer),n);
%     rgbBuffer(row,col,:) = typecast(imageBuffer(n),'uint8');
% end
% 

for m = 1:3
    RGBCells{m} = uint8(bitand(imageBuffer,uint32(255)));
    imageBuffer = bitsrl(imageBuffer,8);
end
RGBimage = cat(3,RGBCells{1},RGBCells{2},RGBCells{3});
imwrite(RGBimage,strcat('Images/',filebase, ...
    '/','blank',num2str(stimulusParams(4)),'bit','.bmp'),'bmp');


for n = 0:frames
    t = tMax-n*deltaT;
    stimRadius = atan(stimulusParams(2)/t);
    %stimRadius = 0.5;
    %Set pixels outside projection region and inside stim radius to off state
    output(angularDistance<=stimRadius | isnan(angularDistance)) = 0;
    output(diodeBounds(1,1):diodeBounds(1,2),diodeBounds(2,1):diodeBounds(2,2)) = uint8(0);
    %imshow(output);
    if framesCounter<framesPerImage
        imageBuffer = imageBuffer.*(2^bitDepth)+...
            uint32(bitsrl(output,8-bitDepth));
        framesCounter = framesCounter+1;
    end
    if framesCounter == framesPerImage
        %Projector remaps bytes to GRB order
        for m = 1:3
            RGBCells{m} = uint8(bitand(imageBuffer,uint32(255)));
            imageBuffer = bitsrl(imageBuffer,8);
        end
        
        RGBimage = cat(3,RGBCells{1},RGBCells{2},RGBCells{3});
        imwrite(RGBimage,strcat('Images/',filebase, ...
            '/',filebase,sprintf('%05d',imageCounter),'.bmp'),'bmp');
        imageBuffer = clearBuffer;
        framesCounter = 0;
        imageCounter = imageCounter+1;
    end
end
if framesCounter ~=0
    %fill out remaining bits w/ even gray
    while framesCounter<framesPerImage        
%         output = ones(size(angularDistance));
%         %Set pixels outside projection region and inside stim radius to off state
%         %Adjust the pixels to percent max luminance
%         output = output./luminanceAdjustment;
%         output(isnan(angularDistance)) = 0;
%         
%         %Normalize values to the max within the display area, then convert to
%         %unsigned integers
%         output = uint8(255*(output/max(output(:))));
%         %imshow(output);
        if framesCounter<framesPerImage
        imageBuffer = imageBuffer.*(2^bitDepth)+...
            uint32(bitsrl(output,8-bitDepth));
        framesCounter = framesCounter+1;
        end

    end
    
    %Projector remaps bytes to GRB order
        for m = 1:3
            RGBCells{m} = uint8(bitand(imageBuffer,uint32(255)));
            imageBuffer = bitsrl(imageBuffer,8);
        end
        
        RGBimage = cat(3,RGBCells{1},RGBCells{2},RGBCells{3});
    imwrite(RGBimage,strcat('Images/',filebase, ...
        '/',filebase,sprintf('%05d',imageCounter),'.bmp'),'bmp');
    imageBuffer = clearBuffer;
    imageCounter = imageCounter+1;
end
%Generate final image to hold last stimulus indefinately
for n=1:framesPerImage
    imageBuffer = imageBuffer.*(2^bitDepth)+...
        uint32(bitsrl(output,8-bitDepth));
end
%Projector remaps bytes to GRB order
for m = 1:3
    RGBCells{m} = uint8(bitand(imageBuffer,uint32(255)));
    imageBuffer = bitsrl(imageBuffer,8);
end

RGBimage = cat(3,RGBCells{1},RGBCells{2},RGBCells{3});
imwrite(RGBimage,strcat('Images/',filebase, ...
    '/',filebase,sprintf('%05d',imageCounter),'.bmp'),'bmp');


end