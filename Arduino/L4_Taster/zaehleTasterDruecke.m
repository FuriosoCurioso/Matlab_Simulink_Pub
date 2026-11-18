close all; clc; % Initialisierung
if ~exist('hArduino','var')
    hArduino = arduino('COM8','Uno'); % Arduino Objekt erzeugen
    disp('Neues Arduino Objekt erzeugt.')
end

configurePin(hArduino, 'D12', 'pullup');

PIN_TASTER         = 'D12';    % digitaler Eingang fuer Taster (Pull-Up aktiv)
PIN_SUMMER         = 'D11';    % PWM-faehiger Ausgang fuer Summer
PIN_LED            = 'D13';    % digitaler Ausgang fuer Status-LED
ENTPRELL_ZEIT_S    = 0.1;      % Entprellzeit in Sekunden
ABTAST_ZEIT_S      = 0.05;     % Abtastzeit pro Zyklus in Sekunden
FREQUENZ_SUMMER_HZ = 1200;     % Tonfrequenz des Summers in Hertz
DAUER_TON_S        = 1;        % Dauer eines aktiven Tonzyklus in Sekunden

nMesswerte = 100;

nLetzterRohzustand   = readDigitalPin(hArduino, PIN_TASTER);  % zuletzt gelesener Rohzustand (0|1)
nStabilerZustand     = nLetzterRohzustand;                    % entprellter Tasterzustand (0|1)
nZeitLetzteAenderung = tic;                                   % Zeitstempel der letzten Rohzustandsaenderung
nDruckZaehler        = 0;                                     % Zaehler erkannter entprellter Tasterdruecke

%% Messschleife
for i=1:nMesswerte
    writeDigitalPin(hArduino, 'D13', 1); % Achtung - System läuft
    speaker_status = readDigitalPin(hArduino, 'D12');

    if speaker_status ~= nLetzterRohzustand
        nLetzterRohzustand   = speaker_status;
        nZeitLetzteAenderung = tic;
    end

    if toc(nZeitLetzteAenderung) >= ENTPRELL_ZEIT_S
        if nStabilerZustand == 1 && speaker_status == 0
            nDruckZaehler = nDruckZaehler + 1;
        end
        nStabilerZustand = speaker_status;
    end

    if speaker_status == 0
        playTone(hArduino, 'D11', 1200, 1);
    else
        % Change duration to zero to mute the speaker
        playTone(hArduino, 'D11', 1200, 0);
    end

    pause(ABTAST_ZEIT_S);
end
writeDigitalPin(hArduino, 'D13', 0);
clear hArduino