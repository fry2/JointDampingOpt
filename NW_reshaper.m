function [outMat,ts] = NW_reshaper(inMat)
    meanStart = mean(inMat(1:200,:));
    point_waveStart = 224;
    point_peak = 274;
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
    ts.tcstart = length(outMat)-50;
    ts.tcend = length(outMat);
end