% Schätze Fahrspurpolynom p(x) = a2*x² + a1*x + a0 mit Kalman-Filter aus verrauschten Spurkandidaten
clear all; clc; close all;
%% MESSDATEN LADEN

% Lade Messvektor.mat
% z: Matrix [nFrames x 5] mit Messwerten
% z(k,:) = [p, xStart, yStart, xEnde, yEnde]
%   p: Dummy-Wert (wird nicht verwendet, Spalte 1)
%   xStart, yStart: Startpunkt der Spur [Pixel]
%   xEnde, yEnde: Endpunkt der Spur [Pixel]
load('Messvektor.mat');

fprintf('========== LANE-TRACKING MIT KALMAN-FILTER ==========\n\n');
fprintf('Messdaten geladen: %d Frames\n', size(z, 1));
fprintf('Messvektor-Format: [p, xStart, yStart, xEnde, yEnde]\n\n');

%% Eingangsgrößen: PARAMETER DEFINIEREN

% dt - Zykluszeit zwischen Frames [s]
% Eingangsgrößen: dt = 1/15 s (15 fps)
dt = 1/15;  % [s]

fprintf('Zykluszeit dt: %.4f s (FrameRate: %.2f fps)\n\n', dt, 1/dt);

%% INITIALISIERUNG DER VARIABLEN

% nFrames - Anzahl der Frames (Messungen)
nFrames = size(z, 1);

% Zustandsvektor-Matrix - Speichert geschätzte Zustände für alle Frames
% Dimension: [7 x nFrames]
% Zeile 1: a2 (Koeffizient x²)
% Zeile 2: a1 (Koeffizient x)
% Zeile 3: a0 (Konstante)
% Zeile 4: xStart [Pixel]
% Zeile 5: yStart [Pixel]
% Zeile 6: xEnde [Pixel]
% Zeile 7: yEnde [Pixel]
xEst_all = zeros(7, nFrames);

%% HAUPTSCHLEIFE: KALMAN-FILTER ANWENDEN

fprintf('========== KALMAN-FILTER VERARBEITUNG ==========\n\n');

% k - Frame-Index (Schleifenvariable)
for k = 1:nFrames
    
    % Messvektor für Frame k extrahieren [5x1]
    % z(k,:)' → Transponiere Zeile k zu Spaltenvektor
    % Format: [p; xStart; yStart; xEnde; yEnde]
    zMess = z(k, :)';  % [5x1] Spaltenvektor
    
    % Kalman-Filter anwenden
    % KalmanFilter(z): Rekursive Funktion
    % Eingabe: zMess [5x1]
    % Ausgabe: xEst [7x1] = [a2; a1; a0; xStart; yStart; xEnde; yEnde]
    xEst = KalmanFilter(zMess);
    
    % Zustandsvektor in Matrix speichern
    xEst_all(:, k) = xEst;
    
    %% ERGEBNISDARSTELLUNG FÜR FRAMES 40, 160, 350
    
    % Prüfe ob aktueller Frame einer der Referenz-Frames ist
    if ismember(k, [40, 160, 350])
        
        fprintf('---------- Frame %d ----------\n', k);
        
        % Extrahiere geschätzte Polynom-Koeffizienten
        a2 = xEst(1);  % Koeffizient x²
        a1 = xEst(2);  % Koeffizient x
        a0 = xEst(3);  % Konstante
        
        fprintf('Geschätzte Polynom-Koeffizienten:\n');
        fprintf('  a2 = %.6e\n', a2);
        fprintf('  a1 = %.6e\n', a1);
        fprintf('  a0 = %.6e\n\n', a0);
        
        %% VISUALISIERUNG
        
        % Erstelle Figure für diesen Frame
        figure('Name', sprintf('Frame %d', k), 'Position', [100, 100, 800, 600]);
        
        % Schwarzer Hintergrund (wie in Abb. 1-3)
        set(gcf, 'Color', 'k');
        axes('Color', 'k', 'XColor', 'w', 'YColor', 'w');
        hold on;
        
        %% Gemessene Spur in GELB zeichnen
        
        % Extrahiere Messpunkte aus zMess
        xStart_mess = zMess(2);  % X-Koordinate Startpunkt [Pixel]
        yStart_mess = zMess(3);  % Y-Koordinate Startpunkt [Pixel]
        xEnde_mess = zMess(4);   % X-Koordinate Endpunkt [Pixel]
        yEnde_mess = zMess(5);   % Y-Koordinate Endpunkt [Pixel]
        
        % Zeichne gemessene Linie (Start → Ende) in GELB
        % Gestrichelte Linie '--' für Messwerte
        plot([xStart_mess, xEnde_mess], [yStart_mess, yEnde_mess], ...
            'y--', 'LineWidth', 2, 'DisplayName', 'Messwert (Gelb)');
        
        %% Geschätzte Spur in MAGENTA zeichnen
        
        % Extrahiere geschätzte Start- und Endpunkte
        xStart_est = xEst(4);  % X-Koordinate Startpunkt (geschätzt) [Pixel]
        yStart_est = xEst(5);  % Y-Koordinate Startpunkt (geschätzt) [Pixel]
        xEnde_est = xEst(6);   % X-Koordinate Endpunkt (geschätzt) [Pixel]
        yEnde_est = xEst(7);   % Y-Koordinate Endpunkt (geschätzt) [Pixel]
        
        % Berechne Polynom-Kurve für x-Werte zwischen xStart und xEnde
        % Erstelle 100 Punkte für glatte Kurve
        xPolynom = linspace(xStart_est, xEnde_est, 100);  % X-Werte [Pixel]
        
        % Berechne Y-Werte mit Polynom p(x) = a2*x² + a1*x + a0
        yPolynom = a2 * xPolynom.^2 + a1 * xPolynom + a0;  % Y-Werte [Pixel]
        
        % Zeichne geschätzte Polynom-Kurve in MAGENTA
        % Durchgezogene Linie '-' für Kalman-Schätzung
        plot(xPolynom, yPolynom, 'm-', 'LineWidth', 3, ...
            'DisplayName', 'Kalman-Schätzung (Magenta)');
        
        %% MARKIERUNGEN SETZEN
        
        % Markiere gemessene Punkte als gelbe Sterne
        plot(xStart_mess, yStart_mess, 'y*', 'MarkerSize', 12, ...
            'LineWidth', 2, 'HandleVisibility', 'off');
        plot(xEnde_mess, yEnde_mess, 'y*', 'MarkerSize', 12, ...
            'LineWidth', 2, 'HandleVisibility', 'off');
        
        % Markiere geschätzte Punkte als magenta Kreise
        plot(xStart_est, yStart_est, 'mo', 'MarkerSize', 10, ...
            'LineWidth', 2, 'HandleVisibility', 'off');
        plot(xEnde_est, yEnde_est, 'mo', 'MarkerSize', 10, ...
            'LineWidth', 2, 'HandleVisibility', 'off');
        
        %% Plot-Formatierung
        
        xlabel('X [Pixel]', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'w');
        ylabel('Y [Pixel]', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'w');
        title(sprintf('Frame %d: Lane-Tracking', k), ...
            'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');
        
        % Achsen anpassen (Y-Achse invertiert für Bildkoordinaten)
        axis([0 450 0 550]);
        set(gca, 'YDir', 'reverse');  % Y-Achse nach unten
        grid on;
        legend('Location', 'best', 'TextColor', 'w', 'Color', 'k');
        
        hold off;
        
        fprintf('Figure erstellt für Frame %d\n\n', k);
    end
end

fprintf('========== VERARBEITUNG ABGESCHLOSSEN ==========\n\n');

%% ZUSÄTZLICHE AUSWERTUNG - Polynom-Koeffizienten über Zeit

figure('Name', 'Polynom-Koeffizienten über Zeit', 'Position', [100, 100, 1200, 800]);

% Subplot 1: Koeffizient a2 über Zeit
subplot(3, 1, 1);
plot(1:nFrames, xEst_all(1, :), 'b-', 'LineWidth', 1.5);
xlabel('Frame-Nummer', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('a_2 (x²-Koeffizient)', 'FontSize', 11, 'FontWeight', 'bold');
title('Koeffizient a_2 über Zeit', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% Subplot 2: Koeffizient a1 über Zeit
subplot(3, 1, 2);
plot(1:nFrames, xEst_all(2, :), 'r-', 'LineWidth', 1.5);
xlabel('Frame-Nummer', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('a_1 (x-Koeffizient)', 'FontSize', 11, 'FontWeight', 'bold');
title('Koeffizient a_1 über Zeit', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% Subplot 3: Koeffizient a0 über Zeit
subplot(3, 1, 3);
plot(1:nFrames, xEst_all(3, :), 'g-', 'LineWidth', 1.5);
xlabel('Frame-Nummer', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('a_0 (Konstante)', 'FontSize', 11, 'FontWeight', 'bold');
title('Koeffizient a_0 über Zeit', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

sgtitle('Polynom-Koeffizienten: Zeitlicher Verlauf', 'FontSize', 14, 'FontWeight', 'bold');

%% ===================================================
%% FUNKTION - KalmanFilter(z)
%% ===================================================
% Rekursive Kalman-Filter-Funktion für Lane-Tracking
%
% EINGABE:
%   z - Messvektor [5x1]: [p; xStart; yStart; xEnde; yEnde]
%       p: Dummy (nicht verwendet)
%       xStart, yStart: Startpunkt der Spur [Pixel]
%       xEnde, yEnde: Endpunkt der Spur [Pixel]
%
% AUSGABE:
%   Zustandsvektor - Geschätzter Zustand [7x1]:
%       [a2; a1; a0; xStart; yStart; xEnde; yEnde]
%       a2, a1, a0: Polynom-Koeffizienten
%       xStart, yStart, xEnde, yEnde: Geschätzte Spurpunkte [Pixel]
%
% MODELL:
%   Zustandsgleichung: x(k+1) = A * x(k) + w
%   Messgleichung:     z(k)   = H * x(k) + v
%   Beschleunigungs-Null-Modell (Konstante Parameter)
%% ===================================================

function [Zustandsvektor] = KalmanFilter(z)

%% PERSISTENT VARIABLES - Zwischen Funktionsaufrufen gespeichert

% A - Systemmatrix [7x7] - Beschreibt Zustandsübergang
% H - Messmatrix [4x7] - Extrahiert messbare Größen
% Q - Prozessrausch-Kovarianzmatrix [7x7]
% R - Messrausch-Kovarianzmatrix [4x4]
persistent A H Q R

% x - Zustandsvektor [7x1]
% P - Fehlerkovarianzmatrix [7x7]
persistent x P

% bInitialized - Initialisierungsflag
persistent bInitialized

%% INITIALISIERUNG (nur beim ersten Aufruf)

if isempty(bInitialized)
    
    fprintf('INFO: Kalman-Filter wird initialisiert\n\n');
    
    %% PARAMETER DEFINIEREN
    
    %% Systemmatrix A [7x7]
    % Beschreibt zeitdiskretes Constant-Parameter-Modell
    % Annahme: Polynom-Koeffizienten und Spurpunkte ändern sich langsam
    % x(k+1) = x(k) → Identitätsmatrix
    % a2(k+1) = a2(k), a1(k+1) = a1(k), a0(k+1) = a0(k)
    % xStart(k+1) = xStart(k), yStart(k+1) = yStart(k), ...
    
    A = eye(7);  % [7x7] Identitätsmatrix (keine Änderung erwartet)
    
    %% Messmatrix H [4x7]
    % Extrahiert messbare Größen aus Zustandsvektor
    % Messgleichung: z(k) = H * x(k) + v
    % Wir messen NUR die Spurpunkte (xStart, yStart, xEnde, yEnde)
    % NICHT die Polynom-Koeffizienten (a2, a1, a0)
    % z = [xStart; yStart; xEnde; yEnde] → Elemente 4, 5, 6, 7 aus x
    
    H = zeros(4, 7);
    H(1, 4) = 1;  % Messung xStart: Nimm Element 4 aus x
    H(2, 5) = 1;  % Messung yStart: Nimm Element 5 aus x
    H(3, 6) = 1;  % Messung xEnde: Nimm Element 6 aus x
    H(4, 7) = 1;  % Messung yEnde: Nimm Element 7 aus x
    
    %% Prozessrausch-Kovarianzmatrix Q [7x7]
    % Modelliert Unsicherheit in der Zustandsentwicklung
    % Kleine Werte für langsam veränderliche Polynom-Koeffizienten
    % Etwas größere Werte für Spurpunkte (variieren stärker)
    
    Q = diag([1e-6, 1e-5, 1e-3, 0.5, 0.5, 0.5, 0.5]);
    % Q(1,1): Unsicherheit a2 (x²-Koeffizient) - sehr klein
    % Q(2,2): Unsicherheit a1 (x-Koeffizient) - sehr klein
    % Q(3,3): Unsicherheit a0 (Konstante) - klein
    % Q(4,4) bis Q(7,7): Unsicherheit Spurpunkte - moderat
    
    %% Messrausch-Kovarianzmatrix R [4x4]
    % Modelliert Unsicherheit der Bildverarbeitungs-Detektion
    % Typischerweise ±10 Pixel Standardabweichung
    
    dSigma_mess = 10;  % [Pixel] Messrauschen
    R = dSigma_mess^2 * eye(4);  % [4x4] Diagonalmatrix
    
    %% Initialer Zustandsvektor x [7x1]
    % Starte mit erster Messung und groben Polynom-Schätzungen
    
    % Extrahiere Spurpunkte aus erster Messung
    xStart_0 = z(2);  % X-Koordinate Startpunkt [Pixel]
    yStart_0 = z(3);  % Y-Koordinate Startpunkt [Pixel]
    xEnde_0 = z(4);   % X-Koordinate Endpunkt [Pixel]
    yEnde_0 = z(5);   % Y-Koordinate Endpunkt [Pixel]
    
    % Grobe Polynom-Schätzung aus erster Messung
    % Annahme: Gerade Linie → a2 ≈ 0, a1 = Steigung, a0 = y-Achsenabschnitt
    % Steigung: a1 = Δy / Δx
    if abs(xEnde_0 - xStart_0) > 1e-6
        a1_0 = (yEnde_0 - yStart_0) / (xEnde_0 - xStart_0);
    else
        a1_0 = 0;
    end
    
    % Y-Achsenabschnitt: a0 = y - a1*x (mit Startpunkt)
    a0_0 = yStart_0 - a1_0 * xStart_0;
    
    % a2 initial = 0 (nehme gerade Linie an)
    a2_0 = 0;
    
    % Initialer Zustandsvektor
    x = [a2_0; a1_0; a0_0; xStart_0; yStart_0; xEnde_0; yEnde_0];
    
    %% Initiale Fehlerkovarianzmatrix P [7x7]
    % Große Unsicherheit beim Start
    
    P = diag([1e-3, 0.1, 100, 100, 100, 100, 100]);
    % P(1,1): Unsicherheit a2 - moderat
    % P(2,2): Unsicherheit a1 - moderat
    % P(3,3): Unsicherheit a0 - groß
    % P(4,4) bis P(7,7): Unsicherheit Spurpunkte - groß
    
    % Setze Flag
    bInitialized = true;
    
    % Rückgabe des Initialzustands
    Zustandsvektor = x;
    return;
end

%% KALMAN-FILTER REKURSION

%% PREDICTION-SCHRITT (Time Update)

% Zustandsprädiktion: x̂(k|k-1) = A * x̂(k-1|k-1)
xp = A * x;  % [7x1] = [7x7] * [7x1]

% Kovarianzprädiktion: P(k|k-1) = A * P(k-1|k-1) * A^T + Q
Pp = A * P * A' + Q;  % [7x7]

%% UPDATE-SCHRITT (Measurement Update)

% Extrahiere messbare Größen aus Messvektor z
% z = [p; xStart; yStart; xEnde; yEnde]
% Wir verwenden nur xStart, yStart, xEnde, yEnde (Spalten 2-5)
zMeasured = z(2:5);  % [4x1] Spaltenvektor

% Innovationskovarianz S [4x4]
% S = H * P * H^T + R
S = H * Pp * H' + R;  % [4x4]

% Kalman-Gain K [7x4]
% K = P * H^T * S^(-1)
K = Pp * H' / S;  % [7x4] = [7x7]*[7x4] / [4x4]

% Innovation (Residuum) y [4x1]
% y = z - H * x̂(k|k-1)
innovation = zMeasured - H * xp;  % [4x1]

% Zustand aktualisieren [7x1]
% x̂(k|k) = x̂(k|k-1) + K * innovation
x = xp + K * innovation;  % [7x1]

% Fehlerkovarianz aktualisieren [7x7]
% P(k|k) = (I - K*H) * P(k|k-1)
P = (eye(7) - K * H) * Pp;  % [7x7]

%% Rückgabe des geschätzten Zustands

% Zustandsvektor [7x1]
% Format: [a2; a1; a0; xStart; yStart; xEnde; yEnde]
Zustandsvektor = x;

end  % Ende der Funktion KalmanFilter
