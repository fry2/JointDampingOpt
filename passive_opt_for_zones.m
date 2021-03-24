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
        IPtemp = initialPoint(9:end); stimIn = initialPoint(1:7); initialPoint = [];
        if size(IPtemp,1) == 1
            IPtemp = reshape(IPtemp,2,length(IPtemp)/2)';
        end
        counter = 9;
        for mLine = 1:size(mInfo,1)
            initialPoint(counter:counter+1) = IPtemp(mInfo{mLine,2},:);
            counter = counter + 2;
        end
        initialPoint(1:7) = stimIn;
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
    
    %% Pick inequality matrices
        ksRatio = initialPoint(8);
        aplacer = 8+(1:2:numZones*2);
        counter = 1;
        n = .5;
        ALowBnd = zeros(8+numZones,8+2*numZones);
        % Linear ineq maker (for defining VE props to be bigger than dt/2)
        for ii = 8+(1:numZones)
            ALowBnd(ii,aplacer(counter):aplacer(counter)+1) = [-2, physTS*(1+ksRatio)];
            counter = counter + 1;
        end
        bLowBnd = zeros(8+numZones,1);

        % Use this is you want to define an upper and lower bound to the time constants for muscles. The lower bound is n*physTS, upper is tauU. Units in (s).
    %     n = 2; tauU = 1;
    %     colplacer = 7+(1:3:3*numZones);
    %     rowplacer = 7+(1:2:2*numZones);
    %     counter = 1;
    %     % Linear ineq maker (for defining VE props to be bigger than dt/2)
    %     for ii = 7+(1:numZones)
    %         ATweenBnds(rowplacer(counter):rowplacer(counter)+1,colplacer(counter):colplacer(counter)+2) = [-1, n*physTS, n*physTS; 1, -tauU, -tauU];
    %         counter = counter + 1;
    %     end
    %     bTweenBnds = zeros(7+2*numZones,1);

        % Linear eq maker (for defining VE props to be equal to a set tau)
    %     tau = .08;
    %     counter = 1;
    %     for ii = 7+(1:numZones)
    %         Aeq(ii,aplacer(counter):aplacer(counter)+2) = [-1, tau, tau];
    %         counter = counter + 1;
    %     end
    %     beq = zeros(7+numZones,1);
    %%
    ub = [repmat(20,1,7),1e3,repmat([50 1e3],1,numZones)];% b, ks, kp
    lb = [zeros(1,7),1,repmat([1 1],1,numZones)];

    fun_pass = @(inVec) objFun_whole_leg_passive(inVec,NWmotion,mInfo,stimLevel,ts);
    pattOpts = optimoptions('patternsearch','UseParallel',true,'MaxTime',maxTime*60,...  
        'Display','iter','SearchFcn','MADSPositiveBasis2N','InitialMeshSize',50,'UseCompleteSearch',true,'MeshExpansionFactor',2,'OutputFcn',@outfun);%'MaxTime',maxTime*60;,'MaxFunctionEvaluations',100;
   % pattOpts = optimoptions('patternsearch','UseParallel',true,'InitialMeshSize',5000,'MaxTime',maxTime*60,...  
    %    'Display','iter','OutputFcn',@outfun,'PlotFcn',@psplotbestf);
    
    [passVals,fVal,~,output] = patternsearch(fun_pass,initialPoint,ALowBnd,bLowBnd,[],[],lb,ub,[],pattOpts);

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

    function [c,ceq] = ksRatio_nonlcon(x)
        ksRatio = x(8);
        physTS = .54e-3;
        bs = x(9:2:end); kps = x(10:2:end);
        c = ksRatio - 2.*(bs)./(physTS.*kps) + 1;
        ceq = [];
    end
end