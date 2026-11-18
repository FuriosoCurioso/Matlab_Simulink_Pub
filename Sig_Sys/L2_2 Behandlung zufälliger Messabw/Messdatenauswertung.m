close all; clear all; clc;

% Eingangsgrößen:
R=[995 993 1006 994 1003 1001 1005 999] % Messwerte in Ohm
n = 8; % Einzelmessungen
M = 1; % 1 Wiederholung der Einzelmessung


%% Wie groß ist der Mittelwert der Einzelwerte?
% Arithmetischer Mittelwert der Einzelmessungen
RE = mean(R) % Mittelwert

%% Wie groß ist der Standardabweichung der Einzelwerte?
% Empirische Standardabweichung der Einzelmessungen (Bessel-Korrektur N-1)
sE = std(R) % Standardabweichung

%% den Verlauf der Wahrscheinlichkeitsdichtefunktion für die zuvor ermittelten Parameter in einen Graph zeichnen
x = 980:0.1:1020; % Messwertbereich
% Wahrscheinlichkeitsdichtefunktion der Normalverteilung: pE(x) = normpdf(x, mu, sigma)
pE = normpdf(x, RE, sE); % Wahrscheinlichkeitsdichtefunktion pE(x)

%% Wie groß ist die absolute Messunsicherheit uE der Einzelmesswerte bei einer Aussagesicherheit von 68,3% bzw. 95,5%?
% 68,3% entspricht 1 Sigma (k=1)
uE_68p = 1 * sE % Messunsichergheit mit 68,3,5% Prozent Aussagesicherheit
% 95,5% entspricht 2 Sigma (k=2)
uE_95p = 2 * sE % Messunsichergheit mit 95,5% Prozent Aussagesicherheit

%% In welchem Intervall sind die R-Werte zu erwarten?
%% Vollständiges Messergebnis
disp(['68,3%: R = ',num2str(RE),'+/- ',num2str(uE_68p),' Ohm'])
disp(['95,5%: R = ',num2str(RE),'+/- ',num2str(uE_95p),' Ohm'])


%% Die Messreihe mit je 8 Einzelmessungen wird M=25 Mal wiederholt, und für jede Messreihe wird ein Mittelwert gebildet. 
M = 25; % je 8 Einzelmessungen wird M=25 Mal

%% Wie groß ist  dieser Mittelwerte, die Standardabweichung dieser Mittelwerte sowie deren Messunsicherheit , wenn angenommen wird, dass sich die Standardabweichung  der Einzelwerte nicht ändert?
% Der Mittelwert der Mittelwerte entspricht dem Mittelwert der Einzelwerte
RM = RE % Mittelwert
% Die Standardabweichung der Mittelwerte verringert sich um den Faktor 1/sqrt(M)
sM = sE / sqrt(M) % Standardabweichung
% Messunsicherheit der Mittelwerte bei 68,3% (k=1)
uM_68p = 1 * sM % Messunsichergheit mit 68,3,5% Prozent Aussagesicherheit
% Messunsicherheit der Mittelwerte bei 95,5% (k=2)
uM_95p = 2 * sM % Messunsichergheit mit 95,5% Prozent Aussagesicherheit

disp(['68,3%: R = ',num2str(RE),'+/- ',num2str(uM_68p),' Ohm'])
disp(['95,5%: R = ',num2str(RE),'+/- ',num2str(uM_95p),' Ohm'])

%% Worin liegt der Gewinn der wiederholten Messung? als Quelltextkommentar begründen
%  Begründung: Durch die wiederholte Messung und anschließende Mittelwertbildung 
%  verringert sich die Standardabweichung (und damit die Messunsicherheit) um 
%  den Faktor 1/sqrt(M). Das Messergebnis wird dadurch signifikant präziser.


%% in den Graphen aus die Wahrscheinlichkeitsdichtefunktion  der Mittelwerte eintragen
% Wahrscheinlichkeitsdichtefunktion der Mittelwerte mit angepasster Standardabweichung sM
pM = normpdf(x, RM, sM);

%% Ergebnisgraph erstellen (wie in Abb. 1 gefordert)
figure;
hold on;

% h1: Handle für Normalverteilung pE(R) mit M=1 (blaue Linie)
h1 = plot(x, pE, 'b-', 'LineWidth', 1);

% h2: Handle für Messwerte (rote Kreise auf der x-Achse)
h2 = plot(R, zeros(1, length(R)), 'ro');

% h3: Handle für Mittelwert R_quer (dicke graue Linie, RGB für Grau da kein Kürzel existiert)
h3 = plot([RE RE], [0 0.4], 'Color', [0.5 0.5 0.5], 'LineWidth', 2.5);

% h4: Handle für Standardabweichung sigma (dünne graue Linien)
h4 = plot([RE - sE, RE - sE], [0 0.4], 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
plot([RE + sE, RE + sE], [0 0.4], 'Color', [0.5 0.5 0.5], 'LineWidth', 1);

% h5: Handle für Standardunsicherheit Typ A (68,3%) (blaue durchgezogene Linien)
h5 = plot([RE - uM_68p, RE - uM_68p], [0 0.4], 'b-', 'LineWidth', 1);
plot([RE + uM_68p, RE + uM_68p], [0 0.4], 'b-', 'LineWidth', 1);

% h6: Handle für Standardunsicherheit Typ A (95,5%) (blaue gestrichelte Linien)
h6 = plot([RE - uM_95p, RE - uM_95p], [0 0.4], 'b--', 'LineWidth', 1);
plot([RE + uM_95p, RE + uM_95p], [0 0.4], 'b--', 'LineWidth', 1);

% h7: Handle für Normalverteilung pM(R) mit M=25 (rote Linie)
h7 = plot(x, pM, 'r-', 'LineWidth', 1);

hold off;

% Achsenbeschriftungen und Limits
xlabel('R in \Omega');
ylabel('p(R)');
ylim([0 0.4]);

% Legende mit exakten Bezeichnungen aus dem Referenzbild
legend([h1, h2, h3, h4, h5, h6, h7], ...
    'Normalverteilung p_E(R) mit M=1', ...
    'Messwerte', ...
    'Mittelwert \bar{R}', ...
    'Standardabweichung \sigma', ...
    'Standardunsicherheit Typ A (68,3 %)', ...
    'Standardunsicherheit Typ A (95,5 %)', ...
    'Normalverteilung p_M(R) mit M=25', ...
    'Location', 'northeast');
