function [NWbaselined,trial] = NW_baseliner(mnum,trial,kinematic_data,modifier,meanEnd)
    % A function for processing kinematic data from a muscle and trial and outputting a normalized, baseline output
    % Input: mnum: int: number of muscle from the data
    % Input: trial: int: number of trial from the data
    % Input: modifier: char ('all','max'): indicates if all trials should be considered for the muscle
    % Input: meanEnd: char ('frontalign','tailalign'): decides which indices should be used to determine the waveform mean
    [~,numtrials,minLen] = NWangs_from_markers(mnum,1,kinematic_data);
    
    if nargin < 5
        meanEnd = [];
    end
    
    if nargin == 3
        modifier = [];
    else
        if strcmp(char(modifier),'all')
            % Cycle through all trials
            trial = 1:numtrials;
        elseif strcmp(char(modifier),'max')
            % Produce the data information for the last trial without NaN data
            trial = 0;
            for ii = 1:numtrials
                tcontent = kinematic_data{mnum,ii};
                if ~any(isnan(tcontent),'all')
                    trial = trial + 1;
                else
                    break
                end
            end
        else
            error('Input modifier is not recognized.')
        end
    end
    
    if isempty(trial)
        trial = numtrials;
        warning('Trials input was left empty with no modifier, setting to max trial')
    end
    
    if length(trial) > 1
        NWbaselined = cell(3,1);
        motionRaw = [];
        counter = 1;
        for ii = trial
            temp = NWangs_from_markers(mnum,ii,kinematic_data); 
            if ~isempty(temp)
                for jj = 1:3
                    motionRaw(:,counter,jj) = temp(1:minLen,jj);
                end
                counter = counter + 1;
            end
        end
        for jj = 1:3
            if ~isempty(meanEnd)
                if strcmp(meanEnd,'tailalign')
                    meanInds = 321:351;
                elseif strcmp(meanEnd,'frontalign')
                    meanInds = 26:212;
                end
                indivmeans = mean(motionRaw(meanInds,:,jj));
                NWbaselined{jj} = (motionRaw(:,:,jj)-indivmeans)+nanmean(indivmeans);
            else
                NWbaselined{jj} = motionRaw(:,:,jj);
            end
        end
    else
        temp = NWangs_from_markers(mnum,trial,kinematic_data);
        if isempty(temp)
            % there is NAN data in this trial
            NWbaselined = NaN;
        else
            NWbaselined = temp;
        end
    end
end