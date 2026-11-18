% Verfolgung eines blauen Ballons mittels Kalman-Filter - Schätzung der Geschwindigkeit (vx, vy) - Beschleunigungs-Null-Modell - Behandlung fehlender Messwerte (NaN)

clear all; clc; close all;
clear KalmanFilter;
clear xEst

global bInitFilter
bInitFilter = false;

fprintf('=== BALLONVERFOLGUNG MIT KALMAN-FILTER ===\n\n');

%% MESSDATEN UND VIDEO LADEN
stMessdatum = 'MessdatenB.mat';
load(stMessdatum); % Messdaten laden

vHandle = VideoReader('BunteBallons.mp4'); % Video laden
dt = 1 / vHandle.FrameRate; % dt aus FrameRate berechnen

%% FRAME-BEREICH DEFINIEREN

nStartFrame = 47;
nEndFrame = 230;

fprintf('Frame-Bereich: %d bis %d\n\n', nStartFrame, nEndFrame);

%% INITIALISIERUNG

xEst = NaN(4, size(BallonXY, 1));  % 4x230 Matrix
Zeit = zeros(1, size(BallonXY, 1));

fprintf('Kalman-Filter wird initialisiert...\n\n');
fprintf('%-7s | %-15s | %-15s | %-12s | %-12s\n', 'Frame', 'Messung [x,y]', 'Schätzung [x,y]', 'vx [px/s]', 'vy [px/s]');
fprintf('%s\n', repmat('-', 1, 85));

%% HAUPTSCHLEIFE
for i = nStartFrame:nEndFrame
    % Messdaten laden
    z = BallonXY(i, :)'; % als Spaltenvektor
    
    % Kalman-Filter
    xEst(:, i) = KalmanFilter(z, dt);
    
    % Zeitachse
    Zeit(i) = (i - nStartFrame) * dt; % Zeit in Sekunden
    
    %% VIDEOFRAME DARSTELLEN
    frame = read(vHandle, i);
    imshow(frame)
    title(['Frame: ', num2str(i)])
    hold on;
    
    %% MESSWERTDARSTELLUNG
    if ~any(isnan(z))
        plot(z(1), z(2), 'r*', 'MarkerSize', 12, 'LineWidth', 2)
    end
    
    %% ERGEBNISDARSTELLUNG
    if ~any(isnan(xEst(:, i)))
        plot(xEst(1, i), xEst(2, i), 'bo', 'MarkerSize', 10, 'LineWidth', 2)
    end
    
    hold off
    
    %% PAUSE BIS ZUM NAECHSTEN FRAME
     pause(dt) % Schnelle Darstellung ohne Blockierung
end

%% ERGEBNIS
% Mittlere Geschwindigkeit vy berechnen
validIdx = ~isnan(xEst(4, :));
vyBallon = mean(xEst(4, validIdx)); % Pixel/s
fprintf('Mittlere Geschwindigkeit vy: %.2f Pixel/s\n', vyBallon);



%% GESCHWINDIGKEITSVERLAUF PLOTTEN

figure('Position', [100, 100, 1200, 600]);

subplot(2, 1, 1)
plot(Zeit(validIdx), xEst(3, validIdx), 'b-', 'LineWidth', 2)
grid on
xlabel('Zeit [s]', 'FontSize', 12)
ylabel('v_x [Pixel/s]', 'FontSize', 12)
title('Geschwindigkeit in x-Richtung', 'FontSize', 14, 'FontWeight', 'bold')

subplot(2, 1, 2)
plot(Zeit(validIdx), xEst(4, validIdx), 'r-', 'LineWidth', 2)
grid on
xlabel('Zeit [s]', 'FontSize', 12)
ylabel('v_y [Pixel/s]', 'FontSize', 12)
title('Geschwindigkeit in y-Richtung', 'FontSize', 14, 'FontWeight', 'bold')


%% ========================================================================
%% KALMAN-FILTER FUNKTION
%% ========================================================================

function xEst = KalmanFilter(z, dt)
%**************************************************************************
% KALMANFILTER 2D-Kalman-Filter für Ballonverfolgung
%
% SYNTAX:
%   xEst = KalmanFilter(z, dt)
%
% BESCHREIBUNG:
%   Mit jedem Aufruf wird ein rekursives Kalman-Filter ausgeführt.
%   Alle internen Variablen werden persistent im Speicher gehalten.
%   Die Einheiten der Ausgangsgrößen entsprechen denen der Eingangsgrößen.
%
%   SYSTEMMODELL (Beschleunigungs-Null-Modell):
%   x(k+1) = A * x(k) + w(k)
%
%   MESSMODELL:
%   z(k) = H * x(k) + v(k)
%
% EINGABEWERTE:
%   z:  Aktueller Messvektor [x; y] (2x1) in Pixel
%   dt: Zykluszeit in s
%
% RÜCKGABEWERTE:
%   xEst: Zustandsschätzung [x; y; vx; vy] (4x1)
%         x, y: Position in Pixel
%         vx, vy: Geschwindigkeit in Pixel/s
%
% BEISPIEL:
%   x = KalmanFilter([300; 200], 0.033);
%**************************************************************************

persistent A H Q R
persistent x P
global bInitFilter

%% INITIALISIERUNG BEI ERSTEM GÜLTIGEN MESSWERT

if ((bInitFilter == false) && (sum(~isnan(z)) > 0))
    

    % SYSTEMMATRIX A (4x4)
    A = [1  0  dt  0;   % x
         0  1  0   dt;  % y
         0  0  1   0;   % vx
         0  0  0   1];  % vy
    

    % MESSMATRIX H (2x4)
    % Wir messen nur Position (x, y), nicht Geschwindigkeit
     H = [1 0 0 0;       % Messung x
         0 1 0 0];      % Messung y
    

    % PROZESSRAUSCHKOVARIANZ Q (4x4)
    % Modelliert Unsicherheit im Systemmodell
    % Annahme: Ballon kann leicht beschleunigen (Windstöße)
        
    fSystemRauschen = 0.1; % Systemrauschen in Pixel/s^2  % Prozessrauschen in Pixel/s^2

        Q = [
        dt^4/4,  0,       dt^3/2,  0;       % x
        0,       dt^4/4,  0,       dt^3/2;  % y
        dt^3/2,  0,       dt^2,    0;       % vx
        0,       dt^3/2,  0,       dt^2     % vy
    ]* fSystemRauschen^2;
    

    % MESSRAUSCHKOVARIANZ R (2x2)
    % Modelliert Unsicherheit der Bildverarbeitung
    
     fMessrauschen = 10; % Messrauschen in Pixel
   R = fMessrauschen^2 * eye(2); % R = [100, 0; 0, 100]
    

    % INITIALER ZUSTANDSVEKTOR x0
    % Initiale Position aus erster gültiger Messung
    % Initiale Geschwindigkeit: Annahme 0 (wird schnell geschätzt)
    
    x = [z(1);    % x-Position
         z(2);    % y-Position
         0;       % vx (unbekannt)
         0];    % vy (Annahme: Ballon steigt mit ca. -30 Pixel/s)!!!
    

    % INITIALE FEHLERKOVARIANZMATRIX P0
    % Große Unsicherheit in Geschwindigkeit, kleine in Position
    
  P = diag([0.1, 0.1, 10, 10]);

    fprintf('Kalman-Filter initialisiert bei Frame mit z = [%.1f, %.1f]\n\n', z(1), z(2));
    
    bInitFilter = true;
    xEst = x;
    return;
end

%% WENN FILTER NOCH NICHT INITIALISIERT: NaN ZURÜCKGEBEN

if (bInitFilter == false)
    xEst = [NaN; NaN; NaN; NaN];
    return;
end

%% PRÄDIKTIONSSCHRITT (PREDICTION)
xp = A * x;
Pp = A * P * A' + Q;


%% KORREKTURSCHRITT
K = Pp * H' / (H * Pp * H' + R);

% Zustandskorrektur
if ~any(isnan(z))
    x = xp + K * (z - H * xp);
    P = Pp - K * H * Pp;
else
    % Keine Messung verfuegbar: Nur Praediktion
    x = xp;
    P = Pp;
end

%% RUECKGABEWERTE
xEst = x;
end

