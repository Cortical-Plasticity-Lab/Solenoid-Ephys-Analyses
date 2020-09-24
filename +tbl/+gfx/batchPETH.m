function fig = batchPETH(T,surgID,solOnset,solOffset,icmsOnset,varargin)
%BATCHPETH Create batch PETH for a single animal with all condition combos
%
%  fig = tbl.gfx.batchPETH(T,surgID,solOnset,solOffset,icmsOnset)
%  fig = tbl.gfx.batchPETH(T,surgID,solOnset,solOffset,icmsOnset,'Name',value,...)
%
% Inputs
%  T - Main database table, with event times rounded to nearest millisecond
%  surgID - Surgical ID (string) for animal to look at
%  solOnset - Time (sec) of solenoid strike
%  solOffset - Time (sec) of solenoid retraction
%  icmsOnset - Time (sec) of ICMS pulse
%  varargin - (Optional) 'Name',value argument pairs
%     XLim - x-limits (ms) of each axes (default: [-100 200])
%     YLim - y-limits (ms) of each axes (default: [0 2])
%     Type - default: {"Solenoid","ICMS","Solenoid + ICMS"}
%     Area - default: {"S1","RFA"}
%
% Output
%  fig - Figure handle that has 6 subplots in 2 rows of 3 columns.
%           Rows: Solenoid | ICMS | Solenoid + ICMS
%           Columns: S1 | RFA
%
% See also: Contents, tbl, utils, tbl.gfx.PETH

pars = struct;
pars.AxesParams = cfg.gfx('AxesParams');
pars.Position = [0.1 0.1 0.8 0.8];
pars.XLim = [-100 200];
pars.YLim = [0 40];
pars.Area = ["S1","RFA"];
pars.Type = ["Solenoid","ICMS","Solenoid + ICMS"];
fn = fieldnames(pars);
iRemove = [];
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
      iRemove = [iRemove, iV, iV+1]; %#ok<AGROW>
   end
end
varargin(iRemove) = [];

fig = figure('Name',sprintf('%s: PETH',surgID),...
   'Color','w',...
   'Units','Normalized',...
   'Position',pars.Position);
T = utils.roundEventTimesToNearestMillisecond(T);

nRow = numel(pars.Area);
nCol = numel(pars.Type);
ii = 0;
fprintf(1,'Generating panelized <strong>%s</strong> PETH results\n',surgID);
fprintf(1,'->\t(ICMS: <strong>%03d-ms</strong> | Solenoid <strong>%03d-ms : %03d-ms</strong>)\n',...
   icmsOnset*1e3,solOnset*1e3,solOffset*1e3);

for iRow = 1:nRow
   for iCol = 1:nCol
      ii = ii + 1;
      ax = subplot(nRow,nCol,ii);
      set(ax,pars.AxesParams{:},'Parent',fig);
      filtArgs = parseFiltArgs(surgID,pars.Type(iCol),pars.Area(iRow),...
                     solOnset,solOffset,icmsOnset);
      fprintf(1,'\t->\tMaking PETH for %s::%s...',pars.Area(iRow),pars.Type(iCol));
      try
         tbl.gfx.PETH(ax,T,filtArgs,'XLim',pars.XLim,'YLim',pars.YLim,varargin{:});
      catch me % Catch error object
         if strcmp(me.identifier,'GFX:PETH:NoTableRows')
            if ~ismember(surgID,T.SurgID)
               causeException = MException(...
                  'MATLAB:batchPETH:BadFiltArgs',...
                  sprintf('Unknown SurgID value: "%s"',surgID));
            else
               tmp = T(T.SurgID==surgID,:);
               if ismember(solOnset,tmp.Solenoid_Onset)
                  if ismember(solOffset,tmp.Solenoid_Offset)
                     if ismember(icmsOnset,tmp.ICMS_Onset)
                        utils.findUniqueEventCombinations(tmp);
                        causeException = MException(...
                           'MATLAB:batchPETH:BadFiltArgs',...
                           'Invalid combination of SolenoidOnset, SolenoidOffset, and ICMS Onset values');  
                     else
                        causeException = MException(...
                           'MATLAB:batchPETH:BadFiltArgs',...
                           sprintf('Bad ICMS_Onset value: %4.3f',icmsOnset));    
                     end
                  else
                     causeException = MException(...
                           'MATLAB:batchPETH:BadFiltArgs',...
                           sprintf('Bad Solenoid_Offset value: %4.3f',solOffset));   
                  end
               else
                  causeException = MException(...
                     'MATLAB:batchPETH:BadFiltArgs',...
                     sprintf('Bad Solenoid_Onset value: %4.3f',solOnset));                  
               end
            end
            me = addCause(me,causeException);
         end
         fprintf(1,'\n\n<strong>Stack top-level</strong> <a href="matlab:opentoline(''%s'',%d);">(link)</a>\n',...
            me.stack(1).file,me.stack(1).line);
         disp(me.stack(1));
         if numel(me.stack) > 1
            fprintf(1,'<strong>Stack 2nd-level</strong> <a href="matlab:opentoline(''%s'',%d);">(link)</a>\n',...
               me.stack(2).file,me.stack(2).line);
            disp(me.stack(2));
         end
         rethrow(me);
      end
      title(ax,sprintf('%s::%s',pars.Area(iRow),pars.Type(iCol)),...
         'FontName','Arial','Color','k');
      fprintf(1,'complete\n');
      drawnow;
   end
end
titleStr = sprintf(...
   ['(\\bf%s\\rm)      ' ...
    '\\itICMS\\rm \\bf%3d\\rm-ms | ' ...
    '\\itSolenoid\\rm \\bf%3d\\rm-ms : \\bf%3d\\rm-ms'],...
   surgID,...
   icmsOnset*1e3,...
   solOnset*1e3,...
   solOffset*1e3);
suptitle(titleStr);

   function filtArgs = parseFiltArgs(surgID,type,area,solOnset,solOffset,icmsOnset)
      %PARSEFILTARGS Helper function to return correct combination of filter arguments, which depends on `Type`
      %
      %  filtArgs = parseFiltArgs(type,area,solOnset,solOffset,icmsOnset);
      
      if isnumeric(type)
         type = string(cfg.TrialType(type));
      end
      switch lower(char(type))
         case 'solenoid'
            filtArgs = {'SurgID',surgID,'Type',"Solenoid",'Area',area,...
               'Solenoid_Onset',solOnset,'Solenoid_Offset',solOffset};
         case 'icms'
            filtArgs = {'SurgID',surgID,'Type',"ICMS",'Area',area,...
               'ICMS_Onset',icmsOnset};
         case {'solenoid + icms','solenoid+icms','solenoid +icms','solenoid+ icms'}
            filtArgs = {'SurgID',surgID,'Type',"Solenoid + ICMS",'Area',area,...
               'Solenoid_Onset',solOnset,'Solenoid_Offset',solOffset,...
               'ICMS_Onset',icmsOnset};
         otherwise
            error('Unrecognized `Type`: %s',type);
      end
   end

end