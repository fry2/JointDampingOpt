function output = osc_proc(input)
    % Check whether the end is oscillating at all
    endwave = input(317:end);
    [pks1,locs1] = findpeaks(endwave,1:length(endwave),'MinPeakDistance',3);
    [pks2,locs2] = findpeaks(-endwave,1:length(endwave),'MinPeakDistance',3);
    locs1 = locs1 + 316;
    locs2 = locs2 + 316;
    minLen = min([length(locs1), length(locs2)]);
    locs3 = [];
    if locs1(1) < locs2(1)
       v1 = locs1;
       v2 = locs2;
    else
       v1 = locs2;
       v2 = locs1;
    end
    for ii = 1:minLen
       locs3 = [locs3,v1(ii)];
       locs3 = [locs3,v2(ii)];
    end
    diffs = diff(input(locs3));
    output = abs(diff(sign(diffs)))==2;
end