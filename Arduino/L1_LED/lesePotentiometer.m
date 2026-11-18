close all; clc; % Initialisierung

% Arduino-Verbindung: exist() verhindert Fehler bei leerem Workspace
if exist('arduinoObj') == 0
    arduinoObj = arduino('COM3', 'Uno');
end

% Pin A0 als analogen Eingang konfigurieren
configurePin(arduinoObj, 'A0', 'AnalogInput');

% Messung: 100 Spannungswerte mit Zeitstempel aufnehmen
tic % Timer starten
for i = 1:100
    Spannung(i) = readVoltage(arduinoObj, 'A0');
    Zeit(i)     = toc;
    pause(0.1) % in s
end

plot(Zeit, Spannung, 'r.-')
xlabel('Zeit in s')
ylabel('Spannung in V')