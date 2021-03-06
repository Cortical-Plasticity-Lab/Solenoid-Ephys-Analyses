 function [T,B,fig] = elimCh(T,fixed_raw_thresh,baselineWindow)
%ELIMCH Eliminate channels from blocks with low spiking 
%
%   T = tbl.elimCh(T,fixed_raw_thresh);
%   [T,fig] = tbl.elimCh(T,fixed_raw_thresh,baselineWindow);
%
% Inputs
%  T                     - Table of spike and LFP data with each row as 
%                          an individual trial from the solenoid experiment
%  fixed_raw_thresh      - User-defined spike/sec threshold
%
%     OPTIONAL:
%  
%  baselineWindow        - Time range for defining the per-channel/block
%                             threshold for what could be considered as
%                             peaks (sec). Otherwise uses value in 
%                             BASELINE_DEF, which is [-0.200 -0.050].
%
% Output
%  T           - Table without low-spiking channels in each block
%  B           - Table with mean spikes in baseline as well as userdata
%                 property indicating the correct bin indices to use for
%                 that same period. 
%  fig         - (Optional) if requested generates a figure to double-check
%                    what was excluded.
%
% See also: tbl, tbl.est.spike_peak_amplitude

BASELINE_DEF = [-0.200 -0.050];
if nargin < 3
   baselineWindow = BASELINE_DEF;
end

% Get mean spike rate in basal (for exclusion)
[T,B] = analyze.perObservationThreshold(T,baselineWindow); 

if nargout > 1
   fig = figure(...
      'Name','Histogram of Excluded Spikes',...
      'Color','w');
   histogram(sqrt(B.Mean_Baseline),50);      % Visualize distribution of spikes/sec
   axis([0 25 0 250]);
   set(get(gca,'Children'),'DisplayName','Baseline Rate',...
      'FaceColor',[0.2 0.2 0.8],'EdgeColor','none');
   line(ones(1,2).*sqrt(fixed_raw_thresh),[0 250],'Color','r',...
      'LineStyle',':','LineWidth',2.5,...
      'DisplayName','Hard Spike Rate Threshold');
   xlabel('\surd(spikes/sec)','FontName','Arial','Color','k');
   ylabel('Count','FontName','Arial','Color','k');
   title('Distribution of Baseline Rates','FontName','Arial','Color','k');
   legend(gca,'Location','northeast','TextColor','black','FontName','Arial');
end
excl = B(B.Mean_Baseline <= fixed_raw_thresh,:); % Sets threshold value here

if numel(excl)>= 1
    for i = 1:size(fixed_raw_thresh,1) 
      idx = (T.BlockID == excl.BlockID(i) & T.ChannelID == excl.ChannelID(i));
      T(idx,:)= [];
    end
end

end
