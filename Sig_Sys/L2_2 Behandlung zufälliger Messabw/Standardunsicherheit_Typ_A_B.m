

close all; clear all; clc;
%% Eingangsgrößen: sind die bekannten systematischen Abweichungen
n = 30; % Anzahl Messungen
mR = 111.712; % Mittelwert der Messwerte in Ohm
sR = 0.001643; % Standardabweichung der Messwerte in Ohm
a = 0.0240; % +/- Garantiefehlerschranke des Ohm-Meters (gleichverteilt) in Ohm

% Vierleitertechnik: Leitungswiderstände werden kompensiert → As,b = 0
As_b = 0; % bekannte systematische Abweichung in Ohm

%% Bester Schätzwert des Widerstandes
% Rmean = mR - As_b  →  da As_b = 0 gilt Rmean = mR
Rmean = mR - As_b % in Ohm

% Empirische Standardabweichung
% Eingangsgrößen: sR ist die Standardabweichung der Einzelmesswerte
s = sR;
disp(['Empirische Standardabweichung : s = ',sprintf('%0.3f',s),' Ohm'])

%% Standardunsicherheit Typ A
alpha = 5; % Prozent  →  Irrtumswahrscheinlichkeit für 95%-Vertrauensbereich
p = 1 - alpha/100; % statistische Sicherheit P = 0.95

% t-Vektor für alle Freiheitsgrade  ν = 1..n-1  via tinv (zweiseitig)
% tinv(1-alpha/2, nu)  →  Student-t-Wert für zweiseitigen Vertrauensbereich
t = tinv(1 - alpha/100/2, 1:n-1);  % Vektor der Länge n-1
disp(['Vertrauensfaktor : t(29) = ',num2str(t(n-1))])

% uA = s/sqrt(n)  →  Standardunsicherheit des Mittelwertes (Typ A nach GUM)
uA = s / sqrt(n) % Unsicherheit Typ A
disp(['Unsicherheit Typ A : uA = ',sprintf('%0.4f',uA),' Ohm'])

%% Standardunsicherheit Typ B
% Gleichverteilung: uB = a/sqrt(3)  →  Unsicherheit der Fehlerschranke
uB = a / sqrt(3) % Unsicherheit der Fehlerschranke
disp(['Unsicherheit unter Berücksichtigung von angegebenen Fehlerschranke : uB = ',sprintf('%0.3f',uB),' Ohm'])

%% Kombinierte Standardunsicherheit Typ C
% uC = sqrt(uA² + uB²)  →  quadratische Kombination nicht korrelierter Anteile
uC = sqrt(uA^2 + uB^2) % Unsicherheit Typ C
disp(['e) kombinierte Standardunsicherheit Typ C : uC = ',sprintf('%0.3f',uC),' Ohm'])

%% Vollständiges Messergebnis
% Vertrauensfaktor
k = 2; % Vertrauensfaktor ohne speziellen Verwendungszweck: k=2 (≈95%)
disp(['f) Vertrauensfaktor ohne Angabe eines speziellen Verwendungszwecks : k = ',num2str(k)])

% uAbs = k * uC  →  erweiterte (absolute) Messunsicherheit
uAbs = k * uC % absolute Messunsicherheit
disp(['g) absolute Messunsicherheit : U = ',sprintf('%0.3f',uAbs),' Ohm (k=',num2str(k),')'])

% uRel = (uAbs / Rmean) * 100  →  relative Messunsicherheit in %
uRel = (uAbs / Rmean) * 100 % relative Messunsicherheit in %
disp(['g) relative Messunsicherheit : U = ',sprintf('%0.3f',uRel),' % (k=',num2str(k),')'])

%% Ergebnisdarstellung
xPlot = 1:n;  % x-Achse: Anzahl der Messwerte

figure
hold on
% Mittelwert als horizontale Linie
hMean = plot(xPlot, Rmean * ones(1,n), 'r-', 'LineWidth', 1.5); % Mittelwert-Linie (rot)
% Unsicherheitsband ±uAbs um Mittelwert (Typ C, erweitert)
hUC   = plot(xPlot, (Rmean + uAbs) * ones(1,n), 'b-', 'LineWidth', 1.5); % obere Grenze
plot(xPlot, (Rmean - uAbs) * ones(1,n), 'b-', 'LineWidth', 1.5); % untere Grenze
hold off

xlabel('Anzahl der Messwerte')
ylabel('Widerstand in \Omega')

% Titel mit vollständigem Messergebnis (relativ und absolut)
title(['Messergebnis : R = ',sprintf('%0.3f',Rmean),' \pm ',sprintf('%0.5f',uAbs),...
    ' \Omega = ',sprintf('%0.3f',Rmean),'\Omega \pm ',sprintf('%0.6f',uRel),'%'],...
    'FontWeight','bold')

legend([hMean, hUC], {'Mittelwert', 'Unsicherheit Typ C'})