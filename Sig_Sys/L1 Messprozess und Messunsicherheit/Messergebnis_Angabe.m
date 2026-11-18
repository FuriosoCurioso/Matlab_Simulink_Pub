clc; clear all; close all;

%% Eingangsgrößen:
x   = 1.0003;   % unberichtigtes Messergebnis in kg
% Komma → Punkt (MATLAB-Dezimaltrennzeichen)
Asb = -1.11;  % bekannte systematische Abweichung in kg
% -1.1 g = -0.0011 kg (Template hatte -1.11 g, Schritt: -1,1 g)
ux  = 0.6;   % Standardunsicherheit u(x) in kg
% g = 0.0006 kg (einheitenkonsistent zu x)

%% Berichtigtes Messergebnis
% M = x - A_sb  →  systematische Abweichung vom unberichtigten Wert subtrahieren
M = x - Asb
disp(['Berichtigte Messwertgebnis: M = ', num2str(M), ' kg'])

%% Vollständiges Messergebnis
disp(['Vollständige Messergebnis: X = ', num2str(M), ' kg ± ', num2str(ux), ' kg'])

%% Berechnung der relativen Unsicherheit
% uYrel = u(x) / M * 100  →  relative Unsicherheit in Prozent
uYrel = ux / M * 100
disp(['Vollständige Messergebnis: X = ', num2str(M), ' kg, ', num2str(uYrel)])