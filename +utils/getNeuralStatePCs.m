function [coeff,score,explained,mu,ElectrodeID,AP,ML,Depth,Type] = getNeuralStatePCs(data,electrodeID,ap,ml,depth,Type,K,wrapOutput)
%GETNEURALSTATEPCS Return PCA data for neural state by concatenating trials
%
%  [coeff,score,explained,mu] = utils.getNeuralStatePCs(data);
%  [__] = utils.getNeuralStatePCs(data,K);
%  [__] = utils.getNeuralStatePCs(data,K,wrapOutput);
%  [__] = utils.getNeuralStatePCs(data,K,wrapOutput,electrodeID,ap,ml,depth);
%
% Inputs
%  data        - LFP or Spike data
%  electrodeID - "Channel" unique identifier
%  K           - # Principal components to return (default: 3)
%  wrapOutput  - (default: false) if true, returns each output as cell
%                    array
%
% Output
%  coeff       - PCA coefficients (DATA = score*coeff' + mu)
%                 -> Where DATA is the vertically concatenated data, with
%                       columns as electrodes
%  score       - PCA scores, each column is a different principal component
%  explained   - Amount of variance explained by each column in `score`
%  mu          - "DC Offset" in dataset that is removed prior to
%                 decomposition
%
% See also: Contents

if nargin < 7
   K = 3;
end

if nargin < 8
   wrapOutput = false;
end

T = table(electrodeID,ap,ml,depth,'VariableNames',{'ElectrodeID','AP','ML','Depth'});
[G,EID] = findgroups(T);
[g,eid] = findgroups(table(electrodeID,ap,ml,depth,Type));
eidx = find(eid.electrodeID==eid.electrodeID(1));
g = g(ismember(g,eidx));
Type = eid.Type(g);

X = splitapply(@(d){reorient(d)},data,G);
x = horzcat(X{:});
[coeff,score,~,~,explained,mu] = pca(x,'Algorithm','svd','Economy',true);


if ~wrapOutput
   coeff = coeff(:,1:K);
   score = score(:,1:K);
   explained = explained(1:K);
   ElectrodeID = EID.ElectrodeID;
   AP = EID.AP;
   ML = EID.ML;
   Depth = EID.Depth;
else
   coeff = {coeff(:,1:K)};
   score = {score(:,1:K)};
   explained = {explained(1:K)};
   mu = {mu};
   ElectrodeID = {EID.ElectrodeID};
   AP = {EID.AP};
   ML = {EID.ML};
   Depth = {EID.Depth};
   Type = {Type};
end

   function data = reorient(data)
      data = data';
      data = data(:);
   end

end