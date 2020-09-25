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
        pvGlobal_old = pvStruct.pvGlobal6;
    else
        pvGlobal_old = pvStruct.pvGlobal38;
    end
     pvG_grades_old = pvStruct.pvGlobal_grades;
catch
    if input6zones
        pvGlobal_old = repmat([5 500 100],1,6);
    else
        pvGlobal_old = repmat([5 500 100],1,38);
    end
    pvG_grades_old = 1e8*ones(1,length(kinematic_currents));
end

passVals = pvGlobal_old;
maxTimeTrial = 45; %in min
maxJM = NW_jointmotion_maxtrial_all(kinematic_data,0);
reshapedJM = cell(1,7); ts = cell(1,7);
for ii = 1:7
    [reshapedJM{ii},ts{ii}] = NW_reshaper(maxJM{ii});
end
stimLevel = 20;
[simText,stimID] = simText_editor(kinematic_muscle_name{2,1},reshapedJM{1},'on',ts{1});
[passVals,mInfo,fVal,history] = passive_opt_for_zones(simText,reshapedJM,passVals,stimLevel,maxTimeTrial,input6zones,out6zones,ts);
%% Now that we have passive values, we need to analyze their effectiveness at recreating NW waveforms
    outJM = cell(1,7); pvG_grades_new = zeros(1,7);
    for ii = 1:7
        NWmotion_temp = reshapedJM{ii};
        stimLevel = 20;
        if ~any(isnan(NWmotion_temp),'all')
            [simText,stimID] = simText_editor(kinematic_muscle_name{2,ii},NWmotion_temp,'on',ts{ii});
            numZones = length(unique(cell2mat(mInfo(:,2))));
            [pvG_grades_new(ii),jm] = objFun_passive(simText,NWmotion_temp,passVals,'all',stimID,stimLevel,numZones,mInfo);
            outJM{ii} = jm;
        else
            outJM{ii} = NaN(size(NWmotion_temp));
        end
    end
%% Determine whether or not to save the new values by comparing new scores to old scores
    newScore = trapz(pvG_grades_new);
    oldScore = trapz(pvG_grades_old);
    if newScore < oldScore
        disp(['New score (',num2str(newScore),') is better than old score (',num2str(oldScore),'), SAVING new values.'])
        % Generate an APROJ file with the updated values
            NWmotion = reshapedJM{1};
            [projText] = projText_editor(passVals,mInfo,stimID,NWmotion); 
        pvStruct.(['pvGlobal',num2str(numZones)]) = passVals;
        pvStruct.pvGlobal_grades = pvG_grades_new;
        save('pvStruct.mat','pvStruct')
    else
        disp(['New score (',num2str(newScore),') is NOT better than old score (',num2str(oldScore),'), NOT saving new values.'])
    end
return
%% Individual trial jointMotion and NWmotion
    trial = 3;
    NWmotion = (reshapedJM{trial}-[98.4373 102.226 116.2473]).*(pi/180);
    jointMotion = outJM{trial};
    dt = .54e-3;
    timeVec = 0:dt:((length(NWmotion)-1)*dt);

    figure('Position',[962,2,958,994]); subp(1) = subplot(2,1,1); joints = 1:3; startInd = 1; endInd = min([length(NWmotion) length(jointMotion)]);
    plot(timeVec(startInd:endInd),NWmotion(startInd:endInd,joints),'LineWidth',2);legend({'Hip';'Knee';'Ankle'});%ylim([60 200]);
    title([kinematic_muscle_name{1,trial},' Desired Joint Motion']); ylabel('Joint Angle (deg)');xlabel('Time (s)');
    subp(2) = subplot(2,1,2);
    plot(timeVec(startInd:endInd),jointMotion(startInd:endInd,joints),'LineWidth',2);
    ylim([60 200]);title('Simulation Results');ylabel('Joint Angle (deg)');xlabel('Time (s)');%xlim([0 max(timeVec)])
%% All trials in green black subplot
    figure('Position',[962,2,958,994])
    startInd = 273; endInd = 358;%endInd = min([length(NWmotion) length(jointMotion)]);
    selInds = [48:196,startInd:endInd];
    yLims = [min([reshapedJM{1};outJM{1}],[],'all') max([reshapedJM{1};outJM{1}],[],'all')];
    for ii = 2:7
        if min([reshapedJM{ii};outJM{ii}],[],'all') < yLims(1)
            yLims(1) = min([reshapedJM{ii};outJM{ii}],[],'all');
        end
        if max([reshapedJM{ii};outJM{ii}],[],'all') > yLims(2)
            yLims(2) = max([reshapedJM{ii};outJM{ii}],[],'all');
        end
    end   
    for ii = 1:7
        subplot(7,1,ii)
        plot(reshapedJM{ii},'g','LineWidth',2)
        hold on
        plot(outJM{ii},'k','LineWidth',2)
        ylim(yLims)
        title([kinematic_muscle_name{1,ii},' ',num2str(pvStruct.pvGlobal_grades(ii))])
    end
%% Scatter plot of muscle values
    figure
    cm = [0,1,0;...
          1,0,0;...
          0.9216,0.8235,0.2039;...
          0,0,1;...
          1,0,1;...
          0,1,1];
    switch 0
        case 1
            muscVals = reshape(pvStruct.pvGlobal38,3,38)';
            mTemp = zoning_sorter(simText,6);
        case 0
            muscVals = reshape(pvStruct.pvGlobal6,3,6)';
            mTemp = cell(6,2);mTemp(:,2) = num2cell(1:6);
        otherwise
            error('error')
    end
    for ii = 1:size(muscVals,1)
        scatter3(muscVals(ii,1),muscVals(ii,2),muscVals(ii,3),36,cm(mTemp{ii,2},:),'o','LineWidth',5)
        hold on
    end
    pbaspect([1 1 1])
    view([-56 16])
    xlabel('B'); ylabel('Ks'), zlabel('Kp')