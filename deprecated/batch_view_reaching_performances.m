function figH = batch_view_reaching_performances(score_var)

%% SET CONSTANTS HERE
SCORE_FILE = '..\Reach-Scoring.xlsx';
SCORE_THRESHOLD = 0.60; % Scoring threshold

%% PARSE INPUT ARGS
if nargin < 1
   score_var = 'Percent_Success';
end

%% READ IN DATA AND PARSE RELEVANT VARIABLES (DATE, % SUCCESSES)
T = readtable(SCORE_FILE);
if ~ismember(score_var,T.Properties.VariableNames)
   disp('Error: score_var must be one of the following:');
   for ii = 1:numel(T.Properties.VariableNames)
      disp(T.Properties.VariableNames{ii});
   end
   figH = [];
   return;
end

T = sortrows(T,'Date','ascend');
[R,idx] = unique(T.Rat);
G = T.Group(idx);
uG = unique(G);
t = T.Date;
score = T.(score_var);

figH = figure('Name','Behavioral Performance',...
   'Units','Normalized',...
   'Color','w',...
   'Position',[0.1 0.1 0.5 0.5]);

if max(score) <= 1
   ax = axes(figH,'NextPlot','add',...
      'YLimMode','manual',...
      'YLim',[0 1]);
else
   ax = axes(figH,'NextPlot','add',...
      'YLimMode','manual',...
      'YLim',[0 max(score)*1.25]);
end
col = {[0.7 0.7 0.7]; 'b'; 'k'; 'w'};
lw = linspace(1.5,2.0,numel(R));

for iR = 1:numel(R)
   idx = ismember(T.Rat,R{iR});
   iCol = find(ismember(uG,G{iR}),1,'first');
   plot(ax,t(idx),score(idx),'LineWidth',lw(iR),'Color',col{iCol},...
      'Marker','o','MarkerFaceColor',col{iCol},...
      'LineStyle',':');
end
title('Retrieval Performance','FontName','Arial','FontSize',16,'Color','k');
xlabel('Date','FontName','Arial','FontSize',14,'Color','k');
ylabel(strrep(score_var,'_',' '),'FontName','Arial','FontSize',14,'Color','k');

if strcmpi(score_var,'Percent_Success')
   line([min(t) max(t)],[SCORE_THRESHOLD SCORE_THRESHOLD],...
      'Color','r','LineStyle','--','LineWidth',2);
   legend([R;'Score Threshold'],'Location','best');
else
   legend(R,'Location','best');
end



end