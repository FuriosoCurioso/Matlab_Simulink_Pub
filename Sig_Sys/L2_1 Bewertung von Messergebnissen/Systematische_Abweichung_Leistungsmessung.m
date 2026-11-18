close all; clear all; clc;

%% Eingangsgrößen:
RiA = 0.5; % Innenwiderstand des Strommessers in Ohm
RiV = 150; % Innenwiderstand des Spannungsmessers in Ohm
U = 1.25;  % gem. Spannung in V
I = 0.2;   % gem. Strom in A

%% Fehlerbehaftete Leistung
% P = U * I → Unberichtigtes Leistungsprodukt aus Messwerten
P = U * I
disp(['Das unberichtigte Ergebnis für die Leistungsmessung beträgt: ',num2str(P),' W'])

%% Berücksichtigung der Fehlerfortpflanzung
% Stromrichtige Schaltung: Voltmeter liegt außerhalb des Amperemeters
% → U_mess = U_RV + I*RiA, daher dP = I^2 * RiA (Verlustleistung am Strommesser)
dP = I^2 * RiA
disp(['Die systematische Abweichung der Leistungsmessung beträgt: ',num2str(dP*1000),' mW'])

%% Korrektur des systematischen Abweichung
% PK = P - dP → Korrektur um bekannte systematische Abweichung
PK = P - dP
disp(['Der um die bekannte systematische Abweichung korrigierte Wert der Leistung lautet: ',num2str(PK),' W'])