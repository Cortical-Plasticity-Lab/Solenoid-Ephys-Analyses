function exportSaveFigure(C,groupings,filename,varargin)
%EXPORTSAVEFIGURE Export and save figures using Figures.PlotGroupedResponses
%
%  utils.exportSaveFigure(C,groupings,filename);
%  utils.exportSaveFigure(C,groupings,filename,'Name',value,...);
%
% Inputs
%  C           - Data table by channel with average LFP already added
%  groupings   - Data table with grouping info for `C` subplots
%  filename    - Name of output file to save (no extension, but full path
%                 with folder included; string or char array)
%  varargin    - (Optional) <'Name',value> argument pairs
%
%                 -> 'NPeaks' (default: 2)
%                 -> 'NameIndices' (default: [2,3])
%                       (Refers to columns of `groupings` table)
%                 -> 'ResponseVar' (default: 'LFP')
%                       (Refers to variable to plot)
%
% Output
%  No returned argument. Saves figures based on `filename`
%
% See also: Contents, Figures, Figures.PlotGroupedResponses

pars = struct;
pars.Figure_Args = {'Units','Normalized','Position',[0.1 0.1 0.8 0.8]};
pars.NPeaks = 1;
pars.NameIndices = [2,3];
pars.PC_Type = "Solenoid";
pars.PeaksAfter = 0;
pars.ResponseVar = 'LFP';
pars.XLim = [-50 500];
pars.YLim = [-500 500];
fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

[p,f,~] = fileparts(filename);
if exist(p,'dir')==0
   mkdir(p);
end

strTitle = strrep(f,'-',' ');
strTitle = strrep(strTitle,'SolenoidICMS','Solenoid + ICMS');

if any(isnan(pars.XLim)) || isempty(pars.XLim)
   xl = [pars.PeaksAfter-100, max(C.Properties.UserData.t.(pars.ResponseVar))];
else
   xl = pars.XLim;
end

% Make actual figure
fig = Figures.PlotGroupedResponses(...
   C,groupings,pars.ResponseVar,...
   'Figure_Args',pars.Figure_Args,...
   'FigureName',strTitle,...
   'NPeaks',pars.NPeaks,...
   'NameIndices',pars.NameIndices,...
   'PC_Type',pars.PC_Type,...
   'PeaksAfter',pars.PeaksAfter,...
   'XLim',xl,...
   'YLim',pars.YLim);
figure(fig(1));
suptitle(sprintf('\\bf%s:\\rm %s',pars.ResponseVar,strTitle));

fprintf(1,'\n(Figures saved at: <strong>%s</strong>)\n',p);
fprintf(1,'Saving %s...',f);

tic;
% utils.expAI(fig,fullfile(p,[f '.svg']));
saveas(fig(1),fullfile(p,[f '.png']));
savefig(fig(1),fullfile(p,[f '.fig']));
delete(fig(1));
saveas(fig(2),fullfile(p,[f '-PCs.png']));
savefig(fig(2),fullfile(p,[f '-PCs.fig']));
delete(fig(2));
fprintf(1,'complete (%5.2f sec)\n',toc);
end