%% Unscented Kalman Filter: Schätzung einer Roboterpose
% Auf einer ebenen Freifläche (100m x 100m) bewegt sich ein Roboter.
% Seine Position [x; y] wird gemessen (verrauscht).
% Der Roboter bewegt sich zyklisch (RoboterBewegung, delta_u) und 
% dreht sich (RoboterDrehung, delta_Psi).
%
% Zustandsvektor: x = [x-Position; y-Position; Kurswinkel] = [x; y; Psi]
% Diskrete Zustandsgleichung:
%   x_{k+1} = x_k + delta_u_k * cos(Psi_k)
%   y_{k+1} = y_k + delta_u_k * sin(Psi_k)
%   Psi_{k+1} = Psi_k + delta_Psi_k
%
% Eingaben:
%   - Messdaten.mat: Position (2xN), Referenz (2xN), RoboterBewegung (1xN),
%                    RoboterDrehung (1xN)
%   - MessdatenSN.mat: Geradeausfahrt Süd-Nord zur Rauschbestimmung
%
% Verfügbare Funktionen:
%   - SigmaPunkte.m: Berechnung der Sigma-Punkte
%   - UT.m: Unscented Transformation
%
% Ausgaben:
%   - R_Ergebnis: Kovarianzmatrix des Messrauschens (2x2)
%   - x_AbsMean: Mittelwert des absoluten Fehlers x-Position in m
%   - y_AbsMean: Mittelwert des absoluten Fehlers y-Position in m
%   - Psi40: Geschätzter Kurswinkel bei Index 40 in Grad
%   - Psi100: Geschätzter Kurswinkel bei Index 100 in Grad

close all; clear all; clc;

%% =========================================================================
%  Bestimmung des Messrauschens anhand MessdatenSN.mat
% =========================================================================
% Bei Geradeausfahrt Süd-Nord ist x-Position konstant (Referenz = 50m).
% Das Messrauschen wird aus der Differenz Position - Referenz bestimmt.

load('MessdatenSN.mat');  % Lädt: Position (2x50), Referenz (2x50)

% Position: verrauschte Messungen [x; y] in m
% Referenz: wahre Position [x; y] in m (x konstant bei 50m)

% Berechne Messrauschen als Differenz zwischen Messung und wahrer Position
noise_x = Position(1,:) - double(Referenz(1,:));  % noise_x: Rauschen in x-Richtung in m

% Standardabweichung des Messrauschens (sigma ≈ 0.4 m)
sigma_mess = std(noise_x);  % sigma_mess: Standardabweichung in m

% Kovarianzmatrix des Messrauschens R (2x2)
% Annahme: Unkorreliertes Rauschen in x und y mit gleicher Varianz
sigma_R = 0.4;  % sigma_R: Standardabweichung gerundet auf 0.4 m
R_Ergebnis = [sigma_R^2, 0; 0, sigma_R^2];  % R = diag(0.16, 0.16)

fprintf('Kovarianzmatrix R des Messrauschens:\n');
fprintf('  R = [%.2f  %.2f]\n', R_Ergebnis(1,1), R_Ergebnis(1,2));
fprintf('      [%.2f  %.2f]\n', R_Ergebnis(2,1), R_Ergebnis(2,2));
fprintf('  (sigma = %.1f m, sigma² = %.2f m²)\n\n', sigma_R, sigma_R^2);

%% =========================================================================
%  Abbildung 1: Darstellung der Geradeausfahrt Süd-Nord (MessdatenSN.mat)
% =========================================================================
figure(1);
hold on;
grid on;

% Wahrer Wert (Referenz) - blaue Linie
plot(double(Referenz(1,:)), double(Referenz(2,:)), 'b-', 'LineWidth', 1.5, ...
     'DisplayName', 'Wahrer Wert');

% Messwerte - rote Punkte mit Linie
plot(Position(1,:), Position(2,:), 'r.-', 'MarkerSize', 8, ...
     'DisplayName', 'Messwerte');

% Startpunkt - blauer Stern
plot(Position(1,1), Position(2,1), 'b*', 'MarkerSize', 12, 'LineWidth', 2, ...
     'DisplayName', 'Startpunkt');

xlabel('x in m');
ylabel('y in m');
title('Abbildung 1: Darstellung einer Geradeausfahrt von Süd-nach Nord');
legend('Location', 'northeast');
axis([0 100 0 100]);
hold off;

%% =========================================================================
%  Laden der Hauptmessdaten für UKF
% =========================================================================
load('Messdaten.mat');  % Lädt: Position, Referenz, RoboterBewegung, RoboterDrehung

% Position: verrauschte Positionsmessungen [x; y] in m (2 x N_samples)
% Referenz: wahre Position [x; y] in m (2 x N_samples)
% RoboterBewegung: Bewegungsinkrement delta_u in m (1 x N_samples)
% RoboterDrehung: Drehungsinkrement delta_Psi in Grad (1 x N_samples)

N = size(Position, 2);  % N: Anzahl der Messzeitpunkte (160)

% Konvertiere Eingangsdaten zu double für Berechnungen
z = double(Position);           % z: Messwertmatrix [x; y] in m (2 x N)
du = double(RoboterBewegung);   % du: Bewegungsinkrement in m (1 x N)
dPsi = double(RoboterDrehung);  % dPsi: Drehungsinkrement in Grad (1 x N)
ref = double(Referenz);         % ref: Referenzposition in m (2 x N)

%% =========================================================================
%  & 2: Unscented Kalman Filter (UKF) Implementierung
% =========================================================================
% UKF für nichtlineares Zustandsmodell mit Sigma-Punkt-Approximation.
% Verwendet die Funktionen SigmaPunkte.m und UT.m
%
%   Zustand: x = [x_pos; y_pos; Psi]
%   Prozessmodell (nichtlinear wegen Psi in cos/sin):
%     x_{k+1} = x_k + du_k * cos(Psi_k)
%     y_{k+1} = y_k + du_k * sin(Psi_k)
%     Psi_{k+1} = Psi_k + dPsi_k
%   Messmodell (linear):
%     z_k = H * x_k + v_k, wobei H = [1 0 0; 0 1 0]
%
% WICHTIG: Der Kurswinkel Psi(k) enthält die kumulierte Drehung bis einschließlich
% Zeitschritt k: Psi(k) = Psi_Start + sum(dPsi(1:k))

% --- UKF Parameter ---
n_states = 3;   % n_states: Anzahl der Zustandsvariablen (x, y, Psi)
n_meas = 2;     % n_meas: Anzahl der Messgrößen (x, y)

% Kappa-Parameter für Sigma-Punkte (Standardwahl für Gaußverteilung)
kappa = 0;  % kappa: Skalierungsparameter (0 ist üblich für n=3)

% Prozessrauschen Q (3x3) - Unsicherheit im Bewegungsmodell
% sigma_q_psi: Winkelrauschen sehr klein, da Odometrie für Winkel genau
sigma_q_pos = 0.05;    % sigma_q_pos: Prozessrauschen Position in m
sigma_q_psi = 0.0001;  % sigma_q_psi: Prozessrauschen Winkel in Grad
Q = diag([sigma_q_pos^2, sigma_q_pos^2, (sigma_q_psi*pi/180)^2]);  
% Q: Prozessrauschkovarianz (Winkel in rad umgerechnet)

% Messrauschen R (2x2) - aus bestimmt
R = R_Ergebnis;  % R: Messrauschkovarianz (0.16 für x und y)

% Messmatrix H (2x3) - Messung erfasst nur Position, nicht Winkel
H = [1 0 0; 0 1 0];  % H: Messmatrix, z = H * x

% --- Initialisierung ---
% Initialer Zustand: Position aus erster Messung, Winkel = 95° + dPsi(1)
% Da Psi(k) die Drehung bis k enthält: Psi(1) = 95 + dPsi(1) = 100°
x0 = z(1, 1);           % x0: Initiale x-Position aus Messung in m
y0 = z(2, 1);           % y0: Initiale y-Position aus Messung in m
Psi_start = 95;         % Psi_start: Basiswinkel in Grad (vor erster Drehung)
Psi0 = (Psi_start + dPsi(1)) * pi/180;  % Psi0: Initialer Winkel in rad

x_est = zeros(n_states, N);  % x_est: Geschätzte Zustände (3 x N)
x_est(:, 1) = [x0; y0; Psi0];

% Initiale Fehlerkovarianz P (3x3)
P = diag([sigma_R^2, sigma_R^2, (0.001*pi/180)^2]);  % P: Kleine Winkelunsicherheit

%% --- UKF Hauptschleife ---
for k = 1:N-1
    % Aktueller Zustand und Kovarianz
    xm = x_est(:, k);     % xm: Aktueller Zustandsmittelwert (3x1)
    
    % Eingaben für diesen Zeitschritt
    du_k = du(k);         % du_k: Bewegungsinkrement in m
    
    % Drehungsinkrement für nächsten Zeitschritt
    % Psi(k+1) enthält sum(dPsi(1:k+1)), also wird dPsi(k+1) addiert
    if k+1 <= N
        dPsi_k = dPsi(k+1) * pi/180;  % dPsi_k: Nächste Drehung in rad
    else
        dPsi_k = 0;
    end
    
    % === PRÄDIKTION mit Sigma-Punkten ===
    
    % Erzeuge Sigma-Punkte aus aktuellem Zustand
    [Xi, W] = SigmaPunkte(xm, P, kappa);  % Xi: Sigma-Punkte (3 x 7), W: Gewichte (7x1)
    
    % Propagiere Sigma-Punkte durch das Prozessmodell
    n_sigma = size(Xi, 2);  % n_sigma: Anzahl Sigma-Punkte (2*n+1 = 7)
    Xi_pred = zeros(n_states, n_sigma);  % Xi_pred: Prädizierte Sigma-Punkte
    
    for i = 1:n_sigma
        % Extrahiere Zustand aus Sigma-Punkt
        x_i = Xi(1, i);
        y_i = Xi(2, i);
        Psi_i = Xi(3, i);
        
        % Nichtlineare Prozessgleichung für jeden Sigma-Punkt
        Xi_pred(1, i) = x_i + du_k * cos(Psi_i);
        Xi_pred(2, i) = y_i + du_k * sin(Psi_i);
        Xi_pred(3, i) = Psi_i + dPsi_k;
    end
    
    % Berechne prädizierte Zustands-Statistik mit Unscented Transformation
    [xm_pred, P_pred] = UT(Xi_pred, W, Q);  % xm_pred: Prädizierter Mittelwert, P_pred: Prädizierte Kovarianz
    
    % === KORREKTUR (Update) ===
    
    % Erzeuge neue Sigma-Punkte aus prädiziertem Zustand
    [Xi_new, W_new] = SigmaPunkte(xm_pred, P_pred, kappa);
    
    % Propagiere Sigma-Punkte durch das Messmodell
    % Messmodell ist linear: z = H * x
    n_sigma_new = size(Xi_new, 2);
    Zi = zeros(n_meas, n_sigma_new);  % Zi: Mess-Sigma-Punkte (2 x 7)
    
    for i = 1:n_sigma_new
        Zi(:, i) = H * Xi_new(:, i);  % Lineares Messmodell
    end
    
    % Berechne prädizierte Mess-Statistik
    [zm_pred, Pzz] = UT(Zi, W_new, R);  % zm_pred: Prädizierte Messung, Pzz: Messkovarianz
    
    % Berechne Kreuzkovarianz Pxz
    Pxz = zeros(n_states, n_meas);  % Pxz: Kreuzkovarianz (3 x 2)
    for i = 1:n_sigma_new
        Pxz = Pxz + W_new(i) * (Xi_new(:, i) - xm_pred) * (Zi(:, i) - zm_pred)';
    end
    
    % Berechne Kalman-Verstärkung
    K = Pxz / Pzz;  % K: Kalman-Gain (3 x 2)
    
    % Korrektur mit aktueller Messung
    z_k1 = z(:, k+1);  % z_k1: Aktuelle Messung [x; y]
    
    % Innovation (Messfehler)
    y_innov = z_k1 - zm_pred;  % y_innov: Innovation (2x1)
    
    % Korrigierter Zustand
    x_est(:, k+1) = xm_pred + K * y_innov;
    
    % Korrigierte Fehlerkovarianz
    P = P_pred - K * Pzz * K';
    
    % Symmetrisierung für numerische Stabilität
    P = (P + P') / 2;
end

%% =========================================================================
%  Darstellung der geschätzten Trajektorie (Abbildung 2)
% =========================================================================
figure(2);
hold on;
grid on;

% Wahrer Wert (Referenz) - magenta Punkte mit Linie
plot(ref(1,:), ref(2,:), 'm.-', 'MarkerSize', 5, 'DisplayName', 'Wahrer Wert');

% Messwerte - rote Punkte mit Linie
plot(z(1,:), z(2,:), 'r.-', 'MarkerSize', 5, 'DisplayName', 'Messwerte');

% UKF Schätzung - blaue Punkte mit Linie
plot(x_est(1,:), x_est(2,:), 'b.-', 'MarkerSize', 5, 'DisplayName', 'UKF Schätzung');

% Startpunkt - magenta Stern
plot(ref(1,1), ref(2,1), 'm*', 'MarkerSize', 15, 'LineWidth', 2, ...
     'DisplayName', 'Start');

xlabel('x-Position in m');
ylabel('y-Position in m');
title('Abbildung 2: Darstellung der geschätzten Trajektorie');
legend('Location', 'northeast');
axis([0 100 0 100]);
hold off;

%% =========================================================================
%  Berechnung der Ergebnisvariablen
% =========================================================================

% --- Fehlerberechnung für x-Position ---
% Fehler zwischen geschätzter Position und Referenz
error_x = x_est(1,:) - ref(1,:);  % error_x: Fehler in x-Richtung (1 x N)
x_AbsMean = mean(error_x);        % x_AbsMean: Mittlerer Fehler x in m

% --- Fehlerberechnung für y-Position ---
error_y = x_est(2,:) - ref(2,:);  % error_y: Fehler in y-Richtung (1 x N)
y_AbsMean = mean(error_y);        % y_AbsMean: Mittlerer Fehler y in m

% --- Kurswinkel bei Index 40 und 100 ---
% Der Winkel zum Index k ist: Psi(k) = Psi_start + sum(dPsi(1:k))
% Konvertiere UKF-Schätzung von rad nach Grad
Psi_deg = x_est(3,:) * 180/pi;    % Psi_deg: Kurswinkel in Grad (1 x N)

% Normalisiere auf [0, 360) Grad
Psi_deg = mod(Psi_deg, 360);

% Geschätzter Kurswinkel bei Index 40 (gerundet auf ganze Grad)
Psi40 = round(Psi_deg(40));       % Psi40: Kurswinkel bei k=40 in Grad

% Geschätzter Kurswinkel bei Index 100 (gerundet auf ganze Grad)
Psi100 = round(Psi_deg(100));     % Psi100: Kurswinkel bei k=100 in Grad

%% =========================================================================
%  Ausgabe der Ergebnisse
% =========================================================================
fprintf('\n========== UKF ERGEBNISSE ==========\n');
fprintf('Kovarianzmatrix R des Messrauschens:\n');
fprintf('  R = [%.2f  %.2f]\n', R_Ergebnis(1,1), R_Ergebnis(1,2));
fprintf('      [%.2f  %.2f]\n\n', R_Ergebnis(2,1), R_Ergebnis(2,2));

fprintf('Mittlerer Fehler x-Position: x_AbsMean = %.4f m\n', x_AbsMean);
fprintf('Mittlerer Fehler y-Position: y_AbsMean = %.4f m\n\n', y_AbsMean);

fprintf('Kurswinkel bei Index 40:  Psi40  = %d°\n', Psi40);
fprintf('Kurswinkel bei Index 100: Psi100 = %d°\n', Psi100);
fprintf('====================================\n');

%% =========================================================================


%% =========================================================================
%  ERGEBNISSE
% =========================================================================
% Ergebnisgrößen:

% R_Ergebnis: Kovarianzmatrix des Messrauschens (bereits oben definiert)

% x_AbsMean: Mittelwert des Fehlers der x-Position in m

% y_AbsMean: Mittelwert des Fehlers der y-Position in m  

% Psi40: Kurswinkel bei Index 40 in Grad

% Psi100: Kurswinkel bei Index 100 in Grad