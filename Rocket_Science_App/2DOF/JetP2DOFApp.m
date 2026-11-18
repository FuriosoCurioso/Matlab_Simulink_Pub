classdef JetP2DOFApp < matlab.apps.AppBase
    % JetP2DOFApp
    % Interaktive 2-DOF-App fuer ein vereinfachtes Rocket-Belt-Modell.
    %
    % Fenster 1:
    %   Bedienfeld mit Slidern und Eingabefeldern
    %
    % Fenster 2:
    %   Diagramme und Parameter-/fprintf-Ausgabe
    %
    % Start:
    %   app = JetP2DOFApp;

    properties (Access = public)
        ControlFigure matlab.ui.Figure
        OutputFigure matlab.ui.Figure

        ControlGrid matlab.ui.container.GridLayout
        OutputGrid matlab.ui.container.GridLayout

        TrajAxes matlab.ui.control.UIAxes
        HeightAxes matlab.ui.control.UIAxes

        PilotMassSlider matlab.ui.control.Slider
        PilotMassSliderLabel matlab.ui.control.Label
        PilotMassValueLabel matlab.ui.control.Label

        ThetaSlider matlab.ui.control.Slider
        ThetaSliderLabel matlab.ui.control.Label
        ThetaValueLabel matlab.ui.control.Label

        TVertEditField matlab.ui.control.NumericEditField
        TVertEditFieldLabel matlab.ui.control.Label

        TPushEditField matlab.ui.control.NumericEditField
        TPushEditFieldLabel matlab.ui.control.Label

        TCoastEditField matlab.ui.control.NumericEditField
        TCoastEditFieldLabel matlab.ui.control.Label

        ResultTextArea matlab.ui.control.TextArea
    end

    properties (Access = private)
        g double = 9.81
        F_nom double = 1250
        F_max double = 1333
        Isp double = 130

        m_dry double = 30.6
        rho_fuel double = 1.39
        V_tank double = 19.0

        t_sim double = 30

        vx_brake_ref double = 2.3
        vx_brake_tol double = 0.2

        luft_red double = 0.07

        t_vert double = 2.5
        t_push double = 4.5
        t_coast double = 0.2

        t_brake_delay double = 0.2
        brake_margin_time double = 1.0
        brake_thrust_min_frac double = 0.85

        Kv double = 1.5

        PilotMass double = 70.0
        ThetaDeg double = 18.0
    end

    methods (Access = private)

        function m_fuel = fuelMass(app)
            m_fuel = app.V_tank * app.rho_fuel;
        end

        function y = clampValue(~, x, lo, hi)
            y = max(lo, min(hi, x));
        end

        function y = sanitizeScalar(app, x, fallback, lo, hi)
            if ~isfinite(x)
                x = fallback;
            end

            y = round(app.clampValue(x, lo, hi), 2);
            
        end

        function prepareAxes(~, ax)
            cla(ax);
            hold(ax, 'on');
            grid(ax, 'on');
            box(ax, 'on');
        end

        function setDataLimits(~, ax, xData, yData)
            xData = xData(isfinite(xData));
            yData = yData(isfinite(yData));

            if isempty(xData) || isempty(yData)
                xlim(ax, [0 1]);
                ylim(ax, [-0.5 1]);
                return
            end

            xMin = min(xData);
            xMax = max(xData);
            yMin = min(yData);
            yMax = max(yData);

            if abs(xMax - xMin) < 1e-9
                xMin = min(0, xMin);
                xMax = max(1, xMax + 1);
            else
                xPad = 0.05 * (xMax - xMin);
                xMin = xMin - xPad;
                xMax = xMax + xPad;

                if xMin >= 0
                    xMin = 0;
                end
            end

            if abs(yMax - yMin) < 1e-9
                yCenter = 0.5 * (yMin + yMax);
                yMin = min(-0.5, yCenter - 0.5);
                yMax = max(1.0, yCenter + 0.5);
            else
                yPad = 0.05 * (yMax - yMin);
                yMin = yMin - yPad;
                yMax = yMax + yPad;

                if yMin > 0
                    yMin = 0;
                end
            end

            if xMax <= xMin
                xMax = xMin + 1;
            end

            if yMax <= yMin
                yMax = yMin + 1;
            end

            xlim(ax, [xMin xMax]);
            ylim(ax, [yMin yMax]);
        end

        function p = simParams(app)
            p.g = app.g;
            p.F_nom = app.F_nom;
            p.F_max = app.F_max;
            p.Isp = app.Isp;

            p.m_fuel = app.fuelMass();
            p.m_pilot = app.PilotMass;
            p.m0 = app.m_dry + p.m_fuel + p.m_pilot;
            p.m_empty = app.m_dry + p.m_pilot;

            p.t_sim = app.t_sim;

            p.vx_brake_ref = app.vx_brake_ref;
            p.vx_brake_tol = app.vx_brake_tol;

            p.thetaB = deg2rad(app.ThetaDeg);
            p.thetaDeg = app.ThetaDeg;

            p.luft_red = app.luft_red;

            p.t_vert = app.t_vert;
            p.t_push = app.t_push;
            p.t_coast = app.t_coast;

            p.t1 = p.t_vert;
            p.t2 = p.t_vert + p.t_push;
            p.t3 = p.t_vert + p.t_push + p.t_coast;

            p.t_brake_start = p.t3 + app.t_brake_delay;
            p.brake_margin_time = app.brake_margin_time;
            p.brake_thrust_min_frac = app.brake_thrust_min_frac;

            p.Kv = app.Kv;
        end

        function [t, X, r] = runSimulation(app)
            p = app.simParams();

            x0 = [0; 0; 0; 0; p.m0];

            if p.F_max <= p.m0 * p.g
                t = [0; p.t_sim];
                X = [ ...
                    0 0 0 0 p.m0; ...
                    0 0 0 0 p.m0];
            else
                opts = odeset( ...
                    'RelTol', 1e-6, ...
                    'AbsTol', 1e-8, ...
                    'MaxStep', 0.02, ...
                    'Events', @(t,x) app.groundEvent(t, x));

                [t, X] = ode45(@(t,x) app.odeProfile(t, x, p), ...
                    [0 p.t_sim], x0, opts);
            end

            r.x_traj = X(:,1);
            r.z_traj = X(:,2);
            r.vx_traj = X(:,3);
            r.vz_traj = X(:,4);
            r.m_traj = X(:,5);

            r.z_max = max(r.z_traj);
            r.x_end = r.x_traj(end);
            r.vx_max = max(abs(r.vx_traj));
            r.vz_sink_max = max(0, -min(r.vz_traj));
            r.vz_land = r.vz_traj(end);
            r.vx_land = r.vx_traj(end);
            r.t_end = t(end);
            r.m_end = r.m_traj(end);

            r.fuel_used = min(p.m_fuel, max(0, p.m0 - r.m_end));
            r.fuel_rest = max(0, p.m_fuel - r.fuel_used);

            r.mdot_nom = p.F_nom / (p.Isp * p.g);
            r.mdot_max = p.F_max / (p.Isp * p.g);

            r.m0 = p.m0;
            r.W0 = p.m0 * p.g;
            r.twr_nom = p.F_nom / r.W0;
            r.twr_max = p.F_max / r.W0;

            r.m_pilot = p.m_pilot;
            r.thetaDeg = p.thetaDeg;
            r.Isp = p.Isp;
            r.luft_red = p.luft_red;

            r.t_vert = p.t_vert;
            r.t_push = p.t_push;
            r.t_coast = p.t_coast;
            r.t1 = p.t1;
            r.t2 = p.t2;
            r.t3 = p.t3;
            r.t_brake_start = p.t_brake_start;
        end

        function dx = odeProfile(~, t, x, p)
            z = x(2);
            vx = x(3);
            vz = x(4);
            m = x(5);

            if t < p.t1
                theta = 0;
                F = p.F_max;

            elseif t < p.t2
                theta = p.thetaB;
                F = p.F_nom;

            elseif t < p.t3
                theta = 0;
                F = 0;

            else
                if z > 12
                    vz_ref = 0.0;
                else
                    vz_ref = -min(0.8, max(0.2, 0.5 * z));
                end

                vx_abs = abs(vx);

                a_brake_est = p.F_max * sin(p.thetaB) * ...
                    (1 - p.luft_red) / max(m, 1e-6);

                if vz < -0.1
                    t_ground_est = z / max(-vz, 0.1);
                else
                    t_ground_est = inf;
                end

                t_brake_need = max(0, vx_abs - p.vx_brake_ref) / ...
                    max(a_brake_est, 0.1);

                brakeByTime = t >= p.t_brake_start;
                brakeByState = t_ground_est <= ...
                    (t_brake_need + p.brake_margin_time);

                brakeActive = (t >= p.t3) && ...
                    (vx_abs > p.vx_brake_ref + p.vx_brake_tol) && ...
                    (brakeByTime || brakeByState);

                if brakeActive
                    theta = -sign(vx) * p.thetaB;
                else
                    theta = 0;
                end

                a_cmd = p.Kv * (vz_ref - vz);
                a_cmd = max(min(a_cmd, 3.0), -3.0);

                Fz_req = m * (p.g + a_cmd);
                F_req = Fz_req / max(cos(theta), 1e-6);

                F = min(p.F_max, max(0, F_req));

                if brakeActive
                    F = min(p.F_max, max(F, ...
                        p.brake_thrust_min_frac * p.F_max));
                end
            end

            if m <= p.m_empty
                F = 0;
                mdot = 0;
            else
                mdot = -F / (p.Isp * p.g);
            end

            Fx = F * sin(theta);
            Fz = F * cos(theta);

            Fx_eff = Fx * (1 - p.luft_red);

            dx = zeros(5,1);
            dx(1) = vx;
            dx(2) = vz;
            dx(3) = Fx_eff / m;
            dx(4) = Fz / m - p.g;
            dx(5) = mdot;
        end

        function [value, isterminal, direction] = groundEvent(~, t, x)
            if t < 1e-6
                value = 1;
            else
                value = x(2);
            end

            isterminal = 1;
            direction = -1;
        end

        function resultText = buildResultText(~, r)
            fmt = [ ...
                '=== Ergebnis Thunderball-Profil ===\n' ...
                'Pilotenmasse                  : %.2f kg\n' ...
                'Gesamtmasse Start             : %.2f kg\n' ...
                'TWR bei F_nom                 : %.3f\n' ...
                'TWR bei F_max                 : %.3f\n' ...
                'ISP                           : %.2f s\n' ...
                'Massenauswurf bei F_nom       : %.3f kg/s\n' ...
                'Massenauswurf bei F_max       : %.3f kg/s\n' ...
                'Horizontaler Luftwiderstand   : %.1f %%\n' ...
                'Winkel theta horiz. Bewegung  : %.2f deg\n' ...
                'Phase 1: Aufstieg             : %.2f s\n' ...
                'Phase 2: Horizontal +theta    : %.2f s\n' ...
                'Phase 3: Ballistisch F = 0    : %.2f s\n' ...
                'Bremsstart:         -theta    : %.2f s\n' ...
                'Maximale Hoehe                : %.2f m\n' ...
                'Endhoehe                      : %.2f m\n' ...
                'Endreichweite                 : %.2f m\n' ...
                'Maximales vz sinkend          : %.2f m/s (%.1f km/h)\n' ...
                'Maximales |vx|                : %.2f m/s (%.1f km/h)\n' ...
                'Landegeschwindigkeit vz_land  : %.2f m/s\n' ...
                'Landegeschwindigkeit vx_land  : %.2f m/s\n' ...
                'Verbrauchter Treibstoff       : %.2f kg\n' ...
                'Resttreibstoff                : %.2f kg\n' ...
                'Gesamtflugzeit                : %.2f s'];

            vals = { ...               
                r.m_pilot, r.m0, ...
                r.twr_nom, r.twr_max, ...
                r.Isp, r.mdot_nom, r.mdot_max, ...
                100 * r.luft_red, r.thetaDeg, ...
                r.t_vert, r.t_push, r.t_coast, ...
                r.t_brake_start, ...
                r.z_max, r.z_traj(end), r.x_end, ...
                r.vz_sink_max, 3.6 * r.vz_sink_max... 
                r.vx_max, 3.6 * r.vx_max, ...
                r.vz_land, r.vx_land, ...
                r.fuel_used, r.fuel_rest, r.t_end};

            resultText = sprintf(fmt, vals{:});
        end

        function updateSimulation(app, doPrint)
            trajLineWidth = 2.2;
            markerLineWidth = 1.4;
            phaseLineWidth = 1.0;
            brakeLineWidth = 1.2;

            [t, ~, r] = app.runSimulation();

            app.prepareAxes(app.TrajAxes);

            plot(app.TrajAxes, r.x_traj, r.z_traj, ...
                'b-', ...
                'LineWidth', trajLineWidth, ...
                'DisplayName', 'Flugbahn');

            plot(app.TrajAxes, r.x_traj(1), r.z_traj(1), ...
                'go', ...
                'LineWidth', markerLineWidth, ...
                'DisplayName', 'Start');

            plot(app.TrajAxes, r.x_traj(end), r.z_traj(end), ...
                'ro', ...
                'LineWidth', markerLineWidth, ...
                'DisplayName', 'Ende');

            app.setDataLimits(app.TrajAxes, r.x_traj, r.z_traj);

            xlabel(app.TrajAxes, 'Horizontale Distanz x [m]');
            ylabel(app.TrajAxes, 'Hoehe z [m]');
            title(app.TrajAxes, 'Hoehe ueber Distanz');
            legend(app.TrajAxes, 'show', 'Location', 'best');

            app.prepareAxes(app.HeightAxes);

            plot(app.HeightAxes, t, r.z_traj, ...
                'r-', ...
                'LineWidth', trajLineWidth, ...
                'DisplayName', 'z(t)');

            yline(app.HeightAxes, 0, 'k-', ...
                'LineWidth', phaseLineWidth, ...
                'DisplayName', 'Boden');

            xline(app.HeightAxes, r.t1, 'b--', ...
                'LineWidth', phaseLineWidth, ...
                'DisplayName', 'P1: Ende');

            xline(app.HeightAxes, r.t2, 'm--', ...
                'LineWidth', phaseLineWidth, ...
                'DisplayName', 'P2: Ende');

            xline(app.HeightAxes, r.t3, 'g--', ...
                'LineWidth', phaseLineWidth, ...
                'DisplayName', 'P3: Ende');

            xline(app.HeightAxes, r.t_brake_start, 'k--', ...
                'LineWidth', brakeLineWidth, ...
                'DisplayName', 'Bremsstart');

            app.setDataLimits(app.HeightAxes, t, r.z_traj);

            xlabel(app.HeightAxes, 'Zeit [s]');
            ylabel(app.HeightAxes, 'Hoehe z [m]');
            title(app.HeightAxes, 'Hoehe ueber Zeit');
            legend(app.HeightAxes, 'show', 'Location', 'best');

            app.PilotMassValueLabel.Text = sprintf('%.0f kg', app.PilotMass);
            app.ThetaValueLabel.Text = sprintf('%.1f deg', app.ThetaDeg);

            app.TVertEditField.Value = app.t_vert;
            app.TPushEditField.Value = app.t_push;
            app.TCoastEditField.Value = app.t_coast;

            resultText = app.buildResultText(r);
            app.ResultTextArea.Value = cellstr(splitlines(string(resultText)));

            if doPrint
                fprintf('\n%s\n', resultText);
            end

            drawnow limitrate;
        end

        function updateFromControls(app, pilotMass, thetaDeg, doPrint)
            pilotMass = app.clampValue(pilotMass, 65, 78);
            thetaDeg = app.clampValue(thetaDeg, 10, 25);

            pilotMass = round(pilotMass);
            thetaDeg = round(thetaDeg, 1);

            app.PilotMass = pilotMass;
            app.ThetaDeg = thetaDeg;

            app.PilotMassSlider.Value = pilotMass;
            app.ThetaSlider.Value = thetaDeg;

            app.updateSimulation(doPrint);
        end

        function updatePhaseTimes(app, doPrint)
            tVertVal = app.sanitizeScalar(app.TVertEditField.Value, 3.5, 0.1, 10.0);
            tPushVal = app.sanitizeScalar(app.TPushEditField.Value, 5.1, 0.1, 15.0);
            tCoastVal = app.sanitizeScalar(app.TCoastEditField.Value, 0.8, 0.0, 5.0);

            app.t_vert = tVertVal;
            app.t_push = tPushVal;
            app.t_coast = tCoastVal;

            app.TVertEditField.Value = tVertVal;
            app.TPushEditField.Value = tPushVal;
            app.TCoastEditField.Value = tCoastVal;

            app.updateSimulation(doPrint);
        end

        function PilotMassSliderValueChanged(app, ~)
            app.updateFromControls(app.PilotMassSlider.Value, app.ThetaDeg, true);
        end

        function PilotMassSliderValueChanging(app, event)
            app.updateFromControls(event.Value, app.ThetaDeg, false);
        end

        function ThetaSliderValueChanged(app, ~)
            app.updateFromControls(app.PilotMass, app.ThetaSlider.Value, true);
        end

        function ThetaSliderValueChanging(app, event)
            app.updateFromControls(app.PilotMass, event.Value, false);
        end

        function PhaseEditFieldValueChanged(app, ~)
            app.updatePhaseTimes(true);
        end

        function createComponents(app)
            app.ControlFigure = uifigure('Visible', 'off');
            app.ControlFigure.Position = [80 120 520 520];
            app.ControlFigure.Name = 'Thunderball 2DOF - Bedienfeld';
            app.ControlFigure.Color = [1 1 1];

            app.ControlGrid = uigridlayout(app.ControlFigure);
            app.ControlGrid.RowHeight = {34, 66, 34, 66, 38, 38, 38, '1x'};
            app.ControlGrid.ColumnWidth = {260, 110, '1x'};
            app.ControlGrid.Padding = [18 18 18 18];
            app.ControlGrid.RowSpacing = 12;
            app.ControlGrid.ColumnSpacing = 12;

            app.PilotMassSliderLabel = uilabel(app.ControlGrid);
            app.PilotMassSliderLabel.Text = 'Pilotenmasse [kg]';
            app.PilotMassSliderLabel.FontWeight = 'bold';
            app.PilotMassSliderLabel.Layout.Row = 1;
            app.PilotMassSliderLabel.Layout.Column = [1 2];

            app.PilotMassValueLabel = uilabel(app.ControlGrid);
            app.PilotMassValueLabel.Text = sprintf('%.0f kg', app.PilotMass);
            app.PilotMassValueLabel.HorizontalAlignment = 'right';
            app.PilotMassValueLabel.FontWeight = 'bold';
            app.PilotMassValueLabel.Layout.Row = 1;
            app.PilotMassValueLabel.Layout.Column = 3;

            app.PilotMassSlider = uislider(app.ControlGrid);
            app.PilotMassSlider.Limits = [65 78];
            app.PilotMassSlider.Value = app.PilotMass;
            app.PilotMassSlider.MajorTicks = 65:1:78;
            app.PilotMassSlider.MinorTicks = [];
            app.PilotMassSlider.Layout.Row = 2;
            app.PilotMassSlider.Layout.Column = [1 3];
            app.PilotMassSlider.ValueChangedFcn = @(src, event) app.PilotMassSliderValueChanged(event);
            app.PilotMassSlider.ValueChangingFcn = @(src, event) app.PilotMassSliderValueChanging(event);

            app.ThetaSliderLabel = uilabel(app.ControlGrid);
            app.ThetaSliderLabel.Text = 'Schub-Winkel theta [deg]';
            app.ThetaSliderLabel.FontWeight = 'bold';
            app.ThetaSliderLabel.Layout.Row = 3;
            app.ThetaSliderLabel.Layout.Column = [1 2];

            app.ThetaValueLabel = uilabel(app.ControlGrid);
            app.ThetaValueLabel.Text = sprintf('%.1f deg', app.ThetaDeg);
            app.ThetaValueLabel.HorizontalAlignment = 'right';
            app.ThetaValueLabel.FontWeight = 'bold';
            app.ThetaValueLabel.Layout.Row = 3;
            app.ThetaValueLabel.Layout.Column = 3;

            app.ThetaSlider = uislider(app.ControlGrid);
            app.ThetaSlider.Limits = [10 25];
            app.ThetaSlider.Value = app.ThetaDeg;
            app.ThetaSlider.MajorTicks = 10:1:25;
            app.ThetaSlider.MinorTicks = 10:0.5:25;
            app.ThetaSlider.Layout.Row = 4;
            app.ThetaSlider.Layout.Column = [1 3];
            app.ThetaSlider.ValueChangedFcn = @(src, event) app.ThetaSliderValueChanged(event);
            app.ThetaSlider.ValueChangingFcn = @(src, event) app.ThetaSliderValueChanging(event);

            app.TVertEditFieldLabel = uilabel(app.ControlGrid);
            app.TVertEditFieldLabel.Text = 'Phase 1: Aufstieg [s]';
            app.TVertEditFieldLabel.FontWeight = 'bold';
            app.TVertEditFieldLabel.Layout.Row = 5;
            app.TVertEditFieldLabel.Layout.Column = 1;

            app.TVertEditField = uieditfield(app.ControlGrid, 'numeric');
            app.TVertEditField.Limits = [0.1 10.0];
            app.TVertEditField.Value = app.t_vert;
            app.TVertEditField.ValueDisplayFormat = '%.2f';
            app.TVertEditField.HorizontalAlignment = 'left';
            app.TVertEditField.Layout.Row = 5;
            app.TVertEditField.Layout.Column = 2;
            app.TVertEditField.ValueChangedFcn = @(src, event) app.PhaseEditFieldValueChanged(event);

            app.TPushEditFieldLabel = uilabel(app.ControlGrid);
            app.TPushEditFieldLabel.Text = 'Phase 2: Beginn horiz. [s]';
            app.TPushEditFieldLabel.FontWeight = 'bold';
            app.TPushEditFieldLabel.Layout.Row = 6;
            app.TPushEditFieldLabel.Layout.Column = 1;

            app.TPushEditField = uieditfield(app.ControlGrid, 'numeric');
            app.TPushEditField.Limits = [0.1 15.0];
            app.TPushEditField.Value = app.t_push;
            app.TPushEditField.ValueDisplayFormat = '%.2f';
            app.TPushEditField.HorizontalAlignment = 'left';
            app.TPushEditField.Layout.Row = 6;
            app.TPushEditField.Layout.Column = 2;
            app.TPushEditField.ValueChangedFcn = @(src, event) app.PhaseEditFieldValueChanged(event);

            app.TCoastEditFieldLabel = uilabel(app.ControlGrid);
            app.TCoastEditFieldLabel.Text = 'Phase 3: Ballistisch F = 0 [s]';
            app.TCoastEditFieldLabel.FontWeight = 'bold';
            app.TCoastEditFieldLabel.Layout.Row = 7;
            app.TCoastEditFieldLabel.Layout.Column = 1;

            app.TCoastEditField = uieditfield(app.ControlGrid, 'numeric');
            app.TCoastEditField.Limits = [0.0 5.0];
            app.TCoastEditField.Value = app.t_coast;
            app.TCoastEditField.ValueDisplayFormat = '%.2f';
            app.TCoastEditField.HorizontalAlignment = 'left';
            app.TCoastEditField.Layout.Row = 7;
            app.TCoastEditField.Layout.Column = 2;
            app.TCoastEditField.ValueChangedFcn = @(src, event) app.PhaseEditFieldValueChanged(event);

            infoLabel = uilabel(app.ControlGrid);
            infoLabel.Text = 'Aenderungen starten die Simulation automatisch neu.';
            infoLabel.FontName = 'Consolas';
            infoLabel.FontSize = 11;
            infoLabel.VerticalAlignment = 'top';
            infoLabel.Layout.Row = 8;
            infoLabel.Layout.Column = [1 3];

            scr = get(groot, 'ScreenSize');

            screenW = scr(3);
            screenH = scr(4);

            outputW = min(1150, round(0.90 * screenW));
            outputH = min(820, round(0.82 * screenH));

            outputX = max(40, round((screenW - outputW) / 2));
            outputY = max(60, round((screenH - outputH) / 2));

            app.OutputFigure = uifigure('Visible', 'off');
            app.OutputFigure.Position = [outputX outputY outputW outputH];
            app.OutputFigure.Name = 'Thunderball 2DOF - Diagramme und Parameter';
            app.OutputFigure.Color = [1 1 1];

            app.OutputGrid = uigridlayout(app.OutputFigure);
            app.OutputGrid.RowHeight = {'2x', '1x'};
            app.OutputGrid.ColumnWidth = {'1x', '1x'};
            app.OutputGrid.Padding = [12 12 12 12];
            app.OutputGrid.RowSpacing = 12;
            app.OutputGrid.ColumnSpacing = 12;

            app.TrajAxes = uiaxes(app.OutputGrid);
            app.TrajAxes.Layout.Row = 1;
            app.TrajAxes.Layout.Column = 1;

            app.HeightAxes = uiaxes(app.OutputGrid);
            app.HeightAxes.Layout.Row = 1;
            app.HeightAxes.Layout.Column = 2;

            app.ResultTextArea = uitextarea(app.OutputGrid);
            app.ResultTextArea.Editable = 'off';
            app.ResultTextArea.FontName = 'Consolas';
            app.ResultTextArea.FontSize = 11;
            app.ResultTextArea.Value = {''};
            app.ResultTextArea.Layout.Row = 2;
            app.ResultTextArea.Layout.Column = [1 2];

            app.updateSimulation(true);

            app.ControlFigure.Visible = 'on';
            app.OutputFigure.Visible = 'on';

            drawnow;

            movegui(app.ControlFigure, 'west');
            movegui(app.OutputFigure);
            app.OutputFigure.WindowState = 'maximized';
        end
    end

    methods (Access = public)

        function app = JetP2DOFApp
            createComponents(app);
            registerApp(app, app.ControlFigure);

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            if ~isempty(app.ControlFigure) && isvalid(app.ControlFigure)
                delete(app.ControlFigure);
            end

            if ~isempty(app.OutputFigure) && isvalid(app.OutputFigure)
                delete(app.OutputFigure);
            end
        end
    end
end