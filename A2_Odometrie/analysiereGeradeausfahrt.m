close all; clear; clc;

ZEIT_NACH = 2;                        % Plotbereich nach dem Stopp [s]
LAEUFE = {'Geradeausfahrt.mat'};      % Messdateien je Lauf (A5: weitere Zeilen) ANPASSEN!
FARBEN = 'brgkmc';                    % Plotfarben der Laeufe in A5, hoechstens 6 [-]
S_SOLL = 8;                           % Sollstrecke 8 m geradeaus [m]

[asSignal,asAuswertung] = WerteLaufAus(LAEUFE{1});   % Signale, Kennwerte je Lauf
for k = 2:numel(LAEUFE)
    [asSignal(k),asAuswertung(k)] = WerteLaufAus(LAEUFE{k});
end
sSignal = asSignal(1);                % Signale des Hauptlaufs (A1 bis A3)
sAuswertung = asAuswertung(1);        % Kennwerte des Hauptlaufs
sAuswertung.AbweichungSoll_Prozent = (sAuswertung.StreckeEnde_m - S_SOLL) / S_SOLL * 100;

% "Einfluss der Reglerverstaerkung KP auf das Regelverhalten" -> Vergleich der Laeufe
tEinflussKp = table(LAEUFE(:),[asAuswertung.Kp_1proRad].',[asAuswertung.FehlerMax_Grad].', ...
    [asAuswertung.StellgroesseMax].',[asAuswertung.Vorzeichenwechsel].', ...
    'VariableNames',{'Messung','KP_1proRad','FehlerMax_Grad','StellgroesseMax','Vorzeichenwechsel'})

% Ausgabe der Ergebnisse
fprintf('** Auswertung **\n');
fprintf('Kurswinkel ueber t [Odometrie, ohne Synchronisation]: Mittel %.2f Grad, max %.2f Grad, am Stopp %.2f Grad\n', ...
    sAuswertung.KursMittel_Grad,sAuswertung.KursMax_Grad,sAuswertung.KursStopp_Grad);
fprintf('Regelfehler, Stellgroesse [e = 0 - psi, u = KP * e]: Regelfehler max %.2f Grad, Stellgroesse max %.1f\n', ...
    sAuswertung.FehlerMax_Grad,sAuswertung.StellgroesseMax);
fprintf('Endstrecke gegen Soll [Odometrie]: bei Stopp %.3f m, Ende %.3f m (Nachlauf %.3f m), %+.2f %% gegen %.0f m\n', ...
    sAuswertung.StreckeStopp_m,sAuswertung.StreckeEnde_m,sAuswertung.Nachlauf_m, ...
    sAuswertung.AbweichungSoll_Prozent,S_SOLL);
fprintf('entfaellt [Kurswinkel anhand der Referenz: Topcon noetig]\n');
fprintf('Einfluss KP [KP = u / e, Vorzeichenwechsel von e]: %d Lauf/Laeufe, KP %.0f 1/rad, %d Vorzeichenwechsel (siehe tEinflussKp)\n', ...
    numel(LAEUFE),sAuswertung.Kp_1proRad,sAuswertung.Vorzeichenwechsel);
fprintf('entfaellt [Trajektorie gegen Topcon-Referenz]\n');
fprintf('\n');

% Literaturwerte
fprintf('** Literaturwerte **\n');
fprintf('Fixed-step 0.01 s (Leitfaden); Sollkurs 0 Grad; Aufloesung 1 Flanke = 5.027 mm / 0.14 m = 2.06 Grad\n');
fprintf('BSE_3: e = 0 - psi, u = KP * e, PWML = PWM0 - u, PWMR = PWM0 + u; Start KP = 100 1/rad, PWM0 = 80\n');
fprintf('Sollstrecke %.0f m; Weg je Flanke 2*pi*0.032/40 = 5.027 mm\n',S_SOLL);
fprintf('Zeitkonstante tau = l / (2 * g * KP) = 0.16 s bei KP = 100 [Schaetzwert, g = 0.0044 m/s je PWM]\n');

% Plots
fStopp = sSignal.t(sSignal.nStopp);   % Zeitpunkt des Stopps [s]
afAchse = [0, fStopp + ZEIT_NACH];    % Zeitbereich der Plots [s]

% "Kurswinkel ueber der Zeit"; A3 Strecke gegen Sollstrecke
figure;
subplot(2,1,1);
plot(sSignal.t,rad2deg(sSignal.Psi),'b');
yline(0,'k--');
xline(fStopp,'k:');
BeschrifteAchse('Kurswinkel aus der Odometrie','Zeit t [s]','Kurswinkel \psi [Grad]');
legend('Odometrie','Sollwert 0 Grad','Stopp');
xlim(afAchse);
subplot(2,1,2);
plot(sSignal.t,sSignal.S,'b');
yline(S_SOLL,'k--');
xline(fStopp,'k:');
BeschrifteAchse('Strecke aus der Odometrie','Zeit t [s]','Strecke s [m]');
legend('s = (SL+SR)/2','Sollstrecke','Stopp','Location','northwest');
xlim(afAchse);

% "Regelfehler und Stellgroesse ueber der Zeit"; PWM links/rechts
figure;
subplot(3,1,1);
plot(sSignal.t,rad2deg(sSignal.E),'b');
BeschrifteAchse('Regelfehler des P-Reglers','Zeit t [s]','Regelfehler e_\psi [Grad]');
xlim(afAchse);
subplot(3,1,2);
plot(sSignal.t,sSignal.U,'b');
BeschrifteAchse('Stellgroesse des P-Reglers','Zeit t [s]','Stellgroesse u [-]');
xlim(afAchse);
subplot(3,1,3);
plot(sSignal.t,sSignal.PWML,'r',sSignal.t,sSignal.PWMR,'b');
BeschrifteAchse('PWM links und rechts','Zeit t [s]','PWM [-]');
legend('PWML','PWMR');
xlim(afAchse);

% "Einfluss KP" -> Kurswinkel der Odometrie je Lauf
figure;
hold on;
for k = 1:numel(asSignal)
    plot(asSignal(k).t,rad2deg(asSignal(k).Psi),FARBEN(k), ...
        'DisplayName',sprintf('KP = %.0f 1/rad',asAuswertung(k).Kp_1proRad));
end
hold off;
BeschrifteAchse('Einfluss von KP auf den Kurswinkel (Odometrie)','Zeit t [s]','Kurswinkel \psi [Grad]');
legend('show');

function [sSignal,sAuswertung] = WerteLaufAus(stMessung)
% WerteLaufAus: laedt einen Lauf und berechnet die Kennwerte aus der Odometrie
% Eingabe:  stMessung   [Text]: Messdatei aus SpeichereGeradeausfahrt.m
% Ausgabe:  sSignal   [Struct]: Signale ab Fahrtbeginn (t = 0)
%           sAuswertung [Struct]: Kennwerte des Laufs
sMess = load(stMessung);
whos('-file',stMessung)

% Messung ab Fahrtbeginn (Zustand Fahrt); Zaehler laufen seit Programmstart!
LeseWert = @(stName) double(reshape(sMess.data.getElement(stName).Values.Data,[],1));
afZeit = sMess.data.getElement('AktMot_Zustand_u8').Values.Time(:);   % Zeit des Modells [s]
anZustand = LeseWert('AktMot_Zustand_u8');   % 0 Stillstand, 1 Fahrt, 2 Stopp [-]
nBeginn = find(anZustand == 1,1);     % erster Schritt im Zustand Fahrt [-]
Kuerze = @(afWert) afWert(nBeginn:end);
anZustand = Kuerze(anZustand);
abFahrt = anZustand == 1;             % Schritte im Zustand Fahrt [-]
afSL = Kuerze(LeseWert('SenOdo_SL_f32'));   % Radstrecke links [m]
afSR = Kuerze(LeseWert('SenOdo_SR_f32'));   % Radstrecke rechts [m]

sSignal = struct();                   % Signale des Laufs
sAuswertung = struct();               % Kennwerte des Laufs
sSignal.t = Kuerze(afZeit) - afZeit(nBeginn);
sSignal.S = (afSL + afSR - afSL(1) - afSR(1)) / 2;
sSignal.Psi = Kuerze(LeseWert('SenOdo_Psi_f32'));
sSignal.U = Kuerze(LeseWert('RegGer_U_f32'));
sSignal.PWML = Kuerze(LeseWert('AktMot_PWML_u8'));
sSignal.PWMR = Kuerze(LeseWert('AktMot_PWMR_u8'));
sSignal.nStopp = find(anZustand == 2,1);
if isempty(sSignal.nStopp)            % Fahrt abgebrochen (Speichern auch ohne Stopp)
    sSignal.nStopp = numel(anZustand);
    warning('analysiereGeradeausfahrt2:keinStopp','%s: Zustand Stopp fehlt, Ende der Aufzeichnung als Stopp.',stMessung);
end

% "Kurswinkel ueber der Zeit" -> psi_k = psi_k-1 + (dsR - dsL)/l aus dem Modell
sAuswertung.KursMittel_Grad = rad2deg(mean(sSignal.Psi(abFahrt)));
sAuswertung.KursMax_Grad = rad2deg(max(abs(sSignal.Psi(abFahrt))));
sAuswertung.KursStopp_Grad = rad2deg(sSignal.Psi(sSignal.nStopp));

% "Regelfehler und Stellgroesse des P-Reglers ueber der Zeit" -> e = 0 - psi, u geloggt
sSignal.E = 0 - sSignal.Psi;
afFehler = sSignal.E(abFahrt & sSignal.E ~= 0);   % Regelfehler in der Fahrt, ohne e = 0 [rad]
sAuswertung.FehlerMax_Grad = max(abs(rad2deg(afFehler)));
sAuswertung.StellgroesseMax = max(abs(sSignal.U(abFahrt)));

% "Erreichte Endstrecke, mit Sollstrecke vergleichen" -> s bei Stopp und am Ende (Nachlauf)
sAuswertung.StreckeStopp_m = sSignal.S(sSignal.nStopp);
sAuswertung.StreckeEnde_m = sSignal.S(end);
sAuswertung.Nachlauf_m = sSignal.S(end) - sSignal.S(sSignal.nStopp);

% "Einfluss von KP" -> KP = u / e (gilt auch nach Tunen), Vorzeichenwechsel von e
sAuswertung.Kp_1proRad = median(sSignal.U(abFahrt & sSignal.E ~= 0) ./ afFehler);
sAuswertung.Vorzeichenwechsel = sum(diff(sign(afFehler)) ~= 0);
end

function BeschrifteAchse(stTitel,stAchseX,stAchseY)
% BeschrifteAchse: Titel, Achsenbeschriftung und Gitter der aktuellen Achse
% Eingabe:  stTitel [Text]: Titel, stAchseX, stAchseY [Text]: Achsen mit Groesse und Einheit
title(stTitel);
xlabel(stAchseX);
ylabel(stAchseY);
grid on;
end
