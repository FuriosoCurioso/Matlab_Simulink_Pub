function stDatei = SpeichereKreisfahrt(stModell)
% Eingabe:  stModell [Text]: Modellname (Standard 'AlphaBotKreisfahrt')
% Ausgabe:  stDatei  [Text]: gespeicherte Datei
if nargin < 1 || isempty(stModell)
    stModell = 'AlphaBotKreisfahrt';
end

% Zielordner: Ordner der .slx
try
    stZielOrdner = fileparts(get_param(stModell,'FileName'));
catch
    stZielOrdner = fileparts(mfilename('fullpath'));
end

data = Simulink.SimulationData.Dataset;   % leer, falls keine Logdaten
try
    data = export(Simulink.sdi.getCurrentSimulationRun(stModell));
catch sFehler
    warning('SpeichereKreisfahrt:keineDaten','Keine Logdaten von %s: %s',stModell,sFehler.message);
end

% Fahrt abgebrochen? -> nur Warnung, Daten werden trotzdem gespeichert
if ~any(strcmp(data.getElementNames,'AktMot_Zustand_u8')) || ...
        ~any(data.getElement('AktMot_Zustand_u8').Values.Data(:) == 3)
    warning('SpeichereKreisfahrt:keineFahrt','Zustand Stopp nicht erreicht: Kreisfahrt unvollstaendig.');
end

% Parameterwerte des Laufs (Simulink.Parameter -> Wert)
sParameter = struct('Modell',stModell,'Zeit',char(datetime('now','Format','dd.MM.yyyy HH:mm:ss')));
try
    hWorkspace = get_param(stModell,'ModelWorkspace');   % Parameter im Model Workspace
    caName = {hWorkspace.whos.name};
    for k = 1:numel(caName)
        wert = hWorkspace.getVariable(caName{k});
        if isa(wert,'Simulink.Parameter')
            wert = wert.Value;
        end
        sParameter.(caName{k}) = wert;
    end
catch sFehler
    warning('SpeichereKreisfahrt:keineParameter','Parameter nicht gelesen: %s',sFehler.message);
end

% Neue Datei; eine vorhandene Messung wird nie ueberschrieben
stDatei = fullfile(stZielOrdner,'Kreisfahrt.mat');
if isfile(stDatei)
    stDatei = fullfile(stZielOrdner,['Kreisfahrt_' char(datetime('now','Format','yyyyMMdd_HHmmss')) '.mat']);
end
save(stDatei,'data','sParameter');
fprintf('Gespeichert: %s (%d Signale)\n',stDatei,data.numElements);
end
