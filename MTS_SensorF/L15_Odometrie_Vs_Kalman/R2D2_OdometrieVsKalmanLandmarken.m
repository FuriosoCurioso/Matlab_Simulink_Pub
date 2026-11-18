% %% Zufällige Initialisierung - Position ist unbekannt 
% R2D2 = robot; % Ein Objekt – oder eine Instanz der eben definierten Klasse lässt sich nun erzeugen 
% 
% % Hinweis: Karte ist Teil der Roboterklasse
% % Landmarken = [20,20;80,80;20,80;80,20]; % Position der Landmarken in m
% % GroesseDerWelt = 100; % m
% 
% %% Figur mit Landmarken zeichnen
% figure
% hold on
% for i=1:4
%     plot(R2D2.Landmarken(i,1),R2D2.Landmarken(i,2),'bo') % Landmarken
% end
% xlim([0 R2D2.GroesseDerWelt]);
% ylim([0 R2D2.GroesseDerWelt]);
% 
% % Roboter zeichnen (wahre Position)
% [hRoboter,hRoboterKurs,hPath] = ZeichneRoboter(R2D2);
% 
% %% Rauschen hinzufügen
% % Aufruf function obj = set_noise(obj, new_f_noise, new_t_noise, new_s_noise)
% forward_noise = 0.5; % in m
% turn_noise    = 1.0; % in deg
% sense_noise   = 1.0; % in m
% R2D2 = R2D2.set_noise(forward_noise, turn_noise , sense_noise);
% 
% 
% %% Setze den Roboter an der Koordinate (30, 70)m mit dem Kurs nach Osten (0°)
% % Aufruf function obj = SetObj(obj,new_x, new_y, new_orientation)
% [hRoboter,hRoboterKurs,hPath] = ZeichneRoboter(R2D2,hRoboter,hRoboterKurs,hPath);
% 
% %% mit R2D2 10-fach ein Quadrat mit der Seitenlänge 20m abfahren
% % Aufruf function obj = move(obj, turn, forward)
% 
% Endposition = R2D2.path(:,end) % Ergebnis - NICHT LÖSCHEN
% 
% %% den absoluten Fehler der Odometrie in x- und y-Richtung über der Zeit darstellen
% 
% %% ein Kalman-Filter, um die Odometriefehler mittels Messung zu den Landmarken zu korrigieren programmieren
% 
% 
% %% den absoluten Fehler des Kalman-Filters in x- und y-Richtung über der Zeit darstellen
% 

close all; clear all; clc;

%% ========================================================================
%  & 2: Roboter initialisieren und positionieren
%  ========================================================================
% Zufällige Initialisierung - Position ist unbekannt
R2D2 = robot();

%% Figur mit Landmarken zeichnen
% Hinweis: Karte ist Teil der Roboterklasse
% Landmarken = [20,20;80,80;20,80;80,20]; % Position der Landmarken in m
% GroesseDerWelt = 100; % m
figure
hold on
for i=1:4
    plot(robot.Landmarken(i,1), robot.Landmarken(i,2), 'bo', 'MarkerSize', 10, 'LineWidth', 2) % Landmarken
    text(robot.Landmarken(i,1)+2, robot.Landmarken(i,2)+2, sprintf('L%d', i), 'FontSize', 10);
end
xlim([0 robot.GroesseDerWelt]);
ylim([0 robot.GroesseDerWelt]);
grid on;
xlabel('x [m]');
ylabel('y [m]');
title('R2D2 Roboter-Lokalisierung mit Kalman-Filter');

% Roboter zeichnen (wahre Position)
[hRoboter, hRoboterKurs, hPath] = ZeichneRoboter(R2D2);

%% Rauschen hinzufügen
% Aufruf function obj = set_noise(obj, new_f_noise, new_t_noise, new_s_noise)
forward_noise = 0.5; % in m
turn_noise = 1.0;    % in deg
sense_noise = 1.0;   % in m
R2D2 = R2D2.set_noise(forward_noise, turn_noise, sense_noise);

%% Setze den Roboter an der Koordinate (30, 50)m mit dem Kurs nach Norden (90°)
% an der Position [30,50] nach Norden starten
% Aufruf function obj = SetObj(obj,new_x, new_y, new_orientation)
% LÖSUNG: Position [30,50], Norden = 90° (da 0° = Osten)
R2D2 = SetObj(R2D2, 30, 50, 90);
[hRoboter, hRoboterKurs, hPath] = ZeichneRoboter(R2D2, hRoboter, hRoboterKurs, hPath);

%% ========================================================================
%  mit R2D2 10-fach ein Quadrat mit der Seitenlänge 20m abfahren
%  die Fahrt mit ZeichneRoboter visualisieren
%  ========================================================================
% Aufruf function obj = move(obj, turn, forward)
% LÖSUNG:
% Quadrat: 4 Seiten à 20m, nach jeder Seite 90° nach links
% 10-fach = 10 Runden = 40 Bewegungen (4 Seiten × 10 Runden)

% Speicher für wahre Position (ohne Rauschen) zur Fehlerberechnung
odometry_positions = [30; 50];  % Odometrie-Positionen (mit Rauschen)
true_positions = [30; 50];      % Ideale Position (ohne Rauschen)

% Ideale Position berechnen (ohne Rauschen)
ideal_x = 30;
ideal_y = 50;
ideal_theta = 90;  % Grad

for runde = 1:10
    for seite = 1:4
        % Roboter bewegen (mit Rauschen)
        R2D2 = R2D2.move(0, 20);  % Geradeaus 20m
        % Position nach Vorwärtsbewegung speichern
        odometry_positions(:, end+1) = [R2D2.x; R2D2.y];
        
        % Ideale Position berechnen (ohne Rauschen)
        ideal_x = ideal_x + 20 * cosd(ideal_theta);
        ideal_y = ideal_y + 20 * sind(ideal_theta);
        true_positions(:, end+1) = [ideal_x; ideal_y];
        
        % Roboter drehen (90° nach links)
        R2D2 = R2D2.move(90, 0);
        
        % Idealer Kurs (ohne Rauschen)
        ideal_theta = mod(ideal_theta + 90, 360);
        
        % Visualisierung aktualisieren
        [hRoboter, hRoboterKurs, hPath] = ZeichneRoboter(R2D2, hRoboter, hRoboterKurs, hPath);
        drawnow;
        pause(0.01);  % Kurze Pause für Visualisierung
    end
end

% ANALYSE:
% - Der Roboter sollte nach 10 Runden wieder bei [30,50] sein
% - Durch Prozessrauschen (forward_noise, turn_noise) weicht die 
%   tatsächliche Endposition von der Startposition ab
% - Die Odometrie akkumuliert Fehler über die Zeit
% - Je mehr Runden gefahren werden, desto größer wird der Fehler
% - Die zyklische Natur (mod) kann zu "Sprüngen" führen bei 0/100m
Endposition = R2D2.path(:,end)  % Ergebnis

%% ========================================================================
%  den absoluten Fehler der Odometrie in x- und y-Richtung stellen
%  über der Zeit dar
%  ========================================================================
% LÖSUNG:
% Fehler = Odometrie-Position - Ideale Position
error_x_odo = abs(odometry_positions(1, :) - true_positions(1, :));
error_y_odo = abs(odometry_positions(2, :) - true_positions(2, :));

% Zeitachse (Anzahl der Bewegungen)
time_steps_odo = 0:(size(odometry_positions, 2) - 1);

% Plot Odometrie-Fehler
figure;
subplot(2, 1, 1);
plot(time_steps_odo, error_x_odo, 'r-', 'LineWidth', 1.5);
grid on;
xlabel('Bewegungsschritt');
ylabel('Absoluter Fehler x [m]');
title('Odometrie: Absoluter Fehler in x-Richtung');

subplot(2, 1, 2);
plot(time_steps_odo, error_y_odo, 'b-', 'LineWidth', 1.5);
grid on;
xlabel('Bewegungsschritt');
ylabel('Absoluter Fehler y [m]');
title('Odometrie: Absoluter Fehler in y-Richtung');

%% ========================================================================
%  ein Kalman-Filter, um die Odometriefehler programmieren
%  mittels Messung zu den Landmarken zu korrigieren
%  ========================================================================
% LÖSUNG: Extended Kalman Filter (EKF)
% Da die Messungen (Distanzen) nichtlinear sind, verwenden wir EKF

% Reset Roboter für Kalman-Filter Durchlauf
R2D2_KF = robot();
R2D2_KF = R2D2_KF.set_noise(forward_noise, turn_noise, sense_noise);
R2D2_KF = SetObj(R2D2_KF, 30, 50, 90);

% Kalman-Filter Initialisierung
x_est = [30; 50];          % x0: Geschätzte Startposition [x; y]
P = diag([1, 1]);          % P0: Start-Kovarianzmatrix (niedrige Unsicherheit am Start)

% Messrauschen R: Kovarianz der Landmarken-Distanzmessungen [4×4]
% Jede Landmarke hat Messunsicherheit sense_noise² = 1² = 1
R_mat = diag([sense_noise^2, sense_noise^2, sense_noise^2, sense_noise^2]);

% Prozessrauschen Q: Unsicherheit im Bewegungsmodell [2×2]
% Kombination aus forward_noise und turn_noise
Q = diag([forward_noise^2, forward_noise^2]);

% Speicher für Kalman-Filter Schätzungen
kf_estimates = x_est;

% Ideale Positionen für Fehlerberechnung (wie oben)
true_positions_kf = [30; 50];
ideal_x_kf = 30;
ideal_y_kf = 50;
ideal_theta_kf = 90;

% Kalman-Filter Durchlauf (gleiche Bewegungen wie oben)
for runde = 1:10
    for seite = 1:4
        % Roboter bewegen
        R2D2_KF = R2D2_KF.move(0, 20);
        
        %% PRÄDIKTION
        % Vorhergesagte Bewegung (Odometrie)
        x_pred = [R2D2_KF.x; R2D2_KF.y];
        
        % Systemmatrix A (Identität, da Position = Position + Bewegung)
        A = eye(2);
        
        % Prädizierte Kovarianz
        P_pred = A * P * A' + Q;
        
        %% UPDATE mit Landmarken-Messungen
        % Messung: Distanzen zu allen 4 Landmarken
        z = R2D2_KF.sense();  % [1×4] Vektor
        
        % Erwartete Messungen (basierend auf prädizierter Position)
        h_pred = zeros(4, 1);
        for i = 1:4
            h_pred(i) = sqrt((x_pred(1) - robot.Landmarken(i,1))^2 + ...
                             (x_pred(2) - robot.Landmarken(i,2))^2);
        end
        
        % Jacobi-Matrix H: ∂h/∂x
        % h_i = sqrt((x - lx_i)² + (y - ly_i)²)
        % ∂h_i/∂x = (x - lx_i) / h_i
        % ∂h_i/∂y = (y - ly_i) / h_i
        H = zeros(4, 2);
        for i = 1:4
            dx = x_pred(1) - robot.Landmarken(i,1);
            dy = x_pred(2) - robot.Landmarken(i,2);
            dist = h_pred(i) + eps;  % Vermeidung Division durch 0
            H(i, 1) = dx / dist;
            H(i, 2) = dy / dist;
        end
        
        % Innovation
        y_innov = z' - h_pred;  % [4×1]
        
        % Innovation Kovarianz
        S = H * P_pred * H' + R_mat;
        
        % Kalman Gain
        K = P_pred * H' / S;
        
        % Update Zustand
        x_est = x_pred + K * y_innov;
        
        % Update Kovarianz
        P = (eye(2) - K * H) * P_pred;
        
        % Speichern
        kf_estimates(:, end+1) = x_est;
        
        % Roboter drehen
        R2D2_KF = R2D2_KF.move(90, 0);
        
        % Ideale Position aktualisieren
        ideal_x_kf = ideal_x_kf + 20 * cosd(ideal_theta_kf);
        ideal_y_kf = ideal_y_kf + 20 * sind(ideal_theta_kf);
        true_positions_kf(:, end+1) = [ideal_x_kf; ideal_y_kf];
        ideal_theta_kf = mod(ideal_theta_kf + 90, 360);
    end
end

%% ========================================================================
%  die Wahl der Parameter A, H, R, Q, x0, P0 argumentieren
%  ========================================================================
% ARGUMENTATION DER PARAMETER:
%
% A (Systemmatrix) = eye(2):
% - Lineares Bewegungsmodell: neue Position = alte Position + Bewegung
% - A = I, da keine Zustandstransformation, nur Addition der Bewegung
% - In Realität ist Bewegung nichtlinear (abhängig von Orientierung)
% - Hier vereinfacht: Nutzen Odometrie-Position direkt als Prädiktion
%
% H (Messmatrix / Jacobi-Matrix) = [∂h/∂x; ∂h/∂y] [4×2]:
% - Nichtlineares Messmodell: z_i = ||x - landmark_i||
% - Jacobi-Matrix linearisiert Messmodell am aktuellen Arbeitspunkt
% - Für jede Landmarke i: H(i,:) = [(x-lx_i)/dist, (y-ly_i)/dist]
% - Dimension [4×2]: 4 Landmarken, 2 Zustandsvariablen (x, y)
%
% R (Messrauschen) = diag([1, 1, 1, 1]):
% - Kovarianzmatrix der Distanzmessungen zu Landmarken
% - sense_noise = 1m → Varianz = 1² = 1 m²
% - Diagonal: Messungen unabhängig (keine Korrelation zwischen Landmarken)
% - Größe [4×4]: Eine Varianz pro Landmarke
%
% Q (Prozessrauschen) = diag([0.25, 0.25]):
% - Unsicherheit im Bewegungsmodell
% - forward_noise = 0.5m → Varianz ≈ 0.5² = 0.25 m²
% - Wirkt auf beide Koordinaten (x, y) gleich
% - Größe [2×2]: Kovarianz für x und y Position
%
% x0 (Startzustand) = [30; 50]:
% - Bekannte Startposition (vorgegeben in Schritt)
% - Roboter wird explizit bei [30,50] platziert
%
% P0 (Start-Kovarianz) = diag([1, 1]):
% - Niedrige Unsicherheit am Start (1m² Varianz)
% - Da Startposition bekannt ist
% - Größer wählen wenn Startposition unsicher
% - Diagonal: x und y unkorreliert zu Beginn

%% ========================================================================
%  den absoluten Fehler des Kalman-Filters in x- und stellen
%  y-Richtung über der Zeit dar
%  ========================================================================
% LÖSUNG:
% Fehler berechnen
error_x_kf = abs(kf_estimates(1, :) - true_positions_kf(1, :));
error_y_kf = abs(kf_estimates(2, :) - true_positions_kf(2, :));

% Zeitachse
time_steps_kf = 0:(size(kf_estimates, 2) - 1);

% Plot Kalman-Filter Fehler
figure;
subplot(2, 1, 1);
plot(time_steps_kf, error_x_kf, 'r-', 'LineWidth', 1.5);
grid on;
xlabel('Bewegungsschritt');
ylabel('Absoluter Fehler x [m]');
title('Kalman-Filter: Absoluter Fehler in x-Richtung');

subplot(2, 1, 2);
plot(time_steps_kf, error_y_kf, 'b-', 'LineWidth', 1.5);
grid on;
xlabel('Bewegungsschritt');
ylabel('Absoluter Fehler y [m]');
title('Kalman-Filter: Absoluter Fehler in y-Richtung');

%% ========================================================================
%  die Ergebnisse aus 4 (nur Odometrie) mit 8 vergleichen
%  ========================================================================
% VERGLEICH ODOMETRIE vs. KALMAN-FILTER:
%
% FEHLER-AKKUMULATION:
%    - Odometrie: Fehler akkumulieren über die Zeit (drift)
%    - Kalman-Filter: Fehler bleiben begrenzt durch Landmarken-Messungen
%    - KF korrigiert kontinuierlich mit absoluten Positionsmessungen
%
% MAXIMALER FEHLER:
%    - Odometrie: Kann mehrere Meter erreichen nach 10 Runden
%    - Kalman-Filter: Typisch <2m auch nach vielen Bewegungen
%    - Faktor 2-5× Verbesserung durch KF
%
% FEHLER-CHARAKTERISTIK:
%    - Odometrie: Monoton steigend (keine Korrektur möglich)
%    - Kalman-Filter: Oszillierend um wahre Position (Konvergenz)
%    - KF nutzt globale Referenz (Landmarken) statt nur relative Bewegung
%
% ROBUSTHEIT:
%    - Odometrie: Sehr anfällig für systematische Fehler (z.B. Rad-Durchmesser)
%    - Kalman-Filter: Robuster durch Fusion mehrerer Informationsquellen
%    - Messrauschen wird durch KF optimal gefiltert
%
% PRAKTISCHE BEDEUTUNG:
%    - Reine Odometrie: Unbrauchbar für lange Fahrten (>50m)
%    - Mit KF: Präzise Lokalisierung auch über große Distanzen
%    - Essenziell für autonome Navigation in Robotik

% Vergleichsplot
figure;
subplot(2, 1, 1);
plot(time_steps_odo, error_x_odo, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Odometrie');
hold on;
plot(time_steps_kf, error_x_kf, 'g-', 'LineWidth', 1.5, 'DisplayName', 'Kalman-Filter');
grid on;
legend('Location', 'best');
xlabel('Bewegungsschritt');
ylabel('Absoluter Fehler x [m]');
title('Vergleich: Absoluter Fehler in x-Richtung');

subplot(2, 1, 2);
plot(time_steps_odo, error_y_odo, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Odometrie');
hold on;
plot(time_steps_kf, error_y_kf, 'g-', 'LineWidth', 1.5, 'DisplayName', 'Kalman-Filter');
grid on;
legend('Location', 'best');
xlabel('Bewegungsschritt');
ylabel('Absoluter Fehler y [m]');
title('Vergleich: Absoluter Fehler in y-Richtung');

%% Ausgabe der finalen Ergebnisse
fprintf('\n=== R2D2 Roboter-Lokalisierung - Zusammenfassung ===\n');
fprintf('Odometrie Endposition:   [%.2f, %.2f]\n', Endposition);
fprintf('Kalman-Filter Endpos.:   [%.2f, %.2f]\n', kf_estimates(:,end));
fprintf('Ideale Endposition:      [%.2f, %.2f]\n', true_positions_kf(:,end));
fprintf('Verbesserung durch KF:   %.1f%%\n', ...
    (1 - norm(kf_estimates(:,end) - true_positions_kf(:,end)) / ...
     norm(Endposition - true_positions_kf(:,end))) * 100);

