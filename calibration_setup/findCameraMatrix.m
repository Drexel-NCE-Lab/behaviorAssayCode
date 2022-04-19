function [cameraMatrix,translationVector,parameters] = findCameraMatrix(calibrationPoints)

%load calibrationPoints
%Setup the function handles to establish the framework of the
%transformation matrix with K and R
K = @(f,ratio) [f*ratio*243.2 0 0;0 f*243.2 0;1140/2 912/2 1];
Rz = @(gamma) [cos(gamma) -sin(gamma) 0;sin(gamma) cos(gamma) 0;0 0 1];
Ry = @(beta) [cos(beta) 0 sin(beta);0 1 0; -sin(beta) 0 cos(beta)];
Rx = @(alpha) [1 0 0;0 cos(alpha) -sin(alpha); 0 sin(alpha) cos(alpha)];
R = @(alpha,beta,gamma) Rz(gamma)*Ry(beta)*Rx(alpha);
hom2euk = @(x) x(:, 1 : 2) ./ x(:, [3 3]);

ratio = 1.948;

%horizontal, elevation, depth
Pworld = calibrationPoints{1};
Pcam = calibrationPoints{2};
% Pworld = [0 2.25 2.25;
%     0 -2.25 2.25;
%     2.25*sin(-0.3/2.25) 2.25 2.25*cos(-0.3/2.25);
%     2.25*sin(-0.3/2.25) -2.25 2.25*cos(-0.3/2.25)];
% Pcam = [1140-710 863;
%         1140-710 20;
%         1140-820 863;
%         1140-820 16];

xCoords = Pworld(:,1);
yCoords = Pworld(:,2);

[~ ,xIdxa, xIdxc] = unique(xCoords);
[~, yIdxa ,yIdxc] = unique(yCoords);

nXPoints = numel(xIdxa);
nYPoints = numel(yIdxa);

xPoints = zeros(nYPoints,nXPoints);
yPoints = zeros(nYPoints,nXPoints);

linIdx = sub2ind([nYPoints,nXPoints],yIdxc(:),xIdxc(:));

xPoints(linIdx) = Pcam(:,1);
yPoints(linIdx) = Pcam(:,2);

xDist = xPoints(:,3:end)-xPoints(:,1:end-2);
yDist = yPoints(3:end,:)-yPoints(1:end-2,:);

xDist = [xDist(:,1) xDist xDist(:,end)];
yDist = [yDist(1,:); yDist; yDist(end,:)];


errorWeight = 1./(((xDist+yDist)/2).^2);


%solve(Pcam == hom2euk((K*R*[eye(3) C]*[Pworld ones(size(Pworld,1),1)]')'))
fun = @(alpha,beta,gamma,Cx,Cy,Cz,f,ratio,worldPoints) ...
    hom2euk([worldPoints(:,1:3) ones(size(worldPoints,1),1)]*...
    [R(alpha,beta,gamma); Cx Cy Cz]*K(f,ratio));

%f(Pworld(:,1),Pworld(:,2),Pworld(:,3))
%test = nlinfit(Pworld,Pcam(:,1),f,[1;1;1;1;1;1;1])

%estimate initial conditions - iterate through a reasonable range of values
%to determine initial condition approximation for error minimization
%function
% squaredError = (Pcam - fun(0,0,0,0,0,5,5,ratio,Pworld)).^2;
minVal = Inf;
% 0:pi/6:(2*pi-pi/6)

for alpha = 0:pi:pi
    for beta = 0:pi:pi
        for gamma = 0:pi:pi
            for Cx = [-2 2]
                for Cy = [2 -2]
                    for Cz = [-9 9]
                        for f = [4 6]
                            %Find the sum of the squared distances between
                            %image points and mapping
                            pm = [pi,pi,pi,Cx,Cy,Cz,f,ratio];
                            
                            fError =@(parameters) sum(sum(errorWeight(linIdx).*(Pcam - fun(alpha-parameters(1),beta-parameters(2),gamma-parameters(3),...
                                        parameters(4),parameters(5),parameters(6),parameters(7),parameters(8),Pworld)).^2));

                            [paramEst, sumError,~,~] = fminsearch(fError,pm,optimset('TolX',1e-6,'TolFun',1e-6,'MaxFunEvals',2000,'MaxIter',1500,'Display','off'));
                            
%                             squaredError = (Pcam - fun(alpha,beta,gamma,Cx,Cy,Cz,f,ratio,Pworld)).^2;
%                             sumError = sum(squaredError(:));
                            if sumError<minVal
                                minVal = sumError;
                                parameters = [alpha-paramEst(1),beta-paramEst(2),gamma-paramEst(3),paramEst(4),paramEst(5),paramEst(6),paramEst(7),paramEst(8)];
                            end
                        end
                    end
                end
            end
        end
    end
end

%Use annealing to minimize the squared distance error - Alter one parameter
%at a time a fixed distance lower and higher than its current value,
%calculating the new error under each condition.  If the lowest error found
%this way is lower than the error found under the initial conditions, the
%parameter is changed to this new value and the process is repeated.  If no
%lower error is produced, the temperature is scaled down by a percentage
%and the process repeated until the temperature reduces below some desired
%value

% %Scale factor for the deviation from current conditions to check
% temperature = .1;
% %Initial value to check for error reductions at
% baseAngle = pi/4;
% baseDistance = 3;
% while temperature>0.0000000000001
%     error = zeros(8,2);
%     deltaAngle = temperature*baseAngle;
%     deltaDistance = temperature*baseDistance;
%     %Find the error for the parameter both lower and higher then current,
%     %then return to original value before checking next parameter
%     for n = 1:3
%         parameters(n)=parameters(n)-deltaAngle;
%         squaredError = errorWeight(linIdx).*(Pcam - fun(parameters(1),parameters(2),parameters(3),...
%             parameters(4),parameters(5),parameters(6),parameters(7),parameters(8),Pworld)).^2;
%         error(n,1) = sum(squaredError(:));
%         parameters(n)=parameters(n)+2*deltaAngle;
%         squaredError = errorWeight(linIdx).*(Pcam - fun(parameters(1),parameters(2),parameters(3),...
%             parameters(4),parameters(5),parameters(6),parameters(7),parameters(8),Pworld)).^2;
%         error(n,2) = sum(squaredError(:));
%         parameters(n)=parameters(n)-deltaAngle;
%     end
% %     for n = 4:7
%     for n = 4:8
%         parameters(n)=parameters(n)-deltaDistance;
%         squaredError = errorWeight(linIdx).*(Pcam - fun(parameters(1),parameters(2),parameters(3),...
%             parameters(4),parameters(5),parameters(6),parameters(7),parameters(8),Pworld)).^2;
%         error(n,1) = sum(squaredError(:));
%         parameters(n)=parameters(n)+2*deltaDistance;
%         squaredError = errorWeight(linIdx).*(Pcam - fun(parameters(1),parameters(2),parameters(3),...
%             parameters(4),parameters(5),parameters(6),parameters(7),parameters(8),Pworld)).^2;
%         error(n,2) = sum(squaredError(:));
%         parameters(n)=parameters(n)-deltaDistance;
%     end
%     
%     %Find the value and index of the minimum error from the deviations
%     [newMin,minIndex] = min(error(:));
%     %New min is lower - set as new min and run again with new parameter
%     if minVal > newMin
%         minVal = newMin;
%         [x,y] = ind2sub(size(error),minIndex);
%         if y==1
%             if x<4
%                 parameters(x) = parameters(x)-deltaAngle;
%             else
%                 parameters(x) = parameters(x)-deltaDistance;
%             end
%         else
%             if x<4
%                 parameters(x) = parameters(x)+deltaAngle;
%             else
%                 parameters(x) = parameters(x)+deltaDistance;
%             end
%         end
%     else
%            
%         temperature = temperature*.8;
%     end
% end
% parameters = paramEst;

alpha = parameters(1);
beta = parameters(2);
gamma = parameters(3);
Cx = parameters(4);
Cy = parameters(5);
Cz = parameters(6);
f = parameters(7);
ratio = parameters(8);
translationVector = parameters(4:6);
projectorPosition = -1*translationVector*R(alpha,beta,gamma)';
cameraMatrix = [R(alpha,beta,gamma); Cx Cy Cz]*K(f,ratio);
save ConfigData/cameraMatrix.mat cameraMatrix projectorPosition

end
