function D = findResponseDiff(C)
%FINDRESPONSEDIFF Return "differential" response for different peak latency windows
%
%  D = tbl.findResponseDiff(C);
%
% Inputs
%  C - Table from `run_stats.m`
%  
% Output
%  D - Table for `run_stats.m` where values are differences between either
%        Solenoid or ICMS and the "combined" Type
%
% See also: run_stats.m

if contains('Solenoid',unique(string(C.Type)))
   Type = "Solenoid";
else
   Type = "ICMS";
end

earlyPk = sprintf('NPeak_%s_Early',Type);
latePk = sprintf('NPeak_%s_Late',Type);
anyPk = sprintf('NPeak_%s_Any',Type);

earlyPk_both = sprintf('%s_combo',earlyPk);
latePk_both = sprintf('%s_combo',latePk);
anyPk_both = sprintf('%s_combo',anyPk);

combined = C(string(C.Type)~=Type,:);
D = C(string(C.Type)==Type,:);
D.(earlyPk_both) = combined.(earlyPk);
D.(latePk_both) = combined.(latePk);
D.(anyPk_both) = combined.(anyPk);
D.(sprintf('%s_delta',earlyPk)) = abs(D.(earlyPk_both) - D.(earlyPk));
D.(sprintf('%s_delta',latePk)) = abs(D.(latePk_both) - D.(latePk));
D.(sprintf('%s_delta',anyPk)) = abs(D.(anyPk_both) - D.(anyPk));


end