function stDatei = SpeichereOdometrieMessung()
% Ausgabe:  stDatei [Text]: gespeicherte Datei
stModell = 'AlphaBotOdometrie';       % Modellname

% Zielordner: Ordner der .slx
try
    stZielOrdner = fileparts(get_param(stModell,'FileName'));
catch
    stZielOrdner = fileparts(mfilename('fullpath'));
end

% Zuordnung: Name der Spezifikation | Signalname im Modell | Einheit | Bedeutung
caZuordnung = {
    'SL',      'SenOdo_SL_f32',     'm',   'Strecke des linken Rades'
    'SR',      'SenOdo_SR_f32',     'm',   'Strecke des rechten Rades'
    'S',       'SenOdo_S_f32',      'm',   'mittlere Strecke (SL + SR) / 2'
    'VL',      'SenOdo_VL_f32',     'm/s', 'Geschwindigkeit des linken Rades'
    'VR',      'SenOdo_VR_f32',     'm/s', 'Geschwindigkeit des rechten Rades'
    'Zustand', 'AktMot_Zustand_u8', '-',   'Fahrablauf: 0 Stillstand, 1 Fahrt, 2 Stopp'};

AlphaBotOdometrie = struct();         % Messung, Struktur wie Odometrie.mat
try
    sDaten = export(Simulink.sdi.getCurrentSimulationRun(stModell));   % letzter Lauf im SDI
    caLog = sDaten.getElementNames;   % Namen der geloggten Signale
    for k = 1:size(caZuordnung,1)
        nIndex = find(strcmp(caLog,caZuordnung{k,2}),1);   % Position im Dataset [-]
        if isempty(nIndex)
            continue                  % nicht geloggt -> Feld fehlt
        end
        sQuelle = sDaten.getElement(nIndex).Values;
        afZeit = sQuelle.Time(:);     % Zeitachse [s]
        sNeu = timeseries(double(squeeze(sQuelle.Data)),afZeit,'Name',caZuordnung{k,1});
        sNeu.DataInfo.Units = caZuordnung{k,3};
        sNeu.UserData = struct('Bedeutung',caZuordnung{k,4},'Einheit',caZuordnung{k,3}, ...
            'Modellsignal',caZuordnung{k,2},'Abtastzeit_s',median(diff(afZeit)));
        AlphaBotOdometrie.(caZuordnung{k,1}) = sNeu;
    end
catch sFehler
    warning('SpeichereOdometrieMessung:Daten','Logdaten fehlen oder unvollstaendig: %s',sFehler.message);
end

% Neue Datei; eine vorhandene Messung wird nie ueberschrieben
stDatei = fullfile(stZielOrdner,'OdometrieMessung.mat');
if isfile(stDatei)
    stDatei = fullfile(stZielOrdner,['OdometrieMessung_' char(datetime('now','Format','yyyyMMdd_HHmmss')) '.mat']);
end
save(stDatei,'AlphaBotOdometrie');
fprintf('Gespeichert: %s (%s)\n',stDatei,strjoin(fieldnames(AlphaBotOdometrie)',', '));
end