close all; clear all; clc;

%% Zufällige Simulation der Messwerte
x = [0:0.1:10];
[y,~] = SimMessdaten(x);

%% Exponentielle Regression
% Linearisierung der y-Werte durch den natürlichen Logarithmus: y_lin = ln(y)
y_lin = log(y);

% Anzahl der Messwerte bestimmen
n = length(x);

% Berechnung der empirischen Varianzen und Kovarianz (Bessel-Korrektur N-1)
sxx = sum((x - mean(x)).^2) / (n - 1);
syy = sum((y_lin - mean(y_lin)).^2) / (n - 1);
sxy = sum((x - mean(x)) .* (y_lin - mean(y_lin))) / (n - 1);

% Regressionsgerade y=b1*x+b0
% Steigung b1 berechnen: b1 = sxy / sxx
b1 = sxy / sxx
% y-Achsenabschnitt b0 berechnen: b0 = mean(y_lin) - b1 * mean(x)
b0 = mean(y_lin) - b1 * mean(x)

% Parameter der Exponentialfunktion
% k entspricht der Steigung b1 der linearisierten Gerade
k = b1
% d entspricht der Exponentialfunktion des y-Achsenabschnitts: d = e^b0
d = exp(b0)

% Exponentialfunktion
Y = d*exp(k*x);

%% Ergebnisbewertung
% Korrelationskoeffizient r berechnen: r = sxy / sqrt(sxx * syy)
r = sxy / sqrt(sxx * syy) % Korrelationskoeffizienten
% Bestimmtheitsmaß r2 berechnen: r2 = r^2
r2 = r^2 % Bestimmtheitsmaß

h=figure; % h: Handle für die Figure
axis equal
h1 = plot(x,y,'r.'); % h1: Handle für den Scatterplot der Messwerte
hold on
h2 = plot(x,Y,'b-'); % h2: Handle für den Linienplot der Regression
ylabel('y') % Achsenbeschriftung korrigiert gemäß Referenzbild
xlabel('x') % Achsenbeschriftung korrigiert gemäß Referenzbild
legend([h1, h2], 'Messwerte','Regression');

