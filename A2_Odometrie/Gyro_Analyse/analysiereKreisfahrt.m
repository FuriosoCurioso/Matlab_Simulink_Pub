close all; clear; clc;

LAEUFE = {'Kreisfahrt.mat','KreisfahrtRef.mat'};   % Messung, Referenz je Lauf ANPASSEN!
FARBEN = 'brgkmc';                    % Plotfarben [-]

sPar = struct();                      % Auswerteschwellen
sPar.Sync_m = 0.2;                    % Wegmarke Synchronisation Odometrie - Topcon [m]
sPar.BewegMin_m = 0.02;               % 2 Rasterschritte (Topcon Tracking 0,01 m) [m]
sPar.BasisKurs_m = 0.3;               % Wegbasis Kurswinkel Referenz [m]
sPar.Band = 0.1;                      % Einschwingen: |e| <= 10 % von omega_soll [-]
sPar.FensterV_s = 1;                  % Zeitfenster Geschwindigkeit Odometrie [s]

[asSignal,asAuswertung] = WerteLaufAus(LAEUFE{1,1},LAEUFE{1,2},sPar);   % Signale, Kennwerte je Lauf
for k = 2:size(LAEUFE,1)
    [asSignal(k),asAuswertung(k)] = WerteLaufAus(LAEUFE{k,1},LAEUFE{k,2},sPar);
end
sSignal = asSignal(1);                % Signale des Hauptlaufs
sAuswertung = asAuswertung(1);        % Kennwerte des Hauptlaufs

% "Einfluss der PI-Parameter auf Einschwingverhalten und Regelabweichung" -> Vergleich der Laeufe
tEinflussPI = table(LAEUFE(:,1),[asAuswertung.Kp].',[asAuswertung.Ki].',[asAuswertung.Einschwing_s].', ...
    [asAuswertung.Ueberschwing_Grads].',[asAuswertung.FehlerMittel_Grads].',[asAuswertung.FehlerRms_Grads].', ...
    'VariableNames',{'Messung','KP','KI','Einschwing_s','Ueberschwing_Grads','FehlerMittel_Grads','FehlerRms_Grads'})

% Ausgabe der Ergebnisse
fprintf('** Auswertung **\n');
fprintf('GyroZRef aus dem Kurs der Referenz [Wegbasis %.1f m, Zeitversatz %.3f s]: Mittel %.2f Grad/s, %d Werte\n', ...
    sPar.BasisKurs_m,sAuswertung.Zeitversatz_s,sAuswertung.OmegaRef_Grads,numel(sSignal.OmegaRef));
fprintf('Soll, GyroZ, GyroZRef ueber t [Mittel nach Einschwingen]: Soll %.2f, Ist %.2f, Referenz %.2f Grad/s\n', ...
    sAuswertung.OmegaSoll_Grads,sAuswertung.OmegaIst_Grads,sAuswertung.OmegaRef_Grads);
fprintf('Abweichung Soll - Ist [e = omega_soll - GyroZ]: Mittel %.3f Grad/s, RMS %.3f Grad/s, max %.2f Grad/s\n', ...
    sAuswertung.FehlerMittel_Grads,sAuswertung.FehlerRms_Grads,sAuswertung.FehlerMax_Grads);
fprintf('Kreisradius Referenz [Kreisanpassung, %d Punkte]: %.3f m (Mittelpunkt %.3f / %.3f m)\n', ...
    sAuswertung.NRef,sAuswertung.RadiusRef_m,sAuswertung.MitteRef_m(1),sAuswertung.MitteRef_m(2));
fprintf('x-y [Endpunkt gegen Referenz]: Modell %.3f m, Odometrie %.3f m Abstand\n', ...
    sAuswertung.AbstandModell_m,sAuswertung.AbstandOdo_m);
fprintf('Radius gegen Soll [r_soll = %.2f m]: Referenz %+.1f %%, Modell %.3f m, Odometrie %.3f m, v/omega %.3f m\n', ...
    sAuswertung.RadiusSoll_m,sAuswertung.RadiusAbw_Prozent,sAuswertung.RadiusModell_m,sAuswertung.RadiusOdo_m, ...
    sAuswertung.RadiusVOmega_m);
fprintf('PI-Parameter [KP %.2f, KI %.2f]: Einschwingen %.2f s, Ueberschwingen %.2f Grad/s, %d Lauf/Laeufe (siehe tEinflussPI)\n', ...
    sAuswertung.Kp,sAuswertung.Ki,sAuswertung.Einschwing_s,sAuswertung.Ueberschwing_Grads,size(LAEUFE,1));
fprintf('Ursachen [Kennwerte]: Restoffset %.3f Grad/s, GyroZ - Referenz %+.2f Grad/s, v %.3f m/s +- %.1f %%, Skala Odometrie %.3f\n', ...
    sAuswertung.Restoffset_Grads,sAuswertung.OmegaIst_Grads - sAuswertung.OmegaRef_Grads, ...
    sAuswertung.VMittel_ms,sAuswertung.VSchwank_Prozent,sAuswertung.RadiusOdo_m / sAuswertung.RadiusRef_m);
fprintf('\n');

% Literaturwerte
fprintf('** Literaturwerte **\n');
fprintf('Topcon Tracking <= 0.4 s je Messung, Raster 0.01 m; Kurs 10 mm / %.1f m = %.1f Grad\n', ...
    sPar.BasisKurs_m,atand(0.01 / sPar.BasisKurs_m));
fprintf('omega_soll = v / r = %.2f m/s / %.2f m = %.2f Grad/s (Leitfaden)\n', ...
    sAuswertung.VSoll_ms,sAuswertung.RadiusSoll_m,sAuswertung.OmegaSoll_Grads);
fprintf('Rauschen Gyroskop 0.1 Grad/s rms (Datenblatt)\n');
fprintf('Unsicherheit Topcon ca. 3 mm (Raster 10 mm / sqrt(12))\n');
fprintf('Umfang 2*pi*r = %.2f m, Umlaufzeit 2*pi*r / v = %.1f s\n', ...
    2 * pi * sAuswertung.RadiusSoll_m,2 * pi * sAuswertung.RadiusSoll_m / sAuswertung.VSoll_ms);
fprintf('Start KP = 0.2, KI = 2.0; Strecke ca. 3.6 Grad/s je u, Motor-Zeitkonstante ca. 0.1 s\n');
fprintf('Restoffset 0.1 Grad/s * 60 s = 6 Grad; r = v / omega (Lernzielkontrolle 7, 8)\n');

% Plots
fStopp = sSignal.t(sSignal.nStopp);   % Zeitpunkt des Stopps [s]

% "Soll-Gierrate, GyroZ, Referenzgierrate ueber t"; A3 Abweichung
figure;
subplot(2,1,1);
plot(sSignal.t,sSignal.OmegaSoll,'k--',sSignal.t,sSignal.GyroZ,'b',sSignal.tRefOmega,sSignal.OmegaRef,'r.-');
xline(fStopp,'k:');
BeschrifteAchse('Gierrate: Soll, Messung, Referenz','Zeit t [s]','Gierrate \omega [Grad/s]');
legend('Soll v/r','GyroZ (offsetkorrigiert)','GyroZRef (Topcon)','Stopp');
subplot(2,1,2);
plot(sSignal.t,sSignal.OmegaSoll - sSignal.GyroZ,'b');
yline(0,'k--');
xline(fStopp,'k:');
BeschrifteAchse('Abweichung Soll - Ist','Zeit t [s]','Regelabweichung e [Grad/s]');

% "Trajektorie, Messung und Referenz in x-y"
afWinkel = linspace(0,2 * pi,200);    % Winkel Sollkreis [rad]
fVorz = sign(sAuswertung.OmegaSoll_Grads);   % Linkskreis +1, Rechtskreis -1 [-]
figure;
plot(sSignal.X,sSignal.Y,'b',sSignal.XOdo,sSignal.YOdo,'g',sSignal.XRef,sSignal.YRef,'r', ...
    sAuswertung.RadiusSoll_m * sin(afWinkel),fVorz * sAuswertung.RadiusSoll_m * (1 - cos(afWinkel)),'k--');
axis equal;
BeschrifteAchse('Trajektorie: Modell, Odometrie, Referenz','Position x [m]','Position y [m]');
legend('berechnet (Modell)','Messung (Odometrie)','Referenz (Topcon)','Sollkreis');

% "Einfluss der PI-Parameter" -> Gierrate je Lauf
figure;
hold on;
for k = 1:numel(asSignal)
    plot(asSignal(k).t,asSignal(k).GyroZ,FARBEN(k),'DisplayName', ...
        sprintf('KP = %.2f, KI = %.2f',asAuswertung(k).Kp,asAuswertung(k).Ki));
end
hold off;
BeschrifteAchse('Einfluss der PI-Parameter auf die Gierrate','Zeit t [s]','Gierrate \omega [Grad/s]');
legend('show');

function [sSignal,sAuswertung] = WerteLaufAus(stMessung,stReferenz,sPar)
% WerteLaufAus: laedt einen Lauf, synchronisiert die Referenz und berechnet die Kennwerte
% Eingabe:  stMessung   [Text]: Messdatei aus SpeichereKreisfahrt.m
%           stReferenz  [Text]: Referenzdatei aus SpeichereTopconRef.m
%           sPar      [Struct]: Auswerteschwellen
% Ausgabe:  sSignal   [Struct]: Signale ab Beginn der Kreisfahrt (t = 0), Referenz im Startsystem
%           sAuswertung [Struct]: Kennwerte des Laufs
sMess = load(stMessung);
whos('-file',stMessung)
sRef = load(stReferenz);
whos('-file',stReferenz)

% Messung ab Beginn der Kreisfahrt (Zustand 2)
LeseWert = @(stName) double(reshape(sMess.data.getElement(stName).Values.Data,[],1));
afZeit = sMess.data.getElement('AktMot_Zustand_u8').Values.Time(:);   % Zeit des Modells [s]
anZustand = LeseWert('AktMot_Zustand_u8');   % 0 Kalibrierung, 1 Stillstand, 2 Kreisfahrt, 3 Stopp [-]
nBeginn = find(anZustand == 2,1);     % erster Schritt der Kreisfahrt [-]
if isempty(nBeginn)
    error('analysiereKreisfahrt:keineFahrt','%s: Zustand Kreisfahrt fehlt.',stMessung);
end
afGyroAlle = LeseWert('SenGyr_GyroZKorr_f32');   % korrigierte Gierrate, ganze Aufzeichnung [Grad/s]
Kuerze = @(afWert) afWert(nBeginn:end);
anZustand = Kuerze(anZustand);
abKreis = anZustand == 2;             % Schritte der Kreisfahrt [-]
afSL = Kuerze(LeseWert('SenOdo_SL_f32'));   % Radstrecke links [m]
afSR = Kuerze(LeseWert('SenOdo_SR_f32'));   % Radstrecke rechts [m]
fAbtast = median(diff(afZeit));       % Abtastzeit [s]

sSignal = struct();                   % Signale des Laufs
sAuswertung = struct();               % Kennwerte des Laufs
sSignal.t = Kuerze(afZeit) - afZeit(nBeginn);
sSignal.OmegaSoll = Kuerze(LeseWert('RegKrs_OmegaSoll_f32'));
sSignal.GyroZ = Kuerze(afGyroAlle);
sSignal.X = Kuerze(LeseWert('SenOdo_X_f32'));
sSignal.Y = Kuerze(LeseWert('SenOdo_Y_f32'));
sSignal.S = (afSL + afSR - afSL(1) - afSR(1)) / 2;
sSignal.nStopp = find(anZustand == 3,1);
if isempty(sSignal.nStopp)            % Fahrt abgebrochen (Speichern auch ohne Stopp)
    sSignal.nStopp = numel(anZustand);
    warning('analysiereKreisfahrt:keinStopp','%s: Zustand Stopp fehlt, Ende der Aufzeichnung als Stopp.',stMessung);
end
sAuswertung.Kp = double(sMess.sParameter.PAR_RegKrs_Kp_f32);
sAuswertung.Ki = double(sMess.sParameter.PAR_RegKrs_Ki_f32);
sAuswertung.VSoll_ms = double(sMess.sParameter.PAR_RegKrs_VSoll_f32);
sAuswertung.RadiusSoll_m = double(sMess.sParameter.PAR_RegKrs_RSoll_f32);
sAuswertung.OmegaSoll_Grads = median(sSignal.OmegaSoll(abKreis));

% "Abweichung Soll - Ist" -> Einschwingen bis |e| <= Band * omega_soll, danach Mittel, RMS
afFehler = sSignal.OmegaSoll - sSignal.GyroZ;   % Regelabweichung [Grad/s]
nEin = find(abKreis & abs(afFehler) <= sPar.Band * abs(sAuswertung.OmegaSoll_Grads),1);   % Ende Einschwingen [-]
if isempty(nEin)                      % Band nie erreicht: ganze Kreisfahrt auswerten
    nEin = 1;
    warning('analysiereKreisfahrt:keinEinschwingen','%s: |e| erreicht das Band nicht.',stMessung);
end
abStationaer = abKreis & (1:numel(abKreis)).' >= nEin;   % Kreisfahrt nach dem Einschwingen [-]
sAuswertung.Einschwing_s = sSignal.t(nEin);
sAuswertung.Ueberschwing_Grads = max(sign(sAuswertung.OmegaSoll_Grads) * (sSignal.GyroZ(abKreis) - sAuswertung.OmegaSoll_Grads));
sAuswertung.FehlerMittel_Grads = mean(afFehler(abStationaer));
sAuswertung.FehlerRms_Grads = sqrt(mean(afFehler(abStationaer) .^ 2));
sAuswertung.FehlerMax_Grads = max(abs(afFehler(abStationaer)));
sAuswertung.OmegaIst_Grads = mean(sSignal.GyroZ(abStationaer));

% A5 Messung: Trajektorie nur aus der Odometrie (Mittelpunktformel wie Differentialantrieb.m)
afKurs = (afSR - afSL - afSR(1) + afSL(1)) / double(sMess.sParameter.PAR_SenOdo_Spur_f32);   % Kurs [rad]
afMitte = (afKurs(1:end - 1) + afKurs(2:end)) / 2;   % Kurs in der Schrittmitte [rad]
sSignal.XOdo = [0; cumsum(diff(sSignal.S) .* cos(afMitte))];
sSignal.YOdo = [0; cumsum(diff(sSignal.S) .* sin(afMitte))];

% Referenz: Zeitversatz bei gleicher Wegmarke, Punkte der Fahrt
afZeitRef = sRef.Zeitstempel(:);      % Zeit der Referenz [s]
afPosX = sRef.Referenz(1,:).' - sRef.Referenz(1,1);   % x relativ zum Start [m]
afPosY = sRef.Referenz(2,:).' - sRef.Referenz(2,1);   % y relativ zum Start [m]
afAbStart = hypot(afPosX,afPosY);     % Abstand vom Start [m]
afAbEnde = hypot(afPosX - afPosX(end),afPosY - afPosY(end));   % Abstand vom Ende [m]
nSyncRef = find(afAbStart >= sPar.Sync_m,1);   % Referenzpunkt an der Wegmarke [-]
sAuswertung.Zeitversatz_s = sSignal.t(find(sSignal.S >= sPar.Sync_m,1)) - afZeitRef(nSyncRef);
anFahrt = (find(afAbStart > sPar.BewegMin_m,1) - 1):(find(afAbEnde > sPar.BewegMin_m,1,'last') + 1);   % Punkte der Fahrt [-]

% "Kreisradius aus der Referenz" -> Kreisanpassung; Startsystem: Tangente am Start = x-Achse
[afMitteRef,sAuswertung.RadiusRef_m] = PasseKreisAn(afPosX(anFahrt),afPosY(anFahrt));
afTangente = [afMitteRef(2), -afMitteRef(1)];   % Tangente am Start bei Linkskreis [m]
if afTangente * [afPosX(nSyncRef); afPosY(nSyncRef)] < 0
    afTangente = -afTangente;
end
fRichtung = atan2(afTangente(2),afTangente(1));   % Startrichtung [rad]
Drehe = @(afX,afY) [afX * cos(fRichtung) + afY * sin(fRichtung), -afX * sin(fRichtung) + afY * cos(fRichtung)];
afDreh = Drehe(afPosX(anFahrt),afPosY(anFahrt));   % Referenz im Startsystem [m]
sSignal.tRef = afZeitRef(anFahrt) + sAuswertung.Zeitversatz_s;
sSignal.XRef = afDreh(:,1);
sSignal.YRef = afDreh(:,2);
sAuswertung.MitteRef_m = Drehe(afMitteRef(1),afMitteRef(2));
sAuswertung.NRef = numel(anFahrt);
sAuswertung.RadiusAbw_Prozent = (sAuswertung.RadiusRef_m - sAuswertung.RadiusSoll_m) / sAuswertung.RadiusSoll_m * 100;

% "GyroZRef aus dem Kurswinkel der Referenz" -> Kurs als Sehne ueber die Wegbasis,
%    Gierrate = Kursaenderung zwischen aufeinanderfolgenden Sehnen / Zeit
nRef = numel(anFahrt);                % Anzahl Referenzpunkte [-]
anVor = nan(nRef,1);                  % Index am Ende der Wegbasis [-]
for k = 1:nRef
    nTreffer = find(hypot(sSignal.XRef(k:end) - sSignal.XRef(k),sSignal.YRef(k:end) - sSignal.YRef(k)) >= sPar.BasisKurs_m,1);
    if ~isempty(nTreffer)
        anVor(k) = k - 1 + nTreffer;
    end
end
anSehne = find(~isnan(anVor));        % Punkte mit vollstaendiger Wegbasis [-]
afKursRef = unwrap(atan2(sSignal.YRef(anVor(anSehne)) - sSignal.YRef(anSehne), ...
    sSignal.XRef(anVor(anSehne)) - sSignal.XRef(anSehne)));   % Kurs der Sehnen [rad]
afZeitSehne = (sSignal.tRef(anSehne) + sSignal.tRef(anVor(anSehne))) / 2;   % Zeit der Sehnen [s]
sSignal.OmegaRef = rad2deg(diff(afKursRef) ./ diff(afZeitSehne));
sSignal.tRefOmega = (afZeitSehne(1:end - 1) + afZeitSehne(2:end)) / 2;
abRefStat = sSignal.tRefOmega >= sAuswertung.Einschwing_s & sSignal.tRefOmega <= sSignal.t(sSignal.nStopp);
sAuswertung.OmegaRef_Grads = mean(sSignal.OmegaRef(abRefStat));

% "Radius gegen Sollradius" -> Kreisanpassung an Modell und Odometrie; r = v / omega
[~,sAuswertung.RadiusModell_m] = PasseKreisAn(sSignal.X(abKreis),sSignal.Y(abKreis));
[~,sAuswertung.RadiusOdo_m] = PasseKreisAn(sSignal.XOdo(abKreis),sSignal.YOdo(abKreis));
sAuswertung.AbstandModell_m = hypot(sSignal.X(end) - sSignal.XRef(end),sSignal.Y(end) - sSignal.YRef(end));
sAuswertung.AbstandOdo_m = hypot(sSignal.XOdo(end) - sSignal.XRef(end),sSignal.YOdo(end) - sSignal.YRef(end));

% "Ursachen" -> Restoffset im Stillstand, Schwankung der Geschwindigkeit
nFenster = round(sPar.FensterV_s / fAbtast);   % Schritte je Zeitfenster [-]
afV = (sSignal.S(1 + nFenster:end) - sSignal.S(1:end - nFenster)) / (nFenster * fAbtast);   % Geschwindigkeit [m/s]
afV = afV(abStationaer(1:end - nFenster) & abKreis(1 + nFenster:end));
sAuswertung.VMittel_ms = mean(afV);
sAuswertung.VSchwank_Prozent = std(afV) / mean(afV) * 100;
sAuswertung.RadiusVOmega_m = sAuswertung.VMittel_ms / deg2rad(sAuswertung.OmegaIst_Grads);
sAuswertung.Restoffset_Grads = mean(afGyroAlle(LeseWert('AktMot_Zustand_u8') == 1));
end

function [afMitte,fRadius] = PasseKreisAn(afX,afY)
% PasseKreisAn: Kreisanpassung (algebraisch, kleinste Quadrate): x^2 + y^2 + D*x + E*y + F = 0
% Eingabe:  afX, afY [Nx1]: Punkte [m]
% Ausgabe:  afMitte [1x2]: Mittelpunkt [m], fRadius [1x1]: Radius [m]
afLoesung = [afX, afY, ones(size(afX))] \ (-(afX .^ 2 + afY .^ 2));   % D, E, F [m, m, m^2]
afMitte = -afLoesung(1:2).' / 2;
fRadius = sqrt(sum(afMitte .^ 2) - afLoesung(3));
end

function BeschrifteAchse(stTitel,stAchseX,stAchseY)
% BeschrifteAchse: Titel, Achsenbeschriftung und Gitter der aktuellen Achse
% Eingabe:  stTitel [Text]: Titel, stAchseX, stAchseY [Text]: Achsen mit Groesse und Einheit
title(stTitel);
xlabel(stAchseX);
ylabel(stAchseY);
grid on;
end
