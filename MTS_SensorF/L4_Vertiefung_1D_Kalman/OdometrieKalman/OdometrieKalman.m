%% Kalman-Filter fuer Odometriedaten - Fahrzeugbeschleunigung
% Schritt: Schaetzung des Fahrzeugzustands (Position, Geschwindigkeit, Beschleunigung)
% basierend auf verrauschten Odometrie-Streckenmessungen
% Zustandsvektor: x = [s; v; a] (Strecke, Geschwindigkeit, Beschleunigung)

%% Initialisierung
nStartFrame = 1; % Startframe
nEndFrame = 1545; % Endframe (Gesamtanzahl Messungen)
tAlt = 0; % Vorheriger Zeitstempel

% ALLOCATE Speicherplatz fuer Ergebnisvektoren
Zeit = zeros(nEndFrame, 1); % Zeitstem pel
Strecke = zeros(nEndFrame, 1); % Streckenmessungen
Zustandsvektor = zeros(nEndFrame, 3); % Klassisches Filter
Zustandsvektor2 = zeros(nEndFrame, 3); % Kalman-Filter
aKovarianzMatrix = cell(nEndFrame, 1); % Kovarianzmatrizen

%% Zyklusschleife
% FOR jede Messung
for k = nStartFrame:nEndFrame
    %% Messdaten laden
    z = LadeMessdaten(k); % z = [Zeitstempel, Strecke]
    
    %% Klassisches Filter ausfuehren
    x = KlassischesFilter(z);
    
    %% Kalman Filter ausfuehren
    dt = z(1) - tAlt; % Zeitschritt berechnen (nicht konstant!)
    [X, P] = KalmanFilter(z(2), dt);
    
    %% Daten fuer die Darstellung speichern
    Zeit(k) = z(1);
    Strecke(k) = z(2);
    Zustandsvektor(k, :) = x;
    Zustandsvektor2(k, :) = X;
    aKovarianzMatrix{k} = P;
    
    tAlt = z(1); % Zeitstempel aktualisieren
end

%% Filterergebnis darstellen
figure;
ZeigeMessdaten(Zeit, Strecke, Zustandsvektor, Zustandsvektor2);

%% Ergebnisauswertung
% EXTRACT Werte aus dem Zustandsvektor
s1 = Zustandsvektor2(end, 1); % Max. gefahrene Strecke (letzter Wert)
sigma_s1 = sqrt(aKovarianzMatrix{end}(1, 1)); % Standardabweichung Strecke

% FIND Index der Maximalgeschwindigkeit
[v1, nIndex] = max(Zustandsvektor2(:, 2));
sigma_v1 = sqrt(aKovarianzMatrix{nIndex}(2, 2)); % Standardabweichung v1

% CALCULATE Startzeit und Endzeit
t1 = 10.3; % Startzeit
t2 = 14.7; % Endzeit

% FIND Indizes für Zeitfenster
k1 = find(Zeit >= t1, 1, 'first'); % Erster Index >= 10.3s
k2 = find(Zeit >= t1 + 2, 1, 'first'); % Zeitfenster ca. 2s
k3 = find(Zeit >= t2, 1, 'first'); % Erster Index >= 14.7s
k4 = find(Zeit >= t2 + 2, 1, 'first'); % Zeitfenster ca. 2s

% Fallback falls k2/k4 leer
if isempty(k2), k2 = min(k1 + 100, nEndFrame); end
if isempty(k4), k4 = nEndFrame; end

% EXTRACT Beschleunigungen für die Endzeit
a1 = mean(Zustandsvektor2(k1:k2, 3)); % Beschleunigung beim Start
a2 = mean(Zustandsvektor2(k3:k4, 3)); % Beschleunigung am Ende

% Initialize variables for standard deviation calculations
pa = zeros(nEndFrame, 1);
pa2 = zeros(nEndFrame, 1);
j = 0;

% Calculate standard deviation for a1
% CALCULATE Standardabweichungen
j = 0;
pa = zeros(k2 - k1 + 1, 1);
for i = k1:k2
    j = j + 1;
    pa(j) = aKovarianzMatrix{i}(3, 3);
end
sigma_a1 = sqrt(mean(pa(1:j)));

j = 0;
pa2 = zeros(k4 - k3 + 1, 1);
for i = k3:k4
    j = j + 1;
    pa2(j) = aKovarianzMatrix{i}(3, 3);
end
sigma_a2 = sqrt(mean(pa2(1:j))); % FIX: (1:j) statt ganzes Array




%% Kalman-Filter Funktion
function [Zustandsvektor, Kovarianz] = KalmanFilter(z, dt)
    % KalmanFilter schaetzt Fahrzeugzustand (s, v, a)
    % Input: z - Streckenmessung in m
    %        dt - Zeitschritt in s (nicht konstant!)
    % Output: Zustandsvektor - [s; v; a]
    %         Kovarianz - Fehlerkovarianzmatrix P
    
    persistent x P bErsterDurchlauf
    
    %% INITIALIZE Variablen bei erstem Durchlauf
    if isempty(bErsterDurchlauf)
        
        % Initiale Zustandsschaetzung
        x = [0; 0; 0]; % [s0=0m, v0=0m/s, a0=0m/s^2]
        
        % Initiale Fehlerkovarianzmatrix
        P = diag([100, 10, 1]); % Hohe Unsicherheit am Anfang
        
        bErsterDurchlauf = 1;
        disp('INIT Kalman-Filter fuer Odometrie')
    end
    
    % SETUP Systemmatrix (zeitabhaengig wegen dt!)
    % Kinematisches Modell: s(t) = s0 + v0*dt + 0.5*a*dt^2
    %                        v(t) = v0 + a*dt
    %                        a(t) = a (konstant)
    A = [1, dt, 0.5 * dt^2;
         0, 1,  dt;
         0, 0,  1];
    
    % Systemrauschen-Kovarianz (Prozessunsicherheit)
    % Modelliert Unsicherheiten in der Kinematik
    q = 0.1; % Basisrauschen
    Q = q*[dt^4 / 4, dt^3 / 2, dt^2 / 2;
             dt^3 / 2, dt^2,     dt;
             dt^2 / 2, dt,       1];
    
    % Messmatrix (konstant)
    H = [1, 0, 0];
    
    % Messrauschen (konstant)
    R = 0.01;
    
    %% PREDICT Praediktionsprozess
    % Vorhersage des Zustandsvektors
    xp = A * x;
    
    % Vorhersage der Fehlerkovarianz
    Pp = A * P * A' + Q;
    
    %% UPDATE Schaetzprozess
    % Berechnung der Kalman-Verstaerkung
    K = Pp * H' * inv(H * Pp * H' + R);
    
    % Korrektur der Zustandsschaetzung
    if ~isnan(z)
        % Normale Messung vorhanden
        x = xp + K * (z - H * xp);
    else
        % Keine Messung (NaN) -> nur Praediktion
        x = xp;
    end
    
    % Korrektur der Kovarianzschaetzung
    P = Pp - K * H * Pp;
    
    %% RETURN Rueckgabewerte
    Zustandsvektor = x;
    Kovarianz = P;
end
