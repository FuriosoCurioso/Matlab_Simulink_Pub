%% Mondlandung mittels Kalman-Filter
% Schritt: Schaetzung des Landezustands (Hoehe, Geschwindigkeit, Beschleunigung)
% einer Mondlandefaehre basierend auf verrauschten Hoehen- und Beschleunigungsmessungen
% Zustandsvektor: x = [h; v; a] (Hoehe, Geschwindigkeit, Beschleunigung)
% Modell: Konstante-Beschleunigung-Modell

clear all; clc; close all; clearvars;
%% Initialisierung
nMesswerte = 500; % Anzahl Messwerte in der Datei

% ALLOCATE Speicher fuer Ergebnisse
t = zeros(nMesswerte, 1); % Zeit
h = zeros(nMesswerte, 1); % Hoehenmessungen
a = zeros(nMesswerte, 1); % Beschleunigungsmessungen
x = zeros(nMesswerte, 3); % Zustandsvektoren [h, v, a]

%% Zyklusschleife
for i = 1:nMesswerte
    [z, t(i)] = leseMesswerte(i); % Messwerte zyklisch laden
    h(i) = z(1); % Hoehenmessung speichern
    a(i) = z(2); % Beschleunigungsmessung speichern
    x(i, :) = KalmanFilter(z); % Kalman-Filter anwenden
end

%% Ergebnisdarstellung
figure

% PLOT 1: Hoehe ueber Zeit
subplot(3, 1, 1)
hold on
yline(0, 'Color', [0.5 0.5 0.5], 'LineWidth', 2)
plot(t, h, 'r.-')
plot(t, x(:, 1), 'b.-')
xlabel('Zeit t in s')
ylabel('Position h(t) in m')
xlim([0, t(end)])
legend('Mondoberfläche', 'Messwerte', 'Kalman-Filter')
grid on
hold off 

% PLOT 2: Beschleunigung ueber Zeit
subplot(3, 1, 2)
hold on
plot(t, a, 'r.-')
plot(t, x(:, 3), 'b.-')
xlabel('Zeit t in s')
ylabel('Beschleunigung a(t) in m/s^2')
xlim([0, t(end)])
legend('Messwerte', 'Kalman-Filter')
grid on
hold off 

% PLOT 3: Geschwindigkeit ueber Zeit
subplot(3, 1, 3)
plot(t, x(:, 2), 'g.-')
xlabel('Zeit t in s')
ylabel('Geschwindigkeit m/s')
xlim([0, t(end)])
grid on


%% Diskussion der Ergebnisse
disp('=== Diskussion der Ergebnisse ===')
disp(' ')
disp('1. Erste Bremsraketenzuendung:')
disp('   Bei t=3-8s erfolgt ein Bremspuls:')
disp('   - Beschleunigung: -10 m/s^2 (kurze Abbremsung)')
disp('   - Geschwindigkeit sinkt von 0 auf -60 m/s')
disp(' ')
disp('2. Hauptbremsphase 1:')
disp('   Bei t=14-17s erfolgt intensive Bremsung:')
disp('   - Beschleunigung: +10 m/s^2 (Raketen feuern)')
disp('   - Geschwindigkeit stabilisiert sich bei -20 m/s')
disp(' ')
disp('3. Hauptbremsphase 2:')
disp('   Bei t=27-30s zweite intensive Bremsung:')
disp('   - Beschleunigung: +10 m/s^2')
disp('   - Finale Landungsabbremsphase beginnt')
disp(' ')
disp('4. Finale Landung:')
disp('   Bei t=37-40s letzte Bremsung:')
disp('   - Beschleunigung: +10 m/s^2')
disp('   - Geschwindigkeit reduziert auf ~0 m/s')
disp('   - Sanfte Landung bei t~35s')




%% Testgroessen
% FIND Index fuer t=28s
[~, idx_28] = min(abs(t - 28));

h28 = x(idx_28, 1); % Hoehe bei t=28s in m
v28 = x(idx_28, 2); % Geschwindigkeit bei t=28s in m/s
a28 = x(idx_28, 3); % Beschleunigung bei t=28s in m/s^2

% FIND Zeitpunkt der Mondlandung (h ~ 0)
% Landung ist wenn Hoehe unter 1m faellt
idx_landung = find(x(:, 1) < 1, 1, 'first');
if ~isempty(idx_landung)
    tLandung = t(idx_landung); % Zeitpunkt der Mondlandung in s
else
    tLandung = t(end); % Falls keine Landung, nehme Endzeit
    disp('WARNUNG: Keine Landung erkannt (Hoehe > 1m am Ende)')
end

% OUTPUT Ergebnisse
disp('=== Kalman-Filter Schaetzungen ===')
disp(['Hoehe bei t=28s: ', num2str(h28), ' m'])
disp(['Geschwindigkeit bei t=28s: ', num2str(v28), ' m/s'])
disp(['Beschleunigung bei t=28s: ', num2str(a28), ' m/s^2'])
disp(['Zeitpunkt der Mondlandung: ', num2str(tLandung), ' s'])

%% Funktion: leseMesswerte
function [z, t] = leseMesswerte(nIndex)
    % leseMesswerte liest zyklisch Messwerte aus CSV-Datei
    % Input: nIndex - Zeilennummer (1 bis nMesswerte)
    % Output: z - Messvektor [Hoehe; Beschleunigung]
    %         t - Zeitstempel in s
    
    persistent Messdaten
    
    if isempty(Messdaten)
        % LOAD Messwerte einmalig beim ersten Aufruf
        Messdaten = load('Messdaten.csv');
        % Format: Spalte 1: Zeit [s]
        %         Spalte 2: Hoehe [m]
        %         Spalte 3: Beschleunigung [m/s^2]
        disp('Init leseMesswerte')
    end
    
    % EXTRACT Zeitstempel und Messwerte
    t = Messdaten(nIndex, 1); % Zeit in s
    z = [Messdaten(nIndex, 2); Messdaten(nIndex, 3)]; % Messvektor [h; a]
end

%% Funktion: KalmanFilter
function xEst = KalmanFilter(z)
    % KalmanFilter schaetzt Mondlandezustand (h, v, a)
    % Input: z - Messvektor [Hoehe; Beschleunigung] in [m; m/s^2]
    % Output: xEst - Zustandsvektor [h; v; a]
    
    persistent A H Q R dt
    persistent x P
    persistent bErsterDurchlauf
    
    %% INITIALIZE Variablen bei erstem Durchlauf
    if isempty(bErsterDurchlauf)
        % Abtastrate (konstant aus Messdaten)
        dt = 0.1; % 0.1s (aus Messdaten abgeleitet)
        
        % SETUP Systemmatrix (Konstante-Beschleunigungs-Modell)
        % Kinematik: h(k+1) = h(k) + v(k)*dt + 0.5*a(k)*dt^2
        %            v(k+1) = v(k) + a(k)*dt
        %            a(k+1) = a(k)
        A = [1, dt, 0.5 * dt^2;
             0, 1,  dt;
             0, 0,  1];
        
        % SETUP Systemrauschen-Kovarianz
        % Modelliert Unsicherheiten in der Kinematik (Raketenschubvariationen)
        % q = 0.5; % Basisrauschen (moderat, da Bremsraketen relativ stabil)
        Q = [dt^4 / 4, dt^3 / 2, dt^2 / 2;
                 dt^3 / 2, dt^2,     dt;
                 dt^2 / 2, dt,       1];
        
        % SETUP Messmatrix
        % Wir messen Hoehe (direkt) und Beschleunigung (direkt)
        H = [1, 0, 0;   % Hoehenmessung
             0, 0, 1];  % Beschleunigungsmessung
        
        % SETUP Messrauschen-Kovarianz
        % Hoehenmessung: Radar mit ca. 5m Unsicherheit
        % Beschleunigungsmessung: Accelerometer mit ca. 0.5 m/s^2 Unsicherheit
        R = diag([25, 0.25]); % [sigma_h^2, sigma_a^2] = [5^2, 0.5^2]
        
        % Initiale Zustandsschaetzung
        x = [z(1); 0; z(2)]; % [h0=Messwert, v0=0, a0=Messwert]
        
        % Initiale Fehlerkovarianzmatrix
        % Hohe Unsicherheit am Anfang
        P = diag([100, 50, 10]); % [sigma_h^2, sigma_v^2, sigma_a^2]
        
        bErsterDurchlauf = 1;
        disp('Init Kalman-Filter')

    end
    
    %% PREDICT Praediktion
    % Vorhersage des Zustandsvektors
    xp = A * x;
    
    % Vorhersage der Fehlerkovarianz
    Pp = A * P * A' + Q;
    
    %% UPDATE Schaetzung
    % Berechnung der Kalman-Verstaerkung
    K = Pp * H' * inv(H * Pp * H' + R);
    
    % Korrektur der Zustandsschaetzung
    x = xp + K * (z - H * xp);
    
    % Korrektur der Kovarianzschaetzung
    P = Pp - K * H * Pp;
    
    %% RETURN Rueckgabewerte
    xEst = x;
end

dt = 0.2;     % Abtastzeit in s
t  = 0:dt:10; % Zeitachse als Array

nSamples = length(t);

Xsaved = zeros(nSamples, 1);
Zsaved = zeros(nSamples, 1);
Sigma = zeros(2, nSamples); % Unsicherheit (obere/untere Grenze)

Psaved = zeros(nSamples, 1);

for k = 1:nSamples
  z        = LeseSpannung(k);  % Messwerte lesen
  [Spannung, PEst] = KalmanFilter(z); % Kalman-Filter anwenden
  
  % Messwerte speichern
    Xsaved(k) = Spannung;
    Zsaved(k) = z;
    Psaved(k) = PEst;
 % CALCULATE Unsicherheit der Schaetzung (1-Sigma-Intervall)
    Sigma(1, k) = Spannung + sqrt(PEst); % Obere Grenze
    Sigma(2, k) = Spannung - sqrt(PEst); % Untere Grenze
  
end

% SAVE Letzten Schaetzwert bei t=10s sichern (WICHTIG!)
Spannung = Xsaved(end);
PEst = Psaved(end);

hFigure=figure;
hold on
plot(t, Zsaved, 'r:.') 
plot(t, Xsaved, 'b.-')
plot(t, Sigma(1,:),'g-')
plot(t, Sigma(2,:),'g-')
yline(14.4,'Color',[0.5 0.5 0.5],'LineWidth',2)

% CONFIGURE Achsen und Legende
legend('Messwerte','Kalman-Filter Schätzung','Unsicherheit der Schätzung (1\sigma)')
xlabel('Zeit in s')
ylabel('Batteriespannung in V')
grid on % Aktiviert Gitter
hold off

% OUTPUT Ergebnisse
disp('Kalman-Filter Ergebnisse')
disp(['Endwert Schaetzung (Spannung): ', num2str(Spannung), ' V'])
disp(['Wahre Spannung: 14.4 V'])
disp(['Abweichung: ', num2str(abs(Spannung - 14.4)), ' V'])
disp(['Fehlerkovarianz (PEst): ', num2str(PEst), ' V^2'])
disp(['Endunsicherheit (1-Sigma): ±', num2str(sqrt(PEst)), ' V'])

%Kalman-Filter Funktion
function [Spannung, P] = KalmanFilter(z)

persistent A C Q R 
persistent x PEst
persistent bErsterDurchlauf

% INITIALIZE Variablen bei erstem Durchlauf
    if isempty(bErsterDurchlauf)
        % SYSTEMMATRIX der linearen Zustandsraumdarstellung
    A = 1;  % Konstantes Spannungsmodell 
    
    % AUSGANGSMATRIX der linearen Zustandsraumdarstellung
    C = 1;  % Spannung wird direkt gemessen
    
    % KOVARIANZMATRIX des Systemrauschens
    Q = 0.01;  % Erhöht (Faktor 10 gegenüber geringem Rauschen)
                % Grund: Einschwingvorgänge und Modellungenauigkeit
    
    % KOVARIANZMATRIX des Messrauschens
    R = 4.0;  % Deutlich erhöht (Faktor 4 gegenüber geringem Rauschen)
              % Grund: Höhere Messvarianz im Diagramm sichtbar
    
    % INITIALE SCHÄTZUNG in V
    x = 18.0;  % Erster Messwert
    
    % KOVARIANZMATRIX des Schätzfehlers
    PEst = 1.0;  % Hohe initiale Unsicherheit (Faktor 10)
               
        
        bErsterDurchlauf = 1; % Flag setzen
    end

    % PREDICT Praediktionsprozess
    % Vorhersage des Zustandsvektors und der Kovarianz
    xp = A * x; % Praediktion der Schaetzung (bleibt konstant)
    Pp = A * PEst * A' + Q; % Praediktion der Fehlerkovarianz

    % Update Kalman K Verst
    % Berechnung der Kalman-Verstaerkung K
    K = Pp * C' * inv(C * Pp * C' + R);
    % K bestimmt Gewichtung zwischen Praediktion und Messung
    
    % Korrektur der Zustandsschaetzung
    x = xp + K * (z - C * xp);
    % Korrigiert Praediktion basierend auf Messfehler
    
    % Korrektur der Kovarianzschaetzung
    PEst = Pp - K * C * Pp;
    % Reduziert Unsicherheit nach jeder Messung
    
    %RETURN Rueckgabewerte
    Spannung = x; % Aktuelle Zustandsschaetzung
    P = PEst; % Aktuelle Fehlerkovarianz
end
