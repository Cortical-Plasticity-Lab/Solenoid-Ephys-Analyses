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
% save(cfg.default('exported_database_table__local'),'T','-v7.3'); % (Large-ish)
save(cfg.default('exported_database_table__remote'),'T','-v7.3'); % (Large-ish)
tocData.total = round(toc(maintic));