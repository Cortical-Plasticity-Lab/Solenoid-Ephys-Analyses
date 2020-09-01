function t = tLFPpeak(LFP_mean,tStimulus,tLFP,peakType,varargin)
%TLFPPEAK Estimate time to peak average LFP deflection of specified type
%
%  t = tbl.est.tLFPpeak(LFP_mean,tStimulus,tLFP,peakType);
%  t = tbl.est.tLFPpeak(LFP_mean,tStimulus,tLFP,peakType,'Name',value,...);
%     -> e.g. tbl.est.tLFPpeak(LFP_mean,tStimulus,tLFP,'min','ZeroLFPBeforeThisTimeMS',150);
%
% Inputs
%  LFP_mean    - See tbl.stats.estimateChannelResponse; Channel-aggregated
%                 LFP-mean across trials of the same type. 
%  tStimulus   - Scalar or array of stimulus times, with one element per
%                 row of LFP_mean (should usually be one row, so one
%                 element). Times are in milliseconds. Positive values
%                 represent stimuli that are delayed with respect to the
%                 start of the "trial."
%  tLFP        - Times that correspond to columns of LFP_mean, relative to
%                 stimuli of interest. Times are in milliseconds.
%  peakType    - 'min' or 'max'
%  varargin    - Parameter 'Name',value input arguments. See 'PARS' code.
%  
% Output
%  t           - Time to the main negative-going deflection.
%
% See also: tbl, tbl.stats, tbl.est, tbl.stats.estimateChannelResponse
 
% PARS % % % % %
pars = struct;
pars.ZeroLFPBeforeThisTimeMS = 10;
fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end
% END PARS % % %

for iRow = 1:size(LFP_mean,1) % For now, this should always be 1
   minTimeToSearchForPeak = pars.ZeroLFPBeforeThisTimeMS + tStimulus(iRow);
   LFP_mean(tLFP < minTimeToSearchForPeak) = 0; % Don't care about these
end
switch lower(peakType)
   case 'max'
      % Specify dimension in case LFP_mean is array in future version:
      [~,iPk] = max(LFP_mean,[],2); % Get index of maximum value.
   case 'min'
      [~,iPk] = min(LFP_mean,[],2); % Get index of minimum value.
   otherwise
      error(['\n\tUnrecognized value for peakType: <strong>%s</strong>\n' ...
             '\t\t->\t(Should be ''min'' or ''max'')\n'],peakType);
end

% Account for stimulus offset delay
t = tLFP(iPk) - tStimulus;
end