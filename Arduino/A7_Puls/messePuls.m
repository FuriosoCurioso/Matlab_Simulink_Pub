close all; clear all; clc;

% messePuls.m
% Pulsmessung mit Herzfrequenzsensor KY-039 am Arduino Uno.
% Das Skript liest die Sensorspannung am Analogpin A0 ein, stellt sie über
% der Zeit dar, erkennt Pulsschläge über eine adaptive Schwellwertlogik und
% berechnet den Puls in Schlägen pro Minute.
%
% Anschluss Lautsprecher / Buzzer:
% Passiver Piezo-Lautsprecher:
% Plus / Signal -> Arduino D11, Minus -> GND. Optional 100 Ohm bis 220 Ohm
% in Reihe zum Signalpin verwenden. Das Skript nutzt dafür playTone().

F_DAUER_S = 30;                  % Messdauer [s]
F_ABTAST_S = 0.02;               % Zielabtastzeit [s]
F_MIN_BPM = 40;                  % kleinster plausibler Puls [1/min]
F_MAX_BPM = 180;                 % groesster plausibler Puls [1/min]
F_MIN_ABST_S = 60 / F_MAX_BPM;   % minimaler Abstand zweier Pulse [s]
F_MAX_ABST_S = 60 / F_MIN_BPM;   % maximaler Abstand zweier Pulse [s]
F_MIN_DELTA_V = 0.015;           % minimale Pulsauslenkung [V]
F_SIGMA_FAK = 0.75;              % Faktor fuer adaptive Schwelle [-]
F_TON_HZ = 1200;                 % Tonfrequenz bei erkanntem Puls [Hz]
F_TON_DAUER_S = 0.04;            % Tondauer je Puls [s]
F_ERG_PAUSE_S = 0.12;            % Pause zwischen Ergebnis-Toenen [s]

N_MAX_MESS = ceil(F_DAUER_S / F_ABTAST_S) + 1;    % maximale Messwerte [-]
N_FILT_ANZ = max(5, round(1.0 / F_ABTAST_S));     % Filterfenster [Samples]
N_PLOT_TEILER = 5;                                % Plot-Aktualisierung [-]

stPortName = 'COM7';              % COM-Port des Arduino, ggf. anpassen
stBoardTyp = 'Uno';               % Arduino-Boardtyp
stSensorPin = 'A0';               % Analogpin fuer KY-039-Ausgang
stLautPin = 'D11';                % Digitalpin fuer Lautsprecher/Buzzer
bAktivBuzzer = false;             % false: passiver Piezo, true: aktiver Buzzer

afZeit = zeros(1, N_MAX_MESS);    % Zeitwerte [s]
afU = zeros(1, N_MAX_MESS);       % gemessene Sensorspannung [V]
afPulsZeit = zeros(1, N_MAX_MESS);% erkannte Pulszeitpunkte [s]
afPulsBPM = NaN(1, N_MAX_MESS);   % laufender Pulswert [1/min]

nMesswerte = 0;                   % Anzahl gueltiger Messwerte [-]
nPulsZaehler = 0;                 % Anzahl erkannter Pulse [-]
fLetztePulszeit_s = -inf;         % letzter erkannter Pulszeitpunkt [s]
fPulsBPM = NaN;                   % aktueller Puls [1/min]
bSignalHoch = false;              % Status fuer Schwellwert-Flanke [-]

hArduino = arduino(stPortName, stBoardTyp);

hFigure = figure('Name', 'Pulsmessung KY-039');
hAchse = axes(hFigure);
hLine = animatedline(hAchse, 'LineWidth', 1.2);
grid(hAchse, 'on');
xlabel(hAchse, 'Zeit t in s');
ylabel(hAchse, 'Spannung U in V');
title(hAchse, 'Pulsmessung KY-039: Messung startet');

nStartZeit = tic;

while toc(nStartZeit) < F_DAUER_S && nMesswerte < N_MAX_MESS
    nLoopZeit = tic;

    nMesswerte = nMesswerte + 1;
    fZeit_s = toc(nStartZeit);
    fSpannung_V = readVoltage(hArduino, stSensorPin);

    afZeit(nMesswerte) = fZeit_s;
    afU(nMesswerte) = fSpannung_V;

    nWinStart = max(1, nMesswerte - N_FILT_ANZ + 1);
    afFenster = afU(nWinStart:nMesswerte);

    fBasisU_V = mean(afFenster);
    fSigmaU_V = std(afFenster, 1);
    fSignalU_V = fSpannung_V - fBasisU_V;
    fSchwelle_V = max(F_MIN_DELTA_V, F_SIGMA_FAK * fSigmaU_V);

    bGenugDaten = nMesswerte >= N_FILT_ANZ;
    bAktivSignal = abs(fSignalU_V) >= fSchwelle_V;

    if bGenugDaten && bAktivSignal && ~bSignalHoch && ...
            (fZeit_s - fLetztePulszeit_s) >= F_MIN_ABST_S

        nPulsZaehler = nPulsZaehler + 1;
        afPulsZeit(nPulsZaehler) = fZeit_s;
        fLetztePulszeit_s = fZeit_s;

        fPulsBPM = BerechnePulsBPM(afPulsZeit, nPulsZaehler, ...
            F_MIN_ABST_S, F_MAX_ABST_S);
        afPulsBPM(nMesswerte) = fPulsBPM;

        GibTonAus(hArduino, stLautPin, F_TON_HZ, ...
            F_TON_DAUER_S, bAktivBuzzer);
    elseif nMesswerte > 1
        afPulsBPM(nMesswerte) = afPulsBPM(nMesswerte - 1);
    end

    bSignalHoch = bAktivSignal;

    addpoints(hLine, fZeit_s, fSpannung_V);

    if mod(nMesswerte, N_PLOT_TEILER) == 0
        if isnan(fPulsBPM)
            title(hAchse, 'Pulsmessung KY-039: Puls wird bestimmt');
        else
            title(hAchse, sprintf('Pulsmessung KY-039: Puls %.0f 1/min', fPulsBPM));
        end
        drawnow limitrate;
    end

    fRestzeit_s = F_ABTAST_S - toc(nLoopZeit);
    if fRestzeit_s > 0
        pause(fRestzeit_s);
    end
end

afZeit = afZeit(1:nMesswerte);
afU = afU(1:nMesswerte);
afPulsBPM = afPulsBPM(1:nMesswerte);
afPulsZeit = afPulsZeit(1:nPulsZaehler);

fPulsBPM = BerechnePulsBPM(afPulsZeit, nPulsZaehler, ...
    F_MIN_ABST_S, F_MAX_ABST_S);

if ~isnan(fPulsBPM)
    title(hAchse, sprintf('Pulsmessung KY-039: Endwert %.0f 1/min', fPulsBPM));
    GibBpmAus(hArduino, stLautPin, fPulsBPM, bAktivBuzzer, F_ERG_PAUSE_S);
else
    title(hAchse, 'Pulsmessung KY-039: kein stabiler Puls erkannt');
end

save('PulsMessung.mat', 'afZeit', 'afU', 'afPulsZeit', ...
    'afPulsBPM', 'fPulsBPM', 'nPulsZaehler');

clear hArduino;

function fPulsBPM = BerechnePulsBPM(afPulsZeit, nPulsZaehler, ...
    fMinAbstand_s, fMaxAbstand_s)
% BERECHNEPULSBPM Berechnet den Puls aus erkannten Pulszeitpunkten.
%
% Syntax:
%     fPulsBPM = BerechnePulsBPM(afPulsZeit, nPulsZaehler, ...
%         fMinAbstand_s, fMaxAbstand_s)
%
% Beschreibung:
%     Die Funktion bildet die Zeitabstaende zwischen erkannten Pulsen,
%     verwirft unplausible Intervalle und berechnet den Puls ausden
%     letzten bis zu fuenf gueltigen Intervallen.
%
% Eingangswerte:
%     afPulsZeit: erkannte Pulszeitpunkte [s]
%     nPulsZaehler: Anzahl erkannter Pulse [-]
%     fMinAbstand_s: minimal plausibler Pulsabstand [s]
%     fMaxAbstand_s: maximal plausibler Pulsabstand [s]
%
% Rueckgabewerte:
%     fPulsBPM: Puls in Schlaegen pro Minute [1/min]
%
% Beispiel:
%     fPulsBPM = BerechnePulsBPM([1.0 1.8 2.6], 3, 0.33, 1.5)

if nPulsZaehler < 2
    fPulsBPM = NaN;
    return;
end

afIntervall_s = diff(afPulsZeit(1:nPulsZaehler));
bGueltig = afIntervall_s >= fMinAbstand_s & afIntervall_s <= fMaxAbstand_s;
afGueltig_s = afIntervall_s(bGueltig);

if isempty(afGueltig_s)
    fPulsBPM = NaN;
    return;
end

nAnzMittel = min(5, numel(afGueltig_s));
afMittel_s = afGueltig_s(end - nAnzMittel + 1:end);
fPulsBPM = 60 / mean(afMittel_s);

end

function GibTonAus(hArduino, stLautPin, fFrequenz_Hz, fDauer_s, bAktivBuzzer)
% GIBTONAUS Gibt einen kurzen Ton ueber Lautsprecher oder Buzzer aus.
%
% Syntax:
%     GibTonAus(hArduino, stLautPin, fFrequenz_Hz, fDauer_s, bAktivBuzzer)
%
% Beschreibung:
%     Bei passivem Piezo-Lautsprecher wird playTone() verwendet. Bei
%     aktivem Buzzer wird der digitale Pin fuer die Dauer fDauer_s auf
%     logisch 1 gesetzt und danach wieder ausgeschaltet.
%
% Eingangswerte:
%     hArduino: Arduino-Verbindungsobjekt
%     stLautPin: digitaler Ausgangspin, z.B. 'D11'
%     fFrequenz_Hz: Tonfrequenz [Hz]
%     fDauer_s: Tondauer [s]
%     bAktivBuzzer: true fuer aktiven Buzzer, false fuer passiven Piezo
%
% Rueckgabewerte:
%     keine
%
% Beispiel:
%     GibTonAus(hArduino, 'D11', 1200, 0.05, false)

if bAktivBuzzer
    writeDigitalPin(hArduino, stLautPin, 1);
    pause(fDauer_s);
    writeDigitalPin(hArduino, stLautPin, 0);
else
    playTone(hArduino, stLautPin, fFrequenz_Hz, fDauer_s);
end

end

function GibBpmAus(hArduino, stLautPin, fPulsBPM, bAktivBuzzer, fPause_s)
% GIBBPMAUS Gibt den berechneten Puls als Tonfolge aus.
%
% Syntax:
%     GibBpmAus(hArduino, stLautPin, fPulsBPM, bAktivBuzzer, fPause_s)
%
% Beschreibung:
%     Der Endwert wird gerundet und als Zehner-/Einerfolge ausgegeben.
%     Kurze tiefe Toene stehen fuer Zehnerstellen, kurze hohe Toene fuer
%     Einerstellen. Eine Null in der Einerstelle wird als langer hoher Ton
%     ausgegeben.
%
% Eingangswerte:
%     hArduino: Arduino-Verbindungsobjekt
%     stLautPin: digitaler Ausgangspin, z.B. 'D11'
%     fPulsBPM: Puls in Schlaegen pro Minute [1/min]
%     bAktivBuzzer: true fuer aktiven Buzzer, false fuer passiven Piezo
%     fPause_s: Pause zwischen Toenen [s]
%
% Rueckgabewerte:
%     keine
%
% Beispiel:
%     GibBpmAus(hArduino, 'D11', 72, false, 0.12)

nPulsBPM = round(fPulsBPM);
nZehner = floor(nPulsBPM / 10);
nEiner = mod(nPulsBPM, 10);

pause(0.5);

for i = 1:nZehner
    GibTonAus(hArduino, stLautPin, 600, 0.07, bAktivBuzzer);
    pause(fPause_s);
end

pause(0.4);

if nEiner == 0
    GibTonAus(hArduino, stLautPin, 1400, 0.35, bAktivBuzzer);
else
    for i = 1:nEiner
        GibTonAus(hArduino, stLautPin, 1400, 0.07, bAktivBuzzer);
        pause(fPause_s);
    end
end

end