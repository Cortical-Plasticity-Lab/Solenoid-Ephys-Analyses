function TID = batchChannelPETH(T,varargin)
%BATCHCHANNELPETH Batch save individual channel responses
%
%  Figures.batchChannelPETH(T);
%  TID = Figures.batchChannelPETH(T,__,'Name',value,...);
%
% Inputs
%  T           - Main data table
%  varargin    - (Optional) 'Name',value pairs (see tbl.gfx.batchPETH)
%
% Output
%  TID         - Table giving the groupings for exported figures.
%
%  Batch saves figures by individual combination of Channel and Block to
%  the location specified by `FIGURE_OUTPUT_PATH`
%
% See also: Contents, tbl, tbl.gfx.batchPETH, tbl.gfx.PETH

FIGURE_OUTPUT_PATH = 'P:\Rat\BilateralReach\Solenoid Experiments\Figures';
FIGURE_POSITION = [1.015 0.225 0.785 0.400];

T = utils.roundEventTimesToNearestMillisecond(T);

% Create anonymous function to use with splitapply
args = varargin;
fun = @(varargin)wrapFun(table(varargin{:},'VariableNames',T.Properties.VariableNames),...
   FIGURE_OUTPUT_PATH,T.Properties.UserData,T.Properties.VariableUnits,...
   FIGURE_POSITION,args{:});
[G,TID] = findgroups(T(:,{'SurgID','BlockID','ChannelID'}));
splitapply(fun,T,G);

   function wrapFun(T,outPath,UserData,VariableUnits,FIGURE_POSITION,varargin)
      %WRAPFUN Wrapper function that causes individual figures to be saved and deleted sequentially rather than at the very end
      
      T.Properties.UserData = UserData;
      T.Properties.VariableUnits = VariableUnits;
      
      surgID = string(T.SurgID(1));
      ch = T.ChannelID(1);
      bk = string(T.BlockID(1));
      
      solOnset = T.Solenoid_Onset((~isnan(T.Solenoid_Onset)) & (~isinf(T.Solenoid_Onset)));
      solOffset = T.Solenoid_Offset((~isnan(T.Solenoid_Offset)) & (~isinf(T.Solenoid_Offset)));
      icmsOnset = T.ICMS_Onset((~isnan(T.ICMS_Onset)) & (~isinf(T.ICMS_Onset)));
      
      if isempty(solOnset) || isempty(solOffset) || isempty(icmsOnset)
         fprintf(1,'%s: %s (Block: %s) <strong>skipped</strong>\n',surgID,ch,bk);
         return;
      else
         solOnset = solOnset(1);
         solOffset = solOffset(1);
         icmsOnset = icmsOnset(1);
      end
      
      
      a = string(T.Area(1));
      d = round(T.Depth(1));
      id = string(T.AnimalID(1));
      
      fig = tbl.gfx.batchPETH(T,surgID,solOnset,solOffset,icmsOnset,...
         'Area',a,...
         'XLim',[],...
         'YLim',[0 40],...
         'SGOrder',5,...
         'SGLen',21,...
         'Position',FIGURE_POSITION, ...
         varargin{:});
      h = findobj(fig.Children,'Type','axes');
      for ii = 1:numel(h)
         title(h(ii),'');
      end
      set(fig,'Name',[strcat(get(fig,'Name')," - ",bk)]);
      titleStr = sprintf(...
         ['(\\bf%s\\rm)      ' ...
          '\\itICMS\\rm \\bf%3d\\rm-ms | ' ...
          '\\itSolenoid\\rm \\bf%3d\\rm-ms : \\bf%3d\\rm-ms | ' ...
          '\\it%d-\\mum\\rm        (\\bf%s\\rm::\\it%s\\rm)'],...
         surgID,icmsOnset*1e3,solOnset*1e3,solOffset*1e3,d,id,ch);
      suptitle(titleStr);
      
      % Save
      pOut = fullfile(outPath,bk);
      if exist(pOut,'dir')==0
         mkdir(pOut);
      end
      saveas(fig,fullfile(pOut,strcat(ch,".png")));
      savefig(fig,fullfile(pOut,strcat(ch,".fig")));
      delete(fig);
   end


end