close all; clear all; clc;
    
%% Eingangsgrößen:
R1 = 99000; % Ohm
R2 = 1000;  % Ohm

%% die Verstärkung berechnen
% k = 1 + R1/R2 (nichtinvertierender Spannungsverstärker)
k = 1 + R1/R2

%% Wie groß ist die tatsächliche Verstärkung kreal
dR1 = 4000;  %Ohm
dR2 = -30;   %Ohm

% GEÄNDERT: Bezugsgröße ist der Nominalwert k (nicht kreal).
% eRel2 = dk / k * 100 (lineare Näherung des relativen Fehlers in %)
eRel2 = dk / k * 100

% Bezugsgröße ist der Nominalwert k (nicht kreal).
% Messtechnische Konvention: eRel = (kreal - k) / k * 100
% Vorzeichen bleibt erhalten (kein abs), Wert in %
eRel = (kreal - k) / k * 100

%% Lineare Näherung
% dk = (dk/dR1)*dR1 + (dk/dR2)*dR2
% dk/dR1 =  1/R2
% dk/dR2 = -R1/R2^2
dk = (1/R2)*dR1 + (-R1/R2^2)*dR2

% Bezugsgröße ist der Nominalwert k (nicht kreal).
% eRel2 = dk / k * 100 (lineare Näherung des relativen Fehlers in %)
eRel2 = dk / k * 100

%% Messunsicherheit
s1 = dR1;
s2 = 30; % Ohm

% u: 68,3%-Messunsicherheit (1-sigma, Gaußsche Fehlerfortpflanzung)
% u = sqrt( (dk/dR1)^2 * s1^2 + (dk/dR2)^2 * s2^2 )
u = sqrt( (1/R2)^2 * s1^2 + (R1/R2^2)^2 * s2^2 )

disp(['Vollständiges Messergebnis: k = ',num2str(k),' ± ',num2str(round(u))])

%% Spannungsfolger/Impedanzwandler
% Spannungsfolger: k = 1, R2 --> inf (offen), R1 = 0 (Kurzschluss)
kSoll   = 1
R1Soll  = 0
R2Soll  = Inf
%}


%{
%% Messverstaerker zur Messung von Spannungen

%% Eingangsgrößen:
R1 = 99000; % Ohm
R2 = 1000;  % Ohm

%% die Verstaerkung berechnen
% Verstaerkung des nichtinvertierenden OP-Verstaerkers
% k = 1 + R1/R2
k = 1 + R1/R2

%% Wie gross ist die tatsaechliche Verstaerkung kreal
dR1 = 400 % Ohm
dR2 = -30 % Ohm

% Tatsaechliche Verstaerkung mit abweichenden Widerstandswerten
% kreal = 1 + (R1 + dR1)/(R2 + dR2)
kreal = 1 + (R1 + dR1)/(R2 + dR2)

% Relativer Fehler der tatsaechlichen Verstaerkung in Prozent
% eRel = ((kreal - k)/k)*100
eRel = ((kreal - k)/k)*100

%% Lineare Naeherung
% Linear genäherter absoluter Fehler der Verstaerkung
% dk = (partial k/partial R1)*dR1 + (partial k/partial R2)*dR2
% partial k/partial R1 = 1/R2, partial k/partial R2 = -R1/R2^2
dk = (1/R2)*dR1 - (R1/R2^2)*dR2

% Relativer Fehler der linearen Naeherung in Prozent
% eRel2 = (dk/k)*100
eRel2 = (dk/k)*100

%% Messunsicherheit
s1 = dR1
s2 = 30; % Ohm

% Messunsicherheit der Verstaerkung durch Fehlerfortpflanzung
% u = sqrt(((partial k/partial R1)*s1)^2 + ((partial k/partial R2)*s2)^2)
u = sqrt(((1/R2)*s1)^2 + ((-R1/R2^2)*s2)^2)

disp(['Vollständiges Messergebnis: k = ',num2str(k),' ± ',num2str(round(u))])

%% Spannungsfolger/Impedanzwandler
% Spannungsfolger mit Verstaerkung 1
% kSoll = 1
kSoll = 1 % Verstaerkung

% Rueckkopplung als Kurzschluss fuer den Spannungsfolger
R1Soll = 0 % Ohm

% Kein Widerstand nach Masse, offener Zweig
R2Soll = Inf % Ohm
    %}