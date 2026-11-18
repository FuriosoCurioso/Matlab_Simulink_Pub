close all; clear; clc;

MESS_DATEI = 'GyroMessung.mat';       % Messdatei im Ordner des Skripts ANPASSEN!
DREH_SCHWELLE = 5;                    % ab |GyroZKorr| > Schwelle gilt ein Wert als Drehung [Annahme] [Grad/s]
RESTOFFSET = 0.1;                     % Restoffset der Kontrollfrage 6 [Grad/s]
ZEIT_BEISPIEL = 60;                   % Integrationszeit der Kontrollfrage 6 [s]

sMess = load(MESS_DATEI);
whos('-file',MESS_DATEI)
LeseWert = @(stName) double(reshape(sMess.data.getElement(stName).Values.Data,[],1));
afZeit = sMess.data.getElement('SenGyr_GyroZ_f32').Values.Time(:);   % Zeit des Modells [s]
afGz = LeseWert('SenGyr_GyroZ_f32');          % Gierrate z ohne Korrektur [Grad/s]
afOffset = LeseWert('SenGyr_GyroOffset_f32'); % Offset aus dem Enable Subsystem [Grad/s]
afGzKorr = LeseWert('SenGyr_GyroZKorr_f32');  % Gierrate z korrigiert [Grad/s]
anZustand = LeseWert('AktMot_Zustand_u8');    % Zustand des Ablaufs [-]
fAbtast = median(diff(afZeit));       % Abtastzeit der Aufzeichnung [s]

% Letzte Kalibrierung (nach Reset gilt der neue Offset)
nKalibEnde = find(anZustand == 0,1,'last');   % letzter Wert in Zustand 0 [-]
nKalibBeginn = find(anZustand(1:nKalibEnde) ~= 0,1,'last') + 1;
if isempty(nKalibBeginn)
    nKalibBeginn = 1;
end
abKalib = false(size(afZeit));        % Werte der Kalibrierung [-]
abKalib(nKalibBeginn:nKalibEnde) = true;
abNach = (1:numel(afZeit)).' > nKalibEnde;   % Werte nach der Kalibrierung [-]
abDreh = abNach & abs(afGzKorr) > DREH_SCHWELLE;   % Werte waehrend einer Drehung [-]
abRuhe = abNach & ~abDreh;            % Werte ohne Drehung nach der Kalibrierung [-]

% "Stillstand gegen Drehung" -> Mittel, std (n-1), SNR; Online-Offset gegen Offline-Mittel
sAuswertung = struct();
sAuswertung.NKalib = sum(abKalib);
sAuswertung.MittelStill_Grads = mean(afGz(abKalib));
sAuswertung.StdStill_Grads = std(afGz(abKalib));
sAuswertung.OffsetOnline_Grads = afOffset(min(nKalibEnde + 1,numel(afOffset)));
sAuswertung.OffsetDiff_Grads = sAuswertung.OffsetOnline_Grads - sAuswertung.MittelStill_Grads;
sAuswertung.MittelRuhe_Grads = mean(afGzKorr(abRuhe));
sAuswertung.NDreh = sum(abDreh);
sAuswertung.MaxDreh_Grads = max([0; abs(afGzKorr(abDreh))]);
sAuswertung.SNR = sAuswertung.MaxDreh_Grads / sAuswertung.StdStill_Grads;

% "Winkelfehler durch fehlerhafte Offsetbestimmung" -> psi_k = psi_k-1 + omega_k * T ab Kalibrierende
afWinkelOhne = cumsum(afGz .* abNach) * fAbtast;      % Winkel ohne Korrektur [Grad]
afWinkelMit = cumsum(afGzKorr .* abNach) * fAbtast;   % Winkel mit Korrektur [Grad]
sAuswertung.Dauer_s = sum(abNach) * fAbtast;
sAuswertung.WinkelOhne_Grad = afWinkelOhne(end);
sAuswertung.WinkelMit_Grad = afWinkelMit(end);
sAuswertung.Drift_Grad = afWinkelOhne(end) - afWinkelMit(end);
sAuswertung.FehlerBeispiel_Grad = RESTOFFSET * ZEIT_BEISPIEL;

% Ausgabe der Ergebnisse
fprintf('** Auswertung **\n');
fprintf('GyroZ ueber t [Zustaende 0-3, Abtastzeit]: %d Werte, %.1f s, T = %.3f s, Kalibrierung %.2f-%.2f s\n', ...
    numel(afZeit),afZeit(end)-afZeit(1),fAbtast,afZeit(nKalibBeginn),afZeit(nKalibEnde));
fprintf('Stillstand [Kalibrierung, %d Werte]: Mittel %.3f Grad/s, std %.3f Grad/s\n', ...
    sAuswertung.NKalib,sAuswertung.MittelStill_Grads,sAuswertung.StdStill_Grads);
fprintf('    Online-Offset [rekursiver Mittelwert]: %.3f Grad/s, gegen Offline-Mittel %+.4f Grad/s\n', ...
    sAuswertung.OffsetOnline_Grads,sAuswertung.OffsetDiff_Grads);
fprintf('    Drehung [|GyroZKorr| > %.0f Grad/s]: %d Werte, max %.1f Grad/s, SNR %.0f; Ruhe korrigiert %.3f Grad/s\n', ...
    DREH_SCHWELLE,sAuswertung.NDreh,sAuswertung.MaxDreh_Grads,sAuswertung.SNR,sAuswertung.MittelRuhe_Grads);
fprintf('Winkelfehler [Delta psi = b * t]: nach %.1f s ohne Korrektur %.1f Grad, mit %.1f Grad, Drift %.1f Grad; %.1f Grad/s * %.0f s = %.1f Grad\n', ...
    sAuswertung.Dauer_s,sAuswertung.WinkelOhne_Grad,sAuswertung.WinkelMit_Grad,sAuswertung.Drift_Grad, ...
    RESTOFFSET,ZEIT_BEISPIEL,sAuswertung.FehlerBeispiel_Grad);
fprintf('\n');

% Literaturwerte
fprintf('** Literaturwerte **\n');
fprintf('Fixed-step 0.01 s (Leitfaden); 1000 Werte * 0.01 s = 10 s Kalibrierung; Messbereich +-250 Grad/s, 131 LSB/(Grad/s) (Datenblatt 3.1)\n');
fprintf('Anfangsoffset +-5 Grad/s, Rauschen 0.1 Grad/s rms bei DLPF 92 Hz (Datenblatt 3.1); x_k = x_k-1 + (x - x_k-1)/k (Leitfaden 1.3)\n');
fprintf('Bias 0.5 Grad/s * 5 s = 2.5 Grad (Vorbereitung 2); Restoffset 0.1 Grad/s * 60 s = 6 Grad (Kontrollfrage 6)\n');

% "Gierrate GyroZ ueber t" mit Zustaenden
figure;
subplot(2,1,1);
plot(afZeit,afGz,'r',afZeit,afGzKorr,'b',afZeit,afOffset,'k--');
xline(afZeit(nKalibEnde),'k:');
BeschrifteAchse('Gierrate z der MPU-9250','Zeit t [s]','Gierrate \omega_z [Grad/s]');
legend('GyroZ','GyroZ korrigiert','GyroOffset','Ende Kalibrierung');
subplot(2,1,2);
stairs(afZeit,anZustand,'b');
BeschrifteAchse('Zustand des Ablaufs','Zeit t [s]','Zustand [-]');
yticks(0:3);
yticklabels({'0 Kalibrierung','1 Stillstand','2 Kreisfahrt','3 Stopp'});

% "Stillstand gegen Drehung" -> Verteilung der Werte
figure;
subplot(1,2,1);
histogram(afGz(abKalib),30);
BeschrifteAchse(sprintf('Stillstand (std %.3f Grad/s)',sAuswertung.StdStill_Grads), ...
    'Gierrate \omega_z [Grad/s]','Anzahl [-]');
subplot(1,2,2);
histogram(afGzKorr(abNach),30);
BeschrifteAchse('Nach der Kalibrierung (korrigiert)','Gierrate \omega_z [Grad/s]','Anzahl [-]');

% "Winkelfehler" -> Winkel ohne und mit Korrektur
figure;
plot(afZeit,afWinkelOhne,'r',afZeit,afWinkelMit,'b');
BeschrifteAchse('Winkel durch Integration der Gierrate','Zeit t [s]','Winkel \psi [Grad]');
legend('ohne Korrektur (Drift)','mit Korrektur');

function BeschrifteAchse(stTitel,stAchseX,stAchseY)
% BeschrifteAchse: Titel, Achsenbeschriftung und Gitter der aktuellen Achse
% Eingabe:  stTitel [Text]: Titel, stAchseX, stAchseY [Text]: Achsen mit Groesse und Einheit
title(stTitel);
xlabel(stAchseX);
ylabel(stAchseY);
grid on;
end
