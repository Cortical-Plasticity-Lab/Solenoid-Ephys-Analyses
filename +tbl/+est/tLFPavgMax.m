function t = tLFPavgMax(LFP_mean,tLFP,varargin)
%TLFPAVGMAX Estimate time to maximum average LFP deflection
%
%  t = tbl.est.tLFPavgMax(LFP_mean);
%  t = tbl.est.tLFPavgMax(LFP_mean,'Name',value,...);
%     -> e.g. tbl.est.tLFPavgMax(LFP_mean,'ZeroLFPBeforeThisTimeMS',150);
%
% Inputs
%  LFP_mean - See tbl.stats.estimateChannelResponse; Channel-aggregated
%              LFP-mean across trials of the same type. 
%  tLFP     - Times that correspond to columns of LFP_mean, relative to
%                 stimuli of interest. 
%  varargin - Parameter 'Name',value input arguments. See 'PARS' section.
%  
% Output
%  t        - Time to the main negative-going deflection.
%
% See also: tbl, tbl.stats, tbl.est, tbl.stats.estimateChannelResponse
 
% PARS % % % % %
pars = struct;
pars.ZeroLFPBeforeThisTimeMS = 50;
fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end
% END PARS % % %

LFP_mean(tLFP < pars.ZeroLFPBeforeThisTimeMS) = 0; % Don't care about these
[~,iMax] = max(LFP_mean); % Get index of maximum value.
t = tLFP(iMax);
end