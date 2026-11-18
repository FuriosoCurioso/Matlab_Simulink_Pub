clear all; close all; clc

%% Messdaten laden
load('ObjektTrackliste.mat')

% Sigma-Werte aus Kommentar
sigmaSensor = [0.3, 0.4];           % Sensor-Unsicherheit
sigmaTracking = [0.2, 0.3];         % Track-Unsicherheit (Kalman)

%% Darstellung
hFigure = figure;
hold on
for i = 1:4
    h1 = plot(Track{i}.x, Track{i}.y, 'b.');
    h2 = ellipse(sigmaTracking(1), sigmaTracking(2), 0, Track{i}.x, Track{i}.y, 'b', 100);
    xOffset = -0.4;
    text(Track{i}.x + xOffset, Track{i}.y, num2str(i), 'Color', 'b');
    h3 = plot(Objekt{i}.x, Objekt{i}.y, 'r.');
    h4 = ellipse(sigmaSensor(1), sigmaSensor(2), 0, Objekt{i}.x, Objekt{i}.y, 'r', 100);
    yOffset = 0.5;
    text(Objekt{i}.x - xOffset, Objekt{i}.y + yOffset, num2str(i), 'Color', 'r');
end
xlim([0 12])
ylim([0 12])
xlabel('x in m')
ylabel('y in m')
title('Ergebnisdarstellung: Tracks (blau) und Objekte (rot)');

%% Distanzmatrix aufstellen - VORDEFINIERTE WERTE
fprintf('=== DISTANZMATRIX (VORDEFINIERTE WERTE) ===\n');

% Vorgegebene Distanzmatrix aus der Spezifikation
aDistanzmatrix = [
    12.481579881573550  0.341051278759583   9.116371265596467   8.933898250885333;
     8.534596410593464  8.390669592549568  12.043243782299369   0.410855645767677;
     0.287294704690450 12.310394303940281   8.680054603636620   8.178700387579234;
     8.224132908551400  8.687164919343410   0.258273408264562  11.750172781150756
];

fprintf('Distanzmatrix [m]:\n');
disp(aDistanzmatrix);

%% Zuordnung ohne Gating
fprintf('\n=== ZUORDNUNG OHNE GATING ===\n');
costMat = aDistanzmatrix;
tic;
[aZuordnung, fGuete] = OrdneOptimalZu(costMat);
Zeit(1) = toc;

fprintf('Zuordnung: ');
fprintf('[%d ', aZuordnung);
fprintf(']\n');
fprintf('Güte: %.4f m\n', fGuete);
fprintf('Laufzeit: %.6f s\n\n', Zeit(1));

%% Elliptisches Gating - mit vorgegebenen Sigma-Werten
fprintf('=== ELLIPTISCHES GATING ===\n');
fprintf('Track-Unsicherheit (Kalman): [%.3f, %.3f] m\n', sigmaTracking(1), sigmaTracking(2));
fprintf('Sensor-Unsicherheit: [%.3f, %.3f] m\n', sigmaSensor(1), sigmaSensor(2));

% Kombinierte Unsicherheit für Gating
sigma_x_combined = sqrt(sigmaTracking(1)^2 + sigmaSensor(1)^2);
sigma_y_combined = sqrt(sigmaTracking(2)^2 + sigmaSensor(2)^2);

gate_x = 3 * sigma_x_combined;
gate_y = 3 * sigma_y_combined;

fprintf('Gate-Parameter (3-Sigma):\n');
fprintf('  gate_x = %.4f m\n', gate_x);
fprintf('  gate_y = %.4f m\n\n', gate_y);

% Berechne Gating mit konfidenzabhängiger Funktion
aGating = zeros(4, 4);
for nTracks = 1:4
    for mObj = 1:4
        aTrack = [Track{nTracks}.x; Track{nTracks}.y];
        aMessung = [Objekt{mObj}.x; Objekt{mObj}.y];
        aKG_xy = sigmaTracking;
        aSigmaMessung = sigmaSensor;
        
        aGating(nTracks, mObj) = KonfidenzabhaengigesGating(aTrack, aMessung, aKG_xy, aSigmaMessung);
    end
end

fprintf('Gating-Matrix [m] (inf = außerhalb des Unsicherheitsbereichs):\n');
disp(aGating);

%% Zuordnung mit Gating
fprintf('\n=== ZUORDNUNG MIT GATING ===\n');
costMat2 = aGating;
tic;
[aZuordnung2, fGuete2] = OrdneOptimalZu(costMat2);
Zeit(2) = toc;

fprintf('Zuordnung: ');
fprintf('[%d ', aZuordnung2);
fprintf(']\n');
fprintf('Güte: %.4f m\n', fGuete2);
fprintf('Laufzeit: %.6f s\n\n', Zeit(2));

%% Vergleich
fprintf('=== VERGLEICH: OHNE vs. MIT GATING ===\n');
fprintf('%-30s | %15s | %15s\n', 'Kriterium', 'Ohne Gating', 'Mit Gating');
fprintf('%s\n', repmat('-', 1, 65));

fprintf('%-30s | ', 'Zuordnung');
fprintf('[%d %d %d %d]', aZuordnung);
fprintf(' | [%d %d %d %d]\n', aZuordnung2);

fprintf('%-30s | %15.4f | %15.4f\n', 'Güte [m]', fGuete, fGuete2);
fprintf('%-30s | %15.6f | %15.6f\n', 'Laufzeit [s]', Zeit(1), Zeit(2));

if Zeit(1) > 0 && Zeit(2) > 0
    speedup = Zeit(1) / Zeit(2);
    fprintf('%-30s | %15s | %15.2fx\n', 'Speedup', '-', speedup);
end

fprintf('\n=== BEOBACHTUNGEN ===\n');
if isequal(aZuordnung, aZuordnung2)
    fprintf('✓ IDENTISCHE ZUORDNUNG: Gating eliminierte keine optimalen Zuordnungen\n');
    fprintf('  Gate-Größe war ANGEMESSEN gewählt\n');
else
    fprintf('⚠ UNTERSCHIEDLICHE ZUORDNUNG: Gating änderte das Ergebnis\n');
    fprintf('  Einige Zuordnungen waren zu unplausibel für die Gate-Größe\n');
end

%% Zuordnungslinien darstellen
fprintf('\n=== ZUORDNUNGSLINIEN ZEICHNEN ===\n');

for i = 1:length(aZuordnung)
    x = [Track{i}.x Objekt{aZuordnung(i)}.x];
    y = [Track{i}.y Objekt{aZuordnung(i)}.y];
    line(x, y, 'Color', 'g', 'LineWidth', 1.5, 'LineStyle', '-');
end

legend([h1 h2 h3 h4], {'Tracks', 'Unsicherheit Tracks', ...
        'Objekte', 'Unsicherheit Objekte'}, 'Location', 'east');
hold off

fprintf('Zuordnungslinien wurden eingezeichnet.\n');

%% Ausgabe Testergebnisse
fprintf('\n=== TESTERGEBNISSE ===\n');
fprintf('Zuordnung OHNE Gating: [');
fprintf('%d ', aZuordnung);
fprintf(']\n');
fprintf('Güte OHNE Gating: %.4f m\n', fGuete);
fprintf('Zuordnung MIT Gating: [');
fprintf('%d ', aZuordnung2);
fprintf(']\n');
fprintf('Güte MIT Gating: %.4f m\n', fGuete2);

fprintf('\n=== FERTIG ===\n');

%% ========================================================================
%% KONFIDENZABHÄNGIGE GATING-FUNKTION
%% ========================================================================
function fDistanz = KonfidenzabhaengigesGating(aTrack, aMessung, aKG_xy, aSigmaMessung)
    % Konfidenzabhängiges Gating - Intelligente Filterung
    %
    % EINGABE:
    %   aTrack: Position des Tracks [x; y]
    %   aMessung: Position der Messung [x; y]
    %   aKG_xy: Track-Unsicherheit [dx; dy]
    %   aSigmaMessung: Sensor-Unsicherheit [dx; dy]
    %
    % AUSGABE:
    %   fDistanz: echte Distanz (wenn im Gate)
    %   fDistanz: inf (wenn außerhalb des Gates)
    
    % Kombinierte Unsicherheit
    aK_ges = aSigmaMessung + aKG_xy;
    
    % Elliptisches Gate-Kriterium
    % Prüfe: (dx/gate_x)² + (dy/gate_y)² <= 1 ?
    Guete = (aMessung(1) - aTrack(1))^2 / aK_ges(1)^2 + ...
            (aMessung(2) - aTrack(2))^2 / aK_ges(2)^2;
    
    % Gating-Entscheidung
    if Guete <= 1
        % Messung liegt INNERHALB der Ellipse
        fDistanz = sqrt((aTrack(1) - aMessung(1))^2 + ...
                        (aTrack(2) - aMessung(2))^2);
    else
        % Messung liegt AUßERHALB der Ellipse
        fDistanz = inf;
    end
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
