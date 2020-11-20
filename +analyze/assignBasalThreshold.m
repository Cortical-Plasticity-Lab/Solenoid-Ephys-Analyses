function C = assignBasalThreshold(T,B,nSD)
%ASSIGNBASALTHRESHOLD Return table where rows are average spikes/channel
%
%  C = analyze.assignBasalThreshold(T,B)
%  C = analyze.assignBasalThreshold(T,B,nSD)
%
% Inputs
%  T       - Main data table
%  B       - Thresholds table
%  nSD     - Table with number of standard deviations (default: 3)
%
% Output
%  C       - Table for mean spikes/channel with detected peak and peak times
%
% See also: Contents, new_analysis.m

ORD = 3;       % polynomial order                       (sgolayfilt)
WLEN = 21;     % window length for polynomial smoothing (sgolayfilt)
KSHAPE = 38;   % kaiwer window shape coefficient        (sgolayfilt)

if nargin < 3
   nSD = 3;
end

disp("Creating table `C` with smoothed spike rates...");
C = utils.computeSmoothMeanSpikeRate(T,ORD,WLEN,KSHAPE);
B.Threshold = B.Mean_Baseline + B.STD_Baseline.*nSD;
C.Threshold = zeros(size(C,1),1);
for i = 1:size(B.Threshold,1)
    idx = (C.BlockID == B.BlockID(i) & C.ChannelID == B.ChannelID(i));
    C.Threshold(idx) = B.Threshold(i);
end


end