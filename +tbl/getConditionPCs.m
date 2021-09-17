function [coeff,score,explained,S,rate,t] = getConditionPCs(T,C,tLim)
%GETCONDITIONPCS Return PCA, new table, and rate data/times for conditions
%
%  [coeff,score,explained,S,rate,t] = tbl.getConditionPCs(T,C);
%  [coeff,score,explained,S,rate,t] = tbl.getConditionPCs(T,C,tLim);
%
% Inputs
%  T - Original data table (after any exclusions): `Reduced-Table.mat`
%  C - Struct array where each array element has fields:
%        * 'Variable' : (e.g. 'Type' or 'Area'; variable in `T`)
%        * 'Value' : (e.g. "Solenoid" or "RFA"; value for 'Variable' match)
%  tLim - [min time (s), max time (s)] default: [0.050, 0.300]
%
% Output
%  [coeff,score,explained] - See also PCA
%  S - Reduced subset of `T` by condition
%  rate - Data array matrix after square-root transform on rates
%  t - Times corresponding to columns of `rate`
%
% See also: tbl, utils.getSelector, run_stats, run_stats_pca

if nargin < 3
   tLim = [0.050, 0.300];
end

if nargin < 2
    C = utils.getSelector("Type", ["Solenoid", "ICMS", "Solenoid + ICMS"]);
end

% Return logical "mask" vector and select only those rows.
iRow = utils.selector2mask(C,T);
S = T(iRow,:);

S.Type = string(S.Type);
S.Area = string(S.Area);
S.Lamina = string(S.Lamina);
t = S.Properties.UserData.t.Spikes; % (relative) time of each sample bin center (sec)
tIdx = (t >= tLim(1)) & (t <= tLim(2));
t = t(tIdx);

X = S.Rate(:,tIdx); % Get samples of interest
rate = sqrt(max(X,0));

[coeff,score,~,~,explained] = pca(rate);

end