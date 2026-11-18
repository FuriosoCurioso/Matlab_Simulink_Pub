clear all; close all; clc; % Initialisierung

if exist('arduinoObj') == 0
    arduinoObj = arduino('COM3', 'Uno', 'Libraries', 'Ultrasonic'); % Arduino Objekt erzeugen
    disp('Neues Arduino Objekt mit Ultrasonic-Bib erzeugt.')
end

hUltraschall = ultrasonic(arduinoObj, 'D12', 'D11', 'OutputFormat', 'double');
nMesswerte = 100;

% alpha klein => starke Glättung; alpha gross => wenig Glättung
alpha = 0.15;

% Ampel-Pins: D5=Rot, D6=Gelb, D7=Gruen
pinRot   = 'D5';
pinGelb  = 'D6';
pinGruen = 'D7';

% Vorabzuweisung der Messvektoren
Distanz           = zeros(1, nMesswerte);
Distanz_gefiltert = zeros(1, nMesswerte);
Zeit              = zeros(1, nMesswerte);


%% Messschleife
tic
writeDigitalPin(arduinoObj, 'D13', 1);  % Rote Status-LED ein

for i = 1:nMesswerte
    Distanz(i) = readDistance(hUltraschall);  % Messwert in Metern
    Zeit(i)    = toc;

    % IIR-Tiefpassfilter (Exponential Moving Average)
    if i == 1
        Distanz_gefiltert(i) = Distanz(i);
    else
        Distanz_gefiltert(i) = alpha * Distanz(i) + (1 - alpha) * Distanz_gefiltert(i-1);
    end

    % Ampelmodul: gefilterte Distanz in cm auswerten
    x = Distanz_gefiltert(i) * 100;  % Umrechnung m -> cm

    if x > 20
        writeDigitalPin(arduinoObj, pinGruen, 1);
        writeDigitalPin(arduinoObj, pinGelb,  0);
        writeDigitalPin(arduinoObj, pinRot,   0);
    elseif x >= 10
        writeDigitalPin(arduinoObj, pinGruen, 0);
        writeDigitalPin(arduinoObj, pinGelb,  1);
        writeDigitalPin(arduinoObj, pinRot,   0);
    else
        writeDigitalPin(arduinoObj, pinGruen, 0);
        writeDigitalPin(arduinoObj, pinGelb,  0);
        writeDigitalPin(arduinoObj, pinRot,   1);
    end
end

writeDigitalPin(arduinoObj, 'D13', 0);  % Rote Status-LED aus

% Ampel ausschalten
writeDigitalPin(arduinoObj, pinGruen, 0);
writeDigitalPin(arduinoObj, pinGelb,  0);
writeDigitalPin(arduinoObj, pinRot,   0);

%% Messwerte sichern
save('Ultraschall.mat', 'Distanz', 'Distanz_gefiltert', 'Zeit');
disp('Messwerte gespeichert in Ultraschall.mat')

%% Ergebnisdarstellung
figure;
plot(Zeit, Distanz * 100, 'r.-', 'DisplayName', 'Rohmesswerte');
hold on;
plot(Zeit, Distanz_gefiltert * 100, 'b-', 'LineWidth', 2, 'DisplayName', ...
     sprintf('Tiefpass (alpha=%.2f)', alpha));
hold off;
xlabel('Zeit in s')
ylabel('Distanz in cm')
title('Entfernungsmessung mit Ultraschall')
grid on


clear arduinoObj