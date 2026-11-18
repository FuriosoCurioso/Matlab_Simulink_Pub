close all; clear all; clc;

%% ========================================================================
%% Beispiel 6.5: Wahrscheinlichkeit bei Normalverteilung
%% ========================================================================
disp('--- Beispiel 6.5 ---');
mu    = 0.7;  % Erwartungswert in l
sigma = 5e-3; % Standardabweichung in l
x1    = 0.69; % Füllmenge 1 in l
x2    = 0.71; % Füllmenge 2 in l

t1 = (x1 - mu)/sigma;
t2 = (x2 - mu)/sigma;
P_Wahrscheinlichkeit = normcdf(x2,mu,sigma) - normcdf(x1,mu,sigma);

disp(['Wahrscheinlichkeit P = ', num2str(P_Wahrscheinlichkeit*100), ' %']);

% Plot
figure('Name', 'Beispiel 6.5: Dichtefunktion');
x_plot = 0.6:0.001:0.8;
pdfNorm = normpdf(x_plot, mu, sigma);
plot(x_plot, pdfNorm, 'k', 'LineWidth', 2); hold on;
xlim([0.68; 0.72]);
xlabel('x in l'); ylabel('Wahrscheinlichkeit in %');
line([x1 x1], [0 max(pdfNorm)], 'LineStyle', '--', 'Color', 'red');
line([x2 x2], [0 max(pdfNorm)], 'LineStyle', '--', 'Color', 'red');
line([mu mu], [0 max(pdfNorm)], 'LineStyle', '--', 'Color', 'blue');
title('Wahrscheinlichkeitsdichtefunktion');


%% ========================================================================
%% Beispiel 6.6: Auswertung von endlichen Messreihen
%% ========================================================================
disp(' '); disp('--- Beispiel 6.6 ---');
x = [1.018 1.032 0.981 0.994 0.966 0.993 0.986 1.005 1.003 0.982 0.995 1.011 0.991 0.998 1.012];
n = length(x);

xm = mean(x);
s = std(x);
u = s/sqrt(n);
u_rel = (u/abs(xm))*100;

disp(['Bester Schätzwert: ', num2str(xm), ' m']);
disp(['Empirische Standardabweichung: ', num2str(s), ' m']);
disp(['Standardunsicherheit: ', num2str(u), ' m']);
disp(['Rel. Standardunsicherheit: ', num2str(u_rel), ' %']);

% Vertrauensbereich (68,27%)
p_conf = 0.6827; 
nu = n - 1;
t_faktor = tinv((1+p_conf)/2, nu);
uA_66 = t_faktor * u;

disp(['Obere Grenze: ', num2str(xm + uA_66), ' m']);
disp(['Untere Grenze: ', num2str(xm - uA_66), ' m']);


%% ========================================================================
%% Beispiel 6.7: Unsicherheit indirekter Messungen (Leistung)
%% ========================================================================
disp(' '); disp('--- Beispiel 6.7 ---');
U = 230.1; uU = 0.1;  % Spannung und Unsicherheit
R = 301.4; uR = 0.4;  % Widerstand und Unsicherheit

P_leistung = (U)^2 / R;
uP = sqrt(((2*U/R)*uU)^2 + ((-U^2/R^2)*uR)^2);
uP_rel = (uP/abs(P_leistung)) * 100;

disp(['Leistung P = ', num2str(P_leistung), ' W']);
disp(['Unsicherheit u(P) = ', num2str(uP), ' W']);
disp(['Relative Unsicherheit = ', num2str(uP_rel), ' %']);


%% ========================================================================
%% Bestimmung der Messunsicherheit nach GUM (Widerstandsmessung)
%% ========================================================================
disp(' '); disp('--- GUM Auswertung ---');
Rm = [342.6 347.1 347.0 348.0 350.7 343.4 346.5 351.8];
n_GUM = length(Rm);

% & b) Schätzwert und Standardabweichung
R_mean = mean(Rm);
s_GUM = std(Rm);

% Unsicherheit Typ A (95% Vertrauensniveau)
alpha = 0.05; 
p_GUM = 1 - (alpha/2);
t_GUM = tinv(p_GUM, n_GUM-1);
uA = s_GUM * t_GUM / sqrt(n_GUM);

% Unsicherheit Typ B
uE = 1.2e-2 * R_mean / sqrt(3); % Empfindlichkeitsabweichung
nD = 2; LSB = 0.1; 
uN = nD * LSB / sqrt(3);        % Nullpunktabweichung
uB = sqrt(uE^2 + uN^2);

% Kombinierte Unsicherheit Typ C
uC = sqrt(uA^2 + uB^2);

% & g) Erweitertes Messergebnis (k=2)
k = 2;
U_erweitert = k * uC;
U_rel = (U_erweitert / R_mean) * 100;

disp(['Mittelwert R = ', num2str(R_mean), ' Ohm']);
disp(['Unsicherheit Typ A = ', num2str(uA), ' Ohm']);
disp(['Unsicherheit Typ B = ', num2str(uB), ' Ohm']);
disp(['Kombinierte Unsicherheit Typ C = ', num2str(uC), ' Ohm']);
disp(['Erweiterte Unsicherheit U (k=2) = ', num2str(U_erweitert), ' Ohm']);
disp(['Vollständiges Ergebnis: R = ', num2str(R_mean), ' Ohm +/- ', num2str(U_rel), ' %']);