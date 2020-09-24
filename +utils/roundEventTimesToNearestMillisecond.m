function T = roundEventTimesToNearestMillisecond(T,eventVars)
%ROUNDEVENTTIMESTONEARESTMILLISECOND Set ICMS onset/offset and Solenoid onset/offset to nearest millisecond value (as seconds)
%
%  T = utils.roundEventTimesToNearestMillisecond(T);
%  T = utils.roundEventTimesToNearestMillisecond(T,eventVars);
%
% Inputs
%  T           - Main data table
%  eventVars   - (Optional) Cell array of event variable names to round
%
% Output
%  T           - Main data table with rounded event times
%
% See also: Contents

if nargin < 2
   eventVars = {'ICMS_Onset','Solenoid_Onset','Solenoid_Offset'};
end

for iV = 1:numel(eventVars)
   x = T.(eventVars{iV});
   x = x.*1e3; % Convert to milliseconds
   y = round(x).*1e-3; % Round and convert back to seconds
   T.(eventVars{iV}) = y;      
end

end