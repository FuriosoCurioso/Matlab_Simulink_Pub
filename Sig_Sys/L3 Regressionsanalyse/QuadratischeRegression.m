close all; clear all; clc;

load('Daten_2_2.mat')
x = U_in_V;
y = Distanz_in_cm;
n = length(x);  % Anzahl der Messwerte

%% Quadratische (polynomische) Regression
% Hilfssummen für das Normalgleichungssystem (MKQ, polynomisch Grad 2)
xy  = sum(x .* y);    % Summe xi*yi
x2  = sum(x.^2);      % Summe xi²
x3  = sum(x.^3);      % Summe xi³
x4  = sum(x.^4);      % Summe xi⁴
yx2 = sum(y .* x.^2); % Summe yi*xi²

% Normalgleichungssystem: A*[a;b;c] = rhs  →  gelöst per \-Operator (math. Basisfunktion)
A   = [x4,    x3,   x2;   ...
    x3,    x2,   sum(x);  ...
    x2,    sum(x), n];
rhs = [yx2; xy; sum(y)];

% Koeffizienten aus dem LGS bestimmen
koeff = A \ rhs;  % [a; b; c] per Gauß-Elimination (mathematische Basisfunktion)
a = koeff(1)      % quadratischer Koeffizient
b = koeff(2)      % linearer Koeffizient
c = koeff(3)      % Achsenabschnitt

%% Polynom berechnen
X = [min(x):0.1:max(x)];
Y = a.*X.^2+b.*X+c;

%% Ergebnisgraph anzeigen
h=figure;  % h: Figure-Handle für den Ergebnisgraph
axis equal
plot(x, y, 'r.')
hold on
plot(X, Y, 'b-')
ylabel('Distanz in cm')
xlabel('U in V')
legend('Messwerte', 'Quadratische (polynomische) Regression', 'Location', 'SE');

