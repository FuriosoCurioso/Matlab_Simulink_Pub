close all; clc; % Initialisierung

if exist('arduinoObj')==0
  arduinoObj = arduino('COM3','Uno'); % Arduino Objekt erzeugen
  disp('Neues Arduino Objekt erzeugt.')
end
nMesswerte = 100;
%% Messschleife
for i=1:nMesswerte
      writeDigitalPin(arduinoObj, 'D13', 0);
      pause(0.5);
      writeDigitalPin(arduinoObj, 'D13', 1);
      pause(0.5);
end
clear  arduinoObj;