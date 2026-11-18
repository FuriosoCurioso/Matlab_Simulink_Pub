clc; clear all; close all;
%% TO DO ALLE WERTE ALS PLOT DARSTELLEN
%% Messdaten laden
load('UltraschallMessung.mat');
whos
%% Referenzwert
sRef = 30;   % feste Zielentfernung in cm

%% Test: Wurde der Plot korrekt gezeichnet?
figure;
plot(fZeit, fEntfernung, 'DisplayName', 'Messwerte');
xlabel('Zeit in s');
ylabel('Entfernung in cm');
legend('show');

%% Test: Wurde der Erwartungswert korrekt berechnet?
s = mean(fEntfernung)

%% Test: Wurde der absolute Fehler eAbs korrekt berechnet?
eAbs = abs(fEntfernung - sRef);

%% Test: Wurde der relative Fehler korrekt berechnet?
eRel = (eAbs / sRef) * 100;

%% Test: Wie gross schaetzen den systematischen Fehler eSys der Messung?
eSys = s - sRef;

%% Test: Wurde die zeitliche Aufloesung dt korrekt bestimmt?
dt = min(nonzeros(diff(fZeit)));

%% Test: Wurde die raeumliche Aufloesung korrekt bestimmt?
ds = min(nonzeros(abs(diff(fEntfernung))));

%% Test: Wurde die Messunsicherheit korrekt berechnet?
u = std(fEntfernung);

%% Test: Wurde die Genauigkeit g korrekt berechnet?
g = 100 - eRel;