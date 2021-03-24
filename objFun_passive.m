function [outVal,jointMotion] = objFun_passive(simText,NWmotion,inVec,joint2grade,stimID,stimLevel,numZones,muscZones)
    stimVals = inVec(1:7); inVec = inVec(9:end);
    if length(inVec)==3
        inMat = repmat(inVec,numZones,1);
    else
        inMat = reshape(inVec,2,numZones)';
    end
    mInds = find(contains(simText,'<Type>LinearHillMuscle</Type>'));
    for ii = 1:length(mInds)
        b = inMat(muscZones{ii,2},1);
        kp = inMat(muscZones{ii,2},2);
        %ks = kp*inVec(8);
        ks = kp*100;
        Fmax = double(extractBetween(string(simText{find(contains(simText(mInds(ii):end),'<MaximumTension>'),1)+mInds(ii)-1}),'>','</'));
        dampInd = find(contains(simText(mInds(ii):end),'<B>'),2)+mInds(ii)-1;
        ksInd = find(contains(simText(mInds(ii):end),'<Kse>'),1,'first')+mInds(ii)-1;
        kpInd = find(contains(simText(mInds(ii):end),'<Kpe>'),1,'first')+mInds(ii)-1;
        simText{dampInd(2)} = replaceBetween(simText{dampInd(2)},'>','</',num2str(b));
        simText{ksInd} = replaceBetween(simText{ksInd},'>','</',num2str(ks));
        simText{kpInd} = replaceBetween(simText{kpInd},'>','</',num2str(kp));
        stmax = (1+kp/ks)*Fmax;
        yoff = -.01*stmax;
        stRoot = find(contains(simText(mInds(ii):end),'<StimulusTension>'),1,'first')+mInds(ii)-1;
            stUB = stRoot+7;
                simText{stUB} = replaceBetween(simText{stUB},'>','</',num2str(stmax));
            stSTmax = stRoot+9;
                simText{stSTmax} = replaceBetween(simText{stSTmax},'>','</',num2str(stmax));
            stSteep = stRoot+10;
                simText{stSteep} = replaceBetween(simText{stSteep},'>','</',num2str(459.512));
            stYoff = stRoot+11;
                simText{stYoff} = replaceBetween(simText{stYoff},'>','</',num2str(yoff));
    end
    
    currentInd = find(contains(simText,stimID),1,'first')+14;
    outStr = simText{currentInd};
    stimLevel = stimVals(stimLevel);
    if stimLevel == 0
        simText{currentInd} = replaceBetween(outStr,'>','</',num2str(stimLevel));   
    else
        simText{currentInd} = replaceBetween(outStr,'>','</',[num2str(stimLevel),'e-009']);    
    end
    
    % Generate a random name for this run
        [~,jobID] = fileparts(tempname);
        
    % Modify the output JointMotion name so that parallel jobs don't conflict
        txtInd = find(contains(simText,'OutputFilename>Joint'));
        simText{txtInd} = replaceBetween(simText{txtInd},'ion','.txt',['_',jobID]);
    
    % Write simText to an ASIM document
        jobSavePath = [pwd,'\',jobID,'.asim'];
        fileID = fopen(jobSavePath,'w');
        fprintf(fileID,'%s\n',simText{:});
        fclose(fileID);
        
    % Run the ASIM document
        sour_folder = 'C:\AnimatLabSDK\AnimatLabPublicSource\bin';
        executable = [string([sour_folder,'\AnimatSimulator']),string(jobSavePath)];
        jsystem(executable);
        
    % Import the Joint Motion data from the output .txt file
        jointMotionPath = [pwd,'\JointMotion_',jobID,'.txt'];
        try 
            ds = importdata(jointMotionPath);
        catch
            outVal = 1e9;
            jointMotion = [];
            return
        end
        try jointMotion = ds.data(:,3:5).*(180/pi);
        catch
            keyboard
        end
        
        temp(:,1) = jointMotion(1:end-9,find(contains(ds.colheaders,'Hip'))-2);
        temp(:,2) = jointMotion(1:end-9,find(contains(ds.colheaders,'Knee'))-2);
        temp(:,3) = jointMotion(1:end-9,find(contains(ds.colheaders,'Ankle'))-2);
        jointMotion = temp+[98.4373 102.226 116.2473];
        
        freq = 100; dt = 1/freq;
        timeVec = 0:dt:((370-3)*dt);
        
    % Calculate the outVal compared to NWmotion
        % Trim the the vectors until they're the same length
        minLen = min([length(jointMotion) length(NWmotion)]);
        jointMotion = jointMotion(1:minLen,:);
        NWmotion = NWmotion(1:minLen,:);
        
        diffVec = NWmotion-jointMotion;
        diff2 = NWmotion(171:minLen,:)-jointMotion(171:minLen,:);
        diff3 = NWmotion(315:minLen,:)-jointMotion(315:minLen,:);
        diff4 = (NWmotion(181,:)-NWmotion(173,:))/(181-173)-(jointMotion(181,:)-jointMotion(173,:))/(181-173);
        diff5 = NWmotion(182,:)-jointMotion(182,:);
        diff6 = NWmotion(171:218,:)-jointMotion(171:218,:);
        diff7 = NWmotion(313:minLen,:)-jointMotion(313:minLen,:);
        diff8 = (NWmotion(325,:)-NWmotion(320,:))/(325-320)-(jointMotion(325,:)-jointMotion(320,:))/(325-320);
        
        sum_square = @(inMat) sum(sum(inMat.^2,2));
        
        if strcmp(joint2grade,'all')
            outVec = [sum_square(diff6) sum_square(diff7)];
            outVecWt = outVec.*[1 1];
            outVal = sum(outVecWt);
        else
            outVal = sum(sum((diffVec(:,joint2grade)).^2));
        end
        
        delete(jointMotionPath,jobSavePath)
        %figure;plot(NWmotion,'LineWidth',2);hold on;plot(jointMotion)
end