classdef figBrowser < handle
   %FIGBROWSER  Handle class for viewing figures
   %
   %   h = FIGBROWSER(solRatObj);
   %
   %  This is a tool for scanning through different graphics and
   %  re-exporting them in high-resolution if needed.
   
   properties (Access = public)
      Rat         % Currently-selected rat
      Menu        % "Menu" figure graphics object handle
      FigViewer   % "Viewer" figure graphics object handle
      CurFile     % Current file to be loaded
   end
   
   properties (Access = private)
      curRat    % Path to current rat folder
      curBlock  % Block name (within rat folder)
      curFig    % Figure file 
      
      Buttons        % struct with pushbutton uicontrol graphics objects
      ratMenu        % uicontrol listbox handle
      blockMenu      % uicontrol listbox handle
      figMenu        % uicontrol listbox handle
   end
   
   methods (Access = public)
      % Class constructor
      function obj = figBrowser(p)
         %FIGBROWSER Constructor for figBrowser object for viewing figures
         %
         %  obj = figBrowser(p);
         %
         % Inputs
         %  p - Scalar or array of solRat objects
         %
         % Output
         %  obj - figBrowser scalar object, which allows curation of PETH,
         %        IFR plots, and LFP plots. Requires user to be mapped to
         %        the KUMC Isilon Processed_Data network drives.
         
         if ~isa(p,'solRat')
            error('Input must be of class SOLRAT');
         end
         
         obj.Rat = p;
         obj.buildFigViewer;
         obj.buildMenu;
         p.setFB(obj);
      end
      
      % OVERLOAD OPEN method
      function open(obj)
         %OPEN Overloaded method for opening figures
         %
         %  open(obj);
         %
         % Inputs
         %  obj - Scalar figBrowser object
         %
         % Output
         %  -- none -- Simply builds the figure viewer and menu
         
         buildFigViewer(obj);
         if ~isvalid(obj.Menu)
            buildMenu(obj);
         end
      end
   end
   
   % Protected callback methods
   methods (Access = protected)
      % Method called when block menu value is changed
      function blockChangedCB(obj,src,~)
         %BLOCKCHANGEDCB Callback executed when block menu value is changed
         %
         %  obj.blockMenu.Callback = @obj.blockChangedCB;
         %
         % Updates list of potential figures when the Block Menu value is
         % changed.
         
         obj.curBlock = src.String{src.Value};
         F = dir(fullfile(obj.curRat,...
                     obj.curBlock,...
                     [obj.curBlock '_Figures'],...
                     cfg.default('fig_type_for_browser'),...
                     '*.fig'));
         
         if ~isempty(obj.figMenu)
            if isvalid(obj.figMenu)
               obj.figMenu.Value = 1;
               if isempty(F)
                  obj.figMenu.String = {''};
               else
                  obj.figMenu.String = {F.name}.';
               end
               obj.figChangedCB(obj.figMenu);
            end
         end
      end
      
      % Method called when fig menu value is changed
      function figChangedCB(obj,src,~)
         %FIGCHANGEDCB Callback executed when fig menu value is changed
         %
         %  obj.figMenu.Callback = @obj.figChangedCB;
         %
         % Updates reference to current figure string so if load button is
         % clicked it loads the corresponding figure.
         
         obj.curFig = src.String{src.Value};
      end
      
      % Method called by LOAD PUSHBUTTON callback
      function loadFigCB(obj,~,~)
         %LOADFIGCB Callback invoked by the "Load" button
         %
         %  loadPushButton.Callback = @obj.loadFigCB;
         %
         % Load the correct figure when `Load` pushbutton is clicked in the
         % figure selection menu (obj.Menu)
         
         obj.CurFile = fullfile(...
            obj.curRat,...
            obj.curBlock,...
            [obj.curBlock '_Figures'],...
            cfg.default('fig_type_for_browser'),...
            obj.curFig);
         
         if exist(obj.CurFile,'file')==0
            fprintf(1,'No such file:\n%s\n',obj.CurFile);
            return;
         else
            fprintf(1,'Loading %s...',obj.curFig);
         end            
         
         oldFig = openfig(obj.CurFile,'reuse','invisible');
         c = get(oldFig,'Children');
         
         obj.buildFigViewer; % Make sure it is valid
         clf(obj.FigViewer);
         copyobj(c,obj.FigViewer);
         set(obj.FigViewer,'Name',obj.curFig(1:(end-4)));
         delete(oldFig);
         fprintf(1,'successful\n');
      end
      
      % Method for capturing key presses
      function keyCaptureCB(obj,~,evt)
         %KEYCAPTURECB Method for capturing key presses
         %
         %  obj.Menu.ButtonDownFcn = @obj.keyCaptureCB;
         %
         % Creates responses to key presses when menu has focus. Current
         % buttons are:
         %  {'rightarrow','d'} : Increase value of figMenu by 1
         %  {'leftarrow','a'}  : Decrease value of figMenu by 1
         %  {'uparrow','w'}    : Decrease value of blockMenu by 1
         %  {'downarrow','s'}  : Increase value of blockMenu by 1
         
         switch evt.Key
            case {'rightarrow','d'} % Increase Value of figMenu by 1
               val = obj.figMenu.Value + 1;
               str = obj.figMenu.String;
               Value = figBrowser.parseMenuValue(val,str);
               
               obj.figMenu.Value = Value;
               obj.figChangedCB(obj.figMenu);
               obj.loadFigCB;
            case {'leftarrow','a'} % Decrease Value of figMenu by 1
               val = obj.figMenu.Value - 1;
               str = obj.figMenu.String;
               Value = figBrowser.parseMenuValue(val,str);
               
               obj.figMenu.Value = Value;
               obj.figChangedCB(obj.figMenu);
               obj.loadFigCB;
            case {'uparrow','w'} % Decrease Value of blockMenu by 1
               val = obj.blockMenu.Value - 1;
               str = obj.blockMenu.String;
               Value = figBrowser.parseMenuValue(val,str);
               
               obj.blockMenu.Value = Value;
               obj.blockChangedCB(obj.blockMenu);
               obj.loadFigCB;
            case {'downarrow','s'} % Increase Value of blockMenu by 1
               val = obj.blockMenu.Value + 1;
               str = obj.blockMenu.String;
               Value = figBrowser.parseMenuValue(val,str);
               
               obj.blockMenu.Value = Value;
               obj.blockChangedCB(obj.blockMenu);
               obj.loadFigCB;
         end
      end
      
      % Method called when MENU is closed
      function menuClosedCB(obj,~,~)
         %MENUCLOSEDCB Method called when MENU is closed
         %
         %  obj.Menu.DeleteFcn = @obj.menuClosedCB;
         %
         % Ensures that if the menu for selecting which figure to load is
         % closed, the "FigViewer" object and browser object are deleted.
         
         if ~isempty(obj.FigViewer)
            if isvalid(obj.FigViewer)
               close(obj.FigViewer);
            end
         end
      end
      
      % Method called when rat menu value is changed
      function ratChangedCB(obj,src,~)
         %RATCHANGEDCB Called when rat menu value is changed
         %
         %  graphicsObj.Callback = @obj.ratChangedCB;
         
         obj.curRat = obj.Rat(src.Value).folder;
         F = dir(fullfile(obj.curRat,[char(obj.Rat(src.Value).Name) '*']));
         if ~isempty(obj.blockMenu)
            if isvalid(obj.blockMenu)
               obj.blockMenu.Value = 1;
               obj.blockMenu.String = {F.name}.';
               obj.blockChangedCB(obj.blockMenu);
            end
         end
      end
      
      
   end
   
   % Private methods used during class initiation
   methods (Access = private)
      % Method to build the figure "VIEWER" window
      function buildFigViewer(obj)
         %BUILDFIGVIEWER Method that creates "viewer" graphics
         %
         %  buildFigViewer(obj);
         %
         % Inputs
         %  obj - Scalar `figBrowser` object
         %
         % Creates the `FigViewer` property object, which is a figure that
         % contains the currently-loaded data graphic.
         
         
         if isempty(obj.FigViewer)
            obj.FigViewer = figure('Name','Figure Viewer',...
                  'NumberTitle','off',...
                  'Color','w',...
                  'Units','Normalized',...
                  'Position',[0.35 0.1 0.45 0.8],...
                  'WindowKeyPressFcn',@obj.keyCaptureCB);
         elseif ~isvalid(obj.FigViewer)
            obj.FigViewer = figure('Name','Figure Viewer',...
                  'NumberTitle','off',...
                  'Color','w',...
                  'Units','Normalized',...
                  'Position',[0.35 0.1 0.45 0.8],...
                  'WindowKeyPressFcn',@obj.keyCaptureCB);
         end
      end
      
      % Method to build the (main) "MENU" figure 
      function buildMenu(obj)
         %BUILDMENU Creates the "Menu" figure graphics
         %
         %  buildMenu(obj);
         %
         % Inputs
         %  obj - Scalar `figBrowser` object
         %
         % Creates the "Menu" which has 3 listboxes, from left-to-right: 
         %  * Animal (obj.ratMenu)
         %  * Block  (obj.blockMenu)
         %  * Figure (obj.figMenu)
         %
         % Combinations of selections from these listboxes influence what
         % is executed when the `Load` or `Generate` buttons are pushed.
         
         obj.Menu = figure('Name','Solenoid Rat Figure Browser',...
            'Units','Normalized',...
            'Position',[0.1 0.65 0.3 0.15],...
            'Color','k',...
            'ToolBar','none',...
            'MenuBar','none',...
            'NumberTitle','off',...
            'DeleteFcn',@obj.menuClosedCB,...
            'WindowKeyPressFcn',@obj.keyCaptureCB);
         
         % Load button
         obj.Buttons = struct;
         obj.Buttons.Load = uicontrol(obj.Menu,'Style','Pushbutton',...
            'Units','Normalized',...
            'ForegroundColor','w',...
            'BackgroundColor','b',...
            'FontName','Arial',...
            'FontSize',16,...
            'String','Load',...
            'Position',[0.025 0.025 0.95 0.15],...
            'Callback',@obj.loadFigCB);
         
         
         
         % Figure Menu
         obj.figMenu = uicontrol(obj.Menu,'Style','ListBox',...
            'Units','Normalized',...
            'Position',[0.425 0.2 0.55 0.775],...
            'String',{''},...
            'Value',1,...
            'Callback',@obj.figChangedCB,...
            'CreateFcn',@obj.figChangedCB);  
         
         % Block Menu
         obj.blockMenu = uicontrol(obj.Menu,'Style','ListBox',...
            'Units','Normalized',...
            'Position',[0.2 0.2 0.2 0.775],...
            'String',{''},...
            'Value',1,...
            'Callback',@obj.blockChangedCB,...
            'CreateFcn',@obj.blockChangedCB);
         
         % Rat Menu
         obj.ratMenu = uicontrol(obj.Menu,'Style','ListBox',...
            'Units','Normalized',...
            'Position',[0.025 0.2 0.15 0.775],...
            'String',[obj.Rat.Name].',...
            'Value',1,...
            'Callback',@obj.ratChangedCB,...
            'CreateFcn',@obj.ratChangedCB);
         
      end
      
   end
   
   % Static methods for parsing simple stuff
   methods (Static = true)
      % Allows looping (val) in menus
      function Value = parseMenuValue(val,str)
         %PARSEMENUVALUE Parses value based on menu to facilitate scrolling
         %
         %  Value = figBrowser.parseMenuValue(val,str);
         %
         % Inputs
         %  val - Value (index) numeric integer scalar
         %  str - String property of a particular listbox, which is used to
         %        determine if the array index is too high or if it goes to
         %        zero, what the "largest" value it should be reset to
         %        should be.
         %
         % Output
         %  Value - Updated value of the indexing integer
         
         n = numel(str);
         if val > numel(str) % If index is too high
            Value = 1; % Set to first element
         elseif val < 1  % If index is too low
            Value = n; % Set to max entry
         else
            Value = val;
         end
      end
   end
   
end

