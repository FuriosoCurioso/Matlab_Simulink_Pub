close all; clear; clc;

% Eingangsgrößen:
START_FAHRT = 110;                    % Beginn Ref. Fahrt [s]
R_RAD = 0.032;                        % Radius r (am Roboter messen?) [m]
INC_U = 40;                           % Flanken je Radumdrehung [-]

% Folgen aus Referenz.mat (analysiereReferenzDSP.m): manuell
PAUSE_MIN = 1;                        % kuerzeste Pause zwischen Fahrabschnitten; Referenz: 2 Pausen ca. 4.8 s [s]
FENSTER = 6;                          % Referenz: Fenster 6 * 0,16 s = 1 s (Abtast Median 0,160 s) [-]
FAHRT_MIN = 0.05;                     % Referenz: ueber Rauschmax. 0,0147 m/s im Stillstand [m/s]

% "Odometrie laden und analysieren" -> Logging-Takt, Luecken, Einheit TimeDiff, Resets
% Odometrie.mat: Logging ungleichmaessig (Soll 0,01 s), TimeDiff in us statt s
load('Odometrie.mat');
whos

sOdometrie = AlphaBotOdometrie;       % Struct Timeseries gegeben
afZeit = sOdometrie.SL.Time;          % Logging-Zeit (eigene Zeitbasis, nicht Referenz) [s]

anZaehlerL = double(squeeze(sOdometrie.CNTL.Data));   % CNTL Zaehler Flanken L [-]
anZaehlerR = double(squeeze(sOdometrie.CNTR.Data));   % CNTR Zaehler Flanken R [-]

afStreckeL = double(squeeze(sOdometrie.SL.Data));     % SL Strecke Rad L [m]
afStreckeR = double(squeeze(sOdometrie.SR.Data));     % SR Strecke Rad R [m]

afGeschwL = double(squeeze(sOdometrie.VL.Data));      % VL Geschw. Rad L [m/s]
afGeschwR = double(squeeze(sOdometrie.VR.Data));      % VR Geschw. Rad R [m/s]

afTimeDiffL = double(squeeze(sOdometrie.TimeDiffL.Data))/1000; % TimeDiffL [us! Tabelle 1: s]
afLogAbtast = diff(afZeit);           % Abstand Logging-Zeitpunkte [s]

afResetZeit = afZeit([false; diff(anZaehlerL) < 0]);   % Zaehler-Resets [s]

% Zusammenfassung Ergebnisse A3-A6
sAuswertung = struct();
sAuswertung.AnzahlWerte = numel(afZeit);
sAuswertung.LogAbtastMedianMittel_s = [median(afLogAbtast) mean(afLogAbtast)];   % ungleichmaessig
sAuswertung.LogLuecken = sum(afLogAbtast > 1.5 * median(afLogAbtast));

abFlanke = afTimeDiffL > 0 & afGeschwL > 0;   % gueltige Flanke [Wahrheitswert]

sAuswertung.VLmalTimeDiffL = median(afGeschwL(abFlanke) .* afTimeDiffL(abFlanke));   % konstant -> us
sAuswertung.ResetZeit_s = afResetZeit.';

% "Referenzierte Fahrt ab 110 s" -> letzter Zaehler-Reset vor START_FAHRT
%    gleiche Fahrt wie Referenz.mat (Topcon), aber getrennte Zeitbasen
fStartFahrt = max(afResetZeit(afResetZeit <= START_FAHRT));   % Fahrtbeginn [s]
abFahrt = afZeit >= fStartFahrt;      % Werte der Fahrt [Wahrheitswert]

sAuswertung.StartFahrt_s = fStartFahrt;

% "Gefahrene Strecke und Geschwindigkeit" -> s = (SL + SR)/2 am Ende;
%    v = Strecke / Dauer der Abschnitte ohne Pausen (> PAUSE_MIN ohne Flanke)
%    Referenz: 3 Etappen mit 2 Pausen, Fahrt 0,178 m/s -> hier 3 Abschnitte erwartet
afZeitF = afZeit(abFahrt) - fStartFahrt;   % Zeit seit Fahrtbeginn [s]

afSLF = afStreckeL(abFahrt);          % SL ab Fahrtbeginn [m]
afSRF = afStreckeR(abFahrt);          % SR ab Fahrtbeginn [m]

afStreckeF = (afSLF + afSRF) / 2;     % s(t) [m]

anBewegt = find(diff(afStreckeF) > 0);   % Schritte mit Streckenzuwachs [-]
anTrenn = find(diff(afZeitF(anBewegt)) > PAUSE_MIN);   % letzte Schritte vor Pause [-]

anAbStart = anBewegt([1; anTrenn + 1]);   % Index vor Abschnitt [-]
anAbEnde = anBewegt([anTrenn; end]) + 1;  % Index nach Abschnitt [-]

afAbDauer = afZeitF(anAbEnde) - afZeitF(anAbStart);   % Dauer je Abschnitt [s]
afAbStrecke = afStreckeF(anAbEnde) - afStreckeF(anAbStart);   % Strecke je Abschnitt [m]

sAuswertung.StreckeLRS_m = [afSLF(end) afSRF(end) afStreckeF(end)];
sAuswertung.Abschnitte = numel(anAbStart);
sAuswertung.GeschwAbschnitte_mps = (afAbStrecke ./ afAbDauer).';
sAuswertung.GeschwFahrt_mps = sum(afAbStrecke) / sum(afAbDauer);   % ohne Pausen

% "Qualitaet SL, SR, VL, VR" -> Konsistenz SL = CNTL * Weg je Flanke,
%    VL/VR-Median gegen Mittel aus s, Vergleich Referenz (unabhaengig)
fWegInkrement = 2 * pi * R_RAD / INC_U;   % Weg je Flanke [m]
afVLB = afGeschwL(abFahrt & afGeschwL > 0);  % VL in Bewegung [m/s]
afVRB = afGeschwR(abFahrt & afGeschwR > 0);  % VR in Bewegung [m/s]

sAuswertung.WegJeFlanke_m = fWegInkrement;

% Konsistenz der Ergebnisse Strecke/Rad
sAuswertung.KonsistenzLR_m = [max(abs(afStreckeL - anZaehlerL * fWegInkrement)) ...
    max(abs(afStreckeR - anZaehlerR * fWegInkrement))];

sAuswertung.DifferenzLR_m = afSLF(end) - afSRF(end);
sAuswertung.VLVRMedian_mps = [median(afVLB) median(afVRB)];
sAuswertung.VLVRStd_mps = [std(afVLB) std(afVRB)];
sAuswertung.FaktorVLVR = sAuswertung.VLVRMedian_mps / sAuswertung.GeschwFahrt_mps;

% Referenz.mat (gleiche Fahrt) -> Strecke Start-Ende, v als Median Fenster 1 s
% A2: Referenz-Unsicherheit ca. 2-3 mm (Stillstand, Raster)
sRef = load('Referenz.mat');          % Topcon-Referenz Vorbereitung
afRefX = sRef.Referenz(1,:);          % x [m]
afRefY = sRef.Referenz(2,:);          % y [m]
afRefT = sRef.Zeitstempel;            % Zeit [s]

afRefV = hypot(afRefX(1 + FENSTER:end) - afRefX(1:end - FENSTER), ...
    afRefY(1 + FENSTER:end) - afRefY(1:end - FENSTER)) ./ ...
    (afRefT(1 + FENSTER:end) - afRefT(1:end - FENSTER));   % Referenzgeschw. [m/s]

sAuswertung.RefStrecke_m = hypot(afRefX(end) - afRefX(1),afRefY(end) - afRefY(1));
sAuswertung.RefGeschw_mps = median(afRefV(afRefV > FAHRT_MIN));

sAuswertung.AbweichungStrecke_Prozent = (afStreckeF(end) / sAuswertung.RefStrecke_m - 1) * 100;
sAuswertung.AbweichungGeschw_Prozent = (sAuswertung.GeschwFahrt_mps / sAuswertung.RefGeschw_mps - 1) * 100;

% Ausgabe der Ergebnisse
fprintf('Odometrie laden: Anzahl Werte %d; Median Logging %.4f s / Mittel %.4f s (ungleichmaessig)\n Anzahl Luecken Messwerte %d \n', ...
    sAuswertung.AnzahlWerte,sAuswertung.LogAbtastMedianMittel_s,sAuswertung.LogLuecken);
fprintf('\n');

fprintf('Referenzierte Fahrt ab %d s: Beginn %.2f s (letzter Zaehler-Reset)\n', ...
    START_FAHRT,sAuswertung.StartFahrt_s);
fprintf('\n');

fprintf(['A5: Gefahrene Strecke und Geschwindigkeit [s = (SL + SR)/2, v ohne Pausen, Abschnitte:\n s = %.3f m (SL %.3f m, SR %.3f m);\n' ...
    ' Geschwindigkeit v = %.3f m/s ohne Pausen, %d Abschnitte (%s m/s)\n'], ...
    sAuswertung.StreckeLRS_m([3 1 2]),sAuswertung.GeschwFahrt_mps, ...
    sAuswertung.Abschnitte,num2str(sAuswertung.GeschwAbschnitte_mps,'%.3f '));
fprintf('\n');

fprintf(['A6: Qualitaet SL, SR, VL, VR:\n Strecke %+.2f %% (%.3f m gegen %.3f m), v %+.2f %% (%.3f m/s gegen %.3f m/s);\n' ...
    ' SL, SR gegen CNT * %.5f m: max. Abweichung %.4f m / %.4f m;\n VL, VR aus Einzelflanke %.1f bzw. %.1f mal zu hoch\n'], ...
    sAuswertung.AbweichungStrecke_Prozent,sAuswertung.StreckeLRS_m(3),sAuswertung.RefStrecke_m, ...
    sAuswertung.AbweichungGeschw_Prozent,sAuswertung.GeschwFahrt_mps,sAuswertung.RefGeschw_mps, ...
    sAuswertung.WegJeFlanke_m,sAuswertung.KonsistenzLR_m,sAuswertung.FaktorVLVR);
fprintf('\n');

% Literaturwerte (Leitfaden V3, Demo DemoAlphaBotOdometrie.slx; Datenblatt zur Odometrie liegt nicht vor)
fprintf('Literaturwerte (Leitfaden):\n');
fprintf('Fixed-step 0.01 s (Leitfaden); TimeDiff aus Tabelle 1 in s\n');
fprintf('Fahrt ab 110 s ist Messereignis\n');
fprintf('Weg je Flanke 2*pi*r/%d = %.3f mm (r = %.1f cm); PWM 80: 0.42 m/s (Demo: 10 Umdrehungen in 4.7 s)\n', ...
    INC_U,2*pi*R_RAD/INC_U*1000,R_RAD*100);
fprintf(['A6: Demo Radumfang 0.201 m (ca. 1.4 mm nach 2 m); Abweichung der Odometrie\n' ...
    'haengt von Radradius, Schlupf und Untergrund ab\n']);

sAuswertung

% Plots: Abb. 6 (Startpunkt) und Geschwindigkeit der referenzierten Fahrt
plot(afZeit,afStreckeL,'r',afZeit,afStreckeR,'b');
xline(fStartFahrt,'k--');
title('Abb. 6: Startpunkt der Referenzmessung');
xlabel('Zeit t [s]');
ylabel('Strecke s [m]');
legend('SL','SR','Start referenzierte Fahrt');
grid on;
figure;
plot(afZeitF,afGeschwL(abFahrt),'r',afZeitF,afGeschwR(abFahrt),'b');
yline(sAuswertung.GeschwFahrt_mps,'k--');
title('Geschwindigkeit der referenzierten Fahrt');
xlabel('Zeit seit Fahrtbeginn t [s]');
ylabel('Geschwindigkeit v [m/s]');
legend('VL','VR','mittlere Geschwindigkeit aus s');
grid on;
