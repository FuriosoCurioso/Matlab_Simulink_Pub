close all; clear; clc;

% Folgen aus Werteaufloesung: manuell bestimmt
BEWEG_MIN = 0.02;                     % 2 Rasterschritte (Datenblatt Topcon) [m]
ABSTAND_MIN = 0.001;                  % Entfernungsspruenge (Datenblatt Topcon) [m]

% Folgen aus Abtastzeit(Fenster) und Rauschen der Gesch.(FAHRT_MIN): manuell
FENSTER = 6;                          % Fenster Modus Tracking 6 * 0,16 s = 1 s [-]
FAHRT_MIN = 0.05;                     % Mindestgeschwindigkeit Fahrt im Fenster [m/s]

% "Referenz laden und analysieren"
% Datentypen: Messvektor Referenz mit Zeilen x,y,z z=-0.17 (konstant)
% Zeitstempel: Zeitpunkt je Spalte von Referenz
load('Referenz.mat');
whos

afZeit = Zeitstempel(:);              % Messzeitpunkte Referenz [s]
afPosX = Referenz(1,:).';             % x-Position Prisma [m] Zeilen zu Spaltenvektor
afPosY = Referenz(2,:).';             % y-Position Prisma [m] Zeilen zu Spaltenvektor

afAbStart = hypot(afPosX - afPosX(1),afPosY - afPosY(1));      % Strecke s(t) [m]
afAbEnde = hypot(afPosX - afPosX(end),afPosY - afPosY(end));   % Abstand Ende [m]

nStart = find(afAbStart > BEWEG_MIN,1) - 1;        % letzter Index vor Fahrt [-]
nEnde = find(afAbEnde > BEWEG_MIN,1,'last') + 1;   % erster Index nach Fahrt [-]

% Zusammenfassung Ergebnisse A1,A2
sAuswertung = struct();              
sAuswertung.AnzahlWerte = numel(afZeit);
sAuswertung.Zeitbereich_s = [afZeit(1) afZeit(end)];
sAuswertung.Fahrt_s = [afZeit(nStart) afZeit(nEnde)];

% "Zeitliche Aufloesung Referenz?" -> Abstand der Zeitstempel (diff)
% Modus TRACKING! -> ungleichmaessiger Takt
afAbtast = diff(afZeit);              % Abstand Messzeitpunkte [s]
sAuswertung.AbtastMedian_s = median(afAbtast);
sAuswertung.AbtastMinMax_s = [min(afAbtast) max(afAbtast)];

% "Werteaufloesung Referenz?" -> kleinster Sprung Entfernung d, Horizontalwinkel H
afAbstand = hypot(afPosX,afPosY);     % Entfernung Station - Prisma [m]
afSprung = abs(diff(afAbstand));      % Aenderung Entfernung je Messung [m]
sAuswertung.AufloesungEntfernung_m = min(afSprung(afSprung > ABSTAND_MIN));
afWinkelSprung = abs(diff(atan2d(afPosX,afPosY)));   % Aenderung H je Messung [Grad]
sAuswertung.AufloesungWinkel_Bogensek = min(afWinkelSprung(afWinkelSprung > 0)) * 3600;

% "Unsicherheit Referenz?" -> Typ A: Streuung im Stillstand vor der Fahrt (n Werte)
%    Typ B: Raster der Entfernung q/sqrt(12)
sAuswertung.StillstandN = nStart;
sAuswertung.StillstandStdXY_m = [std(afPosX(1:nStart)) std(afPosY(1:nStart))];
sAuswertung.RasterUnsicherheit_m = sAuswertung.AufloesungEntfernung_m / sqrt(12);

% "Referenzpositionen vx, vy und v = sqrt(vx^2 + vy^2)"
%    -> Differenzenquotient je Messintervall und ueber Fenster; 1-cm-Raster!
afGeschwX = diff(afPosX) ./ afAbtast; % Geschw. x [m/s]
afGeschwY = diff(afPosY) ./ afAbtast; % Geschw. y [m/s]
afGeschw = hypot(afGeschwX,afGeschwY);   % Bahngeschwindigkeit [m/s]
sAuswertung.vMax_mps = max(afGeschw);
sAuswertung.AnteilV0_Prozent = mean(afGeschw == 0) * 100;
afGeschwFenster = hypot(afPosX(1 + FENSTER:end) - afPosX(1:end - FENSTER), ...
    afPosY(1 + FENSTER:end) - afPosY(1:end - FENSTER)) ./ ...
    (afZeit(1 + FENSTER:end) - afZeit(1:end - FENSTER));   % Geschwindigkeit ueber 1 s [m/s]
sAuswertung.vFahrtMedian_mps = median(afGeschwFenster(afGeschwFenster > FAHRT_MIN));
sAuswertung.StreckeLuftlinie_m = hypot(mean(afPosX(nEnde:end)) - mean(afPosX(1:nStart)), ...
    mean(afPosY(nEnde:end)) - mean(afPosY(1:nStart)));   % Mittel der Stillstandspositionen [m]

% Ausgabe
fprintf('Zeitliche Aufloesung: Median %.4f s (%.4f ... %.4f s), ungleichmaessig (Tracking Modus)\n', ...
    sAuswertung.AbtastMedian_s,sAuswertung.AbtastMinMax_s);
fprintf(['A1.2: Werteaufloesung von Entfernung d [m] und Horizontalwinkel H: ' ...
    'Entfernung %.3f m, Winkel %.1f Bogensekunden (%.8f Grad)\n'], ...
    sAuswertung.AufloesungEntfernung_m, ...
    sAuswertung.AufloesungWinkel_Bogensek, ...
    sAuswertung.AufloesungWinkel_Bogensek / 3600);
fprintf('Unsicherheit: Streuung n = %d\n Typ A: Messrauschen im Stillstand: s_x %.4f m, s_y %.4f m;\n Typ B: Raster des Geraets im Intervall +-q/2: %.4f m\n', ...
    sAuswertung.StillstandN,sAuswertung.StillstandStdXY_m,sAuswertung.RasterUnsicherheit_m);
fprintf('Refernezpositionen: vx, vy, v: v max %.3f m/s, %.0f %% Intervalle v = 0; Fahrt (Fenster 1 s) %.3f m/s\n', ...
    sAuswertung.vMax_mps,sAuswertung.AnteilV0_Prozent,sAuswertung.vFahrtMedian_mps);
fprintf('\n')
% Literaturwerte Topcon PS-103A (Handbuch Kap. 26, S. 159-161)
fprintf('Literaturwerte (Topcon PS-103A Handbuch Kap. 26, S. 159-161):\n');
fprintf('Tracking: Messzeit < 1.3 s, danach alle <= 0.4 s je Messung\n');
fprintf('Entfernung Tracking 0.01 m (Fine 0.0001/0.001 m, Rapid 0.001 m); Winkel 1 oder 5 Bogensekunden (0.0002/0.0010 Grad)\n');
fprintf('Genauigkeit Winkel 3 Bogensekunden (ISO 17123-3); Entfernung Fine +-(1.5 + 2 ppm*D) mm, Rapid +-(5 + 2 ppm*D) mm, Tracking: keine Angabe\n');
fprintf('Auto Tracking bis 20 Grad/s (Prisma 5 m/s bei 20 m)\n');

sAuswertung;

% Plots
plot(afPosX,afPosY,'b.-');
title('X-Y-Darstellung der gefahrenen Strecke (Referenz)');
xlabel('Position x [m]');
ylabel('Position y [m]');
grid on;
figure;
stairs(afZeit,afAbStart,'b');
title('Strecke ueber der Zeit (Referenz, Abstand vom Start)');
xlabel('Zeit t [s]');
ylabel('Strecke s [m]');
grid on;
figure;
afZeitMitte = afZeit(1:end - 1) + afAbtast / 2;   % Intervallmitten [s]
plot(afZeitMitte,afGeschwX,'b',afZeitMitte,afGeschwY,'r',afZeitMitte,afGeschw,'k');
title('Geschwindigkeit aus den Referenzpositionen');
xlabel('Zeit t [s]');
ylabel('Geschwindigkeit v [m/s]');
legend('v_x','v_y','v');
grid on;
