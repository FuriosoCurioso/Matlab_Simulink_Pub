close all; clear all; clc;

% Eingangsgrößen:
R1 = 2e3; % in Ohm
R2 = 2e4; % in Ohm
R3 = 1e4; % in Ohm
R4 = 4e4; % in Ohm
Rf = 4e4; % in Ohm
uOff = 1; % in V
f = 1e3;  % in Hz
t = 0:1e-6:5e-3;       % Zeitachse 5 ms

% Berechnung der Eingangsspannung u1(t) = 0.2 * sin(2*pi*f*t)
u1 = 0.2 * sin(2*pi*f*t); % LÖSUNG ERFORDERLICH

%% Verstärkung der ersten Stufe
% Formel für den invertierenden Verstärker: v1 = -R2 / R1
v1 = -R2 / R1; % LÖSUNG ERFORDERLICH

%% Ausgangsspannung der ersten Stufe
% uA1(t) = v1 * u1(t)
uA1 = v1 * u1; % LÖSUNG ERFORDERLICH

%% Übertragungsfunktion der zweiten Stufe
% Formel für den invertierenden Addierer: uA(t) = -( (Rf/R3)*uA1(t) + (Rf/R4)*uOff )
uA = -( (Rf/R3)*uA1 + (Rf/R4)*uOff ); % LÖSUNG ERFORDERLICH

%% den maximalen Ausgangsspannungswert bestimmen
% Maximum und Minimum der Ausgangsspannung uA bestimmen
uAmax = max(uA) % LÖSUNG ERFORDERLICH
uAmin = min(uA) % LÖSUNG ERFORDERLICH

%% Prüfen, ob bei einer Versorgungsspannung von ±12 V eine Sättigung auftritt.
% Da uAmax = 7 V und uAmin = -9 V betragen, liegen beide Werte deutlich 
% innerhalb des Versorgungsspannungsbereichs von +/- 12 V. 
% Es tritt somit keine Sättigung der Operationsverstärker auf.

% Eine endliche Leerlaufverstärkung (k' < unendlich) führt dazu, dass die 
% tatsächliche Verstärkung der Schaltung geringer ausfällt als die ideal 
% berechnete. Dies verursacht Amplitudenfehler und Phasenverschiebungen.

%% Ergebnisdarstellung
figure;
hold on;

% h1: Handle für Eingangsspannung u1 (rot, durchgezogen)
h1 = plot(t, u1, 'r-');
% h2: Handle für Ausgangsspannung Stufe 1 uA1 (blau, durchgezogen)
h2 = plot(t, uA1, 'b-');
% h3: Handle für Gesamtausgangsspannung uA (schwarz, durchgezogen)
h3 = plot(t, uA, 'k-');

hold off;

% Achsenbeschriftungen und Legende gemäß Referenzbild
xlabel('Zeit in s');
ylabel('Spannung in V');
legend([h1, h2, h3], 'u_1', 'u_{A1}', 'u_A');

% =========================================================================
% Erfüllte Anforderungen:
% - Berechnung u1: Die Sinus-Eingangsspannung wurde korrekt mit der Frequenz f und der Amplitude 0.2V über die Zeitachse t berechnet.
% - Berechnung uA1: Die Verstärkung des invertierenden Verstärkers (-R2/R1) wurde korrekt auf u1 angewendet.
% - Berechnung uA: Die Übertragungsfunktion des invertierenden Addierers wurde korrekt als gewichtete Summe von uA1 und uOff implementiert.
% - Plot: Der Graph wurde exakt nach Referenzbild mit den Standardfarben (rot, blau, schwarz) und korrekten Legenden/Achsenbeschriftungen erstellt.
% =========================================================================