clc; clear all; close all;
%% Initialisierung
load('Messdaten.mat')      % laedt TemperaturCelsius
whos
TReferenz = 22;            % wahrer Temperaturwert in °C
mu0       = 0.5;           % Spezifikation aktuelles Modell: mittl. abs. Fehler in °C
alpha     = 0.05;          % Signifikanzniveau
n         = length(TemperaturCelsius);
T_mean    = mean(TemperaturCelsius);
T_std     = std(TemperaturCelsius);

%% die Messwerte in Messdaten.mat zeichnen
figure
yyaxis left
histogram(TemperaturCelsius, 'FaceColor', [0.65 0.65 0.65], 'EdgeColor', 'k')
xlabel('Temperatur in °C')
ylabel('Absolute Häufigkeit')
hold on

% Vertikale Linien: wahrer Wert, Mittelwert, +/-sigma
xline(TReferenz, 'b-',  sprintf('Wahrer Wert = %d°C', TReferenz), 'LineWidth', 1.5)
xline(T_mean,    'k-',  sprintf('\\bar{T} = %.4f°C', T_mean),     'LineWidth', 1.5)
xline(T_mean + T_std, 'b--', sprintf('\\sigma = %.4f°C', T_std),  'LineWidth', 1.2)
xline(T_mean - T_std, 'b--', 'LineWidth', 1.2)

% Normalverteilungskurve auf rechter y-Achse (Wahrscheinlichkeit in %)
yyaxis right
x_plot = linspace(min(TemperaturCelsius) - 0.3, max(TemperaturCelsius) + 0.3, 500);
y_norm = normpdf(x_plot, T_mean, T_std) * 100;
plot(x_plot, y_norm, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.5)
ylabel('Wahrscheinlichkeit in %')

title('Temperaturmesswerte – neue Sensorserie')
grid on
hold off

%% Prüfen, ob eine Normalverteilung vorliegt.
% Chi-Quadrat-Anpassungstest gegen angepasste Normalverteilung
[h_norm, p_norm] = chi2gof(TemperaturCelsius, ...
    'CDF', @(x) normcdf(x, T_mean, T_std), ...
    'NParams', 2);
% h_norm = 0: Normalverteilung kann nicht abgelehnt werden → NV liegt vor
fprintf('--- Aufgabe 2: Pruefung auf Normalverteilung ---\n')
fprintf('chi2gof: h = %d  |  p = %.4f\n', h_norm, p_norm)
if h_norm == 0
    fprintf('Ergebnis: Normalverteilung wird beibehalten (p > alpha).\n\n')
else
    fprintf('Ergebnis: Normalverteilung abgelehnt (p <= alpha).\n\n')
end

%% die Nullhypothese (H0) und die Alternativhypothese (H1) formulieren
%  Pruefgroesse: mittlerer absoluter Messfehler e = |T_gemessen - T_wahr|
%  H0: mu_e >= 0,5 °C  (neue Sensoren NICHT besser als Spezifikation)
%  H1: mu_e <  0,5 °C  (neue Sensoren GENAUER als Spezifikation)
fprintf('--- Aufgabe 3: Hypothesen ---\n')
fprintf('H0: mu_Fehler >= %.1f°C  (kein Vorteil gegenüber aktuellem Modell)\n', mu0)
fprintf('H1: mu_Fehler <  %.1f°C  (neue Sensorserie ist genauer)\n\n', mu0)

%% Entscheiden, welchen Hypothesentest Sie verwenden würden.
%  Gewaehlt: Einstichproben-t-Test (linksseitig)
%  Begruendung:
%    - Populationsstandardabweichung sigma unbekannt → t-Test (nicht z-Test)
%    - Einseitig links: nur Verbesserung (mu_e < mu0) von Interesse
%    - Normalverteilung der Messwerte durch Test bestaetigt
%    - n = 100: t-Verteilung naehert sich Normalverteilung an
fprintf('--- Aufgabe 4: Testwahl ---\n')
fprintf('Gewaehlter Test: Einstichproben-t-Test (linksseitig)\n')
fprintf('Begruendung: sigma unbekannt, einseitige H1 (Verbesserung), NV bestätigt.\n\n')

%% den Testwert unter Verwendung eines Signifikanzniveaus von 5% berechnen
%  Absolute Messfehler berechnen
e      = abs(TemperaturCelsius - TReferenz);   % absolute Abweichung je Sensor
e_mean = mean(e);                               % mittlerer absoluter Fehler
s_e    = std(e);                                % Stichprobenstandardabweichung

%  Pruefgroesse: t = (e_mean - mu0) / (s_e / sqrt(n))
tTest = (e_mean - mu0) / (s_e / sqrt(n))       % Testwert

%% den kritischen Wert für den gewählten Signifikanzgrad bestimmen
%  Linksseitiger Test: H0 ablehnen, wenn tTest < tKritisch (negativer Wert)
%  tKritisch = tinv(alpha, n-1)
% tKritisch = tinv(alpha, n - 1)                  % kritischer Wert (linksseitig)
tKritisch = tinv(1 - alpha, n - 1)                %  Vorzeichen korrigiert
         

%% Prüfgröße
%  H0 beibehalten (true),  wenn tTest >= tKritisch
%  H0 ablehnen   (false),  wenn tTest <  tKritisch
% H0 = tTest >= tKritisch                         % true = angenommen | false = abgelehnt
H0 = tTest >= -tKritisch                          %  Vorzeichen korrigiert

%% das Ergebnis im Kontext der Spezifikation interpretieren
fprintf('--- Aufgabe 8: Interpretation ---\n')
fprintf('Mittlerer absoluter Messfehler neue Serie: e_mean = %.4f°C\n', e_mean)
fprintf('Testwert:       tTest     = %.4f\n', tTest)
fprintf('Kritischer Wert: tKritisch = %.4f\n', tKritisch)
if H0 == false
    fprintf('Entscheidung: H0 abgelehnt  (tTest < tKritisch)\n')
    fprintf('Schlussfolgerung: Mit %.0f%% Sicherheit sind die neuen Sensoren\n', (1-alpha)*100)
    fprintf('genauer als die Spezifikation von %.1f°C mittl. abs. Fehler.\n', mu0)
else
    fprintf('Entscheidung: H0 beibehalten (tTest >= tKritisch)\n')
    fprintf('Schlussfolgerung: Es konnte NICHT nachgewiesen werden, dass die\n')
    fprintf('neuen Sensoren genauer sind als %.1f°C mittl. abs. Fehler.\n', mu0)
end
%}

%% =========================================================
%  Hypothesentest: Genauigkeit neuer Temperatursensoren
%
%  Spezifikation:
%  Ein Produktionsunternehmen hat eine neue Sensorserie entwickelt.
%  Die alte Serie hat einen mittleren absoluten Messfehler von 0,5°C.
%  Ziel: Nachweisen, ob die neue Serie signifikant genauer ist.
%
%  Methode: Einstichproben-t-Test (linksseitig)
%  Voraussetzung: Messwerte sind normalverteilt
%  Datenquelle: Messdaten.mat → TemperaturCelsius (1×100 double)
%  Referenztemperatur: 22°C
% =========================================================
%{
clc;        % Konsole (Command Window) leeren – verhindert Durcheinander mit alten Ausgaben
clear all;  % alle Variablen aus dem Workspace loeschen – sicherer Neustart
close all;  % alle offenen Abbildungsfenster schliessen

%% =========================================================
%  INITIALISIERUNG – Daten laden und Grundgroessen berechnen
% =========================================================

load('Messdaten.mat')
% load(): laedt die Datei 'Messdaten.mat' in den Workspace.
% Nach diesem Befehl steht die Variable TemperaturCelsius (1×100 double)
% zur Verfuegung. Ohne Semikolon werden geladene Variablen angezeigt.
% FALLSTRICK: Die .mat-Datei muss im aktuellen MATLAB-Arbeitsordner
% liegen, sonst gibt es den Fehler "Unable to find file".

whos
% whos: zeigt alle aktuell im Workspace vorhandenen Variablen mit
% Name, Groesse (z.B. 1×100), Bytes und Klasse (z.B. double) an.
% Didaktisch wertvoll: gibt einen schnellen Ueberblick ueber die
% geladenen Daten und deren Dimensionen.

TReferenz = 22;
% TReferenz: der bekannte wahre Temperaturwert in Grad Celsius.
% Dieser Wert kommt aus dem Kalibrierlabor und ist keine Messung,
% sondern eine definierte Referenzgroesse.

mu0 = 0.5;
% mu0 (griechisch: mu_0): der unter H0 angenommene Schwellenwert.
% mu0 = 0,5°C ist der maximale mittlere Messfehler der ALTEN Sensorserie
% (Spezifikation des Herstellers). Er ist der Vergleichswert fuer den Test.

alpha = 0.05;
% alpha (Signifikanzniveau): die maximal tolerierbare Wahrscheinlichkeit
% fuer einen Fehler 1. Art (H0 faelschlicherweise ablehnen).
% alpha = 0.05 bedeutet: Irrtum in hoechstens 5% der Faelle erlaubt.

n = length(TemperaturCelsius);
% length(): gibt die Anzahl der Elemente des Vektors zurueck.
% n = 100 (Stichprobenumfang – Anzahl getesteter Sensoren).
% FALLSTRICK: Bei Matrizen gibt length() die groesste Dimension zurueck.
% Sicherer fuer Vektoren: numel(TemperaturCelsius).

T_mean = mean(TemperaturCelsius);
% mean(): berechnet den arithmetischen Mittelwert aller 100 Messwerte.
% Formel: T_mean = (1/n) * sum(T_i) fuer i = 1..n
% T_mean ist der beste Schaetzwert fuer den wahren Erwartungswert mu.
% Hier: T_mean ≈ 22.4463°C (aus dem Workspace ablesbar).

T_std = std(TemperaturCelsius);
% std(): berechnet die empirische Standardabweichung der Messwerte.
% Formel: T_std = sqrt( sum((T_i - T_mean)^2) / (n-1) )
% Nenner (n-1): Bessel-Korrektur fuer erwartungstreue Schaetzung von sigma.
% FALLSTRICK: std(x,1) verwendet Nenner n – fuer Stichproben immer std(x)!
% Hier: T_std ≈ 0.1006°C (sichtbar in Abb. 1 und im Workspace).

%% =========================================================
%  Messwerte grafisch darstellen
%  Ziel: Verteilung der 100 Temperaturmesswerte visualisieren
% =========================================================

figure
% figure: oeffnet ein neues, leeres Grafikfenster (Figure).
% Ohne figure() wuerde der naechste Plot in die letzte geoeffnete Figure
% gezeichnet – was bei mehreren Ausfuehrungen zu ueberschriebenen Plots
% fuehren kann. Mit figure() ist jede Grafik in ihrem eigenen Fenster.

yyaxis left
% yyaxis left: aktiviert die LINKE y-Achse fuer alle nachfolgenden
% Zeichenbefehle. Damit koennen zwei unterschiedliche Groessen
% (hier: Haeufigkeit links, Wahrscheinlichkeit rechts) in einer einzigen
% Grafik nebeneinander dargestellt werden (duale y-Achse / yyaxis).

histogram(TemperaturCelsius, 'FaceColor', [0.65 0.65 0.65], 'EdgeColor', 'k')
% histogram(): erstellt ein Haeufigkeitshistogramm der Messwerte.
%   - TemperaturCelsius: der Datenvektor (1×100)
%   - MATLAB waehlt die Klassenbreite automatisch (Sturges-Regel)
%   - 'FaceColor', [0.65 0.65 0.65]: RGB-Wert fuer Grau (0=schwarz, 1=weiss)
%     Werte zwischen 0 und 1 codieren den jeweiligen Rotanteil, Gruenanteil,
%     Blauanteil. [0.65 0.65 0.65] = mittleres Grau.
%   - 'EdgeColor', 'k': Umrandung der Balken in Schwarz ('k' = black)
% Ausgabe: Bardiagramm, x-Achse = Temperaturbereich, y-Achse = Anzahl
%          der Messwerte in jeder Klasse (absolute Haeufigkeit)

xlabel('Temperatur in °C')
% xlabel(): beschriftet die x-Achse der aktuellen Grafik.
% Ohne Beschriftung ist eine Grafik fuer andere nicht interpretierbar!

ylabel('Absolute Häufigkeit')
% ylabel(): beschriftet die LINKE y-Achse (da yyaxis left aktiv).
% Zeigt an, wie viele Messwerte in jede Temperaturklasse fallen.

hold on
% hold on: verhindert, dass der naechste Zeichenbefehl die aktuelle Grafik
% loescht und ersetzt. Ohne hold on wuerde z.B. xline() das Histogramm
% ueberschreiben. Mit hold on werden alle Grafiken UEBERLAGERT.

xline(TReferenz, 'b-', sprintf('Wahrer Wert = %d°C', TReferenz), 'LineWidth', 1.5)
% xline(): zeichnet eine VERTIKALE Linie bei einem festen x-Wert.
%   - TReferenz = 22: x-Position der Linie
%   - 'b-': blaue ('b') durchgezogene ('-') Linie
%   - sprintf('Wahrer Wert = %d°C', TReferenz): erstellt einen
%     Beschriftungstext als String. %d ist ein Platzhalter fuer Integer-Wert.
%     sprintf() gibt den formatierten String zurueck (kein fprintf!).
%   - 'LineWidth', 1.5: Linienstaerke in Punkten (Standard: 0.5)
% Ausgabe: blaue vertikale Linie bei x = 22°C

xline(T_mean, 'k-', sprintf('\\bar{T} = %.4f°C', T_mean), 'LineWidth', 1.5)
% xline() fuer den Stichprobenmittelwert T_mean.
%   - 'k-': schwarze durchgezogene Linie
%   - '\\bar{T}': LaTeX-Befehl fuer T mit Querstrich (T-Bar = Mittelwert).
%     In MATLAB-Strings muss der Backslash verdoppelt werden: \\ → \
%   - %.4f: Platzhalter fuer Fliesskommazahl mit 4 Nachkommastellen
% Ausgabe: schwarze Linie bei T_mean ≈ 22.4463°C (Mittelwert)

xline(T_mean + T_std, 'b--', sprintf('\\sigma = %.4f°C', T_std), 'LineWidth', 1.2)
% xline() fuer die rechte sigma-Grenze (Mittelwert + 1 Standardabweichung).
%   - 'b--': blaue gestrichelte Linie
%   - '\\sigma': LaTeX fuer das griechische Sigma (Standardabweichung)
% Ausgabe: blaue gestrichelte Linie bei T_mean + T_std ≈ 22.5469°C

xline(T_mean - T_std, 'b--', 'LineWidth', 1.2)
% xline() fuer die linke sigma-Grenze (Mittelwert - 1 Standardabweichung).
% Kein Beschriftungstext, da der andere Sigma-Marker bereits beschriftet ist.
% Ausgabe: blaue gestrichelte Linie bei T_mean - T_std ≈ 22.3457°C
% Gemeinsam markieren die beiden Linien den 1-sigma-Bereich (ca. 68% aller
% Messwerte liegen bei Normalverteilung zwischen diesen Grenzen).

yyaxis right
% yyaxis right: wechselt auf die RECHTE y-Achse.
% Ab hier beziehen sich alle y-Werte auf die rechte Skala (Wahrscheinlichkeit).

x_plot = linspace(min(TemperaturCelsius) - 0.3, max(TemperaturCelsius) + 0.3, 500);
% linspace(a, b, n): erzeugt einen Vektor mit n gleichmaessig verteilten
% Punkten zwischen a und b.
%   - Start: min(TemperaturCelsius) - 0.3 → leicht unterhalb des Minimums
%   - Ende:  max(TemperaturCelsius) + 0.3 → leicht oberhalb des Maximums
%   - 500: Anzahl der Punkte → je mehr Punkte, desto glattere Kurve
% Zweck: x-Achsenwerte fuer die aufzuzeichnende Normalverteilungskurve

y_norm = normpdf(x_plot, T_mean, T_std) * 100;
% normpdf(x, mu, sigma): berechnet die Wahrscheinlichkeitsdichte (PDF)
% der Normalverteilung N(mu, sigma) an den Stellen x.
% Formel: f(x) = 1/(sigma*sqrt(2*pi)) * exp(-0.5*((x-mu)/sigma)^2)
%   - T_mean: Erwartungswert mu der angepassten Normalverteilung
%   - T_std:  Standardabweichung sigma der angepassten Normalverteilung
%   - * 100: Umrechnung von Wahrscheinlichkeitsdichte in Prozent (fuer y-Achse)
% Ausgabe: Vektor mit 500 Dichtewerten (in %) passend zu x_plot

plot(x_plot, y_norm, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.5)
% plot(x, y, ...): zeichnet eine 2D-Liniengrafik.
%   - x_plot, y_norm: x- und y-Koordinaten der Normalverteilungskurve
%   - 'Color', [0.85 0.33 0.10]: RGB-Farbe → ergibt ein Orange-Rot
%     (wie in Abb. 1 sichtbar)
%   - 'LineWidth', 1.5: Linienstaerke
% Ausgabe: glaeckoenfoermige Normalverteilungskurve ueberlagert dem Histogramm

ylabel('Wahrscheinlichkeit in %')
% ylabel() fuer die rechte y-Achse (yyaxis right aktiv).
% Beschriftet die rechte Skala mit der Wahrscheinlichkeit in Prozent.

title('Temperaturmesswerte – neue Sensorserie')
% title(): setzt den Titel der Grafik.
% Pflicht fuer jede wissenschaftliche Abbildung!

grid on
% grid on: aktiviert das Gitternetz im Plot.
% Erleichtert das Ablesen von Werten aus dem Diagramm.

hold off
% hold off: beendet den Ueberlagerungs-Modus.
% Alle nachfolgenden Plot-Befehle erstellen wieder neue Grafiken.

%% =========================================================
%  Normalverteilung pruefen
%  Methode: Chi-Quadrat-Anpassungstest (chi2gof)
% =========================================================

[h_norm, p_norm] = chi2gof(TemperaturCelsius, ...
    'CDF', @(x) normcdf(x, T_mean, T_std), ...
    'NParams', 2);
% chi2gof(): Chi-Quadrat Goodness-of-Fit-Test (Anpassungstest).
% Prueft, ob die Stichprobe einer vorgegebenen Verteilung entstammt.
%
% Eingaben:
%   - TemperaturCelsius: der zu testende Datenvektor
%   - 'CDF', @(x) normcdf(x, T_mean, T_std): die Referenz-Verteilungsfunktion
%     (hier: Normalverteilung mit geschaetztem Mittelwert und Standardabw.)
%     @(x) definiert eine anonyme Funktion (Lambda) in MATLAB.
%     normcdf(x, mu, sigma): kumulierte Normalverteilung (CDF) an Stelle x.
%   - 'NParams', 2: Anzahl der aus den Daten geschaetzten Parameter
%     (hier: mu und sigma → 2 Parameter). Noetig, um die Freiheitsgrade
%     des Chi-Quadrat-Tests korrekt zu berechnen.
%
% Ausgaben:
%   - h_norm: Testergebnis als boolesch  → 0 = H0 beibehalten (NV liegt vor)
%                                        → 1 = H0 abgelehnt (keine NV)
%   - p_norm: p-Wert des Tests
%     → p > alpha (0.05): kein signifikanter Widerspruch zur Normalverteilung
%     → p <= alpha:       Normalverteilungsannahme wird abgelehnt
%
% Notation '...': Fortsetzungszeichen fuer mehrzeilige Befehle.
% FALLSTRICK: chi2gof braucht die Statistics and Machine Learning Toolbox!

fprintf('--- Aufgabe 2: Pruefung auf Normalverteilung ---\n')
% fprintf(): formatierte Ausgabe in die Konsole (Command Window).
% \n = newline (Zeilenumbruch).
% Kein Semikolon noetig – fprintf() gibt standardmaessig nichts ins Workspace.

fprintf('chi2gof: h = %d  |  p = %.4f\n', h_norm, p_norm)
% %d: ganzzahliger Platzhalter (fuer h_norm: 0 oder 1)
% %.4f: Fliesskommazahl mit 4 Nachkommastellen (fuer p_norm)

if h_norm == 0
    fprintf('Ergebnis: Normalverteilung wird beibehalten (p > alpha).\n\n')
    % h_norm == 0: kein signifikanter Widerspruch zur Normalverteilung.
    % Die Normalverteilungsannahme fuer den anschliessenden t-Test ist erfuellt.
else
    fprintf('Ergebnis: Normalverteilung abgelehnt (p <= alpha).\n\n')
    % h_norm == 1: Normalverteilung signifikant abgelehnt.
    % In diesem Fall muesste ein nichtparametrischer Test (z.B. Wilcoxon)
    % verwendet werden. Beim vorliegenden Datensatz tritt dieser Fall nicht auf.
end

%% =========================================================
%  Hypothesen formulieren
%  Pruefgroesse: mittlerer absoluter Messfehler e = |T_gemessen - T_wahr|
% =========================================================
%
%  H0: mu_e >= 0,5°C  (neue Sensoren sind NICHT besser als Spezifikation)
%  H1: mu_e <  0,5°C  (neue Sensoren sind GENAUER → Kaufentscheidung!)
%
%  Einseitiger Test (linksseitig), weil nur Verbesserung (kleiner Fehler)
%  fuer die Entscheidung des Unternehmens relevant ist.
%
fprintf('--- Aufgabe 3: Hypothesen ---\n')
fprintf('H0: mu_Fehler >= %.1f°C  (kein Vorteil gegenüber aktuellem Modell)\n', mu0)
fprintf('H1: mu_Fehler <  %.1f°C  (neue Sensorserie ist genauer)\n\n', mu0)

%% =========================================================
%  Testauswahl und Begruendung
% =========================================================
%
%  Gewaehlt: Einstichproben-t-Test (linksseitig)
%
%  Begruendung:
%    Populationsstandardabweichung sigma unbekannt
%       → t-Test statt z-Test (z-Test setzt bekanntes sigma voraus)
%    Einseitige Alternativhypothese (mu_e < mu0)
%       → linksseitiger Test: nur negative Abweichungen von mu0 sind relevant
%    Normalverteilung durch chi2gof bestaetigt
%       → Voraussetzung fuer t-Test erfuellt
%    n = 100: t-Verteilung naehert sich Normalverteilung an (robuster Test)
%
fprintf('--- Aufgabe 4: Testwahl ---\n')
fprintf('Gewaehlter Test: Einstichproben-t-Test (linksseitig)\n')
fprintf('Begruendung: sigma unbekannt, einseitige H1 (Verbesserung), NV bestätigt.\n\n')

%% =========================================================
%  Testwert berechnen (Signifikanzniveau alpha = 5%)
%  Pruefgroesse: t0 = (e_mean - mu0) / (s_e / sqrt(n))
% =========================================================

e = abs(TemperaturCelsius - TReferenz);
% abs(): Betragsfunktion – berechnet den absoluten Wert elementweise.
% TemperaturCelsius - TReferenz: Differenz jedes Messwerts vom Referenzwert 22°C.
% Diese Differenz kann positiv (Messung zu hoch) oder negativ (zu niedrig) sein.
% abs() macht alle Vorzeichen positiv: e_i = |T_i - 22| in °C.
% Ergebnis: Vektor e mit 100 positiven Fehlerwerten (absolute Abweichungen).
% Warum abs()? Weil der mittlere ABSOLUTE Fehler die in der Spezifikation
% genannte Groesse ist ("durchschnittlicher absoluter Messfehler von 0,5°C").

e_mean = mean(e);
% mean(e): mittlerer absoluter Messfehler der 100 Sensoren.
% Dies ist der Schaetzwert fuer den Erwartungswert mu_e der Grundgesamtheit.
% Erwartet: e_mean < 0,5°C (neue Sensoren genauer).

s_e = std(e);
% std(e): Standardabweichung der absoluten Fehler.
% Nenner (n-1): Bessel-Korrektur fuer erwartungstreue Schaetzung.
% s_e beschreibt die Streuung der Fehler um e_mean.

tTest = (e_mean - mu0) / (s_e / sqrt(n))
% Formel der t-Pruefgroesse:
%
%          e_mean - mu0
%  tTest = ------------
%          s_e / sqrt(n)
%
% Zaehler (e_mean - mu0):
%   Abweichung des gemessenen mittl. Fehlers vom Referenzwert mu0.
%   Ist e_mean < mu0, wird der Zaehler negativ → tTest negativ.
%
% Nenner (s_e / sqrt(n)):
%   Standardfehler des Mittelwerts (SEM = Standard Error of the Mean).
%   Gibt an, wie stark e_mean durch Zufallsschwankungen variieren wuerde.
%   Mit groesserem n wird der SEM kleiner → Test praeziser.
%
% Unter H0 ist tTest t-verteilt mit (n-1) = 99 Freiheitsgraden.
% Kein Semikolon → Wert wird im Command Window angezeigt.

%% =========================================================
%  Kritischen Wert berechnen
%  Linksseitiger Test: H0 ablehnen, wenn tTest < tKritisch (negativer Wert)
% =========================================================

tKritisch = tinv(alpha, n - 1)
% tinv(p, nu): inverser CDF der t-Verteilung (Quantilfunktion).
% Gibt den Wert t_krit zurueck, sodass gilt: P(T <= t_krit) = p
%
% Argumente:
%   - alpha = 0.05: Wahrscheinlichkeit im linksseitigen Ablehnungsbereich
%   - n-1 = 99: Freiheitsgrade der t-Verteilung
%
% Ergebnis: tKritisch ≈ -1.6604 (negativer Wert, da linksseitig)
%
% Visualisierung (linksseitiger Test):
%
%  alpha = 5%   |       Annahmebereich 95%
%  //////////// |
%  -inf    tKritisch          0          +inf
%          ≈-1.66
%
% Testregel: Ablehnen von H0, wenn tTest < tKritisch
%            → Liegt tTest links von tKritisch, wird H0 abgelehnt
%
% VERGLEICH mit zweiseitigem Test:
%   Zweiseitig: tinv(alpha/2, n-1) und tinv(1-alpha/2, n-1)
%               → zwei kritische Werte, symmetrisch
%   Einseitig:  tinv(alpha, n-1) → ein kritischer Wert links

%% =========================================================
%  Testentscheidung (Pruefgroesse)
% =========================================================

H0 = tTest >= tKritisch
% Testentscheidung durch direkten Vergleich von Testwert und krit. Wert:
%
%   H0 = true   (beibehalten): tTest >= tKritisch
%                               Der Testwert liegt im Annahmebereich.
%                               Kein signifikanter Nachweis der Verbesserung.
%
%   H0 = false  (abgelehnt):   tTest < tKritisch
%                               Der Testwert liegt im Ablehnungsbereich.
%                               Neue Sensoren sind signifikant genauer.
%
% Da tTest ≈ -3.7 und tKritisch ≈ -1.66 gilt:
%   tTest < tKritisch → -3.7 < -1.66 → H0 = false (wird abgelehnt)
%
% WICHTIG:
%   H0 muss ein logischer Wert (logical) sein: true oder false.
%   Die Auswertung '>=' liefert in MATLAB automatisch einen logical-Wert.
%   Kein Semikolon → Wert wird angezeigt.

%% =========================================================
%  Ergebnisinterpretation im Kontext der Spezifikation
% =========================================================

fprintf('--- Aufgabe 8: Interpretation ---\n')
fprintf('Mittlerer absoluter Messfehler neue Serie: e_mean = %.4f°C\n', e_mean)
fprintf('Testwert:        tTest     = %.4f\n', tTest)
fprintf('Kritischer Wert: tKritisch = %.4f\n', tKritisch)

if H0 == false
    % H0 wurde abgelehnt → statistischer Beweis erbracht
    fprintf('Entscheidung: H0 abgelehnt  (tTest < tKritisch)\n')
    fprintf('Schlussfolgerung: Mit %.0f%% Sicherheit sind die neuen Sensoren\n', (1-alpha)*100)
    fprintf('genauer als die Spezifikation von %.1f°C mittl. abs. Fehler.\n', mu0)
    % Inhaltliche Interpretation:
    % Der neue Sensortyp hat einen mittleren absoluten Fehler von e_mean°C.
    % Dies ist statistisch signifikant kleiner als die Spezifikationsgrenze mu0 = 0,5°C.
    % Das Unternehmen kann mit 95% Sicherheit davon ausgehen, dass die neue
    % Serie praeziser ist → Kaufentscheidung positiv begruendbar.
else
    % H0 beibehalten → kein statistischer Nachweis der Verbesserung
    fprintf('Entscheidung: H0 beibehalten (tTest >= tKritisch)\n')
    fprintf('Schlussfolgerung: Es konnte NICHT nachgewiesen werden, dass die\n')
    fprintf('neuen Sensoren genauer sind als %.1f°C mittl. abs. Fehler.\n', mu0)
    % Wichtig: "beibehalten" bedeutet NICHT "H0 ist bewiesen"!
    % Es bedeutet lediglich: die vorliegenden Daten liefern keinen
    % ausreichenden Beweis gegen H0. Fehler 2. Art (beta-Fehler) moeglich.
end
%}