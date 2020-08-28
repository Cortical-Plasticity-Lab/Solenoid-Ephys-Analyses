% FINDEVOKEDPEAKS Script to test functions for finding evoked spike response
%
% General strategy is as follows:
%  Input: rat, channel, trialType, varargin(for standard dev)
%  Return: array of peak time, width, num spikes, and rank for each peak
%
%  Generic schema for output:
%  [[tPeak1, binWidth1, numSpikes1, rank1] , [tPeak2, binWidth2, numSpikes2, rank2] ]

% Load in the table, it will take a minute or so
clearvars -except T
close all force;
clc;
if exist('T','var')==0
%    T = getfield(load(fullfile('P:\Rat\BilateralReach\Solenoid Experiments','Solenoid-Table.mat'), 'T'),'T');
   T = getfield(load('Solenoid-Table.mat', 'T'),'T');
end
%%
% Testing variables (can be changed)

rat = "R19-226";
% channel = 1; % Easier to use ChannelID based on solBlock.probePETH output
channelID = "A-011";
trialType = 'Solenoid';
sDev = [3.5, 4.5];

% Default file variables
pMargin = 0.05; % proportion to ignore at beginning and before trial

% Get time of each spike sample (histogram bin centers)
t = T.Properties.UserData.t.Spikes; % t == 0 : Trial Onset; seconds
totalSamples = numel(t); % Total samples (bins) per trial
totalTime = t(end) - t(1); % Total duration of a "trial" (seconds)
offsetSamples = ceil(totalSamples * pMargin); % # samples to offset
[~,iStart] = min(abs(t)); % Time closest to zero is "start" sample for trial
binWidth = mode(diff(t)); % To reduce it to one value, just use mode

% Note: tPost and tPre were switched, for stuff like this it's better to 
%       use the data that was previously associated with the sample record;
%       for example, if the table was generated and saved (which takes a
%       while) and then for whatever reason cfg.default times were changed,
%       then the vectors would be mismatched. Also illustrated below, it
%       introduces another possible place for error (here, tPost/tPre get
%       mixed up since I hadn't commented them in the cfg.defaults file)
%
% tPost = cfg.default('tpost'); % time before onset in seconds
% tPre = cfg.default('tpre'); % time after onset in seconds
% totalTime = abs(tPost)+abs(tPre);
% Get the proportion of the time pre and post 
% pPost = tPost/totalTime;
% pPre = abs(tPre/totalTime);
% binWidth = cfg.default('binwidth'); % width of PETH bins in seconds
% totalSamples = (abs(tPre)+abs(tPost))/binWidth;
% midBins =(totalSamples*pMargin:totalSamples*(1-pMargin)); 
% Note: if doing it this way make sure to always wrap sample indices with 
% `round`, `ceil` or `floor` as appropriate, since `pMargin` is a "free" 
% parameter which could cause problems if it's set to a fraction that 
% causes non-integer product with total number of samples.

%% Get relevant groupings
% I would just get the relevant groupings and do the rest as sub-functions
% applied that get applied by grouping
% First get means of the PETH before solenoid

% [G, G_SurgID ,G_Type , G_Channel] = findgroups(T.SurgID, T.Type, T.Channel);
% Note: we also want to split them by "BlockID" since we don't necessarily
%         want to group together Blocks which might have different stimulus
%         locations etc.
% If we have it output a table it makes it easier to adjust and track later

% Reduce the table first
rowSelector = ...
   (T.Type == trialType) & ...
   (T.ChannelID == channelID) & ...
   (string(T.SurgID) == rat);
T_sub = T(rowSelector,:);
[G,TID] = findgroups(T_sub(:,{'SurgID','BlockID','Type','ChannelID'}));


%% This is where I would change the workflow somewhat 
% See: analyze.control.checkSpikes

% Create anonymous function handle to apply using `splitapply`, instead of
% using a for loop. The args in parenthesis after @ are the actual function
% arguments, while the second part is the custom function, which will take
% those arguments in addition to static arguments from this workspace.

% To keep it simpler for now we will just have one standard deviation
% parameter.
tSuppress = [nanmean(T_sub.Solenoid_Offset)-0.004, nanmean(T_sub.Solenoid_Offset)+0.004];
fcn = @(Spikes,tAlign,tag)analyze.control.checkSpikes( ...
   t,Spikes,tAlign,...
   'sDev',sDev(1), ...      % Set # standard deviations for threshold
   'tSuppress',tSuppress,...
   'debug_tag',string(tag(1)));  % Specify epoch to suppress detected peaks
peakData = struct;
peakData.TID = TID; % So we know what each cell corresponds to
tic;
peakData.solenoidOnset = splitapply(fcn,...
   T_sub.Spikes,T_sub.Solenoid_Onset,T_sub.BlockID,G);
toc;
peakData.solenoidOffset = splitapply(fcn,...
   T_sub.Spikes,T_sub.Solenoid_Offset,T_sub.BlockID,G);
toc;

%% Previous code
% sumSpikes = splitapply(@sum, T.Spikes, G);
% meanPreSolTrim = mean(sumSpikes(:,midBins),2);
% 
% 
% %areaOfInterest = (string(G_SurgID) == rat).*(G_Type == trialType).*(G_Channel == channel);
% %% Quick visualization to see an example
%     % --> This is good, I would implement this but use the `pars` from
%           `peakData` instead and do in a function that returns the figure
%           handle.
% i = randsample(length(meanPreSolTrim), 1);
% plot(sumSpikes(i,:))
% yline(meanPreSolTrim(i)) 
% %% Find peaks on the spiking data
% % only look at the data after the event (tPost)
% 
% %set a time delay to ignore solenoid artifact
% delayTime = 0.020; % (seconds)
% delayBin = floor(delayTime/binWidth);
% %set a time to ignore peaks after with respect to event
% maxTime = 0.1; %the difference between maxTime and delayTime is the window size in seconds
% maxBin = floor(maxTime/binWidth);
% 
% % set the window of bins that we want to get the data from
% delays = floor(pPre*totalSamples)+delayBin;
% close = floor(pPre*totalSamples)+maxBin;
% 
% peakCells = cell(length(meanPreSolTrim), length(sDev));
% locCells = cell(length(meanPreSolTrim), length(sDev));
% widthCells = cell(length(meanPreSolTrim), length(sDev));
% promCells = cell(length(meanPreSolTrim), length(sDev));
% 
% %TODO: implement ability to check solenoidOnset and add that accordingly?
% % or does the PETH used to generate spikes take that into account?
% %     --> No; you'd need to use the T.SolenoidOnset parameter--
% %              - It may be necessary to do two separate sets; one,
% %                 using alignment to T.SolenoidOnset, and one using
% %                 alignment to T.SolenoidOffset (when the sensory stimulus
% %                 is "released"). 
% %
% % For record-keeping, there is an empirically-determined approximate 4-ms
% % delay between the logical HIGH value and the solenoid strike, which
% % should be included if tAlign uses T.SolenoidOnset.
% %
% %  -> This value is now saved in cfg.default('sol_onset_phys_delay'); (in
% %     seconds)
% 
% for i = 1:length(sDev)
%     iDev = sDev(i);
%     for j = 1:length(meanPreSolTrim)
%        % Note: we would want to implement this as 
%        %    thresh = mu + k * sigma
%        % Where mu is the mean, sigma is standard deviation, and k is # of
%        %    deviations (`sDev`)
%         thresh = iDev*meanPreSolTrim(j); 
%         
%         % may need to group based on the solenoid onset and offset?
%         %sOnSet = T(T.SurgID == string(G_SurgID(j)) & T.Channel == G_Channel(j) & T.Type == G_Type(j),:);
%         %sOffSet = T(T.SurgID == string(G_SurgID(j)) & T.Channel == G_Channel(j) & T.Type == G_Type(j), T.Solenoid_Offset);
%         
%         
%         d = sumSpikes(j, delays:close);
%         
%         [pks, locs, w, p] = findpeaks(d, 'Threshold',thresh);
%         
%          
%         peakCells{j,i} = pks;
%         locCells{j,i} = locs+delays; %check this for off by one error on the addition
%         widthCells{j,i} = w;
%         promCells{j,i} = p;
%         
%         
%     end
% end

