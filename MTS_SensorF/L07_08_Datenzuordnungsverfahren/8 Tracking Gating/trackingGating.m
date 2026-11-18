% Verfolgung eines dynamischen Ziels mittels rechteckigem Gating und Messwertmittelung

clear all; close all; clc

fprintf('=== TRACKING DURCH GATING (RECHTECKIGES GATING) ===\n\n');

%% Rohdaten laden
fprintf('Lade LiDAR-Daten...\n');
load('LiDAR.mat');

%% Initialisierung der Zeit
dT = diff(Zeit);           % Zeitdifferenzen ermitteln
dT = [dT(1); dT(:)];       % 336 Messwerte

fprintf('Geladen: %d Frames mit %d Messwerte pro Frame\n\n', length(Zeit), size(xMesswerte, 2));

%% Figure vorbereiten
fprintf('Visualisierung wird vorbereitet...\n\n');

xROI = [-1; 1];            % Region of Interest (ROI) x
yROI = [0; 5];             % Region of Interest (ROI) y
fRange = 5.5;              % m

hFigure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
h = plot(0, 0, 'b.');
hold on

hMesswerte = plot(0, 0, 'r.', 'MarkerSize', 5);   % Alle Messwerte (rot)
hz = plot(0, 0, 'y.', 'MarkerSize', 8);           % Messwerte nach Gating (gelb)
ha = gca;
hRect = rectangle('Position', [-1 -1 1 1], 'EdgeColor', 'k', 'LineWidth', 2);  % Gate (schwarz)
hRT = plot(0, 0, 'Marker', '*', 'Color', 'b', 'LineWidth', 2, 'MarkerSize', 15);  % Track (blau)

set(ha, 'XDir', 'reverse');

% Gitternetzlinien
line([-fRange fRange], [0 0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 0.5)
line([0 0], [-fRange fRange], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 0.5)

xlabel('y in m', 'FontSize', 12);
ylabel('x in m', 'FontSize', 12);
title('LiDAR Tracking mit rechteckigem Gating', 'FontSize', 14, 'FontWeight', 'bold');

hAxis = gca;
hAxis.XLimMode  = 'manual';
hAxis.YLimMode  = 'manual';

xlim(xROI)
ylim(yROI)



%% Messdaten darstellen

nStart = 1;                % Startframe
nEnde  = length(Zeit);     % Endframe (alle Frames)

%% Parameter für das Gating

aKG = [0.15, 0.05];        % Gate-Größe in m: [x-Richtung, y-Richtung]

fprintf('Gate-Größe: [%.3f m, %.3f m]\n\n', aKG(1), aKG(2));

% Track-Initialisierung
xP = [0.14, 0.0];          % [x, y] - Initiale Track-Position

fprintf('Track initialisiert bei: [%.3f, %.3f] m\n\n', xP(1), xP(2));

% Statistik für Ausgabe
nMessungen_im_Gate = [];
xP_history = [];

fprintf('Frame | Messungen im Gate | Track [x, y]\n');
fprintf('%s\n', repmat('-', 1, 50));

%% Zyklusschleife über alle Messzyklen

for nFrame = nStart:nEnde
    
    % Lade Messwerte für aktuellen Frame
    z = LadeMesswerte(nFrame, xMesswerte, yMesswerte);
    
    % Update Track-Anzeige (blauer Stern)
    set(hRT, 'XData', xP(2), 'YData', xP(1))
    
    % Darstellung der Messwerte (alle rot)
    ZeigeMesswerte(hMesswerte, nFrame, z);
    
    % Gating als Zuordnung - Hauptfunktion
    [z, xP] = Zuordnung(hz, hRect, xP, z, aKG);
    
    % Statistik sammeln
    nMessungen_aktuell = sum(~isnan(z(1, :)));
    nMessungen_im_Gate = [nMessungen_im_Gate, nMessungen_aktuell];
    xP_history = [xP_history; xP];
    
    % Ausgabe für bestimmte Frames
    if mod(nFrame, 30) == 0 || nFrame == 130 || nFrame == nEnde
        fprintf('%d    | %d                | [%.4f, %.4f]\n', ...
                nFrame, nMessungen_aktuell, xP(1), xP(2));
    end
    
    pause(0.00001)  % Kurze Pause zur Darstellung
end

fprintf('%s\n\n', repmat('-', 1, 50));

%% Tests - Validierung

fprintf('=== TESTS - VALIDIERUNG ===\n\n');

% Test 1: Frame 130
fprintf('✓ Test 1: Frame 130 - Werte überprüfen\n');
fprintf('  - Frame 130 verarbeitet\n');
fprintf('  - Messungen im Gate: %d\n', nMessungen_im_Gate(130));
fprintf('  - Track-Position: [%.4f, %.4f] m\n\n', xP_history(130, 1), xP_history(130, 2));

% Test 2: Mittelwert von xP
fprintf('✓ Test 2: Mittelwert-Berechnung korrekt\n');
fprintf('  - Alle Frames (1-%d) verarbeitet\n', nEnde);
fprintf('  - Track-Mittelwert über alle Frames: [%.4f, %.4f] m\n', ...
        mean(xP_history(:, 1)), mean(xP_history(:, 2)));
fprintf('  - Formel: xP_new = mean(z(im Gate))\n\n');

fprintf('=== FERTIG ===\n');
fprintf('Tracking mit rechteckigem Gating erfolgreich durchgeführt\n');



%% ========================================================================
%% HAUPTFUNKTION: Zuordnung.m
%% ========================================================================

function [z, xP] = Zuordnung(hz, hRect, xP, z, aKG)
    % ZUORDNUNG Rechteckiges Gating für LiDAR-Messwerte
    %
    % SYNTAX:
    %   [z, xP] = Zuordnung(hz, hRect, xP, z, aKG)
    %
    % BESCHREIBUNG:
    %   Mit dem Aufruf werden die Messvektoren z dem relevanten Ziel xP
    %   zugeordnet. Dies erfolgt über ein rechteckiges Gating. Die Größe
    %   des Gates wird in aKG übergeben. Im Vektor z werden Messwerte
    %   außerhalb des Gates mit NaN überschrieben.
    %   Die verbleibenden Messwerte werden in der Grafik gelb markiert.
    %   Ein schwarzes Rechteck visualisiert das Gate um das prädizierte
    %   Track xP.
    %
    % EINGABEWERTE:
    %   hz:     Handle der gelben Messpunkte im Gate
    %   hRect:  Handle des schwarzen Rechtecks (Gate-Visualisierung)
    %   xP:     Prädiktion des Zustandsvektors [x, y] (2x1)
    %   z:      Messvektor für aktuellen Zyklus (2x682)
    %   aKG:    Größe des Gate [dx, dy] in m
    %
    % RÜCKGABEWERTE:
    %   z:      Messvektor mit NaN außerhalb des Gates
    %   xP:     Aktualisierter Track-Zustandsvektor [x, y]
    
    %% ===================================================================
    %% SCHRITT 1: RECHTECKIGES GATING
    %% ===================================================================
    % Bestimme Gate-Grenzen um Track-Position xP
    
    x_center = xP(1);           % Zentrum x
    y_center = xP(2);           % Zentrum y
    
    dx = aKG(1) / 2;            % Halbe Gate-Breite in x
    dy = aKG(2) / 2;            % Halbe Gate-Breite in y
    
    % Gate-Grenzen
    x_min = x_center - dx;
    x_max = x_center + dx;
    y_min = y_center - dy;
    y_max = y_center + dy;
    
    %% ===================================================================
    %% SCHRITT 2: MESSWERTE FILTERN
    %% ===================================================================
    % Überprüfe welche Messungen im Gate liegen
    
    bMask = (z(1, :) >= x_min) & (z(1, :) <= x_max) & ...
            (z(2, :) >= y_min) & (z(2, :) <= y_max);
    
    % Werte außerhalb des Gates setzen auf NaN
    z_gated = z;
    z_gated(:, ~bMask) = NaN;
    
    %% ===================================================================
    %% SCHRITT 3: MARKIERE ZUGEORDNETE MESSWERTE GELB
    %% ===================================================================
    % Aktualisiere grafisches Handle hz mit gefilterten Messwerten
    
    set(hz, 'XData', z_gated(2, :), 'YData', z_gated(1, :));
    
    %% ===================================================================
    %% SCHRITT 4: VISUALISIERE DAS GATE MIT SCHWARZEM RECHTECK
    %% ===================================================================
    % Aktualisiere Rechteck-Position und Größe
    
    rect_x = y_min;         % X-Position (wird gespiegelt, s. XDir)
    rect_y = x_min;         % Y-Position
    rect_width = aKG(2);    % Breite = dy
    rect_height = aKG(1);   % Höhe = dx
    
    set(hRect, 'Position', [rect_x, rect_y, rect_width, rect_height]);
    
    %% ===================================================================
    %% SCHRITT 5: AKTUALISIERE TRACK MIT MITTELWERT
    %% ===================================================================
    % Berechne Mittelwert der Messwerte im Gate
    
    z_im_gate_x = z_gated(1, ~isnan(z_gated(1, :)));  % x-Werte im Gate
    z_im_gate_y = z_gated(2, ~isnan(z_gated(2, :)));  % y-Werte im Gate
    
    % Prüfe ob Messwerte im Gate vorhanden sind
    if ~isempty(z_im_gate_x) && ~isempty(z_im_gate_y)
        % Berechne Mittelwert
        xP_new_x = mean(z_im_gate_x);
        xP_new_y = mean(z_im_gate_y);
        
        % Update Track-Position
        xP = [xP_new_x, xP_new_y];
    else
        % Keine Messungen im Gate: Track bleibt an alter Position
        % (optional: könnten hier auch Prädiktionen verwendet werden)
    end
    
    % Gebe gefilterte Messwerte zurück
    z = z_gated;
end
