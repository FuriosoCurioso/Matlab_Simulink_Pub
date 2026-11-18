close all; clear all; clc;


%% Konfiguration

N_MESS_PRO_DIST = 50;          % Anzahl Einzelmessungen pro Referenzdistanz
N_MEDIANFILTER  = 5;           % Fensterbreite des Medianfilters (muss ungerade sein)
AREF            = 5.0;         % Referenzspannung des ADU in V
N_ADC_BITS      = 10;          % Aufloesung des AD-Wandlers in Bit
N_ADC_STUFEN    = 2^N_ADC_BITS; % Anzahl Quantisierungsstufen (1024)
F_ULBS          = AREF / (N_ADC_STUFEN - 1); % Spannungsaufloesung pro LSB in V
F_ABTASTZEIT    = 0.021;       % Abtastintervall 25 ms > Sensorzykluszeit ~21 ms
ALPHA_KONF      = 0.95;        % Konfidenzniveau fuer Vorhersageintervall

stAnalogPin = 'A0';            % Analoger Eingangspin des IR-Sensors

% Referenzdistanzen in cm (gleichmaessig ueber Messbereich verteilt)
afRefDistanz  = [4 6 8 10 12 24]; % in cm
nAnzahlDist   = length(afRefDistanz);

%% Arduino-Verbindung herstellen
hArduino = arduino();

%% Datenerfassung: Spannungsmesswerte an Referenzdistanzen
afRohU = zeros(N_MESS_PRO_DIST, nAnzahlDist); % Rohspannungen in V

for i = 1:nAnzahlDist
    input(['Objekt auf ' num2str(afRefDistanz(i)) ' cm positionieren, dann Enter druecken.'], 's');
    for j = 1:N_MESS_PRO_DIST
        afRohU(j, i) = readVoltage(hArduino, stAnalogPin); % Spannung in V
        pause(F_ABTASTZEIT);
    end
end

clear hArduino;

%% Medianfilterung der Rohwerte
afGefU = zeros(size(afRohU)); % Gefilterte Spannungen in V

for i = 1:nAnzahlDist
    afGefU(:, i) = medfilt1(afRohU(:, i), N_MEDIANFILTER);
end

%% Plot Rohwerte vs. gefilterte Werte

nBspIdx  = round(nAnzahlDist / 2); % Mittlere Referenzdistanz als Beispiel
fBspDist = afRefDistanz(nBspIdx);  % zugehoerige Distanz in cm
anMessNr = (1:N_MESS_PRO_DIST)';   % Laufindex fuer x-Achse

figure('Name', 'Rohwerte vs. gefilterte Werte');
plot(anMessNr, afRohU(:, nBspIdx), 'b.', 'MarkerSize', 8);
hold on;
plot(anMessNr, afGefU(:, nBspIdx), 'r-', 'LineWidth', 1.5);
hold off;
xlabel('Messung Nr.');
ylabel('Spannung in V');
title(['Rohwerte vs. Medianfilter (d = ' num2str(fBspDist) ' cm)']);
legend('Rohwerte', ['Medianfilter (N = ' num2str(N_MEDIANFILTER) ')'], 'Location', 'best');
grid on;

%% Mittelwerte der gefilterten Spannungen pro Referenzdistanz

afMittelU = mean(afGefU, 1)'; % Spaltenvektor, je Distanz ein Mittelwert in V

%% Nichtlineare Regression (Potenzmodell d = a * U^b)

% Potenzmodell: fDistanz = a * fSpannung^b
% Linearisierung: ln(d) = ln(a) + b * ln(U) -> Startwerte fuer nichtlinearen Fit

afLogU = log(afMittelU);      % ln(Spannung)
afLogD = log(afRefDistanz');  % ln(Distanz)

% Startwertschaetzung ueber lineare Regression im Log-Raum
afStartK = polyfit(afLogU, afLogD, 1); % [b, ln(a)]
fStartB  = afStartK(1);
fStartA  = exp(afStartK(2));

% Nichtlinearer Fit mit Curve Fitting Toolbox
stModell        = fittype('a * x^b', 'independent', 'x', 'dependent', 'y');
stOpt           = fitoptions(stModell);
stOpt.StartPoint = [fStartA fStartB];

[hFit, sGof] = fit(afMittelU, afRefDistanz', stModell, stOpt);

fKoefA = hFit.a; % Koeffizient a des Potenzmodells
fKoefB = hFit.b; % Exponent b des Potenzmodells

%% Bestimmtheitsmass R^2

fRQuad = sGof.rsquare; % Bestimmtheitsmass der Regression

%% Plot Messpunkte, Regressionskurve, 95%-Konfidenzintervall

afUFein   = linspace(min(afMittelU), max(afMittelU), 200)'; % Feine Stuetzstellen in V
afDistFit = feval(hFit, afUFein);                            % Regressionskurve in cm

% 95%-Vorhersageintervall (prediction interval)
afKonf = predint(hFit, afUFein, ALPHA_KONF, 'functional', 'on');

figure('Name', 'Regression und Konfidenzintervall');
plot(afMittelU, afRefDistanz, 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
hold on;
plot(afUFein, afDistFit, 'b-', 'LineWidth', 1.5);
plot(afUFein, afKonf(:, 1), 'r--', 'LineWidth', 1);
plot(afUFein, afKonf(:, 2), 'r--', 'LineWidth', 1);
hold off;
xlabel('Spannung in V');
ylabel('Entfernung in cm');
title(['Nichtlineare Regression: d = ' num2str(fKoefA, '%.2f') ...
       ' \cdot U^{' num2str(fKoefB, '%.2f') '}, R^2 = ' num2str(fRQuad, '%.4f')]);
legend('Messpunkte', 'Regressionskurve', '95%-Konfidenzintervall', 'Location', 'best');
grid on;

%% Sensorparameter

% Messbereich
fMbMin = afRefDistanz(1);   % Minimale kalibrierte Distanz in cm
fMbMax = afRefDistanz(end); % Maximale kalibrierte Distanz in cm

% Zeitliche Aufloesung
% Sensorzykluszeit laut Datenblatt: 16,5 ms +/- 3,7 ms plus max. 5 ms instabil
% -> effektive minimale Abtastperiode ca. 25 ms
fZeitAufl = F_ABTASTZEIT * 1000; % in ms

% Entfernungsaufloesung
% Kleinste unterscheidbare Entfernungsaenderung bei 1 LSB Spannungsaenderung
% dDelta_d/dU = a * b * U^(b-1), ausgewertet am mittleren Arbeitspunkt
fMittelU   = median(afMittelU);                                 % repraesentativer Arbeitspunkt in V
fEmpfDdDu  = abs(fKoefA * fKoefB * fMittelU^(fKoefB - 1));    % |dd/dU| in cm/V
fDistAufl  = fEmpfDdDu * F_ULBS;                               % Aufloesung in cm (bei 1 LSB)

% Empfindlichkeit (Ableitung dU/dd am mittleren Arbeitspunkt)
% Inverse der obigen Beziehung: dU/dd = 1 / (dd/dU)
fEmpfindl = 1 / fEmpfDdDu; % in V/cm

%% Ergebnisausgabe Sensorparameter

fprintf('\n--- Sensorparameter Sharp GP2Y0A41SK0F ---\n');
fprintf('Regressionsmodell:     d = %.2f * U^(%.2f)\n', fKoefA, fKoefB);
fprintf('Bestimmtheitsmass R^2: %.4f\n', fRQuad);
fprintf('Messbereich:           %.0f cm .. %.0f cm\n', fMbMin, fMbMax);
fprintf('Zeitliche Aufloesung:  %.1f ms\n', fZeitAufl);
fprintf('Entfernungsaufloesung: %.3f cm (bei mittlerer Spannung %.2f V)\n', fDistAufl, fMittelU);
fprintf('Empfindlichkeit:       %.4f V/cm (bei mittlerer Spannung %.2f V)\n', fEmpfindl, fMittelU);
