% Load in the table, it will take a minute or so
load('Solenoid-Table.mat', 'T')
%%
% General:
% Input: rat, channel, trialType, varargin(for standard dev)
% Return: array of peak time, width, num spikes, and rank for each peak
% ex: [[tPeak1, binWidth1, numSpikes1, rank1] , [tPeak2, binWidth2, numSpikes2, rank2] ]

% Testing variables (can be changed)

rat = 'R19-224';
channel = 1;
trialType = 'Solenoid';
sDev = [3.5, 4.5];

% Default file variables
pMargin = 0.1; % proportion to ignore at beginning and before trial
tPost = cfg.default('tpost'); % time before onset in seconds
tPre = cfg.default('tpre'); % time after onset in seconds
tTotal = abs(tPost)+abs(tPre);
% Get the proportion of the time pre and post 
pPost = tPost/tTotal;
pPre = abs(tPre/tTotal);

binWidth = cfg.default('binwidth'); % width of PETH bins in seconds
numBins = (abs(tPre)+abs(tPost))/binWidth;
midBins =(numBins*pMargin:numBins*(1-pMargin));

%%
% First get means of the PETH before solenoid
% neglect first 10% and last 10% before


[G, G_SurgID ,G_Type , G_Channel] = findgroups(T.SurgID, T.Type, T.Channel);


sumSpikes = splitapply(@sum, T.Spikes, G);

meanPreSolTrim = mean(sumSpikes(:,midBins),2);

trialSelect = G_Type == trialType;
%areaOfInterest = (string(G_SurgID) == rat).*(G_Type == trialType).*(G_Channel == channel);
%% Quick visualization to see an example
i = randsample(length(meanPreSolTrim), 1);
plot(sumSpikes(i,:))
yline(meanPreSolTrim(i))
%% Find peaks on the spiking data
% only look at the data after the event (tPost)

%set a time delay to ignore solenoid artifact
delayTime = 0.02;
delayBin = floor(delayTime/binWidth);
%set a time to ignore peaks after with respect to event
maxTime = 0.1; %the difference between maxTime and delayTime is the window size in seconds
maxBin = floor(maxTime/binWidth);

% set the window of bins that we want to get the data from
delays = floor(pPre*numBins)+delayBin;
close = floor(pPre*numBins)+maxBin;

peakCells = cell(length(meanPreSolTrim), length(sDev));
locCells = cell(length(meanPreSolTrim), length(sDev));
widthCells = cell(length(meanPreSolTrim), length(sDev));
promCells = cell(length(meanPreSolTrim), length(sDev));

%TODO: impliment ability to check solenoidOnset and add that accordingly?
% or does the PETH used to generate spikes take that into account?

for i = 1:length(sDev)
    iDev = sDev(i);
    for j = 1:length(meanPreSolTrim)
        thresh = iDev*meanPreSolTrim(j);
        
        % may need to group based on the solenoid onset and offset?
        %sOnSet = T(T.SurgID == string(G_SurgID(j)) & T.Channel == G_Channel(j) & T.Type == G_Type(j),:);
        %sOffSet = T(T.SurgID == string(G_SurgID(j)) & T.Channel == G_Channel(j) & T.Type == G_Type(j), T.Solenoid_Offset);
        
        
        d = sumSpikes(j, delays:close);
        [pks, locs, w, p] = findpeaks(d, 'Threshold',thresh);
        
         
        peakCells{j,i} = pks;
        locCells{j,i} = locs+delays; %check this for off by one error on the addition
        widthCells{j,i} = w;
        promCells{j,i} = p;
        
        
    end
end

