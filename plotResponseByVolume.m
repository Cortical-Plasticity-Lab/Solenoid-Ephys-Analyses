function fig = plotResponseByVolume(volumeModel)
%PLOTRESPONSEBYVOLUME  Plots predicted values and CI by volume, using fitted GLMEs
%
% Syntax:
%   fig = plotResponseByVolume(volumeModel);
%
% Inputs:
%   volumeModel - `mdl.volume` (struct with fields 'early' and 'late',
%                   which are each `GeneralizedLinearMixedModel` values)
%
% Output:
%   fig - Figure handle
%
% See also: Contents, run_stats_pca

color = struct('S1', validatecolor("#e7a4dc"), 'RFA', validatecolor("#87e1e1"));


fig = figure('Name', "EARLY IC by VOLUME", 'Color', 'w', ...
    'Position', [206   229   901   420]);
L = tiledlayout(fig, 1, 2);
ax = nexttile(L);
set(ax, 'NextPlot', 'add', 'FontName', 'Tahoma', 'XColor', 'k', 'YColor', 'k');

[ypred, ypredCI] = predict(volumeModel.early);
S = volumeModel.early.Variables;
iRFA = strcmpi(S.Area, "RFA");
iS1 = strcmpi(S.Area, "S1");
scatter(ax, S.Lesion_Volume(iRFA), S.ICA_Early(iRFA), 'filled', ...
    'Color', color.RFA, 'MarkerEdgeColor', color.RFA, 'MarkerFaceColor', color.RFA, ...
    'MarkerFaceAlpha', 0.15, 'MarkerEdgeAlpha', 0.25, 'XJitter', 'density', 'DisplayName', 'RFA');
scatter(ax, S.Lesion_Volume(iS1), S.ICA_Early(iS1), 'filled', ...
    'Color', color.S1, 'MarkerEdgeColor', color.S1, 'MarkerFaceColor', color.S1, ...
    'MarkerFaceAlpha', 0.15, 'MarkerEdgeAlpha', 0.25, 'XJitter', 'density',  'DisplayName', 'S1');
errorbar(S.Lesion_Volume(iRFA), ypred(iRFA), ypredCI(iRFA,1), ypredCI(iRFA,2),...
    'DisplayName', 'RFA + 95% CI', 'Color', color.RFA);
errorbar(S.Lesion_Volume(iS1), ypred(iS1), ypredCI(iS1,1), ypredCI(iS1,2),...
    'DisplayName', 'S1 + 95% CI', 'Color', color.S1);

xlabel(ax, sprintf('Lesion Volume (%s)', S.Properties.VariableUnits{strcmpi(S.Properties.VariableNames, 'Lesion_Volume')}), ...
    'FontName', 'Tahoma');
ylabel(ax, 'Score', 'FontName', 'Tahoma');
title(ax, 'Early IC', 'FontName', 'Tahoma');

ax = nexttile(L);
set(ax, 'NextPlot', 'add', 'FontName', 'Tahoma', 'XColor', 'k', 'YColor', 'k');
[ypred, ypredCI] = predict(volumeModel.late);
S = volumeModel.late.Variables;
iRFA = strcmpi(S.Area, "RFA");
iS1 = strcmpi(S.Area, "S1");
scatter(ax, S.Lesion_Volume(iRFA), S.ICA_Late(iRFA), 'filled', ...
    'Color', color.RFA, 'MarkerEdgeColor', color.RFA, 'MarkerFaceColor', color.RFA, ...
    'MarkerFaceAlpha', 0.15, 'MarkerEdgeAlpha', 0.25, 'XJitter', 'density', 'DisplayName', 'RFA');
scatter(ax, S.Lesion_Volume(iS1), S.ICA_Late(iS1), 'filled', ...
    'Color', color.S1, 'MarkerEdgeColor', color.S1, 'MarkerFaceColor', color.S1, ...
    'MarkerFaceAlpha', 0.15, 'MarkerEdgeAlpha', 0.25, 'XJitter', 'density',  'DisplayName', 'S1');
errorbar(S.Lesion_Volume(iRFA), ypred(iRFA), ypredCI(iRFA,1), ypredCI(iRFA,2),...
    'DisplayName', 'RFA + 95% CI', 'Color', color.RFA);
errorbar(S.Lesion_Volume(iS1), ypred(iS1), ypredCI(iS1,1), ypredCI(iS1,2),...
    'DisplayName', 'S1 + 95% CI', 'Color', color.S1);

xlabel(ax, sprintf('Lesion Volume (%s)', S.Properties.VariableUnits{strcmpi(S.Properties.VariableNames, 'Lesion_Volume')}), ...
    'FontName', 'Tahoma');
ylabel(ax, 'Score', 'FontName', 'Tahoma');
title(ax, 'Late IC', 'FontName', 'Tahoma');

title(L, 'GLME: Predicted + 95% CI', 'FontName', 'Tahoma');
subtitle(L, '(ICs by Lesion Volume)', 'FontName', 'Tahoma');


end