function stDatei = SpeichereTopconRef(stTxtDatei,stMatDatei)
% SpeichereTopconRef: Topcon-Export (.txt) -> Referenz und Zeitstempel (.mat)
% Eingabe:  stTxtDatei [Text]: MagnetField-Export, Trennzeichen ;
%           stMatDatei [Text]: Zielname, z. B. 'RefGeradeausfahrt.mat' (Ordner der .txt)
% Ausgabe:  stDatei    [Text]: tatsaechlich geschriebene Datei

ZEIT_FORMATE = {'dd.MM.yyyy HH:mm:ss.SSS','dd.MM.yyyy HH:mm:ss'};   % Time Stamp mit/ohne Bruchteile [-]

% Zeilen lesen
astZeile = readlines(stTxtDatei);     % alle Zeilen der Datei
astZeile = astZeile(strlength(strtrim(astZeile)) > 0 & ~startsWith(astZeile,'Header>>'));
nZeilen = numel(astZeile);            % Datenzeilen [-]
astZeit = strings(nZeilen,1);         % Spalte Time Stamp
afWinkelH = nan(nZeilen,1);           % Horizontalwinkel H [Grad]
afDistanz = nan(nZeilen,1);           % Schraegentfernung d [m]
afWinkelV = nan(nZeilen,1);           % Vertikalwinkel V  [Grad]

for k = 1:nZeilen
    astFeld = split(astZeile(k),';'); % Time; Time Stamp; H; d; V; ...
    if numel(astFeld) >= 5
        astZeit(k) = strtrim(astFeld(2));
        afWinkelH(k) = double(astFeld(3));
        afDistanz(k) = double(astFeld(4));
        afWinkelV(k) = double(astFeld(5));
    end
end

% Zeitstempel: Formate nacheinander versuchen
afDatum = NaT(nZeilen,1);             % Messzeitpunkte
for k = 1:numel(ZEIT_FORMATE)
    abOffen = isnat(afDatum);
    afDatum(abOffen) = datetime(astZeit(abOffen),'InputFormat',ZEIT_FORMATE{k});
end

% Ungueltige Zeilen weg (Prisma verloren, Zeile unvollstaendig)
abGueltig = ~isnat(afDatum) & ~isnan(afWinkelH) & ~isnan(afDistanz) & ~isnan(afWinkelV);
if any(~abGueltig)
    warning('SpeichereTopconRef:ungueltig','%d von %d Zeilen ungueltig, entfernt.',sum(~abGueltig),nZeilen);
end
afDatum = afDatum(abGueltig);
afWinkelH = afWinkelH(abGueltig);
afDistanz = afDistanz(abGueltig);
afWinkelV = afWinkelV(abGueltig);

% Ebene mit Vertikalwinkel: horizontale Entfernung d*cos(V), z = d*sin(V)
afHorizontal = afDistanz .* cosd(afWinkelV);   % horizontale Entfernung [m]
Referenz = [afHorizontal .* sind(afWinkelH), afHorizontal .* cosd(afWinkelH), afDistanz .* sind(afWinkelV)].';   % x, y, z [m]

%{
% Ohne Korrektur (Wiki: x = d*sin(H), y = d*cos(H), Vertikalwinkel vernachlaessigt, z = 0)
Referenz = [afDistanz .* sind(afWinkelH), afDistanz .* cosd(afWinkelH), zeros(size(afDistanz))].';   % x, y, z [m]
%}

Zeitstempel = seconds(afDatum - afDatum(1)).';   % Zeit ab erstem Messwert [s]

% Doppelte Zeitstempel (nur ganze Sekunden) oder wiederholte Positionen -> Warnung fuer die Synchronisation
if any(diff(Zeitstempel) <= 0)
    warning('SpeichereTopconRef:Zeit','Zeitstempel nicht streng steigend (ganze Sekunden?): Synchronisation ungenau.');
end

% Neue Datei im Ordner der .txt
stDatei = fullfile(fileparts(stTxtDatei),stMatDatei);
if isfile(stDatei)
    stDatei = strrep(stDatei,'.mat',['_' char(datetime('now','Format','yyyyMMdd_HHmmss')) '.mat']);
end
save(stDatei,'Referenz','Zeitstempel');
fprintf('Gespeichert: %s (%d Punkte, %.1f s)\n',stDatei,numel(Zeitstempel),Zeitstempel(end));

%{
% Option MATLAB-Demo trackePrisma.m (SVN MTR_SDE_Praktikum/.../RobotikTotalStation/SRC, Wiki Topcon)
% statt MagnetField-Export. Annahme [ungeprueft]: das Demo liefert Zeit und X, Y, Z der
% Topcon (NEZAUS-S ueber Bluetooth) als Vektoren; Datei- und Variablennamen an das Demo anpassen!
sDemo = load('<Ausgabe trackePrisma>.mat');   % ANPASSEN!
afZeitDemo = sDemo.t(:);              % Zeit [s] ANPASSEN!
Referenz = [sDemo.x(:), sDemo.y(:), sDemo.z(:)].';   % x, y, z [m] ANPASSEN!
Zeitstempel = (afZeitDemo - afZeitDemo(1)).';   % Zeit ab erstem Messwert [s]
save(fullfile(fileparts(stTxtDatei),stMatDatei),'Referenz','Zeitstempel');
%}

end
