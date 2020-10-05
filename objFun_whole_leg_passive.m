function [outScore,outVal] = objFun_whole_leg_passive(inVec,NWmotion,mInfo,stimLevel,ts)
    kinematic_muscle_name(1,:) = lower({'LH_Illiopsoas','LH_GemellusSuperior','LH_SemitendinosusPrincipal',...
        'LH_SemitendinosusAccessory','LH_VastusLateralis','LH_BicepsFemorisPosterior','LH_BicepsFemorisAnterior'});
    val2test = 1:7; outVal = zeros(1,length(val2test)); 
    for jj = 1:length(val2test)
        ii = val2test(jj);
        %NWmotion_temp = NW_baseliner(ii,[],kinematic_data,'max');
        NWmotion_temp = NWmotion{ii};
        [simText,stimID] = simText_editor(kinematic_muscle_name{1,ii},NWmotion_temp,'on',ts{ii});
        numZones = length(unique(cell2mat(mInfo(:,2))));
        outVal(jj) = objFun_passive(simText,NWmotion_temp,inVec,'all',stimID,stimLevel,numZones,mInfo);
    end
    outScore = trapz(outVal);
end