function [NWmotion,numtrials,minLen] = NWangs_from_markers(mnum,trial,kinematic_data)
    %% From the data, find the limb angles
    %load('C:\Users\fry16\OneDrive\Documents\NW_data_local\muscle stim kinematics and forces\17503_datasummary.mat','kinematic_data');
    
    rawDat = kinematic_data{mnum,trial}; % get the marker position data
    if any(isnan(rawDat),'all')
        NWmotion = [];
        return
        %error('This trial isn''t usable because there are NAN entries')
    end
    mkDat = reshape(rawDat(:,3:end),size(rawDat,1),3,12);  % reconfigure the marker data so it's in the format to plot
    mkDat(:,1,:) = mkDat(:,1,:)-mkDat(:,1,1); % make x value relative to first marker

    ind = 1:length(mkDat);
    nn = 1;
    NWmotion = zeros(length(ind),3);
    for ii = ind
        mkSimp = squeeze(mkDat(ii,:,[3,4,7,9,11]))';
        mkSimp(:,1) = mkSimp(:,1)-squeeze(mkDat(ii,1,3));
        for jj = 2:4
            v1 = mkSimp(jj-1,:)-mkSimp(jj,:);
            v2 = mkSimp(jj+1,:)-mkSimp(jj,:);
            NWmotion(nn,jj-1) = real((180/pi)*acos(dot(v1,v2)/(norm(v1(1:2))*norm(v2(1:2)))));
        end
        nn = nn +1;
    end
    
    numtrials = sum(~cellfun(@isempty,kinematic_data(mnum,:)));
    minLen = min(cellfun(@length,kinematic_data(mnum,1:numtrials)));
end