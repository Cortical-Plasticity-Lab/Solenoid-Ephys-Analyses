function T = addVarMaxMinTime(T,tOffset,varNameIn,varNameOut,maxMin)
%ADDVARMAXMINTIME Add LFP variance time-to-min as variable to main data table
%
%  T = tbl.addVarMaxMinTime(T,tOffset);
%
% Inputs
%  T - Main database table
%  tOffset - Vector of offsets. If not specified, then this is a vector of
%              zeros.
%  varNameIn - Name of variable to look for max or min
%              -> 'LFP' (def)
%  varNameOut - Name of output variable 
%              -> 'out' (def)
%  maxMin  - 'min' (def) | 'max'
%
% Output
%  T - Same table, with added variable `tLFPMin`
%
% See also: Contents, tbl, tbl.stats


tOffset(isnan(tOffset) | isinf(tOffset)) = 0;   

if nargin < 3
   varNameIn = 'LFP';
end

if nargin < 4
   varNameOut = 'out';
end

if nargin < 5
   maxMin = 'min';
end


tic;
fprintf(1,'Adding Lamina, ElectrodeID, Solenoid_ICMS_Delay, and Solenoid_Dwell variables...');  
T = tbl.addLaminarCategories(T);
T.TrialType = string(T.Type);
T.ElectrodeID = strcat(string(T.SurgID),"-",string(T.ChannelID));
T.Solenoid_ICMS_Delay = (T.Solenoid_Onset - T.ICMS_Onset).*1000;
T.Solenoid_ICMS_Delay(isinf(T.Solenoid_ICMS_Delay) | isnan(T.Solenoid_ICMS_Delay)) = 0;
T.Properties.VariableUnits{'Solenoid_ICMS_Delay'} = 'ms';
fprintf(1,'complete (%5.2f sec)\n',toc);

tic;
G = (1:size(T,1))';
if ~isfield(T.Properties.UserData.t,varNameIn)
   error('`varNameIn` ("%s") is not a field of input table Properties.UserData.t: cannot match times',varNameIn);
end

tLFP = T.Properties.UserData.t.(varNameIn);
fprintf(1,'Computing individual trial time-to-%s-%sima...',varNameIn,maxMin);

T.Solenoid_Dwell = T.Solenoid_Offset - T.Solenoid_Onset;
T.Properties.VariableUnits{'Solenoid_Dwell'} = 'sec';
% tZero == tOffset; if we use this with respect to some offset, we are
% interested in finding the (minima) that occurred after that offset.
switch lower(maxMin)
   case 'min'
      T.(varNameOut) = splitapply(...
         @(data,tZero)tbl.est.tLFPavgMin(data,tLFP,'ZeroLFPBeforeThisTimeMS',tZero),...
         T.(varNameIn),tOffset,G) - tOffset;
   case 'max' % Since tLFPavgMin is used, just flip the vector and look for min.
      T.(varNameOut) = splitapply(...
         @(data,tZero)tbl.est.tLFPavgMin(-data,tLFP,'ZeroLFPBeforeThisTimeMS',tZero),...
         T.(varNameIn),tOffset,G) - tOffset;
   otherwise
      error('Did not recognize value of `maxMin`: "%s" (should be ''min'' or ''max'')',maxMin);
end
T.Properties.VariableUnits{varNameOut} = 'ms';
fprintf(1,'complete (%5.2f sec)\n',toc);


end