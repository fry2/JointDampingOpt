function [reshapedJM,ts] = generate_NW_waveforms(kinematic_data)
    [maxJM,maxtrial] = NW_jointmotion_maxtrial_all(kinematic_data,0);
    for ii = 1:7
        [reshapedJM{ii,1},ts{ii,1}] = NW_reshaper(maxJM{ii},ii);
        for jj = 2:4
            NWtemp = NWangs_from_markers(ii,maxtrial-jj+1,kinematic_data);
            [reshapetemp,ts{ii,jj}] = NW_reshaper(NWtemp,ii);
            cutoff = ts{ii,jj}.tcstart;
            reshapedJM{ii,jj} = [reshapetemp(1:cutoff,:);reshapedJM{ii,1}(cutoff+1:end,:)];
        end
    end
end