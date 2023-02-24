%RUN_STATS_PCA Run statistics for PCA model: Solenoid responses

% Load data table into workspace
clc;
clearvars -except T
if exist('T','var')==0
   T = getfield(load('Reduced-Table.mat','T'),'T');
end

% We want to:
%  1. Define response.
%  2. Relate response to lesion volume, area.
%  3. Describe response modulation when ICMS is applied.

%% 1. Define the response.
% Start: response is evoked activity **FROM SOLENOID**
% -> Create "SOLENOID" table with only SOLENOID or SOLENOID+ICMS trials.
% --> (Table is `S`)
if exist('run_stats_pca_S.mat', 'file')==0
    [coeff,score,explained,S,Y,t] = tbl.getConditionPCs(T);
    figExplained = analyze.factors.pcs_explained(explained);
    [figScores,ica_mdl,z] = analyze.factors.pcs_ics(t,coeff,Y);
    % S = analyze.factors.label_ics(S,z);
    [S, icaFig] = analyze.factors.label_ics(S,z,t,ica_mdl.TransformWeights);
    icFig2 = figure('Name', 'IC Weights for all Channels', 'Color', 'w'); 
    plot(z);
    xlabel('Channel');
    ylabel('Weight');
    S.Properties.VariableNames{27} = 'ICA_Noise';
    S.Properties.VariableNames{28} = 'ICA_Early';
    S.Properties.VariableNames{29} = 'ICA_Late';
    save('run_stats_pca_S.mat', 'S', 'ica_mdl', 'z', 'coeff', 'score', 'explained', 'Y', 't', '-v7.3');
else
    load('run_stats_pca_S.mat', 'S', 'ica_mdl', 'z', 'coeff', 'score', 'explained', 'Y', 't');
end

io.optSaveFig(figExplained,'figures/pca_stats','Solenoid PCA - Percent Explained');
io.optSaveFig(figScores,'figures/pca_stats','Solenoid PCs and ICs');
io.optSaveFig(icaFig,'figures/pca_stats','Solenoid ICs');
io.optSaveFig(icFig2,'figures/pca_stats','IC Weights for all Channels');

%% 2. Define GLME for lesion volume related to response
mdl = struct;
mdl.volume.late = fitglme(S,'ICA_Late~Lesion_Volume*Area+(ICA_Noise|AnimalID)','DummyVarCoding','effects');
mdl.volume.early = fitglme(S,'ICA_Early~Lesion_Volume*Area+(ICA_Noise|AnimalID)','DummyVarCoding','effects');

%% 3. Describe response modulation by Area and Type
mdl.area.late = fitglme(S, 'ICA_Late~Area*Type+(ICA_Noise|AnimalID)','DummyVarCoding','effects');
mdl.area.early = fitglme(S, 'ICA_Early~Area*Type+(ICA_Noise|AnimalID)','DummyVarCoding','effects');

%% 4. Describe response modulation when ICMS is applied
mdl.icms.late = fitglme(S,'ICA_Late~Area*Type*Lesion_Volume+(ICA_Noise|AnimalID)',...
   'DummyVarCoding','effects');
mdl.icms.early = fitglme(S,'ICA_Early~Area*Type*Lesion_Volume+(ICA_Noise|AnimalID)',...
   'DummyVarCoding','effects');

%% 5. Describe response modulation in only S1
mdl.S1.late = fitglme(S,'ICA_Late~Type*Lamina*Lesion_Volume-Type:Lamina:Lesion_Volume+(ICA_Noise|AnimalID)',...
   'DummyVarCoding','effects',...
   'Exclude',S.Area=="RFA");
mdl.S1.early = fitglme(S,'ICA_Early~Type*Lamina*Lesion_Volume-Type:Lamina:Lesion_Volume+(ICA_Noise|AnimalID)',...
   'DummyVarCoding','effects',...
   'Exclude',S.Area=="RFA");

%% 6. Export any associated figures
[covFig,residFig] = utils.showModelInfo(mdl.volume.early,'VOLUME - EARLY');
io.optSaveFig(covFig,'figures/pca_stats/models','VOLUME - EARLY - Covariance Matrices');
io.optSaveFig(residFig,'figures/pca_stats/models','VOLUME - EARLY - Residuals');

[covFig,residFig] = utils.showModelInfo(mdl.volume.late,'VOLUME - LATE');
io.optSaveFig(covFig,'figures/pca_stats/models','VOLUME - LATE - Covariance Matrices');
io.optSaveFig(residFig,'figures/pca_stats/models','VOLUME - LATE - Residuals');

[covFig,residFig] = utils.showModelInfo(mdl.icms.early,'ICMS - EARLY');
io.optSaveFig(covFig,'figures/pca_stats/models','ICMS - EARLY - Covariance Matrices');
io.optSaveFig(residFig,'figures/pca_stats/models','ICMS - EARLY - Residuals');

[covFig,residFig] = utils.showModelInfo(mdl.icms.late,'ICMS - LATE');
io.optSaveFig(covFig,'figures/pca_stats/models','ICMS - LATE - Covariance Matrices');
io.optSaveFig(residFig,'figures/pca_stats/models','ICMS - LATE - Residuals');

[covFig, residFig] = utils.showModelInfo(mdl.area.early,'AREA - EARLY');
io.optSaveFig(covFig,'figures/pca_stats/models','AREA - EARLY - Covariance Matrices');
io.optSaveFig(residFig,'figures/pca_stats/models','AREA - EARLY - Residuals');

[covFig, residFig] = utils.showModelInfo(mdl.area.late,'AREA - LATE');
io.optSaveFig(covFig,'figures/pca_stats/models','AREA - LATE - Covariance Matrices');
io.optSaveFig(residFig,'figures/pca_stats/models','AREA - LATE - Residuals');

[covFig,residFig] = utils.showModelInfo(mdl.S1.early,'S1 - EARLY');
io.optSaveFig(covFig,'figures/pca_stats/models','S1 - EARLY - Covariance Matrices');
io.optSaveFig(residFig,'figures/pca_stats/models','S1 - EARLY - Residuals');

[covFig,residFig] = utils.showModelInfo(mdl.S1.late,'S1 - LATE');
io.optSaveFig(covFig,'figures/pca_stats/models','S1 - LATE - Covariance Matrices');
io.optSaveFig(residFig,'figures/pca_stats/models','S1 - LATE - Residuals');