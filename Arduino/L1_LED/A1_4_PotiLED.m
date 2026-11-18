close all; clc;clear all; % Initialisierung

if exist('arduinoObj')==0
  arduinoObj = arduino('COM3','Uno'); % Arduino Objekt erzeugen
  disp('Neues Arduino Objekt erzeugt.')
end
nMesswerte = 100;
for i=1:nMesswerte
    Spannung = readVoltage(arduinoObj, 'A0')       % Spannung messen
    writePWMVoltage(arduinoObj, 'D11', Spannung);   % LED via PWM dimmen
    pause(0.1);
end
clear arduinoObj