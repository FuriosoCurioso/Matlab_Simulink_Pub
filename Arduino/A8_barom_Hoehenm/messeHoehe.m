clear all; close all; clc;

%% Aufg1+2: Arduino und I2C Initialisierung 
if exist('hArduino', 'var') == 0
    disp('Versuche Arduino Objekt zu erzeugen...')
    hArduino = arduino('COM4', 'Uno');
    disp('Neues Arduino Objekt erzeugt...')
    hBMP180 = device(hArduino, "I2CAddress", "0x77");
    disp('I2C-Objekt erzeugt...')
end

% Chip-ID aus Register 0xD0 lesen
readRegister(hBMP180, 0xD0, 1); % Chip-ID = 0x55

% OSS (Oversampling Setting): steuert Messgenauigkeit vs. Geschwindigkeit.
% OSS=0: schnellste Messung, geringste Aufloesumg.
OSS = 0; % Oversampling: 0 = niedrig
disp(['OSS = ', num2str(OSS)])
disp('-----------------------------')

%% %% Aufg3: Konstanten barometrische Hoehenformel (Skalare -> Typ double)
fTempNull  = 288.15;  % T0: Standard-Temperatur Meeresspiegel in K
fTempGrad  = 0.0065;  % L: Temperaturgradient in K/m
fGravit    = 9.81;    % g: Erdbeschleunigung in m/s^2
fGasKonst  = 287.05;  % R: Gaskonstante J/(kg*K)
fDruckNull = 101325;  % p0: Normaldruck Meereshoehe in Pa

% beschreibt die Nichtlinearitaet der Druckabnahme mit der Hoehe
fExponent  = 1/5.256;

nMesswerte = 50;

%% Arrays initialisieren
afDruck  = zeros(1, nMesswerte);  % Rohdruck-Messvektor 
afTempC  = zeros(1, nMesswerte);  % Temperaturvektor   

%% Aufg1: Kalibrierwerte des Sensors lesen
% Struct mit 11 Feldern (AC1..AC6, B1, B2, MB, MC, MD)->leseBMP180Temperatur und leseBMP180Druck
% dient Rohwert-Kompensation!
AC = leseKalibrierwerte(hBMP180);

%% Aufg1. Messschleife: Temperatur und Druck erfassen
for i = 1:nMesswerte
    B5 = leseBMP180Temperatur(hBMP180, AC);   % Temp. muss vor Druc (B5 interner Kompensationswert)

    B.B5 = B5; % % B5 in Struct->  Druckfunktion
    afTempC(i) = ((B5 + 8) / 16) / 10; % BMP180-Rohdaten -> Grad °C
    afDruck(i) = leseBMP180Druck(hBMP180, AC, B, OSS); % Druck in Pa

end

% clear hArduino

%% Aufg6: Hoehenberechnung: h = (T0/L) * [1 - (p/p0)^(g/(R*L))]
% ZIEL: Jeden der 50 Druckwerte in eine Hoehe ueber Meeresspiegel umrechnen.
% DATENFLUSS: afDruck [1x50 Pa] -> afHoehe [1x50 m]
% barom. Hoehenformel mit  h = (T0/L) * [ 1 - (p/p0)^(g/(R*L)) ]
afHoehe = (fTempNull / fTempGrad) * (1 - (afDruck / fDruckNull).^fExponent);

%%  Aufg4: Statistische Kenngroessen Druck
% ZIEL: Rauschverhalten des Drucksensors statistisch beschreiben.
% DATENFLUSS: Eingang afDruck [1x50 Pa], Ausgang Skalar (double, Pa).
% mean():      arithmetisches Mittel
% std():       Standardabweichung Mass fuer die Streuung (1sigma Rauschen)
% min()/max(): Extremwerte
% Spannweite:  fMaxDruck - fMinDruck gibt den gesamten Schwankungsbereich an
fMittelDr = mean(afDruck);
fStdDruck = std(afDruck); % tatsaechlich gemessene Standardabweichung
fMinDruck = min(afDruck);
fMaxDruck = max(afDruck);
fSpanneDr = fMaxDruck - fMinDruck; % Spannweite = Rauschindikator

%% Aufg4: Statistische Kenngroessen Hoehe
% ZIEL: Statistische Charakterisierung der berechneten Hoehenverteilung.
% DATENFLUSS: Eingang: afHoehe [1x50 m], Ausgang: Skalar (double, m).
fMittelH  = mean(afHoehe); % Mittlere Hoehe [m]
fStdHoehe = std(afHoehe);  % std Hoehe [m]
fMinHoehe = min(afHoehe);
fMaxHoehe = max(afHoehe);
fSpanneH  = fMaxHoehe - fMinHoehe;  % Hoehenspanne (Spitze-Spitze->Rauschen) [m]

%% Hoehenaenderung aus Druckdifferenzen
afDeltaH = diff(afHoehe); % Aenderung zwischen Messungen

%% Aufg8: Sensitivitaetsanalyse: dh/dp numerisch (zentrale Differenz)
% ZIEL: Empfindlichkeit Hoehenformel gegenueber Druckaenderungen bestimmen
% -> Hoehenunischerheit
% DATENFLUSS: Eingang: fMittelDr [Pa], fStdDruck [Pa]
%             Ausgang: fSensitiv [m/Pa], fUnsichH [m], fUnsichDB [m]
fDeltaP   = 1; % Variation um 1 Pa

% Hoehenformel bei p + dp (Druck leicht erhoehen -> Hoehe sinkt) 
% fHMinus -> Druck verr. -> Hoehe steigt
fHPlus    = (fTempNull / fTempGrad) * (1 - ((fMittelDr + fDeltaP) / fDruckNull)^fExponent);
fHMinus   = (fTempNull / fTempGrad) * (1 - ((fMittelDr - fDeltaP) / fDruckNull)^fExponent);
% dh/dp in m/Pa  negativer Wert, da h mit p faellt
fSensitiv = (fHPlus - fHMinus) / (2 * fDeltaP);

% Messunsicherheit Hoehe aus gemessener Streuung
fUnsichH  = abs(fSensitiv) * fStdDruck;
% Unsicherheit aus Datenblatt-Genauigkeit (BMP180: +/- 12 Pa)
% gibt ABSOLUTEN Fehler laut Hersteller an ->  Vergleich fUnsichH ->
% Rauschen oder system. Fehler
fUnsichDB = abs(fSensitiv) * 12;

%% Aufg4+5 :Gleitender Mittelwert-Filter Algorithmus (kausal -> vergangene Werte)
% ZIEL: Rauschen in afHoehe durch zeitliche Mittelung reduzieren.
% DATENFLUSS: Eingang afHoehe -> Ausgang afGefHoehe

nFiltLen   = 5; % Fensterlaenge
afGefHoehe = zeros(1, nMesswerte); % Gefilterter Hoehenvektor
for i = 1:nMesswerte
    nStart = max(1, i - nFiltLen + 1);
    afGefHoehe(i) = mean(afHoehe(nStart:i));
end

save('Hoehe.mat', 'afDruck', 'afTempC', 'afHoehe', 'afGefHoehe', ...
    'fMittelDr', 'fStdDruck', 'fMittelH', 'fStdHoehe', ...
    'fSensitiv', 'fUnsichH');

% fStdGefilt < fStdHoehe belegt die Rauschreduktion.
fStdGefilt = std(afGefHoehe); % Streuung nach Filterung

%% Daten speichern


%% Visualisierung Druckverlauf
figure;
subplot(3, 1, 1);
plot(1:nMesswerte, afDruck, 'b-');
xlabel('Messung'); % Messindex
ylabel('Druck (Pa)'); % Luftdruck
title('Luftdruck BMP180');
grid on;

%% Visualisierung Hoehe roh und gefiltert
subplot(3, 1, 2);
plot(1:nMesswerte, afHoehe, 'b-', 1:nMesswerte, afGefHoehe, 'r-');
xlabel('Messung');
ylabel('Hoehe (m)');
title('Barometrische Hoehe: Roh vs. Gefiltert');
legend('Rohdaten', 'Gefiltert');
grid on;

%% Visualisierung Temperatur
% afTempC aus B5 berechnet (nicht direkt Sensor!) Kurve sollte konstant
% sein! starke Schwankungen -> Fehler Temp. berechnung!
subplot(3, 1, 3);
plot(1:nMesswerte, afTempC, 'g-');
xlabel('Messung');
ylabel('Temperatur (C)');
title('Temperaturverlauf BMP180');
grid on;


%% Bewertung und Diskussion der Lernziele
%
% Aufg1.: Sensorik und Datenerfassung:
% Der BMP180  kommuniziert ueber I2C-Bus mit Adresse 0x77,Kalibrierregister (AC1-MD) werden beim Start gelesen. 
% Die Temperatur muss immer VOR! dem Druck gemessen werden, da der Zwischenwert B5 fuer die 
% Druckkompensation noetig ist.
%
% Rauschverhalten:
% fStdDruck zeigt die Standardabweichung der Druckwerte (Sensorrauschen).
% fSpanneDr (Max - Min) zeigt die maximale Schwankungsbreite.
% Laut Datenblatt hat der BMP180 eine absolute Genauigkeit von +/- 12 Pa.
% Liegt fStdDruck darunter, arbeitet der Sensor praezise ansonsten schlecht!
% Je kleiner das Rauschen, desto feiner die Hoehenaufloesung.
%
%  Hoehenberechnunh bewerten
% Die barometrische Formel h = (T0/L)*[1-(p/p0)^(g/(R*L))] liefert die
% Hoehe bezogen auf Standardatmosphaere. Bei p = p0 ergibt sich h = 0 m.
% Die Formel gilt exakt nur bei Standardbedingungen (15 C, kein Wind).
% Fuer relative Hoehenaenderungen genuegt die Differenz afDeltaH.
%
%  Messunsicherheit (Sensitivitaetsanalyse) abschätzen
% fSensitiv ≈ -0.08 m/Pa zeigt: 1 Pa Druckaenderung ≈ 8 cm Hoehe.
% fUnsichH = |dh/dp| * sigma_p gibt den 1-Sigma-Hoehenfehler aus der
% gemessenen Streuung. fUnsichDB zeigt den Fehler aus Datenblatt-Angabe.
% Beispiel: Bei sigma_p = 5 Pa ergibt sich ca. 0.4 m Unsicherheit.
%
% Filtereinfluss auf Genauigkeit und Dynamik bewerten
% Der gleitende Mittelwert (Fenster = 5) reduziert das Rauschen:
% fStdGefilt < fStdHoehe. Nachteil: Latenz schnellen Hoehenaenderungen.
% Grosses Fenster glättet besser aber langsam -> anpassen
% Fuer langsame Aenderungen (Wandern): grosses Fenster.
% Fuer schnelle Aenderungen (Drohne): kleines Fenster oder Kalman-Filter ;-) .
%
% Eignung Sensor bewerten
% Gut geeignet fuer relative Hoehenmessung (z.B. Stockwerkerkennung mit
% ca. 3 m Aufloesung). Fuer absolute Hoehen ist Referenzdruckkalibrierung
% noetig, da die Wetterlage den Luftdruck am Boden veraendert.

%% Hilfsfunktionen (gegeben)

function p = leseBMP180Druck(bmp, AC, B, OSS)
    if nargin == 3
        OSS = 0;
    end

    switch OSS
        case 0
            cmd = hex2dec('34');
            fPause = 0.005;
        case 1
            cmd = hex2dec('74');
            fPause = 0.008;
        case 2
            cmd = hex2dec('B4');
            fPause = 0.014;
        case 3
            cmd = hex2dec('F4');
            fPause = 0.026;
    end

    nBitshift = 8 - OSS;
    writeRegister(bmp, hex2dec('F4'), cmd);
    pause(fPause);

    data = readRegister(bmp, hex2dec('F6'), 3);
    msb  = double(data(1));
    lsb  = double(data(2));
    xlsb = double(data(3));

    UP = uint32(msb) * 65536 + uint32(lsb) * 256 + uint32(xlsb);
    UP = double(bitshift(UP, -nBitshift));

    if ~isfield(B, 'B5')
        error('B.B5 fehlt! Temperatur muss zuerst gemessen werden.');
    end
    B5 = B.B5;

    %% Bosch Druckberechnung
    B6 = B5 - 4000;

    X1 = (double(AC.B2) * (B6^2 / 2^12)) / 2^11;
    X2 = double(AC.AC2) * B6 / 2^11;
    X3 = X1 + X2;
    B3 = ((double(AC.AC1) * 4 + X3) + 2) / 4;

    X1 = double(AC.AC3) * B6 / 2^13;
    X2 = (double(AC.B1) * (B6^2 / 2^12)) / 2^16;
    X3 = ((X1 + X2) + 2) / 4;
    B4 = double(AC.AC4) * (X3 + 32768) / 2^15;

    B7 = (double(UP) - B3) * 50000;

    if B7 < 2^31
        p = (B7 * 2) / B4;
    else
        p = (B7 / B4) * 2;
    end

    X1 = (p / 2^8)^2;
    X1 = (X1 * 3038) / 2^16;
    X2 = (-7357 * p) / 2^16;
    p = p + (X1 + X2 + 3791) / 16;
    p = double(p);
end

function AC = leseKalibrierwerte(bmp)
    AC.AC1 = readInt16(bmp, 0xAA);
    AC.AC2 = readInt16(bmp, 0xAC);
    AC.AC3 = readInt16(bmp, 0xAE);
    AC.AC4 = readUInt16(bmp, 0xB0);
    AC.AC5 = readUInt16(bmp, 0xB2);
    AC.AC6 = readUInt16(bmp, 0xB4);
    AC.B1  = readInt16(bmp, 0xB6);
    AC.B2  = readInt16(bmp, 0xB8);
    AC.MB  = readInt16(bmp, 0xBA);
    AC.MC  = readInt16(bmp, 0xBC);
    AC.MD  = readInt16(bmp, 0xBE);
end

function B5 = leseBMP180Temperatur(bmp, AC)
    writeRegister(bmp, 0xF4, 0x2E);
    pause(0.005);
    d = readRegister(bmp, 0xF6, 2);
    UT = d(1) * 256 + d(2);
    X1 = (double(UT) - double(AC.AC6)) * double(AC.AC5) / 2^15;
    X2 = double(AC.MC) * 2^11 / (X1 + double(AC.MD));
    B5 = X1 + X2;
end

function val = readInt16(dev, reg)
    d = readRegister(dev, reg, 2);
    val = double(typecast(uint8([d(2) d(1)]), 'int16'));
end

function val = readUInt16(dev, reg)
    d = readRegister(dev, reg, 2);
    val = double(typecast(uint8([d(2) d(1)]), 'uint16'));
end