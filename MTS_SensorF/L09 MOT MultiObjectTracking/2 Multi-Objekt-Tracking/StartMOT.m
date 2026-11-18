%% Multi-Objekt-Tracking für bunte Ballons
% Matrikelnummer: [das Matrikelnummer]
%
% Implementierung eines Multi-Objekt-Tracking-Systems mittels Kalman-Filter
% und Munkres-Zuordnungsalgorithmus

close all; clear all; clc;

%% Daten laden
load('Messdaten.mat')
v = VideoReader('BunteBallons.mp4');

global dt
dt = 1/v.FrameRate; % Wartezeit für die Pause

%% Parameter
nStartFrame = 1;
nEndFrame = v.NumFrames; % Letzter Frame
n = nEndFrame - nStartFrame + 1;

%% Initialisierung
XSaved = nan(n); % Ergebnisvektor, Zustandsschätzung
YSaved = nan(n);
x = nan(4, n); % Initiale Zustandsschätzung [x; y; vx; vy] für jeden Track
P = ones(4, 4) * 100; % Initiale Fehlerkovarianzmatrix
P = repmat(P, [1, 1, n]); % Für jeden Track eine eigene Kovarianzmatrix

nTracks = 0; % Anzahl aktiver Tracks

%% Hauptschleife
for nFrame = nStartFrame:nEndFrame
    %% Messwerte laden
    z = Position{nFrame};
    
    %% Kalman-Filter - Prädiktionsschritt
    [xp, Pp] = KalmanFilterPraediktion(z, x, P);
    
    %% Zuordnung
    aZuordnungen = Zuordnung(z, xp);
    
    %% Kalman Filter Zustandsschätzung
    [x, P] = KalmanFilterSchaetzung(aZuordnungen, z, xp, Pp, x, P);
    
    % disp(['x: ',num2str(find(isnan(x(1,:))==1,1)-1)])
    
    %% Zustandsvektor sichern
    nTracks = sum(~isnan(x(1, :)));
    XSaved(nFrame, 1:nTracks) = x(1, ~isnan(x(1, :)));
    YSaved(nFrame, 1:nTracks) = x(2, ~isnan(x(1, :)));
    
    %% Trackinitialisierung und -eliminierung
    x = aktualisiereTrackliste(aZuordnungen, z, x);
    
    %% Ergebnisdarstellung
    %% Videoframe darstellen
    frame = read(v, nFrame);
    imshow(frame)
    title(['Frame: ', num2str(nFrame)])
    hold on;
    
    %% Messwertdarstellung
    if ~isempty(Position{nFrame})
        plot(Position{nFrame}(:, 1), Position{nFrame}(:, 2), 'y*', 'MarkerSize', 10, 'LineWidth', 2)
    end
    
    %% Trackdarstellung
    nTracksActive = sum(~isnan(x(1, :)));
    for i = 1:nTracksActive
        if ~isnan(x(1, i))
            % Finde gültige Punkte für diesen Track
            validFrames = find(~isnan(XSaved(1:nFrame, i)));
            if length(validFrames) > 1
                % Zeichne Trajektorie mit zufälliger Farbe
                trackColor = rand(1, 3);
                plot(XSaved(validFrames, i), YSaved(validFrames, i), '-', ...
                    'LineWidth', 2, 'Color', trackColor);
                % Markiere aktuelle Position
                plot(x(1, i), x(2, i), 'o', 'MarkerSize', 8, ...
                    'MarkerFaceColor', trackColor, 'MarkerEdgeColor', 'w', 'LineWidth', 1.5);
            end
        end
    end
    
   hold off
   pause(dt) % Pause bis zum nächsten Frame
end


%% ========================================================================
%% FUNKTION 1: Kalman-Filter Prädiktion
%% ========================================================================
function [xp, Pp] = KalmanFilterPraediktion(z, x, P)
    % Prädiziert den Zustand für alle aktiven Tracks
    %
    % Eingabe:
    %   z  - Messungen [nMeas x 2] (wird hier nicht verwendet)
    %   x  - Zustandsvektoren [4 x nTracks]
    %   P  - Kovarianzmatrizen [4 x 4 x nTracks]
    %
    % Ausgabe:
    %   xp - Prädizierte Zustände [4 x nTracks]
    %   Pp - Prädizierte Kovarianzen [4 x 4 x nTracks]
    
    % Zeitschritt
    global dt
    if isempty(dt)
        dt = 1/30; % Standard-Framerate
    end
    
    % Systemmatrix (Konstante-Geschwindigkeit-Modell)
    A = [1, 0, dt, 0;
         0, 1, 0, dt;
         0, 0, 1,  0;
         0, 0, 0,  1];
    
    % Prozessrauschen-Kovarianzmatrix
    sigma_process = 5; % Prozessrauschen in Pixel
    Q = eye(4) * sigma_process^2;
    
    % Initialisiere Ausgabe
    xp = x;
    Pp = P;
    
    % Prädiziere jeden aktiven Track
    nTracks = size(x, 2);
    for i = 1:nTracks
        if ~isnan(x(1, i))
            % Zustandsprädiktion
            xp(:, i) = A * x(:, i);
            
            % Kovarianzprädiktion
            Pp(:, :, i) = A * P(:, :, i) * A' + Q;
        end
    end
end


%% ========================================================================
%% FUNKTION 2: Zuordnung mit Munkres-Algorithmus
%% ========================================================================
function aZuordnungen = Zuordnung(z, xp)
    % Ordnet Messungen zu Tracks mittels Munkres-Algorithmus zu
    %
    % Eingabe:
    %   z  - Messungen [nMeas x 2]
    %   xp - Prädizierte Zustände [4 x nTracks]
    %
    % Ausgabe:
    %   aZuordnungen - Zuordnungsvektor [nTracks x 1]
    %                  aZuordnungen(i) = j bedeutet: Track i ← Messung j
    %                  aZuordnungen(i) = 0 bedeutet: Track i ohne Messung
    
    % Anzahl Tracks bestimmen
    nTracks = sum(~isnan(xp(1, :)));
    
    % Initialisiere Zuordnungsvektor
    aZuordnungen = zeros(nTracks, 1);
    
    % Wenn keine Messungen vorhanden
    if isempty(z) || nTracks == 0
        return;
    end
    
    % Berechne Distanzmatrix [nTracks x nMeas]
    nMeas = size(z, 1);
    distMatrix = zeros(nTracks, nMeas);
    
    trackIdx = 0;
    for i = 1:size(xp, 2)
        if ~isnan(xp(1, i))
            trackIdx = trackIdx + 1;
            for j = 1:nMeas
                % Euklidische Distanz
                distMatrix(trackIdx, j) = sqrt((xp(1, i) - z(j, 1))^2 + ...
                                               (xp(2, i) - z(j, 2))^2);
            end
        end
    end
    
    % Gating: Setze zu große Distanzen auf Inf
    gateThreshold = 50; % Pixel
    distMatrix(distMatrix > gateThreshold) = inf;
    
    % Munkres-Algorithmus
    if any(isfinite(distMatrix(:)))
        [assignment, ~] = Munkres(distMatrix);
        aZuordnungen = assignment;
    end
end


%% ========================================================================
%% FUNKTION 3: Kalman-Filter Schätzung
%% ========================================================================
function [x, P] = KalmanFilterSchaetzung(aZuordnungen, z, xp, Pp, x, P)
    % Führt Kalman-Filter Update für zugeordnete Tracks durch
    %
    % Eingabe:
    %   aZuordnungen - Zuordnungsvektor [nTracks x 1]
    %   z            - Messungen [nMeas x 2]
    %   xp           - Prädizierte Zustände [4 x nTracks]
    %   Pp           - Prädizierte Kovarianzen [4 x 4 x nTracks]
    %   x            - Aktuelle Zustände [4 x nTracks]
    %   P            - Aktuelle Kovarianzen [4 x 4 x nTracks]
    %
    % Ausgabe:
    %   x - Aktualisierte Zustände [4 x nTracks]
    %   P - Aktualisierte Kovarianzen [4 x 4 x nTracks]
    
    % Messmatrix (nur Position wird gemessen)
    H = [1, 0, 0, 0;
         0, 1, 0, 0];
    
    % Messrauschen-Kovarianzmatrix
    sigma_meas = 10; % Messrauschen in Pixel
    R = eye(2) * sigma_meas^2;
    
    % Update für jeden Track
    trackIdx = 0;
    for i = 1:size(xp, 2)
        if ~isnan(xp(1, i))
            trackIdx = trackIdx + 1;
            
            if trackIdx <= length(aZuordnungen) && aZuordnungen(trackIdx) > 0
                % Track wurde Messung zugeordnet
                j = aZuordnungen(trackIdx);
                
                % Kalman-Update
                S = H * Pp(:, :, i) * H' + R;
                K = Pp(:, :, i) * H' / S;
                
                innovation = z(j, :)' - H * xp(:, i);
                x(:, i) = xp(:, i) + K * innovation;
                
                P(:, :, i) = (eye(4) - K * H) * Pp(:, :, i);
            else
                % Keine Messung: Prädiktion übernehmen
                x(:, i) = xp(:, i);
                P(:, :, i) = Pp(:, :, i);
            end
        end
    end
end


%% ========================================================================
%% FUNKTION 4: Track-Verwaltung
%% ========================================================================
function x = aktualisiereTrackliste(aZuordnungen, z, x)
    % Verwaltet Tracks: Initialisierung neuer und Eliminierung alter Tracks
    %
    % Eingabe:
    %   aZuordnungen - Zuordnungsvektor [nTracks x 1]
    %   z            - Messungen [nMeas x 2]
    %   x            - Zustände [4 x nTracks]
    %
    % Ausgabe:
    %   x - Aktualisierte Zustände [4 x nTracks]
    
    persistent trackAge trackMissed
    
    % Initialisierung beim ersten Aufruf
    if isempty(trackAge)
        trackAge = zeros(1, size(x, 2));
        trackMissed = zeros(1, size(x, 2));
    end
    
    % Stelle sicher, dass Vektoren gleich lang sind
    if length(trackAge) < size(x, 2)
        trackAge(end+1:size(x, 2)) = 0;
        trackMissed(end+1:size(x, 2)) = 0;
    end
    
    %% Update Track-Statistiken
    nTracks = sum(~isnan(x(1, :)));
    
    trackIdx = 0;
    for i = 1:size(x, 2)
        if ~isnan(x(1, i))
            trackIdx = trackIdx + 1;
            trackAge(i) = trackAge(i) + 1;
            
            if trackIdx <= length(aZuordnungen) && aZuordnungen(trackIdx) > 0
                % Track wurde Messung zugeordnet
                trackMissed(i) = 0;
            else
                % Track ohne Messung
                trackMissed(i) = trackMissed(i) + 1;
            end
        end
    end
    
    %% Eliminiere verlorene Tracks
    maxMissedFrames = 10;
    
    for i = 1:size(x, 2)
        if ~isnan(x(1, i)) && trackMissed(i) > maxMissedFrames
            % Lösche Track
            x(:, i) = NaN;
            trackAge(i) = 0;
            trackMissed(i) = 0;
        end
    end
    
    %% Initialisiere neue Tracks
    if ~isempty(z)
        % Finde nicht-zugeordnete Messungen
        assignedMeasurements = aZuordnungen(aZuordnungen > 0);
        
        for j = 1:size(z, 1)
            if ~ismember(j, assignedMeasurements)
                % Finde freien Platz für neuen Track
                freeSlot = find(isnan(x(1, :)), 1);
                
                if ~isempty(freeSlot)
                    % Initialisiere neuen Track
                    x(:, freeSlot) = [z(j, 1); z(j, 2); 0; 0];
                    trackAge(freeSlot) = 1;
                    trackMissed(freeSlot) = 0;
                else
                    % Erweitere Array wenn kein Platz
                    x(:, end+1) = [z(j, 1); z(j, 2); 0; 0];
                    trackAge(end+1) = 1;
                    trackMissed(end+1) = 0;
                end
            end
        end
    end
end