close all; clear all; clc;

load('Messdaten_px.mat');       % Messdaten laden
img = imread('Fahrspur.jpg');   % Kamerabild der Fahrspur

figure
imshow(img) % Kamerabild der Fahrspur
hold on;

%% die Messdaten und zeichnen diese in die Bilddatei einladen
% Messwerte in grün einzeichnen (Kreise mit durchgezogener Linie)
h1 = plot(x, y, 'go-', 'LineWidth', 2);

%% die Polynomkoeffizienten p mittels Polynomregression 2. Ordnung bestimmen
% hierzu die inline Funktion function p = PolynomRegression(x,y) schreiben
p1 = PolynomRegression(x, y);

%% das Ergebnis der Polynomregression 2. Ordnung in das Bild zeichnen
% y-Werte des Polynoms berechnen
Y1 = p1(1)*x.^2 + p1(2)*x + p1(3);
% Regressionspolynom in blau einzeichnen
h2 = plot(x, Y1, 'b-', 'LineWidth', 1.5);
legend([h1, h2], 'Messwerte', 'Polynomregression');

%% das Bestimmtheitsmaß Ihrer Polynomregression berechnen
% R^2 = 1 - (Summe der quadratischen Residuen / Totale Quadratsumme)
SSR1 = sum((y - Y1).^2);
SST1 = sum((y - mean(y)).^2);
R2_Ansatz1 = 1 - (SSR1 / SST1) % Bestimmtheitsmaß % LÖSUNG erforderlich

% Fazit Ansatz 1: 
% Das Polynom 2. Ordnung (Parabel) approximiert die gesamte Kurve der Fahrspur 
% relativ gut (hohes R^2). An den Rändern sind jedoch leichte Abweichungen zu 
% erkennen, da reale Fahrspuren im Straßenbau oft als Klothoiden und nicht als 
% reine Parabeln trassiert werden.

%% ---------------
%% die Aufgaben 1-5 für die ersten 10 Messwerte durch (x(1:10), y(1:10)) führen
x10 = x(1:10);
y10 = y(1:10);

figure
imshow(img)
hold on;

% Messwerte 1-10 zeichnen
h3 = plot(x10, y10, 'go-', 'LineWidth', 2);

% Polynomkoeffizienten für die ersten 10 Werte bestimmen
p2 = PolynomRegression(x10, y10);

% Ergebnis zeichnen
Y2 = p2(1)*x10.^2 + p2(2)*x10 + p2(3);
h4 = plot(x10, Y2, 'b-', 'LineWidth', 1.5);
legend([h3, h4], 'Messwerte', 'Polynomregression');

% Bestimmtheitsmaß berechnen
SSR2 = sum((y10 - Y2).^2);
SST2 = sum((y10 - mean(y10)).^2);
R2_Ansatz2 = 1 - (SSR2 / SST2) % Bestimmtheitsmaß % LÖSUNG erforderlich

% Fazit Ansatz 2: 
% Das Bestimmtheitsmaß für den verkürzten Bereich (die ersten 10 Messwerte) 
% ist noch näher an 1. Ein kürzeres Kurvenstück lässt sich durch eine Parabel 
% lokal besser annähern als ein langer Kurvenverlauf. Für eine Extrapolation 
% über den 10. Punkt hinaus wäre dieses Modell jedoch ungeeignet (Overfitting-Gefahr).


%% Lokale Funktion zur Polynomregression 2. Ordnung
function p = PolynomRegression(x, y)
% Vektoren als Spaltenvektoren sicherstellen
x = x(:);
y = y(:);

% Designmatrix A für das Polynom 2. Ordnung aufstellen: y = p(1)*x^2 + p(2)*x + p(3)
A = [x.^2, x, ones(length(x), 1)];

% Überbestimmtes Gleichungssystem mit der Methode der kleinsten Quadrate lösen
p = A \ y;
end