function [W,H,D] = getFactors(data,k,wrapOutput,varargin)
%GETFACTORS Return non-negative factors for response variable in data
%
%  [W,H,D] = utils.getFactors(data);
%  [W,H,D] = utils.getFactors(data,k);
%  [W,H,D] = utils.getFactors(data,k,wrapOutput);
%  [W,H,D] = utils.getFactors(data,k,wrapOutput,'Name1',value1,...);
%
% Inputs
%  data - C.(responseVar) where responseVar is for example 'LFP'
%           -> Columns are time-samples, rows are trial/observations
%
%        --> Can also be given as the table directly, in which case the
%              data column is automatically defined by 
%
%                 `data.Properties.UserData.ResponseVariable`           
%
%  k    - Number of factors (default: 12)
%
%  wrapOutput - Default: false, if true, automatically wrap outputs in cell
%
%  varargin  - (Optional) "name" value pairs (see `nnmf` built-in options)
%
% Output
%  W    - (n-by-k) factor weightings (Data = W*H + d, Data (n-by-m))
%  H    - (k-by-m) factor weightings
%  D    - root mean square residuals
%
% See also: Contents

if nargin < 2
   k = 12;
end

if nargin < 3
   wrapOutput = false;
end

[W,H,D] = nnmf(data,k,varargin{:});

if wrapOutput
   W = {W};
   H = {H};
   D = {D};
end

end