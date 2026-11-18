close all; clear all; clc;

load('Korrelation_a.mat')

%% Korrelationskoeffizient händisch berechnen
% Formel: r = sum((X-mean(X))*(Y-mean(Y))) / sqrt(sum((X-mean(X))^2) * sum((Y-mean(Y))^2))
r1 = sum((X - mean(X)) .* (Y - mean(Y))) / sqrt(sum((X - mean(X)).^2) * sum((Y - mean(Y)).^2));

%% Korrelationskoeffizient mit Kovarianzmatrix cov()
% Formel: r = cov(X,Y) / sqrt(var(X)*var(Y))
C = cov(X, Y);
r2 = C(1,2) / sqrt(C(1,1) * C(2,2));

%% Korrelationskoeffizient mit corrcoef()
R = corrcoef(X, Y);
r3 = R(1,2);

%% Regressionsgerade berechnen
% Da ein linearer Zusammenhang besteht (r < -0.8), wird die Gerade berechnet.
% Steigung b1 = Kovarianz(X,Y) / Varianz(X)
b1 = C(1,2) / C(1,1);
% Y-Achsenabschnitt b0 = Mittelwert(Y) - b1 * Mittelwert(X)
b0 = mean(Y) - b1 * mean(X);

% X-Werte für die Gerade generieren
X_reg = [min(X):0.1:max(X)];
% Y-Werte der Regressionsgerade berechnen
Y_reg = b1 * X_reg + b0;

%% Graph zeichnen
figure;
hold on;
% h1: Handle für die Messwerte (rote Punkte)
h1 = plot(X, Y, 'r.');
% h2: Handle für die Regressionsgerade (blaue Linie)
h2 = plot(X_reg, Y_reg, 'b-');

% Beschriftungen gemäß Referenzbild
title(['r = ', num2str(r1, '%.5f')]);
xlabel('X');
ylabel('Y');
legend([h1, h2], 'Messwerte', 'Regressionsgerade');