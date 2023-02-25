%MARGINAL_STATS_PARTIAL_DEPENDENCE_FIGURES  For comparing glme with polyfit
close all force;
clc;

color = struct('S1', validatecolor("#e7a4dc"), 'RFA', validatecolor("#87e1e1"));
outdir = 'figures/marginal_stats_comparison';

if exist(outdir, 'dir')==0
    mkdir(outdir);
end

S = mdl.volume.early.Variables;
[G, S_marg] = findgroups(S(:, {'Area', 'Lesion_Volume'}));
S_marg.ICA_Early = splitapply(@mean, S.ICA_Early, G);
[pd,A,LV] = partialDependence(mdl.volume.early, ["Area", "Lesion_Volume"]);
area = string(A);
fig(1) = figure('Name', 'Early Component PD Plot', ...
    'Color','w','Position',[720 558 560 420]); 
ax = axes(fig(1), 'NextPlot', 'add', 'FontName','Tahoma','FontSize',14, ...
    'YLim', [-6 6]);
for iA = 1:numel(area)
    plot(ax, LV, pd(:,iA), 'Color', color.(area(iA)), ...
        'LineWidth', 3, 'DisplayName', sprintf('%s (GLME)', area(iA)));
    iArea = strcmpi(S_marg.Area, area(iA));
    rP = polyfit(S_marg.Lesion_Volume(iArea), S_marg.ICA_Early(iArea), 1);
    rYfit = polyval(rP,LV); % Use the same values as the PD plot for showing the line
    plot(LV,rYfit,'LineStyle', '--', 'LineWidth', 2, ...
        'Color', color.(area(iA)), 'DisplayName', sprintf('%s (Linear)', area(iA)));
end
legend(ax, 'Location', 'Best', 'FontName', 'Tahoma', 'FontSize', 12);
xlabel(ax, "Lesion Volume (mm^3)", 'FontName', 'Tahoma');
ylabel(ax, "IC Score", 'FontName', 'Tahoma');
title(ax, "Early", 'FontName', 'Tahoma');

S = mdl.volume.late.Variables;
[G, S_marg] = findgroups(S(:, {'Area', 'Lesion_Volume'}));
S_marg.ICA_Late = splitapply(@mean, S.ICA_Late, G);
[pd,A,LV] = partialDependence(mdl.volume.late, ["Area", "Lesion_Volume"]);
area = string(A);
fig(2) = figure('Name','Late Component PD Plot', ...
    'Color','w','Position',[160 558 560 420]); 
ax = axes(fig(2), 'NextPlot', 'add', 'FontName','Tahoma','FontSize',14, ...
    'YLim', [-6 6]);
for iA = 1:numel(area)
    plot(ax, LV, pd(:,iA), 'Color', color.(area(iA)), ...
        'LineWidth', 3, 'DisplayName', sprintf('%s (GLME)', area(iA)));
    iArea = strcmpi(S_marg.Area, area(iA));
    rP = polyfit(S_marg.Lesion_Volume(iArea), S_marg.ICA_Late(iArea), 1);
    rYfit = polyval(rP,LV); % Use the same values as the PD plot for showing the line
    plot(LV,rYfit,'LineStyle', '--', 'LineWidth', 2,...
        'Color', color.(area(iA)), 'DisplayName', sprintf('%s (Linear)', area(iA)));
end
legend(ax, 'Location', 'Best', 'FontName', 'Tahoma', 'FontSize', 12); 
xlabel(ax, "Lesion Volume (mm^3)", 'FontName', 'Tahoma');
ylabel(ax, "IC Score", 'FontName', 'Tahoma');
title(ax, "Late", 'FontName', 'Tahoma');

pause(5);
io.optSaveFig(fig(1), outdir, 'GLME_vs_PolyFit_EarlyICA_by_LV_and_Area');
io.optSaveFig(fig(2), outdir, 'GLME_vs_PolyFit_LateICA_by_LV_and_Area');
