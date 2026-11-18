close all; clear all; clc;

%% Schritt: Doppelklatschen erkennen und LED passend schalten

% Parameter
fSampleRate  = 20;      % ANPASSEN!? Abtastrate in Hz wg. fDt!?
fMessdauer   = 10;      % Messdauer ANPASSEN!
fMedian      = 10;      % Fenster Median
fSchwellOff  = 0.3;     % Schwellwert Offset -> Klatschen muss > sein!
fKlatschMin  = 0.5;     % min. Abstand zwischen zwei Klatschern s
fKlatschMax  = 1.5;     % max. Abstand "
stLedPin     = 'D13';   % DAusgang LED
stAnalogPin  = 'A0';    % AEingang Mikro

nMesswerte = fMessdauer * fSampleRate; % Gesamtanzahl Samples
fDt        = 1 / fSampleRate;          % Zeitschritt in s


% Initialisierung
afSpannung  = zeros(1, nMesswerte); % Rohmesswerte
afZeit      = zeros(1, nMesswerte); % Zeitstempel
afTiefpass  = zeros(1, nMesswerte); % Gleitender Median ueber afSpannung
afSchwOben  = zeros(1, nMesswerte); % afTiefpass + fSchwellOff -> ob. Grenze
afSchwUnten = zeros(1, nMesswerte); % afTiefpass - fSchwellOff -> unt. Grenze
anLampe     = zeros(1, nMesswerte); % Lampenstatus mit 0/1


hArduino = arduino('COM7', 'Uno'); % ANPASSEN!?

% writeDigitalPin(hArduino, stLedPin, 0); % LED ausschalten vor Messstart!?

% Zustandsvariablen Klatsch / Lampe 
bLampeAn           = false; 
fZeitErsterKlatsch = -999;  % -> nicht aktiV! -> erste Flanke erkannt
% Flanken-Flag-> true solange Signal ueber Schwelle
% verhindert mehrfachzaehlung Klatschpuls
bKlatschAktiv      = false; % Flanken-Flag-> true solange Signal ueber Schwelle

%% Messschleife
% Spannung einlesen->Offs. per Median schaetzen->Schwellwerte best.
% ->Flanke erk.==Klatscherk.->TimeOut Klatschen pruefen->Status LED ->naechstes Sample

for i = 1 : nMesswerte

    % Zeitstempel und Spannungsmessung
    afZeit(i)     = (i - 1) * fDt;                    
    afSpannung(i) = readVoltage(hArduino, stAnalogPin);

    % Medianfilter
    nStart        = max(1, i - fMedian + 1);     % verhindert negativen Index
    afTiefpass(i) = median(afSpannung(nStart:i));        % Offset

    % Schwellwerte-> verschieben mit Offset
    afSchwOben(i)  = afTiefpass(i) + fSchwellOff;
    afSchwUnten(i) = afTiefpass(i) - fSchwellOff;

    % Klatscherkennung = ->true mit Betrag offsetbereinigte Spannung
    bUeberSchwelle = abs(afSpannung(i) - afTiefpass(i)) > fSchwellOff; 

    if bUeberSchwelle && ~bKlatschAktiv
        % steigende Flanke->Puls
        bKlatschAktiv = true;

        % Kein erster Klatsch->merken->fZeitErsterKlatsch dann positiv
        if fZeitErsterKlatsch < 0
         
            fZeitErsterKlatsch = afZeit(i);

        else
            % erster Klatscherkannt->Abstand prüfen
            fAbstand = afZeit(i) - fZeitErsterKlatsch;
            % Gueltiges Doppelklatschen
            if fAbstand >= fKlatschMin && fAbstand <= fKlatschMax
               
                % ->bLampeAn togglen
                bLampeAn = ~bLampeAn;
                writeDigitalPin(hArduino, stLedPin, double(bLampeAn)); % PRUEFEN! double()/ logical 0/1
            end
            % Flags neu setzen für nächste Schleife egal ob D. Klatsch erkannt
            fZeitErsterKlatsch = -999;
            bKlatschAktiv      = false;
        end

    elseif ~bUeberSchwelle
        % Puls unter Schwelle->beendet->Flag neu setzen
        bKlatschAktiv = false;
    end

    % Timeout-Logik->erste Klatsch laenger als fKlatschMax->verworfen
    if fZeitErsterKlatsch > 0 && (afZeit(i) - fZeitErsterKlatsch) > fKlatschMax
        fZeitErsterKlatsch = -999; % ANPASSEN!? inf verwenden!?
    end

    % LED Status
    anLampe(i) = double(bLampeAn);

    
    % pause(fDt); % ANPASSEN!?
end

writeDigitalPin(hArduino, stLedPin, 0); % ANPASSEN!?
clear hArduino; %% ANPASSEN!?

%% Visualisierung entsprechend Vorgabe HSHL Wiki

figure;
hold on;

plot(afZeit, afSpannung,  'r', 'DisplayName', 'Spannung');
plot(afZeit, afTiefpass,  'y', 'DisplayName', 'Tiefpass');
plot(afZeit, anLampe * 5, 'k', 'DisplayName', 'Lampe an/aus');
plot(afZeit, afSchwOben,  'b', 'DisplayName', 'Schwellwert');
plot(afZeit, afSchwUnten, 'b', 'HandleVisibility', 'off'); % zweite Schwellwertkurve ohne eigenen Legendeneintrag

hold off;

xlabel('Zeit in s');
ylabel('Spannung in V');
ylim([0 5]);
xlim([0 fMessdauer]);
legend('Location', 'northeast');

% Diagramm speichern
saveas(gcf, 'Messdaten.jpg');

