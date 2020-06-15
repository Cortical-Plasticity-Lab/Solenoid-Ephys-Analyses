function varargout = gfx(varargin)
%GFX  Return defaults struct for functions in tbl.gfx package
%
%  params = cfg.gfx();
%     * This format returns full struct of parameters.
%     e.g.
%     >> params.var1 == 'something'; params.var2 == 'somethingelse'; ...
%
%  [var1,var2,...] = cfg.gfx('var1Name','var2Name',...);
%     * This format returns as many output arguments as input arguments, so
%        you can select to return variables for only the desired variables
%        (just up to preference).

% Change default fields here
p = struct;
p.Figure = [];
p.Axes   = [];

p.ColorOrder = [0.0 0.0 0.0; ...
                0.1 0.1 0.9; ...
                0.9 0.1 0.1; ...
                0.8 0.0 0.8; ...
                0.4 0.4 0.4; ...
                0.5 0.6 0.0; ...
                0.0 0.7 0.7];
p.FigureParams = {'Color','w','Units','Normalized','Position',[0.2 0.2 0.5 0.5]};
p.AxesParams = {'NextPlot','add','XColor','k','YColor','k','LineWidth',1.25,'ColorOrder',p.ColorOrder};
p.ScatterParams = {'Marker','o','MarkerFaceColor','flat','MarkerFaceAlpha',0.75};
p.FontParams = {'FontName','Arial','Color','k'};

% Parse output (don't change this part)
if nargin < 1
   varargout = {p};   
else
   F = fieldnames(p);   
   if (nargout == 1) && (numel(varargin) > 1)
      varargout{1} = struct;
      for iV = 1:numel(varargin)
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{1}.(F{idx}) = p.(F{idx});
         end
      end
   elseif nargout > 0
      varargout = cell(1,nargout);
      for iV = 1:nargout
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{iV} = p.(F{idx});
         end
      end
   else % Otherwise no output args requested
      varargout = {};
      for iV = 1:nargin
         idx = strcmpi(F,varargin{iV});
         if sum(idx) == 1
            fprintf('<strong>%s</strong>:',F{idx});
            disp(p.(F{idx}));
         end
      end
      clear varargout; % Suppress output
   end
end
end