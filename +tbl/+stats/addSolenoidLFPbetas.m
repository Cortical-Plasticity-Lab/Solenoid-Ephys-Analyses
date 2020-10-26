function T = addSolenoidLFPbetas(T,C,K)
%ADDSOLENOIDLFPBETAS Add Betas for solenoid-LFP RMS principal components
%
%  T = tbl.stats.addSolenoidLFPbetas(T);
%  T = tbl.stats.addSolenoidLFPbetas(T,C,K);
%
% Inputs
%  T - Main data table
%  C - Per-channel average LFP RMS response variable table (optional,
%        faster if included)
%  K - Number of principal components to include (default: 3)
%
% Output
%  T - Same as input table but with additional columns:
%     Beta_LFP_Solenoid_1 - Beta_LFP_Solenoid_K : Principal components for 
%                                                  top `K` components
%     Exp_LFP_Solenoid_1 - Exp_LFP_Solenoid_K : % Explained for top `K`
%                                               components

if nargin < 2
   C = tbl.stats.estimateChannelResponse(T,@(X,tICMS)suppressICMS_mean_response(X,tICMS.*1e3,T.Properties.UserData.t.LFP),{'LFP','ICMS_Onset','Type'},'LFP');
end

if nargin < 3
   K = 3;
end

[G,TID] = findgroups(C(:,{'BlockID','Type','Solenoid_Onset','Solenoid_Offset','ICMS_Onset'}));

% Get principal components and corresponding channel identifiers etc
tic;
fprintf(1,'Computing PCs...');
[~,TID.score,~,TID.explained] = splitapply(@(data)utils.getPCs(data',true),C.LFP,G);
[~,~,TID.coeff,~] = splitapply(@(data)utils.getPCs(data,true),C.LFP,G);
TID.ElectrodeID = splitapply(@(id){id},C.ElectrodeID,G);
for iT = 1:size(TID,1)
   if TID.Type(iT)~="Solenoid"
      TID.coeff{iT} = TID.coeff{TID.Type=="Solenoid" & TID.BlockID==TID.BlockID(iT)};
   end
end


% Merge back into main data table
fprintf(1,'organizing by channel...');
X = [];
for iT = 1:size(TID,1)
   x = TID(iT,{'BlockID','Type','Solenoid_Onset','Solenoid_Offset','ICMS_Onset'});
   ElectrodeID = TID.ElectrodeID{iT};
   nCh = numel(ElectrodeID);
   Score = TID.score{iT}(:,1:K);
   Coeff = TID.coeff{iT}(:,1:K);
   Explained = repmat(TID.explained{iT}(1:K)',nCh,1);
   
   
   x = repmat(x,nCh,1);
   X = [X; table(ElectrodeID), x, table(Score,Coeff,Explained)]; %#ok<AGROW>
end

tmp = T.Properties.UserData;
fprintf(1,'merging tables...');
idx = contains(T.Properties.VariableNames,'Score_') | contains(T.Properties.VariableNames,'Coeff_') | contains(T.Properties.VariableNames, 'Explained_');
T(:,idx) = [];
T = outerjoin(T,X,'Type','left',...
   'Keys',{'ElectrodeID','BlockID','Type','Solenoid_Onset','Solenoid_Offset','ICMS_Onset'},...
   'LeftVariables',setdiff(T.Properties.VariableNames,{'Score','Coeff','Explained'}),....
   'RightVariables',{'Score','Coeff','Explained'});
T.Properties.UserData = tmp;
T = splitvars(T, {'Score','Explained'});
fprintf(1,'complete (%5.2f sec)\n\n',toc);

   function data = suppressICMS_mean_response(LFP,tICMS,Type,t)
      
      tICMS = unique(tICMS(~isinf(tICMS)));
      if numel(tICMS) > 1
         error('Multiple unique ICMS times returned, should only be one.');
      end
      
      iSuppress = abs(tICMS-t) < 10; % Suppress for 10-ms around it
      
      iSub = Type=="ICMS" | Type=="ICMS + Solenoid";
      LFP(iSub,iSuppress) = 0;            
      data = {nanmean(LFP,1)};
   end

end