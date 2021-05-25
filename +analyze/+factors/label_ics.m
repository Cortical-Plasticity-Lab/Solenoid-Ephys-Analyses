function [S,fig] = label_ics(S,z,t,w)
%LABEL_ICS Always label the indepedent components similarly
%
%    S = analyze.factors.label_ics(S,z);
%   [S, fig] = analyze.factors.label_ics(S,z);  % This doesn't delete fig
%
% Inputs
%  S - Data table to append `z` to as new "labeled" columns
%  z - Independent components weightings
%
% Output
%  S - Same as input but with the new variables (columns of `z`)
%
% See also: Contents, analyze.factors.getICs

S.ICA_Noise = z(:,1); % First IC is "noise floor" component - how active is the channel?
% --> This should be used as a covariate for the
%     other two, which are the responses of interest.

S.ICA_Late = z(:,2);  % Second IC is "late" component

S.ICA_Early = z(:,3); % Third IC is "early" component

if nargin < 4
    fig = [];
    return;
end
fig = figure('Name', 'Independent Components',...
    'Color','w','Units','Normalized','Position',[0.15 0.15 0.80 0.55],...
    'PaperOrientation','Landscape','PaperSize',[8.5 11],...
    'PaperUnits','inches','PaperType','usletter','NumberTitle','off');
ax = axes(fig, 'NextPlot', 'add', 'XColor', 'k', 'YColor', 'k', ...
    'FontName', 'Arial');
f = ["ICA_{Noise}", "ICA_{Late}", "ICA_{Early}"];
for ii = 1:3
    plot(ax, t, w(:, ii), ...
        'DisplayName', f(ii), ...
        'LineWidth', 1.5);
end
xlabel(ax, 'Time', 'FontName', 'Arial', 'Color', 'k');
ylabel(ax, 'Weight', 'FontName', 'Arial', 'Color', 'k');
title(ax, 'Independent Component Assignments', 'FontName', 'Arial', 'Color', 'k');
legend(ax, 'TextColor', 'k', 'FontName', 'Arial');

if nargout < 2
    io.optSaveFig(fig,'figures/pca_stats/models','ICs');
end

end