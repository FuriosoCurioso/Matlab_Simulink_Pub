% Laden und Verarbeiten von Hokuyo LiDAR-Messdaten

%% Initialisierung
clc; clear all; close all;
%% Eingangsgrößen:
stDateiName = 'Lidar.ubh'; % Eingangsdatei
nSamples = 682;            % Anzahl der Messwerte

%% Eingangsgrößen: - Konstanten für LiDAR-Sensor
stDateiName = 'Lidar.ubh'; % Eingangsdatei: Hokuyo URG-04LX Daten
nSamples = 682; % Anzahl der Messwerte pro Scan

%% Datei öffnen (Lesemodus)
% fid: File Identifier für geöffnete Datei
fid = fopen(stDateiName, 'r');

% Fehlerbehandlung: Prüfe ob Datei erfolgreich geöffnet wurde
if fid == -1
    error('Datei %s konnte nicht geöffnet werden!', stDateiName);
end

%% Winkelauflösung und Winkelarray berechnen
% LiDAR-Spezifikation: 682 Messungen von -120° bis +120° (240° Bereich)
% Aufloesung: Winkelauflösung in Grad zwischen zwei Messungen
Aufloesung = 240 / (nSamples - 1); % Winkelauflösung in deg

% aWinkel - Array mit allen Winkeln von -120° bis +120°
aWinkel = -120:Aufloesung:120; % Array mit nSamples Einträgen

%% Einmalige Trigonometrie-Berechnung (Effizienzoptimierung)
% Vorberechnung von cos und sin für alle Winkel (nur einmal durchführen!)
% Vermeidet wiederholte Berechnungen in der Schleife

% Winkel von Grad in Radianten konvertieren
aWinkelRad = deg2rad(aWinkel);

% acosdw - Array mit Kosinuswerten aller Winkel (nSamples Einträge)
% Wird für x-Koordinaten-Berechnung verwendet: x = r * cos(theta)
cosd = cos(aWinkelRad);

% asindw - Array mit Sinuswerten aller Winkel (nSamples Einträge)
% Wird für y-Koordinaten-Berechnung verwendet: y = r * sin(theta)
sind = sin(aWinkelRad);

%% Initialisierung der Ergebnisvariablen
% Speicher reservieren (Arrays dynamisch erweitern mit end+1)
Zeit = [];       % Zeit: Zeitstempel jedes Scans in Sekunden
RangeScan = [];  % RangeScan: Schrägentfernungen in m (nScans x nSamples)
x = [];          % x: kartesische x-Koordinaten in m (nScans x nSamples)
y = [];          % y: kartesische y-Koordinaten in m (nScans x nSamples)

i = 0;           % Zähler für Anzahl der Scans
fStartZeit = -1; % Startzeitpunkt (wird beim ersten Scan gesetzt)

%% Schleife - Datei zeilenweise einlesen und verarbeiten
while ~feof(fid)
    % Zeile aus Datei lesen
    stZeile = fgetl(fid);
    
    % Prüfe ob Zeile einen Zeitstempel enthält
    if contains(stZeile, '[timestamp]')
        % Nächste Zeile enthält Zeitstempel-Wert
        stZeile = fgetl(fid);
        fZeitstempel = str2double(stZeile); % Zeitstempel in ms
        
        % Zeit(i) - Setze Startzeit auf 0 s beim ersten Scan
        if fStartZeit == -1
            fStartZeit = fZeitstempel; % Ersten Zeitstempel als Referenz speichern
        end
        
        % Inkrementiere Scan-Zähler
        i = i + 1;
        
        % Zeit - Berechne relative Zeit in Sekunden (Startzeit = 0 s)
        Zeit(i) = (fZeitstempel - fStartZeit) / 1000; % ms -> s
    end
    
    % Prüfe ob Zeile Messdaten enthält
    if contains(stZeile, '[scan]')
        % Nächste Zeile enthält Messwerte (durch Semikolon getrennt)
        stZeile = fgetl(fid);
        
        % RangeScan - Parse Messwerte und konvertiere zu numerischem Array
        % Messwerte sind durch Semikolon getrennt, in mm angegeben
        aMesswerte = str2double(split(stZeile, ';')); % String -> Double Array
        
        % RangeScan(i,:) - Konvertiere mm zu m und speichere
        RangeScan(i, :) = aMesswerte(1:nSamples)' / 1000; % mm -> m, Zeile speichern
        
        % KOS-Transformation Polar -> Kartesisch mit Matrizenrechnung
        % Polarkoordinaten: (r, theta) -> Kartesisch: (x, y)
        % Formeln: x = r * cos(theta), y = r * sin(theta)
        
        % x(i,:) - Berechne x-Koordinaten für alle Messpunkte des Scans
        % Element-weise Multiplikation: r .* cos(theta)
        x(i, :) = RangeScan(i, :) .* cosd;
        
        % y(i,:) - Berechne y-Koordinaten für alle Messpunkte des Scans
        % Element-weise Multiplikation: r .* sin(theta)
        y(i, :) = RangeScan(i, :) .* sind;
    end
end

%% Datei schließen (wichtig für Speichermanagement)
fclose(fid);

%% Daten speichern in MAT-Datei
stSaveFileName = 'Messdaten.mat';

% Speichere alle Variablen: Zeit, RangeScan, x, y
save(stSaveFileName, 'Zeit', 'RangeScan', 'x', 'y');

disp([stSaveFileName, ' wurde gespeichert...'])

%% Verifikation der Ergebnisse
fprintf('========== VERIFIKATION ==========\n');
fprintf('Winkelauflösung Aufloesung = %.4f°\n', Aufloesung);
fprintf('Winkelarray aWinkel: %d Einträge von %.0f° bis %.0f°\n', ...
    length(aWinkel), aWinkel(1), aWinkel(end));
fprintf('Kosinusarray cosd: %d Einträge\n', length(cosd));
fprintf('Sinusarray sind: %d Einträge\n', length(sind));
fprintf('Anzahl Scans: %d\n', i);
fprintf('Zeit-Array: %d Einträge (%.3f s bis %.3f s)\n', length(Zeit), Zeit(1), Zeit(end));
fprintf('RangeScan: %d x %d Matrix (Scans x Samples)\n', size(RangeScan, 1), size(RangeScan, 2));
fprintf('x-Koordinaten: %d x %d Matrix\n', size(x, 1), size(x, 2));
fprintf('y-Koordinaten: %d x %d Matrix\n', size(y, 1), size(y, 2));
fprintf('Datei gespeichert: %s\n', stSaveFileName);
fprintf('==================================\n');

%% Optional: Visualisierung (wie im Referenzbild)
figure('Name', 'LiDAR-Scanrichtung', 'Position', [100, 100, 800, 600]);
hold on;
axis equal;
grid on;

% Plotte ersten Scan als Beispiel
plot(x(1, :), y(1, :), 'g.', 'MarkerSize', 10);

% Koordinatensystem
plot([0 1], [0 0], 'b-', 'LineWidth', 2); % X-Achse
plot([0 0], [0 1], 'b-', 'LineWidth', 2); % Y-Achse
text(1.2, 0, 'X_{LiDAR}', 'FontSize', 12, 'Color', 'b');
text(0, 1.2, 'Y_{LiDAR}', 'FontSize', 12, 'Color', 'b');

% Scanrichtung einzeichnen
quiver(0.5, 0.5, 0.3, 0.2, 'b', 'LineWidth', 2, 'MaxHeadSize', 1);
text(0.9, 0.8, 'Scanrichtung', 'FontSize', 10, 'Color', 'b');

xlabel('x in m', 'FontSize', 12);
ylabel('y in m', 'FontSize', 12);
title('LiDAR-Scanrichtung', 'FontSize', 14, 'FontWeight', 'bold');
legend('Messpunkte', 'Location', 'best');

hold off;