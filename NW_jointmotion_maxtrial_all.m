function maxJM = NW_jointmotion_maxtrial_all(kinematic_data,toplot)
    % For input kinematic data, output a cell with the joint motion from its largest trial without NaN values in it
    offsetter = zeros(36,3);
    maxBounds = zeros(1,3);
    minBounds = 1000.*ones(1,3);
    for jj = 1:7
        [~,numtrials] = NWangs_from_markers(jj,1,kinematic_data);
        trial = 0;
        for ii = 1:numtrials
            tcontent = kinematic_data{jj,ii};
            if ~any(isnan(tcontent),'all')
                trial = trial + 1;
            else
                break
            end
        end
        if jj==1
            % The largest trial entry for the IP is incorrect
            trial = 10;
        elseif jj == 6
            trial = 12;
        end
        maxWaves{jj} = NWangs_from_markers(jj,trial,kinematic_data);
            temp = max(maxWaves{jj}(272:330,:))>maxBounds;
            maxBounds(temp) = max(maxWaves{jj}((272:330),temp));
            temp = min(maxWaves{jj}(272:330,:))<minBounds;
            minBounds(temp) = min(maxWaves{jj}((272:330),temp));
        offsetter = offsetter+maxWaves{jj}(321:356,:);
        lenVec(jj) = length(maxWaves{jj});
    end

    offsetter = mean(offsetter./7);
    minLen = min(lenVec);
    yLims = [min(minBounds) max(maxBounds)];

    if toplot == 1 || toplot == 2
        figure;cm = hsv(7);
    end
     for jj = 1:7
%         %toplot = (maxWaves{jj}-offsetter)+offsetter;
         maxJM{jj} = (maxWaves{jj}-mean(maxWaves{jj}(321:351,:)))+offsetter;
         if toplot == 1
             subplot(7,1,jj)
             plot(maxJM{jj}(272:330,:),'LineWidth',2);
             ylim(yLims)
             yline(offsetter(1),'b:');
             yline(offsetter(2),'r:');
             yline(offsetter(3),'k:');
         elseif toplot == 2
             plot(maxJM{jj}(272:330,:),'Color',cm(jj,:),'LineWidth',2);hold on
         end        
     end
end