function addStimInfoToAxes(ax,T,params,txtLoc,varargin)
%ADDSTIMINFOTOAXES   Add information about stimulus-type, timing, and if ICMS occurred on this channel.
%
%  utils.addStimInfoToAxes(ax,T,params,'Name',value,...);
%
% Inputs
%  ax       - Axes handle
%  T        - Master data table (after "slicing" has been applied)
%  params   - Parameters struct, requires following fields:
%              * 'Color' [r,g,b] 1x3 vector values on range [0,1]
%              
%  txtLoc   - (Optional) 'southwest' (def) | 'south' | ... see
%                 utils.addTextToAxes
%  varargin - (Optional) 'Name',value input argument pairs
%
% Output
%  -- none -- Just modifies axes input by `ax`
%
% See also: utils, utils.addTextToAxes, tbl.gfx, tbl.gfx.PEP, tbl.gfx.PETH

if nargin < 3
   params = cfg.gfx();
end

if nargin < 4
   txtLoc = 'south';
end

type = unique(T.Type);
if numel(type)>1
   for iType = 1:numel(type)
      utils.addStimInfoToAxes(ax,T(T.Type==type(iType),:),params,varargin{:});
   end
   return;
end

txt = strrep(string(type),'_',' ');
ch = unique(T.ChannelID);
stimch = unique(T.Stim_Ch);
tICMS_Onset = unique(T.ICMS_Onset);
tSolenoid_Onset = unique(T.Solenoid_Onset);
tSolenoid_Offset = unique(T.Solenoid_Offset);
probeData = char(T.ChannelID(1));
areaData = string(T.Area(1));
switch probeData(1)
   case 'A'
      switch areaData
         case "RFA"
            probeArea = struct('A',"RFA",'B',"S1",'N',"None");
         case "CFA"
            probeArea = struct('A',"CFA",'B',"S1",'N',"None");
         case "S1"
            probeArea = struct('A',"S1",'B',"RFA",'N',"None");
      end
      
   case 'B'
      switch areaData
         case "RFA"
            probeArea = struct('A',"S1",'B',"RFA",'N',"None");
         case "CFA"
            probeArea = struct('A',"S1",'B',"CFA",'N',"None");
         case "S1"
            probeArea = struct('A',"RFA",'B',"S1",'N',"None");
      end
      
   otherwise
      error('Invalid ChannelID: %s',T.ChannelID(1));
end

switch txt
   case "ICMS"
      if numel(tICMS_Onset) == 1
         if any(ismember(ch,stimch))
            utils.addTimeIndicatorToAxes(ax,T,'ICMS_Onset',params,...
               'Color',[0.75 0.25 0.25],...
               'LineWidth',2.5,...
               'DisplayName','ICMS',...
               'Tag','ICMS');
            s = char(stimch(1));
            text(ax,tICMS_Onset*1e3,diff(ax.YLim)*0.66+ax.YLim(1),...
               sprintf('ICMS (%s)',probeArea.(s(1))),...
               'FontName','Arial',...
               'Color',[0.75 0.25 0.25],...
               'BackgroundColor','w');
            box(ax,'on');
            set(ax,'XColor',[0.75 0.25 0.25],'YColor',[0.75 0.25 0.25]);
         else
            utils.addTimeIndicatorToAxes(ax,T,'ICMS_Onset',params,...
               'Color',[0.35 0.35 0.35],...
               'LineWidth',1.25,...
               'DisplayName','ICMS',...
               'Tag','ICMS');
            s = char(stimch(1));
            text(ax,tICMS_Onset*1e3,diff(ax.YLim)*0.66+ax.YLim(1),...
               sprintf('ICMS (%s)',probeArea.(s(1))),...
               'FontName','Arial',...
               'Color',[0.35 0.35 0.35],...
               'BackgroundColor','w');
         end
      end
      
   case "Solenoid"
      if (numel(tSolenoid_Onset)==1) && (numel(tSolenoid_Offset)==1)
         lineObj = utils.addSolenoidToAxes(ax,T,params);
      end
      txtObj = utils.addTextToAxes(ax,txt,'south','Color',params.Color);
      updateSolenoidLabelPosition(ax,txtObj,lineObj);
   case "Solenoid + ICMS" 
      if (numel(tSolenoid_Onset)==1) && (numel(tSolenoid_Offset)==1)
         lineObj = utils.addSolenoidToAxes(ax,T,params);
      end
      if numel(tICMS_Onset) == 1
         if any(ismember(ch,stimch))
            utils.addTimeIndicatorToAxes(ax,T,'ICMS_Onset',params,...
               'Color',[0.75 0.25 0.25],...
               'LineWidth',2.5,...
               'DisplayName','ICMS',...
               'Tag','ICMS');
            s = char(stimch(1));
            text(ax,tICMS_Onset*1e3,diff(ax.YLim)*0.66+ax.YLim(1),...
               sprintf('ICMS (%s)',probeArea.(s(1))),...
               'FontName','Arial',...
               'Color',[0.75 0.25 0.25],...
               'BackgroundColor','w');
            box(ax,'on');
            set(ax,'XColor',[0.75 0.25 0.25],'YColor',[0.75 0.25 0.25]);
         else
            utils.addTimeIndicatorToAxes(ax,T,'ICMS_Onset',params,...
               'Color',[0.35 0.35 0.35],...
               'LineWidth',1.25,...
               'DisplayName','ICMS',...
               'Tag','ICMS');
            s = char(stimch(1));
            text(ax,tICMS_Onset*1e3,diff(ax.YLim)*0.66+ax.YLim(1),...
               sprintf('ICMS (%s)',probeArea.(s(1))),...
               'FontName','Arial',...
               'Color',[0.35 0.35 0.35],...
               'BackgroundColor','w');
         end
      end
      txtObj = utils.addTextToAxes(ax,'Solenoid',txtLoc,'Color',params.Color);
      updateSolenoidLabelPosition(ax,txtObj,lineObj);
   otherwise
      error('Invalid value of type (%f)',double(type));
end

   function updateSolenoidLabelPosition(ax,txtObj,lineObj)
      lx = nanmean(lineObj.XData);
      ly = 0.15*(ax.YLim(2)-lineObj.YData(1))+lineObj.YData(1);
      set(txtObj,'HorizontalAlignment','center','Position',[lx,ly,0]);
   end

end