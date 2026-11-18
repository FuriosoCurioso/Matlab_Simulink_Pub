close all; clear all; clc;

%% Eingangsgrößen:
t = [52.69 52.72 52.72 52.68 52.66 52.69 52.68 52.69 52.66 52.72]; % t in s


n = 0; % Stichprobenumfang
mT = 0; % Bestwert (besten Schätzwert der Schwingungsdauer für eine Schwingung) in s,
sT = 0; % empirische Standardabweichung in s


uA = 0; % Standardunsicherheit Typ A
uB = 0; % Standardunsicherheit Typ B
uC = 0; % Standardunsicherheit Typ C

% Stichprobenumfang, Bestwert und empirische Standardabweichung
N = 30;
T = t./N;
% n = length(T) -> Anzahl der Messwerte
n = length(T)
% mT = mean(T) -> Arithmetischer Mittelwert der Schwingungsdauer pro Schwingung
mT = mean(T)
% sT = std(T) -> Empirische Standardabweichung mit n-1 im Nenner
sT = std(T)

% Standardunsicherheit Typ A, Typ B und Typ C
% uA = sT/sqrt(n) -> Standardunsicherheit des Mittelwertes
uA = sT/sqrt(n)
tRead = mean(t);
% deltaTG = 0.01 + 1.4e-5*tRead -> Grenzabweichung der digitalen Stoppuhr
deltaTG = 0.01 + 1.4e-5*tRead;
% uB = (deltaTG/sqrt(3))/N -> Rechteckverteilung der Grenzabweichung und Umrechnung auf eine Schwingung
uB = (deltaTG/sqrt(3))/N
% uC = sqrt(uA^2 + uB^2) -> Kombinierte Standardunsicherheit
uC = sqrt(uA^2 + uB^2)


%% Messergebnis
k=0; % Grad des Vertrauens
uAbs = 0; % absolut
uRel = 0; % relativ

% Grad des Vertrauens sowie absoluter und relativer Messfehler
% k = 2 -> Überdeckungswahrscheinlichkeit P = 95.45 %
k = 2
% uAbs = k*uC -> Erweiterte absolute Messunsicherheit
uAbs = k*uC
% uRel = (uAbs/mT)*100 -> Relative Messunsicherheit in Prozent
uRel = uAbs/mT +100


%% Darstellung der Ergebnisse im Command Window
% Vollständiges Messergebnis relativ und absolut im Command Window
disp('Messergebnisse:')

fprintf('n = %d\n', n);
fprintf('mT = %.7f s\n', mT);
fprintf('sT = %.8f s\n', sT);
fprintf('uA = %.8f s\n', uA);
fprintf('uB = %.8f s\n', uB);
fprintf('uC = %.8f s\n', uC);
fprintf('k = %d\n', k);
fprintf('uAbs = %.8f s\n', uAbs);
fprintf('uRel = %.6f %%\n', uRel);
fprintf('T = (%.7f +- %.8f) s\n', mT, uAbs);


%% Ergebisplot
% Ergebnisplot gemäß Referenzdarstellung
farbeHistogramm = [0.85 0.85 0.85]; % Grau aus Referenzplot, kein MATLAB-Standardfarbkürzel für Grau verfügbar
farbeNorm = [0.82 0.69 0.62]; % Braunton aus Referenzplot, kein MATLAB-Standardfarbkürzel für Braun verfügbar
xGrenzen = [min(T)-0.0015 max(T)+0.0015];
xPlot = linspace(xGrenzen(1), xGrenzen(2), 500);
% pNorm = normpdf(xPlot,mT,sT)/100 -> Skalierte Normaldichte für Prozentachse wie im Referenzplot
pNorm = normpdf(xPlot, mT, sT)./100;

% h: Handle auf das Figure-Objekt → wird für Position/Größe (aPos) benötigt
h = figure;

% Schritt: Figurgröße und -position setzen  [left bottom width height] in Pixeln
set(h, 'Position', [681 407 772 692]);

subplot(2,1,1)
yyaxis left
% hHist: Handle auf Histogrammobjekt -> Zugriff für Legendeneintrag des Histogramms
hHist = histogram(T, 5, 'FaceColor', farbeHistogramm, 'EdgeColor', 'k');
ylabel('Absolute Häufigkeit')
xlabel('Zeit pro Schwingung in s')
xlim(xGrenzen)
ylim([0 6])

% hT1: Handle auf Mittelwertlinie -> Zugriff für Legendeneintrag T
hT1 = xline(mT, 'k', 'LineWidth', 2);
% hS1: Handle auf linke Sigma-Linie -> Zugriff für Legendeneintrag \sigma
hS1 = xline(mT-sT, 'b', 'LineWidth', 1.5);
% hS2: Handle auf rechte Sigma-Linie -> zweite \sigma-Grenze ohne separaten Legendeneintrag
hS2 = xline(mT+sT, 'b', 'LineWidth', 1.5);
hS2.Annotation.LegendInformation.IconDisplayStyle = 'off';


yyaxis right
% hN1: Handle auf Normalverteilung -> Referenz auf rechte Prozentachse ohne separaten Legendeneintrag
hN1 = plot(xPlot, pNorm, 'Color', farbeNorm, 'LineWidth', 1);
hN1.Annotation.LegendInformation.IconDisplayStyle = 'off';
ylabel('Wahrscheinlichkeit in %')
ylim([0 6])
legend([hHist hT1 hS1], {'Histogramm', sprintf('T = %.4f s', mT), sprintf('\\sigma = %.8f s', sT)}, 'Location', 'northeast')

subplot(2,1,2)
% hN2: Handle auf Normalverteilungs-Linie -> Zugriff für Legendeneintrag der Dichtekurve
hN2 = plot(xPlot, pNorm, 'Color', farbeNorm, 'LineWidth', 1);
xlabel('Zeit pro Schwingung in s')
ylabel('Wahrscheinlichkeit in %')
xlim(xGrenzen)
ylim([0 6])

% hT2: Handle auf Mittelwertlinie -> Zugriff für Legendeneintrag T
hT2 = xline(mT, 'k', 'LineWidth', 2);
% hU1: Handle auf linke Unsicherheitslinie -> Zugriff für Legendeneintrag uAbs
hU1 = xline(mT-uAbs, 'b', 'LineWidth', 1.5);
% hU2: Handle auf rechte Unsicherheitslinie -> zweite uAbs-Grenze ohne separaten Legendeneintrag
hU2 = xline(mT+uAbs, 'b', 'LineWidth', 1.5);
hU2.Annotation.LegendInformation.IconDisplayStyle = 'off';
legend([hN2 hT2 hU1], {'Normalverteilung', sprintf('T = %.4f s', mT), sprintf('u_{Abs} = %.7f s (k=%d)', uAbs, k)}, ...
    'Location', 'northeast')
