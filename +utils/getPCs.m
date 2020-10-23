function [DATA,SCORE,coeff,explained] = getPCs(data,idx)
%GETPCS Return principal components for response variable in data
%
%  [DATA,SCORE,coeff,explained] = utils.getPCs(data);
%  [DATA,SCORE,coeff,explained] = utils.getPCs(data,idx);
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
%  idx  - Indexing vector (optional), indicates which rows of `data` are
%           used in recovering principal components. NOTE: the mean from
%           ALL rows (average value of each row in a column, for every
%           column) will still be subtracted from the data.
%
% Output
%  DATA      - Input data matrix minus the time-series average for each
%                 data-point.
%  SCORE     - Principal component scores
%  coeff     - Principal component coefficients
%  explained - Percent explained for each PC

if nargin < 2
   idx = true(size(data,1),1);
   wrapOutput = false;
elseif isscalar(idx)
   wrapOutput = idx;
   idx = true(size(data,1),1);
else
   wrapOutput = false;
end

if istable(data)
   T = data;
   if ~isstruct(T.Properties.UserData)
      error('Table UserData is not a struct. This property field must be a struct with field `ResponseVariable`, which is one of the table variables.');
   elseif ~isfield(T.Properties.UserData,'ResponseVariable')
      error('The `ResponseVariable` field is missing from UserData: this defines the response data, which is one of the table variables.');
   else
      responseVar = T.Properties.UserData.ResponseVariable;
   end
   if ~ismember(responseVar,T.Properties.VariableNames)
      error('The defined ResponseVariable ("%s") is not a table variable. Check input `data` table.',responseVar);
   end
   data = T.(responseVar);
end

DATA = data - nanmean(data,1);
[coeff,SCORE,~,~,explained,~] = pca(data(idx,:)');

if wrapOutput
   coeff = {coeff};
   SCORE = {SCORE};
   DATA = {DATA};
   explained = {explained};
end

end