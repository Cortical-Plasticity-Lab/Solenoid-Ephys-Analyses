%RUN_STATS Run statistical analyses for Frontiers paper

clc; close all force;
clearvars -except C

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
mdlspec_str = "%s ~ 1 + Area*Lesion_Volume*Type + (1|BlockID)";
glme_mdl_args = {...
   'Distribution','binomial',...
   'Link','logit',...
   'DummyVarCoding','effects'};

% COMPUTE SOLENOID RESPONSES FIRST:
[C.NPeak_Solenoid_Early,C.BinomialSize] = tbl.countWindowedResponses(...
   C.ampTime - C.Solenoid_Onset__Exp,...  % Relative times (seconds)
   W_EARLY_SOL(1),W_EARLY_SOL(2));                % Window (seconds)
C.NPeak_Solenoid_Late = tbl.countWindowedResponses(...
   C.ampTime - C.Solenoid_Onset__Exp,...  % Relative times (seconds)
   W_LATE_SOL(1),W_LATE_SOL(2));                  % Window (seconds)
C.NPeak_Solenoid_Any = tbl.countWindowedResponses(...
   C.ampTime - C.Solenoid_Onset__Exp,...  % Relative times (seconds)
   W_ANY(1),W_ANY(2));                    % Window (seconds)

% COMPUTE ICMS RESPONSES SECOND:
C.NPeak_ICMS_Early = tbl.countWindowedResponses(...
   C.ampTime - C.ICMS_Onset__Exp,...   % Relative times (seconds)
   W_EARLY_ICMS(1),W_EARLY_ICMS(2));             % Window (seconds)
C.NPeak_ICMS_Late = tbl.countWindowedResponses(...
   C.ampTime - C.ICMS_Onset__Exp,...   % Relative times (seconds)
   W_LATE_ICMS(1),W_LATE_ICMS(2));               % Window (seconds)
C.NPeak_ICMS_Any = tbl.countWindowedResponses(...
   C.ampTime - C.ICMS_Onset__Exp,...   % Relative times (seconds)
   W_ANY(1),W_ANY(2));                 % Window (seconds)

% EVALUATE STATISTICAL MODELS:
% Initialize struct to organize GLME model objects
mdl = struct('Solenoid',...
               struct('Early',[],'Late',[],'Any',[]),...
             'ICMS',...
               struct('Early',[],'Late',[],'Any',[]));
          
% mdlspec_str allows us to just insert the name of the response variable.
% glme_mdl_args are "generic" model arguments that will always be the same.

% In ALL cases, exclude channels from Layer II/III (too few cases: 192 of
% 5373 observations).
exc = C.Lamina~="Layer V";
Cs = C;
Cs.Type = string(Cs.Type);
Cs.Properties.UserData.NumExcluded = struct;
Cs.Properties.UserData.NumExcluded.Lamina = sum(exc);
Cs(exc,:) = [];

% SOLENOID: Exclude ICMS trials (there will be no "solenoid" peak)
Csol = Cs(Cs.Type~="ICMS",:);
exc = tbl.requireAnyResponse(Csol.NPeak_Solenoid_Early + Csol.NPeak_Solenoid_Late,strcat(Csol.ElectrodeID,'::',num2str(Csol.BlockIndex)),string(Csol.Type));

% Run model for SOLENOID + EARLY
tic; 
fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
   sprintf(mdlspec_str,"NPeak_Solenoid_Early"));
fprintf(1,'Excluding <strong>%d</strong> observations.\n',sum(exc));
fprintf(1,'Fitting Binomial GLME for solenoid-early...');
mdl.Solenoid.Early = fitglme(Csol,sprintf(mdlspec_str,"NPeak_Solenoid_Early"),...
   glme_mdl_args{:},...
   'BinomialSize',Csol.BinomialSize,...
   'Exclude',exc,...
   'Offset',ones(size(Csol,1),1));
fprintf(1,'complete (%5.2f sec)\n',toc);
disp(mdl.Solenoid.Early);
disp('R-squared:');
disp(mdl.Solenoid.Early.Rsquared);
fprintf(1,'\n------------------------------------\n');

% Run model for SOLENOID + LATE
tic; 
fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
   sprintf(mdlspec_str,"NPeak_Solenoid_Late"));
fprintf(1,'Excluding <strong>%d</strong> observations.\n',sum(exc));
fprintf(1,'Fitting Binomial GLME for solenoid-late...');
mdl.Solenoid.Late = fitglme(Csol,sprintf(mdlspec_str,"NPeak_Solenoid_Late"),...
   glme_mdl_args{:},...
   'BinomialSize',Csol.BinomialSize,...
   'Exclude',exc,...
   'Offset',ones(size(Csol,1),1));
fprintf(1,'complete (%5.2f sec)\n',toc);
disp(mdl.Solenoid.Late);
disp('R-squared:');
disp(mdl.Solenoid.Late.Rsquared);
fprintf(1,'\n------------------------------------\n');

% Run model for SOLENOID + ANY
tic; 
fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
   sprintf(mdlspec_str,"NPeak_Solenoid_Any"));
fprintf(1,'Excluding <strong>%d</strong> observations.\n',sum(exc));
fprintf(1,'Fitting Binomial GLME for solenoid-any...');
mdl.Solenoid.Any = fitglme(Csol,sprintf(mdlspec_str,"NPeak_Solenoid_Any"),...
   glme_mdl_args{:},...
   'BinomialSize',Csol.BinomialSize,...
   'Exclude',exc,...
   'Offset',ones(size(Csol,1),1));
fprintf(1,'complete (%5.2f sec)\n',toc);
disp(mdl.Solenoid.Any);
disp('R-squared:');
disp(mdl.Solenoid.Any.Rsquared);
fprintf(1,'\n------------------------------------\n');

% ICMS: Exclude Solenoid trials (there will be no "ICMS" peak)
Cicms = Cs(Cs.Type~="Solenoid",:);
exc = tbl.requireAnyResponse(Cicms.NPeak_ICMS_Early + Cicms.NPeak_ICMS_Late,strcat(Cicms.ElectrodeID,'::',num2str(Cicms.BlockIndex)),string(Cicms.Type));

% Run model for ICMS + EARLY
tic; 
fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
   sprintf(mdlspec_str,"NPeak_ICMS_Early"));
fprintf(1,'Excluding <strong>%d</strong> observations.\n',sum(exc));
fprintf(1,'Fitting Binomial GLME for ICMS-early...');
mdl.ICMS.Early = fitglme(Cicms,sprintf(mdlspec_str,"NPeak_ICMS_Early"),...
   glme_mdl_args{:},...
   'BinomialSize',Cicms.BinomialSize,...
   'Exclude',exc,...
   'Offset',ones(size(Cicms,1),1));
fprintf(1,'complete (%5.2f sec)\n',toc);
disp(mdl.ICMS.Early);
disp('R-squared:');
disp(mdl.ICMS.Early.Rsquared);
fprintf(1,'\n------------------------------------\n');

% Run model for ICMS + LATE
tic; 
fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
   sprintf(mdlspec_str,"NPeak_ICMS_Late"));
fprintf(1,'Excluding <strong>%d</strong> observations.\n',sum(exc));
fprintf(1,'Fitting Binomial GLME for ICMS-late...');
mdl.ICMS.Late = fitglme(Cicms,sprintf(mdlspec_str,"NPeak_ICMS_Late"),...
   glme_mdl_args{:},...
   'BinomialSize',Cicms.BinomialSize,...
   'Exclude',exc,...
   'Offset',ones(size(Cicms,1),1));
fprintf(1,'complete (%5.2f sec)\n',toc);
disp(mdl.ICMS.Late);
disp('R-squared:');
disp(mdl.ICMS.Late.Rsquared);
fprintf(1,'\n------------------------------------\n');

% Run model for ICMS + ANY
tic; 
fprintf(1,'Wilkinson Formula: <strong>%s</strong>\n',...
   sprintf(mdlspec_str,"NPeak_ICMS_Any"));
fprintf(1,'Excluding <strong>%d</strong> observations.\n',sum(exc));
fprintf(1,'Fitting Binomial GLME for ICMS-any...');
mdl.ICMS.Any = fitglme(Cicms,sprintf(mdlspec_str,"NPeak_ICMS_Any"),...
   glme_mdl_args{:},...
   'BinomialSize',Cicms.BinomialSize,...
   'Exclude',exc,...
   'Offset',ones(size(Cicms,1),1));
fprintf(1,'complete (%5.2f sec)\n',toc);
disp(mdl.ICMS.Any);
disp('R-squared:');
disp(mdl.ICMS.Any.Rsquared);
fprintf(1,'\n------------------------------------\n');