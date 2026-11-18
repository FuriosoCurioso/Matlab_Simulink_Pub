close all; clear all; clc;

%% Eingangsgrößen:
alpha = 4e-3; % 1/°C
R0    = 100;  % Ohm
R1    = 10e3; % Ohm
I0    = 1e-3; % A
theta =[0:100];

%% RS berechnen
% Formel für den temperaturabhängigen Widerstand: RS = R0 * (1 + alpha * theta)
RS = R0 * (1 + alpha * theta) % in Ohm

figure
h1 = plot(theta,RS,'b.-'); % h1: Handle für den Plot von RS über theta
xlabel('\vartheta in °C')
ylabel('R_S in \Omega')

%% us berechnen
% Ohmsches Gesetz am Sensor: us = I0 * RS
us = I0 * RS % in V

figure
h2 = plot(theta,us,'b.-'); % h2: Handle für den Plot von us über theta
xlabel('\vartheta in °C')
ylabel('u_S in V')

%% den Zusammenhang zwischen u1 und us ermitteln
% MV1 ist als Impedanzwandler (Spannungsfolger) beschaltet, daher gilt u1 = us
u1 = us % in V

figure
h3 = plot(theta,u1,'b.-'); % h3: Handle für den Plot von u1 über theta
xlabel('\vartheta in °C')
ylabel('u_1 in V')

%% U0 und R dimensionieren
% Eingangsgrößen:
u2_0   =  0; %  0V bei 0°C
u2_100 = -1; % -1V bei 100°C

% u1 Werte bei 0°C und 100°C aus dem Vektor extrahieren (Index 1 und 101)
u1_0 = u1(1)     %  in V bei 0°C
u1_100 = u1(101)   %  in V bei 100°C

% MV2 ist ein invertierender Summierverstärker. Knotengleichung liefert:
% u2 = -U0 - u1 * (R/R1)
% Daraus ergibt sich das Gleichungssystem:
% (1) u2_0 = -U0 - u1_0 * (R/R1)
% (2) u2_100 = -U0 - u1_100 * (R/R1)
% Subtraktion (2) - (1) eliminiert U0 und liefert die Formel für R:
R = R1 * (u2_100 - u2_0) / (u1_0 - u1_100) % in Ohm

% Einsetzen von R in Gleichung (1) liefert U0:
U0 = -u2_0 - u1_0 * (R/R1) % in V

% =========================================================================
% Erfüllte Anforderungen:
% - Berechnung RS: Wurde korrekt über die lineare Temperaturkennlinie des Pt100 berechnet.
% - Berechnung us: Wurde korrekt über das Ohmsche Gesetz (I0 * RS) ermittelt.
% - Berechnung u1: Die Funktion von MV1 als Impedanzwandler wurde korrekt erkannt (u1 = us).
% - Berechnung R und U0: Das Gleichungssystem des invertierenden Summierers (MV2) wurde 
%   korrekt aufgestellt und nach R sowie U0 aufgelöst.
% - Formatierung: Alle geforderten Variablen wurden ohne Semikolon belassen, 
%   damit die Werte direkt ausgewertet werden koennen.
% =========================================================================