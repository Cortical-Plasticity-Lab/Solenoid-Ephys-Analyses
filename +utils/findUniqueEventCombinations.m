function [TID,G] = findUniqueEventCombinations(T,printCombinations)
%FINDUNIQUEEVENTCOMBINATIONS Return or print table of unique event combinations
%
%  [TID,G] = utils.findUniqueEventCombinations(T);
%  -> Returns table of unique event combinations and the indices mapping 
%     rows of `T` into rows of `TID`, but does not print to command window.
%
%  TID = utils.findUniqueEventCombinations(T,true);
%  -> Returns table of unique event combinations and also prints to
%        command window.
%
%  utils.findUniqueEventCombinations(T);
%  -> Does not return table, but automatically prints to command window.
%
% See also: Contents, tbl.gfx.batchPETH

if nargin < 2
   printCombinations = false;
end

A = T(:,{'Solenoid_Onset','Solenoid_Offset','ICMS_Onset'});
[G,TID] = findgroups(A);
disp('<strong>Valid event time options:</strong>');

if (nargout < 1) || printCombinations
   fprintf(1,'    %14s    %15s    %10s\n',...
      '   (sec)   ','   (sec)   ','   (sec)   ');
   disp(TID);
end

end