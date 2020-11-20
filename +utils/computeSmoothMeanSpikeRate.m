function C = computeSmoothMeanSpikeRate(T,ord,wlen,kshape)
%COMPUTESMOOTHMEANSPIKERATE Compute smoothed average spike rate from individual trial observations
%
%  C = utils.computeSmoothMeanSpikeRate(T);
%  C = utils.computeSmoothMeanSpikeRate(T,ord,wlen,kshape);
%
% Inputs
%  T - Main data table with `Spikes` observations for each trial/electrode
%  
%  OPTIONAL
%
%  ord    - Order of sgolayfilt for polynomial smoothing (see: sgolayfilt;
%              default: 3)
%  wlen   - Window length for smoothing window (see: sgolayfilt; 
%              default: 21)
%  kshape - Shape value for kaiser window in polynomial smoothing
%              (see: sgolayfilt; default: 38)
%
% Output
%  C - "Channel Response" data table with smoothed mean spike rate
%      estimates as variable 'Smoothed_Mean_Spike_Rate'. 
%
% See also: Contents, tbl, tbl.stats, tbl.stats.estimateChannelResponse, 
%                     analyze, analyze.meanSpikesPerChannel, sgolayfilt

if nargin < 2
   ord = 3;
end

if nargin < 3
   wlen = 21;
end

if nargin < 4
   kshape = 38;
end

dt = min(diff(T.Properties.UserData.t.Spikes)); % compute bin size (sec)
fn = @(X){nanmean(X,1)}; % Have to do smoothing and rate estimation at this step
outputVars = 'Spike_Mean';
C = tbl.stats.estimateChannelResponse(T,fn,'Spikes',outputVars);
C.Spike_Mean = sgolayfilt(C.Spike_Mean./dt,... % spikes/second
   ord,wlen,kaiser(wlen,kshape),2);
C.Properties.VariableNames{'Spike_Mean'} = 'Smoothed_Mean_Spike_Rate';
C.Properties.VariableUnits{'Smoothed_Mean_Spike_Rate'} = 'E[spikes/s]';
C = movevars(C,'Smoothed_Mean_Spike_Rate','after',size(C,2));

end