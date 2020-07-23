function peakData = checkSpikes(t,Spikes,tAlign,varargin)
%CHECKSPIKES Check for evoked spikes in FL-S1 at relevant physiological latencies
%
%  peakData = analyze.control.checkSpikes(t,Spikes,tAlign);
%  peakData = analyze.control.checkSpikes(__,tAlign,'Name',value,...);
%
%  Example usage:
%     ```
%        [G,TID]=findgroups(T(:,["AnimalID","BlockID","Channel","Type"]));
%        t=T.Properties.UserData.t.Spikes;
%        % Create splitapply function handle; it will take Spikes and
%        %  tAlign from the table; the others are associated using the
%        %  current values in the workspace. To update to a new parameter
%        %  value, you would need to redefine `fcn` before using
%        %  `splitapply` again.
%        fcn=
%           @(Spikes,tAlign)analyze.control.checkSpikes(t,Spikes,tAlign,...
%              'par1',par1value,...,'park',parkvalue);
%        peakData=splitapply(fcn,T.Spikes,T.SolenoidOnset,G);
%     ```
%
% Inputs
%  t        - [1 x nSamples] time vector indicating bin centers for each
%              column of `Spikes` (see T.Properties.UserData.t.Spikes, from
%              table exported using `T = makeTables(solRat);`)
%  Spikes   - [nTrial x nSamples] binary vector of zeros
%              (indicating no spike at that relative sample bin) or ones
%              (indicating that a spike was detected at that time). 
%           -> If this is used with `splitapply` workflow, then the Spikes
%              input matrix should correspond to all trials of a given type
%              for a given Surgery/Block
%  tAlign    - [nTrial * 1] vector of alignment times
%  varargin  - (Optional) <'Name',value> argument pairs for modifying
%                 parameters such as the number of threshold standard
%                 deviations to consider a significant peak, etc.
%
% Outputs : All outputs are "wrapped" as cell arrays so that they will work
%           with the `findgroups` -> `splitapply` workflow.
%  peakData  - Struct array with following fields:
%     * tPeak     - Time(s) of peak vectors
%     * binWidth  - Peak width at half-maximum (each element corresponds to
%                       matched element of `tPeak`)
%     * numSpikes - "Height" (count) at peaks (each element corresponds to
%                       matched element of `tPeak`)
%     * rank      - Ordering, where 1 indicates the peak with largest
%                       `numSpikes` associated with it (each element 
%                       corresponds to matched element of `tPeak`)
%     * pars      - Always associate parameters like thresholds, means,
%                    etc. at each stage; that way later, when somebody says
%                    "what thresholds did you use on average to define
%                    significant peaks?" You can answer it without
%                    re-running the entire analysis.
%
% See also: analyze, analyze.control, findEvokedPeaks

% Default parameters
pars = struct;
pars.debug_tag = "";  % Assign as non-empty string
pars.meanCount_data = 0;  % Report mean data-epoch spike count
pars.meanCount_pre = 0;   % Report the pre-epoch mean spike count
pars.min_peak_distance = 0.005; % Peaks must be separated by at least 5-ms
pars.min_peak_prom_sd  = 1;     % Peaks must have prominence at least 1-SD
pars.pMargin = 0.05;  % Proportion to ignore at beginning & before trial
pars.sdCount_data = nan; % Report the data-epoch spike count standard dev.
pars.sdCount_pre = nan;  % Reports the pre-epoch spike count standard dev.
pars.sDev = 3.5;      % # Standard deviations to set threshold above mean
pars.smooth_ord = 3;   % order of polynomial for smoothing filter
pars.smooth_wlen = 11; % # of samples fit by polynomial smoothing filter
pars.tSuppress = [inf,-inf]; % Suppress peaks falling within this range
                             % -> Default setting does not suppress peaks
pars.threshold = nan; % This gives option for fixed threshold
pars.tDuration = 0.400; % Restrict duration to look; 
                        % Based on IPSP durations & expected propagation
                        % of the nervous impulses from solenoid, we 
                        % only care about approximately the first 400-ms
pars.tAlign = 0;        % This is updated with actual mean alignment time
                           % For a given TrialType, it should always be the
                           % same, but just in case we can parse it from
                           % the data here to include with our result
fn = fieldnames(pars);

% Give the option to pass `pars` struct directly
if numel(varargin) > 0
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin(1) = [];
   end
end

% Update parameters struct based on 'Name',value pairs
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

% If `tAlign` is inf, use value of zero
tAlign(isinf(tAlign)) = 0;
pars.tAlign = nanmedian(tAlign); % Get the median alignment time

% Get the total number of samples
totalSamples = numel(t); % Total samples (bins) per trial
% totalTime = t(end) - t(1); % Total duration of a "trial" (seconds)
offsetSamples = ceil(totalSamples * pars.pMargin); % # samples to offset
[~,iStart] = min(abs(t)); % Time closest to zero is "start" sample for trial
binWidth = mode(diff(t)); % To reduce it to one value, just use mode
trialSamples = round(pars.tDuration / binWidth); % # of bins in trial
nTrials = size(Spikes,1);

% % Recover individual trial alignments vector (samples) % %
[uAlign,~,iC] = unique(tAlign);
iUAlign = nan(size(uAlign));
for iU = 1:numel(uAlign)
   [~,iUAlign(iU)] = min(abs(t - uAlign(iU)));
end
iAlign = iUAlign(iC);

% Still use `iStart` at t == 0 since t < 0 should have no stimulus
% interference; but, depending on tAlign, for example in Sol+ICMS trials
% if tAlign is used in "pre" epoch then you could get interference of the
% solenoid or ICMS depending on which is first and what tAlign uses.
preVec = offsetSamples:(iStart-offsetSamples);
dataSubCols = (iAlign + (0:(trialSamples-1)))';
dataSubRows = repelem((1:nTrials)',trialSamples);
dataSubs = sub2ind(size(Spikes),dataSubRows,dataSubCols(:));
% Note that this causes errors if pars.tDuration is too long, relative to
% cfg.defaults('tpost') (due to out-of-bounds for columns); 
% however, current settings (pars.tDuration = 0.4, and 
% cfg.dfeaults('tpost') = 0.75) means that a buffer of 0.35 seconds is
% present, and no trials ever used an offset latency of more than 150-ms if
% I recall correctly (probably most are on the order of 0 - 50-ms).

pre_data = sum(Spikes(:,preVec),1);
pars.meanCount_pre = mean(pre_data);
pars.sdCount_pre = std(pre_data);

% Restored matrix, but now columns are trials and rows are time samples
% (due to indexing procedure)
dataCounts = reshape(Spikes(dataSubs),trialSamples,nTrials);
[~,idx] = min(abs(t - pars.tAlign));
x = t(idx:(idx+trialSamples-1))'; % Associated bin centers
data = sum(dataCounts,2); % Use cross-trial bin averages
s = sgolayfilt(data,pars.smooth_ord,pars.smooth_wlen);
pars.meanCount_data = mean(s);
pars.sdCount_data = std(s);

if isnan(pars.threshold) % Otherwise, we can use fixed value
   pars.threshold = pars.meanCount_pre + pars.sDev * pars.sdCount_pre;
end

if ~isempty(pars.debug_tag)
   figure('Name','Debug Spike Peak Thresholding',...
      'Color','w','Units','Normalized','Position',[0.2 0.2 0.4 0.4]);
   bar(x*1e3,data,1,'FaceColor','k','EdgeColor','none');
   line([x(1),x(end)]*1e3,[pars.threshold,pars.threshold],...
      'Color','r','LineStyle',':','LineWidth',2,'DisplayName','Threshold');
   line(x*1e3,s,...
      'Color','b','LineStyle','-','LineWidth',2,'DisplayName','Smoothed');
   xlabel('Time (ms)','FontName','Arial','Color','k');
   ylabel('Count_{mean}','FontName','Arial','Color','k');
   legend({'Spike Counts','Threshold','Smoothed Counts'},...
      'TextColor','black','FontName','Arial','Color','none');
   tStr = strrep(pars.debug_tag,'_','\_');
   title(tStr,'Color','k','FontName','Arial','FontWeight','bold');
end

% % Finally, do the peak detection % %
iSuppress = (x >= pars.tSuppress(1)) & (x <= pars.tSuppress(2));
data(iSuppress) = nan;
warning('off','signal:findpeaks:largeMinPeakHeight');
[numSpikes,tPeak,binWidth] = findpeaks(s,x,...
   'MinPeakHeight',pars.threshold,... % average # of spikes
   'MinPeakDistance',pars.min_peak_distance,... % Seconds
   'MinPeakProminence',pars.min_peak_prom_sd * pars.sdCount_data);
warning('on','signal:findpeaks:largeMinPeakHeight');
[~,rank] = sort(numSpikes,'descend');

% % Assign outputs to data struct % %
peakData = {assignPeakData(tPeak,binWidth,numSpikes,rank,pars)}; % "Wrap" with cell
% Putting it in a cell allows it to work with `splitapply`
   
   % Helper output function to assign recovered data to struct fields
   function peakData = assignPeakData(tPeak,binWidth,numSpikes,rank,pars)
      %ASSIGNPEAKDATA  Assign output data struct for `n` peaks
      %
      %  peakData = assignPeakData(tPeak,binWidth,numSpikes,rank,pars);
      %
      % Inputs
      %  tPeak        - Times (seconds) @ each peak
      %  binWidth     - Half-max peak width (seconds) for each peak
      %  numSpikes    - # Spikes @ each peak
      %  rank         - Rank (1 -> greatest numSpikes) of each peak
      %  pars         - Parameters used for peak detection
      %
      % Output
      %  peakData - Main function output struct array
      %     * Fields are all the inputs
      
      n = numel(tPeak);
      % This makes sure all oriented correctly and also that all have
      % correct number of entries
      if n > 0
         tPeak = reshape(tPeak,n,1);
         binWidth = reshape(binWidth,n,1);
         numSpikes = reshape(numSpikes,n,1);
         rank = reshape(rank,n,1);
         
         peakData = struct(...
            'tPeak',num2cell(tPeak),...
            'binWidth',num2cell(binWidth),...
            'numSpikes',num2cell(numSpikes),...
            'rank',num2cell(rank), ...
            'pars',pars ...
            );
      else % If no peaks, peakData still size 1 but values are nan
         peakData = struct(...
            'tPeak',nan,...
            'binWidth',nan,...
            'numSpikes',nan,...
            'rank',nan, ...
            'pars',pars ... % This way we can still return threshold
            );
      end
   end
end