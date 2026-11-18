close all; clear; clc;

% Eingangsgrößen:
S_SOLL = 8;                           % Sollstrecke = Referenz der Fahrt (D4, A4) [m]
L_SPUR = 0.14;                        % Spurweite l (PAR_SenOdo_Spur_f32, nachmessen?) [m]
R_RAD = 0.032;                        % Radradius r (PAR_SenOdo_RadR_f32) [m]
INC_U = 40;                           % Flanken je Radumdrehung (PAR_SenOdo_IncU_f32) [-]

% D6 "Daten einer Fahrt aufzeichnen, s = (sL + sR)/2" -> Laden aus SpeichereOdometrieMessung.m
%    je Timeseries ein Spaltenvektor in sMessung
load('OdometrieMessung.mat');
whos
caFeld = fieldnames(AlphaBotOdometrie);   % gespeicherte Signale: SL, SR, S, VL, VR, Zustand
sMessung = struct();                  % Messdaten: t [s] und je Signal ein Spaltenvektor
sMessung.t = AlphaBotOdometrie.SL.Time(:);

for k = 1:numel(caFeld)
    sMessung.(caFeld{k}) = double(squeeze(AlphaBotOdometrie.(caFeld{k}).Data));
end

% D7 "Signalnamen, Einheiten, Abtastzeiten, Bedeutung dokumentieren" -> Tabelle tSignale
%    Abtastzeit als Median: Logging ungleichmaessig (Luecken im External Mode)
caEinheit = cell(numel(caFeld),1);    % Einheit je Signal
afAbtast = zeros(numel(caFeld),1);    % Abtastzeit je Signal [s]
caBedeutung = cell(numel(caFeld),1);  % Bedeutung je Signal
for k = 1:numel(caFeld)
    sZeitreihe = AlphaBotOdometrie.(caFeld{k});
    caEinheit{k} = sZeitreihe.DataInfo.Units;
    afAbtast(k) = median(diff(sZeitreihe.Time));
    caBedeutung{k} = sZeitreihe.UserData.Bedeutung;
end

% D5 "Zustaende Stillstand, Fahrt, Stopp (Stateflow)"
%    -> geloggter Zustand (0/1/2) begrenzt die Fahrt
nBeginn = find(sMessung.Zustand == 1,1);   % erster Schritt im Zustand Fahrt [-]
nEnde = find(sMessung.Zustand == 2,1);     % erster Schritt im Zustand Stopp [-]

sAuswertung = struct();               % Kennwerte der Messung
sAuswertung.FahrtBeginn_s = sMessung.t(nBeginn);
sAuswertung.FahrtEnde_s = sMessung.t(nEnde);
sAuswertung.Fahrzeit_s = sAuswertung.FahrtEnde_s - sAuswertung.FahrtBeginn_s;

% "Strecken links/rechts vergleichen, plausibel?" -> Differenz in m und %,
%    Kurswinkel am Ende psi = (SR - SL)/l; geradeaus -> psi = 0, psi > 0 Linkskurve
sAuswertung.StreckeL_m = sMessung.SL(end);
sAuswertung.StreckeR_m = sMessung.SR(end);
sAuswertung.DifferenzLR_m = sMessung.SL(end) - sMessung.SR(end);
sAuswertung.DifferenzLR_Prozent = sAuswertung.DifferenzLR_m / sMessung.S(end) * 100;
sAuswertung.KurswinkelEnde_Grad = (sMessung.SR(end) - sMessung.SL(end)) / L_SPUR * 180 / pi;

% "Mittlere zurueckgelegte Strecke" -> S = (SL + SR)/2 am Ende;
%    Startwert (Rad dreht vor Fahrt) und Nachlauf nach Stopp nur genannt
sAuswertung.StreckeMittel_m = sMessung.S(end);
sAuswertung.StreckeStart_m = sMessung.S(nBeginn);
sAuswertung.StreckeStopp_m = sMessung.S(nEnde);
sAuswertung.Nachlauf_m = sMessung.S(end) - sMessung.S(nEnde);

% "Tatsaechlich gefahrene Strecke, mit Sollstrecke vergleichen" (D4 "8 m geradeaus")
%    -> Odometrie S gegen S_SOLL; keine unabhaengige Messung (Topcon, Massband)
sAuswertung.AbweichungOdoSoll_m = sMessung.S(end) - S_SOLL;
sAuswertung.AbweichungOdoSoll_Prozent = sAuswertung.AbweichungOdoSoll_m / S_SOLL * 100;

% D8 "Odometriesignale plausibel auf Bewegung?" -> Kurswinkel (A2),
%    mittlere Geschwindigkeit aus Strecke / Fahrzeit; VL/VR Einzelflanke!
sAuswertung.GeschwL_mps = sMessung.SL(end) / sAuswertung.Fahrzeit_s;
sAuswertung.GeschwR_mps = sMessung.SR(end) / sAuswertung.Fahrzeit_s;

% Ausgabe der Ergebnisse
fprintf('** Auswertung **\n');
fprintf('Strecken SL, SR ueber t: Fahrt %.2f ... %.2f s, Fahrzeit %.2f s\n', ...
    sAuswertung.FahrtBeginn_s,sAuswertung.FahrtEnde_s,sAuswertung.Fahrzeit_s);
fprintf('Strecken Links/Rechts: [Differenz, Kurswinkel psi = (SR - SL)/l]: SL %.3f m, SR %.3f m, Differenz %.3f m (%.1f %%), Kurswinkel %.1f Grad\n', ...
    sAuswertung.StreckeL_m,sAuswertung.StreckeR_m,sAuswertung.DifferenzLR_m, ...
    sAuswertung.DifferenzLR_Prozent,sAuswertung.KurswinkelEnde_Grad);
fprintf('Mittlere Strecke [S = (SL + SR)/2]: %.3f m (Start %.3f m, bei Stopp %.3f m, Nachlauf %.3f m)\n', ...
    sAuswertung.StreckeMittel_m,sAuswertung.StreckeStart_m,sAuswertung.StreckeStopp_m,sAuswertung.Nachlauf_m);
fprintf('Strecke gegen Sollstrecke [Odometrie gegen %.0f m]: %.3f m, Abweichung %+.3f m (%+.2f %%)\n', ...
    S_SOLL,sAuswertung.StreckeMittel_m,sAuswertung.AbweichungOdoSoll_m,sAuswertung.AbweichungOdoSoll_Prozent);
fprintf('D8: Plausibilitaet [mittlere Geschw. = Strecke / Fahrzeit]: links %.3f m/s, rechts %.3f m/s\n', ...
    sAuswertung.GeschwL_mps,sAuswertung.GeschwR_mps);
fprintf('\n');

% Literaturwerte
fprintf('** Literaturwerte **\n');
fprintf('Fixed-step 0.01 s\n');
fprintf('Ideal: Geradeausfahrt: SL = SR, Kurswinkel 0 Grad\n');
fprintf('Weg je Flanke 2*pi*r/%d = %.3f mm (r = %.1f cm) = Aufloesung von SL, SR\n', ...
    INC_U,2*pi*R_RAD/INC_U*1000,R_RAD*100);
fprintf('Sollstrecke %.0f m (8 m geradeaus)\n',S_SOLL);
fprintf('D8: PWM 80: 0.42 m/s (Demo: 10 Umdrehungen in 4.7 s)\n');

afAchse = [sAuswertung.FahrtBeginn_s, sAuswertung.FahrtEnde_s];   % Zeitbereich der Plots [s]

sAuswertung;
% D3 "Messgroessen visualisieren, zeitlichen Verlauf pruefen" -> drei Teilbilder:
%    Strecke, Geschwindigkeit (auch D8), Zustand
figure;
% "Strecken SL und SR ueber der Zeit" -> Teilbild 1
subplot(3,1,1);
plot(sMessung.t,sMessung.SL,'r',sMessung.t,sMessung.SR,'b',sMessung.t,sMessung.S,'k--');
yline(S_SOLL,'g--');
title('Strecke der Raeder');
xlabel('Zeit t [s]');
ylabel('Strecke s [m]');
legend('SL','SR','S = (SL+SR)/2','Sollstrecke','Location','northwest');
xlim(afAchse);
grid on;
subplot(3,1,2);
plot(sMessung.t,sMessung.VL,'r',sMessung.t,sMessung.VR,'b');
yline(sAuswertung.GeschwL_mps,'r--');
yline(sAuswertung.GeschwR_mps,'b--');
title('Geschwindigkeit der Raeder (VL, VR aus Einzelflanken: nicht belastbar)');
xlabel('Zeit t [s]');
ylabel('Geschwindigkeit v [m/s]');
legend('VL','VR','Mittel links aus SL','Mittel rechts aus SR','Location','northwest');
xlim(afAchse);
grid on;
subplot(3,1,3);
stairs(sMessung.t,sMessung.Zustand,'k');
title('Zustand Fahrablauf (0 Stillstand, 1 Fahrt, 2 Stopp)');
xlabel('Zeit t [s]');
ylabel('Zustand [-]');
xlim(afAchse);
ylim([-0.5 2.5]);
grid on;
