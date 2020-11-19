function C = meanSpikesPerChannel(T,B,nSD,pk)
%MEANSPIKESPERCHANNEL Return table where rows are average spikes/channel
%
%  C = analyze.meanSpikesPerChannel(T,B)
%  C = analyze.meanSpikesPerChannel(T,B,nSD,pk)
%
% Inputs
%  T       - Main data table
%  B       - Thresholds table
%  nSD     - Table with number of standard deviations (default: 3)
%  pk      - Max. # of peaks to detect (default: 5)
%
% Output
%  C       - Table for mean spikes/channel with detected peak and peak times
%
% See also: Contents, new_analysis.m

DEBOUNCE = 0.005; % Don't get peaks any closer to zero than this (seconds)

if nargin < 3
   nSD = 3;
end

if nargin < 4
   pk = 5; 
end

disp("Creating table `C`...");
fn = @(X){nanmean(X,1)};
outputVars = 'Spike_Mean';
C = tbl.stats.estimateChannelResponse(T,fn,'Spikes',outputVars);
B.Threshold = B.Mean_Baseline + B.STD_Baseline.*nSD; % Threshold is 3SD over baseline and should be in spikes/5ms or spikes per bin
C.Threshold = zeros(size(C,1),1);
for i = 1:size(B.Threshold,1)
    idx = (C.BlockID == B.BlockID(i) & C.ChannelID == B.ChannelID(i));
    C.Threshold(idx) = B.Threshold(i);
end

% Find latencies of peaks
disp("Finding peak latencies...")
ts = C.Properties.UserData.t.Spikes;
C = utils.roundEventTimesToNearestMillisecond(C);

% Use Matlab builtin `findpeaks`
C.peakVal  = nan(size(C,1),pk);
C.peakTime = nan(size(C,1),pk);
warning('off','signal:findpeaks:largeMinPeakHeight');
for iC = 1:size(C,1)
   [peaks,locs] = findpeaks(...
      C.Spike_Mean(iC,ts > DEBOUNCE),ts(ts > DEBOUNCE),...
      'NPeaks',pk,...
      'MinPeakHeight',C.Threshold(iC));
   nCur = numel(peaks);
   C.peakVal(iC,1:nCur) = peaks;
   C.peakTime(iC,1:nCur) = locs;
end
warning('on','signal:findpeaks:largeMinPeakHeight');

% Add "unified" stimulus times for ease-of-use
C = tbl.addExperimentOnsetOffsetTimes(C);
C.Response_Offset__Exp = C.Solenoid_Onset__Exp*1e3;

end