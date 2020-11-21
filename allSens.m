parStrings = {'B','Ks','Kp'};
outMat = zeros(38,4,3);
omRel = outMat;

parfor ii = 1:7
    NWmotion_temp = reshapedJM{ii,maxtrial(ii)};
    stimLevel = 20;
    [simText,stimID] = simText_editor(kinematic_muscle_name{2,ii},NWmotion_temp,'on',ts{ii});
    numZones = length(unique(cell2mat(mInfo(:,2))));
    grade(ii) = objFun_passive(simText,NWmotion_temp,pvStruct.pvGlobal38,'all',stimID,stimLevel,numZones,mInfo);
end
initGrade = trapz(grade);

for ii = 1:3
    outMat(:,:,ii) = sensitivity_analysis(pvStruct.pvGlobal38,parStrings{ii},reshapedJM,ts,maxtrial,kinematic_muscle_name,mInfo,initGrade);
    temp = outMat(:,:,ii);
    temp(abs(temp)<1) = 0;
    omRel(:,:,ii) = temp;
end

    delete([pwd,'\tp*'],...
           [pwd,'\JointMotion_*'],...
           [pwd,'\Trace_*'])

%%
% write to spreadsheet
mInfo6 = zoning_sorter(simText,6);
mat2save = sortrows([mInfo6,num2cell(omRel(:,:,1)),num2cell(omRel(:,:,2)),num2cell(omRel(:,:,3))],2);
filename = 'sensData.xlsx';
writecell(mat2save,filename,'Sheet',1,'Range','A2')