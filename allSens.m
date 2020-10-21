parStrings = {'B','Ks','Kp'};
outMat = zeros(38,4,3);
omRel = outMat;
for ii = 1:3
    outMat(:,:,ii) = sensitivity_analysis(pvStruct.pvGlobal38,parStrings{ii},reshapedJM,ts,maxtrial,kinematic_muscle_name,mInfo);
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
filename = 'sensData.xlsx';
for ii = 1:3
    writecell([mInfo6,num2cell(omRel(:,:,ii))],filename,'Sheet',ii,'Range','A2')
end
writecell(mInfo6,filename,'Sheet',4,'Range','A2')
writematrix(omRel,filename,'Sheet',4,'Range','C2')