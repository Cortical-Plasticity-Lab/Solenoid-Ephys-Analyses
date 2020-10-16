function [data,score] = applyPCs(DATA,coeff,idx)
%APPLYPCS Apply recovered coefficients to data (or subset)
%
%  [data,score] = utils.applyPCs(DATA,coeff);
%  [data,score] = utils.applyPCs(DATA,coeff,idx);
%
% Inputs
%  DATA  - Data to apply principal components to, where columns are
%           time-samples and rows are observations.
%  coeff - Principal component coefficients
%  idx   - (Optional) index to subset of DATA (rows) to use for returned
%                     dataset.

if nargin < 3
   idx = 1:size(DATA,1);
end

data = DATA(idx,:) - nanmean(DATA(idx,:),2);
score = data' * coeff(idx,:);

end