function [C,histFig,jointFig] = detectAverageEvokedSpikePeaks(C,nPk,peakWindow,rateArt,rateProm)
%DETECTAVERAGEEVOKEDSPIKEPEAKS Detect peaks in condition-averaged evoked activity on per-channel, per-block basis
%
%  C = analyze.detectAverageEvokedSpikePeaks(C);
%  C = analyze.detectAverageEvokedSpikePeaks(C,nPk,peakWindow,rateArt,rateProm);
%  [C,histFig,jointFig] = analyze.detectAverageEvokedSpikePeaks(C,___);
%
% Inputs
%  C - Data table of per-block/type/channel condition averages (each
%     channel has 3 conditions per block that have ~100 trials averaged
%     together to produce that condition).
%
%     OPTIONAL:
%
%  nPk - Maximum number of peaks to identify per average (optional: default
%           value is 8)
%  peakWindow - Window (seconds; default is in `WINDOW` below) where peaks
%                 can be found following the trial onset.
%  rateArt - Artifact threshold (spikes/sec) for maximum value to consider
%              as a biophysically plausible peak. Default: 500 spikes/sec
%  rateProm - Rate peak prominence threshold (spikes/sec) for findpeaks
%              algorithm. Default: 7.5 spikes/sec seems to separate the
%              peaks pretty clearly.
%
% Output
%  C - Updated table same as input but with additional variables:
%        -> 'peakTime' : Times (sec) of each peak
%        -> 'peakVal'  : Spike rate (log(spikes/sec)) for each peak
%
%        Additionally, "__Exp" versions of Solenoid Onset/Offset and ICMS
%        Onset are added for convenience, and Response_Offset__Exp
%        (probably unused) is also added here.
%  histFig - (Optional) If requested generates histogram of peak values for
%                       double-checking.
%  jointFig - (Optional) If requested generates joint distribution of peaks
%                          and their onset latencies relative to TRIAL
%                          onset (not solenoid or ICMS)
%
% See also: Contents, new_analysis.m, analyze.

PK_DEF = 10;                         % Default number of peaks
WINDOW_DEF = [0.005 0.350];          % ONLY find peaks in this window (seconds)
RATE_ART_DEF = 500;                  % Remove values greater than this
MIN_SPIKE_RATE_PROMINENCE_DEF = 7.5; % Peaks must have prominence of at least 5-Hz
if nargin < 2
   nPk = PK_DEF;
end

if nargin < 3
   peakWindow = WINDOW_DEF;
end

if nargin < 4
   rateArt = RATE_ART_DEF;
end

if nargin < 5
   rateProm = MIN_SPIKE_RATE_PROMINENCE_DEF;
end

nRow = size(C,1);

tic; 
fprintf(1,...
   "Finding average evoked peaks and latencies for %d observations...",...
   nRow);
ts = C.Properties.UserData.t.Spikes;
C = utils.roundEventTimesToNearestMillisecond(C);

% Use Matlab builtin `findpeaks`
C.peakVal  = nan(nRow,nPk);
C.peakTime = nan(nRow,nPk);
warning('off','signal:findpeaks:largeMinPeakHeight');
inWindow = ts >= peakWindow(1) & ts < peakWindow(2);
tSpikeSamples = ts(inWindow);
for iC = 1:nRow
   smoothedSpikeRate = C.Smoothed_Mean_Spike_Rate(iC,inWindow);
   [peaks,locs] = findpeaks(...
      smoothedSpikeRate,tSpikeSamples,...
      'NPeaks',nPk,...
      'MinPeakHeight',C.Threshold(iC),...
      'MinPeakProminence',rateProm);
   nCur = numel(peaks);
   C.peakVal(iC,1:nCur) = peaks;
   C.peakTime(iC,1:nCur) = locs;
end
warning('on','signal:findpeaks:largeMinPeakHeight');
fprintf(1,'complete (%5.2f sec required)\n\n',toc);

iArt = C.peakVal > rateArt;
C.peakVal(iArt) = nan;
C.peakTime(iArt) = nan;

% Add "unified" stimulus times for ease-of-use
C = tbl.addExperimentOnsetOffsetTimes(C);
C.Response_Offset__Exp = C.Solenoid_Onset__Exp*1e3;

C.Properties.VariableUnits{'peakVal'} = 'spikes/sec';
C.Properties.VariableUnits{'peakTime'} = 'seconds';

% Apply sorting to the peaks so that they are ranked with the "largest"
% peak on the left-most column. NaN values are moved to the right.
C = utils.sortMatchedArrayValues(C,'peakVal','peakTime');
C.Properties.RowNames = utils.parseRowNames(C);

% Append additional data to finish up handling of this table
C.ZDepth = utils.getNormDepth(C.Depth,string(C.Area),string(C.Lamina));
C.ZLesion_Volume = zscore(C.Lesion_Volume);

if nargout < 2
   return;
end
histFig = tbl.gfx.makeSpikePeakLatencyHistogram(C);

if nargout < 3
   return;
end
jointFig = tbl.gfx.makeJointInputDistributionScatter(C);

end