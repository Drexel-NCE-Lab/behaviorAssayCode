function missedIntervals = testPtbPresentationLoop(scriptPath,delay)

currentTime = GetSecs();
stopCondition = false;
targetVbl = currentTime+delay;
save([scriptPath '/acquisitionData.mat'],'stopCondition','targetVbl');
id = fopen([scriptPath '/WSDone.mutex'],'wt');
fclose(id);

while exist([scriptPath '\PTBDone.mutex'],'file') == 0
    pause(0.2);
end
delete([scriptPath '\PTBDone.mutex']);
ptbData = load([scriptPath '/acquisitionData.mat']);
missedIntervals = ptbData.missed;

end