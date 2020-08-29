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

txt = string(type);
ch = unique(T.ChannelID);
stimch = unique(T.Stim_Ch);

switch txt
   case "ICMS"
      ys = 1;
      if numel(ch) == 1
         if any(ismember(ch,stimch))
            utils.addTimeIndicatorToAxes(ax,T,'ICMS_Onset',params,...
               'Color',[0.75 0.75 0.25],...
               'DisplayName','ICMS',...
               'Tag','ICMS');
         else
            utils.addTimeIndicatorToAxes(ax,T,'ICMS_Onset',params,...
               'Color',params.Color,...
               'DisplayName','ICMS',...
               'Tag','ICMS');
         end
      end
      utils.addTextToAxes(ax,txt,txtLoc,'Color',params.Color,'Y_SCALE',ys);
   case "Solenoid"
      lineObj = utils.addSolenoidToAxes(ax,T,params);
      txtObj = utils.addTextToAxes(ax,txt,'south','Color',params.Color);
      updateSolenoidLabelPosition(ax,txtObj,lineObj);
   case "Solenoid + ICMS" 
      lineObj = utils.addSolenoidToAxes(ax,T,params);
      if numel(ch) == 1
         if any(ismember(ch,stimch))
            utils.addTimeIndicatorToAxes(ax,T,'ICMS_Onset',params,...
               'Color',[0.75 0.75 0.25],...
               'DisplayName','ICMS',...
               'Tag','ICMS');
         else
            utils.addTimeIndicatorToAxes(ax,T,'ICMS_Onset',params,...
               'Color',params.Color,...
               'DisplayName','ICMS',...
               'Tag','ICMS');
         end
      end
      txtObj = utils.addTextToAxes(ax,txt,'south','Color',params.Color);
      updateSolenoidLabelPosition(ax,txtObj,lineObj);
   otherwise
      error('Invalid value of type (%f)',double(type));
end

   function updateSolenoidLabelPosition(ax,txtObj,lineObj)
      lx = nanmean(lineObj.XData);
      ly = 0.05*(ax.YLim(2)-lineObj.YData(1))+lineObj.YData(1);
      set(txtObj,'Position',[lx,ly,0]);
   end

end