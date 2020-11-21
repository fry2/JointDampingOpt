function outMat = sensitivity_analysis(inVec,inPar,reshapedJM,ts,maxtrial,kinematic_muscle_name,mInfo,initGrade)
    % intial run for the base value
    if nargin == 7
        parfor ii = 1:7
            NWmotion_temp = reshapedJM{ii,maxtrial(ii)};
            stimLevel = 20;
            [simText,stimID] = simText_editor(kinematic_muscle_name{2,ii},NWmotion_temp,'on',ts{ii});
            numZones = length(unique(cell2mat(mInfo(:,2))));
            grade(ii) = objFun_passive(simText,NWmotion_temp,inVec,'all',stimID,stimLevel,numZones,mInfo);
        end
        initGrade = trapz(grade);
    end
    inMat = reshape(inVec,3,38)';
    numVals = 4;
    outMat = zeros(38,numVals);
    temptester = @(x) .54e-3 - 2*x(1)./(x(2)+x(3));
    tstart = tic;
    for kk = 1:length(inMat)
        switch inPar
            case 'B'
                parInd = 1;
                bmin =(.54e-3/2)*(inMat(kk,2)+inMat(kk,3));
                vals2test = [bmin, (inMat(kk,1)+bmin)/2, 1.1*inMat(kk,1), 1.5*inMat(kk,1)];
            case 'Ks'
                parInd = 2;
                kmax = (2/.54e-3)*inMat(kk,1)-inMat(kk,3);
                vals2test = [.5*inMat(kk,2), .8*inMat(kk,2) (inMat(kk,2)+kmax)/2 kmax];
            case 'Kp'
                parInd = 3;
                kmax = (2/.54e-3)*inMat(kk,1)-inMat(kk,2);
                vals2test = [.5*inMat(kk,3), .8*inMat(kk,3) (inMat(kk,3)+kmax)/2 kmax];
            otherwise
                error('Check inpar')
        end
%         valTemp = inMat(kk,parInd);
%         vals2test = [.8*valTemp .9*valTemp 1.1*valTemp 1.2*valTemp];
        for jj = 1:length(vals2test)
            tempTest = inMat(kk,:);
            tempTest(parInd) = vals2test(jj);
            if temptester(tempTest) > 2e-19
                outMat(kk,jj) = -10000;
            else
                passVals = inMat;
                passVals(kk,parInd) = vals2test(jj);
                passVals = reshape(passVals',1,3*38);
                grade = zeros(1,7);
                parfor ii = 1:7
                    NWmotion_temp = reshapedJM{ii,maxtrial(ii)};
                    stimLevel = 20;
                    [simText,stimID] = simText_editor(kinematic_muscle_name{2,ii},NWmotion_temp,'on',ts{ii});
                    numZones = length(unique(cell2mat(mInfo(:,2))));
                    grade(ii) = objFun_passive(simText,NWmotion_temp,passVals,'all',stimID,stimLevel,numZones,mInfo);
                end
                outMat(kk,jj) = 100*(trapz(grade)-initGrade)./initGrade;
            end
        end
        disp([num2str(kk),' out of 38.'])
    end
    telapsed = toc(tstart);
    disp(['Total time: ',num2str(telapsed/60),' (min).'])
end