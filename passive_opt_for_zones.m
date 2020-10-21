function [passVals,mInfo,fVal,history,output] = passive_opt_for_zones(simText,NWmotion,initialPoint,stimLevel,maxTime,input6zones,out6zones,ts)
    % Set up the passive nonlinear condition, which needs muscle information from the simText
    if ~input6zones
        mInfo = zoning_sorter(simText,38);
    else
        mInfo = zoning_sorter(simText,6);
    end
    history.x = [];
    history.fval = [];

    if input6zones && ~out6zones
        IPtemp = initialPoint; initialPoint = [];
        if size(IPtemp,1) == 1
            IPtemp = reshape(IPtemp,3,length(IPtemp)/3)';
        end
        counter = 1;
        for mLine = 1:size(mInfo,1)
            initialPoint(counter:counter+2) = IPtemp(mInfo{mLine,2},:);
            counter = counter + 3;
        end
        mInfo(:,2) = num2cell(1:38);
    end

    mInds = find(contains(simText,'<Type>LinearHillMuscle</Type>'));
    for muscNum = 1:length(mInds)
        stMax_ind = find(contains(simText(mInds(muscNum):end),'</StimulusTension>'),1,'first')+mInds(muscNum)-4;
        lr_ind = find(contains(simText(mInds(muscNum):end),'<RestingLength>'),1,'first')+mInds(muscNum)-1;
        fMax_ind = find(contains(simText(mInds(muscNum):end),'MaximumTension'),1,'first')+mInds(muscNum)-1;
        mInfo{muscNum,3} = str2double(extractBetween(string(simText{stMax_ind}),'>','</')); 
        mInfo{muscNum,4} = str2double(extractBetween(string(simText{lr_ind}),'>','</'));
        mInfo{muscNum,5} = str2double(extractBetween(string(simText{fMax_ind}),'>','</'));
    end
    numZones = length(unique(cell2mat(mInfo(:,2))));
    
    physTS = double(extractBetween(string(simText{contains(simText,'<PhysicsTimeStep>')}),'>','<'));
    passive_nonlcon_wrap = @(x) passive_nonlcon(x,physTS);
    
    aplacer = 1:3:38*3;
    for ii = 1:38
        A(ii,aplacer(ii):aplacer(ii)+2) = [-2, physTS, physTS];
    end
    b = zeros(38,1);
    
    ub = repmat([1e2 1e4 1e4],1,numZones);
    lb = repmat([1e-3 1 1],1,numZones);

    fun_pass = @(inVec) objFun_whole_leg_passive(inVec,NWmotion,mInfo,stimLevel,ts);
    pattOpts = optimoptions('patternsearch','UseParallel',true,'InitialMeshSize',37.5,'MaxTime',maxTime*60,...  
        'Display','iter','SearchFcn','MADSPositiveBasis2N','UseCompleteSearch',true,'OutputFcn',@outfun);%'MaxTime',maxTime*60;,'MaxFunctionEvaluations',100;
    [passVals,fVal,~,output] = patternsearch(fun_pass,initialPoint,A,b,[],[],lb,ub,[],pattOpts);%passive_nonlcon_wrap

    delete([pwd,'\tp*'],...
           [pwd,'\JointMotion_*'],...
           [pwd,'\Trace_*'])
       
   function [stop,options,optchanged] = outfun(optimValues,options,flag)
        stop = false; % Let algorithm continue to next iteration
        optchanged = false; % We are not making any changes to 'options'
        switch flag % Current state in which the output is called
             case 'iter'
             % Concatenate current point and objective function
             % value with history. x must be a row vector.
               history.fval = [history.fval; optimValues.fval];
               history.x = [history.x; optimValues.x];
             otherwise
        end
    end
end