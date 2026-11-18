close all; clear all; clc;

%% Eingangsgrößen:
R1 = 1000; % in Ohm
U1 = 0.9028; % in V
UPT = 97.23e-3; % in V


u_UPT = 0; % in der vorläufigen Annahme, dass die Messung von UPT exakt ist.(uc Voltmeter =0)
u_R1 = 0.001; % in Ohm
u_U1 = 0.0012; % in V


a0R0 = 0.385; % in Ohm/°C, Sensitivität PT100
R0 = 100; % in Ohm, RPT(0°C), Referenzwiderstand bei 0°C LÖSUNG bitte anpassen.


%% Lösungen
%% Schritt a)
% Schritt a): Mittleren Platinwiderstand RPT berechnen
% RPT = R1*UPT/U1 → Spannungsteiler mit Serienwiderstand R1
RPT = R1*UPT/U1; % in Ohm LÖSUNG bitte anpassen.
% Schritt a): Messunsicherheit uC_RPT des Platinwiderstands berechnen
% uC_RPT = sqrt((dRPT/dR1*u_R1)^2 + (dRPT/dU1*u_U1)^2 + (dRPT/dUPT*u_UPT)^2) → Gaußsche Fortpflanzung
uC_RPT = sqrt(((UPT/U1)*u_R1)^2 + ((-R1*UPT/U1^2)*u_U1)^2 + ((R1/U1)*u_UPT)^2); % in Ohm, Messunsicherheit LÖSUNG bitte anpassen.


%% Schritt b)
% Schritt b): Relative Messunsicherheit uARel_RPT vorgeben
% uARel_RPT = 2/1000 → 2 Promille als dimensionslose relative Unsicherheit
uARel_RPT = 2/1000; % LÖSUNG bitte anpassen.
% Schritt b): Messunsicherheit uC_UPT der Spannung am Platinwiderstand berechnen
% uC_UPT = (U1/R1)*sqrt((uARel_RPT*RPT)^2 - ((UPT/U1)*u_R1)^2 - ((R1*UPT/U1^2)*u_U1)^2) → nach u_UPT umgestellt
uC_UPT = (U1/R1)*sqrt((uARel_RPT*RPT)^2 - ((UPT/U1)*u_R1)^2 - ((R1*UPT/U1^2)*u_U1)^2); % in V, Messunsicherheit LÖSUNG bitte anpassen.


%% Schritt c)
% Schritt c): Temperatur theta bestimmen
% theta = (RPT - R0)/(a0R0) → lineare Approximation des PT100 im Bereich 0°C bis 100°C
theta = (RPT - R0)/a0R0; % in °C, aktuelle Temperatur LÖSUNG bitte anpassen.
% Schritt c): Unsicherheit uB_RPT aus Toleranzklasse B bestimmen
% uB_RPT = sqrt(((0.12)^2 + (0.0018*theta)^2)/3) → Rechteckverteilung der Toleranzklasse B
uB_RPT = sqrt((0.12^2 + (0.0018*theta)^2)/3); % in Ohm LÖSUNG bitte anpassen.


%% Schritt d)
% Schritt d): Betrag der Unsicherheit uC_RPT2 des Widerstandes bestimmen
% uC_RPT2 = uARel_RPT*RPT → absolute Unsicherheit aus relativer Unsicherheit
uC_RPT2 = uARel_RPT*RPT; % in Ohm, Messunsicherheit LÖSUNG bitte anpassen.
% Schritt d): Messunsicherheit uA_RPT des Widerstandes bestimmen
% uA_RPT = uC_RPT2 → gleiche absolute Unsicherheit des Widerstandes
uA_RPT = uC_RPT2; % in Ohm, Messunsicherheit LÖSUNG bitte anpassen.
% Schritt d): Messunsicherheit uB und uC kombiniert bestimmen
% uC_RPT3 = sqrt(uC_RPT2^2 + uB_RPT^2) → kombinierte Standardunsicherheit
uC_RPT3 = sqrt(uC_RPT2^2 + uB_RPT^2); % in Ohm, Messunsicherheit uB und uC kombiniert LÖSUNG bitte anpassen.
% Schritt d): Messunsicherheit der Temperatur bestimmen
% u_theta = abs(dtheta/dRPT)*uC_RPT3 = (1/(a0R0))*uC_RPT3 → lineare Fehlerfortpflanzung
u_theta = (1/a0R0) * uC_RPT3 % in °C, Messunsicherheit der Temperatur (lineare Fehlerfortpflanzung)

%% Vollständiges Messergebnis angeben
disp(['ϑ = ',num2str(theta),'°C ± ',num2str(2*u_theta),'°C (k=2)'])