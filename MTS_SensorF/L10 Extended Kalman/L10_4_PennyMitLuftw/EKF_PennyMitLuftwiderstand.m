%% Extended Kalman-Filter für fallenden Penny mit Luftwiderstand
% =========================================================================
% Schritt: Schätzung der Aufprallgeschwindigkeit nach 381m freiem Fall
% Modell: Freier Fall mit Windwiderstand
% =========================================================================

clear all; close all; clc;

%% Initialisierung - Parameter
dt = 0.01;                              % dt: Abtastzeit in s
g = 9.81;                               % g: Erdbeschleunigung in m/s²
m = 2.5e-3;                             % m: Masse des Pennys in kg (2.5g)
cw = 1.17;                              % cw: Luftwiderstandskoeffizient
rho = 1.225;                            % rho: Luftdichte in kg/m³
d = 19.05e-3;                           % d: Durchmesser in m (19.05mm)
A = pi * (d/2)^2;                       % A: Querschnittsfläche in m²

% Luftwiderstandskraft-Parameter: Fw = k * v * |v|
k = 0.5 * cw * rho * A;                 % k: Widerstandskoeffizient

%% Messdaten laden
sFileName = 'Messdaten_B';
load(sFileName);                        % Lädt: Zeit, Hoehe

nSamples = length(Zeit);                % nSamples: Anzahl der Messwerte
% xSaved: Gespeicherte Zustände (Nx3 Spalten mit 1:Hoehe;2:Geschw.;3:Beschl.)
% zSaved: Gespeicherte Messungen (Nx1)
xSaved = zeros(nSamples, 3);           
zSaved = zeros(nSamples, 1);        

% Sicherstellen, dass Zeit und Hoehe als Spaltenvektoren eingelesen werden
Zeit = Zeit(:);                         % Zeit als Spaltenvektor
Hoehe = Hoehe(:);                       % Hoehe als Spaltenvektor

%% Hauptschleife - Extended Kalman-Filter
for n = 1:nSamples
    % Messdaten laden (Höhenmessung)
    z = Hoehe(n);                       % z: Aktuelle Höhenmessung in m
    
    % Extended Kalman-Filter aufrufen
    x = ExtendedKalmanFilter(z, dt, g, m, k);
    
    % Daten sichern
    xSaved(n, :) = x';                  % Zustandsvektor [h, v, a]
    zSaved(n) = z;                      % Messung
end

%% Ergebnisse extrahieren
hSaved = xSaved(:, 1);                  % hSaved: Höhe in m
vSaved = xSaved(:, 2);                  % vSaved: Geschwindigkeit in m/s
aSaved = xSaved(:, 3);                  % aSaved: Beschleunigung in m/s²


% Findet den Index des niedrigsten POSITIVEN Wertes in hSaved
hPositive = hSaved;                      % Kopie erstellen
hPositive(hSaved <= 0) = Inf;            % Negative/Null-Werte ausschließen (auf Inf setzen)
[~, idxAufprall] = min(hPositive);       % Minimum der positiven Werte finden


% Ergebnisse
tMax = Zeit(idxAufprall);              % tMax: Fallzeit in s
vMax = (vSaved(idxAufprall));        % vMax: Auftreffgeschwindigkeit in m/s
aErgebnis = aSaved(idxAufprall);        % aErgebnis: Beschleunigung beim Aufprall in m/s²                      % tErgebnis: Zeit konstanter Geschwindigkeit in s
Ekin = 0.5 * m * vMax^2;                % Ekin: Kinetische Energie in J

v_target = -10.9;                      % v_target: Zielgeschwindigkeit
idxTargetV = find(vSaved <= v_target, 1, 'first');

if ~isempty(idxTargetV) && idxTargetV <= idxAufprall
    tErgebnis = Zeit(idxTargetV);       % Zeit bei Erreichen der Zielgeschwindigkeit
else
    tErgebnis = NaN;                    % Zielgeschwindigkeit wurde vor Aufprall nicht erreicht
end
% Debug: die gefundenen Werte prüfen
fprintf('\n=== DEBUG: Aufprall-Detektion ===\n');
fprintf('idxAufprall: %d\n', idxAufprall);
fprintf('Höhe an diesem Index: %.2f m\n', hSaved(idxAufprall));
fprintf('Geschwindigkeit: %.2f m/s\n', vSaved(idxAufprall));
fprintf('Zeit: %.2f s\n', Zeit(idxAufprall));


% Tödlichkeit prüfen (80J Grenze)
if Ekin >= 80
    btoetlich = true;
else
    btoetlich = false;
end

%% Ausgabe der Ergebnisse
fprintf('\n=== ERGEBNISSE ===\n');
fprintf('Fallzeit tMax: %.2f s\n', tMax);
fprintf('Auftreffgeschwindigkeit vMax: %.2f m/s\n', vMax);
fprintf('Beschleunigung beim Aufprall aErgebnis: %.2f m/s²\n', aErgebnis);
fprintf('Zeit konstanter Geschwindigkeit tErgebnis: %.2f s\n', tErgebnis);
fprintf('Kinetische Energie Ekin: %.2f J\n', Ekin);
fprintf('Tödlich (>80J): %s\n', mat2str(btoetlich));

%% Ergebnisdarstellung
figure('Name', 'Extended Kalman-Filter - Penny Fallexperiment', 'NumberTitle', 'off')

% Subplot 1: Höhe
subplot(3, 1, 1)
plot(Zeit, hSaved, 'b-', 'LineWidth', 1.5)
hold on
plot(Zeit, Hoehe, 'r.', 'MarkerSize', 4)
xlabel('Zeit in s')
ylabel('Hoehe in m')
title('Höhe über Zeit')
legend('EKF Schätzung', 'Messung', 'Location', 'Best')
grid on

% Subplot 2: Geschwindigkeit
subplot(3, 1, 2)
plot(Zeit, vSaved, 'b-', 'LineWidth', 1.5)
xlabel('Zeit in s')
ylabel('v in m/s')
title('Geschwindigkeit über Zeit')
grid on

% Subplot 3: Beschleunigung
subplot(3, 1, 3)
plot(Zeit, aSaved, 'b-', 'LineWidth', 1.5)
xlabel('Zeit in s')
ylabel('a in m/s^2')
title('Beschleunigung über Zeit')
grid on

%% ========================================================================
%% Extended Kalman-Filter Funktion
%% ========================================================================
function xEst = ExtendedKalmanFilter(z, dt, g, m, k)
% ExtendedKalmanFilter: EKF für freien Fall mit Luftwiderstand
%
% Eingänge:
%   z:  Höhenmessung in m
%   dt: Abtastzeit in s
%   g:  Erdbeschleunigung in m/s²
%   m:  Masse in kg
%   k:  Luftwiderstandskoeffizient
%
% Ausgang:
%   xEst: Zustandsschätzung [h; v; a] (3x1)

persistent x P A Q R H 
persistent bErsterDurchlauf

%% Initialisierung beim ersten Aufruf
if isempty(bErsterDurchlauf)
    x = [400;           % h: Starthöhe in m (etwas über 381m)
         0;             % v: Startgeschwindigkeit 0 m/s (freier Fall)
         -g];           % a: Startbeschleunigung -g m/s²
    
    % Initiale Kovarianzmatrix (hohe Unsicherheit)
    P = diag([25, 1, 1]);  % P: Fehlerkovarianz (3x3)
    
    % Systemmatrix A
    A = eye(3);
    
    % Prozessrauschen Q (Modellunsicherheit)
    Q = diag([0, 0.0001, 0.0001]); 
    
    % Messrauschen R (Messunsicherheit)
    sigma_h = 0.5;      % σ_h = 0.5m 
    R = sigma_h^2;      % R: Messrauschkovarianz 
    
    % Messmatrix H (linear, nur Höhe wird gemessen)
    H = [1, 0, 0];      % H: Messmatrix (1x3)
    
    bErsterDurchlauf = 1;
end

%% Prädiktion (Time Update)
% Nichtlineare Systemfunktion f(x)
h = x(1);               % h: Höhe
v = x(2);               % v: Geschwindigkeit
a = x(3);               % a: Beschleunigung

% Nichtlineare Systemgleichungen
h = h + v*dt+ 0.5*a*dt^2;     % Neue Höhe
v = v + a*dt;                   % Neue Geschwindigkeit

% Neue Beschleunigung 
% a = -g - (k/m)*v*|v| (mit Luftwiderstand)
a = -g - (k/m) * v * abs(v);   % Neue Beschleunigung (mit Luftwiderstand)  

% Prädizierter Zustand
xp = [h; v; a];

% Jacobi-Matrix A berechnen (Linearisierung)
% A = df/dx ausgewertet an aktuellem Zustand x
%             % ∂f3/∂v = -(k/m)·2·|v|

% Jacobi-Matrix A berechnen (Linearisierung)
% A = df/dx ausgewertet an aktuellem Zustand x
A = [1,        dt,      dt^2/2;
     0,         1,          dt;
     0,  -(k/m)*2*abs(v),    0];

% Kovarianzprädiktion
Pp = A * P * A' + Q;

%% Kalman-Gain
% Innovations-Kovarianz
S = H * Pp * H' + R;

% Kalman-Verstärkung
K = Pp * H' / S;

%% Korrektur (Measurement Update)
% Innovation (Messfehler)
innovation = z - H * xp;

% Zustandsupdate
x = xp + K * innovation;

% Kovarianzupdate
P = (eye(3) - K * H) * Pp;

%% Rückgabe
xEst = x;

end
