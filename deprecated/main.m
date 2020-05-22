%MAIN  Main "batch" script for handling data using "sol" objects
%  Works as a generic "outline" of processing accomplished by this analysis

clear; clc;
TANK = 'P:\Rat\RegionSpecificity';
RAT = {... % Uncomment lines to add those rats
       ... 'R19-85';
       ... 'R19-87';
       ...'R19-94';
       ...'R19-101';
       ...'R19-104';
       ...'R19-146';
       ...'R19-147';
       ...'R19-159';
       ...'R19-160'
       };

maintic = tic;
for ii = 1:numel(RAT)
   rattic = tic;
   fprintf(1,'Parsing rat: %s...\n',RAT{ii});
   r = solRat(fullfile(TANK,RAT{ii}));
   % All "Probe" methods lay out subplots in depth/columnar arrangement of
   % microelectrode arrays, so it's easier to know which plots correspond
   % to elements at a particular depth. Reference the OneNote to get more
   % info about setup/layout/insertion depth.
   batchProbePETH(r); % Makes a bunch of peri-event time histograms (PETH)
   batchProbeAvgLFPplot(r); % Averages local field potential (LFP) traces
   batchProbeAvgIFRplot(r); % Averages instantaneous firing rate (IFR) 
                            % traces. (Note: this is essentially equivalent
                            % to doing the `batchProbePETH` with a kernel
                            % smoothing that depends on how IFR was
                            % estimated).
   batchLFPcoherence(r);    % I don't remember; I think it's the coherence
                            % between LFP and IFR, but not 100% on that. It
                            % might just be between different frequency RMS
                            % powers from LFP.
                            
   % Save "Rat" object
   save([RAT{ii} '.mat'],'r','-v7.3');
   
   % Output some timing info
   s = toc(rattic);
   fprintf(1,'->\tcomplete (%s)\n',utils.sec2string(s));
   fprintf(1,'--------------------------------\n');
end
disp('Batch complete.');
maintoc = toc(maintic);
fprintf(1,'\n->\t->\tTotal runtime: %s \t<-\t<-\n\n',...
   utils.sec2string(maintoc));