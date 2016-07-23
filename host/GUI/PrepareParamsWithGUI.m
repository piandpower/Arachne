%%
function PrepareParamsWithGUI()
   
    close all;
    clc;
    
    global layout palette
    global JFrameNotSupported
    global panelName params
    global hf hbg hrb ht hpb hs
    global panIdx numPanels
    global minHeight minWidth
    global guiType useGUI
    
    
    % Initialize constants for GUI controls and color palette
    Layout();
    Palette();
    
    % Prepare the scenario name
    scenario = GuiTypeToScenarioName(guiType);
    
    name = ['Gamma Simulator (', scenario, ')'];
    
    % Create a figure
    hf = figure('Units', 'pixels', ...
                'MenuBar', 'none', ...
                'Color', palette.backgroundColor, ...
                'Name', name, ...
                'NumberTitle', 'off', ...
                'Visible', 'off');
    
    % Set apart to avoid immediate call after figure creation
    set(hf, 'ResizeFcn', @figure_ResizeFcn);
    
    numPanels = 0;
    panelName = {};
    params = {{}};
    
    % Add all panels to GUI given GUI type,
    % select a default panel
    AddAllPanels();
            
    % Calculate minimum size depending on content size
    minHeight = (numPanels + 1) * (layout.rbHeight + layout.yMargin0) + 3 * layout.yMargin0;
    minWidth = layout.rgWidth + layout.nameWidth + layout.ebWidth + layout.unitWidth + layout.sWidth ...
        + layout.xMargin0 + layout.xMargin1 + layout.xMargin2 + layout.xMargin3;
    
    % Radiogroup
    hbg = uibuttongroup('Units', 'pixels', ...
                        'Title', 'Parameters', ...
                        'SelectionChangeFcn', @buttongroup_SelectionChangeFcn);
    hrb = zeros(1, numPanels);
    for i = 1 : numPanels
        hrb(i) = uicontrol(hbg, 'Style', 'radiobutton', ...
                                'String', panelName(i), ...
                                'Units', 'pixels', ...
                                'UserData', i);
    end
    
    set(hbg, 'SelectedObject', hrb(panIdx));
    
    % Two blank strips at top and bottom of the window
    ht = zeros(1, 4);
    
    bgc = {palette.backgroundColor, palette.gray, palette.gray, palette.backgroundColor};
    for i = 1 : length(ht)
        ht(i) = uicontrol('Style', 'text', ...
                          'Units', 'pixels', ...
                          'BackgroundColor', bgc{i});
    end
    
    % Buttons
    
    hpb.ok = uicontrol('Style', 'pushbutton', ...
                       'Units', 'pixels', ...
                       'BackgroundColor', palette.backgroundColor, ...
                       'Callback', @pushbutton_OK_Callback, ...
                       'String', 'OK');
    
    hpb.load = uicontrol('Style', 'pushbutton', ...
                         'Units', 'pixels', ...
                         'BackgroundColor', palette.backgroundColor, ...
                         'Callback', @pushbutton_Load_Callback, ...
                         'String', 'Load');
    
    hpb.save = uicontrol('Style', 'pushbutton', ...
                         'Units', 'pixels', ...
                         'BackgroundColor', palette.backgroundColor, ...
                         'Callback', @pushbutton_Save_Callback, ...
                         'String', 'Save');
    
    % Slider
    hs = uicontrol('Style', 'slider', ...
                   'Units', 'pixels', ...
                   'BackgroundColor', palette.backgroundColor, ...
                   'Value', 1);
    try
        % R2014a and newer
        addlistener(hs, 'ContinuousValueChange', @slider_ContinuousValueChange);
    catch
        % R2013b and older
        addlistener(hs, 'ActionEvent', @slider_ContinuousValueChange);
    end

    % Mouse wheel event
    set(hf, 'WindowScrollWheelFcn', @figure_WindowScrollWheelFcn);
    
    % Render the figure before it becomes visible
    JFrameNotSupported = false;
    figure_ResizeFcn();
    
    if useGUI
        set(hf, 'Visible', 'on');
    end
    
    % Set minimum size of the window
    % (this code requires the figure to be already visible)
    try        
        drawnow; % Must flush figure queue to get fully constructed JavaFrame object
        jFrame = get(handle(hf), 'JavaFrame');
        try
            jWin = jFrame.fFigureClient.getWindow();
        catch
            jWin = jFrame.fHG1Client.getWindow();
        end
        jWin.setMinimumSize(java.awt.Dimension(minWidth, minHeight));
    catch
        JFrameNotSupported = true;
    end
    
    if ~useGUI
        pushbutton_OK_Callback();
    end
    
end

%%
function figure_ResizeFcn(~, ~, ~)

    global hf hbg hrb ht hpb
    global layout yPos00 yPos0 
    global minWidth minHeight JFrameNotSupported
    
    if isempty(hbg)
        return
    end
    
    pos = get(hf, 'Position');
    winWidth = pos(3);
    winHeight = pos(4);
    
    % Check if new size is smaller than allowed
    if JFrameNotSupported && (winWidth < minWidth || winHeight < minHeight)
        if winWidth < minWidth
            winWidth = minWidth;            
        end
        if winHeight < minHeight
            winHeight = minHeight;            
        end
        pos(3) = winWidth;
        pos(4) = winHeight;
        set(hf, 'Position', pos);
    end
    
    % Button group
    set(hbg, 'Position', [layout.xMargin0, layout.yMargin0, layout.rgWidth, winHeight - 2 * layout.yMargin0]);
    
    % Radio buttons
    x = layout.xMargin0;
    y = winHeight - layout.yMargin0 - 2 * layout.yStep;
    w = layout.rgWidth - 2 * layout.xMargin0;
    h = layout.rbHeight;
    for i = 1 : length(hrb)
        set(hrb(i), 'Position', [x, y, w, h]);
        y = y - layout.yStep;
    end  
    
    % Two blank strips at top and bottom of the window
    x = layout.xMargin0 + layout.rgWidth + layout.xMargin1;
    y = [winHeight - layout.yMargin0 + layout.bsHeight, winHeight - layout.yMargin0, ...
        layout.pbHeight + 2 * layout.yMargin0 - layout.bsHeight, 0];
    w = winWidth - x - layout.sWidth - 2 * layout.xMargin0;
    h = [2 * layout.yMargin0 + layout.pbHeight - layout.bsHeight, layout.bsHeight, ...
        layout.bsHeight, layout.pbHeight + 2 * layout.yMargin0 - layout.bsHeight];
    for i = 1 : length(ht)
        set(ht(i), 'Position', [x, y(i), w, h(i)]);
    end
        
    % "OK" pushbutton
    set(hpb.ok, 'Position', [winWidth - layout.xMargin0 - layout.pbWidth, layout.yMargin0, layout.pbWidth, layout.pbHeight])
    
    % "Save" pushbutton
    set(hpb.save, 'Position', [winWidth - 5 * layout.xMargin0 - 2 * layout.pbWidth, layout.yMargin0, layout.pbWidth, layout.pbHeight])
    
    % "Load" pushbutton
    set(hpb.load, 'Position', [winWidth - 6 * layout.xMargin0 - 3 * layout.pbWidth, layout.yMargin0, layout.pbWidth, layout.pbHeight])
        
    % The main controls
    yPos00 = winHeight - 3 * layout.yMargin0 - layout.yStep;
    yPos0 = yPos00; 
    UpdateViewControls();
    
    % Slider and gray strips
    AdjustSliderAndStrips(false);
    
end

%%
function figure_WindowScrollWheelFcn(~, callbackdata)

    global hs
    
    vis = GetVisibility(hs);
    if ~vis
        return
    end
    
    value = get(hs, 'Value');
    sliderStep = get(hs, 'SliderStep');
    max = get(hs, 'Max');
    
    factor = max * sliderStep(1);
    value = value - callbackdata.VerticalScrollCount * factor;
    value = factor * round(value / factor);
    if value < 0
        value = 0;
    elseif value > max
        value = max;
    end
    
    set(hs, 'Value', value);
    slider_ContinuousValueChange();

end

%%
function buttongroup_SelectionChangeFcn(~, eventdata, ~)

    global panIdx
    
    panIdx = get(eventdata.NewValue, 'UserData');
    buttongroup_SelectionChangeFcn_inner();
    
end

%%
function buttongroup_SelectionChangeFcn_inner()

    global hs

    max = get(hs, 'Max');
    set(hs, 'Value', max);
    slider_ContinuousValueChange();
    
    % Slider and gray strips
    AdjustSliderAndStrips(true);
    
end

%%
function pushbutton_OK_Callback(~, ~)

    global invalidParams hf saveInput2Output
    global guiType debugMode
    
    if ~isempty(invalidParams)
        msg = ['The following parameters are not valid:', invalidParams];
        warndlg(msg, 'Invalid parameters');
        return
    end
    
    % Evaluate all remainders given GUI type
    if ~debugMode
        % Show error message only
        try
            EvaluateAllRemainders(guiType);
        catch ex
            warndlg(ex.message, 'Invalid parameters');
        end
    else
        % Show error message and call stack
        EvaluateAllRemainders(guiType);
    end
    
    % Save input parameters
    if saveInput2Output
        SaveParams('guiParams.mat');
    end
        
    close(hf);
    
    [okHandler, stopAfter] = GuiTypeToOkHandler(guiType);
    
    okHandler();
    
    if stopAfter
        return
    end
      
    % Grab output MAT-file from remote cluster or HPC kernel directory
    getFromSnapshot = false;
    GrabReadAndVisualizeResults(getFromSnapshot);

end

%%
function pushbutton_Load_Callback(~, ~)
    [filename, path] = uigetfile('*.mat', 'Load input parameters');
    if isequal(filename, 0) || isequal(path, 0)
        % Loading was cancelled
    else
        file = fullfile(path, filename);
        LoadParams(file);
        buttongroup_SelectionChangeFcn_inner();
    end
end

%%
function pushbutton_Save_Callback(~, ~)
    [filename, path] = uiputfile('guiParams.mat', 'Save input parameters');
    if isequal(filename, 0) || isequal(path, 0)
        % Saving was cancelled
    else
        file = fullfile(path, filename);
        SaveParams(file);
    end
end
