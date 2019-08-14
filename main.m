clear; clc;

TANK = 'P:\Rat\RegionSpecificity';
RAT = {...
       ... 'R19-85';
       'R19-87';
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
   batchProbePETH(r);
   batchProbeAvgLFPplot(r);
   batchProbeAvgIFRplot(r);
   batchLFPcoherence(r);
   save([RAT{ii} '.mat'],'r','-v7.3');
   
   s = toc(rattic);
   fprintf(1,'->\tcomplete (%s)\n',utils.sec2string(s));
   fprintf(1,'--------------------------------\n');
end
disp('Batch complete.');
maintoc = toc(maintic);
fprintf(1,'\n->\t->\tTotal runtime: %s \t<-\t<-\n\n',...
   utils.sec2string(maintoc));