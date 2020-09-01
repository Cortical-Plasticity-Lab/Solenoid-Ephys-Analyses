function expAI(fig,filename,varargin)
%EXPAI export figure in appropriate format for Adobe Illustrator
%
%  utils.expAI(filename); % Uses gcf for fig
%  utils.expAI(fig,filename);
%  utils.expAI(figl,filename,'NAME',value,...);
%
%   --------
%    INPUTS
%   --------
%      fig      :   Handle to the figure you wish to export.
%
%   filename    :   String with output filename (and extension) of figure
%                   to export for Adobe Illustrator.
%
%   varargin    :   Optional 'NAME', value input argument pairs.
%
%   --------
%    OUTPUT
%   --------
%   A second file with the same name for use with Adobe Illustrator.

% DEFAULT PARAMETERS
%Note: default configuration should work well for AI export as is.

%Boolean options
FORMATFONT  = false;                  %Automatically reconfigure axes fonts
% OPENFIG     = true;                 %Automatically open new fig in AI

%Figure property modifiers
FONTNAME = 'Arial';                 %Set font name (if FORMATFONT true)
FONTSIZE = 16;                      %Set font size (if FORMATFONT true)

%Print function modifiers
% FORMATTYPE  = '-dpsc2';             % Vector output format
% FORMATTYPE = '-dpdf';               % Full-page PDF
% FORMATTYPE = '-dsvg';               % Scaleable vector graphics format
% FORMATTYPE = '-dpsc';               % Level 3 full-page PostScript, color
% FORMATTYPE = '-dmeta';              % Enhanced Metafile (WINDOWS ONLY)
FORMATTYPE = '-depsc';              % EPS Level 3 Color
% FORMATTYPE = '-dtiffn';             % TIFF 24-bit (not compressed)
UIOPT       = '-noui';              % Excludes UI controls
% FORMATOPT   = '-cmyk';              % Format options for color
% FORMATOPT   = '-loose';             % Use loose bounding box
RENDERER    = '-painters';          % Graphics renderer
% RESIZE      = '-fillpage';          % Alters aspect ratio
% RESIZE      = '-bestfit';           % Choose best fit to page
RESOLUTION  = '-r600';              % Specify dots per inch (resolution)

if ~isa(fig,'matlab.ui.Figure')
   if nargin < 2
      filename = fig;
      fig = gcf;
   else
      varargin = [filename, varargin];
      filename = fig;
      fig = gcf;
   end
end

[pname,fname,ext] = fileparts(filename);
if strcmp(ext, '.tif')
   FORMATTYPE = '-dtiffn';
elseif strcmp(ext,'.ps')
   FORMATTYPE = '-dpsc2';
elseif strcmp(ext, '.svg')
   FORMATTYPE = '-dsvg';
elseif strcmp(ext, '.pdf')
   FORMATTYPE = '-dpdf';
elseif strcmp(ext,'.eps')
   FORMATTYPE = '-depsc';
end

% PARSE VARARGIN
for iV = 1:2:length(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

% GET CORRECT OUTPUT FILE EXTENSION
if strcmp(FORMATTYPE, '-dtiffn')
   ext = '.tif';
elseif strcmp(FORMATTYPE, '-dpsc2')
   ext = '.ps';
elseif strcmp(FORMATTYPE, '-dsvg')
   ext = '.svg';
elseif strcmp(FORMATTYPE, '-dpdf')
   ext = '.pdf';
elseif strcmp(FORMATTYPE,'-depsc')
   ext = '.eps';
else
   ext = '.ai';
end

filename = fullfile(pname,[fname ext]);

% MODIFY FIGURE PARAMETERS
set(gcf, 'Renderer', RENDERER(2:end));
if FORMATFONT
   c = get(gcf, 'Children');
   for iC = 1:length(c)
      set(c(iC),'FontName',FONTNAME);
      set(c(iC),'FontSize',FONTSIZE);
   end
end

% OUTPUT CONVERTED FIGURE
version_test = ver;
idx = ismember({version_test.Name},'MATLAB');
if str2double(version_test(find(idx,1,'first')).Version) >= 9.7
   if exist('FORMATOPT','var')==0
      print(fig,...
         filename, ...
         FORMATTYPE,...
         RENDERER);
   else
      print(fig,...
         filename, ...
         FORMATTYPE,...
         FORMATOPT,...
         RENDERER);
   end
      
else
   if exist('RESIZE','var')==0
      
      print(fig,          ...
         ...      RESIZE,       ...
         RESOLUTION,   ...
         FORMATTYPE,   ...
         UIOPT,        ...
         ...      FORMATOPT,    ...
         RENDERER,     ...
         filename);
   else
      if exist('FORMATOPT','var')==0
         print(fig,          ...
            RESIZE,       ...
            RESOLUTION,   ...
            FORMATTYPE,   ...
            UIOPT,        ...
            ...      FORMATOPT,    ...
            RENDERER,     ...
            filename);
      else
         print(fig,          ...
            RESIZE,       ...
            RESOLUTION,   ...
            FORMATTYPE,   ...
            UIOPT,        ...
            FORMATOPT,    ...
            RENDERER,     ...
            filename);
      end
   end
end
end