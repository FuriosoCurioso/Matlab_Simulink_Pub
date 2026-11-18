close all; clear all; clc;

%% Eingangsgrößen:
U1   = 12.50; % in V
U2   = 13.60; % in V
uRel = 0.002; % relativen GUM Unsicherheit 0,2%

%% Resamtspannung
% Gesamtspannung bei Serienschaltung: Uges = U1 + U2
Uges = U1 + U2

%% Teilunsicherheiten
% Absolute Unsicherheiten aus relativer Unsicherheit berechnen: u = U * uRel
uU1 = U1 * uRel
uU2 = U2 * uRel

%% Gesamtunsicherheit
% Quadratische Fehlerfortpflanzung für unkorrelierte Summe: uU = sqrt(uU1^2 + uU2^2)
uU = sqrt(uU1.^2 + uU2.^2)

disp(['Vollständiges Messergebnis: Uges = ',num2str(Uges),' ± ',num2str(uU),'V (k=1)'] )