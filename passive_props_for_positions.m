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
    input6zones = 1; out6zones = 1;

    try 
        if input6zones
            pvGlobal_old = pvStruct.pvGlobal6;
            pvG_grades_old = pvStruct.pvGlobal6_grades;
        else
            pvGlobal_old = pvStruct.pvGlobal38;
            pvG_grades_old = pvStruct.pvGlobal38_grades;
        end
         
    catch
        if input6zones
            pvGlobal_old = repmat([5 500 100],1,6);
        else
            pvGlobal_old = repmat([5 500 100],1,38);
        end
        pvG_grades_old = 1e8*ones(1,length(kinematic_currents));
    end

    passVals = pvGlobal_old;

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
    %stimLevel = [15,20,10,20,15,15,15];
    maxTimeTrial = 60; %in min
    [simText,stimID] = simText_editor(kinematic_muscle_name{2,1},reshapedJM{1},'on',ts{1});
    %%%%%% JUST TO RESET THINGS
    %passVals = repmat([1e-3 1 1],1,numZones);
    %passVals = passValsOld;
    %%%%%%
    [passVals,mInfo,fVal,history,output] = passive_opt_for_zones(simText,reshapedJM,passVals,stimLevel,maxTimeTrial,input6zones,out6zones,ts);
%% Now that we have passive values, we need to analyze their effectiveness at recreating NW waveforms
    outJM = cell(1,7); pvG_grades_new = zeros(1,7);
    if 0
        passVals = pvStruct.pvGlobal38;
        mInfo = zoning_sorter(simText,38);
    end
    for ii = 1:7
        NWmotion_temp = reshapedJM{ii,maxtrial(ii)};
        if length(stimLevel) > 1
            stimIn = stimLevel(ii);
        else
            stimIn = 20;
        end
        if ~any(isnan(NWmotion_temp),'all')
            [simText,stimID] = simText_editor(kinematic_muscle_name{2,ii},NWmotion_temp,'on',ts{ii});
            numZones = length(unique(cell2mat(mInfo(:,2))));
            [pvG_grades_new(ii),jm] = objFun_passive(simText,NWmotion_temp,passVals,'all',stimID,stimIn,numZones,mInfo);
            outJM{ii} = jm;
        else
            outJM{ii} = NaN(size(NWmotion_temp));
        end
    end
%% Determine whether or not to save the new values by comparing new scores to old scores
    newScore = trapz(pvG_grades_new);
    oldScore = trapz(pvG_grades_old);
    telapsed = toc(tstart);
    if newScore < oldScore
        disp(['New score (',num2str(newScore),') is better than old score (',num2str(oldScore),'), SAVING new values (',num2str(telapsed/60),' min).'])
        % Generate an APROJ file with the updated values
            NWmotion = reshapedJM{1};
            [projText] = projText_editor(passVals,mInfo,stimID,NWmotion); 
        pvStruct.(['pvGlobal',num2str(numZones)]) = passVals;
        pvStruct.(['pvGlobal',num2str(numZones),'_grades']) = pvG_grades_new;
        save('pvStruct.mat','pvStruct')
    else
        disp(['New score (',num2str(newScore),') is NOT better than old score (',num2str(oldScore),'), NOT saving new values (',num2str(telapsed/60),' min).'])
    end
return
%% Individual trial jointMotion and NWmotion
    trial = 5;
    NWmotion = (reshapedJM{trial}-[98.4373 102.226 116.2473]).*(pi/180);
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
    yLims = [min([reshapedJM{1,maxtrial(ii)};outJM{1}],[],'all') max([reshapedJM{1,maxtrial(ii)};outJM{1}],[],'all')];
    for ii = 2:7
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
    figure
    cm = [0,1,0;...
          1,0,0;...
          0.9216,0.8235,0.2039;...
          0,0,1;...
          1,0,1;...
          0,1,1];
    switch 0
        case 2
            muscVals = reshape(passVals,3,numZones)';
            mTemp = zoning_sorter(simText,6);
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
        scatter3(muscVals(ii,1),muscVals(ii,2),muscVals(ii,3),36,cm(mTemp{ii,2},:),'o','LineWidth',10)
        hold on
    end
    pbaspect([1 1 1])
    view([-43 18])
    title('Viscoelastic Muscle Parameters','FontSize',18)
    xlabel('B (Ns/m)','FontSize',18); ylabel('Ks (N/m)','FontSize',18), zlabel('Kp (N/m)','FontSize',18)
%% Generate waveforms for modified muscle parameter
mNum = 11; par2change = 'Ks'; newVal = 4;
pvMat = reshape(pvStruct.pvGlobal38,3,38)';
switch par2change
    case 'B'
        if floor(newVal)==newVal
            bmin =(.54e-3/2)*(pvMat(mNum,2)+pvMat(mNum,3));
            vals2test = [bmin, (pvMat(mNum,1)+bmin)/2, 1.1*pvMat(mNum,1), 1.5*pvMat(mNum,1)];
            newVal = vals2test(newVal);
        end
        pvMat(mNum,1) = newVal;
    case 'Ks'
        if floor(newVal)==newVal
            kmax = (2/.54e-3)*pvMat(mNum,1)-pvMat(mNum,3);
            vals2test = [.5*pvMat(mNum,2), .8*pvMat(mNum,2) (pvMat(mNum,2)+kmax)/2 kmax];
            newVal = vals2test(newVal);
        end
        pvMat(mNum,2) = newVal;
    case 'Kp'
        if floor(newVal)==newVal
            kmax = (2/.54e-3)*pvMat(mNum,1)-pvMat(mNum,2);
            vals2test = [.5*pvMat(mNum,3), .8*pvMat(mNum,3) (pvMat(mNum,3)+kmax)/2 kmax];
            newVal = vals2test(newVal);
        end
        pvMat(mNum,3) = newVal;
end
passVals = reshape(pvMat',1,3*38);