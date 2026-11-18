%{
Strukturübersicht der Methodenbibliothek:
AbschnittVerfahrenKernformelBesonderheitA1Lineare Regression + KonfidenzbandY ± t·s·√(1/n + (X-x̄)²/((n-1)·sxx))95%- und 99%-Band, cov()A2Empfindlichkeitskoeffizientuac = t·s/(sx·√n)Substitution y = C/C0 - 1, alternative Restvarianz v = (syy - b1·sxy)/(n-2)A3Linearisierung Exponentialfunktionln(uC) = ln(UC0) - t/τ → C = τ/Rlog()-Transformation, Rückrechnung auf physikalische GrößeA4Residuenanalysee = Y - y5 Standardgraphen zur ModellvalidierungA5Lineare Regression (manuell)sxx = Σ(xi-x̄)²/(n-1)Explizite Summenformel statt cov()A6Quadratische RegressionA·[a;b;c] = rhs → A\rhs3×3-Normalgleichungssystem, \-Operator
Querverweise im Code:

A2, A3, A5 verweisen bei Kovarianz/Koeffizienten auf A1 (keine Formeldopplung).
A6 erweitert A5 konzeptionell von Grad 1 auf Grad 2.
A4 ist methodisch unabhängig und auf beliebige Regressionsergebnisse anwendbar.
%}

%% A1: Lineare Regression – Druck vs. Dickenreduktion mit Konfidenzband
% Was:  MKQ-Regression y(x) = b0 + b1*x mit 95%- und 99%-Konfidenzband
% Wie:  Kovarianzmatrix → b1, b0 → Restvarianz → t-Quantile → Bandbreite
% Warum: Quantifizierung des linearen Zusammenhangs Druck↔Dicke
%        inkl. statistischer Unsicherheit der Regressionsgeraden

% Eingangsgrößen:
p = [1:5]*0.1;        % Druck in bar
d = [1 1 2 2 4]*1e-2; % Dicke in m

% Allgemeine Schreibweise
x=p; y=d;

% Kovarianzmatrix berechnen (2x2 Matrix)
% cov(x,y) liefert [sxx sxy; sxy syy] mit Bessel-Korrektur (1/(n-1))
Kovarianzmatrix = cov(x,y)

sxx = Kovarianzmatrix(1,1)
syy = Kovarianzmatrix(2,2)
sxy = Kovarianzmatrix(1,2)

% Steigung b1 und y-Achsenabschnitt b0 berechnen
% b1 = sxy/sxx  →  MKQ-Schätzer der Steigung
% b0 = ȳ - b1·x̄  →  Gerade durch Schwerpunkt (x̄, ȳ)
b1 = sxy / sxx
b0 = mean(y) - b1 * mean(x)

% Regressionsgerade an den Messstellen
Y = b0 + b1 * x

% Restvarianz und Standardabweichung
% s² = 1/(n-2) · Σ(yi - Yi)²  →  erwartungstreue Schätzung, FG = n-2
n  = length(x)
s2 = sum((y - Y).^2) / (n - 2)
s = sqrt(s2);

% t-Quantile für zweiseitige Vertrauensbereiche
% t_{n-2; 1-α/2}  →  Student-t-Verteilung mit n-2 Freiheitsgraden
alpha = 0.05;
p = 1 - alpha/2;
t = tinv(p, n-2);
t95= t

alpha = 0.01;
p = 1 - alpha/2;
t = tinv(p, n-2);
t99= t

% Regressionsgerade für kontinuierliche Darstellung
X = [0:0.01:0.6];
Y = mean(y)+b1*(X-mean(x));

% Konfidenzband: Y ± t · s · sqrt(1/n + (X - x̄)² / ((n-1)·sxx))
% (n-1)·sxx ≡ Σ(xi - x̄)²  →  Summe der Abweichungsquadrate
t = t95;
y_min95 = Y - t * s * sqrt(1/n + (X - mean(x)).^2 / ((n-1)*sxx))
y_max95 = Y + t * s * sqrt(1/n + (X - mean(x)).^2 / ((n-1)*sxx))

t = t99;
y_min99 = Y - t * s * sqrt(1/n + (X - mean(x)).^2 / ((n-1)*sxx))
y_max99 = Y + t * s * sqrt(1/n + (X - mean(x)).^2 / ((n-1)*sxx))

% Ergebnisdarstellung
figure
hold on
h1=plot(x,y,'r*')
h2=plot(mean(x),mean(y),'ko')
h3=plot(X,Y,'b-')
h4=plot(X,y_min95,'k--')
plot(X,y_max95,'k--')
h5=plot(X,y_min99,'m--')
plot(X,y_max99,'m--')
legend([h1,h2,h3,h4,h5],'Messwerte','Schwerpunkt','Regressiongerade','P=95% Konfidenzinterval','P=99% Konfidenzinterval')
xlabel('Druck in bar')
ylabel('Dickenreduktion in m')

%% A2: Empfindlichkeitskoeffizient – Temperatur vs. Kapazität
% Was:  Bestimmung des Temperaturkoeffizienten ac eines Kondensators
% Wie:  Substitution y = C/C0 - 1, x = T - T0 → lineare Regression
%       → ac = b1 (Steigung) mit Unsicherheit uac
% Warum: ac beschreibt die relative Kapazitätsänderung pro Kelvin;
%        Unsicherheit uac quantifiziert die Zuverlässigkeit des Schätzwerts

close all; clear all; clc;

% Eingangsgrößen:
T  = [0:5:35];
C  = [71.34 70.51 69.72 68.84 68.05 67.19 66.34 65.42]*1e-9; % Kapazität in F
C0 = 68e-9;  % Nennkapazität in F
T0 = 20;     % Nenntemperatur in °C

% Substitution für Geradengleichung y = b1*x + b0
x = T - T0;       % Temperaturdifferenz zur Nenntemperatur in °C
y = C / C0 - 1;   % normiertes Kapazitätsverhältnis (dimensionslos)

% Kovarianzmatrix, Varianzen, Kovarianz → vgl. Formeln in A1
Kovarianzmatrix = cov(x, y);
sxx = Kovarianzmatrix(1,1)
syy = Kovarianzmatrix(2,2)
sxy = Kovarianzmatrix(1,2)

% Regressionskoeffizienten → Formeln siehe A1
b1 = sxy / sxx
b0 = mean(y) - b1 * mean(x)

y_reg = b1 * x + b0;

% Empfindlichkeitskoeffizient: ac = b1 = Δ(C/C0 - 1)/ΔT  in 1/°C
ac = b1

plot(x, y,     'b*')
hold on
plot(x, y_reg, 'r.-')
xlabel('Temperaturdifferenz in °C')
ylabel('Kapazitätsverhältnis (C/C_0)-1')

% Restvarianz – alternative Formel: v = (syy - b1·sxy)/(n-2)
% Mathematisch äquivalent zu s² = Σ(yi-Yi)²/(n-2), vermeidet explizite Y-Berechnung
n = length(x);
v = (1/(n-2)) * (syy - b1 * sxy)
s = sqrt(v);

% t-Quantil für α = 0.05
t95 = tinv(1 - 0.05/2, n-2)

% Unsicherheit der Steigung: u_b1 = t · s / (sx · √n)
% sx = std(x) mit Bessel-Korrektur
sx = std(x)
uac = t95 * s / (sx * sqrt(n))

disp(['ac = ', num2str(ac), ' 1/°C ± ', num2str(uac), ' 1/°C; P=95%'])

%% A3: RC-Entladekurve – Linearisierung und Kapazitätsbestimmung
% Was:  Bestimmung der Kapazität C aus einer Entladekurve uC(t)
% Wie:  Modell: uC(t) = UC0 · exp(-t/Tau)
%       Linearisierung: ln(uC) = ln(UC0) - t/Tau  →  y = b0 + b1·x
%       mit b1 = -1/Tau, b0 = ln(UC0)  →  Tau = -1/b1  →  C = Tau/R
% Warum: Exponentielles Modell wird durch ln-Transformation auf
%        lineares Modell zurückgeführt → MKQ-Regression anwendbar

close all; clear all; clc;

% Eingangsgrößen:
t  = [0 0.199 1.01]*1e-6  % Zeit in s
uC = [9.93 8.2 3.5]       % Kondensatorspannung in V
R  = 1e3                   % Widerstand in Ohm

% Linearisierung: ln(uC) = ln(UC0) - t/Tau
x = t
y = log(uC)    % Natürlicher Logarithmus

% Kovarianzmatrix → Formeln siehe A1
Kovarianzmatrix = cov(x, y)

sxx = Kovarianzmatrix(1,1)
syy = Kovarianzmatrix(2,2)
sxy = Kovarianzmatrix(1,2)

% Regressionskoeffizienten → Formeln siehe A1
b1 = sxy / sxx
b0 = mean(y) - b1 * mean(x)

% Rückrechnung auf physikalische Größen
% b1 = -1/Tau  →  Tau = -1/b1  (Zeitkonstante in s)
Tau = -1 / b1
% C = Tau/R  →  aus Tau = R·C
C = Tau / R

%% A4: Graphische Residuenanalyse
% Was:  Visuelle Überprüfung der Modellannahmen anhand von 5 Standardgraphen
% Wie:  Residuen e = Y - y berechnen und in verschiedenen Darstellungen prüfen
% Warum: Prüfung auf Normalverteilung, Linearität, Homoskedastizität,
%        Unabhängigkeit – Voraussetzungen der MKQ-Regression
%
%  Graph 1: Histogramm          → Normalverteilung der Residuen?
%  Graph 2: Y vs. y             → Punkte auf Winkelhalbierender?
%  Graph 3: e vs. x             → Zufällige Streuung um Null?
%  Graph 4: e vs. Versuchsnr.   → Kein Trend über die Zeit?
%  Graph 5: e vs. Y             → Keine Trichterform (Heteroskedastizität)?

close all; clear all; clc;

load('Residuen.mat')
whos

Y = b1*x+b0  % Regressionsgerade (b0, b1 aus Datei)

e = Y - y  % Residuen

n = length(x)

% Histogramm der Residuen
figure
h = histogram(e,10);
title('1) Histogramm der Residuen')
xlabel('Residuen e')
ylabel('Häufigkeit')

% Berechnete vs. beobachtete Werte
figure;
plot(y,Y,'bo');
hold on;
plot([min(Y) max(Y)], [min(Y) max(Y)], 'r-');
title('2) Berechnete vs. beobachtete Werte');
xlabel('Berechnete Werte Y');
ylabel('Beobachtete Werte y');

% Residuen vs. Einflussgröße x
figure;
plot(x, e, 'bo');
hold on;
plot([min(x) max(x)], [0 0], 'r--');
title('3) Residuen vs. Einflussgröße x');
xlabel('Einflussgröße x');
ylabel('Residuen e');

% Residuen vs. Versuchsnummer
figure;
plot(1:n, e, 'bo');
hold on;
plot([1 n], [0 0], 'r--');
title('4) Residuen vs. Versuchsnummer');
xlabel('Versuchsnummer');
ylabel('Residuen e');

% Residuen vs. berechnete Zielgröße
figure;
plot(Y, e, 'bo');
hold on;
plot([min(Y) max(Y)], [0 0], 'r--');
title('5) Residuen vs. berechnete Zielgröße Y');
xlabel('Berechnete Zielgröße Y');
ylabel('Residuen e');

disp('Fazit: Die graphische Beurteilung der Residuen dient der Überprüfung der Modellannahmen (Normalverteilung, Linearität, Homoskedastizität und Unabhängigkeit).');

%% A5: Lineare Regression aus Messdatei (manuelle Varianzberechnung)
% Was:  Lineare Regression U → Distanz mit manueller Berechnung der Varianzen
% Wie:  sxx, syy, sxy explizit über Summenformeln statt cov()-Funktion
%       sxx = 1/(n-1) · Σ(xi - x̄)²  →  identisch zu cov(x,x)
% Warum: Verdeutlicht die Äquivalenz zwischen cov()-Aufruf (A1–A3)
%        und der expliziten Summenformel

close all; clear all; clc;

load('Daten_2_1.mat')

x = U_in_V;
y = Distanz_in_cm;

figure
hold on
plot(x, y, 'r.')

n = length(x);

% Varianz/Kovarianz manuell (Bessel-Korrektur, 1/(n-1))
sxx = sum((x - mean(x)).^2) / (n - 1)
syy = sum((y - mean(y)).^2) / (n - 1)
sxy = sum((x - mean(x)) .* (y - mean(y))) / (n - 1)

% Regressionskoeffizienten → Formeln siehe A1
b1 = sxy / sxx
b0 = mean(y) - b1 * mean(x)

Y = b1*x+b0;
plot(x, Y, 'b-', 'LineWidth', 3)
xlabel('U in V')
ylabel('Distanz in cm')
legend('Messwerte', 'Regressionsgerade')

%% A6: Quadratische (polynomische) Regression
% Was:  Regression 2. Grades: y = a·x² + b·x + c
% Wie:  Normalgleichungssystem (3×3) aus MKQ-Bedingung ∂S/∂a = ∂S/∂b = ∂S/∂c = 0
%       mit S = Σ(yi - a·xi² - b·xi - c)²
%
%       Matrixform:  [Σx⁴  Σx³  Σx²] [a]   [Σyi·xi²]
%                    [Σx³  Σx²  Σx ] [b] = [Σyi·xi  ]
%                    [Σx²  Σx   n  ] [c]   [Σyi     ]
%
%       Lösung per \-Operator (Gauß-Elimination)
% Warum: Nichtlinearer Zusammenhang U↔Distanz erfordert höheren Polynomgrad;
%        quadratisches Modell als nächste Stufe nach linearer Regression (A5)

close all; clear all; clc;

load('Daten_2_2.mat')
x = U_in_V;
y = Distanz_in_cm;
n = length(x);

% Hilfssummen für das Normalgleichungssystem
xy  = sum(x .* y);
x2  = sum(x.^2);
x3  = sum(x.^3);
x4  = sum(x.^4);
yx2 = sum(y .* x.^2);

% Normalgleichungssystem aufstellen und lösen
A   = [x4,    x3,   x2;   ...
    x3,    x2,   sum(x);  ...
    x2,    sum(x), n];
rhs = [yx2; xy; sum(y)];

koeff = A \ rhs;  % Lösung per \-Operator
a = koeff(1)      % quadratischer Koeffizient
b = koeff(2)      % linearer Koeffizient
c = koeff(3)      % Achsenabschnitt

% Polynom für kontinuierliche Darstellung
X = [min(x):0.1:max(x)];
Y = a.*X.^2+b.*X+c;

h=figure;
axis equal
plot(x, y, 'r.')
hold on
plot(X, Y, 'b-')
ylabel('Distanz in cm')
xlabel('U in V')
legend('Messwerte', 'Quadratische (polynomische) Regression', 'Location', 'SE');

%% ========================================================================
% METHODENBIBLIOTHEK – SIGNALVERARBEITENDE SYSTEME (Teil 2: A7–A12)
% ========================================================================
% Fortsetzung der Methodenbibliothek A1–A6.
% Bereits eingeführte Konzepte (Mittelwert, Varianz, Bessel-Korrektur,
% Lineare Regression, Designmatrix) werden nicht erneut erklärt;
% Verweise auf Teil 1 sind mit "→ vgl. A1–A6" gekennzeichnet.
%
% Übersicht der Aufgaben und Verfahren:
% ---------------------------------------------------------------------
% A7  – Gebrochen rationale Regression  (y = b1/x + b0)
%        Substitution x2 = 1/x, dann lineare Regression → vgl. A1–A6
% A8  – Exponentielle Regression        (y = d·exp(k·x))
%        Linearisierung y_lin = ln(y), dann lineare Regression
%        Rücksubstitution: k = b1, d = exp(b0)
% A9  – Korrelationskoeffizient          (3 Berechnungswege)
%        Händisch, cov()-Matrix, corrcoef(); Regressionsgerade
% A10 – Polynomregression 2. Ordnung    (y = p1·x² + p2·x + p3)
%        Designmatrix A = [x², x, 1]; Lösung via Backslash-Operator
% A11 – Sensorkennlinie: Zwei Regressionsansätze
%        Ansatz 1: L = p1/(U+q1)  → Linearisierung 1/L = f(U)
%        Ansatz 2: L = b1·(1/U)+b0 → Linearisierung L = f(1/U)
%        Vergleich über Bestimmtheitsmaß R²
% A12 – Polynomregression auf Bilddaten (Fahrspur)
%        Polynomregression 2. Ordnung (→ vgl. A10) als lokale Funktion
%        Zwei Datensätze: alle 15 MW vs. erste 10 MW; R²-Vergleich
%
% Zentrale Formeln (Kurzreferenz):
% ---------------------------------------------------------------------
% Empirische Varianz (Bessel):  sxx = sum((x-x̄)²)/(n-1)       → vgl. A1–A6
% Empirische Kovarianz:         sxy = sum((x-x̄)(y-ȳ))/(n-1)   → vgl. A1–A6
% Steigung:                     b1 = sxy / sxx                  → vgl. A1–A6
% Y-Achsenabschnitt:            b0 = ȳ - b1·x̄                  → vgl. A1–A6
% Bestimmtheitsmaß:             R² = sxy² / (sxx·syy)
% Korrelationskoeffizient:      r  = sxy / sqrt(sxx·syy)
%   (es gilt: R² = r²)
% Exponentialreg. Rücksub.:     k = b1,  d = exp(b0)
% Polynomreg. (Normalengl.):   p = (A'A)^(-1) · A'y
% Alternativ (MATLAB):         p = A \ y
% ========================================================================

%% A7: Gebrochen rationale Regression (y = b1/x + b0)
% Was:   Regression eines hyperbolischen Zusammenhangs L = f(U)
% Wie:   Substitution x2 = 1/x wandelt das Modell in eine lineare Form
%        y = b1·x2 + b0 um; danach lineare Regression → vgl. A1–A6
% Warum: Sensorkennlinien (z. B. IR-Abstandssensoren) zeigen häufig
%        einen 1/x-Zusammenhang zwischen Spannung und Distanz.

close all; clear all; clc;

load('Kalibrierdaten.mat')
x = U3
y = L0;

% Substitution: Modell y = b1·(1/x) + b0  →  ersetze 1/x durch x2
x2 = 1 ./ x

% Lineare Regression auf die substituierten Daten (→ Formeln vgl. A1–A6)
n = length(x2);

sxx = sum((x2 - mean(x2)).^2) / (n - 1)
syy = sum((y - mean(y)).^2) / (n - 1)
sxy = sum((x2 - mean(x2)) .* (y - mean(y))) / (n - 1)

b1 = sxy / sxx
b0 = mean(y) - b1 * mean(x2)

X = [0.1:0.1:3.5]
% Rücksubstitution in das Originalmodell: Y = b1·(1/X) + b0
Y = b1*1./X+b0;

% R² = sxy² / (sxx·syy)
R2 = sxy^2 / (sxx * syy)

h=figure;
hold on
plot(x,y,'r.')
xlabel('U in V')
ylabel('Distanz in cm')
plot(X,Y,'b-')

%% A8: Exponentielle Regression (y = d·exp(k·x))
% Was:   Regression eines exponentiellen Zusammenhangs
% Wie:   Linearisierung durch natürlichen Logarithmus:
%          ln(y) = ln(d) + k·x  →  y_lin = b0 + b1·x
%        Nach linearer Regression Rücksubstitution:
%          k = b1  (Wachstums-/Zerfallsrate)
%          d = exp(b0)  (Vorfaktor / Anfangswert)
% Warum: Exponentielle Zusammenhänge treten bei Zerfallsprozessen,
%        Wachstumsmodellen und RC-Gliedern auf. Die Linearisierung
%        ermöglicht die Nutzung der bekannten Regressionsformeln.

close all; clear all; clc;

x = [0:0.1:10];
[y,~] = SimMessdaten(x);

% Linearisierung: y_lin = ln(y)
y_lin = log(y);

n = length(x);

% Regression auf linearisierte Daten (→ Formeln vgl. A1–A6)
sxx = sum((x - mean(x)).^2) / (n - 1);
syy = sum((y_lin - mean(y_lin)).^2) / (n - 1);
sxy = sum((x - mean(x)) .* (y_lin - mean(y_lin))) / (n - 1);

% Steigung und Achsenabschnitt der linearisierten Geraden
b1 = sxy / sxx
b0 = mean(y_lin) - b1 * mean(x)

% Rücksubstitution in das Exponentialmodell y = d·exp(k·x)
% k = b1 (Steigung der linearisierten Geraden = Exponent)
k = b1
% d = exp(b0) (Exponentialfunktion des Achsenabschnitts = Vorfaktor)
d = exp(b0)

Y = d*exp(k*x);

% Korrelationskoeffizient: r = sxy / sqrt(sxx·syy)
r = sxy / sqrt(sxx * syy)
% Bestimmtheitsmaß: r² = r²  (bezogen auf die linearisierten Daten)
r2 = r^2

h=figure;
axis equal
h1 = plot(x,y,'r.');
hold on
h2 = plot(x,Y,'b-');
ylabel('y')
xlabel('x')
legend([h1, h2], 'Messwerte','Regression');

%% A9: Korrelationskoeffizient – drei Berechnungswege
% Was:   Bestimmung des linearen Zusammenhangs zweier Größen X, Y
% Wie:   Drei äquivalente Wege zur Berechnung von r:
%        Händisch:    r = Σ(X-X̄)(Y-Ȳ) / √[Σ(X-X̄)²·Σ(Y-Ȳ)²]
%        cov()-Matrix: r = C(1,2) / √(C(1,1)·C(2,2))
%        corrcoef():   r = R(1,2)
% Warum: Der Korrelationskoeffizient r ∈ [-1,1] quantifiziert die Stärke
%        und Richtung des linearen Zusammenhangs. |r| > 0.8 rechtfertigt
%        eine lineare Regression.
%
% Zusammenhang cov() und Varianz/Kovarianz:
%   cov(X,Y) liefert die 2×2-Matrix  [var(X)   cov(X,Y)]
%                                      [cov(Y,X)  var(Y) ]
%   Dabei gilt: var(X) = sxx,  cov(X,Y) = sxy  (jeweils Bessel-korrigiert)

close all; clear all; clc;

load('Korrelation_a.mat')

% Weg 1: Händische Berechnung (ohne Bessel-Korrektur, da sich n-1 kürzt)
% r = Σ(Xi-X̄)(Yi-Ȳ) / √[Σ(Xi-X̄)² · Σ(Yi-Ȳ)²]
r1 = sum((X - mean(X)) .* (Y - mean(Y))) / sqrt(sum((X - mean(X)).^2) * sum((Y - mean(Y)).^2));

% Weg 2: Über die Kovarianzmatrix cov(X,Y)
% r = C(1,2) / √(C(1,1)·C(2,2))  ≡  sxy / √(sxx·syy)
C = cov(X, Y);
r2 = C(1,2) / sqrt(C(1,1) * C(2,2));

% Weg 3: Direkt über corrcoef()
R = corrcoef(X, Y);
r3 = R(1,2);

% Regressionsgerade (→ Formeln vgl. A1–A6)
% Voraussetzung: |r| > 0.8 → linearer Zusammenhang gerechtfertigt
b1 = C(1,2) / C(1,1);
b0 = mean(Y) - b1 * mean(X);

X_reg = [min(X):0.1:max(X)];
Y_reg = b1 * X_reg + b0;

figure;
hold on;
h1 = plot(X, Y, 'r.');
h2 = plot(X_reg, Y_reg, 'b-');
title(['r = ', num2str(r1, '%.5f')]);
xlabel('X');
ylabel('Y');
legend([h1, h2], 'Messwerte', 'Regressionsgerade');

%% A10: Polynomregression 2. Ordnung (y = p1·x² + p2·x + p3)
% Was:   Anpassung eines Polynoms 2. Ordnung an verrauschte Messdaten
% Wie:   Aufstellen der Designmatrix A = [x², x, 1] (n×3)
%        Lösung des überbestimmten Gleichungssystems A·p = y
%        über die Methode der kleinsten Quadrate:
%          p = (A'A)^(-1)·A'y   (Normalengleichung)
%          p = A \ y            (MATLAB Backslash-Operator, numerisch stabiler)
% Warum: Nichtlineare Zusammenhänge (z. B. parabelförmige Kennlinien)
%        erfordern Polynome höherer Ordnung. Die Designmatrix-Methode
%        ist auf beliebige Ordnungen erweiterbar.

close all; clear all; clc;

x = [0:0.1:10];
y = 2*x.^2-x+10;             % Deterministischer Anteil
y = y'+2*randn(length(x),1); % Messwert = Signal + Rauschen

% Designmatrix A für Polynom 2. Ordnung: A·p = y
% A = [x², x, 1],  p = [p1; p2; p3]
A = [(x').^2, x', ones(length(x), 1)];

% Lösung via Backslash (≡ Normalengleichung, aber numerisch stabiler)
p = (A \ y)'

% Regressionskurve: Y = p(1)·x² + p(2)·x + p(3)
Y = p(1)*x.^2+p(2)*x+p(3);

h = figure;
h1 = plot(x,y,'r.');
hold on
h2 = plot(x,Y,'b-');
xlabel('x');
ylabel('y');
legend([h1, h2], 'Messwerte','Regression');

%% A11: Sensorkennlinie – Zwei gebrochen rationale Regressionsansätze
% Was:   Approximation der Kennlinie L = f(U) eines Abstandssensors
%        mit zwei verschiedenen gebrochen rationalen Modellen
% Wie:   Ansatz 1: L = p1/(U + q1)
%          Linearisierung: 1/L = (1/p1)·U + q1/p1  →  y = b1·x + b0
%          Rücksubstitution: p1 = 1/b1,  q1 = b0/b1
%        Ansatz 2: L = b1·(1/U) + b0
%          Linearisierung: L = b1·(1/U) + b0  →  direkte Substitution (→ vgl. A7)
% Warum: Verschiedene Linearisierungen desselben physikalischen Zusammenhangs
%        führen zu unterschiedlichen Gewichtungen der Messwerte.
%        Vergleich über R² zeigt, welcher Ansatz besser geeignet ist.

close all; clear all; clc;

load('Kennlinie.mat');

disp('----------------------')
disp('Ansatz 1')

% Ansatz 1: L = p1/(U + q1)  →  1/L = (1/p1)·U + (q1/p1)
x_lin1 = U;
y_lin1 = 1 ./ L;

n1 = length(x_lin1);
% Regression auf linearisierte Daten (→ Formeln vgl. A1–A6)
sxx = sum((x_lin1 - mean(x_lin1)).^2) / (n1 - 1)
syy = sum((y_lin1 - mean(y_lin1)).^2) / (n1 - 1)
sxy = sum((x_lin1 - mean(x_lin1)) .* (y_lin1 - mean(y_lin1))) / (n1 - 1)

b1 = sxy / sxx
b0 = mean(y_lin1) - b1 * mean(x_lin1)

X = [0.2:0.1:4];

% Rücksubstitution: p1 = 1/b1,  q1 = b0/b1
p1 = 1 / b1
q1 = b0 / b1

% Originalmodell: Y = p1 / (X + q1)
Y1 = p1 ./ (X + q1);

% R² der Linearisierung
R2_Ansatz1 = sxy^2 / (sxx * syy)

figure('Name', 'Sensorkennlinie Regression', 'Position', [100, 100, 800, 800]);

subplot(2,2,1);
plot(x_lin1, y_lin1, 'b.'); hold on;
plot(X, b1 * X + b0, 'b-');
title('Ansatz 1');
xlabel('Messspannung U in V');
ylabel('1/L in 1/cm');
legend('Messwerte', 'Regression');

subplot(2,2,2);
plot(U, L, 'b.'); hold on;
plot(X, Y1, 'b-');
title(['R^2 = ', num2str(R2_Ansatz1, '%.5f')]);
xlabel('Messspannung U in V');
ylabel('Distanz L in cm');
legend('Messwerte', 'Regression');


disp('----------------------')
disp('Ansatz 2')

% Ansatz 2: L = b1·(1/U) + b0  →  Substitution x2 = 1/U (→ vgl. A7)
x_lin2 = 1 ./ U;
y_lin2 = L;

n2 = length(x_lin2);
sxx = sum((x_lin2 - mean(x_lin2)).^2) / (n2 - 1)
syy = sum((y_lin2 - mean(y_lin2)).^2) / (n2 - 1)
sxy = sum((x_lin2 - mean(x_lin2)) .* (y_lin2 - mean(y_lin2))) / (n2 - 1)

b1 = sxy / sxx
b0 = mean(y_lin2) - b1 * mean(x_lin2)

X = [0.2:0.1:4];
Y2 = b1*1./X+b0;

R2_Ansatz2 = sxy^2 / (sxx * syy)

subplot(2,2,3);
plot(x_lin2, y_lin2, 'b.'); hold on;
X_lin_plot = linspace(min(x_lin2), max(x_lin2), 100);
plot(X_lin_plot, b1 * X_lin_plot + b0, 'b-');
title('Ansatz 2');
xlabel('1/U in 1/V');
ylabel('L in cm');
legend('Messwerte', 'Regression');

subplot(2,2,4);
plot(U, L, 'b.'); hold on;
plot(X, Y2, 'b-');
title(['R^2 = ', num2str(R2_Ansatz2, '%.5f')]);
xlabel('Messspannung U in V');
ylabel('Distanz L in cm');
legend('Messwerte', 'Regression');

% Fazit: Ansatz 2 liefert ein höheres R² und approximiert die
% Sensorkennlinie besser als Ansatz 1.
disp('Fazit: Ansatz 2 liefert ein höheres Bestimmtheitsmaß R^2 und approximiert die Sensorkennlinie besser als Ansatz 1.');

%% A12: Polynomregression auf Bilddaten (Fahrspur)
% Was:   Erkennung einer Fahrspur durch Polynomregression 2. Ordnung
%        auf Pixelkoordinaten; Vergleich Gesamtdatensatz vs. Teilmenge
% Wie:   Lokale Funktion PolynomRegression(x,y) implementiert die
%        Normalengleichung p = (A'A)^(-1)·A'y  (→ vgl. A10)
%        Bestimmtheitsmaß hier über Residuenform:
%          R² = 1 - SS_res/SS_tot
%          SS_res = Σ(yi - ŷi)²   (Residuenquadratsumme)
%          SS_tot = Σ(yi - ȳ)²    (Gesamtquadratsumme)
%        Diese Form ist äquivalent zu R² = sxy²/(sxx·syy) bei linearer
%        Regression, eignet sich aber auch für nichtlineare Modelle.
% Warum: Fahrspurerkennung ist ein Anwendungsbeispiel der Polynomregression
%        in der Bildverarbeitung. Der Vergleich zeigt, wie die Wahl des
%        Datenbereichs das Regressionsergebnis beeinflusst.

close all; clear all; clc;

load('Messdaten_px.mat');
img = imread('Fahrspur.jpg');

figure
imshow(img)

% Messwerte in das Kamerabild einzeichnen
hold on
plot(x, y, 'g.', 'MarkerSize', 12)

% Ansatz 1: Alle 15 Messwerte (→ Polynomregression vgl. A10)
p1 = PolynomRegression(x, y);

xFit = linspace(min(x), max(x), 500);
yFit1 = p1(1).*xFit.^2 + p1(2).*xFit + p1(3);
plot(xFit, yFit1, 'b-', 'LineWidth', 2)
legend('Messwerte', 'Regression')

% R² über Residuenform: R² = 1 - SS_res/SS_tot
yHat1  = p1(1).*x.^2 + p1(2).*x + p1(3);
R2_Ansatz1 = 1 - sum((y - yHat1).^2) / sum((y - mean(y)).^2)

% Ansatz 1: R²≈0.99 → sehr gute Anpassung an den gesamten Kurvenverlauf.

% Ansatz 2: Erste 10 Messwerte
p2 = PolynomRegression(x(1:10), y(1:10));

figure
imshow(img)
hold on
plot(x(1:10), y(1:10), 'g.', 'MarkerSize', 12)
xFit2 = linspace(min(x(1:10)), max(x(1:10)), 500);
yFit2 = p2(1).*xFit2.^2 + p2(2).*xFit2 + p2(3);
plot(xFit2, yFit2, 'b-', 'LineWidth', 2)
legend('Messwerte', 'Regression')

yHat2  = p2(1).*x(1:10).^2 + p2(2).*x(1:10) + p2(3);
R2_Ansatz2 = 1 - sum((y(1:10) - yHat2).^2) / sum((y(1:10) - mean(y(1:10))).^2)

% Ansatz 2: R² tendenziell höher, da kürzerer, gleichmäßigerer Abschnitt.
% Extrapolation auf den Gesamtbereich jedoch unzuverlässig.

%% Lokale Funktionen
% Polynomregression 2. Ordnung via Normalengleichung (→ vgl. A10)
% Eingabe: x, y (Messwerte)
% Ausgabe: p = [p1; p2; p3] mit y = p1·x² + p2·x + p3
% Formel:  p = (A'A)^(-1) · A'y,   A = [x², x, 1]
function p = PolynomRegression(x, y)
x  = x(:);
y  = y(:);
A  = [x.^2, x, ones(length(x), 1)];
p  = inv(A' * A) * (A' * y);
end