close all; clear all; clc;

load('Daten_2_1.mat')

x = U_in_V;
y = Distanz_in_cm;

figure
hold on
plot(x, y, 'r.')

%% Lineare Regression nach Gleichungen
n = length(x); % Anzahl der Messwerte

% Normierte Varianz/Kovarianz (Bessel-Korrektur, n-1): sxx = 1/(n-1)*sum((xi-x̄)²)
sxx = sum((x - mean(x)).^2) / (n - 1)
syy = sum((y - mean(y)).^2) / (n - 1)
sxy = sum((x - mean(x)) .* (y - mean(y))) / (n - 1)

% b1 = sxy/sxx  →  Steigung der Regressionsgeraden (MKQ, Verhältnis bleibt identisch)
b1 = sxy / sxx
% b0 = ȳ - b1*x̄  →  Achsenabschnitt
b0 = mean(y) - b1 * mean(x)

Y = b1*x+b0; %% Gerade berechnen
plot(x, Y, 'b-', 'LineWidth', 3)
xlabel('U in V')
ylabel('Distanz in cm')
legend('Messwerte', 'Regressionsgerade')