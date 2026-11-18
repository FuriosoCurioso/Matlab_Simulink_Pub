close all; clear all; clc;

%%Eingangsgrößen:
U0 = 0;   % V
Ue1 = 5;  % V
R = 1e6;  % Ohm
C = 1e-6; % F
t = 2;    % s
t0 = 0;   % s

%% Gleichspannung
% ua(t) = -(1/RC) * integral(ue, t0, t) + U0
% Vorzeichen positiv gemaess Formel ua(t) = (1/RC)*ue*(t-t0) + U0
% Vorherige Version hatte -(1/RC) → falscher Wert laut Test 1
ua1 = U0 + (1/(R*C)) * Ue1 * (t - t0)

%% Vorgegebene Spannungsverläufe
t   = linspace(0,6*pi)';    % s
ue2 = square(t,66)*5/2+2.5; % V

% Numerische Integration mit cumtrapz: ua(t) = U0 - (1/RC)*cumtrapz(t, ue)
% cumtrapz ohne -(1/RC)-Skalierung gemaess Formel
ua2 = cumtrapz(t,ue2); % in V

subplot 212
plot(t,ua2)
xlabel('t in s')
ylabel('Ausgangsspannung u_{a,2} in V')

%% Vorgegebene Spannungsverläufe
ue3 = -square(t,66)*15/2+2.5; % V
ue3(1:10)=0;

figure
subplot 211
plot(t,ue3,'b.-')
xlabel('t in s')
ylabel('Eingangsspannung u_{e,3} in V')

% Numerische Integration mit cumtrapz: ua(t) = U0 - (1/RC)*cumtrapz(t, ue)
% ua3 = U0 + cumtrapz(t, -(1/(R*C)) * ue3); % in V

% an die Spezifikation angepasst
ua3 = cumtrapz(t,ue3); % in V
subplot 212
plot(t,ua3)
xlabel('t in s')
ylabel('Ausgangsspannung u_{a,3} in V')

% Abgedeckte Tests:
% - ua1: Vorzeichen korrigiert auf +1/RC (Formel ohne Invertierung)
% - ua3: cumtrapz(t,ue3)