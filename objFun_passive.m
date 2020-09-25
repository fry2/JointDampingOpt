function [outVal,jointMotion] = objFun_passive(simText,NWmotion,inVec,joint2grade,stimID,stimLevel,numZones,muscZones)
    if length(inVec)==3
        inMat = repmat(inVec,numZones,1);
    else
        inMat = reshape(inVec,3,numZones)';
    end
    mInds = find(contains(simText,'<Type>LinearHillMuscle</Type>'));
    for ii = 1:length(mInds)
        dampInd = find(contains(simText(mInds(ii):end),'<B>'),2)+mInds(ii)-1;
        ksInd = find(contains(simText(mInds(ii):end),'<Kse>'),1,'first')+mInds(ii)-1;
        kpInd = find(contains(simText(mInds(ii):end),'<Kpe>'),1,'first')+mInds(ii)-1;
        simText{dampInd(2)} = replaceBetween(simText{dampInd(2)},'>','</',num2str(inMat(muscZones{ii,2},1)));
        simText{ksInd} = replaceBetween(simText{ksInd},'>','</',num2str(inMat(muscZones{ii,2},2)));
        simText{kpInd} = replaceBetween(simText{kpInd},'>','</',num2str(inMat(muscZones{ii,2},3)));
    end
    
    currentInd = find(contains(simText,stimID),1,'first')+14;
    outStr = simText{currentInd};
    simText{currentInd} = replaceBetween(outStr,'>','</',[num2str(stimLevel),'e-009']);
    
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
        ds = importdata(jointMotionPath);
        jointMotion = ds.data(:,3:5).*(180/pi);
        
        temp(:,1) = jointMotion(1:end-9,find(contains(ds.colheaders,'Hip'))-2);
        temp(:,2) = jointMotion(1:end-9,find(contains(ds.colheaders,'Knee'))-2);
        temp(:,3) = jointMotion(1:end-9,find(contains(ds.colheaders,'Ankle'))-2);
        jointMotion = temp+[98.4373 102.226 116.2473];
        
        freq = 100; dt = 1/freq;
        timeVec = 0:dt:((370-3)*dt);
        
    % Calculate the outVal compared to NWmotion
        % Trim the front of the vectors until they're the same length
        minLen = min([length(jointMotion) length(NWmotion)]);
%         jointMotion = jointMotion((length(jointMotion)-minLen):length(jointMotion),:);
%         NWmotion = NWmotion((length(NWmotion)-minLen):length(NWmotion),:);
        jointMotion = jointMotion(1:minLen,:);
        NWmotion = NWmotion(1:minLen,:);
        
%         startInd = 273; endInd = 358;%358
%         selInds = [48:196,startInd:endInd];
%         diffVec = NWmotion(selInds,:)-jointMotion(selInds,:);
        diffVec = NWmotion-jointMotion;
        
        if strcmp(joint2grade,'all')
            outVal = sum(sum((diffVec).^2));
        else
            outVal = sum(sum((diffVec(:,joint2grade)).^2));
        end
        
        delete(jointMotionPath,jobSavePath)
end