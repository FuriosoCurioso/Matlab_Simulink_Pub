close all; clear all; clc;

%% Eingangsgrößen:
U0 = 0;    % V
Ue1 = 5;   % V
R = 1e6;   % Ohm
C = 1e-6;  % F
t = 2;     % s
t0 = 0;    % s


%% Gleichspannung
% Analytische Lösung des OP-Integrators für Gleichspannung:
% ua(t) = U0 - (1/RC) * Ue1 * (t - t0)
ua1 = U0 - (1/(R*C)) * Ue1 * (t - t0)


%% Vorgegebene Spannungsverläufe
t = linspace(0,6*pi)'; % s
ue2 = square(t,66)*5/2+2.5; % V


figure
subplot 211
plot(t,ue2,'b.-')
xlabel('t in s')
ylabel('Eingangsspannung u_{e,2} in V')


% ua2: numerische Integration mit cumtrapz (aus Spezifikation)
% ua(t) = U0 - (1/RC) * integral(ue2, t0..t)
ua2 = U0 - (1/(R*C)) * cumtrapz(t, ue2) % in V
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


% ua3: numerische Integration mit cumtrapz (Tipp aus Spezifikation)
% ua(t) = U0 - (1/RC) * integral(ue3, t0..t)
ua3 = U0 - (1/(R*C)) * cumtrapz(t, ue3) % in V
subplot 212
plot(t,ua3)
xlabel('t in s')
ylabel('Ausgangsspannung u_{a,3} in V')