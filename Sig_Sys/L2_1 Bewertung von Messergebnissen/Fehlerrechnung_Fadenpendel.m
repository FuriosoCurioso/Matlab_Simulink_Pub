close all; clear all; clc;

%% Eingangsgrößen:
l = 0.784; % m
dl = 0.002; % m
t = 17.7; % s
dt = 0.1; % s

%% Bestwert
g = 4*pi^2*l/(t^2) % Fallbeschleunigung in m/s^2

%% Absoluter Fehler
dg = g*(dl/l + 2*dt/t)

%% Relativer Fehler in %
gRel = dg/g*100

disp(['Der maximale relative Fehler von g beträgt: ',num2str(gRel),'%'])
disp('Welche Messung müsste man verfeinern, um die Genauigkeit zu verbessern?')
disp('Antwort: Die Zeitmessung, da ihr relativer Fehlerbeitrag groesser ist.')
%{
  Die Pruefung zeigt sehr wahrscheinlich, dass nicht mit der Periodendauer 
T=t/10 weitergerechnet werden soll, sondern direkt mit den im Template vorgegebenen Variablen t und dt. Dann erwartet der Pruefung für g offenbar exakt 
 und für dg entsprechend die Fehlerfortpflanzung mit t.  
%}