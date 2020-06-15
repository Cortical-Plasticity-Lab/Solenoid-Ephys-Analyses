%MAIN Script to run/time batch processes during development
%
%  Objects are arranged according to the hierarchy (Highest to Lowest)
%     * `solRat`     -- All recordings for a given acute procedure (rat)
%     * `solBlock`   -- Data for an individual recording (experiment; block)
%     * `solChannel` -- Data for individual channels within a recording

clear; clc

%% SET FILES HERE
folder_to_process = { ...
   ... '/Users/Shiv/Documents/Med School/M1/GuggenmosResearch/Solenoid-Ephys-Analyses_sdalla/Data/R19-227'
   'P:\Rat\BilateralReach\Solenoid Experiments\R19-224'; ...
   'P:\Rat\BilateralReach\Solenoid Experiments\R19-226'; ...
   'P:\Rat\BilateralReach\Solenoid Experiments\R19-227'; ...
   'P:\Rat\BilateralReach\Solenoid Experiments\R19-230'; ...
   'P:\Rat\BilateralReach\Solenoid Experiments\R19-231'; ...
   'P:\Rat\BilateralReach\Solenoid Experiments\R19-232'; ...
   'P:\Rat\BilateralReach\Solenoid Experiments\R19-234' ...
   };

%% CREATE RAT OBJECTS
% load('R19-227_2019_11_05_2_GenInfo.mat')
% info.tankpath = '/Users/Shiv/Documents/Med School/M1/GuggenmosResearch/Solenoid-Ephys-Analyses_sdalla/Data';
% maintic = tic;
r = solRat(folder_to_process);
% tocData = struct('construction',round(toc(maintic)));

%% CREATE PETH GRAPHICS
% graphicstic = tic;
% batchProbePETH(r,cfg.TrialType('Solenoid'));
% batchProbePETH(r,cfg.TrialType('ICMS'));
% batchProbePETH(r,cfg.TrialType('Solenoid_ICMS'));
% tocData.graphics = round(toc(graphicstic));

%% SAVE RAT OBJECTS
% savetic = tic;
% save(r);
% tocData.save = round(toc(savetic));

%%
% tocData.total = round(toc(maintic));