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
fig = figure('Name', 'Indexing Confirmation','Color','w');
ax = axes(fig, 'NextPlot', 'add', 'YLim', [-0.5, 1.5], ...
    'YTick', [0 1], 'YTickLabel', {'Unused', 'Used'});
stem(ax, t.Spikes.*1e3, double(idxT), 'Color', 'k', 'LineWidth', 2, 'DisplayName', 'idxT');
stem(ax, t.Spikes.*1e3, double(idxS), 'Color', 'b', 'LineWidth', 2, 'DisplayName', 'idxS');
xlabel(ax, 'Time (ms)', 'FontName','Tahoma');
ylabel(ax, 'Indexing Mask', 'FontName', 'Tahoma');
title(ax, 'Set Up Indexing', 'FontName', 'Tahoma');
legend(ax);

%% index channels/blocks in S1 and find z scores
idxC = T.Area == "S1" & T.Type == "Solenoid";
st = T(idxC,:).Rate(:,idxT);
avg = mean(st,2);
stdev = std(st,0,2);
win = T(idxC,:).Rate(:,idxS);
z = nan(size(win));
for i = 1:size(win,1)
    z(i,:) = (win(i,:) - avg(i)) ./ stdev(i);
end
%% identify channels with rates above 3 std
sig = z > 3;
bins = sum(sig,2);
ch = sum(bins > 0);
percent_responsive = ch/size(win,1);