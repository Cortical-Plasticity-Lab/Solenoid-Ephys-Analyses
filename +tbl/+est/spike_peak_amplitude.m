%% Determine time points of interest
binSize = T.Properties.UserData.settings.binwidth;
binSize = binSize * 1e3; % Convert to ms
binSt = 51; % 0 time bin
binEnd = numel(T.Properties.UserData.t.Spikes); % Last bin
buff = ceil(10/binSize); % Buffer at least 10ms before 0 timepoint
preBin = binSt - buff;
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
%% Eliminate channels with low spiking rates
bt = (1+buff):(binEnd-buff); % Buffer edges of baseline period
dur = ((binEnd-buff) - (1+buff))*(binSize*1e-3); % Determine duration in sec
thresh = 2.4; % Spikes/sec
T= tbl.elimCh(T,bt,dur,thresh);
%% Create table 'C' with new variables for each condition
for i = 1 : tot
    n = i*2;
    binTime = (win(n-1):win(n));
    winTitle = "Window_%d";
    varWin = char(sprintf(winTitle,i));
    num = sum(T.Spikes(:,binTime),2);
    T.(varWin) = sqrt(num./dt{i});
    fn = @(X){nanmean(X,1)};
    inputVars = {varWin};
    varTitle = "Amp_Sum_%d";
    outputVars = char(sprintf(varTitle,i));
    C = tbl.stats.estimateChannelResponse(T,fn,inputVars,outputVars);
    newVar = C.Properties.VariableNames{end};
    varC{i,2} = C.(newVar);
    varC{i,1} = outputVars;
    binPreTime = (preWin(n-1):preWin(n));
    winPreTitle = "Pre_Window_%d";
    varPreWin = char(sprintf(winPreTitle,i));
    num = sum(T.Spikes(:,binPreTime),2);
    T.(varPreWin) = sqrt(num./dt{i});
    inputVars = {varPreWin};
    varTitle = "pre_Amp_Sum_%d";
    outputVars = char(sprintf(varTitle,i));
    C = tbl.stats.estimateChannelResponse(T,fn,inputVars,outputVars);
    newVar = C.Properties.VariableNames{end};
    preC{i,2} = C.(newVar);
    preC{i,1} = outputVars;
end
for i = 1 : tot % Fill table 'C' with new variables
    C.(varC{i,1})= varC{i,2};
    C.(preC{i,1})= preC{i,2};
end
%% Run GLME model
for i = 1 : tot
    new = tot*2;
    mod = C(:,1:end-(new));
    mod.VarC = varC{i,2};
    mod.PreC = preC{i,2};
    glme{i} = fitglme(mod,...
        'VarC ~ 1 + Type*Area + (1|ChannelID) + (1 |PreC)',...
        'Distribution','Normal','Link','identity');
end
clearvars -except T C glme