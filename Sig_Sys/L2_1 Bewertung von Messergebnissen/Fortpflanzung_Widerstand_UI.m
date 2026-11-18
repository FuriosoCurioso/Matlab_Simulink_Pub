close all; clear all; clc;

%% Eingangsgrößen:
U  = 110e-3;    % Mittlere Spannung in V
uU = 0.2e-3;    % Unsicherheit der Spannung in V
I  = 90e-6;     % Mittlerer Strom in A
uI = 0.2e-6;    % Unsicherheit des Stromes in A

%% Mittelwert des Widerstandes bestimmen
% R = U / I → Ohmsches Gesetz
R = U / I

%% Messunsicherheit der indirekten Messung
% Quadratisches Fortpflanzungsgesetz für F = U/I:
% (uR/R)² = (uU/U)² + (uI/I)²  → uR = R * sqrt((uU/U)² + (uI/I)²)
uR = R * sqrt((uU/U)^2 + (uI/I)^2)

%% Ergebnis
disp(['Vollständiges Messergebnis: R = ',num2str(R),' ± ',num2str(uR),'Ω (k=1)'])