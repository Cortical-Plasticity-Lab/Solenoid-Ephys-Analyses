function S = label_ics(S,z)
%LABEL_ICS Always label the indepedent components similarly
%
%  S = analyze.factors.label_ics(S,z);
%
% Inputs
%  S - Data table to append `z` to as new "labeled" columns
%  z - Independent components weightings
%
% Output
%  S - Same as input but with the new variables (columns of `z`)
%
% See also: Contents, analyze.factors.getICs

S.ICA_Noise = z(:,1); % First IC is "noise floor" component - how active is the channel?
                      % --> This should be used as a covariate for the
                      %     other two, which are the responses of interest.

S.ICA_Late = z(:,2);  % Second IC is "late" component
                      
S.ICA_Early = z(:,3); % Third IC is "early" component

end