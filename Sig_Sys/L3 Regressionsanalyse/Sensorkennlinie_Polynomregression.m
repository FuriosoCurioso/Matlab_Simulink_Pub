close all; clear all; clc;

%% Simulation der Messwerte
x = [0:0.1:10];
y = 2*x.^2-x+10;             % Messwert
y = y'+2*randn(length(x),1); % Messwert + Rauschen 

%% Polynomregression 2. Ordnung
% Designmatrix A für das überbestimmte Gleichungssystem aufstellen
% Spalten entsprechen den Termen x^2, x und 1. x wird transponiert (Spaltenvektor).
A = [(x').^2, x', ones(length(x), 1)];

% Methode der kleinsten Quadrate zur Bestimmung der Polynomkoeffizienten
% Formel: p = (A'*A)\(A'*y) bzw. in MATLAB effizient direkt über den Backslash-Operator
p = (A \ y)'  % kleinste Quadrate Lösung

Y = p(1)*x.^2+p(2)*x+p(3); % entspricht polyval

%% Ergebnisdarstellung
h = figure; % Handle für die Abbildung
h1 = plot(x,y,'r.'); % Handle für den Scatterplot der Messwerte
hold on
h2 = plot(x,Y,'b-'); % Handle für den Linienplot der Regression
xlabel('x'); % Achsenbeschriftung x-Achse gemäß Referenzbild
ylabel('y'); % Achsenbeschriftung y-Achse gemäß Referenzbild
legend([h1, h2], 'Messwerte','Regression');