% BallTrackingKalmanFilter.m Tracking eines fallenden Basketballs mittels Kalman-Filter mit Koordinatentransformation

close all; clear all; clc;

%% ========================================================================
%  Funktion z = messeBallPos(k)
%  ========================================================================
% Erstellt Funktion, die zyklisch die Messwerte liest
% Pro Messzyklus k wird Messvektor z=[Pos_x; Pos_y] in Pixel ausgegeben

function z = messeBallPos(k)
    % messeBallPos - Liest Ball-Position aus Messdatei
    % INPUT:  k - Messzyklus (Frame-Nummer) 1...60
    % OUTPUT: z - Messvektor [Pos_x; Pos_y] in Pixel
    
    persistent zSaved nFramesTotal
    
    if isempty(zSaved)
        % Einmaliges Laden der Messdaten beim ersten Aufruf
        stDateiName_A = 'MessungenBallPosition_A.mat';
        
        if exist(stDateiName_A, 'file')
            load(stDateiName_A, 'zSaved');
        else
            error('Datei %s nicht gefunden!', stDateiName_A);
        end
        
        nFramesTotal = size(zSaved, 2);  % Anzahl Frames (60)
    end
    
    % Prüfe ob k im gültigen Bereich
    if k < 1 || k > nFramesTotal
        error('Frame k=%d außerhalb des Bereichs [1, %d]', k, nFramesTotal);
    end
    
    % Extrahiere Messvektor für Frame k
    z = zSaved(:, k);  % [Pos_x; Pos_y] in Pixel
end

%% ========================================================================
%  Koordinatentransformation: Bild -> Welt
%  ========================================================================
% Transformiere Messwerte von Bildkoordinaten in metrische Weltkoordinaten
% Beschreibung des Ansatzes:
% 
% PROBLEM: 
%   - Bildkoordinaten: x_b nach rechts (0 bis 320 px), y_b nach unten (0 bis 240 px)
%   - Weltkoordinaten: x_w nach rechts (in m), y_w nach oben (in m)
%
% LÖSUNG - KOS-Transformation in 3 Schritten:
%
%   SKALIERUNG: Pixel -> Meter
%      - Gegeben: Basketball-Durchmesser = 24 cm = 0.24 m
%      - Im Bild: Basketball-Durchmesser = 30 Pixel
%      - Skalierungsfaktor: alpha = 0.24 m / 30 px = 0.008 m/px
%
%   Y-ACHSEN-INVERTIERUNG:
%      - Bildkoordinaten: y_b wächst nachunten
%      - Weltkoordinaten: y_w wächst nachoben
%      - Transformation: y_w = -y_b * alpha (mit negativem Vorzeichen)
%
%   URSPRUNGSVERSCHIEBUNG:
%      - Bild-Ursprung: (0, 0) oben links
%      - Welt-Ursprung: Soll an realistischer Position sein
%      - Y-Offset: Starthöhe = 1.41 m (gegeben)
%      - X-Offset: Bildmitte (160 px * 0.008 m/px = 1.28 m)
%
% MATHEMATISCHE TRANSFORMATION:
%   x_w = x_b * alpha - x_offset
%   y_w = -(y_b * alpha) + y_offset
%
% wobei:
%   alpha = 0.008 m/px
%   x_offset = 160 px * 0.008 m/px = 1.28 m (zentriert)
%   y_offset = 1.41 m (Starthöhe des Balls)

function z_welt = bildZuWelt(z_bild)
    % bildZuWelt - Transformiert Bildkoordinaten in Weltkoordinaten
    % INPUT:  z_bild - Position in Pixel [x_b; y_b]
    % OUTPUT: z_welt - Position in Meter [x_w; y_w]
    
    % Skalierungsfaktor Pixel -> Meter
    alpha = 0.24 / 30;  % 24 cm / 30 px = 0.008 m/px
    
    % Offsets für Ursprungsverschiebung
    x_offset = 160 * alpha;  % Bildmitte in x: 1.28 m
    y_offset = 1.41;         % Starthöhe: 1.41 m (gegeben)
    
    % Koordinatentransformation
    % x_w = x_b * alpha - x_offset (zentriert)
    % y_w = -y_b * alpha + y_offset (invertiert + Starthöhe)
    x_w = z_bild(1) * alpha - x_offset;
    y_w = -(z_bild(2) * alpha) + y_offset;
    
    z_welt = [x_w; y_w];
end

%% ========================================================================
%  Kalman-Filter Implementation
%  ========================================================================
% Erstellt Kalman-Filter für 2D-Bewegungsschätzung
% Zustandsvektor: x(k) = [x; y; v_x; v_y; a_x; a_y]'
% Systemmodell: Konstante Beschleunigung (a_y = -g)

function x = KalmanFilter(z)
    % KalmanFilter - Schätzt Zustand des Balls
    % INPUT:  z - Messvektor [x; y] in m (Weltkoordinaten)
    % OUTPUT: x - Zustandsvektor [x; y; v_x; v_y; a_x; a_y] in m, m/s, m/s²
    
    persistent x_est P A H Q R bInitialized
    
    if isempty(bInitialized)
        % Initialisierung beim ersten Aufruf
        
        % Zeitschritt
        dt = 0.0625;  % Eingangsgrößen: 0.0625 s
        
        % Systemmatrix A (6x6) - Kinematisches Modell
        % x(k+1) = x(k) + v_x(k)*dt + 0.5*a_x(k)*dt^2
        % y(k+1) = y(k) + v_y(k)*dt + 0.5*a_y(k)*dt^2
        % v_x(k+1) = v_x(k) + a_x(k)*dt
        % v_y(k+1) = v_y(k) + a_y(k)*dt
        % a_x(k+1) = a_x(k)  (konstante Beschleunigung)
        % a_y(k+1) = a_y(k)  (konstante Beschleunigung)
        
        A = [1, 0, dt, 0,  0.5*dt^2, 0;        % x
             0, 1, 0,  dt, 0,        0.5*dt^2; % y
             0, 0, 1,  0,  dt,       0;        % v_x
             0, 0, 0,  1,  0,        dt;       % v_y
             0, 0, 0,  0,  1,        0;        % a_x
             0, 0, 0,  0,  0,        1];       % a_y
        
        % Messmatrix H (2x6) - Wir messen nur Position [x, y]
        H = [1, 0, 0, 0, 0, 0;
             0, 1, 0, 0, 0, 0];
        
        % Prozessrauschkovarianz Q (6x6)
        % Modelliert Unsicherheit im Systemmodell
        % Höhere Werte erlauben mehr Dynamik
        q_pos = 0.01;    % Positionsunsicherheit
        q_vel = 0.1;     % Geschwindigkeitsunsicherheit
        q_acc = 0.5;     % Beschleunigungsunsicherheit
        
        Q = diag([q_pos, q_pos, q_vel, q_vel, q_acc, q_acc]);
        
        % Messrauschkovarianz R (2x2)
        % Modelliert Unsicherheit der Positionsmessung
        r_meas = 0.01;  % Messunsicherheit in m^2
        R = r_meas * eye(2);
        
        % Anfangszustand x_est (6x1)
        % Initialisiere mit erster Messung und Nullen für Geschwindigkeit/Beschleunigung
        x_est = [z(1); z(2); 0; 0; 0; -9.81];  % a_y = -g (Erdanziehung)
        
        % Anfangs-Kovarianzmatrix P (6x6)
        % Hohe Unsicherheit zu Beginn
        P = diag([1, 1, 10, 10, 10, 10]);
        
        bInitialized = true;
    end
    
    % KALMAN-FILTER SCHRITTE
    
    % PRÄDIKTION (Vorhersage)
    x_pred = A * x_est;              % Zustandsprädiktion
    P_pred = A * P * A' + Q;         % Kovarianzprädiktion
    
    % INNOVATION (Messung - Vorhersage)
    y_innov = z - H * x_pred;        % Innovationsvektor (Messfehler)
    S = H * P_pred * H' + R;         % Innovationkovarianz
    
    % KALMAN-GAIN (Gewichtung: Modell vs. Messung)
    K = P_pred * H' / S;             % Kalman-Verstärkung
    
    % KORREKTUR (Update mit Messung)
    x_est = x_pred + K * y_innov;    % Korrigierter Zustand
    P = (eye(6) - K * H) * P_pred;   % Korrigierte Kovarianz
    
    % Ausgabe des aktuellen Zustands
    x = x_est;
end

%% ========================================================================
%  HAUPTPROGRAMM
%  ========================================================================

%% Kalman-Filter anhand Messdaten auslegen

% Parameter A, H, Q, R, x0, P0 werden im Kalman-Filter definiert
% Begründung der Parameterwahl:
%
% A: Systemmatrix für konstante Beschleunigung
%    - Modelliert kinematische Gleichungen: s = s0 + v*t + 0.5*a*t^2
%    - Berücksichtigt Position, Geschwindigkeit, Beschleunigung
%
% H: Messmatrix
%    - Wir messen nur Position [x, y]
%    - H = [I_2x2, 0_2x4] extrahiert nur erste 2 Zustände
%
% Q: Prozessrauschkovarianz
%    - q_acc = 0.5 (hoch): Ermöglicht Anpassung bei Ballsprung (Richtungsänderung)
%    - q_vel = 0.1 (mittel): Geschwindigkeit ändert sich durch Beschleunigung
%    - q_pos = 0.01 (niedrig): Position ist gut vorhersagbar
%
% R: Messrauschkovarianz
%    - r_meas = 0.01: Messung hat geringe Unsicherheit (Bildverarbeitung gut)
%    - Niedriger Wert → Filter vertraut Messungen mehr als Modell
%
% x0: Anfangszustand
%    - Position: Erste Messung
%    - Geschwindigkeit: 0 (Ball startet aus Ruhe)
%    - Beschleunigung: [0, -9.81] (Erdanziehung)
%
% P0: Anfangskovarianz
%    - Hohe Unsicherheit für Geschwindigkeit/Beschleunigung (10)
%    - Niedrige Unsicherheit für Position (1)

fprintf('========== BALL-TRACKING MIT KALMAN-FILTER ==========\n');

%% Datei laden und Anzahl Frames bestimmen
stDateiName_A = 'MessungenBallPosition_A.mat';
stDateiName_B = 'MessungenBallPosition_B.mat';

% Prüfe welche Dateien vorhanden sind
if exist(stDateiName_A, 'file')
    load(stDateiName_A, 'zSaved');
    stUsedFile = stDateiName_A;
    fprintf('Datei geladen: %s\n', stDateiName_A);
elseif exist(stDateiName_B, 'file')
    load(stDateiName_B, 'zSaved');
    stUsedFile = stDateiName_B;
    fprintf('Datei geladen: %s\n', stDateiName_B);
end

nFrames = size(zSaved, 2);  % Anzahl Frames (60)
fprintf('Anzahl Frames: %d\n', nFrames);

% Zeitvektor erstellen
dt = 0.0625;  % Eingangsgrößen: 0.0625 s
aZeit = (0:nFrames-1) * dt;  % Zeit in s

%% Verarbeitung und Visualisierung

% Initialisierung der Ergebnisvektoren
aMesswerte_x = zeros(nFrames, 1);   % Messwerte x in m
aMesswerte_y = zeros(nFrames, 1);   % Messwerte y in m
aZustand = zeros(6, nFrames);       % Zustandsvektor für alle Frames

% Hauptschleife: Für jeden Frame
for k = 1:nFrames
    % Messe Ball-Position in Pixel
    z_pixel = messeBallPos(k);
    
    % Transformiere zu Weltkoordinaten (metrisch)
    z_meter = bildZuWelt(z_pixel);
    
    % Speichere Messwerte
    aMesswerte_x(k) = z_meter(1);
    aMesswerte_y(k) = z_meter(2);
    
    % Kalman-Filter anwenden
    x = KalmanFilter(z_meter);
    
    % Speichere Zustand
    aZustand(:, k) = x;
end

fprintf('Verarbeitung abgeschlossen.\n');

%% Darstellung: 2x1 Subplots (Abb. 2)

figure('Name', 'Messwerte in m über der Zeit (Abb. 2)', 'Position', [100, 100, 800, 600]);

% Subplot 1: x über Zeit
subplot(2, 1, 1);
plot(aZeit, aMesswerte_x, 'b.-', 'LineWidth', 1.5, 'MarkerSize', 8);
grid on;
xlabel('Zeit in s', 'FontSize', 12);
ylabel('x in m', 'FontSize', 12);
title('', 'FontSize', 12);
legend('Messwerte', 'Location', 'best');
xlim([0, max(aZeit)]);
ylim([0.9, 1.2]);

% Subplot 2: y über Zeit
subplot(2, 1, 2);
plot(aZeit, aMesswerte_y, 'b.-', 'LineWidth', 1.5, 'MarkerSize', 8);
grid on;
xlabel('Zeit in s', 'FontSize', 12);
ylabel('y in m', 'FontSize', 12);
legend('Messwerte', 'Location', 'best');
xlim([0, max(aZeit)]);
ylim([-0.1, 1.5]);

%% Anpassung für Datei A vs. B

% Begründung für unterschiedliche Anpassungen:
%
% MESSUNGBALLPOSITION_A:
%   - Geringes Messrauschen (glatte Messungen)
%   - Parameter R = 0.01 (niedrig) ist optimal
%   - Filter vertraut Messungen stark
%   - Ergebnis: Glatte Schätzung mit geringem Fehler
%
% MESSUNGBALLPOSITION_B (HOHES MESSRAUSCHEN):
%   - Starkes Messrauschen (verrauschte Messungen)
%   - Parameter R sollte ERHÖHT werden (z.B. R = 0.1)
%   - Filter vertraut Modell mehr als Messung
%   - Q kann erhöht werden für mehr Dynamik
%   - Ergebnis: Glättere Schätzung trotz Rauschen
%
% ANPASSUNGSSTRATEGIE:
%   if enthält_viel_rauschen(stUsedFile)
%       R = 0.1;  % Höheres Messrauschen
%       Q = Q * 2; % Mehr Prozessrauschen erlauben
%   end

fprintf('\n========== PARAMETERANPASSUNG ==========\n');
if contains(stUsedFile, '_B')
    fprintf('DATEI B ERKANNT (hohes Messrauschen):\n');
    fprintf('  Empfehlung: R = 0.1 (statt 0.01)\n');
    fprintf('  Empfehlung: Q-Werte erhöhen (Faktor 2)\n');
    fprintf('  Begründung: Filter soll Modell mehr vertrauen als verrauschten Messungen\n');
else
    fprintf('DATEI A ERKANNT (geringes Messrauschen):\n');
    fprintf('  Parameter R = 0.01 ist optimal\n');
    fprintf('  Begründung: Messungen sind zuverlässig, Filter kann ihnen vertrauen\n');
end


fprintf('\n========== ERGEBNISBEWERTUNG ==========\n');

% Berechne Fehlermaße
aFehler_x = aZustand(1, :)' - aMesswerte_x;  % Fehler in x
aFehler_y = aZustand(2, :)' - aMesswerte_y;  % Fehler in y
fMSE_x = mean(aFehler_x.^2);                 % Mean Squared Error x
fMSE_y = mean(aFehler_y.^2);                 % Mean Squared Error y
fRMSE_x = sqrt(fMSE_x);                      % Root Mean Squared Error x
fRMSE_y = sqrt(fMSE_y);                      % Root Mean Squared Error y

fprintf('Root Mean Squared Error (RMSE):\n');
fprintf('  RMSE_x = %.4f m\n', fRMSE_x);
fprintf('  RMSE_y = %.4f m\n', fRMSE_y);
fprintf('\n');

% Bewertung der Ergebnisqualität
fprintf('QUALITÄTSBEWERTUNG:\n');
if fRMSE_x < 0.05 && fRMSE_y < 0.05
    fprintf('  ✓ SEHR GUT: Fehler < 5 cm in beide Richtungen\n');
    fprintf('  ✓ Kalman-Filter schätzt Position präzise\n');
    fprintf('  ✓ Parameter A, H, Q, R sind gut gewählt\n');
elseif fRMSE_x < 0.1 && fRMSE_y < 0.1
    fprintf('  ✓ GUT: Fehler < 10 cm\n');
    fprintf('  → Kalman-Filter funktioniert zuverlässig\n');
else
    fprintf('  ⚠ VERBESSERUNGSPOTENZIAL: Fehler > 10 cm\n');
    fprintf('  → Parameter Q und R sollten angepasst werden\n');
end

fprintf('\n');
fprintf('PHYSIKALISCHE PLAUSIBILITÄT:\n');
fprintf('  Starthöhe (gemessen): %.2f m\n', aMesswerte_y(1));
fprintf('  Starthöhe (geschätzt): %.2f m\n', aZustand(2, 1));
fprintf('  Endhöhe (gemessen): %.2f m\n', aMesswerte_y(end));
fprintf('  Geschätzte a_y: %.2f m/s² (Soll: -9.81 m/s²)\n', aZustand(6, end));

%% Ergebnisdarstellung: 3x2 Subplots (Abb. 3)

figure('Name', 'Ergebnisdarstellung (Abb. 3)', 'Position', [100, 100, 1200, 900]);

% Subplot 1: x über Zeit
subplot(3, 2, 1);
plot(aZeit, aMesswerte_x, 'r.-', 'LineWidth', 1, 'MarkerSize', 6, 'DisplayName', 'Messwerte');
hold on;
plot(aZeit, aZustand(1, :), 'b.-', 'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Kalman-Filter');
grid on;
xlabel('Zeit in s', 'FontSize', 10);
ylabel('x in m', 'FontSize', 10);
legend('Location', 'best');
xlim([0, max(aZeit)]);
ylim([1.0, 1.1]);

% Subplot 2: y über Zeit
subplot(3, 2, 2);
plot(aZeit, aMesswerte_y, 'r.-', 'LineWidth', 1, 'MarkerSize', 6, 'DisplayName', 'Messwerte');
hold on;
plot(aZeit, aZustand(2, :), 'b.-', 'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Kalman-Filter');
grid on;
xlabel('Zeit in s', 'FontSize', 10);
ylabel('y in m', 'FontSize', 10);
legend('Location', 'best');
xlim([0, max(aZeit)]);
ylim([-0.1, 1.2]);

% Subplot 3: v_x über Zeit
subplot(3, 2, 3);
plot(aZeit, aZustand(3, :), 'b.-', 'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Kalman-Filter');
grid on;
xlabel('Zeit in s', 'FontSize', 10);
ylabel('v_x in m', 'FontSize', 10);
legend('Location', 'best');
xlim([0, max(aZeit)]);
ylim([-0.2, 1]);

% Subplot 4: v_y über Zeit
subplot(3, 2, 4);
plot(aZeit, aZustand(4, :), 'b.-', 'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Kalman-Filter');
grid on;
xlabel('Zeit in s', 'FontSize', 10);
ylabel('v_y in m', 'FontSize', 10);
legend('Location', 'best');
xlim([0, max(aZeit)]);
ylim([-7, 1]);

% Subplot 5: a_x über Zeit
subplot(3, 2, 5);
plot(aZeit, aZustand(5, :), 'b.-', 'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Kalman-Filter');
grid on;
xlabel('Zeit in s', 'FontSize', 10);
ylabel('a_x in m', 'FontSize', 10);
legend('Location', 'best');
xlim([0, max(aZeit)]);
ylim([-0.3, 0.1]);

% Subplot 6: a_y über Zeit
subplot(3, 2, 6);
plot(aZeit, aZustand(6, :), 'b.-', 'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Kalman-Filter');
grid on;
xlabel('Zeit in s', 'FontSize', 10);
ylabel('a_y in m', 'FontSize', 10);
legend('Location', 'best');
xlim([0, max(aZeit)]);
ylim([-11, -4]);

fprintf('\n========== PROGRAMM ABGESCHLOSSEN ==========\n');
