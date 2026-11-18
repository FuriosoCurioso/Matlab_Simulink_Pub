
clear; clc;

load('IRMessung.mat');
whos

afSollAbstand = [3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 29];  % Sollabstaende der Stufen [cm]
nStufen = numel(afSollAbstand);       % Anzahl Stufen
nStart = 201;                         % erster ausgewerteter Wert, t = 2 s
caNamen = data.getElementNames;       % Namen der exportierten Laeufe
afSpgFit = zeros(nStufen,1);          % x-Daten Curve Fitter: mittlere gefilterte Spannung je Stufe [V]

% Mittelwert der gefilterten Spannung je Stufe Durchgang 1 (Laeufe K_xxcm)
for k = 1:nStufen
    stLauf = sprintf('K_%02dcm',afSollAbstand(k));                % Laufname, z.B. K_03cm
    nIndex = find(strcmp(caNamen,stLauf));                         % Position des Laufs im Export
    hSignal = data.getElement(nIndex).get('FltIr_SpgMd_f32');      % gefilterte Spannung
    afAlle = squeeze(hSignal.Values.Data);                         % alle Werte des Laufs [V]
    afSpgFit(k) = mean(afAlle(nStart:end));
end

afDistFit = afSollAbstand';           % y-Daten Curve Fitter: Sollabstand je Stufe [cm]