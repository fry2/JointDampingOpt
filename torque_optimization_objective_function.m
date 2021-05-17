function [outVal,pmTorque] = torque_optimization_objective_function(tE,pE,simText,inVec)   
    inMat = reshape(inVec,[2 38])';
    
    mInds = find(contains(simText,'<Type>LinearHillMuscle</Type>'));
    for ii = 1:38
        muscInd = mInds(ii);
        % Insert Kp and Lr into SimText at the correct locations
            kp = inMat(ii,1); lr = inMat(ii,2)/1e4; ks = kp*100;
            kpInd = find(contains(simText(muscInd:end),'<Kpe>'),1,'first')+muscInd-1;
                simText{kpInd} = replaceBetween(simText{kpInd},'>','</',num2str(kp));
            lrInd = find(contains(simText(muscInd:end),'<RestingLength>'),1,'first')+muscInd-1;
                simText{lrInd} = replaceBetween(simText{lrInd},'>','</',num2str(lr));
            ksInd = find(contains(simText(muscInd:end),'<Kse>'),1,'first')+muscInd-1;
                simText{ksInd} = replaceBetween(simText{ksInd},'>','</',num2str(ks));
    end
    
    % Update joint positions with pE values
        stimNames = {'ConstantHip';'ConstantKnee';'ConstantxAnkle'};
        for ii = 1:3
            stInd = find(contains(simText,stimNames{ii}));
            simText{stInd+1} = '<AlwaysActive>True</AlwaysActive>';
            simText{stInd+2} = '<Enabled>True</Enabled>';
            simText{stInd+10} = ['<Equation>',num2str(pE(ii)),'</Equation>'];
        end
    
    % Generate a random name for this run
        [~,jobID] = fileparts(tempname);
        
    % Modify the output JointMotion and PassiveTension names so that parallel jobs don't conflict
        outfileInds = find(contains(simText,'<OutputFilename>'));
        for ii = 1:length(outfileInds)
            simLine = simText{outfileInds(ii)};
            txtPointer = strfind(simLine,'.txt');
            simText{outfileInds(ii)} = replaceBetween(simLine,simLine(1:txtPointer-1),simLine(txtPointer:end),['_',jobID]);
        end
        
    % Write simText to an ASIM document
        jobSavePath = [pwd,'\',jobID,'.asim'];
        fileID = fopen(jobSavePath,'w');
        fprintf(fileID,'%s\n',simText{:});
        fclose(fileID);
    
    % Run the ASIM file    
        obj = design_synergy(jobSavePath);
    
    % Find simulation torque
        [tSraw,~,pmTorque] = compute_passive_joint_torque(obj);
        tS = mean(tSraw(:,1e4:1.4e4),2)';
    
    % Compute output score
        diffVec = (tS-tE).^2;
        outVal = sum(diffVec,2);
        
        delete(jobSavePath,['*_',jobID,'.txt'])
end