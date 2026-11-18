close all; clear all; clc;

load('Kennlinie.mat');
% U = 0; % Messspannung in V (wird durch load('Kennlinie.mat') geladen)
% L = 0; % Distanz L zum reflektierenden Objekt in cm (wird durch load('Kennlinie.mat') geladen)

disp('----------------------')
disp('Ansatz 1')

%% Substitution
% Ansatz 1: L = p1 / (U + q1)  =>  1/L = (1/p1)*U + (q1/p1)
% Linearisierung: y_lin = b1 * x_lin + b0
x_lin1 = U;
y_lin1 = 1 ./ L;

%% Lineare Regression nach Gleichungen
n1 = length(x_lin1);
% Berechnung der empirischen Varianzen und Kovarianz (Bessel-Korrektur N-1)
sxx = sum((x_lin1 - mean(x_lin1)).^2) / (n1 - 1) % LÖSUNG erforderlich
syy = sum((y_lin1 - mean(y_lin1)).^2) / (n1 - 1) % LÖSUNG erforderlich
sxy = sum((x_lin1 - mean(x_lin1)) .* (y_lin1 - mean(y_lin1))) / (n1 - 1) % LÖSUNG erforderlich

% Steigung und Y-Achsenabschnitt
b1 = sxy / sxx % LÖSUNG erforderlich
b0 = mean(y_lin1) - b1 * mean(x_lin1) % LÖSUNG erforderlich

X = [0.2:0.1:4];

% Rücksubstitution der Parameter
p1 = 1 / b1 % LÖSUNG erforderlich
q1 = b0 / b1 % LÖSUNG erforderlich

Y1 = p1 ./ (X + q1);  % Gerade berechnen % LÖSUNG erforderlich

% Bestimmtheitsmaß der Linearisierung: R^2 = sxy^2 / (sxx * syy)
R2_Ansatz1 = sxy^2 / (sxx * syy) % Bestimmtheitsmaß % LÖSUNG erforderlich

%% Ergebnisplot vom Ansatz 1
figure('Name', 'Sensorkennlinie Regression', 'Position', [100, 100, 800, 800]);

% Subplot 1: Linearisierung Ansatz 1
subplot(2,2,1);
plot(x_lin1, y_lin1, 'b.'); hold on;
plot(X, b1 * X + b0, 'b-');
title('Ansatz 1');
xlabel('Messspannung U in V');
ylabel('1/L in 1/cm');
legend('Messwerte', 'Regression');

% Subplot 2: Original Ansatz 1
subplot(2,2,2);
plot(U, L, 'b.'); hold on;
plot(X, Y1, 'b-');
title(['R^2 = ', num2str(R2_Ansatz1, '%.5f')]);
xlabel('Messspannung U in V');
ylabel('Distanz L in cm');
legend('Messwerte', 'Regression');


disp('----------------------')
disp('Ansatz 2')
%% Substitution
% Ansatz 2: L = b1 * (1/U) + b0
% Linearisierung: y_lin = b1 * x_lin + b0
x_lin2 = 1 ./ U;
y_lin2 = L;

%% Lineare Regression nach Gleichungen
n2 = length(x_lin2);
sxx = sum((x_lin2 - mean(x_lin2)).^2) / (n2 - 1) % LÖSUNG erforderlich
syy = sum((y_lin2 - mean(y_lin2)).^2) / (n2 - 1) % LÖSUNG erforderlich
sxy = sum((x_lin2 - mean(x_lin2)) .* (y_lin2 - mean(y_lin2))) / (n2 - 1) % LÖSUNG erforderlich

b1 = sxy / sxx % LÖSUNG erforderlich
b0 = mean(y_lin2) - b1 * mean(x_lin2) % LÖSUNG erforderlich

X = [0.2:0.1:4];
Y2 = b1*1./X+b0;  % Gerade berechnen

R2_Ansatz2 = sxy^2 / (sxx * syy) % Bestimmtheitsmaß % LÖSUNG erforderlich

%% Ergebnisplot vom Ansatz 2
% Subplot 3: Linearisierung Ansatz 2
subplot(2,2,3);
plot(x_lin2, y_lin2, 'b.'); hold on;
X_lin_plot = linspace(min(x_lin2), max(x_lin2), 100);
plot(X_lin_plot, b1 * X_lin_plot + b0, 'b-');
title('Ansatz 2');
xlabel('1/U in 1/V');
ylabel('L in cm');
legend('Messwerte', 'Regression');

% Subplot 4: Original Ansatz 2
subplot(2,2,4);
plot(U, L, 'b.'); hold on;
plot(X, Y2, 'b-');
title(['R^2 = ', num2str(R2_Ansatz2, '%.5f')]);
xlabel('Messspannung U in V');
ylabel('Distanz L in cm');
legend('Messwerte', 'Regression');

%% Ergebnisinterpretation
disp('Fazit: Ansatz 2 liefert ein höheres Bestimmtheitsmaß R^2 und approximiert die Sensorkennlinie besser als Ansatz 1.');