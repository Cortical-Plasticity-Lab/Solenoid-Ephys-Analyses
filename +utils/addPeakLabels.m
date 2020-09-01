function hg = addPeakLabels(ax,x,y,params,varargin)
%ADDPEAKLABELS Add labels denoting <x,y> value at list of peaks
%
%  hg = utils.addPeakLabels(x,y);
%  hg = utils.addPeakLabels(x,y,'Name',value,...);
%  hg = utils.addPeakLabels(ax,__);
%
% Inputs
%  x        - Scalar or vector of x-coordinate values
%  y        - Scalar or vector of y-coordinate values for each element of x
%  ax       - Target axes (if not specified, uses current axes).
%  params   - Parameters struct (or empty array if wanted to skip)
%  varargin - (Optional) 'Name' value argument pairs (see 'params' struct
%                          below in code)
%  
% Output
%  hg       - Array of graphics hggroup objects corresponding to number of 
%              matched <x,y> pairs
%     -> hg.Children(1): line object (single point indicating label point)
%     -> hg.Children(2): text object (label)
%
% See also: utils, tbl.gfx, Figures

addParams = true;
if ~isa(ax,'matlab.graphics.axis.Axes')
   if nargin < 3
      params = cfg.gfx('FontParams','TimeIndicatorLineParams');
      y = x;
      x = ax;
      ax = gca;
   elseif nargin < 4
      if isempty(y)
         params = cfg.gfx('FontParams','TimeIndicatorLineParams');
      else
         params = y;
         addParams = false;
      end
      y = x;
      x = ax;
      ax = gca;
   else
      varargin = [params, varargin];
      if isempty(y)
         params = cfg.gfx('FontParams','TimeIndicatorLineParams');
      else
         params = y;
         addParams = false;
      end
      y = x;
      x = ax;
      ax = gca;
   end
else
   if (nargin < 4) || isempty(params)
      params = cfg.gfx('FontParams','TimeIndicatorLineParams');
   else
      addParams = false;
   end
end

if numel(x) ~= numel(y)
   error('Each element of x must have a corresponding element of y.');
end

% % % PARAMS % % %
if addParams
   params.Color = nan;
   params.CoordinateSpec = '';
   params.CoordinateMarkerArgs = 1:4;
   params.FixedOffset = [0 0];
   params.GroupTagSpec = 'Peak-%03d'; % Should contain one integer specifier
   params.HorizontalAlignment = 'left';
   params.HorizontalOffsetMultiplier = 0.02;
   params.Marker = '';
   params.VerticalAlignment = 'bottom';
   params.VerticalOffsetMultiplier = 0.01;
   params.XCoordinate = '';
   params.YCoordinate = '';
end
fn = fieldnames(params);
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      params.(fn{idx}) = varargin{iV+1};
   end
end
[xc,yc,spec] = parseCoordinateStringFormat(ax,params);
% % % END PARAMS % 

hg = gobjects(numel(x),1);
if isempty(params.Color) || isnan(params.Color(1))
   c = findobj(ax.Children,'Type','line');
   if ~isempty(c)
      params.Color = c(1).Color;
   else
      params.Color = [0 0 0];
   end
end

dx = diff(ax.XLim);
ox = dx*params.HorizontalOffsetMultiplier;
if strcmpi(params.HorizontalAlignment,'right')
   ox = -1 * ox;
end
dy = diff(ax.YLim);
oy = dy*params.VerticalOffsetMultiplier;
if strcmpi(params.VerticalAlignment,'top') || strcmpi(params.VerticalAlignment,'cap')
   oy = -1 * oy;
end

if isempty(params.Marker)
   iMarker = find(strcmpi(params.TimeIndicatorLineParams(1:3:end),'Marker'),1,'first');
   if isempty(iMarker)
      params.Marker = 'v';
   else
      params.Marker = params.TimeIndicatorLineParams{iMarker+1};
   end
end

for ii = 1:numel(x)
   args = {xc,x(ii),yc,y(ii)};
   str = sprintf(spec,args{params.CoordinateMarkerArgs});
   hg(ii) = hggroup(ax,'Tag',sprintf(params.GroupTagSpec,ii));
   tx = x(ii) + ox + params.FixedOffset(1);
   ty = y(ii) + oy + params.FixedOffset(2);
   text(tx,ty,str,...
      'Color',params.Color,...
      'HorizontalAlignment',params.HorizontalAlignment,...
      'VerticalAlignment',params.VerticalAlignment,...
      'Parent',hg(ii),...
      params.FontParams{:},...
      'FontWeight','bold');
   line(x(ii),y(ii),params.TimeIndicatorLineParams{:},...
      'Marker',params.Marker,...
      'LineStyle','none',...
      'MarkerFaceColor',params.Color,...
      'Parent',hg(ii));
end

   function [xc,yc,spec] = parseCoordinateStringFormat(ax,params)
      %PARSECOORDINATESTRINGFORMAT Parse fields of axes UserData &
      %  parameters struct in order to get the formatting for printing the
      %  x-y coordinate pair with labeled abscissae.
      %
      %  [xc,yc,spec] = parseCoordinateStringFormat(ax,params);
      
      if isa(ax.UserData,'struct')
         if ~isempty(params.XCoordinate)
            xc = params.XCoordinate;
         elseif isfield(ax.UserData,'XCoordinate')
            xc = ax.UserData.XCoordinate;
         else
            xc = '';
         end

         if ~isempty(params.YCoordinate)
            yc = params.YCoordinate;
         elseif isfield(ax.UserData,'YCoordinate')
            yc = ax.UserData.YCoordinate;
         else
            yc = '';
         end

         if ~isempty(params.CoordinateSpec)
            spec = params.CoordinateSpec;
         elseif isfield(ax.UserData,'CoordinateSpec')
            spec = ax.UserData.CoordinateSpec;
         else
            spec = '%s%5.2f, %s%5.2f';
         end
      else
         if isempty(params.XCoordinate)
            xc = '';
         else
            xc = params.XCoordinate;
         end

         if isempty(params.YCoordinate)
            yc = '';
         else
            yc = params.YCoordinate;
         end

         if isempty(params.CoordinateSpec)
            spec = '%s%5.2f, %s%5.2f';
         else
            spec = params.CoordinateSpec;
         end
      end
   end

end