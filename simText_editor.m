function [simText,stimID] = simText_editor(muscName,NWmotion,cPos,ts)
    %simPath = 'C:\Users\fry16\OneDrive\Documents\JointDampingOpt\JointDampingOpt_compAnkle_Standalone.asim';
    simPath = 'G:\My Drive\Rat\SynergyControl\Animatlab\SynergyWalking\SynergyControl_Standalone.asim';
    %simPath = 'C:\Users\fry16\OneDrive\Documents\JointDampingOpt\JointDampingOpt_heavyBones_Standalone.asim';
    %simPath = 'C:\Users\fry16\OneDrive\Documents\JointDampingOpt\InjectedProject\JointDampingOpt_passVals.asim';
    %temp = load([pwd,'/sensSimData.mat'],'sensSimData_ank');
    %simText= temp.sensSimData_ank;
    simText = importdata(simPath);
    freq = 100; dt = 1/freq;

    % Start by turning off all tonic stimuli
    [simText{find(contains(simText,'<CurrentType>Tonic</CurrentType>'))-2}] = deal('<Enabled>False</Enabled>');

    % Change the datachart time step to depend dt in order to align experimental frequency to simulation
    [simText{find(contains(simText,'<TimeStep>0.00054</TimeStep>'))}] = deal(['<TimeStep>',num2str(dt/10),'</TimeStep>']);

    % Extract parameters from the ASIM file
    parGet = {['<ID>ad-',muscName,'-ID</ID>'],6};

    parGetOut = cell(size(parGet,1),1);
    for jj = 1:size(parGet,1)
        findPar = parGet{jj,1};
        outStr = simText{find(contains(simText,findPar))+parGet{jj,2}};
        temp = extractBetween(outStr,'>','<');
        parGetOut{jj,1} = temp{1};
    end

    stimID = ['<ID>stTC1-',parGetOut{1},'</ID>'];
%     stimTime0 = 2.29;
%     stimTime1 = 2.79; %find way to set these automatically based on ang waveform
    stimTime0  = dt*(length(NWmotion)-45);
    stimTime1  = dt*(length(NWmotion)+17);
    simEndTime = dt*(length(NWmotion)+17);
    %physTS = dt/10;
    physTS = .54e-3;
    timeVec = 0:dt:((length(NWmotion)-1)*dt);

    % The system level parameters we want to modify in the ASIM file organized as:
    % parameter string to find, line modifier from that string, value to set it to
    parSet = {'<SimEndTime>',0,simEndTime;...
              '<PhysicsTimeStep>',0,physTS;...
              '<ID>1b1bb75a-f9ae-4839-8124-5172f1dbddcf</ID>',8,((length(NWmotion)+16)*dt);...
              '<ID>1b1bb75a-f9ae-4839-8124-5172f1dbddcf</ID>',9,dt;...
              stimID,2,'False';...
              stimID,3,'True';...
              stimID,8,stimTime0;...
              stimID,9,stimTime1;...
              stimID,10,.1;...
              stimID,11,0;...
              stimID,12,.1;...
              stimID,13,0};

    for jj = 1:size(parSet,1)
        parInd = find(contains(simText,parSet{jj,1}))+parSet{jj,2};
        if ~isempty(parInd)
            oldStr = simText{parInd};
            simText{parInd} = replaceBetween(oldStr,'>','</',num2str(parSet{jj,3}));
        else
            warning('Parameter not found')
            keyboard
        end
    end

    % Set Joint level parameters
    jInds = find(contains(simText,'<Joint>'));
    for joint = 1:length(jInds)
        temp = find(contains(simText(jInds(joint):end),'<EnableLimits>'),1,'first')+jInds(joint)-1;
        if joint==3 || joint == 1 || joint == 2
            simText{temp} = replaceBetween(simText{temp},'>','</','True');
        else
            simText{temp} = replaceBetween(simText{temp},'>','</','False');
        end
    end

    % Set constant position stimulus
    cPosInd = 157;
    cpStart = dt*(ts.cpstart+3);
    cpEnd = dt*(ts.cpend+5);
    simText = set_const_pos_stim(simText,cPos,NWmotion(cPosInd,:),cpStart,cpEnd);
end

    function simText = set_const_pos_stim(simText,toggle,inPos,stimTime0,stimTime1)
        sInds = find(contains(simText,'<Name>Constant'));
        if nargin == 2
            inPos = [];
            stimTime0 = [];
            stimTime1 = [];
        end
        if strcmp(toggle,'on')
            constPos = (inPos-[98.4373 102.226 116.2473]).*(pi/180);
            % First, check if the joint limits are enabled and that the provided inputs are within bounds
            jInfo = [num2cell(find(contains(simText,'<Joint>'))+1),simText(find(contains(simText,'<Joint>'))+1),simText(find(contains(simText,'<EnableLimits>')))];
            for ii = 1:size(jInfo,1)
                if contains(jInfo{ii,3},'True')
                    lLine = simText(find(contains(simText(jInfo{ii,1}:end),'<LowerLimit>'),1,'first')+jInfo{ii,1}+2);
                    uLine = simText(find(contains(simText(jInfo{ii,1}:end),'<UpperLimit>'),1,'first')+jInfo{ii,1}+2);
                    lVal = double((extractBetween(string(lLine),'>','<')));
                    uVal = double((extractBetween(string(uLine),'>','<')));
                    if constPos(ii) < lVal || constPos(ii) > uVal
                        error(['Trying to set constant motor position, ',num2str((180/pi)*constPos(ii)),', outside joint limits [',num2str((180/pi)*lVal),',',...
                            num2str((180/pi)*uVal),'] for joint',jInfo{ii,2}])
                    end
                end
            end
            for ii = 1:length(sInds)
                    % AlwaysActive
                simText{sInds(ii)+1} = replaceBetween(simText{sInds(ii)+1},'>','</','False');
                    % Enabled
                simText{sInds(ii)+2} = replaceBetween(simText{sInds(ii)+2},'>','</','True');
                    % StartTime
                simText{sInds(ii)+7} = replaceBetween(simText{sInds(ii)+7},'>','</',num2str(stimTime0));
                    % EndTime
                simText{sInds(ii)+8} = replaceBetween(simText{sInds(ii)+8},'>','</',num2str(stimTime1));
                    % Position
                temp2 = [contains(simText{sInds(ii)},'Hip') contains(simText{sInds(ii)},'Knee') contains(simText{sInds(ii)},'Ankle')];
                simText{sInds(ii)+10} = replaceBetween(simText{sInds(ii)+10},'>','</',num2str(constPos(temp2)));
            end
            %disp('Constant positions turned on.')
        elseif strcmp(toggle,'off')
            for ii = 1:length(sInds)
                    % Enabled
                simText{sInds(ii)+2} = replaceBetween(simText{sInds(ii)+2},'>','</','False');
            end
            %disp('Constant positions turned off.')
        else
            error('Toggle is not set to on or off')
        end
    end