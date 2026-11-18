% Charakterisierung des IR-Abstandssensors aus IRMessung.mat: Messbereich, Zeitaufloesung a_t,
% Werteaufloesung a_s, Kennlinie d(U) (Potenzansatz) mit Konfidenzband, Empfindlichkeit E und Messunsicherheit (1 sigma).


clear; clc;
load('IRMessung.mat');
whos

nAnzahl = 1024;           % Anzahl Signale im Dataset [-]
afMesswerte = zeros(121,nAnzahl);     % je Spalte eine Messreihe [cm]

for k = 1:1024
    hLauf = data.getElement(1024);               % Lauf k, selbst ein Dataset
    hSignal = hLauf.get('SenIr_SpgV_f32');  % Signal des Laufs k
    afMesswerte(:,k) = squeeze(hSignal.Values.Data);
    ergebnis = mean(afMesswerte)
end

afZeit = (0:120)' * 0.1; 

figure;
plot(afZeit,afMesswerte);
title('IR-Messreihen');
xlabel('Zeit t [s]');
ylabel('Spannung[V]');
legend(compose('Messreihe %d',1:nAnzahl),'Location','best');


%{
close all; clear; clc;

load('IRMessung.mat');
class(data)                            % erwartet: Simulink.SimulationData.Dataset
data.getElementNames                   % erwartet: 24 Laeufe K_03cm ... P_29cm
data.getElement(1).getElementNames     % erwartet: u.a. SenIr_Adc_f32, SenIr_SpgV_f32, SenIr_DistCm_f32

% U_REFERENZ = 5;                     % Referenzspannung des ADC [V]
U_LSB = 5 / 1024;                     % Spannung einer ADC-Stufe, U_ref / 2^10 [V]
T_ABTAST = 0.01;                      % Abtastzeit Analog Input (PAR_SenIr_Abtast_f64) [s]
% FIT_TYP = 'power2';                   % Ansatz d = a * U^b + c

afSollAbstand = [3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 29];  % Sollabstaende der Stufen [cm]
nStufen = numel(afSollAbstand);       % Anzahl Stufen
nStart = 201;                         % erster ausgewerteter Wert, t = 2 s

afSpgMittel = zeros(nStufen,1);       % mittlere Spannung je Stufe, Durchgang 1 [V]
afSpgStreu = zeros(nStufen,1);        % Standardabweichung der Spannung je Stufe [V]
afDistStreu = zeros(nStufen,1);       % Messunsicherheit 1 sigma je Stufe, Durchgang 2 [cm]
caDt = cell(nStufen,1);               % Zeiten zwischen ADC-Wertaenderungen je Lauf [s]

% Messwerte je Stufe lesen (ungefilterte Signale)
for k = 1:nStufen
    stKalib = sprintf('K_%02dcm',afSollAbstand(k));   % Laufname Durchgang 1
    stPruef = sprintf('P_%02dcm',afSollAbstand(k));   % Laufname Durchgang 2

    afSpg = LeseSignal(data,stKalib,'SenIr_SpgV_f32');            % Sensorspannung [V]
    afSpgMittel(k) = mean(afSpg(nStart:end));
    afSpgStreu(k) = std(afSpg(nStart:end));

    [afAdc, afZeit] = LeseSignal(data,stKalib,'SenIr_Adc_f32');   % ADC-Wert [-], Zeit [s]
    anWechsel = find(diff(afAdc(nStart:end)) ~= 0) + nStart;       % Indizes neuer ADC-Werte
    caDt{k} = diff(afZeit(anWechsel));

    afDist = LeseSignal(data,stPruef,'SenIr_DistCm_f32');         % Abstand ungefiltert [cm]
    afDistStreu(k) = std(afDist(nStart:end));
end

% Messbereich MB
[~, nMbAnf] = max(afSpgMittel);                                   % erste Stufe MB
afAbnahme = -diff(afSpgMittel(nMbAnf:end));                       % Abnahme Folgestufe [V]
afGrenze = 2 * sqrt(afSpgStreu(nMbAnf:end - 1).^2 + afSpgStreu(nMbAnf + 1:end).^2);  % [V]
nMbEnd = nMbAnf - 1 + find([afAbnahme <= afGrenze; true],1);      % letzte Stufe MB 
anMb = (nMbAnf:nMbEnd)';                                          % Indizes der Stufen MB
fMbMin = afSollAbstand(nMbAnf);                                   % untere Grenze MB [cm]
fMbMax = afSollAbstand(nMbEnd);                                   % obere Grenze MB [cm]
fprintf('Messbereich MB: %g cm bis %g cm\n',fMbMin,fMbMax);

% Kennlinie d(U) mit d = a * U^b + c), Stufen im MB
afSpgFit = afSpgMittel(anMb);                                     % x-Daten [V]
afDistFit = afSollAbstand(anMb)';                                 % y-Daten [cm]
[FitKennlinie, sGuete] = fit(afSpgFit,afDistFit,'power2');        % Regression und Guete
afSpgFein = linspace(min(afSpgFit),max(afSpgFit),200)';          % Stuetzstellen im MB [V]
afDistFein = FitKennlinie(afSpgFein);                             % Regressionsfunktion d(U) [cm]
afBand = predint(FitKennlinie,afSpgFein,0.95,'functional');       % 95-%-Konfidenzband [cm]

% Empfindlichkeit E = |dU/dd| = 1 / |dd/dU|
afEmpf = 1 ./ abs(differentiate(FitKennlinie,afSpgFein));         % Empfindlichkeit E [V/cm]

% Werteaufloesung a_s = U_LSB / E, Faktor 10 fuer cm -> mm
afAufl = U_LSB ./ afEmpf * 10;                                    % Werteaufloesung a_s [mm]

% Kennwerte der Sensorcharakterisierung
afDt = vertcat(caDt{:});                                          % alle Zeitabstaende [s]
fAtMedian = median(afDt);                                         % typische Zeitaufloesung [s]
fAuflMin = min(afAufl) / 10;                                      % feinste Werteaufloesung [cm]
fAuflMax = max(afAufl) / 10;                                      % groebste Werteaufloesung [cm]
fEmpfMax = max(afEmpf);                                           % groesste Empfindlichkeit [V/cm]
afDistHoch = afDistFein(afEmpf >= 0.5 * fEmpfMax);                % Abstaende mit E >= 50 % E_max [cm]
fEmpfVon = min(afDistHoch);                                       % Beginn empfindlichster Bereich [cm]
fEmpfBis = max(afDistHoch);                                       % Ende empfindlichster Bereich [cm]
fSigmaMin = min(afDistStreu(anMb));                               % kleinste Unsicherheit im MB [cm]
fSigmaMax = max(afDistStreu(anMb));                               % groesste Unsicherheit im MB [cm]

% Abbildung 2: Kennlinie mit Regression und 95-%-Konfidenzband
figure;
hBand = fill([afSpgFein; flipud(afSpgFein)],[afBand(:,1); flipud(afBand(:,2))],'b', ...
    'FaceAlpha',0.2,'EdgeColor','none');
hold on;
hMessung = plot(afSpgFit,afDistFit,'ro');
hKurve = plot(afSpgFein,afDistFein,'b');
grid on;
title(sprintf('Kennlinie d(U), R^2 = %.5f',sGuete.rsquare));
xlabel('Spannung U [V]');
ylabel('Abstand d [cm]');
legend([hMessung, hKurve, hBand],{'Messwerte (Stufenmittelwerte)','Regression','95-%-Konfidenzband'});

% Abbildung 3: Sensorcharakterisierung (Messbereich, a_t, a_s, E)
figure;

% Messbereich als Linie auf mittlerer Spannungshoehe
subplot(2,2,1);
hStufen = plot(afSollAbstand,afSpgMittel,'ro-');
hold on;
fHoehe = mean(afSpgMittel);                                       % Hoehe der Bereichslinie [V]
hMb = plot([fMbMin, fMbMax],[fHoehe, fHoehe],'k.-','MarkerSize',15);
text(mean([fMbMin, fMbMax]),fHoehe,sprintf('Messbereich: %g cm - %g cm',fMbMin,fMbMax), ...
    'HorizontalAlignment','center','VerticalAlignment','bottom');
grid on;
title('Messbereich');
xlabel('Abstand d [cm]');
ylabel('Spannung U [V]');
legend([hStufen, hMb],{'Stufenmittelwerte (Durchgang 1)','Messbereich'});

% Zeitaufloesung als Histogramm, Klassen um Vielfache der Abtastzeit
subplot(2,2,2);
histogram(afDt,'BinEdges',((0:10) + 0.5) * T_ABTAST);
grid on;
title(sprintf('Zeitauflösung a_t, Median %.2f s',fAtMedian));
xlabel('Zeit zwischen Wertänderungen \Delta t [s]');
ylabel('Anzahl [-]');

% Werteaufloesung in mm ueber dem Messbereich
subplot(2,2,3);
plot(afDistFein,afAufl,'b');
grid on;
title('Werteauflösung');
xlabel('Abstand d [cm]');
ylabel('Werteauflösung a_s [mm]');

% Empfindlichkeit ueber dem Messbereich
subplot(2,2,4);
plot(afDistFein,afEmpf,'b');
grid on;
title('Empfindlichkeit');
xlabel('Abstand d [cm]');
ylabel('Empfindlichkeit E = |dU/dd| [V/cm]');

% Messunsicherheit (1 sigma) ueber dem Messbereich, Durchgang 2
figure;
plot(afSollAbstand(anMb),afDistStreu(anMb),'bo-');
grid on;
title('Messunsicherheit 1\sigma (Durchgang 2, ungefiltert)');
xlabel('Abstand d [cm]');
ylabel('Messunsicherheit \sigma [cm]');

% Befunde zur Kennlinie
%   Unterhalb von fMbMin kehrt sich die Kennlinie um (Abstand nicht eindeutig), oberhalb von fMbMax ist die
%   Spannungsaenderung zur Folgestufe kleiner als die Streuung.
%   Zeitaufloesung a_t: unveraenderte ADC-Folgewerte verlaengern dt [Interpretation].
%   a_s = U_LSB / E waechst mit dem Abstand, weil E sinkt.
% Vergleich mit dem Datenblatt (Sheet No. OP13008EN)
%   DB 30 cm -> 4 cm: 1,95 / 2,25 / 2,55 V

%{
fMbMin
fMbMax
fAtMedian
fAuflMin
fAuflMax
fEmpfVon
fEmpfBis
fEmpfMax
fSigmaMin
fSigmaMax
afSpgMittel
sGuete
%}

function [afWerte, afZeit] = LeseSignal(data, stLauf, stSignal)
% LeseSignal: Werte und Zeitstempel eines Signals aus einem exportierten SDI-Lauf
% Eingang  data     [Dataset]: Variable data aus IRMessung.mat
%          stLauf   [char]: Laufname, z.B. 'K_03cm'
%          stSignal [char]: Signalname, z.B. 'SenIr_SpgV_f32'
% Ausgang  afWerte  [Nx1 double]: Signalwerte [Einheit des Signals]
%          afZeit   [Nx1 double]: Zeitstempel [s]
caNamen = data.getElementNames;                   % Namen aller Laeufe
nIndex = find(strcmp(caNamen,stLauf));            % Position des Laufs im Export
hSignal = data.getElement(nIndex).get(stSignal);  % Signal des Laufs
afWerte = double(squeeze(hSignal.Values.Data));
afZeit = double(hSignal.Values.Time);
end
%}