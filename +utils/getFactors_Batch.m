function [W,H,D,f] = getFactors_Batch(C,varargin)
%GETFACTORS_BATCH Return NNMF Factors in batch for several combinations of number of factors
%
%  [W,H,D,f] = utils.getFactors_Batch(C);
%  [W,H,D,f] = utils.getFactors_Batch(C,'N_Factors,3:20,'Response','Spikes');
%
% Inputs
%  C - Channel-level averages table
%  varargin - (Optional) 'Name',value pairs
%
% Output
%  W - Time-weightings cell array 
%  H - Channel-weightings cell array
%  D - Array of root-mean-square error in each factor reconstruction
%  f - Number of factors corresponding to elements of other outputs
%
% See also: utils, utils.getFactors

pars = struct;
pars.N_Factors = 3:20;
pars.Response = 'Spikes';

fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

f = pars.N_Factors;
N = numel(f);

W = cell(1,N); 
H = cell(1,N); 
D = nan(1,N);
for ii = 1:N
   [W{ii},H{ii},D(ii)] = utils.getFactors(C.(pars.Response)',f(ii),false);
end

end