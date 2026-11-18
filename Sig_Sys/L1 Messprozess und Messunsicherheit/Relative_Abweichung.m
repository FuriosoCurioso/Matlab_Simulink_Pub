close all; clear all; clc;

%% Eingangsgrößen:
x  = 0.212;  % Messgröße in Ohm
xR = 0.207;  % Wahrer Wert in Ohm

%% Bestimmung der absoluten Abweichung
% A = x - xR  →  Differenz zwischen Messwert und richtigem Wert (DIN 1319)
A = x - xR
disp(['Die absoluten Abweichung beträgt: ', num2str(A), ' Ohm'])

%% Bestimmung der relativen Abweichungen bezogen auf xR
% Arel1 = A / xR  →  relative Abweichung bezogen auf den richtigen Wert
Arel1 = A / xR
disp(['Die relative Abweichungen bezogen auf xR beträgt: ', num2str(Arel1), ' Ohm'])

%% Bestimmung der relativen Abweichungen bezogen auf x
% Arel2 = A / x  →  Näherung: relatve Abweichung bezogen auf den Messwert (gilt für A << x)
Arel2 = A / x
disp(['Die relative Abweichungen bezogen auf x beträgt: ', num2str(Arel2), ' Ohm'])