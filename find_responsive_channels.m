%% set indices
% load Reduced-Table.mat
t = T.Properties.UserData.t;
l = zeros(1,150);
idxT = l;
idxS = l;
idxT(6:45) = 1; % middle 200ms, avoids beginning and end of baseline/prestim period
idxS(61:75) = 1; % 50-125ms after 0 timepoint
idxT = logical(idxT);
idxS = logical(idxS);
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