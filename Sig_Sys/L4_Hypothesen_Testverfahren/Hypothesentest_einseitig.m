clc; clear all; close all;
%% Eingangsgrößen:
load('Messdaten_A4.mat')    % Messdaten laden
mu0 = 3.5                   % Referenzwert: vom Hersteller angegebene Laufzeit in h

%% Stichprobenumfang bestimmen
n = length(x)               % Stichprobenumfang (Anzahl der Messwerte)

%% Mittelwert und Standardabweichung berechnen
xMean = mean(x)             % arithmetischer Mittelwert der Stichprobe in h
s     = std(x)              % Stichprobenstandardabweichung in h (Nenner: n-1, Bessel-Korrektur)

%% Pruefwert t bestimmen
% Formel: t0 = (xMean - mu0) / (s / sqrt(n))
% Nenner s/sqrt(n): Standardfehler des Mittelwerts (SEM)
tMin = (xMean - mu0) / (s / sqrt(n))   % Pruefwert t (dimensionslos)

%% t-Quantil berechnen
% Einseitiger Test (linksseitig): p = alpha  -->  tinv liefert negativen krit. Wert
% Zweiseitiger Test zum Vergleich: p = 1 - alpha/2
alpha = 0.05                % Signifikanzniveau 5 Prozent (Fehler 1. Art)
p     = alpha               % Vertrauensniveau fuer einseitigen linksseitigen Test (0.05)
nu    = n - 1               % Freiheitsgrade der t-Verteilung

t = tinv(p, nu)             % t-Quantil berechnen: ergibt negativen kritischen Wert

%% Ergebnis
% Testregel (linksseitig): H0 ablehnen, wenn tMin < t  (d.h. tMin < tinv(alpha, nu))
if tMin < 0
    disp('Die Nullhypothese, dass der Erwartungswert der Laufzeit gleich 3,5 Stunden ist, zum Signifikanzniveau wird abgelehnt.')
    disp('Die Akkus laufen im Mittel nicht 3,5 Stunden, also mehr oder weniger.')
    H0 = false;
else
    disp('Die Nullhypothese, dass der Erwartungswert der Laufzeit gleich 3,5 Stunden ist, zum Signifikanzniveau wird angenommen.')
    disp('Die Akkus laufen im Mittel 3,5 Stunden.')
    H0 = true;
end