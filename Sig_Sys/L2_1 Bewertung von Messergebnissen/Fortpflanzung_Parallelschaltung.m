close all; clear all; clc;

%% Eingangsgrößen: in Ohm
R1 = 100; 
R2 = 150; 
uR1 = 2; 
uR2 = 3; 


%% Leitwerte
% Schritt: Leitwerte der beiden Widerstände berechnen
% G = 1/R → Leitwert aus Widerstand
G1 = 1/R1
G2 = 1/R2


%% die relativen Unsicherheiten von R und G sind identisch
% Schritt: Unsicherheiten der Leitwerte berechnen
% uG/G = uR/R → uG = G*(uR/R)
uG1 = G1*(uR1/R1)
uG2 = G2*(uR2/R2)


%% Ergebnis
disp(['Vollständiges Messergebnis: G1 = ',num2str(G1),' S ± ',num2str(uG1),' S (k=1)'] )
disp(['Vollständiges Messergebnis: G2 = ',num2str(G2),' S ± ',num2str(uG2),' S (k=1)'] )


%% Parallelschaltung
% Schritt: Gesamtleitwert und Unsicherheit der Parallelschaltung berechnen
% G = G1 + G2 → Leitwerte in Parallelschaltung addieren sich
G = G1 + G2;
% Schritt: Vertrauensfaktor für 95% setzen
% k = 2 → 95% Vertrauensbereich
k=2;
% Schritt: Erweiterte Unsicherheit des Gesamtleitwerts berechnen
% uG = k*sqrt(uG1^2 + uG2^2) → GUM für unkorrelierte Größen
uG = k*sqrt(uG1^2 + uG2^2);
disp(['Vollständiges Messergebnis: G = ',num2str(G*1000),' mS ± ',num2str(uG*1000),' mS (k=2)'] )


%% Leitwert berechnen
% Schritt: resultierenden Widerstand und seine Unsicherheit berechnen
% R = 1/G → Widerstand aus Gesamtleitwert
R = 1/G;
% uR/R = uG/G → uR = R*(uG/G)
uR = R*(uG/G);
disp(['Vollständiges Messergebnis: R = ',num2str(R),' Ω ± ',num2str(uR),' Ω (k=2)'] )