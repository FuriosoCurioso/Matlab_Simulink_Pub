clc; clear all; close all;
load('Messdaten_A4.mat') % Messdaten laden
mu0 = 3.5 % durchschnittliche Laufzeit in h

% Stichprobenumfang bestimmen
n = length(x) % Stichprobenumfang

% Mittelwert und Standardabweichung berechnen
xMean = mean(x)          % Mittelwert in h
s     = std(x)           % Stichprobenstandardabweichung in h (Nenner: n-1)

%% Prüfwert t bestimmen
tMin = (xMean - mu0) / (s / sqrt(n)) % Prüfwert t

%% t-Quantil berechnen
alpha = 0.05             % Signifikanzniveau 5 Prozent
p     = 1 - alpha/2      % Vertrauensniveau (zweiseitig: 0.975)
nu    = n - 1            % Freiheitsgrade

t = tinv(p, nu)          % t-Quantil berechnen (MATLAB Statistics Toolbox)

%% Ergebnis
if tMin < 0
    disp('Die Nullhypothese, dass der Erwartungswert der Laufzeit gleich 3,5 Stunden ist, zum Signifikanzniveau wird abgelehnt.')
    disp('Die Akkus laufen im Mittel nicht 3,5 Stunden, also mehr oder weniger.')
    H0 = false;
else
    disp('Die Nullhypothese, dass der Erwartungswert der Laufzeit gleich 3,5 Stunden ist, zum Signifikanzniveau wird angenommen.')
    disp('Die Akkus laufen im Mittel 3,5 Stunden.')
    H0 = true;
end;
%}

%% =========================================================
%  Zweiseitiger t-Test für den Erwartungswert
%  Schritt: Entspricht die mittlere Laufzeit der Akkus mu0 = 3,5 h?
%
%  Voraussetzung: Die Messwerte x sind in der Workspace-Variable x
%  geladen (z.B. via: load('Messdaten_A4.mat'))
%
%  Methode: Einstichproben-t-Test (Student'scher t-Test)
%  Die t-Verteilung wird verwendet, weil sigma (Populationsstreuung)
%  unbekannt ist und durch die Stichprobenstreuung s geschaetzt wird.
% =========================================================

%% --- Schritt 1: Referenzwert (Vergleichswert) festlegen ---

mu0 = 3.5;
% mu0 (griech. mu_0): der unter H0 angenommene Erwartungswert in Stunden.
% Dieser Wert stammt aus der Herstellerangabe und ist KEIN Messwert.
% Er ist der "Prüfwert", mit dem der gemessene Mittelwert verglichen wird.

%% --- Schritt 2: Stichprobenkenngroessen berechnen ---

n = length(x);
% length(x): gibt die Anzahl der Elemente im Vektor x zurueck.
% n ist der Stichprobenumfang – je groesser n, desto
% zuverlaessiger die Schaetzung des Erwartungswerts.
% FALLSTRICK: Ist x eine Matrix statt einem Vektor, gibt length()
% die groesste Dimension zurueck. Sicherer: n = numel(x).

xMean = mean(x);
% mean(x): berechnet den arithmetischen Mittelwert der Stichprobe.
% Formel: xMean = (1/n) * sum(x_i)  fuer i = 1..n
% xMean ist der beste Schaetzwert (Maximum-Likelihood-Schaetzer)
% fuer den unbekannten Erwartungswert mu der Grundgesamtheit.

s = std(x);
% std(x): berechnet die empirische Standardabweichung der Stichprobe.
% Formel: s = sqrt( sum((x_i - xMean)^2) / (n-1) )
%                                            ^^^^^
%                                            Nenner (n-1): Bessel-Korrektur!
% Warum (n-1) und nicht n?
%   Mit Nenner n wuerde s den wahren sigma systematisch unterschaetzen
%   (verzerrter Schaetzer). Der Nenner (n-1) liefert einen erwartungstreuen
%   Schaetzer fuer die Populationsvarianz sigma^2.
% FALLSTRICK: std(x, 1) verwendet Nenner n (populationsbasiert) –
%   fuer Stichprobentests immer std(x) bzw. std(x, 0) verwenden!

%% --- Schritt 3: Prüfgroesse (Teststatistik) berechnen ---

tMin = (xMean - mu0) / (s / sqrt(n));
% Formel des t-Prüfwertes:
%
%         xMean - mu0
%   t0 = -------------
%           s / sqrt(n)
%
% Interpretation der Formel:
%   - Zaehler (xMean - mu0): Abweichung des gemessenen Mittelwerts
%     vom Referenzwert. Je groesser diese Abweichung, desto mehr
%     spricht gegen H0.
%   - Nenner (s / sqrt(n)): Standardfehler des Mittelwerts (SEM).
%     Er gibt an, wie stark xMean aufgrund von Stichprobenvariation
%     schwankt. Mit wachsendem n wird der SEM kleiner – die Schaetzung
%     wird praeziser.
%   - Das Verhaeltnis t0 ist dimensionslos und t-verteilt mit (n-1)
%     Freiheitsgraden, sofern H0 wahr ist und x normalverteilt ist.
%
% FALLSTRICK: (s / sqrt(n)) darf nicht null sein. Bei n=1 oder
%   konstanten Messwerten gibt MATLAB Inf oder NaN zurueck.

%% --- Schritt 4: Kritischen Wert (t-Quantil) berechnen ---

alpha = 0.05;
% Das Signifikanzniveau alpha legt die maximal tolerierbare
% Wahrscheinlichkeit fuer einen Fehler 1. Art fest:
%   Fehler 1. Art: H0 wird abgelehnt, obwohl H0 wahr ist (False Positive).
% alpha = 0.05 bedeutet: In 5 % der Faelle wird eine wahre H0
% faelschlicherweise verworfen.
% Gaengige Werte: 0.05 (5%), 0.01 (1%), 0.001 (0.1%)

p = 1 - alpha/2;
% Fuer den ZWEISEITIGEN Test wird alpha auf beide Seiten der
% Verteilung aufgeteilt (alpha/2 je Seite).
% p = 1 - alpha/2 = 0.975 ist das Quantil, das den nicht-kritischen
% Bereich nach oben begrenzt.
%
%  Visualisierung (Dichtefunktion):
%
%        alpha/2 |              | alpha/2
%        -t_krit       0       +t_krit
%        <--- kritisch ->  <-- kritisch --->
%              Annahmebereich (1-alpha)
%
% FALLSTRICK: Fuer einen EINSEITIGEN Test gilt p = 1 - alpha (nicht alpha/2).

nu = n - 1;
% Freiheitsgrade (degrees of freedom) der t-Verteilung.
% Beim Einstichproben-t-Test: nu = n - 1
% Hintergrund: Durch Schaetzung von xMean aus den Daten geht ein
% Freiheitsgrad verloren. Mit steigendem nu naehert sich die
% t-Verteilung der Standardnormalverteilung an.

t = tinv(p, nu);
% tinv(p, nu): inverser CDF (Quantilfunktion) der t-Verteilung.
% Gibt den Wert t_krit zurueck, sodass gilt:
%   P(T <= t_krit) = p   unter der t-Verteilung mit nu Freiheitsgraden
%
% Beispiel: tinv(0.975, 9) = 2.2622  (fuer n=10, alpha=0.05)
% Das heisst: Unter H0 liegt der Prüfwert t0 mit 97.5% Wahrsch.
% unterhalb von 2.2622.
%
% FALLSTRICK: tinv gehoert zur Statistics and Machine Learning Toolbox.
%   Ohne Toolbox: t = icdf('t', p, nu)  oder Tabelle verwenden.
%   Alternative ohne Toolbox: norminv(p) als Naeherung fuer grosse n.

%% --- Schritt 5: Testentscheidung treffen ---

if tMin < 0
    % ANMERKUNG: Diese Fallunterscheidung ist vereinfacht!
    % Die korrekte zweiseitige Testbedingung lautet:
    %   H0 ablehnen, wenn |tMin| > t_krit
    % also:   abs(tMin) > t
    %
    % Hier wird nur auf tMin < 0 gecheckt (negatives Vorzeichen),
    % was nur dann zur richtigen Entscheidung fuehrt, wenn
    % xMean < mu0 und |tMin| implizit > t_krit.
    %
    % DIDAKTISCHE EMPFEHLUNG: Ersetze diese Bedingung durch:
    %   if abs(tMin) > t
    
    disp('Die Nullhypothese wird abgelehnt.')
    disp('Die Akkus laufen im Mittel nicht 3,5 Stunden.')
    % Interpretation: Die Abweichung zwischen xMean und mu0 ist so
    % gross, dass sie mit einer Wahrscheinlichkeit > (1 - alpha)
    % nicht durch Zufall erklaert werden kann.
    % Statistisch gesichert: mu ≠ mu0 auf Signifikanzniveau alpha = 5%.
    
    H0 = false;
    % H0 = false: boolesche Variable zur weiteren Verwendung im Skript.
    % Kein Standardausgabewert in MATLAB – aber sinnvoll fuer
    % Folgeberechnungen oder Schleifen ueber mehrere Datensaetze.
else
    disp('Die Nullhypothese wird beibehalten.')
    disp('Die Akkus laufen im Mittel 3,5 Stunden.')
    % WICHTIG: "Beibehalten" bedeutet NICHT "bewiesen"!
    % H0 kann mit diesem Test nie bewiesen werden – sie kann nur
    % nicht widerlegt werden (fehlende Evidenz ≠ Beweis der H0).
    
    H0 = true;
end

%% --- Schritt 6: Ergebnis grafisch nachvollziehen (optional) ---
%  Zum Verstaendnis empfehlenswert:
%
%  x_vals = linspace(-4, 4, 500);
%  plot(x_vals, tpdf(x_vals, nu), 'b-', 'LineWidth', 1.5);
%  hold on;
%  xline( t, 'r--', 't_{krit}');
%  xline(-t, 'r--', '-t_{krit}');
%  xline(tMin, 'g-', 't_0');
%  xlabel('t'); ylabel('Dichte'); title('t-Verteilung mit Prüfwert');
%  Liegt t_0 (grün) ausserhalb der roten Grenzen → H0 ablehnen.

%% --- Zusammenfassung der verwendeten Groessen ---
%
%  Variable  | Bedeutung                             | Einheit
%  ----------|---------------------------------------|--------
%  mu0       | Referenz-Erwartungswert (H0)          | h
%  n         | Stichprobenumfang                     | -
%  xMean     | Stichprobenmittelwert                 | h
%  s         | Stichprobenstandardabweichung (n-1)   | h
%  tMin      | Prüfwert (Teststatistik t0)           | -
%  alpha     | Signifikanzniveau (Fehler 1. Art)     | -
%  p         | Quantilswahrscheinlichkeit (zweiseit.)| -
%  nu        | Freiheitsgrade                        | -
%  t         | Kritischer Wert t_{krit}              | -
%  H0        | Testergebnis (true = beibehalten)     | logical