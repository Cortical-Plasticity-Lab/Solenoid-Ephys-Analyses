function T = elimCh(T,bt,dur,thresh)
%ELIMCH Eliminate channels from blocks with low spiking 
%
%   T = tbl.elimCh(T,bt,dur);
%
% Inputs
%  T           - Table of spike and LFP data with each row as an individual
%                 trial from the solenoid experiment
%  bt          - Array with bins from start to end of trial with a 10ms buffer
%  dur         - Total time set with 'bt' in seconds
%  thresh      - User-defined spike/sec threshold
%
% Output
%  T           - Table without low-spiking channels in each block
%
% See also: tbl, tbl.est.spike_peak_amplitude

initialVars = who;
base = (T.Spikes(:,bt));      % Isolate spiking data from trial
T.Baseline = (sum(base,2))./dur;   % Total of spikes in time frame
[G,B] = findgroups(T(:,{'ChannelID','BlockID'}));     % Separate by unique identifier and block
B.Mean_Baseline = cell2mat(splitapply(@(X){nanmean(X,1)},T.Baseline,G)); 
histogram(B.Mean_Baseline(B.Mean_Baseline <= 25),50);     % Visualize distribution of spikes/sec
axis([0 25 0 150])
excl = B(B.Mean_Baseline <= thresh,:);     % Sets threshold value here
for i = 1:size(thresh,1) 
    idx = (T.BlockID == excl.BlockID(i) & T.ChannelID == excl.ChannelID(i));
    T(idx,:)= [];
end

clearvars('-except',initialVars{:})
end
