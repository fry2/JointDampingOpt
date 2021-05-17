function [outScore,outVal] = objFun_whole_leg_passive(inVec,NWmotion,mInfo,stimLevel,ts)
    kinematic_muscle_name(1,:) = lower({'LH_Illiopsoas','LH_GemellusSuperior','LH_SemitendinosusPrincipal',...
        'LH_SemitendinosusAccessory','LH_VastusLateralis','LH_BicepsFemorisPosterior','LH_BicepsFemorisAnterior'});
    val2test = 1:7; outVal = zeros(length(val2test),1); 
    %stimLevel = inVec(1:7);inVec = inVec(8:end);]
    stimLevel = [];
    for jj = 1:length(val2test)
        ii = val2test(jj);
        %NWmotion_temp = NW_baseliner(ii,[],kinematic_data,'max');]
        maxtrial = sum(~cellfun(@isempty,NWmotion(ii,:)));
        if maxtrial > 1
            inds = 4:maxtrial;
        else
            inds = 1;
        end
        counter = 1;
        for kk = inds
            NWmotion_temp = NWmotion{ii,kk};
            [simText,stimID] = simText_editor(kinematic_muscle_name{1,ii},NWmotion_temp,'on',ts{ii});
            numZones = length(unique(cell2mat(mInfo(:,2))));
            outVal(jj,counter) = objFun_passive(simText,NWmotion_temp,inVec,'all',stimID,jj,numZones,mInfo);
            counter = counter + 1;
        end
    end
    if length(outVal) == 1
        outScore = outVal;
    else 
        outScore =  sum(outVal);
    end
end