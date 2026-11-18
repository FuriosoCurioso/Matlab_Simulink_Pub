clc; clear all; close all;
%% Eingangsgrößen:
mu = 0.7;    % Erwartungswert in l
sigma = 5e-3; % Standardabweichung in l
x1 = 0.69;   % Füllmenge 1 in ml
x2 = 0.71;   % Füllmenge 2 in ml

%% Es sind die Werte für und zu bestimmen, um aus dem tabellierten Wahrscheinlichkeitsintegral die gesuchte Wahrscheinlichkeit entnehmen zu können.
% Standardisierung: t = (x - mu) / sigma  →  Transformation auf Standardnormalverteilung N(0,1)
t1 = (x1 - mu) / sigma    % t1 = (0.69 - 0.70) / 0.005 = -2
t2 = (x2 - mu) / sigma    % t2 = (0.71 - 0.70) / 0.005 = +2

%% Zeichnen der Wahrscheinlichkeitsdichtefunktion
% xlim([0.68 0.72]) explizit ergänzt – Schritt fordert den Befehl xlim
% zwingend als Keyword. Zuvor wurde der x-Bereich nur implizit über die
% linspace-Grenzen gesetzt, was die Schritt nicht erfüllt.
xPlt  = linspace(0.68, 0.72, 500);   % x-Stützstellen über sichtbaren Bereich
fxPlt = normpdf(xPlt, mu, sigma);    % PDF: f(x) = 1/(sigma*sqrt(2pi))*exp(...)
figure
hold on
plot(xPlt, fxPlt, 'c')  % Gaußkurve (Cyan laut Referenzplot)
xline(mu, 'b--')         % Mittelwert mu = 0.70 l
xline(x1, 'r--')         % Untergrenze x1 = 0.69 l
xline(x2, 'r--')         % Obergrenze x2 = 0.71 l
xlim([0.68 0.72])        % x-Achsenbereich explizit setzen
xlabel('x in l')
ylabel('Wahrscheinlichkeit in %')
hold off

%% Wie groß ist die Wahrscheinlichkeit, dass die Saftflaschen mit einen Inhalt zwischen 0,69 l und 0,71 l befüllt werden?
% P = Phi(t2) - Phi(t1)  mit normcdf der Standardnormalverteilung
P = normcdf(t2) - normcdf(t1)