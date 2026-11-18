% Charakterisierung des Ultraschall-Abstandssensors aus USMessung.mat: Messbereich, Zeitaufloesung a_t,
% Werteaufloesung a_s, Empfindlichkeit E und Messunsicherheit (1 sigma) je Sollabstand; Vergleich mit dem Datenblatt.
%{
close all; clear; clc;
load('USMessung.mat');
whos

nAnzahl = data.numElements;           % Anzahl Signale im Dataset [-]
afMesswerte = zeros(121,nAnzahl);     % je Spalte eine Messreihe [cm]

for k = 1:nAnzahl
    hLauf = data.getElement(k);               % Lauf k, selbst ein Dataset
    hSignal = hLauf.get('SenUs_DistCm_f32');  % Signal des Laufs k
    afMesswerte(:,k) = squeeze(hSignal.Values.Data);
  ergebnis = mean(afMesswerte)
end

afZeit = (0:120)' * 0.1; 

figure;
plot(afZeit,afMesswerte);
title('US-Messreihen');
xlabel('Zeit t [s]');
ylabel('Abstand d [cm]');
legend(compose('Messreihe %d',1:nAnzahl),'Location','best');
%}

close all; clear; clc;

% Analyse Messwerte USMessung.mat
load('USMessung.mat');
whos

afSollAbstand = [5, 10, 15, 20, 25];  % Referenzabstaende [cm]
nStufen = data.numElements;           % Anzahl Messreihen
hLauf = data.getElement(1);           % Lauf einer Stufe
hSignal = hLauf.get('SenUs_DistCm_f32');  % Abstandssignal eines Laufs
nWerte = hSignal.Values.Length;       % Anzahl Messwerte je Lauf

afMesswerte = zeros(nWerte,nStufen);  % Messwerte [cm]
afZeit = zeros(nWerte,nStufen);       % Zeitstempel [s]

% Messreihen auslesen: data Signal SenUs_DistCm_f32
for k = 1:nStufen
    hLauf = data.getElement(k);
    hSignal = hLauf.get('SenUs_DistCm_f32');
    afMesswerte(:,k) = squeeze(hSignal.Values.Data);
    afZeit(:,k) = hSignal.Values.Time;
end

% Messbereich MB
fMessMin = min(afMesswerte(:));       % kleinster Messwert [cm]
fMessMax = max(afMesswerte(:));       % groesster Messwert [cm]
fprintf('Messbereich MB: %.2f cm bis %.2f cm\n',fMessMin,fMessMax);

% Ergebnis Messbereich
% Gemessen 5 cm bis 25 cm. Das ist der untersuchte Bereich
% (Stufen 5 bis 25 cm). Den vollen Sensorbereich zeigen die Daten nicht; er wurde
% nicht ausgemessen.

% Zeitaufloesung a_t: Darstellung als MATLAB-Plot
afZeitDiff = diff(afZeit);            % Abstand aufeinanderfolgender Zeitstempel[s]
fZeitAufl = min(afZeitDiff(:));       % Zeitaufloesung a_t [s]
figure;
plot(afZeitDiff,'b.');
title('Zeitaufloesung a_t: Abstand aufeinanderfolgender Messwerte');
xlabel('Messwert Index. [-]'); 
ylabel('Zeitauflösung a_t [s]');

% Maximale Abtastrate
fAbtastMax = 1 / fZeitAufl;           % Abtastrate f = 1 / a_t [Hz]

% Ergebnis: a_t = 0,1 s in allen Stufen, also 10 Hz. Diese Rate ist durch die
% Sample time 0,1 s des Simulink-Modells vorgegeben, nicht durch den Sensor.
% Die maximale Abtastrate des Sensors ist aus diesen Daten nicht bestimmbar.

% Werteaufloesung a_s: Darstellung als MATLAB-Plot
afWerte = unique(afMesswerte(:));     % alle verschiedenen Messwerte, aufsteigend [cm]
afWertDiff = diff(afWerte);           % Schritt zwischen benachbarten Messwerten [cm]
fWertAufl = min(afWertDiff);          % Werteaufloesung a_s [cm]
figure;
semilogy(afWerte(2:end),afWertDiff,'b.');
title('Werteaufloesung a_s: Schritte zwischen benachbarten Messwerten');
xlabel('Messwert [cm]'); 
ylabel('Werteschritt a_s [cm]');

% Werteaufloesung
% Ergebnis: a_s = fWertAufl (Ausgabe in cm). Alle Werteschritte innerhalb einer Stufe sind
% ganzzahlige Vielfache davon. Der Wert entspricht 1 us Laufzeit bei 343 m/s
% (343 m/s * 1 us / 2); die Werte sind also zeitlich quantisiert.

% Empfindlichkeit E: Darstellung als MATLAB-Plot
afMittel = mean(afMesswerte);         % Mittelwert je Stufe [cm]
afEmpf = diff(afMittel) ./ diff(afSollAbstand);  % E zwischen benachbarten Stufen 
afIntervMitte = afSollAbstand(1:end - 1) + diff(afSollAbstand) / 2;  % Intervallmitten [cm]
figure;
plot(afIntervMitte,afEmpf,'b-o');
title('Empfindlichkeit E zwischen benachbarten Stufen');
xlabel('Abstandsintervall [cm]'); 
ylabel('Empfindlichkeit E [-]');

% Empfindlichster Bereich
% Ergebnis: Zwischen 12,5 cm und 17,5 cm (E = 0,98115). Ideal waere E = 1. Die Abweichungen
% liegen in der Groessenordnung der Positionierfehler des Reflektors.

% sigma: Darstellung als MATLAB-Plot
afSigma = std(afMesswerte);           % Standardabweichung (1 sigma) je Stufe [cm]
figure;
plot(afSollAbstand,afSigma,'b-o');
title('Unsicherheit sigma der Einzelmessung');
xlabel('Sollabstand [cm]'); 
ylabel('Standardabweichung sigma [cm]');

% Unsicherheit (1 sigma) bei glatter reflektierender Flaeche
% Ergebnis: 1 sigma je Stufe 1,35 mm zwischen 10 cm und 20 cm.
% Groesster Wert: 0,135 cm.

% Vergleich der Messwerte mit dem Datenblatt
% Grundlage: Technische Uebersicht (2 bis 450 cm, Messunsicherheit 3 mm, Messfrequenz 50 Hz)
% - Messbereich: gemessen 5 bis 25 cm, liegt innerhalb 2 bis 450 cm.
% - Zeitaufloesung a_t: 0,1s
% - Unsicherheit: gemessen hoechstens 1.35 mm (1 sigma), unter den 3 mm des Datenblatts.
% - Mittelwerte gegenueber Sollabstand: Abweichung afMittel - afSollAbstand [cm].
%   Die Abweichungen bei 10,15,20,25  cm uebersteigen 3 mm deutlich (~5,6 cm) und sind systematisch
% - Empfindlichkeit E: Zwischen 12,5cm und 17,5 cm (E = 0,98115). Ideal waere E = 1.
% - Abtastrate: gemessen 10 Hz (Modelleinstellung), Datenblatt 50 Hz.
% - Werteaufloesung: gemessen fWertAufl (Rechnung: 343 m/s * 1 us / 2 = 0,17149 mm); das Datenblatt nennt keine Aufloesung,
%   die 3 mm sind eine Unsicherheitsangabe laut Datenblatt

