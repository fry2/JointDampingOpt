function [c,ceq] = passive_nonlcon(inVec,mi,numZones)
    inMat = reshape(inVec(2:end),3,numZones)';
    c = zeros(38,1);
    for ii = 1:size(mi,1) 
        x = inMat(mi{ii,2},:); m = cell2mat(mi(ii,3:5));
        c(ii) = m(1)*(x(2)/(x(2)+x(3)))*(1+((x(3)*m(2))/(4*m(1)))^2)-m(3);
        %c(ii+38) = physTS-2*x(1)/(x(2)+x(3));
    end
    ceq = [];
end