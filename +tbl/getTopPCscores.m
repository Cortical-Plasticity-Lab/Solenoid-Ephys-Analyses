function [P,M,TT] = getTopPCscores(T)
%GETTOPPCSCORES Return table with top-K principal component scores
%
%  [P,M,TT] = tbl.getTopPCscores(T);
%
% Inputs
%  T - Main data table after `Scores` and `Coeffs` added in using for
%        example
%        `T = tbl.stats.addSolenoidLFPbetas(T,C,3);`
%
% Output
%  P - Subset where each row corresponds to a different principal component
%        for a particular recording
%  M - Same as `P` but with `Score` averaged by Trial Type
%  TT - Same as M but rearranged for Time-Table format
%
% See also: Contents, batch_LFP_response_PCA, tbl.stats,
%              tbl.stats.addSolenoidLFPbetas

% if nargin < 2
%    responseFcn = @(lfp){rms(lfp,1)};
% end
% 
% if nargin < 3
%    response = 'LFP';
% end
% 
% K = size(T.Coeff,2);
% 
% [G,TID] = findgroups(T(:,{'GroupID','SurgID','AnimalID','ElectrodeID','BlockID','BlockIndex','Type','Area','ICMS_Onset','Solenoid_Onset','Solenoid_Offset','Lamina'}));
% TID.data = cell2mat(splitapply(responseFcn,T.(response),G));
% TID.coeff = cell2mat(splitapply(@(x){x(1,:)},T.Coeff,G));
% 
% [g,p] = findgroups(TID(:,{'GroupID','SurgID','AnimalID','BlockID','BlockIndex','Type','Area','ICMS_Onset','Solenoid_Onset','Solenoid_Offset'}));
% 
% P = [];
% for k = 1:K
%    [tmp,p.PC] = ...
%          splitapply(@(data,coef)estimateScore(data,coef,k),...
%             TID.data,TID.coeff,g);
%    p.(response) = cell2mat(tmp);
%    P = [P; p]; %#ok<AGROW>
% end
% 
% 
%    function [score,k] = estimateScore(data,coef,k)
%       score = {sum(data.*coef(:,k),1)};      
%    end

[G,P] = findgroups(T(:,'TrialID'));
P.Score = splitapply(@(data,coeff,tICMS,Type)suppressICMS_response(data,coeff,tICMS.*1e3,Type,T.Properties.UserData.t.LFP),T.LFP,T.Coeff,T.ICMS_Onset,T.Type,G);
P = utils.getSingleton(T,P,{'SurgID','BlockID','AnimalID','GroupID','Type','Solenoid_Onset','Solenoid_Offset','ICMS_Onset'},G);
[G,M] = findgroups(P(:,{'SurgID','BlockID','AnimalID','GroupID','Type','Solenoid_Onset','Solenoid_Offset','ICMS_Onset'}));
M.Score = splitapply(@averageScore,P.Score,G);

% ttmp = T.Properties.UserData.t.LFP;
% t1 = datetime(0,0,0,0,0,0,min(ttmp));
% t2 = datetime(0,0,0,0,0,0,max(ttmp));
% dt = mean(diff(ttmp));
% dt = milliseconds(dt);
% t = (t1:dt:t2)';
t = T.Properties.UserData.t.LFP';

nT = numel(t);
t = repmat(t,size(M,1),1);
m = M(:,1:(end-1));
m = repelem(m,nT,1);
Score = vertcat(M.Score{:});
TT = [table(t,Score), m]; 
   function mu = averageScore(score)
      mu = {nanmean(cat(3,score{:}),3)};
   end

   function data = suppressICMS_response(LFP,coeff,tICMS,Type,t)
      
      tICMS = unique(tICMS(~isinf(tICMS)));      
      iSuppress = abs(tICMS-t) < 10; % Suppress for 10-ms around it
      
      iSub = Type=="ICMS" | Type=="ICMS + Solenoid";
      LFP(iSub,iSuppress) = 0;            
      data = {(LFP')*coeff};
   end
end