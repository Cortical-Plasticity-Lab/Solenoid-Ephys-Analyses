 function [T,B,fig] = elimCh(T,thresh)
%ELIMCH Eliminate channels from blocks with low spiking 
%
%   [T,B] = tbl.elimCh(T,thresh);
%   [T,B,fig] = tbl.elimCh(T,thresh);
%
% Inputs
%  T           - Table of spike and LFP data with each row as an individual
%                 trial from the solenoid experiment
%  thresh      - User-defined spike/sec threshold
%
% Output
%  T           - Table without low-spiking channels in each block
%  B           - Table of baseline spike rates and standard deviations
%  fig         - (Optional) if requested generates a figure to double-check
%                    what was excluded.
%
% See also: tbl, tbl.est.spike_peak_amplitude

BASELINE = [-0.200 -0.050]; % Window from -200 ms to -50 ms prior to stim

dur = diff(BASELINE); % Total duration of baseline window
idx = T.Properties.UserData.t.Spikes >= BASELINE(1) & ...
      T.Properties.UserData.t.Spikes < BASELINE(2);

T.Baseline = (sum(T.Spikes(:,idx),2))./dur;           % Spike Rate during this time
[G,B] = findgroups(T(:,{'ChannelID','BlockID'}));     % Separate by unique identifier and block
B.Mean_Baseline = cell2mat(splitapply(@(X){nanmean(X,1)},T.Baseline,G)); 
B.STD_Baseline = cell2mat(splitapply(@(X){nanstd(X,[],1)},T.Baseline,G)); 
if nargout > 2
   fig = figure(...
      'Name','Histogram of Excluded Spikes',...
      'Color','w');
   histogram(sqrt(B.Mean_Baseline),50);     % Visualize distribution of spikes/sec
   axis([0 25 0 250]);
   set(get(gca,'Children'),'DisplayName','Baseline Rate',...
      'FaceColor',[0.2 0.2 0.8],'EdgeColor','none');
   line(ones(1,2).*sqrt(thresh),[0 250],'Color','r',...
      'LineStyle',':','LineWidth',2.5,...
      'DisplayName','Hard Spike Rate Threshold');
   xlabel('\surd(spikes/sec)','FontName','Arial','Color','k');
   ylabel('Count','FontName','Arial','Color','k');
   title('Distribution of Baseline Rates','FontName','Arial','Color','k');
   legend(gca,'Location','northeast','TextColor','black','FontName','Arial');
end
excl = B(B.Mean_Baseline <= thresh,:);     % Sets threshold value here

if numel(excl)>= 1
    for i = 1:size(thresh,1) 
      idx = (T.BlockID == excl.BlockID(i) & T.ChannelID == excl.ChannelID(i));
      T(idx,:)= [];
    end
end

end
