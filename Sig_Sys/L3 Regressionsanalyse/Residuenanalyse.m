load('Residuen.mat')
% x,y: Messwerte
% b0, b1 Koeffizienten der Regressionsgerade
whos

% x,y: Messwerte
% b0, b1 Koeffizienten der Regressionsgerade
Y = b1*x+b0  % Regressionsgerade

e = Y - y  % Residuen: Abweichungen der Messwerte zur Geraden

% n = Anzahl der Datenpunkte
n = length(x)  % Anzahl der Messwerte

%% Graphische Beurteilung der Residuen

% Histogramm der Residuen
figure
h = histogram(e,10);
title('1) Histogramm der Residuen')
xlabel('Residuen e')
ylabel('Häufigkeit')

% Graph berechnete vs. beobachtete Werte yi
figure;
plot(y,Y,'bo');
hold on;
% Ideallinie einzeichnen (y = x)
plot([min(Y) max(Y)], [min(Y) max(Y)], 'r-'); 
title('2) Berechnete vs. beobachtete Werte');
xlabel('Berechnete Werte Y');
ylabel('Beobachtete Werte y');

%% Graph Residuen vs. Werte der Einflussgröße xi
% Graph Residuen vs. Werte der Einflussgröße xi: nur zufällige Streuung der Residuen um Null, 
% andernfalls beschreibt die angenommene funktionale Form das Experiment nicht gut genug
figure;
plot(x, e, 'bo');
hold on;
% Nulllinie zur besseren Beurteilung der Streuung
plot([min(x) max(x)], [0 0], 'r--'); 
title('3) Residuen vs. Einflussgröße x');
xlabel('Einflussgröße x');
ylabel('Residuen e');

% Graph Residuen vs. Versuchsnummer
figure;
plot(1:n, e, 'bo');
hold on;
% Nulllinie zur Beurteilung von Trends
plot([1 n], [0 0], 'r--'); 
title('4) Residuen vs. Versuchsnummer');
xlabel('Versuchsnummer');
ylabel('Residuen e');

% Graph Residuen vs. berechnete Zielgröße
figure;
plot(Y, e, 'bo');
hold on;
% Nulllinie zur Beurteilung der Varianz (Trichterform)
plot([min(Y) max(Y)], [0 0], 'r--'); 
title('5) Residuen vs. berechnete Zielgröße Y');
xlabel('Berechnete Zielgröße Y');
ylabel('Residuen e');

% Fazit
disp('Fazit: Die graphische Beurteilung der Residuen dient der Überprüfung der Modellannahmen (Normalverteilung, Linearität, Homoskedastizität und Unabhängigkeit).');

