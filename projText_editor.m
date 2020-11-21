function [projText] = projText_editor(passVals6,mInfo,stimID,NWmotion)
    %projPath = 'C:\Users\fry16\OneDrive\Documents\JointDampingOpt\JointDampingOpt_compAnkle.aproj';
    projPath = 'G:\My Drive\Rat\SynergyControl\Animatlab\SynergyWalking\SynergyControl.aproj';
    projText = importdata(projPath);
    freq = 100; dt = 1/freq;

    % Start by turning off all tonic stimuli
    [projText{find(contains(projText,'<ClassName>AnimatGUI.DataObjects.ExternalStimuli.TonicCurrent</ClassName>'))+7}] = deal('<Enabled>False</Enabled>');

    % Change the datachart time step to depend dt in order to align experimental frequency to simulation
    [projText{find(contains(projText,'<TimeStep Value="0.54"'))}] = deal(['<TimeStep Value="',num2str(dt*100),'" Scale="milli" Actual="',num2str(dt/10),'"/>']);

    %stimID = ['<ID>stTC1-',parGetOut{1},'</ID>'];
    stimTime0 = 2.29;
    stimTime1 = 2.79; %find way to set these automatically based on ang waveform
    %physTS = dt/10;
    physTS = .54e-3;
    timeVec = 0:dt:((length(NWmotion)-1)*dt);

    % The system level parameters we want to modify in the ASIM file organized as:
    % parameter string to find, line modifier from that string, value to set it to
    parSet = {'<SimEndTime',0,((length(NWmotion)-1)*dt);...
              '<PhysicsTimeStep',0,physTS;...
              stimID,5,'True';...
              stimID,1,stimTime0;...
              stimID,2,stimTime1;...
              stimID,13,.1;...
              stimID,14,0;...
              stimID,15,.1;...
              stimID,16,0};

    for jj = 1:size(parSet,1)
        parInd = find(contains(projText,parSet{jj,1}))+parSet{jj,2};
        if ~isempty(parInd)
            oldStr = projText{parInd};
            projText{parInd} = insert_content_into_line(oldStr,parSet{jj,3});
        else
            warning('Parameter not found')
            keyboard
        end
    end

    % Open the joint motion AFORM file and edit it
    jAformPath = 'C:\Users\fry16\OneDrive\Documents\JointDampingOpt\InjectedProject\JointMotion_injected.aform';
    jAformData = importdata(jAformPath);
    endTimeInd = find(contains(jAformData,'<CollectEndTime'));
    stepInd = find(contains(jAformData,'<UpdateDataInterval'));
    jAformData{endTimeInd} = insert_content_into_line(jAformData{endTimeInd},((length(NWmotion)-2)*dt));
    jAformData{stepInd} = insert_content_into_line(jAformData{stepInd},dt);
    % Write simText to an ASIM document
    fileID = fopen(jAformPath,'w');
    fprintf(fileID,'%s\n',jAformData{:});
    fclose(fileID);
    
    jmInds = find(contains(projText,'JointMotion'));
    for ll = 1:length(jmInds)
        projText{jmInds(ll)} = strrep(projText{jmInds(ll)},'JointMotion','JointMotion_injected');
    end
  
    if size(passVals6,1) == 1
        passVals6 = reshape(passVals6,3,length(passVals6)/3)';
    end
    
    for tt = 1:size(mInfo,1)
        b = passVals6(mInfo{tt,2},1); ks = passVals6(mInfo{tt,2},2); kp = passVals6(mInfo{tt,2},3);
        mInd = find(contains(projText,mInfo{tt,1}));
        Fmax = double(extractBetween(string(projText{find(contains(projText(mInd:end),'<MaximumTension'),1)+mInd-1}),'Value="','"'));
        ksInd = find(contains(projText(mInd:end),'<Kse Value='),1,'first')+mInd-1;
        kpInd = ksInd + 1;
        bInd = ksInd + 2;
        projText{bInd} = insert_content_into_line(projText{bInd},b);
        projText{ksInd} = insert_content_into_line(projText{ksInd},ks);
        projText{kpInd} = insert_content_into_line(projText{kpInd},kp);
        stmax = (ks+kp)/ks*Fmax;
        yoff = -.007*stmax;
        stRoot = find(contains(projText(mInd:end),'<StimulusTension>'),1,'first')+mInd-1;
            stUB = stRoot+12;
                projText{stUB} = insert_content_into_line(projText{stUB},stmax);
            stSTmax = stRoot+16;
                projText{stSTmax} = insert_content_into_line(projText{stSTmax},stmax);
            stSteep = stRoot+17;
                projText{stSteep} = insert_content_into_line(projText{stSteep},459.512);
            stYoff = stRoot+18;
                projText{stYoff} = insert_content_into_line(projText{stYoff},yoff);
    end
    
    % Set Joint level parameters
    jInds = find(contains(projText,'<Joint>'));
    for joint = 1:length(jInds)
        temp = find(contains(projText(jInds(joint):end),'<EnableLimits>'),1,'first')+jInds(joint)-1;
        if joint==3 || joint == 1 || joint == 2
            projText{temp} = replaceBetween(projText{temp},'>','</','True');
        else
            projText{temp} = replaceBetween(projText{temp},'>','</','False');
        end
    end

    % Write simText to an ASIM document
    fileID = fopen('C:\Users\fry16\OneDrive\Documents\JointDampingOpt\InjectedProject\JointDampingOpt_injected.aproj','w');
    fprintf(fileID,'%s\n',projText{:});
    fclose(fileID);

end
    function outLine = insert_content_into_line(oldStr,content)
        quoteLocs = strfind(oldStr,'"');
        if ~ischar(content)
            content = num2str(content);
        end
        if isempty(quoteLocs)
            outLine = replaceBetween(oldStr,'>','</',content);
        else
            outLine = [oldStr(1:quoteLocs(1)),content,oldStr(quoteLocs(2):quoteLocs(3)),...
                'None',oldStr(quoteLocs(4):quoteLocs(5)),content,oldStr(quoteLocs(6):end)];
        end
    end