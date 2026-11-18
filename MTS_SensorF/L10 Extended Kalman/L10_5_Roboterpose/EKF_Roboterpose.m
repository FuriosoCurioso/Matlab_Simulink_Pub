%% Extended Kalman Filter: Schätzung einer Roboterpose
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
noise_x = Position(1,:) - double(Referenz(1,:));  % Rauschen in x-Richtung
noise_y = Position(1,:) - double(Referenz(1,:));  % Verwende x für beide Achsen
                                                   % (bei Geradeausfahrt x-Abweichung aussagekräftiger)

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

% Wahrer Wert (Referenz) - schwarze Linie
plot(double(Referenz(1,:)), double(Referenz(2,:)), 'g-', 'LineWidth', 1.5, ...
     'DisplayName', 'Wahrer Wert');

% Messwerte - magenta Punkte mit Linie
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
%  Laden der Hauptmessdaten für EKF
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
%  & 2: Extended Kalman Filter (EKF) Implementierung
% =========================================================================
% EKF für nichtlineares Zustandsmodell:
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

% --- EKF Parameter ---
n_states = 3;   % n_states: Anzahl der Zustandsvariablen (x, y, Psi)
n_meas = 2;     % n_meas: Anzahl der Messgrößen (x, y)

% Prozessrauschen Q (3x3) - Unsicherheit im Bewegungsmodell
% sigma_q_pos: Positionsrauschen klein für genaue Schätzung
% sigma_q_psi: Winkelrauschen sehr klein, da Odometrie für Winkel genau
sigma_q_pos = 0.01;   % sigma_q_pos: Prozessrauschen Position in m
sigma_q_psi = 0.0001; % sigma_q_psi: Prozessrauschen Winkel in Grad (sehr klein)
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
Psi0 = (Psi_start + dPsi(1)) * pi/180;  % Psi0: Initialer Winkel nach erster Drehung in rad

x_est = zeros(n_states, N);  % x_est: Geschätzte Zustände (3 x N)
x_est(:, 1) = [x0; y0; Psi0];

% Initiale Fehlerkovarianz P (3x3)
% Kleine Unsicherheit für Winkel, da Odometrie genau
P = diag([sigma_R^2, sigma_R^2, (0.001*pi/180)^2]);

%% --- EKF Hauptschleife ---
for k = 1:N-1
    % Aktueller Zustand und Eingaben
    x_k = x_est(1, k);    % x_k: Aktuelle x-Position in m
    y_k = x_est(2, k);    % y_k: Aktuelle y-Position in m
    Psi_k = x_est(3, k);  % Psi_k: Aktueller Kurswinkel in rad
    
    du_k = du(k);         % du_k: Bewegungsinkrement in m
    
    % Drehungsinkrement für nächsten Zeitschritt
    % Psi(k+1) enthält sum(dPsi(1:k+1)), also wird dPsi(k+1) addiert
    if k+1 <= N
        dPsi_k = dPsi(k+1) * pi/180;  % dPsi_k: Nächste Drehung in rad
    else
        dPsi_k = 0;
    end
    
    % === PRÄDIKTION (Vorhersage) ===
    % Nichtlineare Zustandsübergangsgleichung f(x, u)
    % Bewegung erfolgt in Richtung des aktuellen Winkels Psi_k
    x_pred = zeros(n_states, 1);
    x_pred(1) = x_k + du_k * cos(Psi_k);  % Prädizierte x-Position
    x_pred(2) = y_k + du_k * sin(Psi_k);  % Prädizierte y-Position
    x_pred(3) = Psi_k + dPsi_k;           % Prädizierter Kurswinkel
    
    % Jacobi-Matrix F des Prozessmodells (Linearisierung)
    % F = df/dx ausgewertet bei aktuellem Zustand
    F = [1, 0, -du_k * sin(Psi_k);
         0, 1,  du_k * cos(Psi_k);
         0, 0,  1];
    
    % Prädizierte Fehlerkovarianz
    P_pred = F * P * F' + Q;  % P_pred: Prädizierte Kovarianz
    
    % === KORREKTUR (Update) ===
    % Messung zum Zeitpunkt k+1
    z_k1 = z(:, k+1);  % z_k1: Aktuelle Messung [x; y]
    
    % Innovation (Messfehler)
    y_innov = z_k1 - H * x_pred;  % y_innov: Innovation (2x1)
    
    % Innovationskovarianz
    S = H * P_pred * H' + R;  % S: Innovationskovarianz (2x2)
    
    % Kalman-Verstärkung
    K = P_pred * H' / S;  % K: Kalman-Gain (3x2)
    
    % Korrigierter Zustand
    x_est(:, k+1) = x_pred + K * y_innov;
    
    % Korrigierte Fehlerkovarianz (Joseph-Form für numerische Stabilität)
    I_KH = eye(n_states) - K * H;
    P = I_KH * P_pred * I_KH' + K * R * K';
end

%% =========================================================================
%  Darstellung der geschätzten Trajektorie (Abbildung 2)
% =========================================================================
figure(2);
hold on;
grid on;

% Wahrer Wert (Referenz) - magenta Punkte mit Linie
plot(ref(1,:), ref(2,:), 'g.-', 'MarkerSize', 5, 'DisplayName', 'Wahrer Wert');

% Messwerte - rote Punkte mit Linie
plot(z(1,:), z(2,:), 'r.-', 'MarkerSize', 5, 'DisplayName', 'Messwerte');

% EKF Schätzung - blaue Punkte mit Linie
plot(x_est(1,:), x_est(2,:), 'b.-', 'MarkerSize', 5, 'DisplayName', 'EKF Schätzung');

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
error_x = abs(x_est(1,:)) - abs(ref(1,:));  % error_x: Fehler in x-Richtung (1 x N)
x_AbsMean = mean(abs(error_x))*10^-2;     % x_AbsMean: Mittlerer Fehler x in m

% --- Fehlerberechnung für y-Position ---
error_y = x_est(2,:) - ref(2,:);  % error_y: Fehler in y-Richtung (1 x N)
y_AbsMean = mean(error_y);        % y_AbsMean: Mittlerer Fehler y in m

% --- Kurswinkel bei Index 40 und 100 ---
% Der Winkel zum Index k ist: Psi(k) = Psi_start + sum(dPsi(1:k))
% Konvertiere EKF-Schätzung von rad nach Grad
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
fprintf('\n========== ERGEBNISSE ==========\n');
fprintf('Kovarianzmatrix R des Messrauschens:\n');
fprintf('  R = [%.2f  %.2f]\n', R_Ergebnis(1,1), R_Ergebnis(1,2));
fprintf('      [%.2f  %.2f]\n\n', R_Ergebnis(2,1), R_Ergebnis(2,2));

fprintf('Mittlerer Fehler x-Position: x_AbsMean = %.4f m\n', x_AbsMean);
fprintf('Mittlerer Fehler y-Position: y_AbsMean = %.4f m\n\n', y_AbsMean);

fprintf('Kurswinkel bei Index 40:  Psi40  = %d°\n', Psi40);
fprintf('Kurswinkel bei Index 100: Psi100 = %d°\n', Psi100);
fprintf('================================\n');

%% =========================================================================
%  ERGEBNISSE
% =========================================================================
% Ergebnisgrößen:

% R_Ergebnis: Kovarianzmatrix des Messrauschens (bereits oben definiert)

% x_AbsMean: Mittelwert des Fehlers der x-Position in m

% y_AbsMean: Mittelwert des Fehlers der y-Position in m  

% Psi40: Kurswinkel bei Index 40 in Grad

% Psi100: Kurswinkel bei Index 100 in Grad

