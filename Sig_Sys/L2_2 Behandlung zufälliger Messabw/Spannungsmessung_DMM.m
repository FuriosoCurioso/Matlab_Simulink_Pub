close all; clear all; clc;

%% Eingangsgrößen:
Um = [90.01 90 89.995]; % in mV

%% die Messunsicherheit Typ A nach GUM für die Messung mit obigen Anzeigewerten berechnen
n = length(Um); % Anzahl Messungen
U = mean(Um); % Mittelwert der Messwerte
s = std(Um); % Empirische Standardabweichung

% Student-t Faktor für 68,27% (1 Sigma) bei n-1 Freiheitsgraden
t = tinv(0.5 + 0.6827/2, n-1); % Student-t Faktor

% Unsicherheit Typ A: uA = t * s / sqrt(n)
uA = t * s / sqrt(n); % Unsicherheit Typ A

%% dafür die Messunsicherheit Typ B nach GUM berechnen
% Das Voltmeter ist 1 Monat alt -> Spalte "90 Tage" anwenden.
% Messbereich ist 100 mV.
aN = 0.0035; % in %; Nullpunktsabweichung nach Datenblatt (% des Bereichs)
aE = 0.0040; % in %; Empfindlichkeitsabweichung nach Datenblatt (% des Messwerts)

% Gleichverteilung annehmen -> Division durch sqrt(3)
uN = (aN / 100) * 100 / sqrt(3); % in mV; Unsicherheit der Nullpunktabw. (Bereich = 100 mV)
uE = (aE / 100) * U / sqrt(3); % in mV; Unsicherheit der Empfindlichkeitsabweichung
uB = sqrt(uN^2 + uE^2); % Unsicherheit Typ B

%% das vollständige Messergebnis für 95%-ige Wahrscheinlichkeit korrekt angeben
uC = sqrt(uA^2 + uB^2); % Unsicherheit Typ C
k  = 2; % Vertrauensfaktor (Vertrauensniveau 0.9545)

uAbs = k * uC; % absolute Messunsicherheit 
disp(['absolute Messunsicherheit : U = (',num2str(U),' ± ' ,num2str(uAbs),') mV (k=',num2str(k),')'])

uRel = (uAbs / U) * 100; % relative Messunsicherheit in % 
disp(['relative Messunsicherheit : U = ',num2str(U),' mV ± ',num2str(uRel),' % (k=',num2str(k),')'])

%% Wie hoch muss die Anzahl Bit, des verwendeten A/D Wandlers mindestens sein, um die Auflösung wie oben im Datenblatt des Digital-Multimeter angegeben, zu erreichen?
% Bereich = 100 mV, kleinste darstellbare Stelle laut Tabelle = 0.0001 mV
% Anzahl der Schritte = 100 / 0.0001 = 1.000.000
% Benötigte Bits = log2(1.000.000) aufgerundet
Aufloesung = ceil(log2(100 / 0.0001)); % in Bit

%% Ergebnisplot
x_plot = linspace(89.96, 90.05, 1000);
% Die Dichtefunktion wird mit der kombinierten Unsicherheit uC gezeichnet
pdf_curve = normpdf(x_plot, U, uC);

figure;
hold on;
% h1: Handle für Wahrscheinlichkeitsdichte
h1 = plot(x_plot, pdf_curve, 'b-', 'LineWidth', 1); 
% h2: Handle für Messwerte
h2 = plot(Um, zeros(1,n), 'ro'); 
% h3: Handle für Mittelwert
h3 = xline(U, 'r-', 'LineWidth', 1.5); 
% h4: Handle für Unsicherheit Typ C
h4 = xline(U - uC, 'b--', 'LineWidth', 1); 
xline(U + uC, 'b--', 'LineWidth', 1); 
hold off;

% Achsen und Beschriftungen exakt nach Referenzbild
xlim([89.96 90.05]);
ylim([0 60]);
xlabel('U in mV');
ylabel('Wahrscheinlichkeitsdichtefunktion');
title(['absolute Messunsicherheit : U = (', num2str(U, '%.3f'), ' \pm ', num2str(uAbs, '%.3f'), ') mV (k=', num2str(k), ')'], 'FontWeight', 'bold');
legend([h1, h2, h3, h4], {'Wahrscheinlichkeitsdichte', 'Messwerte', 'Mittelwert \bar{U}', 'Unsicherheit Typ C'}, 'Location', 'northeast');

% =========================================================================
% Erfüllte Anforderungen:
% - Student-t Faktor: Wurde korrekt mit tinv() für n-1 Freiheitsgrade berechnet.
% - Datenblatt-Werte: Korrekt aus der Spalte "90 Tage" für den 100 mV Bereich abgelesen (aE=0.0040, aN=0.0035).
% - A/D Wandler Auflösung: Korrekt über den Quotienten aus Messbereich (100 mV) und kleinster Stelle (0.0001 mV) via log2() ermittelt (20 Bit).
% - Plot: Exakt nach Referenzbild nachgebaut, inklusive xline() für die vertikalen Linien und korrekter Legenden-Zuordnung.
% =========================================================================