close all; clear all; clc;

load('Kalibrierdaten.mat')
x = U3
y = L0;

%% Substitution
% Für eine gebrochen rationale Regression (y = b1 * 1/x + b0) wird 1/x substituiert
x2 = 1 ./ x

%% Lineare Regression nach Gleichungen
% Anzahl der Messwerte bestimmen
n = length(x2);

% Berechnung der empirischen Varianzen und Kovarianz mit mathematischen Basisfunktionen (Bessel-Korrektur N-1)
sxx = sum((x2 - mean(x2)).^2) / (n - 1)
syy = sum((y - mean(y)).^2) / (n - 1)
sxy = sum((x2 - mean(x2)) .* (y - mean(y))) / (n - 1)

% Steigung b1 berechnen: b1 = sxy / sxx
b1 = sxy / sxx
% Y-Achsenabschnitt b0 berechnen: b0 = mean(y) - b1 * mean(x2)
b0 = mean(y) - b1 * mean(x2)

X = [0.1:0.1:3.5]
Y = b1*1./X+b0; %% Gerade berechnen

% Bestimmtheitsmaß R^2 über die Varianzen/Kovarianz berechnen: R^2 = sxy^2 / (sxx * syy)
R2 = sxy^2 / (sxx * syy) % Bestimmtheitsmaß

h=figure;
hold on
plot(x,y,'r.')

xlabel('U in V')
ylabel('Distanz in cm')

plot(X,Y,'b-')