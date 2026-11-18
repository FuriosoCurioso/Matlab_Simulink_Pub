close all; clear all; clc;

%% Eingangsgrößen:
x  = 0.212; % Messgröße in Ohm
xR = 0.207; % Wahrer Wert in Ohm

%% Bestimmung der absoluten Abweichung
% Absolute Abweichung berechnen: A = x - xR
A = x - xR
disp(['Die absoluten Abweichung beträgt: ',num2str(A),' Ohm'])

%% Bestimmung der relativen Abweichungen bezogen auf xR
% Relative Abweichung bezogen auf den wahren/richtigen Wert: Arel1 = A / xR
Arel1 = A / xR
disp(['Die relative Abweichungen bezogen auf xR beträgt: ',num2str(Arel1),' Ohm'])

%% Bestimmung der relativen Abweichungen bezogen auf x
% Relative Abweichung bezogen auf den Messwert: Arel2 = A / x
Arel2 = A / x
disp(['Die relative Abweichungen bezogen auf x beträgt: ',num2str(Arel2),' Ohm'])