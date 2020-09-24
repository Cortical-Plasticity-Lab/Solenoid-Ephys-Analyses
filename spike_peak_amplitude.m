%% Spike Peak Amplitude
% Determine time points of interest
binSize = T.Properties.UserData.settings.binwidth;
bin1 = 51;
iT = [5; 40;... % input times of interest in ms
    60; 85]; 
% Return bin numbers 
win = ((iT/(binSize.*1000)) + bin1); % return bin numbers
% Generate pre-stim window based on variable bandwidths
preBin = bin1-10;
preWin = [preBin-(win(2)-win(1)); preBin;...
    preBin-(win(4)-win(3)); preBin];
% Create table 'C' with new variables for each condition
tot = numel(win)/2;
for i = 1 : tot;
    n = i*2;
    binTime = (win(n-1):win(n));
    winTitle = "Window_%d";
    varWin = char(sprintf(winTitle,i));
    num = (T.Spikes(:,binTime));
    T.(varWin) = sum(num,2);
    fn = @(X){nanmedian(X,1)};
    inputVars = {'Window'},;
    varTitle = "Amp_Sum_%d";
    outputVars = char(sprintf(varTitle,i));
    C = tbl.stats.estimateChannelResponse(T,fn,inputVars,outputVars);
    newVar = C.Properties.VariableNames{end};
    varC{i,2} = C.(newVar);
    varC{i,1} = outputVars;
    binPreTime = (preWin(n-1):preWin(n));
    winPreTitle = "Pre_Window_%d";
    varPreWin = char(sprintf(winPreTitle,i));
    num = (T.Spikes(:,binPreTime));
    T.(varPreWin) = sum(num,2);
    inputVars = {'preWindow'},;
    varTitle = "pre_Amp_Sum_%d";
    outputVars = char(sprintf(varTitle,i));
    C = tbl.stats.estimateChannelResponse(T,fn,inputVars,outputVars);
    newVar = C.Properties.VariableNames{end};
    preC{i,2} = C.(newVar);
    preC{i,1} = outputVars;
end
for i = 1 : tot
    C.(varC{i,1})= varC{1,2};
end
for i = 1 : tot
    C.(preC{i,1})= preC{1,2};
end