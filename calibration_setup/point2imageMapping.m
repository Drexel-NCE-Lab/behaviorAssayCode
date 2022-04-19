
%% image of the calibration points
function tmpImg= point2imageMapping(imPoints,targetPath)

if ~exist('imPoints','var')
    TL = load('configData\calibrationPoints.mat');
    imPoints = TL.calibrationPoints{2};    
end
if ~exist('targetPath','var'); targetPath = 'Images/blank6bit.bmp';end

% imPoints = calibrationPoints{2};
xMax = 1140;
yMax = 912;
tmpImg = ones(xMax,yMax);
size(imPoints,1);
offset = 5;

for n = 1:size(imPoints,1)
    xRange = round(imPoints(n,1)-offset):round(imPoints(n,1)+offset);
    yRange = round(imPoints(n,2)-offset):round(imPoints(n,2)+offset);
    xRange(xRange<1|xRange>xMax) = [];
    yRange(yRange<1|yRange>yMax) = [];
    if ~isempty(xRange) && ~isempty(yRange)
        tmpImg(xRange,yRange) = 0;
    end
end

imwrite(tmpImg,targetPath,'bmp');
end
function thisIsAFunction()
%% camera matrix points
%clear;
%offset=5;
%tmpImg = ones(1140,912);

load('C:\Local David_share\Project resources\Scripts\behavior_assay_operation\calibration_setup\configData\calibrationPoints.mat')
load('C:\Local David_share\Project resources\Scripts\behavior_assay_operation\calibration_setup\configData\cameraMatrix.mat')

hom2euk = @(x) x(:, 1 : 2) ./ x(:, [3 3]);
worldPoints = [calibrationPoints{1} calibrationPoints{1}(:,[1 2])];
cameraPoints = [hom2euk([worldPoints(:,1:3) ...
ones(size(worldPoints,1),1)]*cameraMatrix) worldPoints(:,4:5)];



imPoints=cameraPoints(:,1);
imPoints(:,2)=cameraPoints(:,2);


for n = 1:size(imPoints,1)
    xRange = round(imPoints(n,1)-offset):round(imPoints(n,1)+offset);
    yRange = round(imPoints(n,2)-offset):round(imPoints(n,2)+offset);
    tmpImg(xRange,yRange) = 0;
end

imwrite(tmpImg,strcat('Images/','test', ...
'/','blank','6','bit','.bmp'),'bmp');


%%
clear;
load('C:\Local David_share\Project resources\Scripts\behavior_assay_operation\calibration_setup\configData\imageMap.mat')
load('C:\Local David_share\Project resources\Scripts\behavior_assay_operation\calibration_setup\configData\calibrationPoints.mat')
tmpPoints=cell2mat(calibrationPoints(1));
calPts=tmpPoints(:,1:2);
newMap=imageMap;
newMap(isnan(newMap))=0;
count=0;
for n=1:size(calPts,1)
    xMinDif=500000;
    count=count+1;
    for j=1:1140
        for k=1:912
            xDif=calPts(n,1)-newMap(j,k,1);
            xSquaredDif=xDif^2;
            if xSquaredDif < xMinDif
                xMinDif=xSquaredDif;
                xPoint(count,1)=newMap(j,k,1);
            end
        end
    end
end
count=0;
for n=1:size(calPts,1)
    yMinDif=500000;
    count=count+1;
    for j=1:1140
        for k=1:912
            yDif=calPts(n,2)-newMap(j,k,2);
            ySquaredDif=yDif^2;
            if ySquaredDif < yMinDif
                yMinDif=ySquaredDif;
                yPoint(count,1)=newMap(j,k,2);
            end
        end
    end
end
newImageMap=[xPoint,yPoint];
offset=5;
for n = 1:size(newImageMap,1)
    xRange = abs(round(newImageMap(n,1)-offset)):abs(round(newImageMap(n,1)+offset));
    yRange = abs(round(newImageMap(n,2)-offset)):abs(round(newImageMap(n,2)+offset));
    tmpImg(xRange,yRange) = 0;
end
imwrite(tmpImg,strcat('Images/','test', ...
'/','blank','6','bit','.bmp'),'bmp');
end