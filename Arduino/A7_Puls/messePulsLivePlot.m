close all; clear all; clc;

%% Konfigurationsparameter
const_LAUFZEIT_S       = 30;      % Messdauer in s
const_ABTASTZEIT_S     = 0.02;    % Abtastzeit in s (50 Hz -> ausreichend fuer Herzschlag ~1-3 Hz)
const_SCHWELLWERT      = 2.0;     % Spannungsschwelle Peak-Detektion in V (empirisch anpassen)
const_MIN_PEAK_ABST_S  = 0.3;     % Minimaler Abstand zwischen zwei Peaks in s (max. ~200 BPM)
const_BPM_FENSTER      = 5;       % Anzahl letzter Peak-Abstaende fuer gleitenden BPM-Mittelwert
const_BUZZER_FREQ_HZ   = 440;     % Tonfrequenz passiver Lautsprecher in Hz (A4)
const_BUZZER_DAUER_S   = 0.05;    % Tondauer je Herzschlag in s
stPinSensor            = 'A0';    % Analoger Eingangspin KY-039 Signal
stPinLautsprecher      = 'D11';    % PWM-Pin passiver Lautsprecher (PWM-Pins: D3,D5,D6,D9,D10,D11)

%% Arduino-Verbindung herstellen
if ~exist('hArduino', 'var')
    hArduino = arduino('COM7', 'Uno');
    disp('Neues Arduino-Objekt erzeugt.');
end

%% Vorab-Allokation
nMaxMesswerte  = ceil(const_LAUFZEIT_S / const_ABTASTZEIT_S) + 1;
afZeit         = zeros(1, nMaxMesswerte);   % Zeitstempel in s
afSpannung     = zeros(1, nMaxMesswerte);   % Sensorspannung in V
afBPM          = zeros(1, nMaxMesswerte);   % Berechnete BPM je Messzeitpunkt

%% Live-Plot initialisieren
hFig     = figure('Name', 'messePuls – KY-039 Herzfrequenzmessung');
hAx1     = subplot(2, 1, 1);
hLineSig = plot(hAx1, NaN, NaN, 'b-');
hold(hAx1, 'on');
hSchwelle = yline(hAx1, const_SCHWELLWERT, 'r--', 'LineWidth', 1.2);
hold(hAx1, 'off');
xlabel(hAx1, 'Zeit in s');
ylabel(hAx1, 'Spannung in V');
title(hAx1, 'KY-039 Rohsignal');
legend(hAx1, 'Messsignal', ['Schwellwert ' num2str(const_SCHWELLWERT) ' V'], ...
    'Location', 'best');
grid(hAx1, 'on');
ylim(hAx1, [0, 5]);
xlim(hAx1, [0, const_LAUFZEIT_S]);

hAx2    = subplot(2, 1, 2);
hLineBPM = plot(hAx2, NaN, NaN, 'r-', 'LineWidth', 1.5);
xlabel(hAx2, 'Zeit in s');
ylabel(hAx2, 'Herzfrequenz in BPM');
title(hAx2, 'Berechnete Herzfrequenz (BPM)');
grid(hAx2, 'on');
ylim(hAx2, [30, 200]);
xlim(hAx2, [0, const_LAUFZEIT_S]);

%% Peak-Detektions-Zustandsvariablen
bOberhalb         = false;   % Zustand: Signal aktuell ueber Schwellwert
fZeitLetzterPeak  = -Inf;    % Zeitstempel letzter detektierter Peak in s
afPeakAbstaende   = [];      % Vektor der letzten Peak-Abstaende in s
fAktuelleBPM      = 0;       % Zuletzt berechneter BPM-Wert

%% Messschleife
nMesswerte = 0;
tic;

while toc <= const_LAUFZEIT_S
    nMesswerte      = nMesswerte + 1;
    fAktZeit        = toc;
    fU              = readVoltage(hArduino, stPinSensor);  % Spannung in V

    afZeit(nMesswerte)     = fAktZeit;
    afSpannung(nMesswerte) = fU;

    %% Peak-Detektion: steigende Flanke ueber Schwellwert
    % Prinzip: Uebergang FALSE->TRUE am Schwellwert = neuer Herzschlag
    % Mindestabstand verhindert Doppelzaehlung durch Signalrauschen
    if fU >= const_SCHWELLWERT && ~bOberhalb
        bOberhalb = true;
        fAbstandZumLetzten = fAktZeit - fZeitLetzterPeak;

        if fAbstandZumLetzten >= const_MIN_PEAK_ABST_S
            % Gueltiger Peak: BPM berechnen
            fZeitLetzterPeak = fAktZeit;
            afPeakAbstaende  = [afPeakAbstaende, fAbstandZumLetzten]; %#ok<AGROW>

            % Gleitender Mittelwert der letzten const_BPM_FENSTER Abstaende
            nFenster     = min(const_BPM_FENSTER, length(afPeakAbstaende));
            fMittAbstand = mean(afPeakAbstaende(end-nFenster+1:end));
            fAktuelleBPM = 60 / fMittAbstand;  % 60 s / mittlerer Schlagabstand [s] = BPM

            %% Akustische Ausgabe: passiver Lautsprecher (Rechtecksignal ueber PWM)
            % Ein Herzschlag-Ton: PWM-Duty 50% fuer const_BUZZER_DAUER_S Sekunden,
            % dann wieder auf 0 setzen. Ton-Frequenz wird durch writePWMFrequency
            % und writePWMDutyCycle gesteuert (MATLAB Arduino Support Package).
            % Quelle: lbotics.at, MathWorks Arduino Support Package Dokumentation
          %  writePWMFrequency(hArduino, stPinLautsprecher, const_BUZZER_FREQ_HZ);
            writePWMDutyCycle(hArduino, stPinLautsprecher, 0.5);  % 50% Duty = Ton an
            pause(const_BUZZER_DAUER_S);
            writePWMDutyCycle(hArduino, stPinLautsprecher, 0);    % Duty 0 = Ton aus

            fprintf('Peak erkannt | Zeit: %.2f s | Abstand: %.3f s | BPM: %.1f\n', ...
                fAktZeit, fAbstandZumLetzten, fAktuelleBPM);
        end

    elseif fU < const_SCHWELLWERT
        bOberhalb = false;
    end

    afBPM(nMesswerte) = fAktuelleBPM;

    %% Live-Plot aktualisieren
    set(hLineSig, 'XData', afZeit(1:nMesswerte),     'YData', afSpannung(1:nMesswerte));
    set(hLineBPM, 'XData', afZeit(1:nMesswerte),     'YData', afBPM(1:nMesswerte));
    drawnow limitrate;

    pause(const_ABTASTZEIT_S);
end

%% Lautsprecher-Ausgang sicher ausschalten
writePWMDutyCycle(hArduino, stPinLautsprecher, 0);

%% Vektoren auf tatsaechliche Messanzahl kuerzen
afZeit     = afZeit(1:nMesswerte);
afSpannung = afSpannung(1:nMesswerte);
afBPM      = afBPM(1:nMesswerte);

%% Ergebnisausgabe
nAnzahlPeaks = length(afPeakAbstaende);
if nAnzahlPeaks >= 2
    fMittlBPM = 60 / mean(afPeakAbstaende);
    fprintf('\n--- Ergebnis Pulsmessung ---\n');
    fprintf('Erkannte Peaks:       %d\n',   nAnzahlPeaks);
    fprintf('Mittlere Herzfrequenz: %.1f BPM\n', fMittlBPM);
    fprintf('Min. Herzfrequenz:    %.1f BPM\n', 60 / max(afPeakAbstaende));
    fprintf('Max. Herzfrequenz:    %.1f BPM\n', 60 / min(afPeakAbstaende));
else
    disp('Zu wenige Peaks erkannt. Schwellwert const_SCHWELLWERT pruefen.');
end

% clear hArduino