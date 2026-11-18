close all; clear all; clc;

%% Eingangsgrößen:
p = [1:5]*0.1;        % Druck in bar
d = [1 1 2 2 4]*1e-2; % Dicke in m

%% Bestimmung der Parameter der Regressionsgerade

% Allgemeine Schreibweise
x=p; y=d;

% Kovarianzmatrix berechnen (2x2 Matrix)
Kovarianzmatrix = cov(x,y)

sxx = Kovarianzmatrix(1,1)
syy = Kovarianzmatrix(2,2)
sxy = Kovarianzmatrix(1,2)

% Steigung b1 und y-Achsenabschnitt b0 berechnen
b1 = sxy / sxx
b0 = mean(y) - b1 * mean(x)

%% Regressionsgerade berechnen
% Berechnung der y-Werte der Regressionsgeraden an den Messstellen x
Y = b0 + b1 * x

%% Vertrauensbereich für Regressionsgerade
n  = length(x) % Anzahl der Messwerte
s2 = sum((y - Y).^2) / (n - 2) % Restvarianz
s = sqrt(s2); % Standardabweichung

% p-Quantil der Student-t-Verteilung: $t_{n-2;1-\alpha/2}$

% p für zweiseitigen Vertrauensbereich für 95%
alpha = 0.05 % Prozent (5% Irrtumswahrscheinlichkeit)
p = 1 - alpha/2
t = tinv(p, n-2) %x = tinv(p,nu)
t95= t

% p für zweiseitigen Vertrauensbereich für 99%
alpha = 0.01 % Prozent (1% Irrtumswahrscheinlichkeit)
p = 1 - alpha/2
t = tinv(p, n-2) %x = tinv(p,nu)
t99= t

%% Messpunkte, Regressionsgerade und 95% Konfidenzintervall in einen Graph zeichnen

X = [0:0.01:0.6]; % beliebige X-Werte
Y = mean(y)+b1*(X-mean(x)); % Berechnung der Regressionsgeraden für beliebige X-Werte

%% Berechnung des Konfidenzbandes
% Hinweis: (n-1)*sxx entspricht der Summe der Fehlerquadrate sum((x-mean(x)).^2)
t = t95; % P=95%
y_min95 = Y - t * s * sqrt(1/n + (X - mean(x)).^2 / ((n-1)*sxx)) % untere Intervallgrenze
y_max95 = Y + t * s * sqrt(1/n + (X - mean(x)).^2 / ((n-1)*sxx)) % obere Intervallgrenze

t = t99; % P=99%
y_min99 = Y - t * s * sqrt(1/n + (X - mean(x)).^2 / ((n-1)*sxx)) % untere Intervallgrenze
y_max99 = Y + t * s * sqrt(1/n + (X - mean(x)).^2 / ((n-1)*sxx)) % obere Intervallgrenze

%% Ergebnisdarstellung
figure
hold on
h1=plot(x,y,'r*')
h2=plot(mean(x),mean(y),'ko')
h3=plot(X,Y,'b-')
h4=plot(X,y_min95,'k--')
plot(X,y_max95,'k--')
h5=plot(X,y_min99,'m--')
plot(X,y_max99,'m--')
legend([h1,h2,h3,h4,h5],'Messwerte','Schwerpunkt','Regressiongerade','P=95% Konfidenzinterval','P=99% Konfidenzinterval')
xlabel('Druck in bar')
ylabel('Dickenreduktion in m')