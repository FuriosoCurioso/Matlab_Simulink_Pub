clear all; close all; clc; % Initialisierung

if exist('hArduino','var')==0
    disp('Versuche Arduino Objekt zu erzeugen...')
    hArduino = arduino('COM7','Uno'); % Arduino Objekt erzeugen
    disp('Neues Arduino Objekt erzeugt...')
    hBMP180 = device(hArduino,"I2CAddress","0x77");
    disp('I2C-Objekt erzeugt...')
end
readRegister(hBMP180, 0xD0, 1) % Identifikation des Chips "85"

OSS = 0; % Oversampling für die Messung 1: Standard
disp(['OSS = ',num2str(OSS)])
disp('-----------------------------')

nMesswerte = 50;
%% Messschleife

AC = leseKalibrierwerte(hBMP180); % Kalibrierwerte des Sensors lesen

for i=1:nMesswerte
    %% Temperatur messen
    B5 = leseBMP180Temperatur(hBMP180,AC);
    B.B5 = B5; % Struktur erwartet

    %% Druck messen
    p(i) = leseBMP180Druck(hBMP180, AC, B, OSS);

end

clear hArduino

%---------------------------------------------------
% Hilfsfunktionen
%---------------------------------------------------
function p = leseBMP180Druck(bmp, AC, B, OSS)
if nargin == 3
    OSS = 0; % Funktioniert derzeit nur mit 0
    % 0	>> 8	~4.5 ms	niedrig
    % 1	>> 7	~7.5 ms	mittel
    % 2	>> 6	~13.5 ms	hoch
    % 3	>> 5	~25.5 ms	maximal
end

% =========================
% AC = Struktur mit:
% AC.AC1 ... AC.AC6
% AC.B1  ... AC.MD
%
% B = Struktur mit:
% B.B5 (wird intern aktualisiert, kann leer sein)
% =========================

%% -------------------------
% Druckmessung starten
%% -------------------------
switch OSS
    case 0
        cmd = hex2dec('34'); % OSS=0
        fPause = 0.005;
    case 1
        cmd = hex2dec('74');
        fPause = 0.008;
    case 2
        cmd = hex2dec('B4');
        fPause = 0.014;
    case 3
        cmd = hex2dec('F4');
        fPause = 0.026;
end

nBitshift = 8-OSS;
writeRegister(bmp, hex2dec('F4'), cmd); % cmd=OSS
pause(fPause); % Wartezeit anpassen

data = readRegister(bmp, hex2dec('F6'), 3);

msb  = double(data(1));
lsb  = double(data(2));
xlsb = double(data(3));

UP = uint32(msb)*65536 + uint32(lsb)*256 + uint32(xlsb);
UP = double(bitshift(UP, -nBitshift));


%% -------------------------
% Temperatur muss vorher existieren!
% (B.B5 kommt aus Temperaturfunktion)
%% -------------------------
if ~isfield(B,'B5')
    error('B.B5 fehlt! Temperatur muss zuerst gemessen werden.');
end

B5 = B.B5;

%% -------------------------
% Bosch Druckberechnung
%% -------------------------
B6 = B5 - 4000;

X1 = (double(AC.B2) * (B6^2 / 2^12)) / 2^11;
X2 = double(AC.AC2) * B6 / 2^11;
X3 = X1 + X2;

B3 = ((double(AC.AC1)*4 + X3) + 2) / 4;


X1 = double(AC.AC3) * B6 / 2^13;
X2 = (double(AC.B1) * (B6^2 / 2^12)) / 2^16;
X3 = ((X1 + X2) + 2) / 4;

B4 = double(AC.AC4) * (X3 + 32768) / 2^15;

B7 = (double(UP) - B3) * 50000;

if B7 < 2^31
    p = (B7 * 2) / B4;
else
    p = (B7 / B4) * 2;
end

X1 = (p / 2^8)^2;
X1 = (X1 * 3038) / 2^16;

X2 = (-7357 * p) / 2^16;

p = p + (X1 + X2 + 3791) / 16;

p=double(p);
end;

% Kalibrierwerte auslesen
function AC = leseKalibrierwerte(bmp)
AC.AC1 = readInt16(bmp,0xAA);
AC.AC2 = readInt16(bmp,0xAC);
AC.AC3 = readInt16(bmp,0xAE);
AC.AC4 = readUInt16(bmp,0xB0);
AC.AC5 = readUInt16(bmp,0xB2);
AC.AC6 = readUInt16(bmp,0xB4);
AC.B1  = readInt16(bmp,0xB6);
AC.B2  = readInt16(bmp,0xB8);
AC.MB  = readInt16(bmp,0xBA);
AC.MC  = readInt16(bmp,0xBC);
AC.MD  = readInt16(bmp,0xBE);
end;

% Temperatur auslesen
function B5 = leseBMP180Temperatur(bmp,AC)
writeRegister(bmp,0xF4,0x2E);
pause(0.005);

d = readRegister(bmp,0xF6,2);
UT = d(1)*256 + d(2);

X1 = (double(UT) - double(AC.AC6)) * double(AC.AC5) / 2^15;
X2 = double(AC.MC) * 2^11 / (X1 + double(AC.MD));

B5 = X1 + X2;
end

% Auslesen der Werte aus einem Register
% dev: I2C-Device
% reg: Register
function val = readInt16(dev, reg)
d = readRegister(dev, reg, 2);
val = double(typecast(uint8([d(2) d(1)]), 'int16'));
end

function val = readUInt16(dev, reg)
d = readRegister(dev, reg, 2);
val = double(typecast(uint8([d(2) d(1)]), 'uint16'));
end