% =========================================================================
% Penny Falling Simulation mit Unscented Kalman-Filter (UKF)
% =========================================================================
% Dieses Programm schätzt die Fallzeit und Aufprallgeschwindigkeit eines
% Pennys, der vom Empire State Building (381m) fällt, unter Verwendung
% verrauschter Höhenmessungen.
% =========================================================================

close all; clear all; clc;

% Initialisierung
% Messdaten laden: Hoehe (1x882), Zeit (1x882)
sFileName = 'Messdaten_B';
load(sFileName); % Lädt Variablen 'Hoehe' und 'Zeit' aus .mat-Datei

% Bestimmung der Abtastzeit aus den Zeitdaten
dt = Zeit(2) - Zeit(1); % Abtastzeit in s: Zeitdifferenz zwischen Messungen (~0.01s)

Nsamples = length(Zeit); % Anzahl der Messwerte: Gesamtlänge der Zeitreihe
Xsaved = zeros(Nsamples, 2); % Speicher für geschätzte Zustände [Position; Geschwindigkeit]
Zsaved = zeros(Nsamples, 1); % Speicher für Messwerte (Höhe)

% Schleife über alle Messwerte
for k=1:Nsamples
    % Messdaten laden: Höhenmessung zum Zeitpunkt k
    z = Hoehe(k); % z: Gemessene Höhe in m
    
    % Unscented Kalman Filter
    % Rückgabewert des Kalman-Filters ist die Zustandsschätzung [Position; Geschwindigkeit]
    x = UnscentedKalmanFilter(z, dt); 
    
    % Daten sichern
    Xsaved(k,:) = x'; % Transponiert, da x ein Spaltenvektor ist
    Zsaved(k) = z;
end

%% Ergebnisse berechnen

% Finde den Zeitpunkt, zu dem der Penny bei 0m (Boden) ankommt
% Position startet bei ~381m und sinkt auf 0m
PositionSaved = Xsaved(:, 1); % Geschätzte Position über Zeit
VelocitySaved = Xsaved(:, 2); % Geschätzte Geschwindigkeit über Zeit

% Finde Index, wo Position den Boden erreicht (≈0m oder negativ wird)
idxAufprall = find(PositionSaved <= 0, 1, 'first');

if isempty(idxAufprall)
    % Falls Boden nicht erreicht, nehme letzten Wert
    idxAufprall = Nsamples;
end

% Fallzeit: Zeit bis zum Aufprall
tMax = Zeit(idxAufprall); % Fallzeit in s

% Maximale Fallgeschwindigkeit: Geschwindigkeit beim Aufprall (negativ, da nach unten)
vMax = abs(VelocitySaved(idxAufprall)); % Auftreffgeschwindigkeit in m/s (Betrag)

% Kinetische Energie beim Auftreffen
m_penny = 2.5e-3; % Masse des Pennys in kg (2.5g = 0.0025kg)
Ekin = 0.5 * m_penny * vMax^2; % Kinetische Energie in J: E = 0.5*m*v²

% Tödliche Grenze: 80J
btoetlich = (Ekin >= 80); % true wenn kinetische Energie >= 80J

% Ausgabe der Ergebnisse
fprintf('=== ERGEBNISSE ===\n');
fprintf('Fallzeit tMax: %.4f s\n', tMax);
fprintf('Auftreffgeschwindigkeit vMax: %.4f m/s\n', vMax);
fprintf('Kinetische Energie Ekin: %.4f J\n', Ekin);
fprintf('Tödlich (>=80J): %s\n', mat2str(btoetlich));

%% Ergebnisse darstellen

figure('Name', 'Penny Falling - UKF Ergebnisse', 'NumberTitle', 'off');

% Subplot 211: Höhe über Zeit
subplot(2,1,1)
hold on
plot(Zeit, Hoehe, 'b.', 'MarkerSize', 3, 'DisplayName', 'Gemessene Höhe (verrauscht)');
plot(Zeit, PositionSaved, 'r-', 'LineWidth', 2, 'DisplayName', 'UKF Schätzung');
plot(tMax, 0, 'ko', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Aufprall');
xlabel('Zeit in s');
ylabel('Höhe in m');
title('Fallhöhe des Pennys');
legend('Location', 'Best');
grid on;
hold off;

% Subplot 212: Geschwindigkeit über Zeit
subplot(2,1,2)
hold on
plot(Zeit, VelocitySaved, 'g-', 'LineWidth', 2, 'DisplayName', 'UKF Geschwindigkeit');
plot(tMax, -vMax, 'ko', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Aufprall');
xlabel('Zeit in s');
ylabel('Geschwindigkeit in m/s');
title(sprintf('Geschwindigkeit des Pennys (v_{max} = %.2f m/s)', vMax));
legend('Location', 'Best');
grid on;
hold off;


%% ========================================================================
% HAUPTFUNKTION: UnscentedKalmanFilter
% ========================================================================
% Implementiert den Unscented Kalman-Filter für den freien Fall
% 
% Eingänge:
%   z  - Messwert (Höhe in m): Skalare Höhenmessung vom Boden aus
%   dt - Abtastzeit in s: Zeitschritt zwischen Messungen
%
% Ausgänge:
%   xEst - Geschätzter Zustandsvektor [Position; Geschwindigkeit]
% ========================================================================
function xEst = UnscentedKalmanFilter(z, dt)

% Persistente Variablen: Behalten das Werte zwischen Funktionsaufrufen
persistent Q R % Kovarianzmatrizen für System- und Messrauschen
persistent x P % Zustandsvektor und Kovarianzmatrix des Schätzfehlers
persistent n m % Dimensionen: n=Zustandsvektor, m=Messvektor
persistent bErsterDurchlauf % Flag für Initialisierung
persistent g % Erdbeschleunigung

%% Initialisierung beim ersten Durchlauf
if isempty(bErsterDurchlauf)
    % Physikalische Konstante
    g = 9.81; % Erdbeschleunigung in m/s² (nach unten positiv)
    
    % Systemrauschen: Modelliert Unsicherheiten in der Dynamik
    SigmaQ_pos = 0.1; % Standardabweichung für Position in m
    SigmaQ_vel = 0.5; % Standardabweichung für Geschwindigkeit in m/s
    Q = diag([SigmaQ_pos^2, SigmaQ_vel^2]); % Q: 2x2 Kovarianzmatrix
    
    % Messrauschen: Unsicherheit in der Höhenmessung
    SigmaR = 0.5; % Standardabweichung des Messrauschens in m
    R = SigmaR^2; % R: Skalare Varianz (nur eine Messgröße: Höhe)
    
    % Initialzustand: Anfangsschätzung basierend auf erster Messung
    % Penny startet bei ~381m Höhe mit Geschwindigkeit 0 m/s
    x = [z; 0]; % x: 2x1 Vektor [Höhe; Geschwindigkeit]
    
    % Initiale Kovarianzmatrix: Unsicherheit der Anfangsschätzung
    P = diag([1, 1]); % P: 2x2 Matrix, kleine Anfangsunsicherheit
    
    % Dimensionen des Systems
    n = 2; % n: Anzahl der Zustandsgrößen (Position, Geschwindigkeit)
    m = 1; % m: Anzahl der Messgrößen (nur Höhe)
    
    bErsterDurchlauf = 1; % Initialisierung abgeschlossen
    disp('UKF für Penny Falling wurde initialisiert.');
end

%% ========================================================================
% PRÄDIKTION (Vorhersageschritt)
% ========================================================================

% Berechnung der Sigma-Punkte und Gewichte
[Xi, W] = SigmaPunkte(x, P, 0); % Xi: 2x5 Matrix, W: 5x1 Vektor

% Transformation der Sigma-Punkte durch Systemmodell fx()
fXi = zeros(n, 2*n+1); % fXi: 2x5 Matrix für transformierte Sigma-Punkte
for k = 1:2*n+1
    fXi(:, k) = fx(Xi(:,k), dt, g); % Wende Zustandsübergangsmodell an
end

% Vorhersage des Zustandsvektors und der Kovarianz
[xp, Pp] = UT(fXi, W, Q); % xp: 2x1 prädizierter Zustand, Pp: 2x2 Kovarianz

%% ========================================================================
% SCHÄTZUNG (Korrekturschritt)
% ========================================================================

% Transformation der Sigma-Punkte durch Messmodell hx()
hXi = zeros(m, 2*n+1); % hXi: 1x5 Matrix für transformierte Sigma-Punkte
for k = 1:2*n+1
    hXi(:, k) = hx(fXi(:,k)); % Wende Messmodell an
end

% Vorhersage des Messvektors und der Kovarianz
[zp, Pz] = UT(hXi, W, R); % zp: 1x1 vorhergesagte Messung, Pz: 1x1 Kovarianz

% Berechnung der Kreuzkovarianz zwischen Zustand und Messung
Pxz = zeros(n, m); % Pxz: 2x1 Kreuzkovarianzmatrix
for k = 1:2*n+1
    Pxz = Pxz + W(k)*(fXi(:, k) - xp)*(hXi(:, k) - zp)';
end

% Berechnung der Kalman-Verstärkung
K = Pxz / Pz; % K: 2x1 Kalman-Verstärkung

% Korrektur der Zustandsschätzung
x = xp + K*(z - zp); % Innovation: Differenz zwischen Messung und Vorhersage

% Korrektur der Kovarianzschätzung
P = Pp - K*Pz*K'; % Joseph-Form für numerische Stabilität

% Rückgabewert
xEst = x; % Geschätzter Zustandsvektor [Position; Geschwindigkeit]
end


%% ========================================================================
% UNTERFUNKTION: fx (Zustandsübergangsmodell)
% ========================================================================
% Beschreibt die Systemdynamik des freien Falls
%
% Systemmodell (Freier Fall ohne Luftwiderstand):
%   x1(k+1) = x1(k) + x2(k)*dt - 0.5*g*dt²  (Position)
%   x2(k+1) = x2(k) - g*dt                   (Geschwindigkeit)
%
% Eingänge:
%   x  - Zustandsvektor 2x1: [Position; Geschwindigkeit]
%   dt - Abtastzeit in s
%   g  - Erdbeschleunigung in m/s²
%
% Ausgang:
%   xp - Prädizierter Zustandsvektor 2x1
% ========================================================================
function xp = fx(x, dt, g)
% Systemmatrix für freien Fall (diskretisiert)
% Position: x1 + x2*dt - 0.5*g*dt²
% Geschwindigkeit: x2 - g*dt (Beschleunigung nach unten)

F = [1, dt;    % Position ändert sich mit Geschwindigkeit
     0, 1];    % Geschwindigkeit ändert sich mit Beschleunigung

B = [0.5*dt^2; % Einfluss der Beschleunigung auf Position
     dt];      % Einfluss der Beschleunigung auf Geschwindigkeit

u = -g; % Beschleunigung nach unten (negativ, da Höhe abnimmt)

xp = F * x + B * u; % Prädiktion
end


%% ========================================================================
% UNTERFUNKTION: hx (Messmodell)
% ========================================================================
% Beschreibt die Messabbildung: Messung der Höhe
%
% Messmodell (linear):
%   z = x1  (Höhe wird direkt gemessen)
%
% Eingang:
%   x - Zustandsvektor 2x1: [Position; Geschwindigkeit]
%
% Ausgang:
%   yp - Vorhergesagte Messung (skalarer Wert): Höhe in m
% ========================================================================
function yp = hx(x)
% Lineares Messmodell: Höhe wird direkt gemessen
yp = x(1); % Nur die Position (Höhe) wird gemessen
end


%% ========================================================================
% UNTERFUNKTIONEN aus Referenzierte-Dateien.txt
% ========================================================================

% UT.m - Unscented Transformation
% Berechnet Mittelwert und Kovarianz aus gewichteten Sigma-Punkten
function [xm, xcov] = UT(Xi, W, noiseCov)
[n, kmax] = size(Xi); % n: Dimension, kmax: Anzahl Sigma-Punkte

% Gewichteter Mittelwert
xm = 0;
for k=1:kmax
    xm = xm + W(k)*Xi(:, k); % Summiere gewichtete Sigma-Punkte
end

% Gewichtete Kovarianz
xcov = zeros(n, n);
for k=1:kmax
    xcov = xcov + W(k)*(Xi(:, k) - xm)*(Xi(:, k) - xm)';
end
xcov = xcov + noiseCov; % Addiere Rauschkovarianz
end


% SigmaPunkte.m - Generierung von Sigma-Punkten
% Erzeugt symmetrisch verteilte Punkte um den Mittelwert
function [Xi, W] = SigmaPunkte(xm, P, kappa)
n  = numel(xm); % Dimension des Zustandsvektors
Xi = zeros(n, 2*n+1); % 2n+1 Sigma-Punkte
W  = zeros(2*n+1, 1); % Zugehörige Gewichte

% Zentraler Sigma-Punkt
Xi(:, 1) = xm; % Mittelwert
W(1)     = kappa / (n + kappa); % Gewicht des zentralen Punkts

% Cholesky-Zerlegung: U'*U = (n+kappa)*P
U = chol((n+kappa)*P); % Obere Dreiecksmatrix

% Positive Sigma-Punkte
for k=1:n
    Xi(:, k+1) = xm + U(k, :)'; % Mittelwert + Zeile von U
    W(k+1)     = 1 / (2*(n+kappa)); % Symmetrisches Gewicht
end

% Negative Sigma-Punkte
for k=1:n
    Xi(:, n+k+1) = xm - U(k, :)'; % Mittelwert - Zeile von U
    W(n+k+1)     = 1 / (2*(n+kappa)); % Symmetrisches Gewicht
end
end
