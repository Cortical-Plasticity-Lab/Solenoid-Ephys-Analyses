function C = meanSpikesPerChannel(T,B,nSD,binSt,binSize,pk)
%MEANSPIKESPERCHANNEL Return table where rows are average spikes/channel
%
%  C = analyze.meanSpikesPerChannel(T,B)
%  C = analyze.meanSpikesPerChannel(T,B,nSD,binSt,binSize,pk)
%
% Inputs
%  T       - Main data table
%  B       - Thresholds table
%  nSD     - Table with number of standard deviations (default: 3)
%  binSt   - Index of "zero" bin (default: 51)
%  binSize - Width of bins (sec; default: 0.005)
%  pk      - Max. # of peaks to detect (default: 5)
%
% Output
%  C       - Table for mean spikes/channel with detected peak and peak times
%
% See also: Contents, new_analysis.m

if nargin < 3
   nSD = 3;
end

if nargin < 4
   binSt = 51;
end

if nargin < 5
   binSize = 0.005;
end

if nargin < 6
   pk = 5; 
end


disp("Creating table `C`...");
fn = @(X){nanmean(X,1)};
outputVars = 'Spike_Mean';
C = tbl.stats.estimateChannelResponse(T,fn,'Spikes',outputVars);
B.Threshold = (B.Mean_Baseline.*binSize) + ((B.STD_Baseline.*binSize).*nSD); % Threshold is 3SD over baseline and should be in spikes/5ms or spikes per bin
C.Threshold = zeros(size(C,1),1);
for i = 1:size(B.Threshold,1)
    idx = (C.BlockID == B.BlockID(i) & C.ChannelID == B.ChannelID(i));
    C.Threshold(idx) = B.Threshold(i);
end

% Find latencies of peaks
disp("Finding peak latencies...")
ts = C.Properties.UserData.t.Spikes(binSt:end);
P = C.Spike_Mean(:,binSt:end);
C.ICMS_Onset = round(C.ICMS_Onset,2);
C.Solenoid_Onset = round(C.Solenoid_Onset,2);
[G,uniq] = findgroups(C(:,{'ICMS_Onset','Solenoid_Onset'}));
for i = 1:size(uniq, 1) % Zero activity before first stim
    a = min(table2array(uniq(i,:)));
    alignBin = a/(binSize*0.001);
    if alignBin > 0
        idx = G == i;
        P(idx,1:alignBin) = 0;
    end
end
for i = 1: size(P,1) % Zero spikes under threshold
    p = P(i,:);
    idx = p <= (C.Threshold(i)); 
    p(idx) = 0;
    P(i,:) = p;
end
rep = P == 0;
P(rep) = NaN;
[P_sort, idx] = sort(P,2,'descend','MissingPlacement','last');
C.ampMax = [P_sort(:,1:pk)];
C.ampBin = idx(:,1:pk);
C.ampTime = cell2mat(arrayfun(@(bin)ts(bin),C.ampBin,'UniformOutput',false));
n = isnan(C.ampMax);
C.ampBin(n) = 0;
C.ampTime(n) = nan;
C.pkTime = C.ampBin.*binSize;

% Add "unified" stimulus times for ease-of-use
C = tbl.addExperimentOnsetOffsetTimes(C);
C.Response_Offset__Exp = C.Solenoid_Onset__Exp*1e3;

end