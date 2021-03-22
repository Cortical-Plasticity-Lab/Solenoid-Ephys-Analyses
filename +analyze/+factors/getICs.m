function [ica_mdl,z,R] = getICs(Y,coeff)
%GETICS Return reconstruction independent components model (rICA) and scores
%
%  [ica_mdl,z] = analyze.factors.getICs(Y,coeff);
%
% Inputs
%  Y     - Data vector for rICA. Rows are observations, columns variables
%  coeff - "Seeding" coefficients
%
% Output
%  ica_mdl - Reconstruction ICA model
%  z       - Independent component scores.
%  R       - Struct with regression info
%
% See also: Contents

if nargin < 2
   ica_mdl = rica(Y,3);
else
   ica_mdl = rica(Y,3,'InitialTransformWeights',coeff(:,1:3));
end
z = transform(ica_mdl,Y);
R = struct('TSS', nan, 'RSS', nan, 'Rsq', nan);
if nargin < 2
   return;
end
c = coeff(:,1:3);
Zt = c - nanmean(c,1);
R.TSS = sum(Zt(:).^2);
Zr = c - ica_mdl.TransformWeights;
R.RSS = sum(Zr(:).^2);
R.Rsq = 1 - (R.RSS / R.TSS);

end