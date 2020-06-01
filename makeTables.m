%% Load in mat file created in main.m of solRat
load('R19-227.mat')

%% Start making the table
trialID = r.Children.Name;

% Note that r.Children can be an array. So this syntax works currently, but
% only because there is a single Block in the example.

%number of rows = number of channels * number of trials
nChannels = length(r.Children.Children);
trialTypes = r.Children.TrialType;
nTrials = length(r.Children.TrialType);
nRows = nChannels * nTrials;
RowID = strings([nRows 1]);

alphabet = strcat('a':'z','A':'Z');

for i = 1:nRows
    randstr = alphabet(randi(length(alphabet), 1, 10));
    RowID(i) = strcat("ROWID_",randstr);
end

% should group be a number? or should it say: "Solenoid","ICMS","ICMS+Solenoid"
% 1 = evoked response of the solenoid only
% 2 = evoked response of ICMS only
% 3 = evoked response from the combination of solenoid and ICMS. 

GroupID = repelem(trialTypes, 64);

% %if you want it as a group name, not value do this
% GroupStr = strings([nRows 1]);
% 
% for i = 1:length(GroupID)
%     if GroupID(i) == 1
%         GroupStr(i) = 'Solenoid';
%     end
%     if GroupID(i) == 2
%         GroupStr(i) = 'ICMS';
%     end
%     if GroupID(i) == 3
%         GroupStr(i) = 'Solenoid+ICMS';
%     end
% end

parseID = split(trialID, '_');
AnimalID = string(repelem(parseID(1),nRows)');
BlockID = string(repmat(join(parseID(2:end),'_'),nRows,1));
TrialID = string(repmat(trialID,nRows,1));

% Group = categorical(GroupID,1:3,{'Solenoid','ICMS','Solenoid+ICMS'});
Group = cfg.TrialType(GroupID); % Uses previously-defined enumeration TrialType class

%% SolChannel stuff

Channel = repmat(1:nChannels,1,nTrials)';

depthArr = zeros(nChannels,1);
hemisphereArr = zeros(nChannels,1);
impedenceArr = zeros(nChannels,1);
nameArr = strings([nChannels 1]);

for i = 1:nChannels
    depthArr(i) = r.Children.Children(i,1).Depth;
    hemisphereArr(i) = r.Children.Children(i,1).Hemisphere;
    impedenceArr(i) = r.Children.Children(i,1).Impedance;
    nameArr(i) = r.Children.Children(i,1).Name;
end

Depth = repmat(depthArr,nTrials,1);
Hemisphere = repmat(hemisphereArr,nTrials,1);
Impedance = repmat(impedenceArr,nTrials,1);
Names = string(repmat(nameArr,nTrials,1));

trialNumber = repelem(1:nTrials,nChannels)';
%% make the table 

masterTable = table(TrialID, BlockID, RowID, AnimalID, GroupID, ...
    Group, Channel, trialNumber, ...
    Names, Hemisphere, Depth, Impedance);

%% get the Histogram (spikes; PETH) and LFP data timeseries
binCell = {nRows,1};
%for loop over the whole table
for iRow = 1:height(masterTable)
    %first need to get which channel that row is
    iChan = table2array(masterTable(iRow,'Channel'));
    %get the binned spikes for that channel, allTrials is 118x500 double
    % 118 --> Number of trials
    % 500 --> Number of time bins (-500 : 500 ms; 2-ms bins)
    allTrials = r.Children.Children(iChan,1).getBinnedSpikes();
    %get the specific trial in question using the trialNumber as index
    %each cell in binCell should return a 1x500 double
    binCell{iRow} = allTrials(table2array(masterTable(iRow,'trialNumber')),:);
end

%have to some reason transpose it to get it to be nx1
binCellt = binCell';

%add it to the table
masterTable.Spikes = binCellt;