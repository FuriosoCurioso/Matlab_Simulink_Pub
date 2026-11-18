close all; clc;

%% Initialisierung
if ~exist('hArduino', 'var')
    hArduino = arduino('COM3', 'Uno');
    disp('Neues Arduino Objekt erzeugt.')
end

%% Parameter
stPinTaster        = 'D12';  % Eingangs-Pin Taster (Pull-Up)
stPinLEDRot        = 'D13';  % Ausgangs-Pin Rote LED –> Status 1 
stPinLEDGelb       = 'D9';   % Ausgangs-Pin Gelbe LED –> Status 2, 1 Hz 
stPinLEDBlau       = 'D8';   % Ausgangs-Pin Blaue LED –> Status 3, 5 Hz
nMesswerte         = 100;    % Messzyklen
fEntprellZeit_s    = 0.05;   % Entprellzeit (Sek.)
fAbtastZeit_s      = 0.05;   % Abtastzeit 
fLangdruckZeit_s   = 1.0;    % Schwellzeit lange druecken
fHalbperiodeGelb_s = 0.5;    % Halbe Periode Gelbe LED 
fHalbperiodeBlau_s = 0.1;    % Halbe Periode Blaue LED 

configurePin(hArduino, stPinTaster, 'pullup');

%% Entprellvariablen
nLetzterRohzustand   = readDigitalPin(hArduino, stPinTaster); % Letzter Zustand Flankenerkennung
nStabilerZustand     = nLetzterRohzustand;                    % Entprellter Zustand
nZeitLetzteAenderung = tic;                                   % Zeitstempel Initial-Flanke
nDruckZaehler        = uint8(0);                              % Zaehler erkannte Tasterdrucke

%% Statusvariablen
nStatus          = 0;     % Aktueller Status der LED-Maschine (0 bis 3)
bTasterGehalten  = false; % Taster gedrueckt gehalten
nZeitTasterdruck = tic;   % Zeitstempel Tasterdruck (langer Druck)
bBlinkGelb       = false; % Blinkzustand Gelbe LED
bBlinkBlau       = false; % Blinkzustand Blaue LED
nZeitBlinkGelb   = tic;   % Blinktimer Gelbe LED
nZeitBlinkBlau   = tic;   % Blinktimer Blaue LED

fprintf('\nMessschleife: %d Zyklen x %d ms = %.1f s\n', ...
    nMesswerte, fAbtastZeit_s * 1000, nMesswerte * fAbtastZeit_s);
disp('Taster druecken und LED beobachten!');

%% Messschleife
for i = 1:nMesswerte

    nAktuellerRohzustand = readDigitalPin(hArduino, stPinTaster);

    % Initial-Flanke erkannt: Entprelltimer ruecksetzen
    if nAktuellerRohzustand ~= nLetzterRohzustand
        nLetzterRohzustand   = nAktuellerRohzustand;
        nZeitLetzteAenderung = tic;
    end

    % Entprellzeit abgelaufen: stabilen Zustand auswerten
    if toc(nZeitLetzteAenderung) >= fEntprellZeit_s

        % Fallende Flanke: Tasterdruck-Beginn erfassen
        if nStabilerZustand == 1 && nAktuellerRohzustand == 0
            bTasterGehalten  = true;
            nZeitTasterdruck = tic;
            nDruckZaehler    = nDruckZaehler + 1;
        end

        % Steigend Tasterdruck-Ende -> Kurzdruck
        if nStabilerZustand == 0 && nAktuellerRohzustand == 1 && bTasterGehalten
            bTasterGehalten = false;
            nStatus = mod(nStatus + 1, 4);
            fprintf('Kurzdruck erkannt! Status: %d  Gesamt: %d\n', nStatus, nDruckZaehler);
        end

        nStabilerZustand = nAktuellerRohzustand;
    end

    % Langdruck: Status 3 wechseln
    if bTasterGehalten && toc(nZeitTasterdruck) >= fLangdruckZeit_s
        bTasterGehalten = false;
        nStatus = 3;
        fprintf('Langdruck erkannt!  Status: %d  Gesamt: %d\n', nStatus, nDruckZaehler);
    end

    % Gelbe LED aktualisieren
    if toc(nZeitBlinkGelb) >= fHalbperiodeGelb_s
        nZeitBlinkGelb = tic;
        bBlinkGelb = ~bBlinkGelb;
    end

    % Blaue LED aktualisieren
    if toc(nZeitBlinkBlau) >= fHalbperiodeBlau_s
        nZeitBlinkBlau = tic;
        bBlinkBlau = ~bBlinkBlau;
    end

    % LED-Ausgabe gemaess aktuellem Status
    switch nStatus
        case 0
            writeDigitalPin(hArduino, stPinLEDRot,  0);
            writeDigitalPin(hArduino, stPinLEDGelb, 0);
            writeDigitalPin(hArduino, stPinLEDBlau, 0);
        case 1
            writeDigitalPin(hArduino, stPinLEDRot,  1);
            writeDigitalPin(hArduino, stPinLEDGelb, 0);
            writeDigitalPin(hArduino, stPinLEDBlau, 0);
        case 2
            writeDigitalPin(hArduino, stPinLEDRot,  0);
            writeDigitalPin(hArduino, stPinLEDGelb, bBlinkGelb);
            writeDigitalPin(hArduino, stPinLEDBlau, 0);
        case 3
            writeDigitalPin(hArduino, stPinLEDRot,  0);
            writeDigitalPin(hArduino, stPinLEDGelb, 0);
            writeDigitalPin(hArduino, stPinLEDBlau, bBlinkBlau);
    end

    pause(fAbtastZeit_s);
end

%% Abschluss
writeDigitalPin(hArduino, stPinLEDRot,  0);
writeDigitalPin(hArduino, stPinLEDGelb, 0);
writeDigitalPin(hArduino, stPinLEDBlau, 0);

% Ausgabe finaler Ergebnisse
fprintf('\nErkannte Tasterdrucke (entprellt): %d\n', nDruckZaehler);

% Ausgabe letzter finaler Status
fprintf('Finaler Status: %d\n', nStatus);

if nDruckZaehler == 0
    disp('WARNUNG: Kein Tasterdruck erkannt.')
else
    disp('Funktion korrekt: Taster entprellt, Statusmaschine aktiv.')
end

% clear hArduino