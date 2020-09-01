function hl = addConnectingLine(ax,X,Y,params,varargin)
%ADDCONNECTINGLINE Add (annotated) line connecting point pairs <X,Y>
%
%  hg = utils.addConnectingLine(X,Y);
%  hg = utils.addConnectingLine(X,Y,params);
%  hg = utils.addConnectingLine(X,Y,[],'Name',value,...);
%  hg = utils.addConnectingLine(ax,__);
%
% Inputs
%  ax - (Optional) First argument can be given as target axes
%  X  - Vector containing 2 (or more) X-values to connect via line
%        -> If more than 2, this is called iteratively across consecutive
%              segment pairs.
%  Y  - Vector containing 2 (or more) Y-values to connect via line, with
%           same number of elements as X
%  params - Parameters struct, or [] if skipped
%  varargin - (Optional) 'Name',value pairs corresponding to modified
%                 versions of default params fields.
%
% Output
%  hl - Output line object
%
% See also: utils, cfg.gfx, utils.addPeakLabels, Figures, tbl.gfx

addParams = true;
if ~isa(ax,'matlab.graphics.axis.Axes')
   if nargin < 3
      params = cfg.gfx('FontParams','TimeIndicatorLineParams');
      Y = X;
      X = ax;
      ax = gca;
   elseif nargin < 4
      if isempty(Y)
         params = cfg.gfx('FontParams','TimeIndicatorLineParams');
      else
         params = Y;
         addParams = false;
      end
      Y = X;
      X = ax;
      ax = gca;
   else
      varargin = [params, varargin];
      if isempty(Y)
         params = cfg.gfx('FontParams','TimeIndicatorLineParams');
      else
         params = Y;
         addParams = false;
      end
      Y = X;
      X = ax;
      ax = gca;
   end
else
   if (nargin < 4) || isempty(params)
      params = cfg.gfx('FontParams','TimeIndicatorLineParams');
   else
      addParams = false;
   end
end

% % % PARAMS % % %
if addParams
   params.LabelHorizontalAlignment = 'right';
   params.LabelVerticalAlignment = 'top';
   params.LineAnnotation = 'off';
   params.LineDisplayName = '';
   params.Marker = 'none';
   params.Marker_Args = {}; % Miscellaneous other <'Name',value> pairs for utils.addPeakLabels
   params.Tag = '';
   params.XOffsetMultiplier = [0.025, -0.025];
   params.YOffsetMultiplier = [0.010, -0.010];
end
fn = fieldnames(params);
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      params.(fn{idx}) = varargin{iV+1};
   end  
end
% % END PARAMS % %

if numel(X) ~= numel(Y)
   error('X and Y must contain the same number of elements');
end

if numel(X) > 2
   hl = gobjects(numel(X)-1,1);
   for ii = 1:(numel(X)-1)
      subset = ii:(ii+1);
      hl(ii) = utils.addConnectingLine(ax,...
         X(subset),Y(subset),params,...
         'Tag',sprintf('%s%d',params.Tag,ii));
   end   
   return;
end

X = reshape(X,1,2);
Y = reshape(Y,1,2);

dX = X(2) - X(1);
dY = Y(2) - Y(1);

% Line start and stop points
xl = X + params.XOffsetMultiplier.*dX;
yl = Y + params.YOffsetMultiplier.*dY;

hl = line(ax,xl,yl,...
   params.TimeIndicatorLineParams{:},...
   'Marker','none',...
   'Tag',params.Tag,...
   'DisplayName',params.LineDisplayName);
hl.Annotation.LegendInformation.IconDisplayStyle = params.LineAnnotation;

xt = nanmean(xl);
yt = nanmean(yl);
utils.addPeakLabels(ax,dX,dY,[],...
   'HorizontalAlignment',params.LabelHorizontalAlignment,...
   'VerticalAlignment',params.LabelVerticalAlignment,...
   'Marker',params.Marker,...
   'FixedOffset',[xt - dX, yt - dY],...
   params.Marker_Args{:});

end