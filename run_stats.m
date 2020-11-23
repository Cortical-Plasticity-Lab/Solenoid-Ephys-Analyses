%RUN_STATS Run statistical analyses for Frontiers paper

clc; close all force;
clearvars -except B C T

if exist('C','var')==0
   % This is the table `C` produced in `new_analysis.m`
   C = getfield(load('Fig3_Table.mat','C'),'C');
end

% DEFINE WINDOWS HERE:
W_EARLY_SOL    = [0.015 0.045]; % Seconds [window start | window stop]
W_LATE_SOL     = [0.090 0.300]; % Seconds [window start | window stop]
W_EARLY_ICMS   = [0.005 0.020]; % Seconds [window start | window stop]
W_LATE_ICMS    = [0.050 0.300]; % Seconds [window start | window stop]
W_ANY          = [0.005 0.500]; % Seconds [window start | window stop]

% DEFINE MODELS HERE:
mdlspec_str_main = "peakVal ~ 1 + Area*Type*Lesion_Volume + Depth + Area:Depth + peakTime + Area:peakTime + (1 + peakTime|AnimalID)";
mdlspec_str_sol = "%s ~ 1 + Area*Type*Lesion_Volume + (1 + Depth|Area:Type) + (1|AnimalID)";
mdlspec_str_icms = "%s ~ 1 + Area*Type*Lesion_Volume + (1 + StimDepth + Depth|Area:Type) + (1|AnimalID)";
glme_mdl_args = {...
   'Distribution','gamma',...
   'Link',-1,...
   'DummyVarCoding','effects',...
   ... 'CovariancePattern',{'Diagonal','Diagonal'},...
   'FitMethod','REMPL'};

% REORGANIZE DATA:
% % Uncomment to run without figures: % %
P = tbl.peaks2rows(C);

% % % Uncomment to make figures: % % %
% [P,sFig,eFig] = tbl.peaks2rows(C);
% io.optSaveFig(sFig,'figures/fig3_stats','A1 - Ranked Peak Values Swarm Charts');
% io.optSaveFig(eFig,'figures/fig3_stats','A2 - Example of Multi-Peaked Evoked Spikes');

warning('off','stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadDistLinkCombination1');
mdl = struct;

% [B1/B2] Run "full" model using all Types
tic; fprintf(1,'Computing GLME for <strong>FULL MODEL</strong>...');
mdl.Full = fitglme(P,mdlspec_str_main,glme_mdl_args{:},...
   'Exclude',P.peakTime <= 0);
fprintf(1,'complete (%5.2f sec)\n',toc);
[covFig,residFig] = utils.showModelInfo(mdl.Full,'FULL MODEL');
io.optSaveFig(covFig,'figures/fig3_stats','B1 - Covariance Matrices');
io.optSaveFig(residFig,'figures/fig3_stats','B2 - Residuals');

% COMPUTE SOLENOID RESPONSES FIRST:
C.NPeak_Solenoid_Early = tbl.countWindowedResponses(...
   C.peakTime - C.Solenoid_Onset__Exp,...  % Relative times (seconds)
   W_EARLY_SOL(1),W_EARLY_SOL(2));                % Window (seconds)
C.NPeak_Solenoid_Late = tbl.countWindowedResponses(...
   C.peakTime - C.Solenoid_Onset__Exp,...  % Relative times (seconds)
   W_LATE_SOL(1),W_LATE_SOL(2));                  % Window (seconds)
C.NPeak_Solenoid_Any = tbl.countWindowedResponses(...
   C.peakTime - C.Solenoid_Onset__Exp,...  % Relative times (seconds)
   W_ANY(1),W_ANY(2));                    % Window (seconds)

% COMPUTE ICMS RESPONSES SECOND:
C.NPeak_ICMS_Early = tbl.countWindowedResponses(...
   C.peakTime - C.ICMS_Onset__Exp,...   % Relative times (seconds)
   W_EARLY_ICMS(1),W_EARLY_ICMS(2));             % Window (seconds)
C.NPeak_ICMS_Late = tbl.countWindowedResponses(...
   C.peakTime - C.ICMS_Onset__Exp,...   % Relative times (seconds)
   W_LATE_ICMS(1),W_LATE_ICMS(2));               % Window (seconds)
C.NPeak_ICMS_Any = tbl.countWindowedResponses(...
   C.peakTime - C.ICMS_Onset__Exp,...   % Relative times (seconds)
   W_ANY(1),W_ANY(2));                 % Window (seconds)

% EVALUATE STATISTICAL MODELS:
% Initialize struct to organize GLME model objects
mdl.Solenoid = struct('Early',[],'Late',[],'Any',[]);
mdl.ICMS = struct('Early',[],'Late',[],'Any',[]);

glme_mdl_args = {...
   'Distribution','binomial',...
   'Link','logit',...
   'DummyVarCoding','effects',...
   ... 'CovariancePattern',{'Diagonal','Diagonal'},...
   'FitMethod','REMPL'};

% mdlspec_str allows us to just insert the name of the response variable.
% glme_mdl_args are "generic" model arguments that will always be the same.

Cs = C;
Cs.Type = string(Cs.Type);
Cs.Properties.UserData.NumExcluded = struct;

% SOLENOID: Exclude ICMS trials (there will be no "solenoid" peak)
Csol = Cs(Cs.Type~="ICMS",:);
id = strcat(Csol.ElectrodeID,'::',num2str(Csol.BlockIndex));
exc = tbl.requireAnyResponse(Csol.NPeak_Solenoid_Early + Csol.NPeak_Solenoid_Late,id,string(Csol.Type));
Csol(exc,:) = [];
id(exc) = [];
Csol.BinomialSize = tbl.findMaxResponse(Csol.NPeak_Solenoid_Any,id,string(Csol.Type));
Csol.Properties.RowNames = strcat(Csol.Properties.RowNames,"-N:",num2str(Csol.BinomialSize));

% [C1/C2] Run model for SOLENOID + EARLY
tic; 

fprintf(1,'\n\n\t\t<strong>WITHOUT EXCLUSIONS</strong>\n\n');

fprintf(1,'\n------------------------------------\n');
fprintf(1,'\n\t<strong>EARLY SOLENOID</strong> (%d <= t < %d ms)\n',...
   W_EARLY_SOL*1e3);
fprintf(1,'\n------------------------------------\n');
fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
   sprintf(mdlspec_str_sol,"NPeak_Solenoid_Early"));
fprintf(1,'Excluding <strong>%d</strong> observations.\n',sum(exc));
fprintf(1,'Fitting Binomial GLME for solenoid-early...');
mdl.Solenoid.Early = fitglme(Csol,sprintf(mdlspec_str_sol,"NPeak_Solenoid_Early"),...
   glme_mdl_args{:},...
   'BinomialSize',Csol.BinomialSize,...
   'Offset',ones(size(Csol,1),1));
fprintf(1,'complete (%5.2f sec)\n',toc);
[covFig,residFig] = utils.showModelInfo(mdl.Solenoid.Early,'SOLENOID + EARLY');
io.optSaveFig(covFig,'figures/fig3_stats','C1 - Covariance Matrices');
io.optSaveFig(residFig,'figures/fig3_stats','C2 - Residuals');

% [D1/D2] Run model for SOLENOID + LATE
tic; 
fprintf(1,'\n------------------------------------\n');
fprintf(1,'\n\t<strong>LATE SOLENOID</strong> (%d <= t < %d ms)\n',...
   W_LATE_SOL*1e3);
fprintf(1,'\n------------------------------------\n');
fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
   sprintf(mdlspec_str_sol,"NPeak_Solenoid_Late"));
fprintf(1,'Excluding <strong>%d</strong> observations.\n',sum(exc));
fprintf(1,'Fitting Binomial GLME for solenoid-late...');
mdl.Solenoid.Late = fitglme(Csol,sprintf(mdlspec_str_sol,"NPeak_Solenoid_Late"),...
   glme_mdl_args{:},...
   'BinomialSize',Csol.BinomialSize,...
   'Offset',ones(size(Csol,1),1));
fprintf(1,'complete (%5.2f sec)\n',toc);
[covFig,residFig] = utils.showModelInfo(mdl.Solenoid.Late,'SOLENOID + LATE');
io.optSaveFig(covFig,'figures/fig3_stats','D1 - Covariance Matrices');
io.optSaveFig(residFig,'figures/fig3_stats','D2 - Residuals');
fprintf(1,'\n------------------------------------\n');

% ICMS: Exclude Solenoid trials (there will be no "ICMS" peak)
Cicms = Cs(Cs.Type~="Solenoid",:);
id = strcat(Cicms.ElectrodeID,'::',num2str(Cicms.BlockIndex));
exc = tbl.requireAnyResponse(Cicms.NPeak_ICMS_Early + Cicms.NPeak_ICMS_Late,id,string(Cicms.Type));
Cicms(exc,:) = [];
id(exc) = [];
Cicms.BinomialSize = tbl.findMaxResponse(Cicms.NPeak_ICMS_Any,id,string(Cicms.Type));

% [E1/E2] Run model for ICMS + EARLY
tic; 
fprintf(1,'\n------------------------------------\n');
fprintf(1,'\n\t<strong>EARLY ICMS</strong> (%d <= t < %d ms)\n',...
   W_EARLY_ICMS*1e3);
fprintf(1,'\n------------------------------------\n');
fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
   sprintf(mdlspec_str_icms,"NPeak_ICMS_Early"));
fprintf(1,'Excluding <strong>%d</strong> observations.\n',sum(exc));
fprintf(1,'Fitting Binomial GLME for ICMS-early...');
mdl.ICMS.Early = fitglme(Cicms,sprintf(mdlspec_str_icms,"NPeak_ICMS_Early"),...
   glme_mdl_args{:},...
   'BinomialSize',Cicms.BinomialSize,...
   'Offset',ones(size(Cicms,1),1));
fprintf(1,'complete (%5.2f sec)\n',toc);
[covFig,residFig] = utils.showModelInfo(mdl.ICMS.Early,'ICMS + EARLY');
io.optSaveFig(covFig,'figures/fig3_stats','E1 - Covariance Matrices');
io.optSaveFig(residFig,'figures/fig3_stats','E2 - Residuals');

% [F1/F2] Run model for ICMS + LATE
tic; 
fprintf(1,'\n------------------------------------\n');
fprintf(1,'\n\t<strong>LATE ICMS</strong> (%d <= t < %d ms)\n',...
   W_LATE_ICMS*1e3);
fprintf(1,'\n------------------------------------\n');
fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
   sprintf(mdlspec_str_icms,"NPeak_ICMS_Late"));
fprintf(1,'Excluding <strong>%d</strong> observations.\n',sum(exc));
fprintf(1,'Fitting Binomial GLME for ICMS-late...');
mdl.ICMS.Late = fitglme(Cicms,sprintf(mdlspec_str_icms,"NPeak_ICMS_Late"),...
   glme_mdl_args{:},...
   'BinomialSize',Cicms.BinomialSize,...
   'Offset',ones(size(Cicms,1),1));
fprintf(1,'complete (%5.2f sec)\n',toc);
[covFig,residFig] = utils.showModelInfo(mdl.ICMS.Late,'ICMS + Late');
io.optSaveFig(covFig,'figures/fig3_stats','F1 - Covariance Matrices');
io.optSaveFig(residFig,'figures/fig3_stats','F2 - Residuals');
fprintf(1,'\n------------------------------------\n');

% % RERUN MODELS USING EXCLUSIONS FOR OBSERVATIONS WITH ZERO-PEAK % % 
fprintf(1,'\n\n\t\t<strong>WITH EXCLUSIONS</strong>\n\n');

% [C3/C4] Run model for SOLENOID + EARLY
tic; 
fprintf(1,'\n------------------------------------\n');
fprintf(1,'\n\t<strong>EARLY SOLENOID (+ Exclude)</strong> (%d <= t < %d ms)\n',...
   W_EARLY_SOL*1e3);
fprintf(1,'\n------------------------------------\n');
fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
   sprintf(mdlspec_str_sol,"NPeak_Solenoid_Early"));
fprintf(1,'Excluding an additional <strong>%d</strong> observations.\n',sum(Csol.NPeak_Solenoid_Early==0));
fprintf(1,'Fitting Binomial GLME for solenoid-early...');
mdl.Solenoid.Early_Exclude = fitglme(Csol,sprintf(mdlspec_str_sol,"NPeak_Solenoid_Early"),...
   glme_mdl_args{:},...
   'BinomialSize',Csol.BinomialSize,...
   'Exclude',Csol.NPeak_Solenoid_Early==0);
fprintf(1,'complete (%5.2f sec)\n',toc);
[covFig,residFig] = utils.showModelInfo(mdl.Solenoid.Early_Exclude,'SOLENOID + EARLY + EXCLUDE');
io.optSaveFig(covFig,'figures/fig3_stats','C3 - Covariance Matrices');
io.optSaveFig(residFig,'figures/fig3_stats','C4 - Residuals');

% [D3/D4] Run model for SOLENOID + LATE
tic; 
fprintf(1,'\n------------------------------------\n');
fprintf(1,'\n\t<strong>LATE SOLENOID (+ Exclude)</strong> (%d <= t < %d ms)\n',...
   W_LATE_SOL*1e3);
fprintf(1,'\n------------------------------------\n');
fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
   sprintf(mdlspec_str_sol,"NPeak_Solenoid_Late"));
fprintf(1,'Excluding an additional <strong>%d</strong> observations.\n',sum(Csol.NPeak_Solenoid_Late==0));
fprintf(1,'Fitting Binomial GLME for solenoid-late...');
mdl.Solenoid.Late_Exclude = fitglme(Csol,sprintf(mdlspec_str_sol,"NPeak_Solenoid_Late"),...
   glme_mdl_args{:},...
   'BinomialSize',Csol.BinomialSize,...
   'Exclude',Csol.NPeak_Solenoid_Late==0);
fprintf(1,'complete (%5.2f sec)\n',toc);
[covFig,residFig] = utils.showModelInfo(mdl.Solenoid.Late_Exclude,'SOLENOID + LATE + EXCLUDE');
io.optSaveFig(covFig,'figures/fig3_stats','D3 - Covariance Matrices');
io.optSaveFig(residFig,'figures/fig3_stats','D4 - Residuals');
fprintf(1,'\n------------------------------------\n');

% [E3/E4] ICMS: Exclude Solenoid trials (there will be no "ICMS" peak)
% Run model for ICMS + EARLY AFTER EXCLUSIONS
tic; 
fprintf(1,'\n------------------------------------\n');
fprintf(1,'\n\t<strong>EARLY ICMS (+ Exclude)</strong> (%d <= t < %d ms)\n',...
   W_EARLY_ICMS*1e3);
fprintf(1,'\n------------------------------------\n');
fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
   sprintf(mdlspec_str_icms,"NPeak_ICMS_Early"));
fprintf(1,'Excluding an additional <strong>%d</strong> observations.\n',sum(Cicms.NPeak_ICMS_Early==0));
fprintf(1,'Fitting Binomial GLME for ICMS-early...');
mdl.ICMS.Early_Exclude = fitglme(Cicms,sprintf(mdlspec_str_icms,"NPeak_ICMS_Early"),...
   glme_mdl_args{:},...
   'BinomialSize',Cicms.BinomialSize,...
   'Exclude',Cicms.NPeak_ICMS_Early==0);
fprintf(1,'complete (%5.2f sec)\n',toc);
[covFig,residFig] = utils.showModelInfo(mdl.ICMS.Early_Exclude,'ICMS + EARLY + EXCLUDE');
io.optSaveFig(covFig,'figures/fig3_stats','E3 - Covariance Matrices');
io.optSaveFig(residFig,'figures/fig3_stats','E4 - Residuals');

% [F3/F4] Run model for ICMS + LATE
tic; 
fprintf(1,'\n------------------------------------\n');
fprintf(1,'\n\t<strong>LATE ICMS (+ Exclude)</strong> (%d <= t < %d ms)\n',...
   W_LATE_ICMS*1e3);
fprintf(1,'\n------------------------------------\n');
fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
   sprintf(mdlspec_str_icms,"NPeak_ICMS_Late"));
fprintf(1,'Excluding an additional <strong>%d</strong> observations.\n',sum(Cicms.NPeak_ICMS_Late==0));
fprintf(1,'Fitting Binomial GLME for ICMS-late...');
mdl.ICMS.Late_Exclude = fitglme(Cicms,sprintf(mdlspec_str_icms,"NPeak_ICMS_Late"),...
   glme_mdl_args{:},...
   'BinomialSize',Cicms.BinomialSize,...
   'Exclude',Cicms.NPeak_ICMS_Late==0);
fprintf(1,'complete (%5.2f sec)\n',toc);
[covFig,residFig] = utils.showModelInfo(mdl.ICMS.Late_Exclude,'ICMS + LATE + EXCLUDE');
io.optSaveFig(covFig,'figures/fig3_stats','F3 - Covariance Matrices');
io.optSaveFig(residFig,'figures/fig3_stats','F4 - Residuals');
fprintf(1,'\n------------------------------------\n');