    tstart = tic;
    curvars = whos;
    if ~any(contains({curvars.name},'pvStruct'))
        load('pvStruct.mat')
        load('C:\Users\fry16\OneDrive\Documents\NW_data_local\muscle stim kinematics and forces\17503_datasummary.mat','kinematic*');
            kinematic_muscle_name(2,:) = lower({'LH_Illiopsoas','LH_GemellusSuperior','LH_SemitendinosusPrincipal',...
            'LH_SemitendinosusAccessory','LH_VastusLateralis','LH_BicepsFemorisPosterior','LH_BicepsFemorisAnterior'});
    end

    % Defines three different types of optimization
    % Input6 = 0, Output6 = 0: using 38 muscle parameters, refine those values and output/save 38 muscle parameters
    % Input6 = 1, Output6 = 1: using 6 muscle parameters, refine those values and output/save 6 muscle parameters
    % Input6 = 1, Output6 = 0: using 6 muscle parameters, cast those values out to the correct muscles and refine them
    input6zones = 0; out6zones = 0;

    try 
        if input6zones
            passVals = [pvStruct.pvGlobal6_stimVals,pvStruct.pvGlobal6];
            pvG_grades_old = pvStruct.pvGlobal6_grades;
        else
            passVals = [pvStruct.pvGlobal38_stimVals,pvStruct.pvGlobal38];
            pvG_grades_old = pvStruct.pvGlobal38_grades;
        end
         
    catch
        if input6zones
            passVals = repmat([46 100 100],1,6);
        else
            passVals = repmat([5 500 100],1,38);
        end
        pvG_grades_old = 1e8*ones(1,length(kinematic_currents));
    end

%% Generate the input waveforms for each muscle and trial that you want the optimizer to follow
    [maxJM,maxtrial] = NW_jointmotion_maxtrial_all(kinematic_data,0);
    clear reshapedJM
    for ii = 1:7
        temp = NW_baseliner(ii,15,kinematic_data,'all','frontalign');
        meanMat(ii,:) = [mean(temp{1}(1:200)),mean(temp{2}(1:200)),mean(temp{3}(1:200))];
        %trials2test = 4:maxtrial(ii);
        trials2test = maxtrial(ii);
        counter = 1;
        for jj = trials2test
            expJM{ii,counter} = [temp{1}(:,jj),temp{2}(:,jj),temp{3}(:,jj)];
            [reshapedJM{ii,counter}, ts{ii,counter}] = NW_reshaper(expJM{ii,counter});
            counter = counter + 1;
        end
    end

    meanIntro = mean(meanMat);
    maxtrial = sum(~cellfun(@isempty,reshapedJM),2);
    for ii = 1:7
        maxTail = (reshapedJM{ii,maxtrial(ii)}(ts{ii,maxtrial(ii)}.tcstart:end,:)-meanMat(ii,:))+meanIntro;
        for jj = 1:maxtrial(ii)
            temp = (reshapedJM{ii,jj}-meanMat(ii,:))+meanIntro;
            reshapedJM{ii,jj} = [temp(1:ts{ii,jj}.tcstart,:);maxTail];
        end
    end   
%% Begin the Optimization process
    stimLevel = 20;
    maxTimeTrial = 90; %in min
    time_predictor(maxTimeTrial);
    % Blanket change parameter values by a factor. 9:3:end is kp, 10:3:end is ks
%     for ii = 9:3:length(passVals)
%         %passVals(ii) = .9*passVals(ii);
%         passVals(ii+1) = .75*passVals(ii+1);
%     end
    
    [simText,stimID] = simText_editor(kinematic_muscle_name{2,1},reshapedJM{1},'on',ts{1});
    mTemp = zoning_sorter(simText,6);
    
    % Only change hip joint muscle Ks values
     passMat = reshape(passVals(8:end)',[3 38])';
%     hipmuscs1 = cell2mat(mTemp(:,2)) == 1;
%     hipmuscs2 = cell2mat(mTemp(:,2)) == 2;
%     hipmuscs4 = cell2mat(mTemp(:,2)) == 4;
%     passMat(hipmuscs1,2) = .5*passMat(hipmuscs1,2);
%     passMat(hipmuscs2,2) = .5*passMat(hipmuscs2,2);
%     passMat(hipmuscs4,2) = .5*passMat(hipmuscs4,2);
% %     passMat(hipmuscs1,3) = 2*passMat(hipmuscs1,3);
% %     passMat(hipmuscs2,3) = 2*passMat(hipmuscs2,3);
% %     passMat(5,1) = 8; passMat(5,2) = 1;
% %     passMat(33,1) = 3; passMat(33,2) = 1;
    %musc2reduce = [1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;30;31;32;33;34;35;36;37;38]; % all hip affectors
    musc2reduce = [1;4;5;6;7;9;10;11;14;15;30;31;32;33;34;35;37]; % hip affectors generating positive moments
    musc2reduce = [2;3;8;12;13;36;38]; % hip affectors generating negative moments
    %   % Change Kp
%     for ii = 1:length(musc2reduce)
%         newKp = .2*passMat(musc2reduce(ii),2);
%         if newKp > (passMat(musc2reduce(ii),1)/.54e-3)-passMat(musc2reduce(ii),3)
%             newKp = .9999*(passMat(musc2reduce(ii),1)/.54e-3)-passMat(musc2reduce(ii),3);
%         elseif newKp < 1
%             newKp = 1;
%         end
%         passMat(musc2reduce(ii),2) = newKp;
%     end
%     % Change Ks
%         for ii = 1:length(musc2reduce)
%             newKs = .2*passMat(musc2reduce(ii),3);
%             if newKs > (passMat(musc2reduce(ii),1)/.54e-3)-passMat(musc2reduce(ii),2)
%                 newKs = .9999*(passMat(musc2reduce(ii),1)/.54e-3)-passMat(musc2reduce(ii),2);
%             elseif newKs < 1
%                 newKs = 1;
%             end
%             passMat(musc2reduce(ii),3) = newKs;
%         end
%         passMat(19,3) = passMat(19,3)*1e-3;
%         passVals(8:end) = reshape(passMat',[1 numel(passMat)]);
    
    [passVals,mInfo,fVal,history,output] = passive_opt_for_zones(simText,reshapedJM,passVals,stimLevel,maxTimeTrial,input6zones,out6zones,ts);
    stimVals = passVals(1:7); passVals = passVals(8:end);
%% Now that we have passive values, we need to analyze their effectiveness at recreating NW waveforms
    outJM = cell(1,7); pvG_grades_new = zeros(1,7);
    if 0
        if 1
            passVals = pvStruct.pvGlobal38;
            stimVals = pvStruct.pvGlobal38_stimVals;
            mInfo = zoning_sorter(simText,38);
        else
%             load('goodPassVals3.mat','goodStimVals6','goodPassVals6')
%             passVals = [20.*ones(1,7),repmat([25 9e4 100],1,6)];
%             stimVals = goodStimVals6;
%             passVals = goodPassVals6;
            passVals = pvStruct.pvGlobal6;
            stimVals = pvStruct.pvGlobal6_stimVals;
            mInfo = zoning_sorter(simText,6);
        end
    end
    for ii = 1:7
        NWmotion_temp = reshapedJM{ii,maxtrial(ii)};
        if ~any(isnan(NWmotion_temp),'all')
            [simText,stimID] = simText_editor(kinematic_muscle_name{2,ii},NWmotion_temp,'on',ts{ii});
            numZones = length(unique(cell2mat(mInfo(:,2))));
%             [pvG_grades_new(ii),jm] = objFun_passive(simText,NWmotion_temp,passVals,'all',stimID,stimVals(ii),numZones,mInfo);
            [pvG_grades_new(ii),jm] = objFun_passive(simText,NWmotion_temp,[stimVals,passVals],'all',stimID,ii,numZones,mInfo);
            outJM{ii} = jm;
        else
            outJM{ii} = NaN(size(NWmotion_temp));
        end
    end
%% Determine whether or not to save the new values by comparing new scores to old scores
    newScore = sum(pvG_grades_new);
    oldScore = sum(pvG_grades_old);
    telapsed = toc(tstart);
    if newScore < oldScore
        disp(['New score (',num2str(newScore),') is better than old score (',num2str(oldScore),'), SAVING new values (',num2str(telapsed/60),' min).'])
        % Generate an APROJ file with the updated values
            %NWmotion = reshapedJM{1};
            [projText] = projText_editor(passVals,mInfo,stimID,reshapedJM{1}); 
        pvStruct.(['pvGlobal',num2str(numZones)]) = passVals;
        pvStruct.(['pvGlobal',num2str(numZones),'_stimVals']) = stimVals;
        pvStruct.(['pvGlobal',num2str(numZones),'_grades']) = pvG_grades_new;
        save('pvStruct.mat','pvStruct')
    else
        disp(['New score (',num2str(newScore),') is NOT better than old score (',num2str(oldScore),'), NOT saving new values (',num2str(telapsed/60),' min).'])
    end
return
%% Individual trial jointMotion and NWmotion
    trial = 3;
%     NWmotion = (reshapedJM{trial}-[98.4373 102.226 116.2473]).*(pi/180);
    NWmotion = reshapedJM{trial};
    jointMotion = outJM{trial};
    dt = .01;
    joints = 1:3; startInd = 1; endInd = min([length(NWmotion) length(jointMotion)]);
    timeVec = 0:dt:((length(NWmotion)-1)*dt);
    yLims = [min([min(jointMotion(startInd:endInd,joints),[],'all') min(NWmotion(startInd:endInd,joints),[],'all')],[],'all'),...
             max([max(jointMotion(startInd:endInd,joints),[],'all') max(NWmotion(startInd:endInd,joints),[],'all')],[],'all')];

    figure('Position',[962,2,958,994]); 
    subp(1) = subplot(2,1,1);
        plot(timeVec(startInd:endInd),NWmotion(startInd:endInd,joints),'LineWidth',2);
        legend({'Hip';'Knee';'Ankle'},'Location','northwest');
        title([kinematic_muscle_name{1,trial},' Desired Joint Motion']); 
        ylabel('Joint Angle (deg)');
        xlabel('Time (s)');
        xlim([0 max(timeVec)])
        %ylim([80 160]);
        ylim(yLims)
    subp(2) = subplot(2,1,2);
        plot(timeVec(startInd:endInd),jointMotion(startInd:endInd,joints),'LineWidth',2);
        ylim([60 200]);
        title('Simulation Results');
        ylabel('Joint Angle (deg)');
        xlabel('Time (s)');
        xlim([0 max(timeVec)])
        %ylim([80 160]);
        ylim(yLims)
%% All trials in green black subplot
    figure('Position',[962,2,958,994])
    startInd = 1; endInd = 358;%endInd = min([length(NWmotion) length(jointMotion)]);
    yLims = [min(cell2mat(cellfun(@min,[reshapedJM',outJM],'UniformOutput',false)),[],'all'), max(cell2mat(cellfun(@max,[reshapedJM',outJM],'UniformOutput',false)),[],'all')];
    for ii = 2:5
        rMax = reshapedJM{ii,maxtrial(ii)};
        % Find the ylim bounds based on the maximum values from all the trials to plot
        if min([rMax;outJM{ii}],[],'all') < yLims(1)
            yLims(1) = min([rMax;outJM{ii}],[],'all');
        end
        if max([rMax;outJM{ii}],[],'all') > yLims(2)
            yLims(2) = max([rMax;outJM{ii}],[],'all');
        end
    end     
    for ii = 1:7
        rMax = reshapedJM{ii,maxtrial(ii)}; 
        subplot(7,1,ii)
        plot(rMax(startInd:endInd,:),'g','LineWidth',2)
        hold on
        plot(outJM{ii}(startInd:endInd,:),'k','LineWidth',2)
        ylim(yLims)
        xlim([0,length(outJM{ii}(startInd:endInd,:))])
        title([kinematic_muscle_name{1,ii},' ',num2str(round(pvG_grades_new(ii)))])
    end
%% Scatter plot of muscle values
    figure('Position',[962,2,958,994])
    cm = [0,1,0;...
          1,0,0;...
          0.9216,0.8235,0.2039;...
          0,0,1;...
          1,0,1;...
          0,1,1];
    switch 0
        case 0
            muscVals = reshape(passVals,3,numZones)';
            if length(passVals)==3*6
                mTemp = cell(6,2);mTemp(:,2) = num2cell(1:6);
            else
                mTemp = zoning_sorter(simText,6);
            end
        case 1
            muscVals = reshape(pvStruct.pvGlobal38,3,38)';
            mTemp = zoning_sorter(simText,6);
        case 2
            muscVals = reshape(pvStruct.pvGlobal6,3,6)';
            mTemp = cell(6,2);mTemp(:,2) = num2cell(1:6);
        otherwise
            error('error')
    end
    for ii = 1:size(muscVals,1)
        scatter3(muscVals(ii,3),muscVals(ii,2),muscVals(ii,1),36,cm(mTemp{ii,2},:),'o','LineWidth',10)
        hold on
    end
    pbaspect([1 1 1])
    view([-47 26])
    set(gca,'xscale','log','yscale','log');
    title('Viscoelastic Muscle Parameters','FontSize',18)
    zlabel('B (Ns/m)','FontSize',18); xlabel('Ks (N/m)','FontSize',18), ylabel('Kp (N/m)','FontSize',18)
%% Plot value changes over time
    figure('Position',[962,2,958,994])
    cm = [0,1,0;1,0,0;0.9216,0.8235,0.2039;0,0,1;1,0,1;0,1,1];
    subplot(6,1,1)
        plot(output.trialX(1:7,:)-output.trialX(1:7,1))
        title('Stimulus Change')
    subplot(6,1,2)
        count = 1;
        for ii = 8:3:size(output.trialX,1)
            plot(output.trialX(ii,:)'-output.trialX(ii,1),'Color',cm(mTemp{count,2},:)); hold on; count = count + 1;
        end
        title('B Change')
    subplot(6,1,3)
        count = 1;
        for ii = 9:3:size(output.trialX,1)
            plot(output.trialX(ii,:)'-output.trialX(ii,1),'Color',cm(mTemp{count,2},:)); hold on; count = count + 1;
        end
        title('Kp Change')
    subplot(6,1,4)
        count = 1;
        for ii = 10:3:size(output.trialX,1)
            plot(output.trialX(ii,:)'-output.trialX(ii,1),'Color',cm(mTemp{count,2},:)); hold on; count = count + 1;
        end
        title('Ks Change')
    subplot(6,1,5)
        plot(output.trialF)
        title('All Function Fval')
    subplot(6,1,6)
        plot(history.fval,'LineWidth',3)
        title('Iteration Fval')
%% Time Predictor Sub Function
function time_predictor(maxTime)
    [h,m] = hms(datetime('now')+minutes(maxTime)+minutes(.1*maxTime));
    if h > 12
        h = mod(h,12);
    elseif h == 0
        h = 12;
    end
    if m < 10
        mprint = ['0',num2str(m)];
    else
        mprint = num2str(m);
    end
    disp(['Optimization should finish around ',num2str(h),':',mprint])
end