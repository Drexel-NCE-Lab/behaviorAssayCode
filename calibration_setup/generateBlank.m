function generateBlank( bitDepth, luminanceAdjustment, angularDistance,diodeBounds)
%generateBlank Generate an isoluminant blank image of specified bit depth
%   Use the calculated luminance adjustment mask and the display bounds
%   specified in the angular distance mask to generate a blank image for
%   display between stimulus presentations

output = ones(size(luminanceAdjustment));
%Adjust the pixels to percent max luminance
output = output./luminanceAdjustment;
%Match the display bounds to what was specified for the angularDistance
%mask
output(isnan(angularDistance)) = 0;
%Normalize values to the max within the display area, then convert to
%unsigned integers
outBuffer = zeros(size(output),'uint32');
%Normalize the luminance range
output = uint8(255*(output/max(output(:))));
%Set the pixels w/in the photodiode location high
output(diodeBounds(1,1):diodeBounds(1,2),diodeBounds(2,1):diodeBounds(2,2)) = uint8(255);
%Convert the frames into a 24bit RGB image
output = bitsrl(output,(8-bitDepth));
framesPerImage = 24/bitDepth;
for n=1:framesPerImage
   outBuffer = outBuffer.*(2^bitDepth);
   outBuffer = outBuffer+uint32(output);
end
for n = 1:3
   RGBCells{n} = uint8(bitand(outBuffer,uint32(255)));
   outBuffer = bitsrl(outBuffer,8);
end

RGBImage = cat(3,RGBCells{1},RGBCells{2},RGBCells{3});

%imwrite(RGBImage,sprintf('Images/blank6bit.bmp'),'bmp');
imwrite(RGBImage,sprintf('Images/blank%dbit.bmp',bitDepth),'bmp');
end

