% Erzeugt die .gitignore des Repositorys: nur .m, .slx, README.md, LICENSE, .gitignore und .gitattributes; Dateien mit Zahl am Ende werden ignoriert, wenn dieselbe Datei ohne Zahl im selben Ordner liegt. Nach neuen Dateien erneut ausfuehren.

close all; clear; clc;

stOrdner = fileparts(mfilename('fullpath'));  % Wurzel des Repositorys [-]
caKopf = {'# Erzeugt von aktualisiereGitignore.m - nicht von Hand aendern', ...
    '*', '!*/', '!*.m', '!*.slx', '!README.md', '!LICENSE', '!.gitignore', '!.gitattributes', '/erase.m', '', ...
    '# Nummerierte Varianten mit gleichnamiger Grunddatei'};  % feste Regeln [-]
caIgnoriert = {};                             % ignorierte Varianten (Pfade relativ) [-]

asDateien = [dir(fullfile(stOrdner,'**','*.m')); dir(fullfile(stOrdner,'**','*.slx'))];  % alle Kandidaten [-]
for k = 1:numel(asDateien)
    [~,stName,stEndung] = fileparts(asDateien(k).name);
    caTreffer = regexp(stName,'^(.*?)_?\d+$','tokens','once');
    if ~isempty(caTreffer) && ~isempty(caTreffer{1}) && ...
            isfile(fullfile(asDateien(k).folder,[caTreffer{1} stEndung]))
        stRelativ = strrep(extractAfter(fullfile(asDateien(k).folder,asDateien(k).name),[stOrdner filesep]),'\','/');
        caIgnoriert{end + 1} = ['/' regexprep(stRelativ,'([ #!\[\]])','\\$1')]; %#ok<AGROW>
    end
end

writelines([caKopf, sort(caIgnoriert)],fullfile(stOrdner,'.gitignore'));
fprintf('Gitignore: %d nummerierte Varianten ignoriert\n',numel(caIgnoriert));
