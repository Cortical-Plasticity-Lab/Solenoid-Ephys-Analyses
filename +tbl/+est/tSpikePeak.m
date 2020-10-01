function t = tSpikePeak(Spike_Mean,tStimulus,tSpike,peakType,varargin)
%TSPIKEPEAK Estimate time to peaks in spiking 
%
%  t = tbl.est.tSpikePeak(Spike_Mean,tSpike,peakType);
%  t = tbl.est.tSpikePeak(Spike_Mean,tSpike,peakType,'Name',value,...);
%
% Inputs
%  Spike_Mean  - See tbl.est.spike_peak_latency; Channel-aggregated
%                 mean spike rates across trials of the same type. 
%  tStimulus   - Scalar or array of stimulus times, with one element per
%                 row of LFP_mean. 
%  tSpike      - Times that correspond to columns of LFP_mean, relative to
%                 stimuli of interest.
%  peakType    - 'min' or 'max'
%  varargin    - Parameter 'Name',value input arguments. See 'PARS' code.
%  
% Output
%  t           - Time to the peak in spike rates.
%
% See also: tbl, tbl.est.spike_peak_latency, tbl.est, tbl.stats.estimateChannelResponse
 
% PARS % % % % %
pars = struct;
fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end
% END PARS % % %
for iRow = 1:size(Spike_Mean,1) % For now, this should always be 1
   minTimeToSearchForPeak = tStimulus(iRow);
   Spike_Mean(tSpike < minTimeToSearchForPeak) = 0; % Don't care about these
end
switch lower(peakType)
   case 'max'
      [~,iPk] = max(Spike_Mean,[],2); 
   case 'min'
      [~,iPk] = min(Spike_Mean,[],2); 
   otherwise
      error(['\n\tUnrecognized value for peakType: <strong>%s</strong>\n' ...
             '\t\t->\t(Should be ''min'' or ''max'')\n'],peakType);
end

t = tSpike(iPk) - tStimulus;
end