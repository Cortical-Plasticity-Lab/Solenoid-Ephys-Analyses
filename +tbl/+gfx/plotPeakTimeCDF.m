function fig = plotPeakTimeCDF(C,tStart_Fixed,tStop_Fixed,tag)
%PLOTPEAKTIMECDF Plot peak-time cumulative distribution function
%
%  fig = tbl.gfx.plotPeakTimeCDF(C,tStart_Fixed,tStop_Fixed,tag);
%
% Inputs
%  C            - See `C` from new_analysis.m
%  tStart_Fixed - Start time (ms) for window "sweeps" to construct CDF
%                 -> "Presence" detected as
%           `present = any(tStart_Fixed <= t < stop,2)`
%              Where `stop` is varied from `tStart_Fixed` to `tStop_Fixed`
%
%           -> If `tStart_Fixed` is given as a negative value, then the
%           magnitude is retained but it indicates the "sweep" should go in
%           the opposite direction.
%
%  tStop_Fixed - End time (ms) for window "sweeps" to construct CDF
%           -> Should always be a positive value
%
%  tag - (Optional) tag for saving the file
%
% Output
%  fig         - Figure handle
%
% See also: Contents, main.m, new_analysis.m

if nargin < 2
   tStart_Fixed = 10;
end

if nargin < 3
   tStop_Fixed = 250;
end

if nargin < 4
   tag = '';
end

tVec = C.Properties.UserData.t.Spikes*1e3;
if tStart_Fixed >= 0
   tIdx = tVec >= tStart_Fixed & tVec <= tStop_Fixed;
   tSample = tVec(tIdx);
   nSweep = numel(tSample);
   tFixed = tStart_Fixed;
   tSweep = [repmat(tFixed,nSweep,1), tSample'];
   wtype = "larger";
   wlabel = "Window Upper Bound";
   llabel = "Window Lower Bound";
else
   tIdx = tVec >= (-tStart_Fixed) & tVec <= tStop_Fixed;
   tSample = tVec(tIdx);
   nSweep = numel(tSample);
   tFixed = tStop_Fixed;
   tSweep = [tSample', repmat(tFixed,nSweep,1)];
   wtype = "smaller";
   wlabel = "Window Lower Bound";
   llabel = "Window Upper Bound";
end

% "Sweep" through tSample by iteration
present = false(size(C,1),nSweep);
tic; fprintf(1,'"Sweeping" incrementally <strong>%s</strong> windows...%03d%%\n',wtype,0);

% % % Compute the response-offset-normalized timings % % %
t = C.ampTime*1e3 - C.Response_Offset__Exp;
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

for ii = 1:nSweep
   present(:,ii) = getPresent(t,tSweep(ii,:));
   fprintf(1,'\b\b\b\b\b%03d%%\n',round(ii/nSweep * 100));
end
fprintf(1,'\b\b\b\b\bcomplete (%5.2f sec)\n',toc);


fig = figure('Name',sprintf('CDF %s',tag),'Color','w',...
   'Units','Normalized','Position',[0.15 0.1 0.8 0.7],...
   'PaperOrientation','landscape');
TYPE = ["Solenoid", "ICMS", "Solenoid + ICMS"];

if tStart_Fixed >= 0
   xdir = "normal";
   yRand = [0 100];
   legLoc = 'southeast';
else
   xdir = "reverse";
   legLoc = 'northwest';
   yRand = [100 0];
end

for ii = 1:3
   ax = subplot(1,3,ii);
   set(ax,'Parent',fig,'FontName','Arial','XColor','k','YColor','k',...
      'NextPlot','add',...
      'XLim',[0 max(tVec)],...
      'YLim',[0 100],...
      'XDir',xdir,...
      'Tag',TYPE(ii));
   
   idx = string(C.Type)==TYPE(ii);
   nTotal = sum(idx);
   p = present(idx,:);
   pct = zeros(size(tVec));
   pct(tIdx) = nansum(p,1)*100/nTotal;
   if xdir=="normal"
      iLast = find(tIdx,1,'last');
      pct(iLast:end) = pct(iLast);
   else
      iFirst = find(tIdx,1,'first');
      pct(1:iFirst) = pct(iFirst);
   end
   
   line(ax,tVec,pct,'LineWidth',2.5,...
      'Color','b','LineStyle','-',...
      'DisplayName','CDF');
   line(ax,[tFixed tFixed],[0 100],...
      'LineWidth',1.5,'LineStyle',':',...
      'Color','m','DisplayName',sprintf('%s (ms)',llabel));
   line(ax,[0 max(tVec)],yRand,'LineWidth',2,...
      'Color','k','LineStyle','--',...
      'DisplayName','Random');
   
   if ii == 1
      ylabel(ax,'% Trials with Peak',...
         'FontName','Arial','Color','k','FontSize',18);
   end
   
   if ii == 2
      xlabel(ax,sprintf('%s (ms)',wlabel),'FontName','Arial','Color','k','FontSize',18);
   end
   
   if ii == 3
      title(ax,"BOTH",'FontName','Arial','Color','k','FontSize',24);
      legend(ax,...
         'FontName','Arial',...
         'TextColor','black',...
         'FontSize',14,...
         'EdgeColor','none',...
         'Color','white',...
         'Location',legLoc);
   else
      title(ax,TYPE(ii),'FontName','Arial','Color','k','FontSize',24);
   end
end

if ~isempty(tag)
   suptitle(strrep(tag,'_',' '));
end

if (nargout < 1) && ~isempty(tag)
   io.optSaveFig(fig,'figures/CDF',tag);
end

   function present = getPresent(t,time_window)
      %GETPRESENT Helper that returns boolean flag: did any peak fall in window?
      present = any((t >= time_window(1)) & (t < time_window(2)),2);
   end

end