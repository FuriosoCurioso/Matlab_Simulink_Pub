% =========================================================================
% UNSCENTED KALMAN FILTER - PENNY FALL SIMULATION
% =========================================================================
% Modell: Freier Fall mit Windwiderstand
% Zustandsvektor: x = [Position; Geschwindigkeit; Beschleunigung]
% =========================================================================

close all; clear all; clc;

%% ========================================================================
% PHYSIKALISCHE PARAMETER
% =========================================================================
% Luftwiderstand: F_W = 0.5 * c_W * rho * A * v^2
cW = 1.17;                      % Luftwiderstandskoeffizient (dimensionslos)
rho = 1.225;                    % kg/m³ - Dichte des Mediums (Luft)
d = 19.05e-3;                   % m - Durchmesser des Pennys
m = 2.5e-3;                     % kg - Masse des Pennys
g = 9.81;                       % m/s² - Erdbeschleunigung
A = pi * (d/2)^2;               % m² - Querschnittsfläche des Pennys
dt = 0.01;                      % s - Abtastrate (Zeitschritt)

%% ========================================================================
% MESSDATEN LADEN
% =========================================================================
sFileName = 'Messdaten_B';
load(sFileName);                % Lädt: Hoehe, Zeit

Nsamples = length(Zeit);        % Anzahl der Messwerte

%% ========================================================================
% INITIALISIERUNG UNSCENTED KALMAN FILTER
% =========================================================================
% Zustandsvektor: x = [Position; Geschwindigkeit; Beschleunigung]
x0 = [Hoehe(1); 0; 0];          % Startzustand: [Anfangshöhe; v=0; a=0]
P0 = diag([1, 1, 1]);           % Anfangs-Kovarianzmatrix

% Prozessrauschen Q (Modellunsicherheit)
Q = diag([0.001, 0.01, 0.1]);       % Rauschkovarianz für [Position, Geschw., Beschl.]

% Messrauschen R (Messunsicherheit der Höhenmessung)
R = 4;                          % Standardabweichung der Höhenmessung

% UKF Parameter
kappa = 0;                      % Skalierungsparameter für Sigma-Punkte

% Initialisierung
x = x0;                         % Aktueller Zustand
P = P0;                         % Aktuelle Kovarianz

%% ========================================================================
% DATENSPEICHER FÜR ERGEBNISSE
% =========================================================================
Xsaved = zeros(Nsamples, 3);   % Speichert geschätzte Zustände
Zsaved = zeros(Nsamples, 1);   % Speichert Messungen

%% ========================================================================
% HAUPTSCHLEIFE: UNSCENTED KALMAN FILTER
% =========================================================================
for k = 1:Nsamples
    % Messung laden
    z = Hoehe(k);               % Aktuelle Höhenmessung in m
    
    % Unscented Kalman Filter Schritt
    [x, P] = UnscentedKalmanFilter(x, P, z, dt, m, cW, rho, A, g, Q, R, kappa);
    
    % Daten sichern
    Xsaved(k, :) = x';          % Zustand: [Position, Geschwindigkeit, Beschleunigung]
    Zsaved(k) = z;              % Messung
end

%% ========================================================================
% ERGEBNISSE BERECHNEN
% =========================================================================

% Fallzeit tMax: Zeitpunkt des Aufpralls (Position ≈ 0 m oder minimale Höhe)
[minHoehe, idxMin] = min(Xsaved(:, 1));
tMax = Zeit(idxMin);            % s - Fallzeit bis Aufprall

% Maximale Fallgeschwindigkeit vMax (negativste Geschwindigkeit)
vMax = min(Xsaved(:, 2));       % m/s - maximale Fallgeschwindigkeit (negativ)

% Beschleunigung zum Aufprallzeitpunkt tMax
aErgebnis = Xsaved(idxMin, 3);  % m/s² - Beschleunigung bei Aufprall

% Zeitpunkt konstanter Fallgeschwindigkeit (Terminal Velocity)
% Kriterium: Beschleunigung ≈ 0 (d.h. Gleichgewicht zwischen Schwerkraft und Luftwiderstand)
threshold_a = 0.5;              % m/s² - Schwellwert für "konstante" Geschwindigkeit
idx_const = find(abs(Xsaved(:, 3)) < threshold_a, 1, 'first');
if ~isempty(idx_const)
    tErgebnis = Zeit(idx_const);% s - Zeitpunkt konstanter Fallgeschwindigkeit
else
    tErgebnis = NaN;            % Keine konstante Geschwindigkeit erreicht
end

% Kinetische Energie beim Aufprall
Ekin = 0.5 * m * vMax^2;        % J - Kinetische Energie: E_kin = 0.5 * m * v²

% Ist der Penny tödlich? (Grenze: 80 J)
btoetlich = (Ekin > 80);        % true/false

%% ========================================================================
% AUSGABE DER ERGEBNISSE
% =========================================================================
fprintf('========================================\n');
fprintf('ERGEBNISSE DER SIMULATION\n');
fprintf('========================================\n');
fprintf('Fallzeit tMax:              %.2f s\n', tMax);
fprintf('Max. Fallgeschwindigkeit:   %.2f m/s\n', vMax);
fprintf('Beschleunigung bei Aufprall: %.2f m/s²\n', aErgebnis);
if ~isnan(tErgebnis)
    fprintf('Zeit konstanter Geschw.:    %.2f s\n', tErgebnis);
else
    fprintf('Zeit konstanter Geschw.:    Nicht erreicht\n');
end
fprintf('Kinetische Energie:         %.4f J\n', Ekin);
fprintf('Tödlich (> 80 J):           %s\n', mat2str(btoetlich));
fprintf('========================================\n');

%% ========================================================================
% VISUALISIERUNG
% =========================================================================
figure('Name', 'Unscented Kalman Filter - Penny Fall', 'NumberTitle', 'off');

% Subplot 1: Höhe vs. Zeit
subplot(3, 1, 1);
plot(Zeit, Xsaved(:, 1), 'b-', 'LineWidth', 1.5); hold on;
plot(Zeit, Zsaved, 'r.', 'MarkerSize', 3);
xlabel('Zeit in s');
ylabel('Höhe in m');
title('Höhe=f(Zeit)');
legend('Geschätzte Position', 'Messung', 'Location', 'best');
grid on;

% Subplot 2: Geschwindigkeit vs. Zeit
subplot(3, 1, 2);
plot(Zeit, Xsaved(:, 2), 'g-', 'LineWidth', 1.5);
xlabel('Zeit in s');
ylabel('Geschwindigkeit in m/s');
title('Geschwindigkeit=f(Zeit)');
grid on;
hold on;
% Markiere maximale Geschwindigkeit
plot(tMax, vMax, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
legend('Geschwindigkeit', sprintf('vMax = %.2f m/s bei t=%.2f s', vMax, tMax), 'Location', 'best');

% Subplot 3: Beschleunigung vs. Zeit
subplot(3, 1, 3);
plot(Zeit, Xsaved(:, 3), 'm-', 'LineWidth', 1.5);
xlabel('Zeit in s');
ylabel('Beschleunigung in m/s²');
title('Beschleunigung=f(Zeit)');
grid on;
hold on;
% Markiere Beschleunigung bei Aufprall
plot(tMax, aErgebnis, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
yline(0, 'k--', 'LineWidth', 1);
legend('Beschleunigung', sprintf('a(tMax) = %.2f m/s²', aErgebnis), 'Location', 'best');

%% ========================================================================
% FUNKTIONEN
% =========================================================================

function [x_new, P_new] = UnscentedKalmanFilter(x, P, z, dt, m, cW, rho, A, g, Q, R, kappa)
    % UNSCENTEDKALMANFILTER - Ein Schritt des Unscented Kalman Filters
    %
    % Eingänge:
    %   x      - Zustandsvektor [Position; Geschwindigkeit; Beschleunigung] (3×1)
    %   P      - Kovarianzmatrix des Zustands (3×3)
    %   z      - Messung (Höhe) (Skalar)
    %   dt     - Zeitschritt in s
    %   m      - Masse in kg
    %   cW     - Luftwiderstandskoeffizient
    %   rho    - Luftdichte in kg/m³
    %   A      - Querschnittsfläche in m²
    %   g      - Erdbeschleunigung in m/s²
    %   Q      - Prozessrauschkovarianz (3×3)
    %   R      - Messrauschkovarianz (Skalar)
    %   kappa  - UKF Skalierungsparameter
    %
    % Ausgänge:
    %   x_new  - Aktualisierter Zustandsvektor (3×1)
    %   P_new  - Aktualisierte Kovarianzmatrix (3×3)
    
    %% SCHRITT 1: SIGMA-PUNKTE GENERIEREN
    [Xi, W] = SigmaPunkte(x, P, kappa);
    
    %% SCHRITT 2: PRÄDIKTION (Zeitupdate)
    % Transformiere Sigma-Punkte durch die Prozessgleichung
    n_sigma = size(Xi, 2);
    Xi_pred = zeros(size(Xi));
    
    for i = 1:n_sigma
        Xi_pred(:, i) = prozessModell(Xi(:, i), dt, m, cW, rho, A, g);
    end
    
    % Berechne prädizierte Mittelwert und Kovarianz mit Unscented Transformation
    [x_pred, P_pred] = UT(Xi_pred, W, Q);
    
    %% SCHRITT 3: MESSUPDATE
    % Generiere neue Sigma-Punkte aus prädiziertem Zustand
    [Xi_pred_new, W_new] = SigmaPunkte(x_pred, P_pred, kappa);
    
    % Transformiere Sigma-Punkte durch Messgleichung
    Zi = zeros(1, n_sigma);
    for i = 1:n_sigma
        Zi(i) = messModell(Xi_pred_new(:, i));
    end
    
    % Berechne prädizierte Messung
    [z_pred, Pzz] = UT_scalar(Zi, W_new, R);
    
    % Berechne Kreuzkovarianz Pxz
    Pxz = zeros(3, 1);
    for i = 1:n_sigma
        Pxz = Pxz + W_new(i) * (Xi_pred_new(:, i) - x_pred) * (Zi(i) - z_pred);
    end
    
    % Kalman Gain
    K = Pxz / Pzz;
    
    % Update Zustand und Kovarianz
    x_new = x_pred + K * (z - z_pred);
    P_new = P_pred - K * Pzz * K';
    
    % Sicherstellen, dass Kovarianz symmetrisch bleibt
    P_new = (P_new + P_new') / 2;
end

function x_next = prozessModell(x, dt, m, cW, rho, A, g)
    % PROZESSMODELL - Diskrete Zeitentwicklung des Zustands
    %
    % Zustandsvektor: x = [Position; Geschwindigkeit; Beschleunigung]
    % Physik: 
    %   - Luftwiderstand: F_W = 0.5 * cW * rho * A * v²
    %   - Beschleunigung: a(t) = F_W(t)/m - g (nach unten positiv für v<0)
    %   - Newton: a = (F_Luftwiderstand - F_Gravitation) / m
    
    pos = x(1);         % Position in m
    vel = x(2);         % Geschwindigkeit in m/s
    acc = x(3);         % Beschleunigung in m/s²
    
    % Berechne Luftwiderstand (wirkt der Bewegung entgegen)
    F_W = 0.5 * cW * rho * A * vel^2;
    
    % Vorzeichen der Luftwiderstandskraft (entgegen der Bewegungsrichtung)
    if vel < 0
        F_W = F_W;      % Luftwiderstand nach oben (positiv)
    else
        F_W = -F_W;     % Luftwiderstand nach unten (negativ)
    end
    
    % Neue Beschleunigung: a = F_W/m - g
    % (g ist nach unten gerichtet, also negativ in unserem Koordinatensystem)
    acc_new = F_W / m - g;
    
    % Euler-Integration (diskrete Zeitentwicklung)
    vel_new = vel + acc * dt;
    pos_new = pos + vel * dt + 0.5 * acc * dt^2;
    
    % Rückgabe des neuen Zustands
    x_next = [pos_new; vel_new; acc_new];
end

function z = messModell(x)
    % MESSMODELL - Messung ist die Position (Höhe)
    %
    % Eingang:
    %   x - Zustandsvektor [Position; Geschwindigkeit; Beschleunigung]
    %
    % Ausgang:
    %   z - Messwert (Position)
    
    z = x(1);  % Messung = Position
end

function [z_mean, Pzz] = UT_scalar(Zi, W, noiseCov)
    % UT_SCALAR - Unscented Transformation für skalare Messungen
    %
    % Eingänge:
    %   Zi        - Transformierte Sigma-Punkte (1×n)
    %   W         - Gewichte (n×1)
    %   noiseCov  - Rauschkovarianz (Skalar)
    %
    % Ausgänge:
    %   z_mean - Mittelwert
    %   Pzz    - Kovarianz
    
    n = length(Zi);
    
    % Mittelwert
    z_mean = 0;
    for i = 1:n
        z_mean = z_mean + W(i) * Zi(i);
    end
    
    % Kovarianz
    Pzz = 0;
    for i = 1:n
        Pzz = Pzz + W(i) * (Zi(i) - z_mean)^2;
    end
    Pzz = Pzz + noiseCov;
end


