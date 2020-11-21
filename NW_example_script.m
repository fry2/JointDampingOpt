% An example script to show how to use some of the NW_* helper functions
% The goal here was to go from raw kinematics data to reshaped waveforms
% There's an intermediate step where waveforms are "baselined", or aligned to their mean resting values

[maxJM,maxtrial] = NW_jointmotion_maxtrial_all(kinematic_data,0);
clear reshapedJM
for ii = 1:7
    temp = NW_baseliner(ii,15,kinematic_data,'all','frontalign');
    meanMat(ii,:) = [mean(temp{1}(1:200)),mean(temp{2}(1:200)),mean(temp{3}(1:200))];
    %trials2test = 4:maxtrial(ii);
    trials2test = maxtrial(ii);
    counter = 1;
    for jj = trials2test
        expJM{ii,counter} = [temp{1}(:,jj),temp{2}(:,jj),temp{3}(:,jj)];
        [reshapedJM{ii,counter}, ts{ii,counter}] = NW_reshaper(expJM{ii,counter});
        counter = counter + 1;
    end
end

meanIntro = mean(meanMat);
maxtrial = sum(~cellfun(@isempty,reshapedJM),2);
for ii = 1:7
    maxTail = (reshapedJM{ii,maxtrial(ii)}(ts{ii,maxtrial(ii)}.tcstart:end,:)-meanMat(ii,:))+meanIntro;
    for jj = 1:maxtrial(ii)
        temp = (reshapedJM{ii,jj}-meanMat(ii,:))+meanIntro;
        reshapedJM{ii,jj} = [temp(1:ts{ii,jj}.tcstart,:);maxTail];
    end
end