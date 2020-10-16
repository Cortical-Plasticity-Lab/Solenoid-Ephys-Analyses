function [T,BID] = addStimLamina(T)
%ADDSTIMLAMINA Add Laminar classification of ICMS stimulation channel
%
%  T = tbl.addStimLamina(T);
%  [T,BID] = tbl.addStimLamina(T);
%
% Inputs
%  T - Main data table
%  
% Output
%  T   - Main data table with new variable `StimLamina` 
%  BID - Table of co-registrations of Stim channel to depth
%
% See also: Contents

tic;
fprintf(1,'Adding ICMS channel lamina...');
[B,BID] = findgroups(T(:,{'BlockID'}));
[BID.Depth,BID.Stim_Ch,BID.Area] = splitapply(@findStimDepth,...
   T.Stim_Ch,T.Area,T.ChannelID,T.Depth,B);

BID = tbl.addLaminarCategories(BID);
BID.Properties.VariableNames{'Lamina'} = 'StimLamina';
BID.Properties.VariableNames{'Depth'} = 'StimDepth';
BID.Properties.VariableUnits{'StimDepth'} = '\mum';
tmp = T.Properties.UserData;
T = outerjoin(T,BID,'Type','left',...
   'Keys',{'BlockID'},...
   'LeftVariables',setdiff(T.Properties.VariableNames,{'StimDepth','StimLamina'}),...
   'RightVariables',{'StimDepth','StimLamina'});
T.Properties.UserData = tmp;
fprintf(1,'complete (%5.2f sec)\n',toc);

   function [StimDepth,Stim_Ch,Area] = findStimDepth(Stim_Ch,Area,ChannelID,Depth)
      Stim_Ch = Stim_Ch(1);
      Area = Area(1);
      if strcmpi(Stim_Ch,"None")
         StimDepth = nan;
      else
         StimDepth = Depth(ChannelID==Stim_Ch);
         if numel(StimDepth) > 0
            StimDepth = StimDepth(1);
         else
            StimDepth = nan;
         end
      end
   end

end