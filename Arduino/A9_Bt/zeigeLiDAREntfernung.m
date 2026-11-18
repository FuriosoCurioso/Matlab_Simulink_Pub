clear all; close all
%% Initialisierung: Handle zeigt auf alle folgenden Operationen
HC05 = bluetooth('202505008012', 1);    % Sensorbezeichnung eventuell anpassen!
configureTerminator(HC05, 'CR/LF'); % zeigt Ende des Datenpaketes an

nDaten = inf;                      % Anzahl Datensätze / Abbruchbedingung
i= 0;                              % Index Datenzähler
tic;                               

%% Ergebnisdarstellung
hFig  = figure;                         
hLine = animatedline('LineWidth', 1);    % Handle auf animierten Liniengraph

%% A: Echtzeit-Plot
xlabel('Zeit in s');             
ylabel('Entfernung in mm');

%% Bluetooth empfangen Schleife
while true

i<nDaten

    % Daten lesen
    n = HC05.NumBytesAvailable;   % Anzahl verfügbarer Bytes im Empfangspuffer

    if n>0                        % Daten vorhanden?
        stData = readline(HC05);     % Zeile lesen

        if ~isempty(stData)         % Daten empfangen?
            i = i+1;

            afDist(i) = str2double(stData); % Entfernung in mm sichern
            afZeit(i) = toc;                        % Zeit messen

            addpoints(hLine, afZeit(i), afDist(i)); % Daten Echtzeit visualisieren
            drawnow;
            save('Messdaten.mat', 'afDist', 'afZeit'); % Daten speichern
        end      
    end
end
