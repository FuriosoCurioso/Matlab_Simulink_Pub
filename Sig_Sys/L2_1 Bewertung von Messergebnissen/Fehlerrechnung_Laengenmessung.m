close all; clear all; clc;

%% Eingangsgrößen:
a = [71, 72, 72, 73, 71] % mm

%% Ergebnisgrößen:
% Anzahl der Messungen bestimmen
n   = length(a) % Anzahl der Messungen

% Mittelwert berechnen
ma  = mean(a) % in mm - Mittelwert

% Standardabweichung der Einzelmessungen berechnen (empirisch, N-1)
sa  = std(a) % in mm - Standardabweichung der Einzelmessungen

% Mittleren Fehler des Mittelwertes berechnen: sma = sa / sqrt(n)
sma = sa / sqrt(n) % in mm - mittleren Fehler des Mittelwertes