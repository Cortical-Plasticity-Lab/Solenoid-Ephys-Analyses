%% clear workspace and load data
clearvars -except T;
clc;
if (exist('T', 'var')==0) || (~isTable(T)) % To avoid issue commenting/uncommenting
    load Reduced-Table.mat
end

%% setup indexing
t = T.Properties.UserData.t;
l = zeros(1,150);
idxT = l;
idxS = l;
idxT(6:45) = 1; % middle 200ms, avoids beginning and end of baseline/prestim period
idxS(61:75) = 1; % 50-125ms after 0 timepoint
idxT = logical(idxT);
idxS = logical(idxS);

% % Confirm indexing by making figure % %
fig(1) = figure('Name', 'Indexing Confirmation','Color','w');
ax = axes(fig(1), 'NextPlot', 'add', 'YLim', [-0.5, 1.5], ...
    'YTick', [0 1], 'YTickLabel', {'Unused', 'Used'}, 'FontName', 'Tahoma');
stem(ax, t.Spikes.*1e3, double(idxT), 'Color', 'k', 'LineWidth', 2, 'DisplayName', 'idxT');
stem(ax, t.Spikes.*1e3, double(idxS), 'Color', 'b', 'LineWidth', 2, 'DisplayName', 'idxS');
xlabel(ax, 'Time (ms)', 'FontName','Tahoma');
ylabel(ax, 'Indexing Mask', 'FontName', 'Tahoma');
title(ax, 'Set Up Indexing', 'FontName', 'Tahoma');
legend(ax);

%% index channels/blocks in S1 and find z scores
idxC = T.Area == "S1" & T.Type == "Solenoid";
st = T(idxC,:).Rate(:,idxT);
% preMax = max(st, [], 2);
% [~, iPreMaxSort] = sort(preMax, 'ascend');
% [~, iPreMaxRank] = sort(iPreMaxSort, 'ascend');

% % % Check the pre-stim rate traces % % %
fig(2) = figure('Name', 'Rate Traces', 'Color', 'w');
ax = axes(fig(2), 'NextPlot', 'add', 'FontName', 'Tahoma');
plot(ax, t.Spikes(idxT).*1e3, st);
xlabel(ax, 'Time (ms)', 'FontName','Tahoma');
ylabel(ax, 'Rate (spikes/s)', 'FontName', 'Tahoma');
title(ax, 'Check Rate Traces', 'FontName', 'Tahoma');
subtitle(ax, '(idxT)', 'FontName', 'Tahoma');

avg = mean(st,2);
stdev = std(st,0,2);
win = T(idxC,:).Rate(:,idxS);

% % % Check the post-stim rate traces % % %
fig(3) = figure('Name', 'Rate Traces', 'Color', 'w');
ax = axes(fig(3), 'NextPlot', 'add', 'FontName', 'Tahoma');
plot(ax, t.Spikes(idxS).*1e3, win);
xlabel(ax, 'Time (ms)', 'FontName','Tahoma');
ylabel(ax, 'Rate (spikes/s)', 'FontName', 'Tahoma');
title(ax, 'Check Rate Traces', 'FontName', 'Tahoma');
subtitle(ax, '(idxS)', 'FontName', 'Tahoma');

z = nan(size(win));
for i = 1:size(win,1)
    z(i,:) = (win(i,:) - avg(i)) ./ stdev(i);
end
%% identify channels with rates above 3 std
sig = z > 3;
bins = sum(sig,2);
ch = sum(bins > 0);
percent_responsive = ch/size(win,1);