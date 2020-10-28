%% Set variables
binSize = T.Properties.UserData.settings.binwidth;
binSize = binSize * 1e3; % Convert to ms
binSt = 51; % 0 time bin
binEnd = numel(T.Properties.UserData.t.Spikes); % Last bin
buff = ceil(10/binSize); % Buffer at least 10ms before 0 timepoint
preBin = binSt - buff;
%% Eliminate channels with low spiking rates
bt = (1+buff):(binEnd-buff); % Buffer edges of baseline period
dur = ((binEnd-buff) - (1+buff))*(binSize*1e-3); % Determine duration in sec
thresh = 2.4; % Spikes/sec
[T,B]= tbl.elimCh(T,bt,dur,thresh);
%% Create table 'C' with mean spikes per channel
fn = @(X){nanmean(X,1)};
outputVars = 'Spike_Mean';
C = tbl.stats.estimateChannelResponse(T,fn,'Spikes',outputVars);
B.Threshold = (B.Mean_Baseline.*0.005) + ((B.STD_Baseline.*0.005).*3); % Threshold is 3SD over baseline and should be in spikes/5ms or spikes per bin
C.Threshold = zeros(size(C,1),1);
for i = 1:size(B.Threshold,1)
    idx = (C.BlockID == B.BlockID(i) & C.ChannelID == B.ChannelID(i));
    C.Threshold(idx) = B.Threshold(i);
end
%% Find latencies of peaks
P = C.Spike_Mean(:,binSt:end);
C.ICMS_Onset = round(C.ICMS_Onset,2);
C.Solenoid_Onset = round(C.Solenoid_Onset,2);
[G,uniq] = findgroups(C(:,{'ICMS_Onset','Solenoid_Onset'}));
for i = 1:size(uniq, 1) % Zero activity before first stim
    a = min(table2array(uniq(i,:)));
    alignBin = a/(binSize*0.001);
    if alignBin > 0
        idx = G == i;
        P(idx,1:alignBin) = 0;
    end
end
for i = 1: size(P,1) % Zero spikes under threshold
    p = P(i,:);
    idx = p <= (C.Threshold(i)); 
    p(idx) = 0;
    P(i,:) = p;
end
rep = P == 0;
P(rep) = NaN;
[P, idx] = sort(P,2,'descend','MissingPlacement','last');
pk = 5;
C.ampMax = [P(:,1:pk)];
C.ampBin = idx(:,1:pk);
n = isnan(C.ampMax);
C.ampBin(n) = 0;
C.pkTime = C.ampBin.*binSize;
histogram(C.ampBin(C.ampBin > 1),99) % Plot amplitudes
[index,ref] = findgroups(C(:,{'ICMS_Onset','Solenoid_Onset','Area','Type'}));
for i = 1:size(ref,1)
    gr = index == i;
    figure;
    group = C.ampBin(gr,:);
    histogram(group(group > 1),99);
    hold on
    v1 = table2array(ref(i,1));
    v2 = table2array(ref(i,2));
    v3 = char(table2array(ref(i,3)));
    v4 = char(table2array(ref(i,4)));
    varTitle = "ICMS %02d Solenoid %02d Area %s Type %s";
    title(sprintf(varTitle,v1,v2,v3,v4));
    hold off
end
glme = fitglme(C,...
        'pkTime ~ 1 + Type*Area + (1|SurgID)',...
        'Distribution','Normal','Link','identity');
%% Use windows
iT = [5; 40;... % Input times of interest in ms
    60; 85]; 
win = ((iT/binSize) + binSt); % Return bin numbers
tot = numel(iT)/2; % Number of windows
for i = 1 : tot % Generate corresponding pre-stim windows
    n = i*2;
    preWin = [preBin-(win(n)-win(n-1)); preBin;...
        preBin-(win(n)-win(n-1)); preBin];
end
for i = 1 : tot % Find durations of each window of interest
    n = i*2;
    dt{i} = iT(n)-iT(n-1);
end
%% Run GLME model
for i = 1 : tot
    new = tot*2;
    mod = C(:,1:(end) - (new));
    mod.SpChannelID = strcat(string(mod.BlockID),{'_'},string(mod.ChannelID));
    mod.VarC = varC{i,2};
    mod.PreC = preC{i,2};
    glme{i} = fitglme(mod,...
        'VarC ~ 1 + Type*Area + (1+PreC|SpChannelID)',...
        'Distribution','Normal','Link','identity');
end
clearvars -except T C glme