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


fig(1) = figure('Name', "IC by VOLUME - FULL", 'Color', 'w', ...
    'Position', [206   229   901   420]);
L = tiledlayout(fig(1), 1, 2);
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
legend(ax, 'Location', 'Best');

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
legend(ax, 'Location', 'Best');

xlabel(ax, sprintf('Lesion Volume (%s)', S.Properties.VariableUnits{strcmpi(S.Properties.VariableNames, 'Lesion_Volume')}), ...
    'FontName', 'Tahoma');
ylabel(ax, 'Score', 'FontName', 'Tahoma');
title(ax, 'Late IC', 'FontName', 'Tahoma');

title(L, 'GLME: Predicted + 95% CI', 'FontName', 'Tahoma');
subtitle(L, '(ICs by Lesion Volume)', 'FontName', 'Tahoma');


fig(2) = figure('Name', "IC by VOLUME - MEANS", 'Color', 'w', ...
    'Position', [770   504   901   420]);
L = tiledlayout(fig(2), 1, 2);
ax = nexttile(L);
set(ax, 'NextPlot', 'add', 'FontName', 'Tahoma', 'XColor', 'k', 'YColor', 'k');

[ypred, ypredCI] = predict(volumeModel.early);
S = volumeModel.early.Variables;
[G, S_marg] = findgroups(S(:, {'Area', 'Lesion_Volume'}));
S_marg.ICA_Early = splitapply(@mean, S.ICA_Early, G);
iRFA = strcmpi(S_marg.Area, "RFA");
iS1 = strcmpi(S_marg.Area, "S1");
scatter(ax, S_marg.Lesion_Volume(iRFA), S_marg.ICA_Early(iRFA), 'filled', ...
    'Color', color.RFA, 'MarkerEdgeColor', color.RFA, 'MarkerFaceColor', color.RFA, ...
    'DisplayName', 'RFA');
scatter(ax, S_marg.Lesion_Volume(iS1), S_marg.ICA_Early(iS1), 'filled', ...
    'Color', color.S1, 'MarkerEdgeColor', color.S1, 'MarkerFaceColor', color.S1, ...
    'DisplayName', 'S1');
errorbar(S_marg.Lesion_Volume(iRFA), ypred(iRFA), ypredCI(iRFA,1), ypredCI(iRFA,2),...
    'DisplayName', 'RFA + 95% CI', 'Color', color.RFA, 'LineWidth', 2);
errorbar(S_marg.Lesion_Volume(iS1), ypred(iS1), ypredCI(iS1,1), ypredCI(iS1,2),...
    'DisplayName', 'S1 + 95% CI', 'Color', color.S1, 'LineWidth', 2);
legend(ax, 'Location', 'Best');
xlabel(ax, sprintf('Lesion Volume (%s)', S.Properties.VariableUnits{strcmpi(S.Properties.VariableNames, 'Lesion_Volume')}), ...
    'FontName', 'Tahoma');
ylabel(ax, 'Score', 'FontName', 'Tahoma');
title(ax, 'Early IC', 'FontName', 'Tahoma');

ax = nexttile(L);
set(ax, 'NextPlot', 'add', 'FontName', 'Tahoma', 'XColor', 'k', 'YColor', 'k');
[ypred, ypredCI] = predict(volumeModel.late);
S = volumeModel.late.Variables;
[G, S_marg] = findgroups(S(:, {'Area', 'Lesion_Volume'}));
S_marg.ICA_Late = splitapply(@mean, S.ICA_Late, G);
iRFA = strcmpi(S_marg.Area, "RFA");
iS1 = strcmpi(S_marg.Area, "S1");
scatter(ax, S_marg.Lesion_Volume(iRFA), S_marg.ICA_Late(iRFA), 'filled', ...
    'Color', color.RFA, 'MarkerEdgeColor', color.RFA, 'MarkerFaceColor', color.RFA, ...
    'DisplayName', 'RFA');
scatter(ax, S_marg.Lesion_Volume(iS1), S_marg.ICA_Late(iS1), 'filled', ...
    'Color', color.S1, 'MarkerEdgeColor', color.S1, 'MarkerFaceColor', color.S1, ...
    'DisplayName', 'S1');
errorbar(S_marg.Lesion_Volume(iRFA), ypred(iRFA), ypredCI(iRFA,1), ypredCI(iRFA,2),...
    'DisplayName', 'RFA + 95% CI', 'Color', color.RFA, 'LineWidth', 2);
errorbar(S_marg.Lesion_Volume(iS1), ypred(iS1), ypredCI(iS1,1), ypredCI(iS1,2),...
    'DisplayName', 'S1 + 95% CI', 'Color', color.S1, 'LineWidth', 2);
legend(ax, 'Location', 'Best');
xlabel(ax, sprintf('Lesion Volume (%s)', S.Properties.VariableUnits{strcmpi(S.Properties.VariableNames, 'Lesion_Volume')}), ...
    'FontName', 'Tahoma');
ylabel(ax, 'Score', 'FontName', 'Tahoma');
title(ax, 'Late IC', 'FontName', 'Tahoma');

title(L, 'GLME: Marginal Predictions + 95% CI', 'FontName', 'Tahoma');
subtitle(L, '(ICs by Lesion Volume)', 'FontName', 'Tahoma');
legend(ax);

fig(3) = figure('Name', "IC by VOLUME - MEANS BY STIMULUS", 'Color', 'w', ...
    'Position', [479    91   901   813]);
L = tiledlayout(fig(3), 2, 2);

uType = ["Solenoid", "Solenoid + ICMS"];
for iType = 1:2
    ax = nexttile(L);
    set(ax, 'NextPlot', 'add', 'FontName', 'Tahoma', 'XColor', 'k', 'YColor', 'k');
    
    [ypred, ypredCI] = predict(volumeModel.early);
    S = volumeModel.early.Variables;
    [G, S_marg] = findgroups(S(:, {'Area', 'Lesion_Volume', 'Type'}));
    S_marg.ICA_Early = splitapply(@mean, S.ICA_Early, G);
    iRFA = strcmpi(S_marg.Area, "RFA") & strcmpi(S_marg.Type, uType(iType));
    iS1 = strcmpi(S_marg.Area, "S1") & strcmpi(S_marg.Type, uType(iType));
    scatter(ax, S_marg.Lesion_Volume(iRFA), S_marg.ICA_Early(iRFA), 'filled', ...
        'Color', color.RFA, 'MarkerEdgeColor', color.RFA, 'MarkerFaceColor', color.RFA, ...
        'DisplayName', 'RFA');
    scatter(ax, S_marg.Lesion_Volume(iS1), S_marg.ICA_Early(iS1), 'filled', ...
        'Color', color.S1, 'MarkerEdgeColor', color.S1, 'MarkerFaceColor', color.S1, ...
        'DisplayName', 'S1');
    errorbar(S_marg.Lesion_Volume(iRFA), ypred(iRFA), ypredCI(iRFA,1), ypredCI(iRFA,2),...
        'DisplayName', 'RFA + 95% CI', 'Color', color.RFA, 'LineWidth', 2);
    errorbar(S_marg.Lesion_Volume(iS1), ypred(iS1), ypredCI(iS1,1), ypredCI(iS1,2),...
        'DisplayName', 'S1 + 95% CI', 'Color', color.S1, 'LineWidth', 2);
    legend(ax, 'Location', 'Best');
    xlabel(ax, sprintf('Lesion Volume (%s)', S.Properties.VariableUnits{strcmpi(S.Properties.VariableNames, 'Lesion_Volume')}), ...
        'FontName', 'Tahoma');
    ylabel(ax, 'Score', 'FontName', 'Tahoma');
    title(ax, sprintf('Early IC (%s)', uType(iType)), 'FontName', 'Tahoma');
    
    ax = nexttile(L);
    set(ax, 'NextPlot', 'add', 'FontName', 'Tahoma', 'XColor', 'k', 'YColor', 'k');
    [ypred, ypredCI] = predict(volumeModel.late);
    S = volumeModel.late.Variables;
    [G, S_marg] = findgroups(S(:, {'Area', 'Lesion_Volume', 'Type'}));
    S_marg.ICA_Late = splitapply(@mean, S.ICA_Late, G);
    iRFA = strcmpi(S_marg.Area, "RFA") & strcmpi(S_marg.Type, uType(iType));
    iS1 = strcmpi(S_marg.Area, "S1") & strcmpi(S_marg.Type, uType(iType));
    scatter(ax, S_marg.Lesion_Volume(iRFA), S_marg.ICA_Late(iRFA), 'filled', ...
        'Color', color.RFA, 'MarkerEdgeColor', color.RFA, 'MarkerFaceColor', color.RFA, ...
        'DisplayName', 'RFA');
    scatter(ax, S_marg.Lesion_Volume(iS1), S_marg.ICA_Late(iS1), 'filled', ...
        'Color', color.S1, 'MarkerEdgeColor', color.S1, 'MarkerFaceColor', color.S1, ...
        'DisplayName', 'S1');
    errorbar(S_marg.Lesion_Volume(iRFA), ypred(iRFA), ypredCI(iRFA,1), ypredCI(iRFA,2),...
        'DisplayName', 'RFA + 95% CI', 'Color', color.RFA, 'LineWidth', 2);
    errorbar(S_marg.Lesion_Volume(iS1), ypred(iS1), ypredCI(iS1,1), ypredCI(iS1,2),...
        'DisplayName', 'S1 + 95% CI', 'Color', color.S1, 'LineWidth', 2);
    legend(ax, 'Location', 'Best');
    xlabel(ax, sprintf('Lesion Volume (%s)', S.Properties.VariableUnits{strcmpi(S.Properties.VariableNames, 'Lesion_Volume')}), ...
        'FontName', 'Tahoma');
    ylabel(ax, 'Score', 'FontName', 'Tahoma');
    title(ax, sprintf('Late IC (%s)', uType(iType)), 'FontName', 'Tahoma');
    
    title(L, 'GLME: Marginal Predictions + 95% CI', 'FontName', 'Tahoma');
    subtitle(L, '(ICs by Lesion Volume)', 'FontName', 'Tahoma');
    legend(ax);
end

if nargout < 1
    outdir = 'figures/glme_prediction_stats';
    if exist(outdir, 'dir')==0
        mkdir(outdir);
    end
    io.optSaveFig(fig(1), fullfile(outdir, 'GLME_Full_Predictions_Volume_ICEarly_ICLate'));
    io.optSaveFig(fig(2), fullfile(outdir, 'GLME_Marginal_Predictions_Volume_ICEarly_ICLate'));
    io.optSaveFig(fig(3), fullfile(outdir, 'GLME_Marginal_Predictions_by_Stimulus_by_Volume_ICEarly_ICLate'));
end

end