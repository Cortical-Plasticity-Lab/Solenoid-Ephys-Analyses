function T = addExperimentOnsetOffsetTimes(T)
%ADDEXPERIMENTONSETOFFSETTIMES Parses ICMS_Onset, Solenoid_Onset, Solenoid_Offset, and Type to append unified stimulus times
%
%  T = tbl.addExperimentOnsetOffsetTimes(T);
%
% Inputs
%  T - Any data table with ICMS_Onset, Solenoid_Onset, Solenoid_Offset, and
%        Type fields
%
% Output
%  T - Same as input data, with new fields:
%        'ICMS_Onset__Exp'
%        'Solenoid_Onset__Exp'
%        'Solenoid_Offset__Exp'
%        'Response_Offset__Exp' --> Set to zeros but this can be used with
%                                   other graphics functions etc so that
%                                   the offset for the response (which
%                                   might be set depending on if it is an
%                                   ICMS or Solenoid-related response that
%                                   is of interest) will be associated to
%                                   the table.
%
%     Which are the values, in seconds, of those onset times for any trial
%     across the experiment (block) even if the particular stimulus was not
%     actually delivered in that trial.
%
% See also: Contents, new_analysis.m

T_Both = T(string(T.Type)=="Solenoid + ICMS",:);
T_Both.ICMS_Onset__Exp = T_Both.ICMS_Onset;
T_Both.Solenoid_Onset__Exp = T_Both.Solenoid_Onset;
T_Both.Solenoid_Offset__Exp = T_Both.Solenoid_Offset;
T_Both.Response_Offset__Exp = zeros(size(T_Both,1),1);

newVars = {'ICMS_Onset__Exp','Solenoid_Onset__Exp','Solenoid_Offset__Exp','Response_Offset__Exp'};
[vOrig,iOrig] = setdiff(T.Properties.VariableNames,newVars);
[~,iSort] = sort(iOrig,'ascend');
vOrig = vOrig(iSort);

[T,iOrig] = outerjoin(T,T_Both,...
   'Type','Left',...
   'Keys',{'ElectrodeID','BlockID'},...
   'LeftVariables',vOrig,...
   'RightVariables',newVars);
[~,iSort] = sort(iOrig,'ascend');
T = T(iSort,:);
T = movevars(T,vOrig,'Before',1);
end