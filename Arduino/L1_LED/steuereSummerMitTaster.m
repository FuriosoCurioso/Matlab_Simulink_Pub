close all; clc; % Initialisierung
if exist('arduinoObj')==0
    arduinoObj = arduino('COM3','Uno'); % Arduino Objekt erzeugen
    disp('Neues Arduino Objekt erzeugt.')
end

configurePin(arduinoObj, 'D12', 'pullup');
nMesswerte = 100;
%% Messschleife
for i=1:nMesswerte
    writeDigitalPin(arduinoObj, 'D13', 1); % Achtung - System läuft
    speaker_status = readDigitalPin(arduinoObj, 'D12');
    if speaker_status == 0
        playTone(arduinoObj, 'D11', 1200, 1);
    else
        % Change duration to zero to mute the speaker
        playTone(arduinoObj, 'D11', 1200, 0);
    end
end
writeDigitalPin(arduinoObj, 'D13', 0);
clear arduinoObj