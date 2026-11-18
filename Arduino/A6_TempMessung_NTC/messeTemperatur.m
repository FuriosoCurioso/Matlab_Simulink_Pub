close all; clear all; clc;

% Parameter der Messschaltung (NTC 110 kOhm)
const_R1      = 110000;  % Vorwiderstand R1 in Ohm -> festunten
const_R25     = 110000;  % NTC-Nennwiderstand Messung-> temp. Abhängig
const_B       = 3990;    % B-Parameter des NTC in K (Datenblatt)
const_T0_K    = 298.15;  % Bezugstemperatur T0 in K (25°C)
const_U0      = 5.0;     % Versorgungsspannung Arduino in V
const_ADC_MAX = 1023;    % Maximaler ADC-Wert (10-Bit ADC)
const_N_MESS  = 200;     % Anzahl Messwiederholungen fuer seriellen Plotter
stPinLEDRot        = 'D13';  % Ausgangs-Pin Rote LED
stPinLEDGruen        = 'D12';  % Ausgangs-Pin Rote LED
% Arduino Verbindung herstellen
hArduino = arduino();

% Speicher fuer Messwerte vorallokieren
afTemp_C  = zeros(1, const_N_MESS);  % Gemessene Temperaturen in °C
anDigWort = zeros(1, const_N_MESS);  % ADC-Digitalwerte

% Live-Plot initialisieren (Serielle-Plotter in MATLAB)
hFig     = figure;                            % Handle auf Figure-Fenster
hAx      = axes(hFig);                        % Handle auf Achsenbeschriftung
hLine    = plot(hAx, NaN, NaN, 'r-');         % hLine: Handle der Temperaturkurve fuer Live-Update
hold(hAx, 'on');
hMean    = plot(hAx, NaN, NaN, 'b-');         % Handle gleitender Mittelwert (blau)
hSigPos  = plot(hAx, NaN, NaN, 'k--');        % Handle oberes Konfidenzband +sigma (schwarz)
hSigNeg  = plot(hAx, NaN, NaN, 'k--');        % Handle unteres Konfidenzband -sigma (schwarz)
xlabel(hAx, 'Messung');
ylabel(hAx, 'Temperatur in °C');
title(hAx,  'NTC MF58 3950 B – Temperaturmessung');
grid(hAx, 'on');

% feste Achsengrenzen
xlim(hAx, [1, const_N_MESS]);
ylim(hAx, [-10, 60]);  % Erwarteter Temperaturbereich

%% Schritt: Messchleife lesen, R(T) und T berechnen
% Datenfluss: readVoltage -> fU_A0 -> nDigWort -> fR2 -> fT_K -> fT_C -> afTemp_C(i)
for i = 1 : const_N_MESS

    % Physikalischer Zusammenhang (Spannungsteiler):
    %   UA0 = U0 * R1 / (R2(T) + R1)
    %   Mit steigender Temperatur sinkt R2 -> UA0 steigt.
    fU_A0 = readVoltage(hArduino, 'A0');

    % Umkehrformel: Digitalwort = UA0 / U0 * 1023
    % round() rundet auf den nächsten ganzzahligen ADU-Wert, da der ADU
    % nur ganzzahlige Digitalworte liefert.
    % nDigWort wird für spätere Auswertung gespeichert
    nDigWort      = round(fU_A0 / const_U0 * const_ADC_MAX);
    anDigWort(i)  = nDigWort;

    % Widerstand R2(T) aus Digitalwort berechnen
    % R2(T) = R1 * (1023 / Digitalwort - 1) → Spannungsteilerformel umgestellt
    fR2 = const_R1 * (const_ADC_MAX / nDigWort - 1);  % NTC-Widerstand in Ohm

    % Temperatur T aus B-Parameter-Naeherung berechnen
    % 1/T = 1/T0 + (1/B) * ln(R2/R25)
    % T = 1 / [ 1/T0 + (1/B)*ln(R2/R25) ]   [K]
    % log() = natürlicher Logarithmus (ln), nicht log10!
    fT_K       = 1 / (1/const_T0_K + (1/const_B) * log(fR2 / const_R25));  % Temperatur in K
    fT_C       = fT_K - 273.15;                                              % Umrechnung in °C
    afTemp_C(i) = fT_C;

    % Gleitenden Mittelwert und Standardabweichung ueber letzte 10 Werte berechnen
    nWinStart   = max(1, i - 9);                         % Index1
    afFenster   = afTemp_C(nWinStart : i);               % Letzte 10 Messwerte
    fMittel     = mean(afFenster);                       % Gleitender Mittelwert in °C
    fSigma      = std(afFenster);                        % Standardabweichung im Fenster in °C

    % LED-Steuerung 
    if fSigma >= 0.5
        writeDigitalPin(hArduino, 'D13', 1);  
        writeDigitalPin(hArduino, 'D12', 0);  
    else
        writeDigitalPin(hArduino, 'D13', 0);  
        writeDigitalPin(hArduino, 'D12', 1);  
    end

    % Live-Plot
    set(hLine,   'XData', 1:i, 'YData', afTemp_C(1:i));
    set(hMean,   'XData', 1:i, 'YData', [afTemp_C(1:nWinStart-1), repmat(fMittel, 1, i-nWinStart+1)]);
    set(hSigPos, 'XData', 1:i, 'YData', [afTemp_C(1:nWinStart-1), repmat(fMittel + fSigma, 1, i-nWinStart+1)]);
    set(hSigNeg, 'XData', 1:i, 'YData', [afTemp_C(1:nWinStart-1), repmat(fMittel - fSigma, 1, i-nWinStart+1)]);
    drawnow;

    pause(0.1);  % begrenzt die Abtastrate auf ~10 Hz -> therm. Signal

end

% Verbindung sauber beenden
clear hArduino;