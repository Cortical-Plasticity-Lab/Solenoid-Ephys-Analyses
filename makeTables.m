%% Load in mat file created in main.m of solRat
load('R19-227.mat')

%% Start making the table
trialID = r.Children.Name;

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

Group = repelem(trialTypes, 64);

%if you want it as a group name, not value do this
GroupStr = strings([nRows 1]);

for i = 1:length(Group)
    if Group(i) == 1
        GroupStr(i) = 'Solenoid';
    end
    if Group(i) == 2
        GroupStr(i) = 'ICMS';
    end
    if Group(i) == 3
        GroupStr(i) = 'Solenoid+ICMS';
    end
end

parseID = split(trialID, '_');
AnimalID = string(repelem(parseID(1),nRows)');
TrialID = string(repmat(trialID,nRows,1));


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

%% get the Histogram (spikes; PETH) and LFP data timeseries

%% make the table 

masterTable = table(TrialID, RowID, AnimalID, Group, GroupStr, Channel, ...
    Names, Hemisphere, Depth, Impedance);