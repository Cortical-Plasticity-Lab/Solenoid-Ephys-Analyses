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
T = tbl.parseBlockID(T); % Format data
% save(cfg.default('exported_database_table__local'),'T','-v7.3'); % (Large-ish)
% save(cfg.default('exported_database_table__remote'),'T','-v7.3'); % (Large-ish)
tocData.total = round(toc(maintic));

%% EXAMPLES FOR CREATING GRAPHICS OF EVENT-RELATED DATA
% Make spike histogram (peri-event histogram; PETH)
fig_peth = tbl.gfx.PETH(T,...
      {'SurgID','R19-224',... % "filtArgs"
       'BlockIndex',1,...
       'ChannelID','A002',...
       'TrialType',2},...
    'AxesParams', ... % (Optional 'Name', value args)
      {'NextPlot','add',...
       'XColor','k',...
       'YColor','k',...
       'LineWidth',1.25,...
       'ColorOrder',cfg.gfx('ColorOrder'),...
    'XLim',[-100 200]});
% Make LFP event-related potential (peri-event potential; PEP)
fig_pep = tbl.gfx.PEP(T,{'SurgID','R19-224','BlockIndex',1,'ChannelID','A002','TrialType',2},'AxesParams',{'NextPlot','add','XColor','k','YColor','k','LineWidth',1.25,'ColorOrder',cfg.gfx('ColorOrder'),'XLim',[-100 200]});

