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
mdlspec_str_main = "peakVal ~ 1 + Area*Type*Lesion_Volume + (1 + Depth + peakTime + peakRank|Area:Type) + (1 + peakTime + peakRank + ZDepth|AnimalID)";
mdlspec_str_sol = "peakVal ~ 1 + Area*Lesion_Volume*ZDepth + (1|Area:Type) + (1 + peakTime|AnimalID)";
mdlspec_str_icms = "peakVal ~ 1 + Area*Lesion_Volume*ZDepth + (1 + StimDepth|Area:Type) + (1 + peakTime|AnimalID)";
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

tic; fprintf(1,'Computing GLME for <strong>FULL MODEL</strong>...');
mdl.Full = fitglme(P,mdlspec_str_main,glme_mdl_args{:},...
   'Exclude',P.peakTime <= 0);
fprintf(1,'complete (%5.2f sec)\n',toc);
[covFig,residFig] = utils.showModelInfo(mdl.Full,'FULL MODEL');
io.optSaveFig(covFig,'figures/fig3_stats','B1 - Covariance Matrices');


% fprintf(1,'\n\n-------------------------------------------------\n\n');
%
% tic; fprintf(1,'Computing GLME for <strong>SOLENOID</strong>...');
% pSol = P(string(P.Type)~="ICMS",:);
% pSol.peakTime = pSol.peakTime - pSol.Solenoid_Onset__Exp;
% mdl.Solenoid = fitglme(pSol,mdlspec_str_sol,glme_mdl_args{:},...
%    'Exclude',pSol.peakTime <= 0);
% fprintf(1,'complete (%5.2f sec)\n',toc);
% disp(mdl.Solenoid);
% fprintf(1,'<strong>R-squared:</strong>\n');
% disp(mdl.Solenoid.Rsquared);
% 
% fprintf(1,'\n\n-------------------------------------------------\n\n');
% 
% tic; fprintf(1,'Computing GLME for <strong>ICMS</strong>...');
% pICMS = P(string(P.Type)~="Solenoid",:);
% pICMS.peakTime = pICMS.peakTime - pICMS.ICMS_Onset__Exp;
% mdl.ICMS = fitglme(pICMS,mdlspec_str_icms,glme_mdl_args{:},...
%    'Exclude',pICMS.peakTime <= 0);
% fprintf(1,'complete (%5.2f sec)\n',toc);
% disp(mdl.ICMS);
% fprintf(1,'<strong>R-squared:</strong>\n');
% disp(mdl.ICMS.Rsquared);


warning('on','stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadDistLinkCombination1');

% % % % % % % % % % Probably deprecated: % % % % % % % % % % % %
% % COMPUTE SOLENOID RESPONSES FIRST:
% C.NPeak_Solenoid_Early = tbl.countWindowedResponses(...
%    C.peakTime - C.Solenoid_Onset__Exp,...  % Relative times (seconds)
%    W_EARLY_SOL(1),W_EARLY_SOL(2));                % Window (seconds)
% C.NPeak_Solenoid_Late = tbl.countWindowedResponses(...
%    C.peakTime - C.Solenoid_Onset__Exp,...  % Relative times (seconds)
%    W_LATE_SOL(1),W_LATE_SOL(2));                  % Window (seconds)
% C.NPeak_Solenoid_Any = tbl.countWindowedResponses(...
%    C.peakTime - C.Solenoid_Onset__Exp,...  % Relative times (seconds)
%    W_ANY(1),W_ANY(2));                    % Window (seconds)
% 
% % COMPUTE ICMS RESPONSES SECOND:
% C.NPeak_ICMS_Early = tbl.countWindowedResponses(...
%    C.peakTime - C.ICMS_Onset__Exp,...   % Relative times (seconds)
%    W_EARLY_ICMS(1),W_EARLY_ICMS(2));             % Window (seconds)
% C.NPeak_ICMS_Late = tbl.countWindowedResponses(...
%    C.peakTime - C.ICMS_Onset__Exp,...   % Relative times (seconds)
%    W_LATE_ICMS(1),W_LATE_ICMS(2));               % Window (seconds)
% C.NPeak_ICMS_Any = tbl.countWindowedResponses(...
%    C.peakTime - C.ICMS_Onset__Exp,...   % Relative times (seconds)
%    W_ANY(1),W_ANY(2));                 % Window (seconds)
% 
% % EVALUATE STATISTICAL MODELS:
% % Initialize struct to organize GLME model objects
% mdl = struct('Solenoid',...
%                struct('Early',[],'Late',[],'Any',[]),...
%              'ICMS',...
%                struct('Early',[],'Late',[],'Any',[]));
%           
% mdlspec_str allows us to just insert the name of the response variable.
% glme_mdl_args are "generic" model arguments that will always be the same.
% 
% 
% 
% 
% % exc = C.Lamina~="Layer V";
% Cs = C;
% Cs.Type = string(Cs.Type);
% Cs.Properties.UserData.NumExcluded = struct;
% % Cs.Properties.UserData.NumExcluded.Lamina = sum(exc);
% % Cs(exc,:) = [];
% 
% % SOLENOID: Exclude ICMS trials (there will be no "solenoid" peak)
% Csol = Cs(Cs.Type~="ICMS",:);
% id = strcat(Csol.ElectrodeID,'::',num2str(Csol.BlockIndex));
% exc = tbl.requireAnyResponse(Csol.NPeak_Solenoid_Early + Csol.NPeak_Solenoid_Late,id,string(Csol.Type));
% Csol(exc,:) = [];
% id(exc) = [];
% Csol.BinomialSize = tbl.findMaxResponse(Csol.NPeak_Solenoid_Any,id,string(Csol.Type));
% Csol.Properties.RowNames = strcat(Csol.Properties.RowNames,"-N:",num2str(Csol.BinomialSize));
% Dsol = tbl.findResponseDiff(Csol);
% 
% % Run model for SOLENOID + EARLY
% tic; 
% 
% fprintf(1,'\n\n\t\t<strong>WITHOUT EXCLUSIONS</strong>\n\n');
% 
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'\n\t<strong>EARLY SOLENOID</strong> (%d <= t < %d ms)\n',...
%    W_EARLY_SOL*1e3);
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
%    sprintf(mdlspec_str_sol,"NPeak_Solenoid_Early_combo","NPeak_Solenoid_Early"));
% fprintf(1,'Excluding <strong>%d</strong> observations.\n',sum(exc));
% fprintf(1,'Fitting Binomial GLME for solenoid-early...');
% mdl.Solenoid.Early = fitglme(Dsol,sprintf(mdlspec_str_sol,"NPeak_Solenoid_Early_combo","NPeak_Solenoid_Early"),...
%    glme_mdl_args{:},...
%    'BinomialSize',Dsol.BinomialSize,...
%    'Offset',ones(size(Dsol,1),1));
% fprintf(1,'complete (%5.2f sec)\n',toc);
% disp(mdl.Solenoid.Early);
% disp('R-squared:');
% disp(mdl.Solenoid.Early.Rsquared);
% 
% % Run model for SOLENOID + LATE
% tic; 
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'\n\t<strong>LATE SOLENOID</strong> (%d <= t < %d ms)\n',...
%    W_LATE_SOL*1e3);
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
%    sprintf(mdlspec_str_sol,"NPeak_Solenoid_Late_combo","NPeak_Solenoid_Late"));
% fprintf(1,'Excluding <strong>%d</strong> observations.\n',sum(exc));
% fprintf(1,'Fitting Binomial GLME for solenoid-late...');
% mdl.Solenoid.Late = fitglme(Dsol,sprintf(mdlspec_str_sol,"NPeak_Solenoid_Late_combo","NPeak_Solenoid_Late"),...
%    glme_mdl_args{:},...
%    'BinomialSize',Dsol.BinomialSize,...
%    'Offset',ones(size(Dsol,1),1));
% fprintf(1,'complete (%5.2f sec)\n',toc);
% disp(mdl.Solenoid.Late);
% disp('R-squared:');
% disp(mdl.Solenoid.Late.Rsquared);
% fprintf(1,'\n------------------------------------\n');
% 
% % ICMS: Exclude Solenoid trials (there will be no "ICMS" peak)
% Cicms = Cs(Cs.Type~="Solenoid",:);
% id = strcat(Cicms.ElectrodeID,'::',num2str(Cicms.BlockIndex));
% exc = tbl.requireAnyResponse(Cicms.NPeak_ICMS_Early + Cicms.NPeak_ICMS_Late,id,string(Cicms.Type));
% Cicms(exc,:) = [];
% id(exc) = [];
% Cicms.BinomialSize = tbl.findMaxResponse(Cicms.NPeak_ICMS_Any,id,string(Cicms.Type));
% Dicms = tbl.findResponseDiff(Cicms);
% 
% % Run model for ICMS + EARLY
% tic; 
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'\n\t<strong>EARLY ICMS</strong> (%d <= t < %d ms)\n',...
%    W_EARLY_ICMS*1e3);
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
%    sprintf(mdlspec_str_icms,"NPeak_ICMS_Early_combo","NPeak_ICMS_Early"));
% fprintf(1,'Excluding <strong>%d</strong> observations.\n',sum(exc));
% fprintf(1,'Fitting Binomial GLME for ICMS-early...');
% mdl.ICMS.Early = fitglme(Dicms,sprintf(mdlspec_str_icms,"NPeak_ICMS_Early_combo","NPeak_ICMS_Early"),...
%    glme_mdl_args{:},...
%    'BinomialSize',Dicms.BinomialSize,...
%    'Offset',ones(size(Dicms,1),1));
% fprintf(1,'complete (%5.2f sec)\n',toc);
% disp(mdl.ICMS.Early);
% disp('R-squared:');
% disp(mdl.ICMS.Early.Rsquared);
% 
% % Run model for ICMS + LATE
% tic; 
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'\n\t<strong>LATE ICMS</strong> (%d <= t < %d ms)\n',...
%    W_LATE_ICMS*1e3);
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
%    sprintf(mdlspec_str_icms,"NPeak_ICMS_Late_combo","NPeak_ICMS_Late"));
% fprintf(1,'Excluding <strong>%d</strong> observations.\n',sum(exc));
% fprintf(1,'Fitting Binomial GLME for ICMS-late...');
% mdl.ICMS.Late = fitglme(Dicms,sprintf(mdlspec_str_icms,"NPeak_ICMS_Late_combo","NPeak_ICMS_Late"),...
%    glme_mdl_args{:},...
%    'BinomialSize',Dicms.BinomialSize,...
%    'Offset',ones(size(Dicms,1),1));
% fprintf(1,'complete (%5.2f sec)\n',toc);
% disp(mdl.ICMS.Late);
% disp('R-squared:');
% disp(mdl.ICMS.Late.Rsquared);
% fprintf(1,'\n------------------------------------\n');
% 
% % Debug
% % figure; scatter(mdl.Solenoid.Early.Variables.NPeak_Solenoid_Early+randn(size(Csol,1),1).*0.15,mdl.Solenoid.Early.Variables.BinomialSize+randn(size(Csol,1),1).*0.15,'MarkerFaceColor','b','MarkerEdgeColor','k','MarkerEdgeAlpha',0.05,'SizeData',8,'MarkerFaceAlpha',0.1);
% % xlabel('N Early Peaks (Solenoid)'); ylabel('BinomialSize');
% % set(gcf,'Color','w'); set(gca,'YDir','reverse');
% 
% % % RERUN MODELS USING EXCLUSIONS FOR OBSERVATIONS WITH ZERO-PEAK % % 
% fprintf(1,'\n\n\t\t<strong>WITH EXCLUSIONS</strong>\n\n');
% 
% % Run model for SOLENOID + EARLY
% tic; 
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'\n\t<strong>EARLY SOLENOID (+ Exclude)</strong> (%d <= t < %d ms)\n',...
%    W_EARLY_SOL*1e3);
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
%    sprintf(mdlspec_str_sol,"NPeak_Solenoid_Early_combo","NPeak_Solenoid_Early"));
% fprintf(1,'Excluding an additional <strong>%d</strong> observations.\n',sum(Dsol.NPeak_Solenoid_Early==0));
% fprintf(1,'Fitting Binomial GLME for solenoid-early...');
% mdl.Solenoid.Early_Exclude = fitglme(Dsol,sprintf(mdlspec_str_sol,"NPeak_Solenoid_Early_combo","NPeak_Solenoid_Early"),...
%    glme_mdl_args{:},...
%    'BinomialSize',Dsol.BinomialSize,...
%    'Exclude',Dsol.NPeak_Solenoid_Early==0);
% fprintf(1,'complete (%5.2f sec)\n',toc);
% disp(mdl.Solenoid.Early_Exclude);
% disp('R-squared:');
% disp(mdl.Solenoid.Early_Exclude.Rsquared);
% 
% % Run model for SOLENOID + LATE
% tic; 
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'\n\t<strong>LATE SOLENOID (+ Exclude)</strong> (%d <= t < %d ms)\n',...
%    W_LATE_SOL*1e3);
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
%    sprintf(mdlspec_str_sol,"NPeak_Solenoid_Late_combo","NPeak_Solenoid_Late"));
% fprintf(1,'Excluding an additional <strong>%d</strong> observations.\n',sum(Dsol.NPeak_Solenoid_Late==0));
% fprintf(1,'Fitting Binomial GLME for solenoid-late...');
% mdl.Solenoid.Late_Exclude = fitglme(Dsol,sprintf(mdlspec_str_sol,"NPeak_Solenoid_Late_combo","NPeak_Solenoid_Late"),...
%    glme_mdl_args{:},...
%    'BinomialSize',Dsol.BinomialSize,...
%    'Exclude',Dsol.NPeak_Solenoid_Late==0);
% fprintf(1,'complete (%5.2f sec)\n',toc);
% disp(mdl.Solenoid.Late_Exclude);
% disp('R-squared:');
% disp(mdl.Solenoid.Late_Exclude.Rsquared);
% fprintf(1,'\n------------------------------------\n');
% 
% % ICMS: Exclude Solenoid trials (there will be no "ICMS" peak)
% % Run model for ICMS + EARLY AFTER EXCLUSIONS
% tic; 
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'\n\t<strong>EARLY ICMS (+ Exclude)</strong> (%d <= t < %d ms)\n',...
%    W_EARLY_ICMS*1e3);
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
%    sprintf(mdlspec_str_icms,"NPeak_ICMS_Early_combo","NPeak_ICMS_Early"));
% fprintf(1,'Excluding an additional <strong>%d</strong> observations.\n',sum(Dicms.NPeak_ICMS_Early==0));
% fprintf(1,'Fitting Binomial GLME for ICMS-early...');
% mdl.ICMS.Early_Exclude = fitglme(Dicms,sprintf(mdlspec_str_icms,"NPeak_ICMS_Early_combo","NPeak_ICMS_Early"),...
%    glme_mdl_args{:},...
%    'BinomialSize',Dicms.BinomialSize,...
%    'Exclude',Dicms.NPeak_ICMS_Early==0);
% fprintf(1,'complete (%5.2f sec)\n',toc);
% disp(mdl.ICMS.Early_Exclude);
% disp('R-squared:');
% disp(mdl.ICMS.Early_Exclude.Rsquared);
% 
% % Run model for ICMS + LATE
% tic; 
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'\n\t<strong>LATE ICMS (+ Exclude)</strong> (%d <= t < %d ms)\n',...
%    W_LATE_ICMS*1e3);
% fprintf(1,'\n------------------------------------\n');
% fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
%    sprintf(mdlspec_str_icms,"NPeak_ICMS_Late_combo","NPeak_ICMS_Late"));
% fprintf(1,'Excluding an additional <strong>%d</strong> observations.\n',sum(Dicms.NPeak_ICMS_Late==0));
% fprintf(1,'Fitting Binomial GLME for ICMS-late...');
% mdl.ICMS.Late_Exclude = fitglme(Dicms,sprintf(mdlspec_str_icms,"NPeak_ICMS_Late_combo","NPeak_ICMS_Late"),...
%    glme_mdl_args{:},...
%    'BinomialSize',Dicms.BinomialSize,...
%    'Exclude',Dicms.NPeak_ICMS_Late==0);
% fprintf(1,'complete (%5.2f sec)\n',toc);
% disp(mdl.ICMS.Late_Exclude);
% disp('R-squared:');
% disp(mdl.ICMS.Late_Exclude.Rsquared);
% fprintf(1,'\n------------------------------------\n');
% % % % % % % % % End Deprecated % % % % % %% % % % % % % %