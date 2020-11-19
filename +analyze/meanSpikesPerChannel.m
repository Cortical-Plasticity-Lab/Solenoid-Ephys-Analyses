function C = meanSpikesPerChannel(T,B,nSD,nPk)
%MEANSPIKESPERCHANNEL Return table where rows are average spikes/channel
%
%  C = analyze.meanSpikesPerChannel(T,B)
%  C = analyze.meanSpikesPerChannel(T,B,nSD,nPk)
%
% Inputs
%  T       - Main data table
%  B       - Thresholds table
%  nSD     - Table with number of standard deviations (default: 3)
%  nPk     - Max. # of peaks to detect (default: 5)
%
% Output
%  C       - Table for mean spikes/channel with detected peak and peak times
%
% See also: Contents, new_analysis.m

WINDOW = [0.005 0.350]; % ONLY find peaks in this window (seconds)
ORD = 3;       % polynomial order                       (sgolayfilt)
WLEN = 21;     % window length for polynomial smoothing (sgolayfilt)
KSHAPE = 38;   % kaiwer window shape coefficient        (sgolayfilt)

if nargin < 3
   nSD = 3;
end

if nargin < 4
   nPk = 5; 
end

disp("Creating table `C` with smoothed spike rates...");
C = utils.computeSmoothMeanSpikeRate(T,ORD,WLEN,KSHAPE);
B.Threshold = B.Mean_Baseline + B.STD_Baseline.*nSD;
C.Threshold = zeros(size(C,1),1);
for i = 1:size(B.Threshold,1)
    idx = (C.BlockID == B.BlockID(i) & C.ChannelID == B.ChannelID(i));
    C.Threshold(idx) = B.Threshold(i);
end

% Find latencies of peaks
tic; fprintf(1,"Finding peak latencies...");
ts = C.Properties.UserData.t.Spikes;
C = utils.roundEventTimesToNearestMillisecond(C);

% Use Matlab builtin `findpeaks`
C.peakVal  = nan(size(C,1),nPk);
C.peakTime = nan(size(C,1),nPk);
warning('off','signal:findpeaks:largeMinPeakHeight');
inWindow = ts >= WINDOW(1) & ts < WINDOW(2);
tSpikeSamples = ts(inWindow);
for iC = 1:size(C,1)
   smoothedSpikeRate = C.Smoothed_Mean_Spike_Rate(iC,inWindow);
   [peaks,locs] = findpeaks(...
      smoothedSpikeRate,tSpikeSamples,...
      'NPeaks',nPk,...
      'MinPeakHeight',C.Threshold(iC));
   nCur = numel(peaks);
   C.peakVal(iC,1:nCur) = peaks;
   C.peakTime(iC,1:nCur) = locs;
end
warning('on','signal:findpeaks:largeMinPeakHeight');
fprintf(1,'complete (%5.2f sec required)\n\n',toc);

% Add "unified" stimulus times for ease-of-use
C = tbl.addExperimentOnsetOffsetTimes(C);
C.Response_Offset__Exp = C.Solenoid_Onset__Exp*1e3;

end