close all; clear all; clc;

%% Messdaten laden - Diese ZEILE NICHT VERÄNDRERN!
% Die Messung wird simuliert von messeWiderstand.p
Rm = messeWiderstand(); % Messwerte in Ohm
whos
% Anzahl der Messwerte bestimmen
% n = length(Rm) → Anzahl der Elemente im Messwertearray
n = length(Rm) % Anzahl Messungen

%% Bester Schätzwert des Widerstandes berechnen
% R = mean(Rm) → Arithmetischer Mittelwert als bester Schätzwert
R = mean(Rm) % Mittelwert der Messwerte

%% Empirische Standardabweichung bestimmen
% s = std(Rm) → Empirische Standardabweichung der Stichprobe (Nenner n-1)
s = std(Rm)

%% Standardunsicherheit Typ A bestimmen
% uA = s/sqrt(n) → Standardunsicherheit Typ A nach GUM
t = tinv((1+0.683)/2,n-1);
uA = t*s/sqrt(n)


%% Standardunsicherheit Typ B bestimmen
% uE = (0.012*R)/sqrt(3) → Empfindlichkeitsabweichung 1,2% vom Messwert, Rechteckverteilung
uE = (0.012 * R) / sqrt(3) % Berücksichtigung von Empfindlichkeitsabweichung
% uN = (2*0.1)/sqrt(3) → Nullpunktabweichung 2 Digits × 0,1 Ω/Digit, Rechteckverteilung
uN = (2 * 0.1) / sqrt(3) % Berücksichtigung von Nullpunktabweichung
% uB = sqrt(uE^2+uN^2) → Quadratische Kombination beider Typ-B-Anteile
uB = sqrt(uE^2 + uN^2) % Unsicherheit Typ B

%% Kombinierte Standardunsicherheit Typ C bestimmen
% uC = sqrt(uA^2+uB^2) → Quadratische Kombination Typ A und Typ B
uC = sqrt(uA^2 + uB^2) % Unsicherheit Typ C

%% Grad des Vertrauens bestimmen
% k = tinv(0.975, n-1) → Vertrauensfaktor aus t-Verteilung, P=95%, zweiseitig, Endkontrolle
k = tinv(0.975, n - 1) % Vertrauensfaktor

%% Vollständiges Messergebnis anzeigen
% uAbs = k*uC → Erweiterte absolute Messunsicherheit
uAbs = k * uC % absolute Messunsicherheit
% uRel = (uAbs/R)*100 → Relative Messunsicherheit in Prozent
uRel = (uAbs / R) * 100 % relative Messunsicherheit

%% Ergebnisdarstellung
figure;
% p1: Handle auf Messwerte-Linie (rot, Sternmarker) → Zugriff für Legende
p1 = plot(1:n, Rm, 'r-*');
hold on;
% p2: Handle auf Mittelwert-Linie (schwarz) → Zugriff für Legende
p2 = yline(R, 'k-');
% p3: Handle auf obere Unsicherheitsgrenze (cyan) → Zugriff für Legende
p3 = yline(R + uAbs, 'c-');
% Untere Unsicherheitsgrenze (cyan, kein eigener Legendeneintrag)
yline(R - uAbs, 'c-');
xlabel('Anzahl der Messwerte');
ylabel('Widerstand in Ω');
title(['Messergebnis : R = ', num2str(R), ' ± ', num2str(uAbs), ...
       ' Ω = ', num2str(R), 'Ω ± ', num2str(uRel), '%']);
legend([p1, p2, p3], 'Messwerte', 'Mittelwert', 'Unsicherheit Typ C');