%MAIN Script to run/time batch processes during development
%
%  Objects are arranged according to the hierarchy (Highest to Lowest)
%     * `solRat`     -- All recordings for a given acute procedure (rat)
%     * `solBlock`   -- Data for an individual recording (experiment; block)
%     * `solChannel` -- Data for individual channels within a recording

clear; 
clc

%% SET FILES HERE
[p,rats] = cfg.default('path','rats'); % Server tank or folder containing Animal folders

%% CREATE RAT OBJECTS
maintic = tic;
if any(arrayfun(@(s)exist(fullfile(pwd,strcat(s,".mat")),'file')==0,rats))
    r = solRat(fullfile(p,rats)); % approx. 3-minutes on Nudo lab desktop, if files already extracted
    tocData = struct('construction',round(toc(maintic)));
    savetic = tic;
    save(r);
    tocData.save = round(toc(savetic));

else
    r = solRat.loadAll(pwd,rats); 
    tocData = struct('construction',round(toc(maintic)));
end

%% CREATE PETH GRAPHICS
graphicstic = tic;
% batchProbePETH(r,cfg.TrialType('Solenoid'));
% batchProbePETH(r,cfg.TrialType('ICMS'));
% batchProbePETH(r,cfg.TrialType('Solenoid_ICMS'));
tocData.graphics = round(toc(graphicstic));

%% LAUNCH FIGURE BROWSER
% h = figBrowser(r);

%% CREATE MASTER TABLE FOR FURTHER STATISTICS
T = makeTables(r);
T = tbl.parseBlockID(T);   % Format block-related info
T = tbl.parseProbeData(T); % Format channel-related info
T = utils.roundEventTimesToNearestMillisecond(T);
T = tbl.addLaminarCategories(T);
% save(cfg.default('exported_database_table__local'),'T','-v7.3'); % (Large-ish)
% save(cfg.default('exported_database_table__remote'),'T','-v7.3'); % (Large-ish)
tocData.total = round(toc(maintic));

%% EXAMPLES FOR CREATING GRAPHICS OF EVENT-RELATED DATA
surgID = 'R19-227';
blockIndex = 3;
trialType = 1;
channelName = 'B005';

% Make spike histogram (peri-event histogram; PETH)
fig_peth = analyze.rat.plotPETH(T,surgID,blockIndex,trialType,channelName);
% Make LFP event-related potential (peri-event potential; PEP)
fig_pep = analyze.rat.plotPEP(T,surgID,blockIndex,trialType,channelName);
