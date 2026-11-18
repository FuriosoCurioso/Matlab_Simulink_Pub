%% Schraeger Wurf ohne Rauschen - Kalman-Filter
% Schritt: Ballverfolgung beim Baseball mit Kalman-Filter
% Eingangsgrößen: Messdaten_A.mat - Rohdaten ohne Rauschen aus Bildverarbeitung
% Modell: Beschleunigungs-Null-Modell (Konstante-Geschwindigkeit-Modell)
% Erdbeschleunigung wird als Stoerung u(k) = -g beruecksichtigt
% Zustandsvektor: x = [x; y; vx; vy] (4D)

clear all; clc; close all; clearvars;

%% Initialisierung
Nsamples = 643; % Anzahl der Messungen

t = 0;       % Initialisierung der Zykluszeit in s
dt = 0.01;   % Zykluszeit (Abtastrate) in s

% ALLOCATE Speicher fuer Ergebnisse
Xsaved = zeros(Nsamples, 4); % Zustandsvektoren [x, y, vx, vy]
Zsaved = zeros(Nsamples, 2); % Messvektoren [x, y]
Asaved = [];                 % Ausreisser-Array
nAusreisser = 0;             % Zaehler fuer Ausreisser

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Oberhalb dieses Kommentars nichts veraendern

for k = 1:Nsamples
    %% Messdaten laden
    % Lade aktuelle Position aus Bildverarbeitung (Messdaten_A.mat)
    Messung = LadeMessdaten(k); 
    
    %% Distanzgating - Ausreissererkennung
    % Pruefe ab der zweiten Messung auf unrealistische Werte
    if k > 1 
        [Messung, Ausreisser] = DistanzGating(x, Messung, t); 
        if ~isempty(Ausreisser)
            nAusreisser = nAusreisser + 1;
            Asaved(nAusreisser, :) = [Ausreisser'];
        end
    end
    
    %% Kalman Filter
    % Schaetze aktuellen Zustand [x, y, vx, vy]
    x = KalmanFilter(Messung, t);  
    
    %% Daten sichern
    Xsaved(k, :) = [x(1) x(2) x(3) x(4)]; % Speichere Zustandsschaetzung
    Zsaved(k, :) = [Messung'];             % Speichere Messwerte
    Zeit(k) = t;                           % Speichere Zeitstempel
    
    %% Zykluszeit berechnen
    t = t + dt; % Inkrementiere Zeit
end

%% Ergebnisdarstellung
% Visualisiere Flugbahn und Zustandsverlaeufe
ZeichneDiagramme(Zeit, Xsaved, Zsaved, Asaved); 

%% Gewuenschte Werte berechnen
% Berechne Scheitelpunkt, Anfangsgeschwindigkeiten und Wurfwinkel
[t1, Vx0, Vy0, V0, alpha] = Auswertung(Zeit, Xsaved); 

%% Ausgabe der Ergebnisse
disp('=== Auswertung des schraegen Wurfs (ohne Rauschen) ===')
disp(' ')
disp(['Zeitpunkt des Scheitelpunktes t1: ', num2str(t1, '%.3f'), ' s'])
disp(['Geschwindigkeit Vx0 bei t0=0s: ', num2str(Vx0(1), '%.3f'), ' m/s'])
disp(['Geschwindigkeit Vy0 bei t0=0s: ', num2str(Vy0(1), '%.3f'), ' m/s'])
disp(['Betrag der Geschwindigkeit |V0|: ', num2str(V0(1), '%.3f'), ' m/s'])
disp(['Wurfwinkel alpha bei t0=0s: ', num2str(alpha, '%.3f'), ' Grad'])
disp(' ')
disp(['Anzahl erkannter Ausreisser: ', num2str(nAusreisser)])

%% Funktion: KalmanFilter
function xEst = KalmanFilter(z, t)
    persistent A B H Q R u
    persistent x P
    
    %% INITIALIZE bei t=0 (erster Durchlauf)
    if t == 0
        dt = 0.01; % Abtastzeit in s
        
        % Eingangsgröße: Erdbeschleunigung
        u = -9.81; % m/s^2 (negativ = nach unten)
        
        % SETUP Systemmatrix A (Konstante-Geschwindigkeit-Modell)
        % Kinematik ohne Luftwiderstand:
        % x(k+1) = x(k) + vx(k)*dt
        % y(k+1) = y(k) + vy(k)*dt
        % vx(k+1) = vx(k) (konstant)
        % vy(k+1) = vy(k) (wird durch Eingangsgröße u beeinflusst)
        A = [1, 0, dt, 0;    % x-Position
             0, 1, 0,  dt;   % y-Position
             0, 0, 1,  0;    % x-Geschwindigkeit (konstant)
             0, 0, 0,  1];   % y-Geschwindigkeit
        
        % SETUP Eingangsmatrix B (Beschleunigung wirkt auf y)
        % Erdbeschleunigung beeinflusst y-Position und y-Geschwindigkeit
        B = [0;              % Kein Einfluss auf x
             0.5 * dt^2;     % Einfluss auf y (0.5*a*t^2)
             0;              % Kein Einfluss auf vx
             dt];            % Einfluss auf vy (a*t)
        
        % SETUP Messmatrix H (nur Position messbar)
        % Bildverarbeitung liefert nur x- und y-Koordinaten
        H = [1, 0, 0, 0;     % x-Position gemessen
             0, 1, 0, 0];    % y-Position gemessen
        
        % SETUP Prozessrauschen-Kovarianz Q
        % Sehr klein, da Messdaten ohne Rauschen (Rohdaten)
        Q = 0.01 * eye(4, 4); % Minimales Prozessrauschen
        
        % SETUP Messrauschen-Kovarianz R
        % Sehr klein, da keine Messungenauigkeit (Rohdaten ohne Rauschen)
        R = 0.01 * eye(2, 2); % Minimales Messrauschen
        
        % Initialer Zustandsvektor x0
        % Nutze erste Messung fuer Position, Geschwindigkeit=0
        z = z(:); % Stelle sicher, dass z Spaltenvektor ist
        x = [z(1); z(2); 0; 0]; % [x0, y0, vx0=0, vy0=0]
        
        % Initiale Fehlerkovarianzmatrix P
        % Hohes Vertrauen in Startposition (bekannt aus Messung)
        % Mittlere Unsicherheit in Geschwindigkeit (unbekannt)
        P = diag([0.1, 0.1, 10, 10]); % [sigma_x^2, sigma_y^2, sigma_vx^2, sigma_vy^2]
        
        disp('Kalman-Filter wurde initialisiert')
        disp(['  Abtastzeit dt = ', num2str(dt), ' s'])
        disp(['  Erdbeschleunigung u = ', num2str(u), ' m/s^2'])
        disp(['  Prozessrauschen Q = ', num2str(Q(1,1)), ' (minimal, da Rohdaten)'])
        disp(['  Messrauschen R = ', num2str(R(1,1)), ' (minimal, da Rohdaten)'])
        
        xEst = x;
        return; % Beende Initialisierung, gebe initialen Zustand zurueck
    end
    
    %% PREDICT Praediktionsphase
    % Vorhersage des Zustandsvektors mit Systemmodell und Eingangsgröße
    xp = A * x + B * u; % Praedizierter Zustand
    
    % Vorhersage der Fehlerkovarianz
    Pp = A * P * A' + Q; % Praedizierte Kovarianz
    
    %% UPDATE Korrekturphase
    % Berechnung der Kalman-Verstaerkung
    K = Pp * H' * inv(H * Pp * H' + R); % Kalman-Gain
    
    % Korrektur der Zustandsschaetzung
    if ~isnan(z(1)) && ~isnan(z(2))
        % Normale Messung vorhanden
        x = xp + K * (z - H * xp); % Korrigierter Zustand
    else
        % Keine Messwerte (Ausreisser) -> nur Praediktion verwenden
        x = xp; 
    end
    
    % Korrektur der Kovarianzschaetzung
    P = Pp - K * H * Pp; % Korrigierte Kovarianz
    
    %% RETURN Rueckgabewerte
    xEst = x; % Geschaetzter Zustand [x, y, vx, vy]
end
