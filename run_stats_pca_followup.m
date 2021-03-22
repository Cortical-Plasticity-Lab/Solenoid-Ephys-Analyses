%RUN_STATS_PCA_FOLLOWUP Additional analyses after discussion with Page
close all force;
clearvars -except T;
clc;

if exist('T','var')==0
   T = getfield(load('Reduced-Table.mat','T'),'T');
end

% We want to make graphics to illustrate statistical model findings.
%  1. Get Top-3 Principal Components for specific combinations.
%  2. Make bar plots for means of ICA_Early by Area & Type

%% 1. Get PCs/ICs by condition
% Start: response is evoked activity **FROM SOLENOID**
% -> Create "SOLENOID" table with only SOLENOID or SOLENOID+ICMS trials.

Type = string(unique(T.Type));
Area = string(unique(T.Area));
Component = ["ICA_Noise","ICA_Late","ICA_Early"];
nType = numel(Type);
nArea = numel(Area);

coeff = cell(nType,1);
score = cell(nType,1);
explained = cell(nType,1);
S = cell(nType,1);
rate = cell(nType,1);
for iT = 1:nType
   C = utils.getSelector('Type',Type(iT));
   [coeff{iT},score{iT},explained{iT},S{iT},rate{iT},t] = tbl.getConditionPCs(T,C);
end

%% 2. Plot PCs/ICs by condition
% Plot PCs & ICs
ica_mdl = cell(nType,1);
z = cell(nType,1);
R = cell(nType,1);
for ii = 1:nType
   [fig,ica_mdl{ii},z{ii},R{ii}] = ...
      analyze.factors.pcs_ics(t,coeff{ii},rate{ii},Type(ii));
   io.optSaveFig(fig,'figures/pca_stats/conditions',...
      sprintf('%s PCs and ICs',Type(ii)));
end

%% 3. Plot PCs/ICs -- %-explained
% Plot % explained by PC
for ii = 1:nType
   fig = analyze.factors.pcs_explained(explained{ii},Type(ii),R{ii});
   io.optSaveFig(fig,'figures/pca_stats/conditions',...
      sprintf('%s PCA - Percent Explained',Type(ii)));
end

%% 4. Plot means by area/condition
[coeff,score,explained,S,Y,t] = tbl.getConditionPCs(T);
[ica_mdl,z] = analyze.factors.getICs(Y,coeff);
S = analyze.factors.label_ics(S,z);
Stats = [];
for iC = 1:numel(Component)
   component = Component(iC);
   for ii = 1:nType
      type = Type(ii);
      for iA = 1:nArea
         area = Area(iA);
         C = utils.getSelector('Type',Type(ii),'Area',Area(iA));
         iRow = utils.selector2mask(C,S);
         x = S.(component);
         Mean = nanmean(x(iRow));
         SEM = nanstd(x(iRow))./sqrt(sum(iRow));
         N = sum(iRow);
         Stats = [Stats; table(component,type,area,Mean,SEM,N)]; %#ok<AGROW>
      end
   end
end
st = Stats(Stats.component=="ICA_Early",:);
y = reshape(st.Mean,2,3);
s = reshape(st.SEM,2,3);
fig = figure('Name','ICA Means by Group','Color','w');
b = bar(y');
set(b,'EdgeColor','none');
set(b(1),'DisplayName',Area(1));
set(b(2),'DisplayName',Area(2));
set(gca,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5);
x = [b(1).XEndPoints; b(2).XEndPoints];
l = errorbar(gca, ...
   x', y', s',...
   'LineStyle','none',...
   'LineWidth',1.5, 'Color', 'k');
set(l(1),'DisplayName','\pmSEM');
l(2).Annotation.LegendInformation.IconDisplayStyle = 'off';
title(gca, 'ICA Means by Group','Color','k','FontName','Arial');
ylabel(gca,'E[Weight]','Color','k','FontName','Arial');
set(gca,'XTickLabels',Type);
legend(gca,'Location','Northwest');
io.optSaveFig(fig,'figures/pca_stats/conditions','ICA - Early - Group Means');