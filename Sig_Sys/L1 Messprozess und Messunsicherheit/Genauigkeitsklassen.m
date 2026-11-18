close all; clear all; clc;

%% Eingangsgrößen:
G = 45;    % symmetrische Fehlergrenze in ppm
x = 2000;  % Messbereich (Endwert) in ppm

%% Genauigkeit
% Gp = G/x * 100  →  relative Fehlergrenze in Prozent bezogen auf Messbereichsendwert
Gp = G / x * 100  % Ergebnis: 2.25 %
disp(['Die Genauigkeit beträgt G = ', num2str(Gp), ' %'])

%% Genauigkeitsklasse
% Zuordnung: nächsthöherer Tabellenwert aus Tab. 6.6 (Parthier S. 108)
% Klassen Betriebsmessgeräte: 1; 1.5; 2.5; 5
% Gp = 2.25 %  →  liegt zwischen 1.5 und 2.5  →  Klasse 2.5
Genauigkeitsklasse = 2.5