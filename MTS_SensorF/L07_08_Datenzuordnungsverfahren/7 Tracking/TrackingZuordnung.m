% Verfolgung von 2 Objekten (A→D und B→C) durch kontinuierliche Zuordnung via Munkres

clear all; close all; clc

fprintf('=== TRACKING VON 2 OBJEKTEN DURCH ZUORDNUNG ===\n\n');

%% Schritt 1: Initialisierung - Objekt-Start- und Endpunkte

% Startpunkte (Punkt A und B)
A = [1 1];
B = [10 1];

% Endpunkte (Punkt D und C)
D = [1 10];
C = [10 10];

fprintf('Objektbahnen:\n');
fprintf('  Track 1: A [%.1f, %.1f] → D [%.1f, %.1f]\n', A(1), A(2), D(1), D(2));
fprintf('  Track 2: B [%.1f, %.1f] → C [%.1f, %.1f]\n', B(1), B(2), C(1), C(2));
fprintf('\n');

%% Schritt 5: Darstellung der Ergebnisse vorbereiten

hFigure = figure('Position', [100, 100, 1000, 800]);
hold on
grid on

% Markiere Start- und Endpunkte
plot(A(1), A(2), 'ok', 'MarkerSize', 8, 'LineWidth', 2);
text(A(1) - 0.5, A(2) - 0.5, 'A', 'FontSize', 12, 'FontWeight', 'bold');

plot(B(1), B(2), 'ok', 'MarkerSize', 8, 'LineWidth', 2);
text(B(1) + 0.3, B(2) - 0.5, 'B', 'FontSize', 12, 'FontWeight', 'bold');

plot(D(1), D(2), 'ok', 'MarkerSize', 8, 'LineWidth', 2);
text(D(1) - 0.5, D(2) + 0.3, 'D', 'FontSize', 12, 'FontWeight', 'bold');

plot(C(1), C(2), 'ok', 'MarkerSize', 8, 'LineWidth', 2);
text(C(1) + 0.3, C(2) + 0.3, 'C', 'FontSize', 12, 'FontWeight', 'bold');

%% Schritt 4: Speichern der Trackliste
saTrackListe = {};

%% Schritt 2 & 3: Zyklusschleife mit Munkres-Zuordnung

kMax = 11;  % Anzahl der Zyklen

fprintf('Zyklusweise Zuordnung:\n');
fprintf('%-5s | %-20s | %-20s | %-10s\n', 'Zyklus', 'Track 1 [x, y]', 'Track 2 [x, y]', 'Güte');
fprintf('%s\n', repmat('-', 1, 65));

for k = 1:kMax
    % Schritt 2: Lese Messwerte zyklisch
    z = leseMesswerte(k);
    
    if k == 1
        % Schritt 1: Initialisiere Tracks mit ersten Messungen
        Tracks = z;  % 2x2 Matrix: Spalte 1 = Track 1, Spalte 2 = Track 2
        Guete = 0;
        aZuordnung = [1, 2];  % Identität
        
        fprintf('%d      | [%.2f, %.2f]      | [%.2f, %.2f]      | Initial\n', ...
                k, Tracks(1,1), Tracks(2,1), Tracks(1,2), Tracks(2,2));
    else
        % Schritt 3: Berechne Distanzmatrix und führe Zuordnung durch
        aDistanzmatrix = zeros(2, 2);
        
        % ===== DISTANZMATRIX: Euklidischer Abstand zwischen Tracks und Messungen =====
        for i = 1:2  % i = Track-Index
            for j = 1:2  % j = Messwert-Index
                % Berechne euklidischen Abstand zwischen Track i und Messwert j
                delta_x = Tracks(1, i) - z(1, j);
                delta_y = Tracks(2, i) - z(2, j);
                aDistanzmatrix(i, j) = sqrt(delta_x^2 + delta_y^2);
            end
        end
        
        % ===== MUNKRES-ZUORDNUNG: Optimale 1:1 Zuordnung =====
        [aZuordnung, Guete] = OrdneOptimalZu(aDistanzmatrix);
        
        % ===== TRACKS AKTUALISIEREN: Ordne Messwerte den Tracks zu =====
        Tracks_neu = zeros(2, 2);
        for i = 1:2
            Tracks_neu(:, i) = z(:, aZuordnung(i));  % Messwert aZuordnung(i) → Track i
        end
        Tracks = Tracks_neu;
        
        fprintf('%d      | [%.2f, %.2f]      | [%.2f, %.2f]      | %.4f\n', ...
                k, Tracks(1,1), Tracks(2,1), Tracks(1,2), Tracks(2,2), Guete);
    end
    
    % Schritt 4: Speichere Track-Liste
    saTrackListe{k} = Tracks;
    
    % Schritt 5: Zeichne Messungen
    plot(z(1, :), z(2, :), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    
    % Schritt 6: Markiere Tracks mit farbigen Sternen
    % Track 1: Blaue Sterne
    plot(Tracks(1, 1), Tracks(2, 1), 'b*', 'MarkerSize', 15, 'LineWidth', 2);
    
    % Track 2: Grüne Sterne
    plot(Tracks(1, 2), Tracks(2, 2), 'g*', 'MarkerSize', 15, 'LineWidth', 2);
end

fprintf('%s\n\n', repmat('-', 1, 65));

% Achsenbeschriftung und Layout
xlim([0, 12]);
ylim([0, 12]);
xlabel('x in m', 'FontSize', 12);
ylabel('y in m', 'FontSize', 12);
title('Abbildung 1: Tracking von 2 Objekten', 'FontSize', 14, 'FontWeight', 'bold');

% Legende
legend({'Start/End', 'Messungen (rot)', 'Track 1 (blau)', 'Track 2 (grün)'}, ...
       'Location', 'northwest', 'FontSize', 11);

grid on;
hold off;

%% Unterfunktion
function z = leseMesswerte(k)
persistent bInit

if isempty(bInit) % einmalige Initialisierung
   load('ObjektListe.mat'); 
end

z= ObjektListe{k}; % Messungen

end

function [aZuordnung, fKosten] = OrdneOptimalZu(aKosten)
% OrdneOptimalZu: optimale 1:1-Zuordnung (Ungarische Methode) mit matchpairs
% Eingabe:  aKosten    [n x m]: Kostenmatrix, inf = Zuordnung verboten
% Ausgabe:  aZuordnung [1 x n]: zugeordnete Spalte je Zeile, 0 = ohne Partner
%           fKosten    [1x1]:   Summe der Kosten der Zuordnung
    fOhnePartner = 1e3 * max(aKosten(isfinite(aKosten)));  % Strafkosten fuer offene Zeilen
    aPaare = matchpairs(aKosten, fOhnePartner);
    aZuordnung = zeros(1, size(aKosten, 1));
    aZuordnung(aPaare(:, 1)) = aPaare(:, 2)';
    fKosten = sum(aKosten(sub2ind(size(aKosten), aPaare(:, 1), aPaare(:, 2))));
end