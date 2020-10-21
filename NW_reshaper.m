function [outMat,ts] = NW_reshaper(inMat)
    meanStart = mean(inMat(1:200,:));
    sigMag = sum((inMat-meanStart).^2,2);
    [~,locs] = findpeaks(flip(sigMag),'MinPeakHeight',.2*max(sigMag));
    point_peak = length(sigMag)-locs(1)+1;
    slopeNum = 7;
    for ii = 1:length(sigMag)-slopeNum
        slopes(ii) = (sigMag(ii+slopeNum)-sigMag(ii))/slopeNum;
    end
    [~,point_waveStart] = max(slopes);
    while sigMag(point_waveStart) > sigMag(point_waveStart-1)
        point_waveStart = point_waveStart - 1;
    end
    point_end = length(inMat);
    outMat = [inMat(point_peak:point_end,:);...
               inMat(point_end,:).*ones(50,3);...
               inMat(point_waveStart:point_peak,:)];
    temp = length(inMat)-length(outMat);
    outMat = [meanStart.*ones(floor(.85*temp),3);...
               inMat(point_peak,:).*ones(ceil(.15*temp),3);...
               outMat];
    ts = struct();
    ts.cpstart = floor(.85*temp);
    ts.cpend = temp;
    ts.tcstart = length(outMat)-(point_peak-point_waveStart);
    ts.tcend = length(outMat);
end