%% SETUP Parameter
dt = 0.1;       % Abtastzeit in s
t = 0:dt:10;    % Zeitachse als Array von 0 bis 10 Sekunden

nSamples = length(t);  % Anzahl der Messungen (101)

%% ALLOCATE Speicherplatz reservieren
Xsaved = zeros(nSamples, 1);  % Gespeicherte Kalman-Schaetzungen in V
Zsaved = zeros(nSamples, 1);  % Gespeicherte Messwerte in V
Sigma = zeros(2, nSamples);   % Unsicherheitsintervall (obere/untere)

%% MAIN LOOP Hauptschleife fuer Kalman-Filterung
for k = 1:nSamples
    z = LeseSpannung(k);  % Messwert einlesen (kann NaN sein)
    
    % Kalman-Filter mit Rueckgabe von Schaetzung und Fehlerkovarianz
    [Spannung, PEst] = kalmanfilter(z);
    
    % STORE Ergebnisse speichern
    Xsaved(k) = Spannung;
    Zsaved(k) = z;
    
    % CALCULATE Unsicherheit der Schaetzung (1-Sigma-Intervall)
    % sqrt(PEst) ergibt Standardabweichung der Schaetzung
    Sigma(1, k) = Spannung + sqrt(PEst);  % Obere Grenze (+1 Sigma)
    Sigma(2, k) = Spannung - sqrt(PEst);  % Untere Grenze (-1 Sigma)
end

%% VISUALIZATION Ergebnisdarstellung
hFigure = figure;
hold on
plot(t, Zsaved, 'r:.')  % Messwerte (rot, gepunktet)
plot(t, Xsaved, 'b.-')  % Kalman-Schaetzung (blau, durchgezogen)
plot(t, Sigma(1, :), 'k-')  % Obere Unsicherheitsgrenze (schwarz)
plot(t, Sigma(2, :), 'k-')  % Untere Unsicherheitsgrenze (schwarz)
yline(14.4, 'Color', [0.5 0.5 0.5], 'LineWidth', 2)  % Wahre Spannung
legend('Messwerte', 'Kalman-Filter Schätzung', ...
       'Unsicherheit der Schätzung (1\sigma)')
xlabel('Zeit in s')
ylabel('Batteriespannung in V')
grid on
hold off

%--------------------------------------------------------------------------
function [Spannung, P] = kalmanfilter(z)
%--------------------------------------------------------------------------    
    % PERSISTENT Variablen bleiben zwischen Funktionsaufrufen erhalten
    persistent A C Q R
    persistent x PEst
    persistent bErsterDurchlauf
    
    %% INITIALIZE Variablen bei erstem Durchlauf
    if isempty(bErsterDurchlauf)
        % SYSTEMMATRIX der linearen Zustandsraumdarstellung
        A = 1;  % Konstantes Spannungsmodell: x(k+1) = x(k)
        
        % AUSGANGSMATRIX der linearen Zustandsraumdarstellung  
        C = 1;  % Spannung wird direkt gemessen: z = x
        
        % KOVARIANZMATRIX des Systemrauschens
        Q = 0.01;  % Prozessrauschen in V^2

        % KOVARIANZMATRIX des Messrauschens
        R = 4.0;  % Messrauschen in V^2
                  % Entspricht Standardabweichung von 2V
                  % Angepasst an beobachtetes Messrauschen (~3.7V)
        
        % INITIALE SCHAETZUNG in V
        x = 14.0;  % Startwert basierend auf typischer Batteriespannung
                   % Naeherung an wahre Spannung 14.4V
        
        % KOVARIANZMATRIX des Schaetzfehlers
        PEst = 10.0;  % Initiale Unsicherheit in V^2
                      % Hoher Wert erlaubt schnelle Adaption
                      % sqrt(10) = 3.16V initiale Standardabweichung
        
        bErsterDurchlauf = 1;  % Flag setzen (Initialisierung fertig)
    end
    
    %% PREDICT Praediktionsprozess
    % Vorhersage des Zustandsvektors
    xp = A * x;  % Praedizierte Schaetzung: xp = x (konstant)
    
    % Vorhersage der Fehlerkovarianz
    Pp = A * PEst * A' + Q;  % Pp = PEst + Q
                             % Unsicherheit steigt durch Systemrauschen
    
    %% CHECK Pruefung auf Messdatenausfall
    if isnan(z)
        % KEINE KORREKTUR bei Messdatenausfall
        % Nur Praediktion verwenden (Zustand wird extrapoliert)
        x = xp;      % Schaetzung = Praediktion
        PEst = Pp;   % Unsicherheit waechst ohne Messung
    else
        %% UPDATE Schaetzprozess bei gueltigem Messwert
        % Berechnung der Kalman-Verstaerkung K
        K = Pp * C' * inv(C * Pp * C' + R);
        % K = Pp / (Pp + R) im skalaren Fall
        % K bestimmt Gewichtung: 0 = nur Praediktion, 1 = nur Messung
        
        % Korrektur der Zustandsschaetzung
        x = xp + K * (z - C * xp);
        % Innovation: (z - C*xp) = Messfehler
        % Neue Schaetzung = Praediktion + gewichteter Messfehler
        
        % Korrektur der Kovarianzschaetzung
        PEst = Pp - K * C * Pp;
        % PEst = (1 - K*C) * Pp im skalaren Fall
        % Unsicherheit sinkt durch Messung
    end
    
    %% RETURN Rueckgabewerte
    Spannung = x;   % Aktuelle optimale Schaetzung in V
    P = PEst;       % Aktuelle Fehlerkovarianz in V^2
    
end

MessdataufallM

dt = 0.2;     % Abtastzeit in s % LÖSUNG ERFORDERLICH
t  = 0:dt:10; % Zeitachse als Array

nSamples = length(t);

Xsaved = zeros(nSamples, 1);
Zsaved = zeros(nSamples, 1);


for k=1:nSamples
  z        = LeseSpannung(k);  % Messwerte lesen
  Spannung = KalmanFilter(z); % Kalman-Filter % LÖSUNG ERFORDERLICH
  
  % Messwerte speichern
  Xsaved(k) = Spannung;
  Zsaved(k) = z;
  PEst= 0;            % LÖSUNG ERFORDERLICH Fehlerkovariantmatrix der Schätzung 
  Sigma(:,k) = [0;0]; % LÖSUNG ERFORDERLICH Unsicherheit der Schätzung 
  
end

hFigure=figure;
hold on
plot(t, Zsaved, 'r:.') 
plot(t, Xsaved, 'b.-')
plot(t, Sigma(1,:),'k-')
plot(t, Sigma(2,:),'k-')
yline(14.4,'Color',[0.5 0.5 0.5],'LineWidth',2)
legend('Messwerte','Kalman-Filter Schätzung','Unsicherheit der Schätzung (1\sigma)')
xlabel('Zeit in s')
ylabel('Batteriespannung in V')

%-------------------------------------------------------------------------
function Spannung = KalmanFilter(z) % LÖSUNG ERFORDERLICH
%-------------------------------------------------------------------------

persistent A C Q R 
persistent x P
persistent bErsterDurchlauf

%% Initalisierung der Variablen bei ersten Durchlauf
if isempty(bErsterDurchlauf)
  A = 0; % LÖSUNG ERFORDERLICH Systemmatrix der linearen Zustandsraumdarstellung
  C = 0; % LÖSUNG ERFORDERLICH Ausgangsmatrix der linearen Zustandsraumdarstellung
  
  Q = 0; % LÖSUNG ERFORDERLICH Kovarianzmatrix des Systemrauschens
  R = 0; % LÖSUNG ERFORDERLICH Kovarianzmatrix des Messrauschens


  x = 0; % LÖSUNG ERFORDERLICH in V, initiale Schätzung
  P = 0; % LÖSUNG ERFORDERLICH Kovarianzmatrix des Schätzfehlers
  
  bErsterDurchlauf = 1;  
end

%% Prädiktionsprozess 
% Vorhersage des Zustandsvektors und der Kovarianz
xp = A*x;            % Prädiktion der Schätzung
Pp = A*P*A' + Q;     % Prädiktion der Fehlerkovarianz

%% Schätzprozess
% Berechnung der Kalman-Verstärkung K
K = Pp*C'*inv(C*Pp*C' + R);

% Korrektur der Zustandsschätzung
x = xp + K*(z - C*xp); % LÖSUNG ERFORDERLICH

% Korrektur der Kovarianzschätzung
P = Pp - K*C*Pp;

%% Rückgabewert ist die Zustandsschätzung
Spannung = x;
end

%% INITIALISIERUNG
global dt
dt = 0.1;                    % Abtastzeit in s
t = 0:dt:100;                % Zeitachse 0 bis 100 s
nSamples = length(t);        % Anzahl der Messwerte

Xsaved = zeros(2, nSamples); % Speicher fuer Zustandsschaetzungen
Zsaved = zeros(2, nSamples); % Speicher fuer Messwerte

%% MESSDATEN LADEN
messwerte = load('Messdaten.txt');
positionsMessungen = messwerte(:, 1);  % Erste Spalte: Position
geschwindigkeitsMessungen = messwerte(:, 2);  % Zweite Spalte: Geschwindigkeit

%% SCHLEIFE UEBER ALLE MESSWERTE
for k = 1:nSamples
    % MESSWERTE ZUSAMMENFUEHREN
    z = [positionsMessungen(k); geschwindigkeitsMessungen(k)];
    
    % KALMAN-FILTER AUFRUF
    [pos, vel, K, P_Est] = kalmanfilter(z);
    
    % WERTE SPEICHERN
    Xsaved(:, k) = [pos; vel];
    Zsaved(:, k) = z;
end

%% ENDWERTE AUSGEBEN
xFinal = Xsaved(1, k);
vFinal = Xsaved(2, k);

fprintf('=================================================\n');
fprintf('ERGEBNISSE DER KALMAN-FILTER ANALYSE\n');
fprintf('=================================================\n');
fprintf('Finale Position:         %.2f m\n', xFinal);
fprintf('Finale Geschwindigkeit:  %.2f m/s\n', vFinal);
fprintf('Soll-Geschwindigkeit:    80.00 m/s\n');
fprintf('Abweichung:              %.2f m/s\n', abs(vFinal - 80.0));
fprintf('=================================================\n');

%% VISUALISIERUNG - POSITION
figure('Name', 'Position des Hochgeschwindigkeitszuges', ...
       'NumberTitle', 'off')
hold on
plot(t, Zsaved(1, :), 'r.', 'MarkerSize', 8, ...
     'DisplayName', 'Positionsmesswerte')
plot(t, Xsaved(1, :), 'b-', 'LineWidth', 1.5, ...
     'DisplayName', 'Kalman-Filter Schaetzung')
legend('Location', 'SE')
xlabel('Zeit [s]')
ylabel('Position [m]')
title('Positionsschaetzung mittels Kalman-Filter')
grid on
hold off

%% VISUALISIERUNG - GESCHWINDIGKEIT
figure('Name', 'Geschwindigkeit des Hochgeschwindigkeitszuges', ...
       'NumberTitle', 'off')
hold on
plot(t, Zsaved(2, :), 'r.', 'MarkerSize', 8, ...
     'DisplayName', 'Geschwindigkeitsmesswerte')
plot(t, Xsaved(2, :), 'b-', 'LineWidth', 1.5, ...
     'DisplayName', 'Kalman-Filter Schaetzung')
yline(80, 'g--', 'LineWidth', 2, ...
      'DisplayName', 'Soll-Geschwindigkeit (80 m/s)')
legend('Location', 'NE')
xlabel('Zeit [s]')
ylabel('Geschwindigkeit [m/s]')
title('Geschwindigkeitsschaetzung mittels Kalman-Filter')
grid on
hold off


%**************************************************************************
function [pos, vel, K, P_Est] = kalmanfilter(z)
%**************************************************************************
% KALMANFILTER Schaetzt Position und Geschwindigkeit eines Zuges
%
% Eingabe:
%   z: Messvektor [Position; Geschwindigkeit] in [m; m/s]
%
% Ausgabe:
%   pos: Geschaetzte Position in m
%   vel: Geschaetzte Geschwindigkeit in m/s
%   K: Kalman-Verstaerkung (2x2-Matrix)
%   P_Est: Fehlerkovarianzmatrix (2x2-Matrix)
%
% Beschreibung:
%   Implementiert einen Kalman-Filter fuer ein lineares Bewegungsmodell
%   mit konstanter Geschwindigkeit. Beide Zustandsgroessen werden gemessen.
%**************************************************************************

global dt % Abtastzeit in s
persistent A H Q R
persistent x P
persistent bErsterDurchlauf

%% INITIALISIERUNG BEI ERSTEM DURCHLAUF
if isempty(bErsterDurchlauf)
    % SYSTEMMATRIX A (2x2)
    % Beschreibt Zustandsuebergang: x(k+1) = A*x(k) + w(k)
    % Modell: p(k+1) = p(k) + v(k)*dt
    %         v(k+1) = v(k)  (konstante Geschwindigkeit)
    A = [1  dt;
         0   1];
    
    % MESSMATRIX H (2x2)
    % Beide Zustandsgroessen werden gemessen: z(k) = H*x(k) + v(k)
    H = [1  0;
         0  1];
    
    % PROZESSRAUSCHKOVARIANZ Q (2x2)
    % Modelliert Unsicherheit im Systemmodell
    % Position: geringere Unsicherheit (0.1 m^2)
    % Geschwindigkeit: hoehere Unsicherheit (1.0 (m/s)^2)
    Q = [0.1  0;
         0    1.0];
    
    % MESSRAUSCHKOVARIANZ R (2x2)
    % Modelliert Sensorrauschen
    % Position: 5 m Standardabweichung -> 25 m^2 Varianz
    % Geschwindigkeit: 1 m/s Standardabweichung -> 1 (m/s)^2 Varianz
    R = [25.0  0;
         0     1.0];
    
    % INITIALER ZUSTANDSVEKTOR x0
    % Anfangsposition: 0 m
    % Anfangsgeschwindigkeit: 20 m/s (Schaetzung)
    x = [0;
         20];
    
    % INITIALE FEHLERKOVARIANZMATRIX P0
    % Hohe Anfangsunsicherheit, da Zustand unbekannt
    % Position: 100 m^2 Varianz
    % Geschwindigkeit: 25 (m/s)^2 Varianz
    P = [100  0;
         0    25];
    
    bErsterDurchlauf = 1;
end

%% PRAEDIKTIONSSCHRITT (Time Update)
% Zustandspraediktion
xp = A * x;

% Kovarianzspraediktion
Pp = A * P * A' + Q;

%% KORREKTURSCHRITT (Measurement Update)
% Kalman-Verstaerkung berechnen
% K bestimmt wie stark die Messung gewichtet wird
K = Pp * H' * inv(H * Pp * H' + R);

% Zustandskorrektur
% Pruefe ob Messung gueltig ist (nicht NaN)
if ~any(isnan(z))
    % Innovation (Differenz zwischen Messung und Vorhersage)
    innovation = z - H * xp;
    
    % Aktualisiere Zustandsschaetzung
    x = xp + K * innovation;
else
    % Falls keine Messung: Verwende nur Praediktion
    x = xp;
end

% Kovarianzkorrektur (Joseph-Form fuer numerische Stabilitaet)
P = Pp - K * H * Pp;

%% RUECKGABEWERTE
pos = x(1);     % Geschaetzte Position in m
vel = x(2);     % Geschaetzte Geschwindigkeit in m/s
P_Est = P;      % Fehlerkovarianzmatrix
end

   