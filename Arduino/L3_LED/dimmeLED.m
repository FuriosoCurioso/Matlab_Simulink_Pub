clear all; close all; clc; 

%if exist('hArduino') == 0 % US besser: exist('a','var') 
if ~exist('hArduino','var') % US Änderung
    hArduino = arduino('COM7','Uno'); % Arduino Objekt erzeugen
    disp('Neues Arduino Objekt erzeugt.')
end

% Linearpotentiometer
R_ges      = 10000;  % Gesamtwiderstand Poti % US: 11,1 kΩ
Verfahrweg = 6;      % weg in cm % | R
U_ref      = 5;      % ADC-Referenzspannung in V
D_max      = 1023;   % 10-Bit ADC-Maximalwert

nMesswerte = 50;    % US: nicht verwendete Variable

%% Messschleife
tic
for i=1:10 % US: Magic Number
    Spannung = readVoltage(hArduino, 'A0')      % Spannung messen % US Einheit?
    writePWMVoltage(hArduino, 'D11', Spannung); % LED via PWM dimmen
    Zeit(i) = toc;

    % Ergebnisgroessen aus der Spannung
    Spannung_vec(i) = Spannung;
    D(i)          = round(Spannung / U_ref * D_max);   % Digitalwort 0..1023
    R(i)          = Spannung / U_ref * R_ges;          % Teilwiderstand Poti
    Helligkeit(i) = Spannung / U_ref * 100;            % Helligkeit in %
    Strecke(i)    = Spannung / U_ref * Verfahrweg;     % position in cm

    pause(0.1);
end

%% Ergebnisdarstellung
figure;

subplot(4,1,1);
plot(Zeit, D, 'b.-');
ylabel('Digitalwort D');
title('LED-Dimmung mit Linearpotentiometer');
grid on;

subplot(4,1,2);
plot(Zeit, R, 'r.-');
ylabel('Widerstand in \Omega');
grid on;

subplot(4,1,3);
plot(Zeit, Helligkeit, 'g.-');
ylabel('Helligkeit in %');
grid on;

subplot(4,1,4);
plot(Zeit, Strecke, 'm.-');
xlabel('Zeit in s');
ylabel('Strecke in cm');
grid on;

clear hArduino % US: Wieso? Das Objekt könnte erhalten bleiben, um bei mehrfacher Ausführung Zeit zu sparen.