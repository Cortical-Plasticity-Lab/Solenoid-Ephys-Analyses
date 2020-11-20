function [T,B] = perObservationThreshold(T,baselineWindow)
%PEROBSERVATIONTHRESHOLD Create table of per-observation thresholds
%
%  [T,B] = analyze.perObservationThreshold(T);
%  [T,B] = analyze.perObservationThreshold(T,baselineWindow);
%
% Inputs
%  T - Data table where each row is an observation (trial) for some channel
%        of some unique block and some unique trial type. 
%  baselineWindow - (Optional) specify the pre-stimulus baseline epoch from
%                                which to recover the average spike rate
%                                and then use for the assumption on
%                                stationarity required for estimating the
%                                standard deviation. Should be given in
%                                seconds as a two-element vector. Default
%                                is BASELINE in code below e.g:
%                                   [-0.200 -0.050]
%
% Output
%  T - Same as input, but with new `Baseline` variable which is the average
%        rate on a per-trial basis for each unique observation, during the
%        time relative to trial onset defined by `baselineWindow`. 
%  B - Table with thresholds grouped by Channel and Block. 
%
% See also: Contents, new_analysis.m, tbl, tbl.elimCh

BASELINE = [-0.200 -0.050]; % Window from -200 ms to -50 ms prior to stim
if nargin < 2
   bEpoch = BASELINE;
else
   bEpoch = baselineWindow;
end

if nargin < 3
   ord = 3;
end

if nargin < 4
   wlen = 21;
end

if nargin < 5
   kshape = 38;
end

idx = T.Properties.UserData.t.Spikes >= bEpoch(1) & ...
      T.Properties.UserData.t.Spikes < bEpoch(2);
ts = T.Properties.UserData.t.Spikes(idx);
dur = ts(end) - ts(1); % Total duration of baseline window
dt = nanmean(diff(ts));

T.Baseline = (sum(T.Spikes(:,idx),2))./dur;              % Spike Rate during this time
[G,B] = findgroups(T(:,{'ChannelID','BlockID'}));        % Separate by unique identifier and block
B.Properties.UserData = struct('in_basal_window',idx);   % Store, just in case

B.Mean_Baseline = splitapply(@(X)nanmean(X),T.Baseline,G);

% Return full array of means
mu = cell2mat(splitapply(@(X){nanmean(X,1)./dt},T.Spikes,G));

% Apply smoothing to these means
mu = sgolayfilt(mu,ord,wlen,kaiser(wlen,kshape),2); % Smooth rows

% % % Note about standard deviation and setting the threshold: % % % % % %
%
% Instead of computing standard deviation in a bin from trial-to-trial,
% instead we should compute the time-series standard deviation. Our "null
% hypothesis" here is that the time-series is ergodic in its noise
% distribution; that is, we expect it to maintain the same mean and
% deviation about that mean for the duration of the trial, regardless of a
% stimulus. The threshold-setting method is a way to check if the mean
% deviates from this assumption on ergodicity, because if there are no very
% large peaks prior to stimulus, and there is a very large peak after the
% stimulus, we can safely assume that "something has changed" as a result
% of our experiment. 
%
% Note that the smoothing basically reduces the expected variance. So
% effectively the smoothing makes it so that we are using a "reduced
% threshold" to detect a particular peak. 
%
% % % % So we replace this:
% B.STD_Baseline = cell2mat(splitapply(@(X){nanstd(X,[],1)},T.Baseline,G));
%
% % % % With this:
B.STD_Baseline = nanstd(mu(:,B.Properties.UserData.in_basal_window),[],2);

end