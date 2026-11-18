%% Messwerte und gefilterte Werte vergleichend darstellen (Abb. 1)
% Darstellung einer repraesentativen Messreihe (mittlere Kalibrierposition)
% als Rohwerte (blaue Punkte) und gefilterte Werte (rote Linie).

%% Daten laden
load('IR_Messung.mat', 'Zeit', 'Spannung');

nBspIdx  = round(nAnzahlDist / 2);
fBspDist = afRefDistanz(nBspIdx);
anMessNr = (1:N_MESS_PRO_DIST)';

figure('Name', 'Abb. 1: Rohwerte vs. gefilterte Werte');
plot(anMessNr, afRohU(:, nBspIdx), 'b.', 'MarkerSize', 8);
hold on;
plot(anMessNr, afGefU(:, nBspIdx), 'r-', 'LineWidth', 1.5);
plot(anMessNr, ones(N_MESS_PRO_DIST, 1) * afMittelU(nBspIdx), 'k--', 'LineWidth', 1);
hold off;
xlabel('Messung Nr.');
ylabel('Spannung in V');
title(['Rohwerte vs. Medianfilter (d = ' num2str(fBspDist) ' cm)']);
legend('Rohwerte', ['Medianfilter (N = ' num2str(N_MEDIANFILTER) ')'], ...
       'Mittelwert', 'Location', 'best');
grid on;

%% Spannung in V mittels nichtlinearer Regression in Entfernung in cm umrechnen
% Potenzmodell d = a * U^b; Startwerte aus Log-Linearisierung.

afMittelU_col = afMittelU';
afRefDist_col = afRefDistanz';

afLogU   = log(afMittelU_col);
afLogD   = log(afRefDist_col);
afStartK = polyfit(afLogU, afLogD, 1);
fStartB  = afStartK(1);
fStartA  = exp(afStartK(2));

stModell         = fittype('a * x^b', 'independent', 'x', 'dependent', 'y');
stOpt            = fitoptions(stModell);
stOpt.StartPoint = [fStartA fStartB];

[hFit, sGof] = fit(afMittelU_col, afRefDist_col, stModell, stOpt);

fKoefA = hFit.a;
fKoefB = hFit.b;

%% Bestimmtheitsmass R^2 der Regression angeben

fRQuad = sGof.rsquare;

%% Entfernung in cm, Regressionskurve und 95%-KI zeichnen (Abb. 2)

afUFein   = linspace(min(afMittelU_col), max(afMittelU_col), 200)';
afDistFit = feval(hFit, afUFein);
afKonf    = predint(hFit, afUFein, ALPHA_KONF, 'functional', 'on');

figure('Name', 'Abb. 2: Regression und 95%-Konfidenzintervall');
plot(afMittelU_col, afRefDist_col, 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
hold on;
plot(afUFein, afDistFit, 'b-', 'LineWidth', 1.5);
plot(afUFein, afKonf(:, 1), 'r--', 'LineWidth', 1);
plot(afUFein, afKonf(:, 2), 'r--', 'LineWidth', 1);
hold off;
xlabel('Spannung in V');
ylabel('Entfernung in cm');
title(['d = ' num2str(fKoefA, '%.2f') ' \cdot U^{' num2str(fKoefB, '%.2f') ...
       '},  R^2 = ' num2str(fRQuad, '%.4f')]);
legend('Messpunkte', 'Regressionskurve', '95%-Konfidenzintervall', 'Location', 'best');
grid on;

%% Sensorkennwerte bestimmen: MB, at, ad, E
% MB [cm]:   Messbereich = kleinster und groesster kalibrierter Abstand
% at [s]:    zeitliche Aufloesung = Abtastintervall
% ad [cm]:   Entfernungsaufloesung = |dd/dU| * U_LSB (arbeitspunktabhaengig)
% E  [cm/V]: Empfindlichkeit = |dd/dU| = |a * b * U^(b-1)| (1. Ableitung)
%
% ad und E werden an allen 16 Messpunkten berechnet, um das Verlauf
% ueber den Messbereich darzustellen (

MB = [afRefDistanz(1), afRefDistanz(end)];
at = F_ABTASTZEIT;

afE_Verlauf  = abs(fKoefA .* fKoefB .* afMittelU_col.^(fKoefB - 1));
afAd_Verlauf = afE_Verlauf .* F_ULBS;

E  = median(afE_Verlauf);
ad = median(afAd_Verlauf);

%% Sensorkennwerte in 2x2 Subplots darstellen (Abb. 3)
% [Annahme] "4x4 Subplots" wird als 2x2-Anordnung (4 Panels fuer 4 Parameter)
%           interpretiert. Eine 4x4-Matrix (16 Panels) ergibt fuer 4 Kennwerte
%           keinen sinnvollen Inhalt.

figure('Name', 'Abb. 3: Sensorkennwerte');

subplot(2, 2, 1);
plot(afRefDist_col, afMittelU_col, 'bo-', 'MarkerFaceColor', 'b');
hold on;
xline(MB(1), 'r--', 'LineWidth', 1);
xline(MB(2), 'r--', 'LineWidth', 1);
hold off;
xlabel('Entfernung d in cm');
ylabel('Spannung U in V');
title(['Messbereich: ' num2str(MB(1)) ' .. ' num2str(MB(2)) ' cm']);
legend('Kennlinie U(d)', ['MB_{min} = ' num2str(MB(1)) ' cm'], ...
       ['MB_{max} = ' num2str(MB(2)) ' cm'], 'Location', 'best');
grid on;

subplot(2, 2, 2);
fSensorZyklus = 0.0165;
bar([at, fSensorZyklus]);
set(gca, 'XTickLabel', {'Abtastzeit a_t', 'Sensorzykluszeit'});
ylabel('Zeit in s');
title(['Zeitliche Aufloesung: a_t = ' num2str(at * 1000, '%.1f') ' ms']);
legend('Zeitparameter', 'Location', 'best');
grid on;

subplot(2, 2, 3);
plot(afRefDist_col, afAd_Verlauf, 'go-', 'MarkerFaceColor', 'g');
hold on;
yline(ad, 'k--', 'LineWidth', 1);
hold off;
xlabel('Entfernung d in cm');
ylabel('a_d in cm');
title(['Entfernungsaufloesung (Median: ' num2str(ad, '%.4f') ' cm)']);
legend('a_d(d)', ['Median = ' num2str(ad, '%.4f') ' cm'], 'Location', 'best');
grid on;

subplot(2, 2, 4);
plot(afRefDist_col, afE_Verlauf, 'mo-', 'MarkerFaceColor', 'm');
hold on;
yline(E, 'k--', 'LineWidth', 1);
hold off;
xlabel('Entfernung d in cm');
ylabel('E in cm/V');
title(['Empfindlichkeit (Median: ' num2str(E, '%.2f') ' cm/V)']);
legend('E(d) = |dd/dU|', ['Median = ' num2str(E, '%.2f') ' cm/V'], 'Location', 'best');
grid on;

%% Wissenschaftliche Beschriftung
% Alle drei Figuren (Abb. 1, 2, 3) enthalten:
%   - xlabel und ylabel mit physikalischer Groesse und Einheit
%   - title mit Kennwerten
%   - legend bei >2 Kurven bzw. Datenserien
%   - grid on fuer Werteablesung

%% Ergebnisausgabe

fprintf('\n--- Sensorparameter Sharp GP2Y0A41SK0F ---\n');
fprintf('Regressionsmodell:     d = %.2f * U^(%.2f)\n', fKoefA, fKoefB);
fprintf('Bestimmtheitsmass R^2: %.4f\n', fRQuad);
fprintf('Messbereich MB:        %d cm .. %d cm\n', MB(1), MB(2));
fprintf('Zeitliche Aufloesung:  %.1f ms\n', at * 1000);
fprintf('Entfernungsaufloesung: %.4f cm (Median ueber MB)\n', ad);
fprintf('Empfindlichkeit:       %.2f cm/V (Median ueber MB)\n', E);

%% Annahmen und Hinweise
% [Annahme] "4x4 Subplots" (als 2x2-Anordnung interpretiert:
%           4 Panels fuer 4 Sensorkennwerte. 16 Panels fuer 4 Kennwerte
%           waere inhaltlich nicht sinnvoll.
% [Annahme] Empfindlichkeit E = |dd/dU| in cm/V (laut und Tipps:
%           E = Delta_y / Delta_x = dd/dU). Dies ist der Betrag der
%           Ableitung des Potenzmodells nach U.
% [Annahme] ad und E werden an allen 16 Messpunkten berechnet und als
%           Median zusammengefasst, da beide arbeitspunktabhaengig sind.
% [Annahme] "Zeit in s" in IR_Messung.mat: kumulierte Laufzeit seit
%           Skriptstart (via tic/toc), da die Schritt kein Zeitformat
%           spezifiziert.
% [Hinweis] Die Spezifikation sieht zwei Skripte vor:
%           messeIREntfernung.m (4, Datenerfassung + Speicherung)
%           analysiereIREntfernung.m (11, Analyse + Visualisierung).
%           Dieses Skript fasst beide Teile zusammen. Trennpunkt waere
%           nach dem save()-Befehl (; analysiereIREntfernung.m
%           wuerde mit load('IR_Messung.mat') beginnen.