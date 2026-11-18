classdef TWRApp < matlab.apps.AppBase
    % TWRApp
    % Interaktive TWR-Analyse des Bell Rocket Belt.
    %
    % Bedienung:
    %   - Pilotengewicht per Slider von 40 kg bis 110 kg einstellen
    %   - feste Werte ueber Menueleiste setzen
    %
    % Start:
    %   app = TWRApp;

    properties (Access = public)
        UIFigure matlab.ui.Figure
        MainGrid matlab.ui.container.GridLayout

        WeightAxes matlab.ui.control.UIAxes
        TWRAxes matlab.ui.control.UIAxes

        ControlPanel matlab.ui.container.Panel

        PilotMassSlider matlab.ui.control.Slider
        PilotMassSliderLabel matlab.ui.control.Label

        ResultLabel matlab.ui.control.Label

        PilotgewichtMenu matlab.ui.container.Menu
        Menu50 matlab.ui.container.Menu
        Menu65 matlab.ui.container.Menu
        Menu75 matlab.ui.container.Menu
        Menu100 matlab.ui.container.Menu
        Menu110 matlab.ui.container.Menu
    end

    properties (Access = private)
        g double = 9.81
        F_nom double = 1250
        F_max double = 1333
        m_jetpack double = 30.6
        rho_fuel double = 1.39
        V_tank double = 19.0

        PilotMass double = 50.0
    end

    methods (Access = private)

        function m_fuel = fuelMass(app)
            m_fuel = app.V_tank * app.rho_fuel;
        end

        function [m_total, W_total, twr_nom, twr_max] = computeTWR(app, m_pilot)
            m_fuel = app.fuelMass();

            m_total = m_pilot + app.m_jetpack + m_fuel;
            W_total = m_total * app.g;

            twr_nom = app.F_nom / W_total;
            twr_max = app.F_max / W_total;
        end

        function updateFromPilotMass(app, value)
            value = max(40, min(110, value));
            value = round(value, 1);

            app.PilotMass = value;
            app.PilotMassSlider.Value = value;

            app.updatePlots();
        end

        function updatePlots(app)
            m_pilot = app.PilotMass;
            m_fuel = app.fuelMass();

            [m_total, W_total, twr_nom, twr_max] = app.computeTWR(m_pilot);

            cla(app.WeightAxes);
            hold(app.WeightAxes, 'on');
            grid(app.WeightAxes, 'on');
            box(app.WeightAxes, 'on');

            bar(app.WeightAxes, 1, W_total, 0.45, ...
                'FaceColor', [0.2 0.6 1], ...
                'EdgeColor', [0.1 0.2 0.4], ...
                'HandleVisibility', 'off');

            % Alte yline-Objekte (ConstantLine) entfernen,
            %  F_max- und F_nom-Labels bei slider nicht
            % überlagert werden
            
            delete(findall(app.WeightAxes, 'Type', 'ConstantLine'));

            yline(app.WeightAxes, app.F_max, 'r-', ...
                'LineWidth', 1.5, ...
                'Label', sprintf('F_{max} = %d N', app.F_max), ...
                'LabelHorizontalAlignment', 'left', ...
                'FontSize', 9, ...
                'HandleVisibility', 'off');

            yline(app.WeightAxes, app.F_nom, 'b--', ...
                'LineWidth', 1.2, ...
                'Label', sprintf('F_{nom} = %d N', app.F_nom), ...
                'LabelHorizontalAlignment', 'left', ...
                'FontSize', 9, ...
                'HandleVisibility', 'off');

            text(app.WeightAxes, 1, W_total + 18, ...
                sprintf('%.0f N\nm_{ges}=%.1f kg', W_total, m_total), ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 10, ...
                'FontWeight', 'bold', ...
                'Color', 'k');

            text(app.WeightAxes, 1, W_total * 0.50, ...
                sprintf('TWR_{max}=%.3f\nTWR_{nom}=%.3f', twr_max, twr_nom), ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 10, ...
                'Color', 'k');

            app.WeightAxes.XLim = [0.3 1.7];
            app.WeightAxes.XTick = 1;
            app.WeightAxes.XTickLabel = {sprintf('Pilot %.1f kg', m_pilot)};
            app.WeightAxes.YLim = [0, max([W_total, app.F_max, app.F_nom]) * 1.25];

            ylabel(app.WeightAxes, 'Gewichtskraft [N]');
            title(app.WeightAxes, 'Startgewicht vs. Schubkraefte');


            % Alte ConstantLine-, Text- und Legend-Objekte explizit entfernen,
            % damit das TWR=1-Label beim Slider-Bewegen nicht mehrfach
            % ueberlagert wird und dadurch immer dicker/unleserlicher wirkt.
            delete(findall(app.TWRAxes, 'Type', 'ConstantLine'));
            delete(findall(app.TWRAxes, 'Type', 'Text'));
            delete(findall(app.TWRAxes, 'Type', 'Legend'));
            cla(app.TWRAxes);

            hold(app.TWRAxes, 'on');
            grid(app.TWRAxes, 'on');
            box(app.TWRAxes, 'on');

            fuel_axis = linspace(0, m_fuel, 300);
            m_now = m_total - fuel_axis;

            twr_curve_max = app.F_max ./ (m_now * app.g);
            twr_curve_nom = app.F_nom ./ (m_now * app.g);

            plot(app.TWRAxes, fuel_axis, twr_curve_max, '-', ...
                'Color', [0.0 0.45 0.85], ...
                'LineWidth', 2.2, ...
                'DisplayName', sprintf('F_{max}, Start-TWR = %.3f', twr_max));

            plot(app.TWRAxes, fuel_axis, twr_curve_nom, '--', ...
                'Color', [0.0 0.55 0.20], ...
                'LineWidth', 1.7, ...
                'DisplayName', sprintf('F_{nom}, Start-TWR = %.3f', twr_nom));

            yline(app.TWRAxes, 1.0, 'k-', ...
                'LineWidth', 1.2, ...
                'Label', 'TWR = 1', ...
                'LabelHorizontalAlignment', 'left', ...
                'FontSize', 9, ...
                'HandleVisibility', 'off');

            xline(app.TWRAxes, m_fuel, 'k--', ...
                'LineWidth', 1.2, ...
                'Label', 'Tank leer', ...
                'LabelHorizontalAlignment', 'left', ...
                'FontSize', 9, ...
                'HandleVisibility', 'off');

            xlabel(app.TWRAxes, 'Verbrauchter Treibstoff [kg]');
            ylabel(app.TWRAxes, 'TWR = F / (m g)');
            title(app.TWRAxes, 'TWR-Verlauf ueber Treibstoffverbrauch');

            legend(app.TWRAxes, 'show', 'Location', 'northwest');

            app.TWRAxes.XLim = [0, m_fuel * 1.05];

            yMax = max([twr_curve_max, twr_curve_nom, 1.05]) * 1.05;
            yMin = min([twr_curve_max, twr_curve_nom, 0.95]) * 0.98;

            app.TWRAxes.YLim = [yMin, yMax];

            if twr_max >= 1
                statusMax = 'F_max: Hover/Steigen rechnerisch moeglich';
            else
                statusMax = 'F_max: Start-Hover rechnerisch nicht moeglich';
            end

            if twr_nom >= 1
                statusNom = 'F_nom: Hover/Steigen rechnerisch moeglich';
            else
                statusNom = 'F_nom: Start-Hover rechnerisch nicht moeglich';
            end

            app.ResultLabel.Text = sprintf([ ...
                'Aktuelles Pilotengewicht: %.1f kg\n' ...
                'Treibstoffmasse: %.2f kg\n' ...
                'Startgesamtmasse: %.2f kg\n' ...
                'Gewichtskraft: %.1f N\n' ...
                'TWR_{max}: %.3f\n' ...
                'TWR_{nom}: %.3f\n' ...
                '%s\n' ...
                '%s'], ...
                m_pilot, m_fuel, m_total, W_total, ...
                twr_max, twr_nom, statusMax, statusNom);
        end

        function PilotMassSliderValueChanged(app, event)
            value = app.PilotMassSlider.Value;
            app.updateFromPilotMass(value);
        end

        function PilotMassSliderValueChanging(app, event)
            value = event.Value;
            app.updateFromPilotMass(value);
        end

        function MenuMassSelected(app, value)
            app.updateFromPilotMass(value);
        end

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1220 720];
            app.UIFigure.Name = 'Bell Rocket Belt -- TWR App Designer Analyse';
            app.UIFigure.Color = [1 1 1];

            app.PilotgewichtMenu = uimenu(app.UIFigure);
            app.PilotgewichtMenu.Text = 'Pilotgewicht';

            app.Menu50 = uimenu(app.PilotgewichtMenu);
            app.Menu50.Text = '50 kg';
            app.Menu50.MenuSelectedFcn = @(src, event) app.MenuMassSelected(50);

            app.Menu65 = uimenu(app.PilotgewichtMenu);
            app.Menu65.Text = '65 kg';
            app.Menu65.MenuSelectedFcn = @(src, event) app.MenuMassSelected(65);

            app.Menu75 = uimenu(app.PilotgewichtMenu);
            app.Menu75.Text = '75 kg';
            app.Menu75.MenuSelectedFcn = @(src, event) app.MenuMassSelected(75);

            app.Menu100 = uimenu(app.PilotgewichtMenu);
            app.Menu100.Text = '100 kg';
            app.Menu100.MenuSelectedFcn = @(src, event) app.MenuMassSelected(100);

            app.Menu110 = uimenu(app.PilotgewichtMenu);
            app.Menu110.Text = '110 kg';
            app.Menu110.MenuSelectedFcn = @(src, event) app.MenuMassSelected(110);

            app.MainGrid = uigridlayout(app.UIFigure);
            app.MainGrid.RowHeight = {'1x', 165};
            app.MainGrid.ColumnWidth = {'1x', '1x'};
            app.MainGrid.Padding = [12 12 12 12];
            app.MainGrid.RowSpacing = 12;
            app.MainGrid.ColumnSpacing = 12;

            app.WeightAxes = uiaxes(app.MainGrid);
            app.WeightAxes.Layout.Row = 1;
            app.WeightAxes.Layout.Column = 1;

            app.TWRAxes = uiaxes(app.MainGrid);
            app.TWRAxes.Layout.Row = 1;
            app.TWRAxes.Layout.Column = 2;

            app.ControlPanel = uipanel(app.MainGrid);
            app.ControlPanel.Title = 'Bedienung und Kennwerte';
            app.ControlPanel.FontWeight = 'bold';
            app.ControlPanel.Layout.Row = 2;
            app.ControlPanel.Layout.Column = [1 2];

            controlGrid = uigridlayout(app.ControlPanel);
            controlGrid.RowHeight = {30, 70};
            controlGrid.ColumnWidth = {220, '1x', 360};
            controlGrid.Padding = [10 10 10 10];
            controlGrid.ColumnSpacing = 15;
            controlGrid.RowSpacing = 8;

            app.PilotMassSliderLabel = uilabel(controlGrid);
            app.PilotMassSliderLabel.Text = 'Pilotengewicht [kg]';
            app.PilotMassSliderLabel.FontWeight = 'bold';
            app.PilotMassSliderLabel.Layout.Row = 1;
            app.PilotMassSliderLabel.Layout.Column = [1 2];

            app.PilotMassSlider = uislider(controlGrid);
            app.PilotMassSlider.Limits = [40 110];
            app.PilotMassSlider.Value = app.PilotMass;
            app.PilotMassSlider.MajorTicks = 40:10:110;
            app.PilotMassSlider.MinorTicks = 40:5:110;
            app.PilotMassSlider.Layout.Row = 2;
            app.PilotMassSlider.Layout.Column = [1 2];
            app.PilotMassSlider.ValueChangedFcn = @(src, event) app.PilotMassSliderValueChanged(event);
            app.PilotMassSlider.ValueChangingFcn = @(src, event) app.PilotMassSliderValueChanging(event);

            app.ResultLabel = uilabel(controlGrid);
            app.ResultLabel.Text = '';
            app.ResultLabel.FontName = 'Consolas';
            app.ResultLabel.FontSize = 11;
            app.ResultLabel.VerticalAlignment = 'top';
            app.ResultLabel.Layout.Row = [1 2];
            app.ResultLabel.Layout.Column = 3;

            app.updatePlots();

            app.UIFigure.Visible = 'on';
        end
    end

    methods (Access = public)

        function app = TWRApp
            createComponents(app);
            registerApp(app, app.UIFigure);

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end
end
