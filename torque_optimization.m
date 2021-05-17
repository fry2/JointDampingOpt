% Define the experimental data
%     obj = design_synergy("G:\My Drive\Rat\SynergyControl\Animatlab\SynergyWalking\SynergyControl_Standalone_Walking.asim");
%     [passive_joint_torque,passive_joint_motion,passive_muscle_torque] = compute_passive_joint_torque(obj);
%     tE = [];
%     pE = [];

     load([pwd,'/Data/torque_sample_data.mat'],'tE','pE','muscleinfo')
     inSimPath = "G:\My Drive\Rat\SynergyControl\Animatlab\SynergyWalking\SynergyControl_Standalone.asim";
     simText = importdata(inSimPath);
     obj = design_synergy(inSimPath);

    curvars = who;
    if ~any(contains(curvars,'torqueVals'))
        load([pwd,'/Data/torqueVals.mat'],'torqueVals')
    end
 
    muscCount = 1;
    for ii = 1:2:2*38
        musc = obj.musc_obj{muscCount}; kp = musc.Kpe; lr = musc.RestingLength;
        initialPoint(ii:ii+1) = [kp lr];
        muscCount = muscCount + 1;
    end
    initialPoint(2:2:end) = initialPoint(2:2:end).*1e4;
 
    %% Define the linear constraints for Kp
        physTS = .54e-3;
        A = diag(ones(1,length(initialPoint)));
        b = zeros(38,1); muscCount = 1;
        for ii = 1:length(initialPoint)
            if mod(ii,2)
                musc = obj.musc_obj{muscCount}; ks = musc.Kse; kp = musc.Kpe; damp = musc.damping;
                b(ii,1) = (2/physTS)*damp-ks;
                muscCount = muscCount + 1;
            else
                b(ii,1) = 1e9;
            end
        end
    %%
    ub = repmat([1e4 Inf],1,38);
    lb = repmat([1 1e-6],1,38);
    history.x = [];
    history.fval = [];
    
    maxTime = 15;
    
    rng(10)
    r = .8 + (.8/2).*rand(1,3);
    tEin = tE(5000,:).*r;
    pEin = pE(5000,:);
    
    fun_pass = @(inVec) torque_optimization_objective_function(tEin,pEin,simText,inVec);
    pattOpts = optimoptions('patternsearch','UseParallel',true,'MaxTime',maxTime*60,'InitialMeshSize',10,'Display','iter','SearchFcn','MADSPositiveBasis2N','UseCompleteSearch',true);
    
    [tvals,fVal,~,output] = patternsearch(fun_pass,initialPoint,A,b,[],[],lb,ub,[],pattOpts);
    
    if fVal < torqueVals.fVal
        disp(['SAVING: New value ',num2str(fVal),' is lower than old value ',num2str(torqueVals.fVal)])
        torqueVals.tvals = tvals; torqueVals.fVal = fVal;
        save([pwd,'/Data/torqueVals.mat'],'torqueVals')
    else
        disp(['NOT SAVING: New value ',num2str(fVal),' is higher than old value ',num2str(torqueVals.fVal)])
    end
    
    delete([pwd,'\tp*'],...
       [pwd,'\*.txt'],...
       [pwd,'\Trace_*'])
   %% Plot value changes over time
    figure('Position',[962,2,958,994])
    mTemp = zoning_sorter(simText,6);
    cm = [0,1,0;1,0,0;0.9216,0.8235,0.2039;0,0,1;1,0,1;0,1,1];
    subplot(3,1,1)
        count = 1;
        for ii = 1:2:size(output.trialX,1)
            plot(output.trialX(ii,:)','Color',cm(mTemp{count,2},:)); hold on; count = count + 1;
        end
        title('Kp Change')
    subplot(3,1,2)
        count = 1;
        for ii = 2:2:size(output.trialX,1)
            plot(output.trialX(ii,:)','Color',cm(mTemp{count,2},:)); hold on; count = count + 1;
        end
        title('Lr Change')
    subplot(3,1,3)
        plot(output.trialF)
        title('All Function Fval')