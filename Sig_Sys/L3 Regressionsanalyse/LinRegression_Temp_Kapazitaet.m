close all; clear all; clc;

%% Eingangsgrößen:
T  = [0:5:35];                              % Temperatur in deg C
C  = [71.34 70.51 69.72 68.84 68.05 67.19 66.34 65.42]*1e-9; % Kapazität in F
C0 = 68e-9;  % Nennkapazität in F
T0 = 20;     % Nenntemperatur in degC

%% mittels linearer Regression den Empfindlichkeitskoeffizienten ac des untersuchten Kondensators einschließlich der wahrscheinlichen Abweichungsgrenzen auf einem Signifikanzniveau von $\\alpha$ = 0,005 bestimmen
% Substitution, um die geradengleichung zu erhalten: y = b1*x+b0;
% x = T - T0  →  Temperaturdifferenz zur Nenntemperatur in °C
x = T - T0;
% y = C/C0 - 1  →  normiertes Kapazitätsverhältnis (dimensionslos)
y = C / C0 - 1;

%% die drei Hilfsgrößen berechnen
Kovarianzmatrix = cov(x, y);  % empirische 2x2-Kovarianzmatrix (Bessel-Korrektur)
sxx = Kovarianzmatrix(1,1)    % Varianz von x in °C²
syy = Kovarianzmatrix(2,2)    % Varianz von y (dimensionslos)
sxy = Kovarianzmatrix(1,2)    % Kovarianz x,y in °C

%% die Koeffizienten der Regressionsgerade berechnen
% b1 = sxy/sxx  →  Steigung (MKQ-Formel)
b1 = sxy / sxx
% b0 = ȳ - b1*x̄  →  Achsenabschnitt
b0 = mean(y) - b1 * mean(x)

%% Berechnung der Regressionsgeraden
y_reg = b1 * x + b0;  % Regressionsgerade an Messpunkten ausgewertet

%% Bestimmung des Empfindlichkeitskoeffizienten ac des untersuchten Kondensators
% ac = b1  →  Steigung entspricht dem Empfindlichkeitskoeffizienten (1/°C)
ac = b1

%% Darstellung der Ergebnisse
plot(x, y,     'b*')   % Messwerte als blaue Sterne
hold on
plot(x, y_reg, 'r.-')  % Regressionsgerade rot
xlabel('Temperaturdifferenz in °C')
ylabel('Kapazitätsverhältnis (C/C_0)-1')

%% Berechnung der Restvarianz und der Standardabweichung
n = length(x);                              % Anzahl der Daten
% v = 1/(n-2) * (syy - b1*sxy)  →  Restvarianz (erwartungstreue Schätzung, FG = n-2)
v = (1/(n-2)) * (syy - b1 * sxy)           % Restvarianz
s = sqrt(v);                                % Standardabweichung der Residuen

%% Vertrauensbereich für Regressionsgerade
% p für zweiseitigen Vertrauensbereich für 95%
t95 = tinv(1 - 0.05/2, n-2)  % t-Quantil: tinv(0.975, n-2), zweiseitig α=0.05

%% Berechnung der Empirische Standardabweichung von x
% sx = std(x)  →  empirische Standardabweichung von x mit Bessel-Korrektur (n-1)
sx = std(x)  % in °C

%% Berechnen der Varianz der Residuen
% uac = t95 * s / (sx * sqrt(n))  →  Unsicherheit der Steigung b1 = ac
uac = t95 * s / (sx * sqrt(n))  % in 1/°C

disp(['ac = ', num2str(ac), ' 1/°C ± ', num2str(uac), ' 1/°C; P=95%'])