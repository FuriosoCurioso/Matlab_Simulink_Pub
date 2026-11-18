% ZeigeMessdaten.m - Darstellung LiDAR-Scan Frame 200

%% Initialisierung
clear all; close all; clc

%% Messdaten laden aus MAT-Datei
% stDateiName: Dateiname der LiDAR-Messdaten
% Datei enthält: Zeit, RangeScan, x, y (aus vorheriger Verarbeitung)
stDateiName = 'LiDAR.mat';

% Lade Variablen x, y aus MAT-Datei
% x: Matrix mit x-Koordinaten aller Scans im LiDAR-KOS (nScans x nSamples)
% y: Matrix mit y-Koordinaten aller Scans im LiDAR-KOS (nScans x nSamples)
load(stDateiName);

%% Frame 200 auswählen und Daten extrahieren
% nFrame: Frame-Nummer für Darstellung (200. Scan)
nFrame = 200;

% x_frame - x-Koordinaten des 200. Scans im LiDAR-KOS
% Extrahiert Zeile 200 aus Matrix x (alle 682 Messpunkte dieses Scans)
x_frame = x(nFrame, :);

% y_frame - y-Koordinaten des 200. Scans im LiDAR-KOS
% Extrahiert Zeile 200 aus Matrix y (alle 682 Messpunkte dieses Scans)
y_frame = y(nFrame, :);

%% Figure vorbereiten und konfigurieren
% Erstelle Figure-Fenster mit Titel "Frame: 200"
figure('Name', sprintf('Frame: %d', nFrame), 'Position', [100, 100, 800, 600]);
hold on;  % Mehrere Plot-Befehle in einer Figure
grid on;  % Gitterlinien einblenden
axis equal; % Gleiche Skalierung für x- und y-Achse (metrisch korrekt)

%% KOS-Transformation LiDAR-KOS {L} -> Fahrzeug-KOS {F}
%
% Problemstellung:
%   LiDAR-KOS {L}: x_L nach rechts, y_L nach vorne (Fahrtrichtung)
%   Fahrzeug-KOS {F}: x_F nach vorne (Fahrtrichtung), y_F nach links
%
% Geforderte KOS-Transformation:
%   x_F = y_L   (Fahrtrichtung nach vorne = LiDAR y-Achse)
%   y_F = -x_L  (Nach links = negative LiDAR x-Achse)
%
% Mathematische Transformationsmatrix:
%   [x_F]   [ 0  1] [x_L]
%   [y_F] = [-1  0] [y_L]
%
% MATLAB Plot-Konvention:
%   plot(x_plot, y_plot) wobei:
%   - x_plot: horizontale Achse (wird zu y_F)
%   - y_plot: vertikale Achse (wird zu x_F)
%
% Daher: plot(-x_frame, y_frame)
%   - Erste Achse (horizontal): -x_frame = y_F (nach links)
%   - Zweite Achse (vertikal):  y_frame = x_F (nach vorne)

% hPlot - Handle auf Messdaten-Plot (rote Punkte)
% Handle ermöglicht spätere Manipulation der Plot-Eigenschaften ohne Neuzeichnen
% Transformation: y_F = -x_L (horizontal), x_F = y_L (vertikal)
hPlot = plot(-x_frame, y_frame, 'r.', 'MarkerSize', 8);
hPlot = line(-x_frame, y_frame, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'Color', 'r', ...
    'MarkerSize', 8);
%% Anzeigebereich anpassen (entsprechend Abb. 1)
% xlim: Bereich der horizontalen Achse (y_F: nach links positiv)
xlim([-5, 5]);   % y_F Bereich: -5 m (rechts) bis +5 m (links)

% ylim: Bereich der vertikalen Achse (x_F: nach vorne positiv)
ylim([-1, 5]);   % x_F Bereich: -1 m (hinten) bis +5 m (vorne)

%% Koordinatensystem-Achsen des Fahrzeug-KOS {F} einzeichnen

% x_F-Achse (vertikal, nach oben = Fahrtrichtung)
% Zeichnet vertikale Linie von (0,0) nach (0,4) im Plot-KOS
% Im Fahrzeug-KOS: y_F=0, x_F von 0 bis 4 m
plot([0, 0], [0, 4], 'k-', 'LineWidth', 2.5);

% Pfeilspitze für x_F-Achse
quiver(0, 3.5, 0, 0.5, 0, 'k', 'LineWidth', 2.5, 'MaxHeadSize', 0.8);

% Beschriftung x_F-Achse
text(0.2, 4.2, 'x_F', 'FontSize', 12, 'FontWeight', 'bold');

% y_F-Achse (horizontal, nach links = negative x-Richtung im Plot)
% Zeichnet horizontale Linie von (0,0) nach (-4,0) im Plot-KOS
% Im Fahrzeug-KOS: x_F=0, y_F von 0 bis 4 m (nach links)
plot([0, -4], [0, 0], 'k-', 'LineWidth', 2.5);

% Pfeilspitze für y_F-Achse (zeigt nach links)
quiver(-3.5, 0, -0.5, 0, 0, 'k', 'LineWidth', 2.5, 'MaxHeadSize', 0.8);

% Beschriftung y_F-Achse
text(-4.5, 0.2, 'y_F', 'FontSize', 12, 'FontWeight', 'bold');

%% Linie bei y_F=0 m (vertikale Hilfslinie)
% Markiert Mittellinie des Fahrzeugs (Symmetrieachse)
% Vertikal durch (0,0) über gesamten y-Achsen-Bereich
plot([0, 0], ylim, 'b-', 'LineWidth', 1);

%% Achsenbeschriftungen und Titel
% xlabel: Beschriftung der horizontalen Achse (y_F-Achse)
xlabel('y_F in m', 'FontSize', 12);
hAxes = gca;
set(hAxes, 'XLim', [-5, 5]);
set(hAxes, 'YLim', [-1, 5]);
% ylabel: Beschriftung der vertikalen Achse (x_F-Achse)
ylabel('x_F in m', 'FontSize', 12);

% title: Titel mit Frame-Nummer
title(sprintf('Frame: %d', nFrame), 'FontSize', 14, 'FontWeight', 'bold');
line([0, 0], [0, 4], 'Color', 'k', 'LineWidth', 2.5);
line([0, -4], [0, 0], 'Color', 'k', 'LineWidth', 2.5);
line([0, 0], ylim, 'Color', 'b', 'LineWidth', 1);
hold off; % Beende Plot-Modus

%% Verifikation der KOS-Transformation und Darstellung
fprintf('========== VERIFIKATION ==========\n');
fprintf('Datei geladen: %s\n', stDateiName);
fprintf('Frame: %d\n', nFrame);
fprintf('Anzahl Messpunkte: %d\n', length(x_frame));
fprintf('\n');
fprintf('KOS-Transformation LiDAR -> Fahrzeug:\n');
fprintf('  LiDAR-KOS {L}: x_L nach rechts, y_L nach vorne\n');
fprintf('  Fahrzeug-KOS {F}: x_F nach vorne, y_F nach links\n');
fprintf('  Transformation: x_F = y_L, y_F = -x_L\n');
fprintf('  MATLAB-Plot: plot(-x_frame, y_frame)\n');
fprintf('    -> Horizontal: y_F = -x_L (nach links positiv)\n');
fprintf('    -> Vertikal:   x_F = y_L (nach vorne positiv)\n');
fprintf('\n');
fprintf('Darstellung:\n');
fprintf('  Messpunkte: rote Punkte (r., MarkerSize 8)\n');
fprintf('  Handle hPlot: verfügbar für dynamische Aktualisierung\n');
fprintf('  Koordinatensystem {F}: x_F (vertikal), y_F (horizontal)\n');
fprintf('  Anzeigebereich: y_F [-5, 5] m, x_F [-1, 5] m\n');
fprintf('==================================\n');
