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

%% ChannelID and ProbeID
% this variable/section will need to be changed
% unsure how these filenames correspond with each of the channels from
% solRat object
% is P1 Ch 0 always == channel 1?
wav_sneo_folder = 'R19-227_2019_11_05_2_wav-sneo_CAR_Spikes'; 

probeList = {};
chList = [];

%gets all mat files only
matFiles = dir(fullfile(wav_sneo_folder,'*.mat')); 
for i = 1:length(matFiles)
  fileName = matFiles(i).name;
  fileSplit = split(fileName, '_');
  probeList(i) = fileSplit(end-2);
  %have to get rid of the .mat on this
  chSplit = split(fileSplit(end), '.');
  chList(i) = str2double(chSplit(end-1));
end

% check to see if any channels were removed
% if they werent, then assume:
% probe 1 ch0 -> channel 1
% probe 2 ch0 -> channel 33
% not sure how well this holds up if its not the same shape as this data
probeTable = strings(nRows,1);
chTable = zeros(nRows,1);
% +1 is needed because chList values start at 0
if length(unique(chList))*length(unique(probeList)) == nChannels
    for iRow = 1:height(masterTable)
        %get the channel of that row
        iChan = table2array(masterTable(iRow,'Channel'));
        % if its greater than the max + 1 then subract 1
        if iChan <= max(chList) + 1
            chTable(iRow) = iChan - 1; 
        % otherwise subract (max + 2), 2 is the offset
        else
            chTable(iRow) = iChan - max(chList) - 2;            
        end
        probeTable(iRow) = probeList{iChan};
    end
    
else
    warning(['SOLENOID:' mfilename ':DataFormat'],...
       ['\n\t->\t<strong>[MAKETABLES]:</strong> ' ...
        'Channel might have been removed. The indexing for ' ...
        'ChannelID & ProbeID may be incorrect']);
end

%add it to the table
masterTable.ChannelID = chTable;
masterTable.ProbeID = probeTable;

% move the variable around so its next to the other channel stuff
masterTable = movevars(masterTable,'ProbeID','After','Channel');
masterTable = movevars(masterTable,'ChannelID','After','ProbeID');

%% Load in the _DS mat files and parse them using timestamps

% Default PETH parameters
tpre = -0.250;
tpost = 0.750;
% fs is 1000 for the _DS data
timeStamps = r.Children.Trials;

%using fs and the timeStamps create a nTrials x 2 array of indices 
% first value is the start of that 1s window (in samples), second is end
% these indices can then be used to index into mat files and grab data

windowInd = zeros(nTrials, 2);

for i = 1:nTrials
    % should I round up or down? 
    % the boundary is never on a whole number index
    % right now round down on the beginning, and round up on the end
    % tpre is a negative number, so add it 
    windowInd(i,1) = floor(timeStamps(i)*fs+(tpre*fs));
    windowInd(i,2) = ceil(timeStamps(i)*fs+(tpost*fs));
end

%now use windowInd to access the mat files and parse the data
%using cells because some of the windows be off by 1 due to rounding
lfp = cell(nRows,1);
% loop through the .mat files in _DS

DS_folder = 'R19-227_2019_11_05_2_DS'; 

%gets all mat files only
matFiles = dir(fullfile(DS_folder,'*.mat')); 
%iterate through all the files
for i = 1:length(matFiles)
  fileName = matFiles(i).name;
  load(fileName);
  fileSplit = split(fileName, '_');
  probe = fileSplit(end-2);
  %have to get rid of the .mat on this
  chSplit = split(fileSplit(end), '.');
  ch = str2double(chSplit(end-1));
  
  % find the rows where you have that channel and probe
  % there might be a faster way to do this? not sure
  % iterate through all rows
  for iRow = 1:height(masterTable)
      % if the channel is correct
      chI = table2array(masterTable(iRow,'ChannelID'));
      if chI == ch
          % if the probe is correct
          if strcmp(table2array(masterTable(iRow,'ProbeID')), cell2mat(probe))
              
              % grab the indicies we parsed earlier and get that data
              ind = table2array(masterTable(iRow,'trialNumber'));
              t = windowInd(ind,:);
              lfp{iRow} = data(t(1):t(2));
          end
      end
  end
  
end

% add it to the table
masterTable.LFP = lfp;

