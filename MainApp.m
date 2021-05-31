classdef MainApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure        matlab.ui.Figure
        GridLayout      matlab.ui.container.GridLayout
        LeftPanel       matlab.ui.container.Panel
        Input           matlab.ui.control.UIAxes
        Output          matlab.ui.control.UIAxes
        RightPanel      matlab.ui.container.Panel
        AdjSpeed        matlab.ui.container.Panel
        Button1         matlab.ui.control.Button
        Label           matlab.ui.control.Label
        SpeedSlider     matlab.ui.control.Slider
        AdjTune         matlab.ui.container.Panel
        Button2         matlab.ui.control.Button
        Slider_2Label   matlab.ui.control.Label
        TuneSlider      matlab.ui.control.Slider
        DeNoise         matlab.ui.container.Panel
        AddNoiseButton  matlab.ui.control.Button
        DenoiseButton   matlab.ui.control.Button
        Panel           matlab.ui.container.Panel
        GridLayout2     matlab.ui.container.GridLayout
        Erase           matlab.ui.control.Button
        Play            matlab.ui.control.Button
        Save            matlab.ui.control.Button
        Record          matlab.ui.control.StateButton
        InfoLabel       matlab.ui.control.Label
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = private)
        RecordObj % 录音对象实例
        fs = 8000 % 采样率8000
        AudioData % 音频数据
        TimeAxis % 时间轴向量
        AudioProcessData % 处理后的音频数据
        FilePath ='*.*'% 保存文件路径
        SaveType ='Ori'% 要保存原始还是处理后的音频
        DialogApp % Dialog box app
        SpeedVal % 倍速
        TuneVal % 音调改变值
    end
    
    properties (Access = public)
        playerObj % 播放实例
    end
    
    methods (Access = public)
        
        function SaveAudioData(app,FilePath,SaveType)
            app.FilePath = FilePath;
            app.SaveType = SaveType;
            if (strcmp(app.SaveType,'Ori'))
                audiowrite(app.FilePath,app.AudioData,app.fs);
            else
                audiowrite(app.FilePath,app.AudioProcessData,app.fs);
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.RecordObj= audiorecorder(app.fs,16,1);
            app.Play.Enable = 'off';
            app.Save.Enable = 'off';
            app.Button1.Enable = 'off';
            app.Button2.Enable = 'off';
        end

        % Value changed function: Record
        function RecordValueChanged(app, event)
            value = app.Record.Value;
            if(value)
                app.Record.Icon = '停止.svg';
                record(app.RecordObj);
                app.Erase.Enable = 'off';
                app.Save.Enable = 'off';
                app.Play.Enable = 'off';
                cla(app.Input);
                cla(app.Output);
            else
                app.Record.Icon = '录制.svg';
                stop(app.RecordObj);
                app.AudioData = getaudiodata(app.RecordObj);
                app.AudioProcessData = getaudiodata(app.RecordObj);
                app.TimeAxis = (1:length(app.AudioData))/app.fs;
                plot(app.Input,app.TimeAxis,app.AudioData);
                plot(app.Output,app.TimeAxis,app.AudioData);
                app.Erase.Enable = 'on';
                app.Save.Enable = 'on';
                app.Play.Enable = 'on';
                app.Button1.Enable = 'on';
                app.Button2.Enable = 'on';
            end
        end

        % Button pushed function: Erase
        function EraseButtonPushed(app, event)
            cla(app.Input);
            cla(app.Output);
            app.RecordObj = audiorecorder(app.fs,16,1);
            app.AudioData = zeros(1,1);
            app.TimeAxis = zeros(1,1);
            app.Play.Enable = 'off';
            app.Save.Enable = 'off';
            app.Button1.Enable = 'off';
            app.Button2.Enable = 'off';
        end

        % Button pushed function: Play
        function PlayButtonPushed(app, event)
            app.playerObj = audioplayer(app.AudioData,app.fs);
            play(app.playerObj);
        end

        % Button pushed function: Save
        function SaveButtonPushed(app, event)
            % Disable Plot Options button while dialog is open
            app.Save.Enable = 'off';
            % Open the options dialog and pass inputs
            app.DialogApp = SaveDialog(app, app.FilePath, app.SaveType);
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
             % Delete both apps
             delete(app.DialogApp);
             delete(app);
        end

        % Button pushed function: Button1
        function Button1Pushed(app, event)
            app.playerObj = audioplayer(app.AudioProcessData,app.fs);
            play(app.playerObj);
        end

        % Value changed function: SpeedSlider
        function SpeedSliderValueChanged(app, event)
            app.SpeedVal = app.SpeedSlider.Value;
            app.AudioProcessData = AdjustSpeed(app.AudioData,app.fs,1/app.SpeedVal);
            tmp_TimeAxis = (1:length(app.AudioProcessData))/app.fs;
            cla(app.Output);
            plot(app.Output,tmp_TimeAxis,app.AudioProcessData);
        end

        % Value changed function: TuneSlider
        function TuneSliderValueChanged(app, event)
            app.TuneVal = app.TuneSlider.Value;
            app.AudioProcessData = AdjustTune(app.AudioData,app.fs,app.TuneVal);
            tmp_TimeAxis = (1:length(app.AudioProcessData))/app.fs;
            cla(app.Output);
            plot(app.Output,tmp_TimeAxis,app.AudioProcessData);
        end

        % Button pushed function: Button2
        function Button2Pushed(app, event)
            app.playerObj = audioplayer(app.AudioProcessData,app.fs);
            play(app.playerObj);
        end

        % Button pushed function: AddNoiseButton
        function AddNoiseButtonPushed(app, event)
            app.AudioProcessData = AddNoise(app.AudioData,5); %5dB
            tmp_TimeAxis = (1:length(app.AudioProcessData))/app.fs;
            cla(app.Output);
            plot(app.Output,tmp_TimeAxis,app.AudioProcessData);
            pause(0.5);
            app.playerObj = audioplayer(app.AudioProcessData,app.fs);
            play(app.playerObj);
        end

        % Button pushed function: DenoiseButton
        function DenoiseButtonPushed(app, event)
            app.AudioProcessData = PowerSpectrumSubtraction(app.AudioProcessData,app.fs);
            tmp_TimeAxis = (1:length(app.AudioProcessData))/app.fs;
            cla(app.Output);
            plot(app.Output,tmp_TimeAxis,app.AudioProcessData);
            pause(0.5);
            app.playerObj = audioplayer(app.AudioProcessData,app.fs);
            play(app.playerObj);
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {480, 480};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {448, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {448, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create Input
            app.Input = uiaxes(app.LeftPanel);
            title(app.Input, '输入波形')
            xlabel(app.Input, 'Time(s)')
            ylabel(app.Input, 'Amplitude')
            app.Input.TitleFontWeight = 'bold';
            app.Input.Position = [6 244 436 221];

            % Create Output
            app.Output = uiaxes(app.LeftPanel);
            title(app.Output, '输出波形')
            xlabel(app.Output, 'Time(s)')
            ylabel(app.Output, 'Amplitude')
            app.Output.TitleFontWeight = 'bold';
            app.Output.Position = [6 16 436 221];

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create AdjSpeed
            app.AdjSpeed = uipanel(app.RightPanel);
            app.AdjSpeed.TitlePosition = 'centertop';
            app.AdjSpeed.Title = '变速不变调';
            app.AdjSpeed.Position = [1 228 191 112];

            % Create Button1
            app.Button1 = uibutton(app.AdjSpeed, 'push');
            app.Button1.ButtonPushedFcn = createCallbackFcn(app, @Button1Pushed, true);
            app.Button1.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Button1.Position = [27 3 138 24];
            app.Button1.Text = '播放';

            % Create Label
            app.Label = uilabel(app.AdjSpeed);
            app.Label.HorizontalAlignment = 'right';
            app.Label.Position = [18 64 25 22];
            app.Label.Text = '';

            % Create SpeedSlider
            app.SpeedSlider = uislider(app.AdjSpeed);
            app.SpeedSlider.Limits = [0.5 2];
            app.SpeedSlider.MajorTicks = [0.5 0.75 1 1.25 1.5 1.75 2];
            app.SpeedSlider.MajorTickLabels = {'0.5', '0.75', '1', '1.25', '1.5', '1.75', '2', ''};
            app.SpeedSlider.ValueChangedFcn = createCallbackFcn(app, @SpeedSliderValueChanged, true);
            app.SpeedSlider.MinorTicks = [];
            app.SpeedSlider.Position = [18 73 163 3];
            app.SpeedSlider.Value = 1;

            % Create AdjTune
            app.AdjTune = uipanel(app.RightPanel);
            app.AdjTune.TitlePosition = 'centertop';
            app.AdjTune.Title = '变调不变速';
            app.AdjTune.Position = [1 114 191 112];

            % Create Button2
            app.Button2 = uibutton(app.AdjTune, 'push');
            app.Button2.ButtonPushedFcn = createCallbackFcn(app, @Button2Pushed, true);
            app.Button2.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Button2.Position = [27 3 138 24];
            app.Button2.Text = '播放';

            % Create Slider_2Label
            app.Slider_2Label = uilabel(app.AdjTune);
            app.Slider_2Label.HorizontalAlignment = 'right';
            app.Slider_2Label.Position = [13 59 25 22];
            app.Slider_2Label.Text = '';

            % Create TuneSlider
            app.TuneSlider = uislider(app.AdjTune);
            app.TuneSlider.Limits = [-12 12];
            app.TuneSlider.MajorTicks = [-12 -8 -4 0 4 8 12];
            app.TuneSlider.ValueChangedFcn = createCallbackFcn(app, @TuneSliderValueChanged, true);
            app.TuneSlider.MinorTicks = [-11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 1 2 3 4 5 6 7 8 9 10 11];
            app.TuneSlider.Position = [13 68 163 3];

            % Create DeNoise
            app.DeNoise = uipanel(app.RightPanel);
            app.DeNoise.TitlePosition = 'centertop';
            app.DeNoise.Title = '降噪';
            app.DeNoise.Position = [0 25 191 88];

            % Create AddNoiseButton
            app.AddNoiseButton = uibutton(app.DeNoise, 'push');
            app.AddNoiseButton.ButtonPushedFcn = createCallbackFcn(app, @AddNoiseButtonPushed, true);
            app.AddNoiseButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.AddNoiseButton.Position = [27 34 138 24];
            app.AddNoiseButton.Text = '叠加高斯白噪声';

            % Create DenoiseButton
            app.DenoiseButton = uibutton(app.DeNoise, 'push');
            app.DenoiseButton.ButtonPushedFcn = createCallbackFcn(app, @DenoiseButtonPushed, true);
            app.DenoiseButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.DenoiseButton.Position = [27 5 138 24];
            app.DenoiseButton.Text = '功率谱减法降噪';

            % Create Panel
            app.Panel = uipanel(app.RightPanel);
            app.Panel.TitlePosition = 'centertop';
            app.Panel.Title = '语音录制/保存';
            app.Panel.Position = [0 343 191 136];

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.Panel);

            % Create Erase
            app.Erase = uibutton(app.GridLayout2, 'push');
            app.Erase.ButtonPushedFcn = createCallbackFcn(app, @EraseButtonPushed, true);
            app.Erase.Icon = '清除.svg';
            app.Erase.Layout.Row = 1;
            app.Erase.Layout.Column = 2;
            app.Erase.Text = '';

            % Create Play
            app.Play = uibutton(app.GridLayout2, 'push');
            app.Play.ButtonPushedFcn = createCallbackFcn(app, @PlayButtonPushed, true);
            app.Play.Icon = '播放.svg';
            app.Play.IconAlignment = 'center';
            app.Play.Layout.Row = 2;
            app.Play.Layout.Column = 1;
            app.Play.Text = '';

            % Create Save
            app.Save = uibutton(app.GridLayout2, 'push');
            app.Save.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.Save.Icon = '保存.svg';
            app.Save.Layout.Row = 2;
            app.Save.Layout.Column = 2;
            app.Save.Text = '';

            % Create Record
            app.Record = uibutton(app.GridLayout2, 'state');
            app.Record.ValueChangedFcn = createCallbackFcn(app, @RecordValueChanged, true);
            app.Record.Icon = '录制.svg';
            app.Record.Text = '';
            app.Record.Layout.Row = 1;
            app.Record.Layout.Column = 1;

            % Create InfoLabel
            app.InfoLabel = uilabel(app.RightPanel);
            app.InfoLabel.Position = [19 1 162 22];
            app.InfoLabel.Text = 'Author:洪世杰         Ver 1.0.2';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = MainApp

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end