clc; clear all; close all;
%{
% Eingangsgrößen:
R=[995 993 1006 994 1003 1001 1005 999]; % in Ohm
yR = zeros(1,length(R));
RE = mean(R);
sE = std(R);
x = 980:0.1:1020;
pE = normpdf(x,RE,sE );
fMaxpE=max(pE);


%% Ergebnisdarstellung
% für die Ergebnisdarstellung die vorgegebenen Handles für die automatische Auswertung verwenden
h = figure;
set(h,'Position',[681 407 772 692])

% Schritt: Gaußkurve und Messwerte zeichnen
p1 = plot(x,pE,'Color',[0.7 0.9 0.9]); % Handle zu plot(pE)
hold on
p2 = plot(R,yR,'o','Color',[0.85 0.6 0.6]); % Handle zum Plot der Messwerte

% Schritt: Mittelwert und Standardabweichungen markieren
p3 = xline(RE,'Color',[0.5 0.5 0.5],'LineWidth',2); % Handle zur Linie RE
p4 = xline(RE+sE,'Color',[0.7 0.7 0.7]); % Handle zur Linie RE+sE
p5 = xline(RE+2*sE); % Handle zur Linie RE+2*sE
p6 = xline(RE-2*sE); % Handle zur Linie RE-2*sE
set(p5,'LineStyle','--')
set(p6,'LineStyle','--')

% Schritt: Maximum markieren und beschriften
p7 = yline(fMaxpE,'Color','b'); % Handle zum Max.
hText = text(983,fMaxpE+0.002,['\downarrow p(R)_{max}= ' num2str(fMaxpE*100,'%.4f') ' %']); % Handle zum Beschriftung des Kurvenmaximums

% Schritt: Achsen beschriften und Grenzen setzen
xlabel('R in \Omega')
ylabel('p(R)')
xlim([980 1020])
ylim([0 0.1])

% Schritt: Legende ergänzen und nach Osten verschieben
hLegend = legend([p1 p2 p3 p4 p5 p7],{'Normalverteilung p_E(R)','Messwerte','Mittelwert R','Standardabweichung \sigma','Standardabweichung 2\sigma','Max. Wahrscheinlichkeit'}); % Handle zur Legende
set(hLegend,'Location','east')


%% Handles für die Automatische Auswertung
ax=gca; % Handle zu Ihrem aktuellen Grafikobjekt
aPos = h.Position;
aXLim =ax.XLim;
aYLim =ax.YLim;
stLegend = hLegend.Location;
aP1YData = p1.YData;
aP2XData = p2.XData;
nP3LW =p3.LineWidth;
aP4Color=p4.Color;
stP5LS =p5.LineStyle;
%}

% Eingangsgrößen:
R = [995 993 1006 994 1003 1001 1005 999]; % in Ohm – Messwertevektor (1x8)
yR = zeros(1,length(R));  % y=0 Positionen für Messwerte auf der x-Achse

% RE = (1/N) * sum(R_i)  →  Arithmetischer Mittelwert der Widerstandsmessung
RE = mean(R);

% sE = sqrt(1/(N-1) * sum((R_i - RE)^2))  →  Empirische Standardabweichung (Bessel-korrigiert)
sE = std(R);

x = 980:0.1:1020;  % Wertebereich für die Darstellung der Dichtefunktion in Ohm

% p(R) = 1/(sE*sqrt(2π)) * exp(-(R-RE)^2 / (2*sE^2))  →  Normalverteilung (Gaußsche Dichtefunktion)
pE = normpdf(x, RE, sE);

% fMaxpE = p(RE) = 1/(sE*sqrt(2π))  →  Maximum der Gaußkurve liegt beim Mittelwert RE
fMaxpE = max(pE);


%% Ergebnisdarstellung
% für die Ergebnisdarstellung die vorgegebenen Handles für die automatische Auswertung verwenden

% h: Handle auf das Figure-Objekt → wird für Position/Größe (aPos) benötigt
h = figure;

% Schritt: Figurgröße und -position setzen  [left bottom width height] in Pixeln
set(h, 'Position', [681 407 772 692]);

% Schritt: Gaußkurve zeichnen
% p1: Handle auf das Linienobjekt der Gaußkurve → enthält p1.YData (= pE-Vektor)
p1 = plot(x,pE,'c');
hold on
% p2: Handle auf Markierungsobjekte der Messwerte → enthält p2.XData
p2 = plot(R,yR,'or');

% Schritt: Mittelwert und Standardabweichungen markieren
% p3: Handle auf Mittelwertlinie → Soll: p3.LineWidth == 2
p3 = xline(RE,'k','LineWidth',2);
% p4: Handle auf RE+sE Linie → Soll: p4.Color
p4 = xline(RE+sE,'Color','k');
% p5/p6: Handles auf RE±2*sE Linien → Soll: p5.LineStyle == '--'
p5 = xline(RE+2*sE,'k');
p6 = xline(RE-2*sE,'k');
set(p5,'LineStyle','--')
set(p6,'LineStyle','--')

% Schritt: Maximum markieren und beschriften
% p7: Handle auf yline-Objekt des Maximums → fMaxpE = 1/(sE*sqrt(2π))
p7 = yline(fMaxpE,'b');
% hText: Handle auf Text-Objekt → num2str formatiert auf 4 Nachkommastellen
hText = text(983,fMaxpE+0.002,['\downarrow p(R)_{max}= ' num2str(fMaxpE*100,'%.4f') ' %']);

% Schritt: Achsen beschriften und Grenzen setzen
xlabel('R in \Omega')
ylabel('p(R)')
xlim([980 1020])
ylim([0 0.1])

% Schritt: Legende ergänzen und nach Osten verschieben
% hLegend: Handle auf Legend-Objekt → Soll: hLegend.Location == 'east'
hLegend = legend([p1 p2 p3 p4 p5 p7],{'Normalverteilung p_E(R)','Messwerte',...
    'Mittelwert R','Standardabweichung \sigma',...
    'Standardabweichung 2\sigma','Max. Wahrscheinlichkeit'});
set(hLegend,'Location','east')

%% Handles für die Automatische Auswertung
ax      = gca;                % Handle auf aktuelles Axes-Objekt → Zugriff auf XLim/YLim
aPos    = h.Position;         % Figurgröße und -position [left bottom width height]
aXLim   = ax.XLim;            % x-Achsengrenzen [980 1020]
aYLim   = ax.YLim;            % y-Achsengrenzen [0 0.1]
stLegend  = hLegend.Location; % Position der Legende (erwartet: 'east')
aP1YData  = p1.YData;         % y-Werte der Gaußkurve (= pE-Vektor, Länge 401)
aP2XData  = p2.XData;         % x-Werte der Messwerte (= R-Vektor, Länge 8)
nP3LW     = p3.LineWidth;     % Linienbreite Mittelwert (erwartet: 2)
aP4Color  = p4.Color;         % Farbe der einfachen Standardabweichungslinie
stP5LS    = p5.LineStyle;     % Linientyp der zweifachen Stdabw. (erwartet: '--')