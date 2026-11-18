%% Radar Extended Kalman-Filter - Erweiterte Version
%% mit dynamischen Daten-Operationen und robustem Datenhandling

statisch
clear all; clc;close all;
dt = 0.05;                   % Abtastzeit in s
nSamples = 401;              % Anzahl der Messwerte
t = 0:dt:(nSamples*dt - dt); % Zeitachse als Array

dynamisch nach Zeit
clear all; clc;close all;
dt = 0.05;                   % Abtastzeit in s
% Option B: Dynamisch aus Simulationsdauer berechnen
tSimulation = 20;                       % tSimulation: Gesamtsimulationszeit in s
nSamples = floor(tSimulation / dt) + 1; % nSamples: Berechnet aus Zeit (401 Samples)
fprintf('Berechnet: %d Samples für %.1f Sekunden bei dt=%.3fs\n', nSamples, tSimulation, dt);
% Zeitachse erstellen
t = 0:dt:(nSamples*dt - dt);           % t: Zeitvektor von 0 bis ~20s

%% =========================================================================
%% Radar Extended Kalman-Filter - Erweiterte Version
%% mit dynamischen Daten-Operationen und robustem Datenhandling
%% =========================================================================
clear all; clc; close all;
%% =========================================================================
%% TEIL 1: PARAMETER UND INITIALISIERUNG
%% =========================================================================
% Zeitparameter
dt = 0.05;                              % dt: Abtastzeit in s (Zeitschritt)
% Option A: Feste Anzahl (Original)
% nSamples = 401;                       % Feste Anzahl der Messwerte
% Option B: Dynamisch aus Simulationsdauer berechnen
tSimulation = 20;                       % tSimulation: Gesamtsimulationszeit in s
nSamples = floor(tSimulation / dt) + 1; % nSamples: Berechnet aus Zeit (401 Samples)
fprintf('Berechnet: %d Samples für %.1f Sekunden bei dt=%.3fs\n', nSamples, tSimulation, dt);
% Zeitachse erstellen
t = 0:dt:(nSamples*dt - dt);           % t: Zeitvektor von 0 bis ~20s
%% =========================================================================
%% TEIL 2: SPEICHER-ARRAYS INITIALISIEREN (PREALLOCATION)
%% =========================================================================
% Hauptdaten-Arrays (Preallocation für Performance)
Xsaved = zeros(nSamples, 3);           % Xsaved: Matrix (Nx3) für [pos, vel, alt]
                                        % Spalte 1: Position in m
                                        % Spalte 2: Geschwindigkeit in m/s
                                        % Spalte 3: Höhe in m
Zsaved = zeros(nSamples, 1);           % Zsaved: Vektor (Nx1) für Radar-Messwerte in m
zp = zeros(nSamples, 1);               % zp: Vektor (Nx1) für prädizierte Schrägentfernung
% Zusätzliche Datenstrukturen für erweiterte Analyse
stErgebnis = struct();                 % stErgebnis: Struktur für Endergebnisse
stErgebnis.Zeit = [];                  % Initialisierung der Felder
stErgebnis.Position = [];
stErgebnis.Geschwindigkeit = [];
stErgebnis.Hoehe = [];
%% =========================================================================
%% TEIL 3: HAUPTSCHLEIFE - DATENERFASSUNG
%% =========================================================================
fprintf('\n=== DATENERFASSUNG GESTARTET ===\n');
% Schleife über alle Messwerte
for k = 1:nSamples
    % Radarmessung simulieren
    r = LeseRadar(dt);                 % r: Aktuelle Schrägentfernung in m
    
    % Extended Kalman-Filter ausführen
    [pos, vel, alt] = RadarEKF(r, dt); % Zustandsschätzung zurückerhalten
    
    % Werte in Arrays speichern
    Xsaved(k, :) = [pos, vel, alt];    % Zeile k mit Zustandsvektor füllen
    Zsaved(k) = r;                      % Messwert speichern
    zp(k) = sqrt(pos^2 + alt^2);       % Prädizierte Schrägentfernung berechnen
    
    % Fortschritt anzeigen (alle 100 Samples)
    if mod(k, 100) == 0
        fprintf('  Progress: %d/%d Samples verarbeitet (%.1f%%)\n', ...
                k, nSamples, 100*k/nSamples);
    end
end
fprintf('=== DATENERFASSUNG ABGESCHLOSSEN ===\n\n');
%% =========================================================================
%% TEIL 4: MATRIX- UND SPALTEN-OPERATIONEN
%% =========================================================================
fprintf('=== MATRIX-OPERATIONEN ===\n');
% Spalten extrahieren (Standard-Methode)
PosSaved = Xsaved(:, 1);               % PosSaved: Alle Zeilen, Spalte 1 (Position)
VelSaved = Xsaved(:, 2);               % VelSaved: Alle Zeilen, Spalte 2 (Geschwindigkeit)
AltSaved = Xsaved(:, 3);               % AltSaved: Alle Zeilen, Spalte 3 (Höhe)
% Auf 3 Nachkommastellen runden
PosSaved = round(PosSaved, 3);         % Rundung für saubere Anzeige
VelSaved = round(VelSaved, 3);
AltSaved = round(AltSaved, 3);
% Zeilen-Operationen: Bestimmte Zeitschritte extrahieren
idx10s = round(10 / dt) + 1;           % idx10s: Index bei t=10s
if idx10s <= nSamples
    ZustandBei10s = Xsaved(idx10s, :); % ZustandBei10s: Komplette Zeile bei t=10s
    fprintf('Zustand bei t=10s: pos=%.2f m, vel=%.2f m/s, alt=%.2f m\n', ...
            ZustandBei10s(1), ZustandBei10s(2), ZustandBei10s(3));
end
% Teilmatrix extrahieren (Zeitfenster 5s bis 15s)
idxStart = round(5 / dt) + 1;          % Index bei t=5s
idxEnd = round(15 / dt) + 1;           % Index bei t=15s
if idxEnd <= nSamples
    XsavedWindow = Xsaved(idxStart:idxEnd, :); % Teilmatrix [Zeilen × alle Spalten]
    fprintf('Teilmatrix (t=5-15s): Größe = %dx%d\n', size(XsavedWindow, 1), size(XsavedWindow, 2));
end
% Transponieren (Zeilen  Spalten vertauschen)
XsavedTransposed = Xsaved';            % XsavedTransposed: (3xN) statt (Nx3)
fprintf('Original-Dimension: %dx%d, Transponiert: %dx%d\n', ...
        size(Xsaved, 1), size(Xsaved, 2), ...
        size(XsavedTransposed, 1), size(XsavedTransposed, 2));
% Spalten anhängen (Horizontale Konkatenation)
XsavedErweitert = [Xsaved, t'];        % Fügt Zeitvektor als 4. Spalte hinzu (Nx4)
fprintf('Erweiterte Matrix: %dx%d (mit Zeitstempel)\n', ...
        size(XsavedErweitert, 1), size(XsavedErweitert, 2));
% Zeilen anhängen (Vertikale Konkatenation)
mittelwerte = mean(Xsaved, 1);         % mittelwerte: Durchschnitt jeder Spalte (1x3)
XsavedMitMittelwert = [Xsaved; mittelwerte]; % Fügt Mittelwert-Zeile unten an
fprintf('Matrix mit Mittelwert-Zeile: %dx%d\n', ...
        size(XsavedMitMittelwert, 1), size(XsavedMitMittelwert, 2));
fprintf('\n');
%% =========================================================================
%% TEIL 5: STATISTISCHE ANALYSE
%% =========================================================================
fprintf('=== STATISTISCHE ANALYSE ===\n');
% Grundlegende Statistiken
meanPos = mean(PosSaved);              % meanPos: Durchschnittliche Position
stdPos = std(PosSaved);                % stdPos: Standardabweichung der Position
minPos = min(PosSaved);                % minPos: Minimale Position
maxPos = max(PosSaved);                % maxPos: Maximale Position
fprintf('Position: Mittelwert=%.2f m, Std=%.2f m, Min=%.2f m, Max=%.2f m\n', ...
        meanPos, stdPos, minPos, maxPos);
% Geschwindigkeitsanalyse
meanVel = mean(VelSaved);
maxVel = max(abs(VelSaved));           % maxVel: Maximale Geschwindigkeit (Betrag)
fprintf('Geschwindigkeit: Mittelwert=%.2f m/s, Max=%.2f m/s\n', meanVel, maxVel);
% Höhenanalyse
meanAlt = mean(AltSaved);
fprintf('Höhe: Mittelwert=%.2f m\n', meanAlt);
fprintf('\n');
%% =========================================================================
%% TEIL 6: ROBUSTES DATENEINLESEN (VERSCHIEDENE FORMATE)
%% =========================================================================
fprintf('=== DATENHANDLING-BEISPIELE ===\n');
% Methode 1: Aus MAT-Datei laden (wenn vorhanden)
matFileName = 'RadarDaten.mat';
if isfile(matFileName)
    fprintf('Lade Daten aus %s...\n', matFileName);
    loadedData = load(matFileName);    % loadedData: Struktur mit allen Variablen
    
    % Variablennamen anzeigen
    varNames = fieldnames(loadedData); % varNames: Cell-Array mit Feldnamen
    fprintf('  Gefundene Variablen: %s\n', strjoin(varNames, ', '));
    
    % Erste Variable extrahieren (anonymes Laden)
    if ~isempty(varNames)
        ersteVariable = loadedData.(varNames{1});
        fprintf('  Erste Variable: Typ=%s, Größe=%s\n', ...
                class(ersteVariable), mat2str(size(ersteVariable)));
    end
else
    fprintf('Datei %s nicht gefunden (wird übersprungen).\n', matFileName);
end
% Methode 2: Aus CSV-Datei laden (wenn vorhanden)
csvFileName = 'RadarDaten.csv';
if isfile(csvFileName)
    fprintf('Lade Daten aus %s...\n', csvFileName);
    
    try
        % Option A: Als Matrix
        dataMatrix = readmatrix(csvFileName); % dataMatrix: Numerische Matrix
        fprintf('  CSV als Matrix geladen: %dx%d\n', size(dataMatrix, 1), size(dataMatrix, 2));
        
        % Option B: Als Table (mit Spaltennamen)
        dataTable = readtable(csvFileName);   % dataTable: Table-Objekt
        fprintf('  CSV als Table geladen: %d Zeilen, %d Spalten\n', ...
                height(dataTable), width(dataTable));
        fprintf('  Spaltennamen: %s\n', strjoin(dataTable.Properties.VariableNames, ', '));
    catch ME
        fprintf('  Fehler beim CSV-Laden: %s\n', ME.message);
    end
else
    fprintf('Datei %s nicht gefunden (wird übersprungen).\n', csvFileName);
end
fprintf('\n');
%% =========================================================================
%% TEIL 7: DATENTYP-KONVERTIERUNG UND VALIDIERUNG
%% =========================================================================
fprintf('=== DATENTYP-OPERATIONEN ===\n');
% Datentypen prüfen
fprintf('Xsaved: Typ=%s, Größe=%s, Bytes=%d\n', ...
        class(Xsaved), mat2str(size(Xsaved)), numel(Xsaved) * 8);
% Konvertierung: double  single (Speicher sparen)
XsavedSingle = single(Xsaved);         % XsavedSingle: 32-bit statt 64-bit
fprintf('Als single: Bytes=%d (%.1f%% Reduktion)\n', ...
        numel(XsavedSingle) * 4, 50);
% Konvertierung: Array  Cell-Array
XsavedCell = num2cell(Xsaved, 2);      % XsavedCell: Jede Zeile als Zelle (Nx1 Cell)
fprintf('Als Cell-Array: %d Zellen\n', length(XsavedCell));
% Konvertierung: Array  Struktur
for i = 1:min(5, nSamples)             % Nur erste 5 Einträge
    stDaten(i).Position = PosSaved(i);
    stDaten(i).Geschwindigkeit = VelSaved(i);
    stDaten(i).Hoehe = AltSaved(i);
    stDaten(i).Zeit = t(i);
end
fprintf('Als Struktur-Array: %d Einträge\n', length(stDaten));
% Validierung: NaN und Inf prüfen
hasNaN = any(isnan(Xsaved(:)));        % hasNaN: true wenn NaN vorhanden
hasInf = any(isinf(Xsaved(:)));        % hasInf: true wenn Inf vorhanden
fprintf('Validierung: NaN=%s, Inf=%s\n', mat2str(hasNaN), mat2str(hasInf));
fprintf('\n');
%% =========================================================================
%% TEIL 8: DYNAMISCHE ARRAY-ERWEITERUNG (ALTERNATIVE ZU PREALLOCATION)
%% =========================================================================
fprintf('=== DYNAMISCHE ARRAY-VERWALTUNG ===\n');
% Beispiel: Dynamisches Anhängen (NUR FÜR DEMONSTRATION, LANGSAM!)
dynamicArray = [];                     % dynamicArray: Start mit leerem Array
for i = 1:10
    neuerWert = randn();               % Zufallswert
    dynamicArray(end+1) = neuerWert;   %  LANGSAM: Array wächst dynamisch
end
fprintf('Dynamisch gewachsenes Array: Länge=%d\n', length(dynamicArray));
fprintf(' WARNUNG: Dynamisches Wachsen ist LANGSAM! Besser: Preallocation\n');
% Bessere Methode: Wachsen in Blöcken
blockSize = 100;                       % blockSize: Blockgröße für Erweiterung
preallocArray = zeros(blockSize, 1);   % Initiale Größe
currentIdx = 0;                        % currentIdx: Aktueller Füll-Index
for i = 1:250
    currentIdx = currentIdx + 1;
    
    % Wenn Array voll, erweitern
    if currentIdx > length(preallocArray)
        preallocArray = [preallocArray; zeros(blockSize, 1)]; % Block hinzufügen
    end
    
    preallocArray(currentIdx) = randn();
end
% Nicht genutzte Elemente entfernen
preallocArray = preallocArray(1:currentIdx);
fprintf('Block-Wachstum: Endlänge=%d (effizienter)\n', length(preallocArray));
fprintf('\n');
%% =========================================================================
%% TEIL 9: DATEN KOMBINIEREN UND ZUSAMMENFÜHREN
%% =========================================================================
fprintf('=== DATEN KOMBINIEREN ===\n');
% Table erstellen (moderne MATLAB-Methode)
tblErgebnisse = table(t', PosSaved, VelSaved, AltSaved, Zsaved, zp, ...
                      'VariableNames', {'Zeit_s', 'Position_m', ...
                                       'Geschwindigkeit_ms', 'Hoehe_m', ...
                                       'Messung_m', 'Praediktion_m'});
fprintf('Table erstellt: %d Zeilen, %d Spalten\n', height(tblErgebnisse), width(tblErgebnisse));
fprintf('Spaltennamen: %s\n', strjoin(tblErgebnisse.Properties.VariableNames, ', '));
% Erste 5 Zeilen anzeigen
fprintf('\nErste 5 Zeilen:\n');
disp(tblErgebnisse(1:5, :));
% Zeilen filtern (z.B. nur t > 10s)
tblFiltered = tblErgebnisse(tblErgebnisse.Zeit_s > 10, :);
fprintf('Nach Filter (t>10s): %d Zeilen übrig\n', height(tblFiltered));
% Daten sortieren (nach Position aufsteigend)
tblSorted = sortrows(tblErgebnisse, 'Position_m', 'ascend');
fprintf('Sortiert nach Position: Min=%.2f m, Max=%.2f m\n', ...
        tblSorted.Position_m(1), tblSorted.Position_m(end));
fprintf('\n');
%% =========================================================================
%% TEIL 10: ENDERGEBNISSE EXTRAHIEREN
%% =========================================================================
fprintf('=== ENDERGEBNISSE ===\n');
% Endwerte (letzter Zeitschritt)
ResX = PosSaved(end);                  % ResX: Endposition in m
ResV = VelSaved(end);                  % ResV: Endgeschwindigkeit in m/s
ResH = AltSaved(end);                  % ResH: Endhöhe in m
fprintf('Endposition ResX: %.3f m\n', ResX);
fprintf('Endgeschwindigkeit ResV: %.3f m/s\n', ResV);
fprintf('Endhöhe ResH: %.3f m\n', ResH);
% In Struktur speichern
stErgebnis.Zeit = t;
stErgebnis.Position = PosSaved;
stErgebnis.Geschwindigkeit = VelSaved;
stErgebnis.Hoehe = AltSaved;
stErgebnis.Messung = Zsaved;
stErgebnis.Praediktion = zp;
stErgebnis.EndPosition = ResX;
stErgebnis.EndGeschwindigkeit = ResV;
stErgebnis.EndHoehe = ResH;
fprintf('Ergebnisse in Struktur "stErgebnis" gespeichert.\n');
% Optional: Speichern für spätere Verwendung
% save('RadarEKF_Ergebnisse.mat', 'stErgebnis', 'tblErgebnisse');
% fprintf('Daten gespeichert in RadarEKF_Ergebnisse.mat\n');
fprintf('\n');
%% =========================================================================
%% TEIL 11: VISUALISIERUNG
%% =========================================================================
figure('Name', 'Radar EKF - Erweiterte Analyse', 'NumberTitle', 'off')
% Subplot 1: Position
subplot(3, 1, 1)
plot(t, PosSaved, 'b-', 'LineWidth', 1.5)
xlabel('Zeit in s')
ylabel('x-Position in m')
title('Geschätzte Position über Zeit')
grid on
% Subplot 2: Geschwindigkeit
subplot(3, 1, 2)
plot(t, VelSaved, 'r-', 'LineWidth', 1.5)
xlabel('Zeit in s')
ylabel('Geschwindigkeit in m/s')
title('Geschätzte Geschwindigkeit über Zeit')
grid on
% Subplot 3: Höhe
subplot(3, 1, 3)
plot(t, AltSaved, 'g-', 'LineWidth', 1.5)
xlabel('Zeit in s')
ylabel('Höhe in m')
title('Geschätzte Höhe über Zeit')
grid on
fprintf('=== PROGRAMM ABGESCHLOSSEN ===\n');
%% =========================================================================
%% HILFSFUNKTIONEN (müssen am Ende der Datei stehen)
%% =========================================================================
function r = LeseRadar(dt)
% LeseRadar: Simuliert Radar-Messungen
% DUMMY-IMPLEMENTATION - mit echten Daten ersetzen
persistent posp
if isempty(posp)
    posp = 0;
end
vel = round(100 + 5*randn, 3);
alt = round(1000 + 10*randn, 3);
pos = round(posp + vel*dt, 3);
v = 0 + pos*0.05*randn;
r = sqrt(pos^2 + alt^2) + v;
posp = pos;
end
function [pos, vel, alt] = RadarEKF(r, dt)
% RadarEKF: Extended Kalman-Filter für Radar-Tracking
% DUMMY-IMPLEMENTATION - mit echtem EKF ersetzen
persistent x P A Q R H
persistent bErsterDurchlauf
if isempty(bErsterDurchlauf)
    A = eye(3) + dt*[0 1 0; 0 0 0; 0 0 0];
    Q = [0 0 0; 0 0.001 0; 0 0 0.001];
    R = 10;
    x = [0 90 1100]';
    P = 10*eye(3);
    H = [1, 0, 0];
    bErsterDurchlauf = 1;
end
xp = A*x;
Pp = A*P*A' + Q;
H_jacob = [x(1)/sqrt(x(1)^2 + x(3)^2), 0, x(3)/sqrt(x(1)^2 + x(3)^2)];
K = Pp*H_jacob'*inv(H_jacob*Pp*H_jacob' + R);
x = xp + K*(r - sqrt(xp(1)^2 + xp(3)^2));
P = Pp - K*H_jacob*Pp;
pos = x(1);
vel = x(2);
alt = x(3);
end

dt = 0.05;                    % Abtastzeit in s
nSamples = 401;               % Anzahl der Messwerte
t = 0:dt:(nSamples*dt - dt);  % Zeitachse als Array

%% Speicherplatz reservieren
Xsaved = zeros(nSamples, 3);
Zsaved = zeros(nSamples, 1);

%% Schleife über alle Messwerte
for k=1:nSamples
  r = LeseRadar(k);               % Messdaten laden
  [pos vel alt] = RadarUKF(r, dt); % UKF
  
  %% Werte speichern
  Xsaved(k, :) = [pos vel alt];
  Zsaved(k)    = r;
end 

PosSaved = Xsaved(:, 1);
VelSaved = Xsaved(:, 2);
AltSaved = Xsaved(:, 3);

%% Ergebnisspeicher
ResX = PosSaved(end)
ResV = VelSaved(end)
ResH = AltSaved(end)

figure
subplot 311
hold on
line([0 20],[0 2000],'Color',[1 0 0])
plot(t, PosSaved)
xlabel('Zeit in s')
ylabel('Horizontale Entfernung in m')
legend('Wahrer Wert','UKF Schätzung','Location','Best')

subplot 312
hold on
line([0 20],[100 100],'Color',[1 0 0])
plot(t, VelSaved)
xlabel('Zeit in s')
ylabel('Horizontale Geschwindigkeit in m/s')
legend('Wahrer Wert','UKF Schätzung','Location','Best')

subplot 313
hold on
line([0 20],[1000 1000],'Color',[1 0 0])
plot(t, AltSaved)
xlabel('Zeit in s')
ylabel('Höhe in m')
legend('Wahrer Wert','UKF Schätzung','Location','Best')
ylim([990 1050])

function [pos vel alt] = RadarUKF(z, dt)
%
%
persistent Q R
persistent x P
persistent n m
persistent bErsterDurchlauf 

%% Initalisierung der Variablen bei ersten Durchlauf
if isempty(bErsterDurchlauf )
  SigmaQ=0;     % LÖSUNG ERFORDERLICH
  Q = 0*eye(3); % LÖSUNG ERFORDERLICH
  
  SigmaR=0;     % LÖSUNG ERFORDERLICH
  R = 0*eye(3); % LÖSUNG ERFORDERLICH

  x = 0;        % LÖSUNG ERFORDERLICH
  P = 0*eye(3); % LÖSUNG ERFORDERLICH

  n = 0; % LÖSUNG ERFORDERLICH
  m = 0; % LÖSUNG ERFORDERLICH
  
  bErsterDurchlauf  = 1;  
  disp('UKF wurde initialisiert.')
end

%% Prädiktion
[Xi W] = SigmaPunkte(x, P, 0); % Berechnung der Sigma-Punkte und Gewichte

fXi = zeros(n, 2*n+1);
for k = 1:2*n+1
  fXi(:, k) = fx(Xi(:,k), dt);
end

[xp Pp] = UT(fXi, W, Q); % Vorhersage des Zustandsvektors und der Kovarianz

%% Schätzung
hXi = zeros(m, 2*n+1);
for k = 1:2*n+1
  hXi(:, k) = hx(fXi(:,k));
end

[zp Pz] = UT(hXi, W, R); % Vorhersage des Messvektors und der Kovarianz
%norm(zp - hx(xp))

Pxz = zeros(n, m);
for k = 1:2*n+1
  Pxz = Pxz + W(k)*(fXi(:, k) - xp)*(hXi(:, k) - zp)';
end

K = Pxz*inv(Pz);     % Berechnung der Kalman-Verstärkung

x = xp + K*(z - zp); % Korrektur der Zustandsschätzung
P = Pp - K*Pz*K';    % 6. Korrektur der Kovarianzschätzung

%% Rückgabewerte 
pos = x(1);
vel = x(2);
alt = x(3);
end

%------------------------------
function xp = fx(x, dt)
%
%
xp = 0; % Prädiktion  % LÖSUNG ERFORDERLICH
end

%------------------------------
function yp = hx(x)
%
%
yp = 0; % LÖSUNG ERFORDERLICH
end


sFileName = 'Messdaten_B';
load(sFileName);
dt = Zeit(2) - Zeit(1);
Nsamples = length(Zeit);
Xsaved = zeros(Nsamples, 2);
Zsaved = zeros(Nsamples, 1);
for k=1:Nsamples
    z = Hoehe(k);
    x = UnscentedKalmanFilter(z, dt);
    Xsaved(k,:) = x';
    Zsaved(k) = z;
end
PositionSaved = Xsaved(:, 1);
VelocitySaved = Xsaved(:, 2);
idxAufprall = find(PositionSaved <= 0, 1, 'first');
if isempty(idxAufprall)
    idxAufprall = Nsamples;
end
tMax = Zeit(idxAufprall);
vMax = abs(VelocitySaved(idxAufprall));
m_penny = 2.5e-3;
Ekin = 0.5 * m_penny * vMax^2;
btoetlich = (Ekin >= 80);

function xEst = UnscentedKalmanFilter(z, dt)
persistent Q R
persistent x P
persistent n m
persistent bErsterDurchlauf
persistent g
if isempty(bErsterDurchlauf)
    g = 9.81;
    SigmaQ_pos = 0.1;
    SigmaQ_vel = 0.5;
    Q = diag([SigmaQ_pos^2, SigmaQ_vel^2]);
    SigmaR = 0.5;
    R = SigmaR^2;
    x = [z; 0];
    P = diag([1, 1]);
    n = 2;
    m = 1;
    bErsterDurchlauf = 1;
    disp('UKF für Penny Falling wurde initialisiert.');
end
[Xi, W] = SigmaPunkte(x, P, 0);
fXi = zeros(n, 2*n+1);
for k = 1:2*n+1
    fXi(:, k) = fx(Xi(:,k), dt, g);
end
[xp, Pp] = UT(fXi, W, Q);
hXi = zeros(m, 2*n+1);
for k = 1:2*n+1
    hXi(:, k) = hx(fXi(:,k));
end
[zp, Pz] = UT(hXi, W, R);
Pxz = zeros(n, m);
for k = 1:2*n+1
    Pxz = Pxz + W(k)*(fXi(:, k) - xp)*(hXi(:, k) - zp)';
end
K = Pxz / Pz;
x = xp + K*(z - zp);
P = Pp - K*Pz*K';
xEst = x;
end
function xp = fx(x, dt, g)
F = [1, dt;
     0, 1];
B = [0.5*dt^2;
     dt];
u = -g;
xp = F * x + B * u;
end
function yp = hx(x)
yp = x(1);
end
function [xm, xcov] = UT(Xi, W, noiseCov)
[n, kmax] = size(Xi);
xm = 0;
for k=1:kmax
    xm = xm + W(k)*Xi(:, k);
end
xcov = zeros(n, n);
for k=1:kmax
    xcov = xcov + W(k)*(Xi(:, k) - xm)*(Xi(:, k) - xm)';
end
xcov = xcov + noiseCov;
end
function [Xi, W] = SigmaPunkte(xm, P, kappa)
n  = numel(xm);
Xi = zeros(n, 2*n+1);
W  = zeros(2*n+1, 1);
Xi(:, 1) = xm;
W(1)     = kappa / (n + kappa);
U = chol((n+kappa)*P);
for k=1:n
    Xi(:, k+1) = xm + U(k, :)';
    W(k+1)     = 1 / (2*(n+kappa));
end
for k=1:n
    Xi(:, n+k+1) = xm - U(k, :)';
    W(n+k+1)     = 1 / (2*(n+kappa));
end
end
