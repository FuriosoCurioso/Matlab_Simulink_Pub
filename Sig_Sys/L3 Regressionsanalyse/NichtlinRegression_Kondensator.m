close all; clear all; clc;

% Eingangsgrößen:
t  = [0 0.199 1.01]*1e-6  % Zeit in s
uC = [9.93 8.2 3.5]       % Kondensatorspannung in Volt
R  = 1e3                  % Widerstand in Ohm
% Ergebnisgrößen: C

%% die Gleichung für u_C(t), wenn der Kondensator von U_C0 auf 0 entladen wird notieren
% uC =UC0 * e^(t/Tau)

%% u_C(t) in eine lineare Gleichung transformieren
% Tipp: ln(uC) = ln(UC0-t/Tau) y=b0 +b1*x

%% die Tabelle mit den Werten, mit denen die lineare Regression durchführen notieren
x = t           % Zeit in s
% y = ln(uC)  →  Logarithmierung linearisiert die Exponentialfunktion
y = log(uC)     % ln der Spannung in V

%% die drei Hilfsgrößen (Varianzen) berechnen
Kovarianzmatrix = cov(x, y)  % empirische 2x2-Kovarianzmatrix von x und y

sxx = Kovarianzmatrix(1,1)   % Varianz von x (Zeit)
syy = Kovarianzmatrix(2,2)   % Varianz von y (ln-Spannung)
sxy = Kovarianzmatrix(1,2)   % Kovarianz x,y

%% die Koeffizienten der Regressionsgerade berechnen
% b1 = sxy/sxx  →  Steigung der Regressionsgeraden (MKQ)
b1 = sxy / sxx
% b0 = ȳ - b1*x̄  →  Achsenabschnitt
b0 = mean(y) - b1 * mean(x)

%% Wie groß ist die Kapazität C?
% *Hinweis:* Tau hat dieselbe Einheit wie t.
% b1 = -1/Tau  →  Tau = -1/b1
Tau = -1 / b1   % in s
% C = Tau / R  →  RC-Glied: Tau = R*C
C = Tau / R     % Kapazität in F