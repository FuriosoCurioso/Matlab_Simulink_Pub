% Rotation eines Binärbildes um Bildmittelpunkt
clear all; close all;clc
%% Initialisierung

%% Eingangsgrößen: - Rotationswinkel
% fWinkel = 90° nach links (Gegenuhrzeigersinn)
%% Eingangsgrößen: - Rotationswinkel fWinkel
% fWinkel: Rotationswinkel in Grad
% -90° = 90° nach links (Gegenuhrzeigersinn/mathematisch positiv)
% Negatives Vorzeichen wegen Bildkoordinatensystem (y-Achse nach unten)
fWinkel = -90; % fWinkel in deg

%% Originalbild aOriginalBild laden
% stDateiName: Dateiname des Binärbildes
% aOriginalBild: 2D-Matrix mit logischen Werten (0=schwarz, 1=weiß)
stDateiName = 'StrichmaennchenBinaer.png';
aOriginalBild = imread(stDateiName);

%% Bildgröße bestimmen - Variablen m (Höhe) und n (Breite)
% m: Bildhöhe (Anzahl Zeilen) - vertikale Ausdehnung
% n: Bildbreite (Anzahl Spalten) - horizontale Ausdehnung
[m, n] = size(aOriginalBild);

%% Translationsvektor t zum Bildmittelpunkt bestimmen
% Der Bildmittelpunkt dient als Rotationspunkt (Drehzentrum)
% KOS-Operation: Translation vom Ursprung zum Bildmittelpunkt

% cx - horizontaler Bildmittelpunkt (x-Koordinate in Pixeln)
cx = round(n / 2); % Mitte der Bildbreite (Spalten)

% cy - vertikaler Bildmittelpunkt (y-Koordinate in Pixeln)
cy = round(m / 2); % Mitte der Bildhöhe (Zeilen)

% t - Translationsvektor als homogener 3D-Vektor
% t = [cx; cy; 0] beschreibt die Position des Rotationszentrums
% Wird verwendet um Pixel zum Ursprung zu verschieben und zurück
t = [cx; cy; 0];

%% Zielmatrix aBildInit und aBildB initialisieren
% aBildInit: Initialisierungsmatrix mit logisch 1 (Weiß)
% Alle Pixel werden auf Weiß gesetzt (Hintergrund)
aBildInit = ones(m, n, 'logical');

% aBildB - Zielbild für rotiertes Ergebnis
% Kopie von aBildInit, wird durch Rotationsalgorithmus modifiziert
aBildB = aBildInit;

%% Rotationsmatrix Rza um Z-Achse berechnen
% KOS-Operation: Rotation um Z-Achse (senkrecht zur Bildebene)
% Rza: 3x3 homogene Rotationsmatrix für 2D-Rotation
% Transformiert Punkte im Bildkoordinatensystem
Rza = RotationUmZ(fWinkel);

%% Rotation des Originalbildes - KOS-Transformationskette
% Für jeden schwarzen Pixel wird folgende KOS-Transformation durchgeführt:
% Translation zum Ursprung: p_temp = p - t (Bild-KOS -> Rotations-KOS)
% Rotation um Z-Achse: p_rot = Rza * p_temp (Rotation im Rotations-KOS)
% Translation zurück: p_neu = p_rot + t (Rotations-KOS -> Bild-KOS)
%
% Mathematisch: p_neu = Rza * (p - t) + t = Rza * p + (t - Rza * t)

for i = 1:m
    for j = 1:n
        % Wenn Pixel im Original schwarz ist (logisch 0)
        if aOriginalBild(i, j) == 0
            
            % p_alt - Alter Pixelvektor im Bild-KOS {B}
            % Homogene Koordinaten: [x; y; 1] wobei x=Spalte (j), y=Zeile (i)
            p_alt = [j; i; 1];
            
            % KOS-Transformation Schritt 1 - Translation zum Ursprung
            % p_temp: Pixelposition im Rotations-KOS {R} (Ursprung = Bildmittelpunkt)
            % Transformation {B} -> {R}: p_temp = p_alt - t
            p_temp = p_alt - t;
            
            % KOS-Transformation Schritt 2 - Rotation um Z-Achse
            % p_rot: Rotierter Pixel im Rotations-KOS {R}
            % Anwendung der Rotationsmatrix: p_rot = Rza * p_temp
            % Rza rotiert um Winkel fWinkel (mathematisch positiv = Gegenuhrzeigersinn)
            p_rot = Rza * p_temp;
            
            % KOS-Transformation Schritt 3 - Translation zurück zum Bildmittelpunkt
            % p_neu: Neuer Pixelvektor im Bild-KOS {B}
            % Transformation {R} -> {B}: p_neu = p_rot + t
            p_neu = p_rot + t;
            
            % Neue Pixelkoordinaten extrahieren und runden
            j_neu = round(p_neu(1)); % x-Koordinate (Spalte) im Zielbild
            i_neu = round(p_neu(2)); % y-Koordinate (Zeile) im Zielbild
            
            % Boundary Check - Prüfe ob neue Position im Bildbereich liegt
            % Verhindert Zugriff außerhalb der Matrix (Index out of bounds)
            if i_neu >= 1 && i_neu <= m && j_neu >= 1 && j_neu <= n
                % aBildB - Setze transformierten Pixel auf schwarz (logisch 0)
                % Übertrage schwarzen Pixel vom Original an rotierte Position
                aBildB(i_neu, j_neu) = false;
            end
        end
    end
end

%% Ergebnisdarstellung entsprechend Abb. 1
figure('Name', 'Abb. 1: Rotation_eines_Bildes', 'Position', [100, 100, 900, 400]);

% Subplot 1: Originalbild aOriginalBild
hAxes1 = subplot(1, 2, 1);
imshow(aOriginalBild);
title('Originalbild', 'FontSize', 12);
xlabel(''); % Leeres xlabel
set(hAxes1, 'box', 'on', 'Visible', 'on', 'xtick', [], 'ytick', []);

% Subplot 2: Rotiertes Bild aBildB
hAxes2 = subplot(1, 2, 2);
imshow(aBildB);
title(sprintf('Rotation um %.0f°', fWinkel), 'FontSize', 12);
xlabel(''); % Leeres xlabel
set(hAxes2, 'box', 'on', 'Visible', 'on', 'xtick', [], 'ytick', []);

% Gesamttitel
sgtitle('Abb. 1: Rotation_eines_Bildes', 'FontSize', 13, 'FontWeight', 'bold');

%% Verifikation der Testgrößen
fprintf('========== VERIFIKATION ==========\n');
fprintf('Rotationswinkel fWinkel = %.0f° (nach links)\n', fWinkel);
fprintf('Originalbild aOriginalBild: %s\n', stDateiName);
fprintf('Bildbreite n = %d Pixel\n', n);
fprintf('Bildhöhe m = %d Pixel\n', m);
fprintf('Bildmittelpunkt: cx = %d, cy = %d\n', cx, cy);
fprintf('Translationsvektor t = [%d; %d; %d]\n', t(1), t(2), t(3));
fprintf('Zielmatrix aBildInit: %d x %d (logisch 1 = Weiß)\n', size(aBildInit, 1), size(aBildInit, 2));
fprintf('Rotiertes Bild aBildB: Strichmännchen um %.0f° gedreht\n', fWinkel);
fprintf('Rotationsmatrix Rza: 3x3 um Z-Achse\n');
fprintf('Ergebnisdarstellung: Abb. 1 mit 2 Subplots\n');
fprintf('==================================\n');

%% Inline-Unterfunktion RotationUmZ zur Berechnung von Rza
function Rza = RotationUmZ(fWinkel)
    % RotationUmZ - Erzeugt 3x3 homogene Rotationsmatrix um Z-Achse
    %
    % Eingabe:
    %   fWinkel: Rotationswinkel in Grad
    %            positiv = Gegenuhrzeigersinn (mathematisch positiv)
    %            negativ = Uhrzeigersinn
    %
    % Ausgabe:
    %   Rza: 3x3 homogene Rotationsmatrix für 2D-Rotation
    %        Rza transformiert Punkte p durch: p_neu = Rza * p
    %
    % Mathematische Formulierung der Rotationsmatrix:
    %   Rza = [cos(theta), -sin(theta), 0]
    %         [sin(theta),  cos(theta), 0]
    %         [0,           0,          1]
    %
    % KOS-Bedeutung:
    %   - Rotiert 2D-Punkte (x,y) um Ursprung
    %   - Dritte Zeile/Spalte für homogene Koordinaten (z=0, w=1)
    %   - Erhält Distanzen und Winkel (orthogonale Transformation)
    
    % Winkel von Grad in Radianten konvertieren
    % theta: Rotationswinkel in Radianten für trigonometrische Funktionen
    theta = deg2rad(fWinkel);
    
    % Rza - Rotationsmatrix erstellen (3x3 homogen)
    % Erste Spalte: rotierte x-Achse [cos(theta); sin(theta); 0]
    % Zweite Spalte: rotierte y-Achse [-sin(theta); cos(theta); 0]
    % Dritte Spalte: unveränderte z-Achse [0; 0; 1]
    Rza = [cos(theta), -sin(theta), 0;
           sin(theta),  cos(theta), 0;
           0,          0,          1];
end