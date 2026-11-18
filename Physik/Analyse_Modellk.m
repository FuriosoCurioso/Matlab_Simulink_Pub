%[text] # Modellkette der Längsdynamik: Stufen 0–6 an einem durchgehenden Bremsvorgang
%[text] **Leitfrage der Arbeit:** Welche Modelltiefe braucht die Beschreibung der Längsdynamik, und woran erkennt man physikalisch, dass ein Modell nicht mehr ausreicht?
%[text] Herkunft jeder Zahl: **berechnet** (in diesem Skript nachgebildet), **gespeichert** (steht so in einer Ergebnisdatei des Projekts), **simuliert** (Simulink-Modell des Projekts, ode45, RelTol $10^{-6}$) oder **Annahme**. Das Skript startet kein Simulink-Modell und schreibt keine Dateien.
close all; clear; clc;

SCHRIFT_GROESSE = 10;  % Schriftgroesse von Achsen, Titeln und Legenden (Vorgabe) [pt]
TOL_LAST = 1;          % Toleranz fuer Kraftvergleiche (10_SEMINAR.md, Abschnitt 5) [N]
stOrdner = fileparts(mfilename('fullpath'));  % Ordner simulink/ mit den Stufenordnern [-]
if startsWith(stOrdner,tempdir)  % Live Editor meldet seinen Temp-Ordner statt des Dateiordners
    stOrdner = fileparts(matlab.desktop.editor.getActiveFilename);  % Ordner der geoeffneten Datei [-]
end
addpath(stOrdner,fullfile(stOrdner,'Stufe_4_bis_7'));  % parameterFahrzeug.m und parameterAufbau.m

sS1 = load(fullfile(stOrdner,'Stufe_0_bis_3','Stufe1_FTP75.mat'));              % Projektlauf Stufen 0/1, FTP75 Phase 1 [-]
sS2 = load(fullfile(stOrdner,'Stufe_0_bis_3','Stufe2_Ausrollen.mat'));          % Projektlauf Stufen 2/3, Ausrollen [-]
sS4 = load(fullfile(stOrdner,'Stufe_4_bis_7','Stufe4_Bremsrampe.mat'));         % Projektlauf Stufe 4, Bremsrampe [-]
sS5 = load(fullfile(stOrdner,'Stufe_4_bis_7','Stufe5_Bremsrampe.mat'));         % Projektlauf Stufe 5, Bremsrampe [-]
sAusschw = load(fullfile(stOrdner,'Stufe_4_bis_7','Stufe5_Ausschwingen.mat'));  % Projektlauf Stufe 5, ungedaempft, FFT [-]
sS6 = load(fullfile(stOrdner,'Stufe_4_bis_7','Stufe6_Energiebilanz.mat'));      % Projektlauf Stufe 6, Energiebilanz [-]
set(groot,'defaultAxesFontSize',SCHRIFT_GROESSE,'defaultAxesTitleFontSizeMultiplier',1, ...
    'defaultAxesLabelFontSizeMultiplier',1,'defaultLineLineWidth',1.5,'defaultStairLineWidth',1.5,'defaultAxesXGrid','on','defaultAxesYGrid','on');

%%
%[text] ## Das Problem: Ein Fahrzeug bremst – welche Modelltiefe braucht man, um das zu beschreiben?
%[text] Längsdynamik beschreibt, wie sich ein Fahrzeug in Fahrtrichtung bewegt und welche Kräfte dabei wirken. Eine einzige Gleichung genügt dafür nicht: Je nach Frage braucht man die Bewegung selbst (Kinematik), die Kräfte, die sie erzeugen (Kinetik), deren Verteilung auf die Achsen oder die Schwingung des gefederten Aufbaus.
%[text] Die Modellkette baut diese Tiefe schrittweise auf. Jede Stufe übernimmt eine Größe der vorigen und fügt genau ein physikalisches Element hinzu: Kraft (Stufen 1, 2), Achsen (Stufe 4), Federn und Dämpfer (Stufe 5). Die Stufen 3 und 6 sind **Prüfstufen**: Sie rechnen keine neue Physik, sondern prüfen mit der Energiebilanz, ob die vorige Stufe richtig gelöst ist.
%[text] **Leitszenario** (durchgehend für alle Stufen): Das Fahrzeug fährt mit $v\_0$ = 30 m/s (108 km/h). Ab $t\_0$ = 1 s steigt die Verzögerung in der Aufbauzeit $t\_r$ = 0,3 s linear auf $a\_B$ = 8 m/s² und bleibt dann konstant; betrachtet werden 4,5 s. Das ist die Bremsrampe der Stufen 4–6 des Projekts.
%[text] **Originalgetreu und vereinfacht:** Gleichungen, Parameter, Vorzeichen und Toleranzen sind die des Projekts. Vereinfacht ist das Szenario: Im Projekt rechnen die Stufen 0/1 mit dem Fahrzyklus FTP75 Phase 1 und die Stufen 2/3 mit dem Ausrollen ab 30 m/s; hier laufen alle Stufen mit der Bremsrampe. Die Projektläufe erscheinen je Stufe als Vergleich („Projektlauf"). Werte, die nur im Leitszenario entstehen, sind neu berechnet und keine Projektwerte.

%%
%[text] ## Übersicht: Welche Größe reicht jede Stufe weiter?
%[text] Lesehinweis: Pfeile zeigen die weitergereichten Größen. **Durchgezogen:** Die Übergabe ist im Projekt als Signal umgesetzt (Skript simuliereStufe1.m, Modelle Stufe 2 und Stufe 5). **Gestrichelt:** Die Übergabe gibt es nur im Leitszenario dieses Skripts; im Projekt bekommen diese Stufen eigene Vorgaben (z. B. Stufe 2 die Konstante $F\_x = 0$). Blau: Modelle; grün: Prüfstufen.
caStufe = { ...
    'Leitszenario',     0, 4, 'k'; ...
    'S0 Kinematik',     0, 3, 'b'; ...
    'S1 Rueckwaerts',   0, 2, 'b'; ...
    'S2 Vorwaerts',     0, 1, 'b'; ...
    'S3 Energie 1DOF',  0, 0, [0 0.5 0]; ...
    'S4 Achslasten',    7, 3, 'b'; ...
    'S5 Hub/Nick 3DOF', 7, 2, 'b'; ...
    'S6 Energie 3DOF',  7, 1, [0 0.5 0]};  % Kaesten: Text, Mitte x, Mitte y, Farbe [-]
caUebergabe = { ...
    1, 2, 'v(t)',                   '--'; ...
    2, 3, 'a_k, v_m',               '-'; ...
    3, 4, 'F_x(t)',                 '--'; ...
    4, 5, 'v, F_x, F_R, F_L',       '-'; ...
    2, 6, 'a(t)',                   '--'; ...
    6, 7, 'M_y = -m a h, F_{z,i0}', '--'; ...
    7, 8, 'z, \theta, M_y',         '-'};  % Pfeile: von, nach, weitergereichte Groessen, Linienart [-]

% Zwei Spalten: links Laengsdynamik (Stufen 0-3), rechts Aufbau (Stufen 4-6); Kaesten 4,4 x 0,5 Einheiten,
%    Beschriftung rechts neben senkrechten Pfeilen bzw. ueber waagerechten Pfeilen
figure; hold on %[output:1f0a241c]
for k = 1:size(caStufe,1)
    rectangle('Position',[caStufe{k,2} - 2.2, caStufe{k,3} - 0.25, 4.4, 0.5],'Curvature',0.2,'EdgeColor',caStufe{k,4},'LineWidth',1.5); %[output:1f0a241c]
    text(caStufe{k,2},caStufe{k,3},caStufe{k,1},'HorizontalAlignment','center','Color',caStufe{k,4});
end
for k = 1:size(caUebergabe,1)
    i = caUebergabe{k,1};
    j = caUebergabe{k,2};
    if caStufe{i,3} == caStufe{j,3}  % waagerechter Pfeil
        plot([caStufe{i,2} + 2.2, caStufe{j,2} - 2.25],caStufe{i,3} * [1 1],'k','LineStyle',caUebergabe{k,4});
        plot(caStufe{j,2} - 2.3,caStufe{j,3},'k>','MarkerFaceColor','k','MarkerSize',6);
        text((caStufe{i,2} + caStufe{j,2}) / 2,caStufe{i,3} + 0.05,caUebergabe{k,3},'HorizontalAlignment','center','VerticalAlignment','bottom');
    else                             % senkrechter Pfeil
        plot(caStufe{i,2} * [1 1],[caStufe{i,3} - 0.25, caStufe{j,3} + 0.28],'k','LineStyle',caUebergabe{k,4}); %[output:1f0a241c]
        plot(caStufe{j,2},caStufe{j,3} + 0.3,'kv','MarkerFaceColor','k','MarkerSize',6);
        text(caStufe{i,2} + 0.25,(caStufe{i,3} + caStufe{j,3}) / 2,caUebergabe{k,3});
    end
end
hold off; axis off; xlim([-2.5 12.5]); ylim([-1.4 4.4]); %[output:1f0a241c]
text(-2.3,-0.95,{'durchgezogen: im Projekt umgesetzt; gestrichelt: nur im Leitszenario','blau: Modell; gruen: Pruefstufe'}); %[output:1f0a241c]
title('Modellkette Stufen 0-6: weitergereichte Groessen'); %[output:1f0a241c]
fontsize(gcf,SCHRIFT_GROESSE,'points'); %[output:1f0a241c]

%%
%[text] ## Parameter: ein Satz für alle Stufen, an einer Stelle
%[text] Alle Werte stehen in parameterFahrzeug.m (Stufen 0–7) und parameterAufbau.m (zusätzlich Stufen 4–7); die Funktion LeseParameter liest sie einmal. Fast alle Werte sind Annahmen (Lernhilfe-Satz des Projekts); Literaturangaben stehen in der Spalte Herkunft. Spalte gleich: Der Wert ist in allen gespeicherten Projektläufen derselbe (die Läufe der Stufen 1/2 kennen nur die zehn Werte aus parameterFahrzeug.m, $m$ bis $h$).
%[text] Gemeinsam genutzt werden ab hier $m$ (fMasse) und $v\_0$ (fGeschwStart); alle weiteren Größen führt die Stufe ein, die sie zuerst braucht.
sParameter = LeseParameter();  % PAR_-Werte aus parameterAufbau.m und parameterFahrzeug.m [Einheit je Feld]
caParameter = { ...
    'PAR_Lng_MasseFzg_f64',     'm',   'Fahrzeugmasse',                    'kg',     'Annahme',                          '1-6'; ...
    'PAR_Lng_BeiwLuft_f64',     'c_w', 'Luftwiderstandsbeiwert',           '-',      'Annahme',                          '1-3'; ...
    'PAR_Lng_Stirnfl_f64',      'A',   'Stirnflaeche',                     'm^2',    'Lit [4], Abb. 3.4, Schaetzwert',   '1-3'; ...
    'PAR_Lng_DichteLuft_f64',   'rho', 'Luftdichte',                       'kg/m^3', 'Annahme',                          '1-3'; ...
    'PAR_Lng_BeiwRoll_f64',     'f_R', 'Rollwiderstandsbeiwert',           '-',      'Annahme',                          '1-3'; ...
    'PAR_Lng_BeschlErde_f64',   'g',   'Erdbeschleunigung',                'm/s^2',  'Annahme (9,80665 gerundet)',       '1-4'; ...
    'PAR_Lng_GeschwStart_f64',  'v_0', 'Anfangsgeschwindigkeit',           'm/s',    'Annahme',                          '0-6'; ...
    'PAR_Ach_AbstVo_f64',       'l_v', 'Abstand Schwerpunkt-Vorderachse',  'm',      'Annahme',                          '4-6'; ...
    'PAR_Ach_AbstHi_f64',       'l_h', 'Abstand Schwerpunkt-Hinterachse',  'm',      'Annahme',                          '4-6'; ...
    'PAR_Ach_SchwerpHoehe_f64', 'h',   'Schwerpunkthoehe ueber Fahrbahn',  'm',      'Lit [4], Abb. 8.5, Interpretation', '4-6'; ...
    'PAR_Ach_BeiwHaft_f64',     'mu',  'Kraftschlussbeiwert',              '-',      'Annahme',                          '4'; ...
    'PAR_Ach_BeschlBrems_f64',  'a_B', 'Bremsverzoegerung (Betrag)',       'm/s^2',  'Annahme',                          '0-6'; ...
    'PAR_Ach_ZeitBrems_f64',    't_r', 'Aufbauzeit der Verzoegerung',      's',      'Annahme',                          '0-6'; ...
    'PAR_Ach_ZeitStart_f64',    't_0', 'Beginn der Bremsrampe',            's',      'Annahme',                          '0-6'; ...
    'PAR_Auf_FederVo_f64',      'k_v', 'Federkonstante Vorderachse',       'N/m',    'Annahme',                          '5-6'; ...
    'PAR_Auf_FederHi_f64',      'k_h', 'Federkonstante Hinterachse',       'N/m',    'Annahme',                          '5-6'; ...
    'PAR_Auf_DaempfVo_f64',     'c_v', 'Daempferkonstante Vorderachse',    'N s/m',  'Annahme',                          '5-6'; ...
    'PAR_Auf_DaempfHi_f64',     'c_h', 'Daempferkonstante Hinterachse',    'N s/m',  'Annahme',                          '5-6'; ...
    'PAR_Auf_TraeghNick_f64',   'I',   'Nicktraegheitsmoment',             'kg m^2', 'Annahme',                          '5-6'};  % Name, Zeichen, Bedeutung, Einheit, Herkunft, Stufen [-]

% Wert je Parameter und Vergleich mit den Projektlaeufen (Stufen 1/2 nur, wenn dort vorhanden)
for k = 1:size(caParameter,1)
    caParameter{k,7} = compose("%g",sParameter.(caParameter{k,1}));
    caParameter{k,8} = isequal(sParameter.(caParameter{k,1}),sS4.sParameter.(caParameter{k,1}), ...
        sS5.sParameter.(caParameter{k,1}),sS6.sParameter.(caParameter{k,1})) && (~isfield(sS1.sParameter,caParameter{k,1}) ...
        || isequal(sParameter.(caParameter{k,1}),sS1.sParameter.(caParameter{k,1}),sS2.sParameter.(caParameter{k,1})));
end

convertvars(cell2table(caParameter(:,[2 7 4 3 5 6 8 1]),'VariableNames', ... %[output:group:8136d4f1] %[output:28de20d2]
    {'Zeichen','Wert','Einheit','Bedeutung','Herkunft','Stufen','gleich','Name'}),@iscell,'string') %[output:group:8136d4f1] %[output:28de20d2]
fMasse = sParameter.PAR_Lng_MasseFzg_f64;            % Fahrzeugmasse m [kg]
fGeschwStart = sParameter.PAR_Lng_GeschwStart_f64;   % Anfangsgeschwindigkeit v_0 [m/s]
ZEIT_ENDE = sS5.afZeit(end);                         % Ende des Leitszenarios wie Projektlauf Stufe 5 [s]

%%
%[text] ## Stufe 0 – Kinematik: Aus der Geschwindigkeit folgen Beschleunigung und Weg
%[text] **Frage:** Wie schnell ändert sich die Geschwindigkeit, und welche Strecke legt das Fahrzeug zurück?
%[text] **Zweck:** Die Kinematik beschreibt Bewegung, ohne nach Kräften zu fragen. Sie macht aus dem vorgegebenen Geschwindigkeitsverlauf $v(t)$ die Beschleunigung $a$ und den Weg $x$ – die Größen, mit denen alle weiteren Stufen rechnen.
%[text] **Eingänge und Parameter:**
%[text] - $v(t)$ Geschwindigkeit \[m/s\]: Vorgabe des Leitszenarios (afGeschw); im Projekt das Sollprofil FTP75 Phase 1
%[text] - $v\_0$, $a\_B$, $t\_0$, $t\_r$: Parameter der Bremsrampe (Tabelle oben)
%[text] - Zeitraster $t$ \[s\]: das des Projektlaufs Stufe 5 (vom Löser gewählt, Schritt höchstens 0,01 s), damit jeder Wert direkt mit dem Simulink-Lauf verglichen werden kann (afZeit) \
%[text] **Physikalisches Modell:** Geschwindigkeit ist die Änderung des Wegs, Beschleunigung die Änderung der Geschwindigkeit: $\\dot{x} = v$, $\\dot{v} = a$. Die Bremsrampe ist eine Beschleunigung, die zwischen $t\_0$ und $t\_0 + t\_r$ linear von 0 auf $-a\_B$ fällt. Mit der Rampenfunktion $u(s) = \\max(s, 0)$ lautet sie $a(t) = -\\frac{a\_B}{t\_r}\\left(u(t - t\_0) - u(t - t\_0 - t\_r)\\right)$. Einmal integriert ($\\int u\\, dt = u^2/2$) ergibt sich die Vorgabe $v(t) = v\_0 - \\frac{a\_B}{2 t\_r}\\left(u(t - t\_0)^2 - u(t - t\_0 - t\_r)^2\\right)$.
%[text] Messdaten und Fahrzyklen liefern $v$ nur an Stützstellen $t\_k$. Das Projekt verbindet sie geradlinig; dann ist die Beschleunigung im Intervall konstant, $a\_k = (v\_{k+1} - v\_k)/(t\_{k+1} - t\_k)$ (Vorwärtsdifferenz), und der Weg ist die Trapezsumme von $x = \\int v\\, dt$.
%[text] **Umsetzung:** BerechneRampe liefert $v(t)$ und die exakte Beschleunigung in geschlossener Form; danach dieselben Befehle wie in simuliereStufe1.m: diff (Vorwärtsdifferenz) und cumtrapz (Trapezregel). Im Simulink-Modell Stufe5\_Laengsdyn3DOF.slx läuft die Rechnung umgekehrt: Subsystem „Bremsrampe a(t)" → Integrator „Geschwindigkeit v" → Integrator „Weg x" (Signale Lng\_Beschl\_f64, Lng\_Geschw\_f64, Lng\_Weg\_f64).
%[text] Namen im Code: $t$ afZeit · $v$ afGeschw · $a\_k$ afBeschl · $a(t)$ exakt afBeschlAna · $x$ afWeg
[afZeit,nIndex] = unique(sS5.afZeit);                         % Zeitraster des Projektlaufs Stufe 5, Schritt <= 0,01 s [s]
[afBeschlAna,afGeschw] = BerechneRampe(afZeit,sParameter);    % exakte Beschleunigung a(t) und Vorgabe v(t) [m/s^2, m/s]

% S0 "Kinematik: v(t) => a, x" -> Vorwaertsdifferenz und Trapezregel wie simuliereStufe1.m
afBeschl = diff(afGeschw) ./ diff(afZeit);                    % Beschleunigung a_k je Intervall [m/s^2]
afWeg = cumtrapz(afZeit,afGeschw);                            % Weg x [m]

figure; tiledlayout(3,1); %[output:5934e5bb]
nexttile; plot(afZeit,afGeschw,'b'); %[output:5934e5bb]
title('Stufe 0: Vorgabe Geschwindigkeit'); xlabel('Zeit t [s]'); ylabel('Geschwindigkeit v [m/s]'); %[output:5934e5bb]
nexttile; stairs(afZeit(1:end - 1),afBeschl,'r'); hold on; plot(afZeit,afBeschlAna,'k--'); hold off %[output:5934e5bb]
title('Stufe 0: Beschleunigung'); xlabel('Zeit t [s]'); ylabel('Beschleunigung a [m/s^2]'); ylim([-9 1]); %[output:5934e5bb]
legend('a_k (Vorwaertsdifferenz)','a(t) exakt','Location','northeast'); %[output:5934e5bb]
nexttile; plot(afZeit,afWeg,'k'); %[output:5934e5bb]
title('Stufe 0: Weg'); xlabel('Zeit t [s]'); ylabel('Weg x [m]'); %[output:5934e5bb]
fontsize(gcf,SCHRIFT_GROESSE,'points'); %[output:5934e5bb]
fprintf('S0 Leitszenario (berechnet): v(%.1f s) = %.2f m/s, x = %.2f m, a_k = %.2f ... %.2f m/s^2\n', ... %[output:group:27acc9be] %[output:3e2898de]
    afZeit(end),afGeschw(end),afWeg(end),min(afBeschl),max(afBeschl)); %[output:group:27acc9be] %[output:3e2898de]
fprintf('S0 Projektlauf FTP75 Phase 1 (gespeichert): Strecke %.1f m, a_k = %.2f ... %.2f m/s^2\n', ... %[output:group:6f40df7b] %[output:03759588]
    sS1.sErgebnis.Strecke_m,sS1.sErgebnis.MinBeschl_m_s2,sS1.sErgebnis.MaxBeschl_m_s2); %[output:group:6f40df7b] %[output:03759588]
%[text] **Ergebnis:** Lesehinweis zur mittleren Abbildung: Die Treppe $a\_k$ liegt auf der exakten Rampe; nur in den Intervallen, die einen Knick enthalten ($t\_0$, $t\_0 + t\_r$), liegt ihr Wert dazwischen, denn $a\_k$ ist der Mittelwert von $a$ über das Intervall. Der Weg wächst zuerst linear, nach Bremsbeginn immer langsamer. Nach 4,5 s fährt das Fahrzeug noch 3,2 m/s und hat 90,08 m zurückgelegt (berechnet). Der Projektlauf FTP75 (Ausgabe) ist ein Stadtzyklus mit höchstens ±1,48 m/s², also weit schwächer als die Bremsung.
%[text] **Übergang:** Stufe 1 übernimmt $a\_k$ und die mittlere Geschwindigkeit $v\_m$ je Intervall; Stufe 4 übernimmt die exakte Beschleunigung $a(t)$.

%%
%[text] ## Stufe 1 – Rückwärtsmodell: Welche Kraft am Rad erzeugt diese Bewegung?
%[text] **Frage:** Welche Längskraft muss am Rad wirken, damit das Fahrzeug genau dem Profil aus Stufe 0 folgt?
%[text] **Zweck:** Das Rückwärtsmodell schließt von der Bewegung auf die Kraft (Kinematik → Kinetik). Es liefert den Antriebs- oder Bremsbedarf $F\_x$ und die Radleistung $P$, ohne eine Differentialgleichung zu lösen.
%[text] **Eingänge und Parameter:**
%[text] - aus Stufe 0: $a\_k$ \[m/s²\] (afBeschl) und $v\_m = (v\_k + v\_{k+1})/2$ \[m/s\], die mittlere Geschwindigkeit je Intervall (afGeschwMitte)
%[text] - Parameter: $m$, $f\_R$, $g$, $c\_w$, $A$, $\\rho$
%[text] - berechnet: Rollwiderstandskraft $F\_R = f\_R\\, m\\, g$ \[N\] (fKraftRoll) und Luftwiderstandskonstante $C = \\frac{1}{2} \\rho\\, c\_w A$ \[kg/m\] (fKonstLuft) \
%[text] **Physikalisches Modell:** Zwei Fahrwiderstände bremsen das Fahrzeug: der **Rollwiderstand** (Verformungsverluste der Reifen, näherungsweise konstant, solange das Rad rollt) und der **Luftwiderstand** $F\_L = C v^2$ (Umströmung, wächst mit dem Quadrat der Geschwindigkeit). Annahmen: Punktmasse, ebene Fahrbahn, kein Wind, keine Drehmassen von Rädern und Antrieb.
%[text] Newton in Längsrichtung: $m\\, a = F\_x - F\_R - F\_L$. Nach der Längskraft aufgelöst und je Intervall mit $v\_m$ ausgewertet: $F\_x = m\\, a\_k + F\_R + C\\, v\_m^2$, wobei $F\_R$ nur bei $v\_m \> 0$ wirkt; Radleistung $P = F\_x\\, v\_m$. $F\_x \> 0$ heißt Antrieb, $F\_x \< 0$ Bremsen. Die Parameter gehen nur über $m$, $F\_R$ und $C$ ein.
%[text] **Umsetzung:** dieselbe Zeile wie in simuliereStufe1.m; Stufe 1 ist im Projekt ein Skript, kein Simulink-Modell. Dieselbe Kraftbilanz steckt im Modell Stufe 2 im Sum-Block „Kraftbilanz", dort nach $a$ aufgelöst.
%[text] Namen im Code: $F\_R$ fKraftRoll · $C$ fKonstLuft · $v\_m$ afGeschwMitte · $F\_x$ afKraftAntr · $P$ afLeistAntr
% S1 "Kraft? v(t) => F_x, P" -> F_x = m a + F_R [v_m > 0] + C v_m^2 je Intervall wie simuliereStufe1.m
fKraftRoll = sParameter.PAR_Lng_BeiwRoll_f64 * fMasse * sParameter.PAR_Lng_BeschlErde_f64;  % Rollwiderstandskraft F_R [N]
fKonstLuft = 0.5 * sParameter.PAR_Lng_DichteLuft_f64 * sParameter.PAR_Lng_BeiwLuft_f64 ...
    * sParameter.PAR_Lng_Stirnfl_f64;                                    % Luftwiderstandskonstante C [kg/m]
afGeschwMitte = (afGeschw(1:end - 1) + afGeschw(2:end)) / 2;            % mittlere Geschwindigkeit v_m je Intervall [m/s]
afKraftAntr = fMasse * afBeschl + fKraftRoll * (afGeschwMitte > 0) + fKonstLuft * afGeschwMitte.^2;  % Laengskraft am Rad F_x [N]
afLeistAntr = afKraftAntr .* afGeschwMitte;                              % Radleistung P [W]

figure; tiledlayout(2,1); %[output:303fbc0c]
nexttile; stairs(afZeit(1:end - 1),[fMasse * afBeschl, fKraftRoll * (afGeschwMitte > 0), fKonstLuft * afGeschwMitte.^2, afKraftAntr] / 1e3); %[output:303fbc0c]
colororder(gca,{'r','g','m','k'}); %[output:303fbc0c]
title('Stufe 1: Laengskraft am Rad und ihre Anteile'); xlabel('Zeit t [s]'); ylabel('Kraft F [kN]'); %[output:303fbc0c]
legend('m a_k (Traegheit)','F_R (Rollwiderstand)','C v_m^2 (Luftwiderstand)','F_x (Summe)','Location','east'); %[output:303fbc0c]
nexttile; stairs(afZeit(1:end - 1),afLeistAntr / 1e3,'k'); %[output:303fbc0c]
title('Stufe 1: Radleistung'); xlabel('Zeit t [s]'); ylabel('Leistung P [kW]'); %[output:303fbc0c]
fontsize(gcf,SCHRIFT_GROESSE,'points'); %[output:303fbc0c]
fprintf('S1 Leitszenario (berechnet): F_x vor Bremsbeginn %.0f N, kleinstes F_x %.0f N, P = %.1f ... %.1f kW\n', ... %[output:group:7c206c05] %[output:04394035]
    afKraftAntr(1),min(afKraftAntr),min(afLeistAntr) / 1e3,max(afLeistAntr) / 1e3); %[output:group:7c206c05] %[output:04394035]
fprintf('S1 Projektlauf FTP75 Phase 1 (gespeichert): F_x,max %.0f N, P_max %.1f kW, Antriebsenergie %.2f kWh/100 km\n', ... %[output:group:3dcf38db] %[output:9d43c88b]
    sS1.sErgebnis.MaxKraft_N,sS1.sErgebnis.MaxLeistung_W / 1e3,sS1.sErgebnis.Verbrauch_kWh_100km); %[output:group:3dcf38db] %[output:9d43c88b]
%[text] **Ergebnis:** Lesehinweis: Vor Bremsbeginn ist $F\_x$ positiv (504 N, berechnet) – um 30 m/s zu halten, muss der Antrieb Roll- und Luftwiderstand ausgleichen. Während der Bremsung ist $F\_x$ fast gleich $m\\, a$; die Bremse muss etwas weniger aufbringen als $m\\, a\_B$ = 12 000 N, weil Roll- und Luftwiderstand mitbremsen (am Laufende −11 849 N). Der Luftanteil nimmt mit sinkender Geschwindigkeit ab. Die Leistung zeigt, wie viel die Bremse je Sekunde aufnimmt; ihr Betrag ist am Rampenende am größten (331,9 kW), weil dort Kraft und Geschwindigkeit zugleich groß sind. Im Projektlauf FTP75 braucht der Antrieb höchstens 2408 N und 32,0 kW (Ausgabe).
%[text] **Übergang:** Stufe 2 übernimmt den Kraftverlauf $F\_x(t)$ als Eingang.

%%
%[text] ## Stufe 2 – Vorwärtsmodell: Aus der Kraft folgt die Bewegung
%[text] **Frage** („Kraft?", Übergang zu Stufe 2): Wie bewegt sich das Fahrzeug, wenn nicht die Bewegung, sondern die Kraft vorgegeben ist?
%[text] **Zweck:** Das Vorwärtsmodell löst die Bewegungsgleichung: Kraft hinein, Bewegung heraus. Erst damit lassen sich Vorgänge berechnen, deren Verlauf man nicht kennt (Ausrollen, später Regelung). Im Leitszenario wird die Kraft aus Stufe 1 eingespeist; dann muss die Bewegung aus Stufe 0 wieder herauskommen.
%[text] **Eingänge und Parameter:**
%[text] - aus Stufe 1: $F\_x(t)$ \[N\] (afKraftAntr), im Intervall konstant
%[text] - Anfangswert $v\_0$; Parameter über $m$, $F\_R$, $C$ \
%[text] **Physikalisches Modell:** Newton, nach der Beschleunigung aufgelöst: $m\\, \\dot{v} = F\_x - F\_R - C\\, v |v|$, wobei $F\_R$ nur bei $v \> 0$ wirkt. $v |v|$ statt $v^2$ hält die Richtung der Luftkraft richtig, falls $v$ negativ würde; im Stand entfällt der Rollwiderstand. Die Gleichung ist nichtlinear und wird im Allgemeinen numerisch gelöst (ode45: Runge-Kutta-Verfahren mit Schrittweitensteuerung).
%[text] Im Sonderfall **Ausrollen** ($F\_x = 0$, $v \> 0$), dem Projektlauf dieser Stufe, gibt es eine exakte Lösung. Aus $m\\, \\dot{v} = -(F\_R + C v^2)$ folgt durch Trennung der Variablen $\\int \\frac{m\\, dv}{F\_R + C v^2} = -\\int dt$. Mit $v\_c = \\sqrt{F\_R/C}$ (Geschwindigkeit, bei der Roll- und Luftwiderstand gleich groß sind) und der Zeitkonstante $T\_c = m/(C v\_c)$ wird daraus $T\_c \\arctan(v/v\_c) = T\_c \\arctan(v\_0/v\_c) - t$, also $v(t) = v\_c \\tan\\left(\\arctan(v\_0/v\_c) - t/T\_c\\right)$; Stillstand nach $t\_{stop} = T\_c \\arctan(v\_0/v\_c)$. Herleitung des Projekts (Gl. (3.2) der Themen-PDF liegt nicht vor).
%[text] **Umsetzung:** ode45 mit dem Zustand $v$ und – für Stufe 3 – den Arbeiten $W\_x$, $W\_R$, $W\_L$. Im Simulink-Modell Stufe2\_Laengsdyn1DOF.slx: Sum „Kraftbilanz" → Gain „Kehrwert Masse" (1/m) → Integrator „Geschwindigkeit v"; Switch „Fahrt v \> 0" schaltet $F\_R$, „Produkt v|v|" und Gain „Luftwiderstand C" bilden $F\_L$. Dort ist $F\_x$ der Constant-Block „Antriebskraft F\_x" = 0 (Ausrollen).
%[text] Namen im Code: $F\_x(t)$ fhKraftAntr · $v$ afGeschwVorw (Signal Lng\_Geschw\_f64) · $v\_c$ fGeschwKrit · $T\_c$ fZeitKrit · exakte Ausroll-Lösung afGeschwAna
% S2 "Kraft? F_x => v(t)" -> m dv/dt = F_x - F_R [v > 0] - C v|v|, Zustaende v, W_x, W_R, W_L
fhKraftAntr = @(fZeit) interp1(afZeit(1:end - 1),afKraftAntr,fZeit,'previous','extrap');  % F_x(t) aus Stufe 1, im Intervall konstant [N]
[~,afZustLng] = ode45(@(fZeit,afZust) [(fhKraftAntr(fZeit) - fKraftRoll * (afZust(1) > 0) - fKonstLuft * afZust(1) * abs(afZust(1))) / fMasse; ...
    fhKraftAntr(fZeit) * afZust(1); fKraftRoll * (afZust(1) > 0) * afZust(1); fKonstLuft * afZust(1)^2 * abs(afZust(1))], ...
    afZeit,[fGeschwStart; 0; 0; 0],odeset('RelTol',1e-10,'AbsTol',1e-8));  % v, W_x, W_R, W_L [m/s, J, J, J]
afGeschwVorw = afZustLng(:,1);                                           % Geschwindigkeit aus dem Vorwaertsmodell v [m/s]

% S2 Sonderfall Ausrollen (Projektlauf): v = v_c tan(atan(v_0/v_c) - t/T_c)
fGeschwKrit = sqrt(fKraftRoll / fKonstLuft);                             % Geschwindigkeit mit F_R = C v^2, v_c [m/s]
fZeitKrit = fMasse / (fKonstLuft * fGeschwKrit);                         % Zeitkonstante der Ausroll-Loesung T_c [s]
afGeschwAna = max(fGeschwKrit * tan(atan(fGeschwStart / fGeschwKrit) - sS2.afZeit / fZeitKrit),0);  % exakte Ausroll-Loesung [m/s]

figure; tiledlayout(3,1); %[output:8d2aa6ed]
nexttile; plot(afZeit,afGeschwVorw,'b',afZeit,afGeschw,'k--'); %[output:8d2aa6ed]
title('Stufe 2: Vorwaertsmodell mit F_x(t) aus Stufe 1'); xlabel('Zeit t [s]'); ylabel('Geschwindigkeit v [m/s]'); %[output:8d2aa6ed]
legend('v aus Stufe 2 (ode45)','v aus Stufe 0 (Vorgabe)','Location','northeast'); %[output:8d2aa6ed]
nexttile; plot(afZeit,afGeschwVorw - afGeschw,'k'); %[output:8d2aa6ed]
title('Stufe 2: Rundlauf Stufe 0 -> 1 -> 2, Differenz'); xlabel('Zeit t [s]'); ylabel('\Deltav [m/s]'); %[output:8d2aa6ed]
nexttile; plot(sS2.afZeit,sS2.afGeschw,'b',sS2.afZeit,afGeschwAna,'k--',sS2.afZeit,sS2.afGeschwRef,'r:', ... %[output:8d2aa6ed]
    sS2.afZeit([1 end]),fGeschwKrit * [1 1],'g'); %[output:8d2aa6ed]
title('Stufe 2, Projektlauf: Ausrollen ab v_0 (F_x = 0)'); xlabel('Zeit t [s]'); ylabel('Geschwindigkeit v [m/s]'); %[output:8d2aa6ed]
legend('Simulink-Modell Stufe 2','exakte Loesung','Referenzblock 1DOF [1]','v_c (F_R = C v^2)','Location','northeast'); %[output:8d2aa6ed]
fontsize(gcf,SCHRIFT_GROESSE,'points'); %[output:8d2aa6ed]
fprintf('S2 Leitszenario (berechnet): max. |v aus Stufe 2 - v aus Stufe 0| = %.1e m/s\n',max(abs(afGeschwVorw - afGeschw))); %[output:0778eeae]
fprintf('S2 Projektlauf Ausrollen (simuliert): Stillstand %.2f s (exakt %.2f s), %.1f m; v_c = %.2f m/s, T_c = %.2f s\n', ... %[output:group:2aa0960a] %[output:421c9d4d]
    sS2.sErgebnis.StoppZeit_s,fZeitKrit * atan(fGeschwStart / fGeschwKrit),sS2.sErgebnis.StoppWeg_m,fGeschwKrit,fZeitKrit); %[output:group:2aa0960a] %[output:421c9d4d]
%[text] **Ergebnis:** Lesehinweis: Oben liegen beide Kurven aufeinander; die Mitte zeigt die Differenz (höchstens 1,4·10⁻⁵ m/s, berechnet). Rückwärts- und Vorwärtsmodell sind zueinander invers – das ist eine Konsistenzprüfung der Umsetzung, keine Prüfung der Physik. Die Physik prüft unten der Projektlauf: Simulink-Modell, exakte Lösung und MathWorks-Referenzblock \[1\] liegen aufeinander; das Fahrzeug steht nach 196,44 s und 2330,0 m (simuliert). Oberhalb von $v\_c$ = 19,28 m/s bremst überwiegend die Luft, darunter der Rollwiderstand; weil $F\_R$ auch bei kleiner Geschwindigkeit voll wirkt, steht das Fahrzeug nach endlicher Zeit.
%[text] **Übergang:** Stufe 3 übernimmt $v$ und die Arbeiten der drei Kräfte (im Modell die Signale $v$, $F\_x$, $F\_R$, $F\_L$).

%%
%[text] ## Stufe 3 – Energiebilanz 1DOF: Ist die Lösung von Stufe 2 richtig?
%[text] **Frage** („machbar?", Übergang zu Stufe 3): Verbucht die Lösung von Stufe 2 die Energie vollständig?
%[text] **Zweck:** Prüfstufe. Was an Bewegungsenergie verschwindet, muss als Arbeit der Kräfte auftauchen. Geht die Bilanz nicht auf, ist die Lösung von Stufe 2 falsch (Vorzeichen, Einheit, Integration).
%[text] **Eingänge und Parameter:**
%[text] - aus Stufe 2: $v$ und die Arbeiten $W\_x$, $W\_R$, $W\_L$ \[J\] (afZustLng)
%[text] - Parameter: $m$, $v\_0$ \
%[text] **Physikalisches Modell:** Fachbegriffe: kinetische Energie $E\_{kin} = \\frac{1}{2} m v^2$; Leistung einer Kraft $P = F\\, v$; Arbeit $W = \\int P\\, dt$. Herleitung: Die Bewegungsgleichung mal $v$ ergibt $m\\, v\\, \\dot{v} = F\_x v - F\_R v - C v^2 |v|$; links steht die Ableitung von $\\frac{1}{2} m v^2$. Von 0 bis $t$ integriert: $E\_{kin} - E\_{kin,0} = W\_x - W\_R - W\_L$. Der **Bilanzrest** $E\_{kin} - E\_{kin,0} - W\_x + W\_R + W\_L$ muss bis auf die Rechengenauigkeit 0 sein; Toleranz des Projekts: RelTol · $E\_{kin,0}$.
%[text] Grenze (Perle ★1): Die Bilanz ist nur die Bewegungsgleichung mal $v$. Sie findet Vorzeichen-, Einheiten- und Integrationsfehler, aber keinen falschen Parameterwert; Rotationsenergie von Rädern und Antrieb fehlt im Modell.
%[text] **Umsetzung:** Im Modell Stufe 2 das Subsystem „Energiebilanz Stufe 3": Produkte „Leistung P\_x/P\_R/P\_L", Integratoren „Arbeit W\_x/W\_R/W\_L", Gain „Kinetische Energie", Sum „Bilanzrest". Im Skript sind die Arbeiten die Zustände 2–4 der ode45-Lösung von Stufe 2 – dieselbe Integration wie im Modell.
%[text] Namen im Code: $E\_{kin}$ afEnergKinFzg · $W\_x$, $W\_R$, $W\_L$ afArbeitAntr, afArbeitRoll, afArbeitLuft (Signale Ene\_ArbeitAntr\_f64 …) · Bilanzrest afEnergRestFzg (Ene\_EnergRest\_f64)
% S3 "machbar? E_kin - E_kin,0 - W_x + W_R + W_L = 0" -> Arbeiten aus den Zustaenden von Stufe 2
afArbeitAntr = afZustLng(:,2);                                           % Arbeit der Laengskraft W_x, beim Bremsen negativ [J]
afArbeitRoll = afZustLng(:,3);                                           % Arbeit des Rollwiderstands W_R [J]
afArbeitLuft = afZustLng(:,4);                                           % Arbeit des Luftwiderstands W_L [J]
afEnergKinFzg = 0.5 * fMasse * afGeschwVorw.^2;                          % kinetische Energie der Laengsbewegung E_kin [J]
afEnergRestFzg = afEnergKinFzg - afEnergKinFzg(1) - afArbeitAntr + afArbeitRoll + afArbeitLuft;  % Bilanzrest [J]

figure; tiledlayout(2,1); %[output:9e14273c]
nexttile; plot(afZeit,[afEnergKinFzg, -afArbeitAntr, afArbeitRoll, afArbeitLuft] / 1e3); colororder(gca,{'b','r','g','m'}); hold on %[output:9e14273c]
plot(afZeit,(afEnergKinFzg - afArbeitAntr + afArbeitRoll + afArbeitLuft) / 1e3,'k--'); hold off %[output:9e14273c]
title('Stufe 3: Energie und Arbeiten'); xlabel('Zeit t [s]'); ylabel('Energie E, Arbeit W [kJ]'); %[output:9e14273c]
legend('E_{kin}','-W_x (Bremse)','W_R','W_L','E_{kin} - W_x + W_R + W_L','Location','east'); %[output:9e14273c]
nexttile; plot(afZeit,afEnergRestFzg,'k'); %[output:9e14273c]
title('Stufe 3: Bilanzrest'); xlabel('Zeit t [s]'); ylabel('Rest [J]'); %[output:9e14273c]
fontsize(gcf,SCHRIFT_GROESSE,'points'); %[output:9e14273c]
fprintf('S3 Leitszenario (berechnet): E_kin,0 = %.0f J, -W_x = %.0f J, W_R = %.0f J, W_L = %.0f J, E_kin(Ende) = %.0f J, Rest %.1e J\n', ... %[output:group:734f68f2] %[output:40db8dd7]
    afEnergKinFzg(1),-afArbeitAntr(end),afArbeitRoll(end),afArbeitLuft(end),afEnergKinFzg(end),max(abs(afEnergRestFzg))); %[output:group:734f68f2] %[output:40db8dd7]
fprintf('S3 Projektlauf Ausrollen (simuliert): W_R = %.0f J, W_L = %.0f J, Rest %.1e J\n', ... %[output:group:87b07c13] %[output:39a2b911]
    sS2.sErgebnis.ArbeitRoll_J,sS2.sErgebnis.ArbeitLuft_J,sS2.sErgebnis.EnergieRest_J); %[output:group:87b07c13] %[output:39a2b911]
%[text] **Ergebnis:** Lesehinweis: Die gestrichelte Summe bleibt waagerecht auf $E\_{kin,0}$ – keine Energie geht verloren oder entsteht. Von $E\_{kin,0}$ = 675 000 J nimmt die Bremse 631 778 J auf ($-W\_x$, berechnet); Rollwiderstand 13 255 J, Luft 22 287 J, 7680 J bleiben als Bewegungsenergie. Vor Bremsbeginn ist $W\_x$ positiv, weil der Antrieb die Fahrwiderstände ausgleicht. Der Rest bleibt unter 10⁻⁵ J (Toleranz 0,675 J). Beim Ausrollen (Projektlauf) teilen sich Roll- und Luftwiderstand die Energie dagegen etwa hälftig (342 857 J zu 332 143 J).
%[text] **Übergang:** Stufe 3 gibt keine neue Größe weiter, sondern gibt die Lösung frei. Ab Stufe 4 geht es nicht mehr um $v$, sondern um die Verteilung der Kräfte auf die Achsen; Eingang ist wieder $a(t)$ aus Stufe 0.

%%
%[text] ## Stufe 4 – Quasistatische Achslasten: Welche Achse trägt wie viel?
%[text] **Frage** („welche Achse?", Übergang zu Stufe 4): Wie verteilt sich das Gewicht beim Bremsen auf Vorder- und Hinterachse, und wann erreicht eine Achse die Haftgrenze?
%[text] **Zweck:** Die Stufen 1–3 kennen nur eine Gesamtkraft. Ein Reifen überträgt aber höchstens $\\mu F\_{z,i}$; dafür braucht man die **Achslasten** $F\_{z,v}$ (vorn) und $F\_{z,h}$ (hinten). **Quasistatisch** heißt: Der Aufbau ist starr und folgt jeder Änderung von $a$ sofort.
%[text] **Eingänge und Parameter:**
%[text] - aus Stufe 0: $a(t)$ \[m/s²\] (afBeschlAna)
%[text] - Parameter: $m$, $g$, $l\_v$, $l\_h$, $h$, $\\mu$
%[text] - berechnet: Radstand $L = l\_v + l\_h$ \[m\] (fRadstand) \
%[text] **Physikalisches Modell:** Annahmen: starrer Aufbau, ebene Fahrbahn, Luftkräfte ohne Moment (Modellgrenze des Projekts: Das fehlende Luftwiderstandsmoment macht bei 30 m/s 72,6 N je Achse aus). Nach d'Alembert wirkt im Schwerpunkt, in der Höhe $h$, die Trägheitskraft $-m a$. Momentengleichgewicht um den Aufstandspunkt der Hinterachse: $F\_{z,v} L = m g\\, l\_h - m a\\, h$. Daraus und aus $F\_{z,v} + F\_{z,h} = m g$:
%[text] $F\_{z,v} = m g\\, l\_h/L - (m h/L)\\, a$, $F\_{z,h} = m g\\, l\_v/L + (m h/L)\\, a$. Beim Bremsen ($a \< 0$) wird die Vorderachse be-, die Hinterachse entlastet, um $m h/L$ je m/s².
%[text] **Haftgrenze:** Der Kraftschlussbeiwert $\\mu$ ist das Verhältnis der höchstens übertragbaren Längskraft zur Radlast. Treibt nur eine Achse an, gilt $m a \\le \\mu F\_{z,i}(a)$; eingesetzt folgen $a\_{max} = \\mu g\\, l\_v/(L - \\mu h)$ für Heck- und $a\_{max} = \\mu g\\, l\_h/(L + \\mu h)$ für Frontantrieb. Beim Bremsen gilt dasselbe je Achse: Blockieren die Hinterräder zuerst, wird das Fahrzeug instabil \[4, Abschn. 9.5\]; die Entlastung der Hinterachse macht das wahrscheinlicher, wenn die Bremskraftverteilung nicht angepasst ist \[Interpretation\].
%[text] **Umsetzung:** wie simuliereStufe4.m (Skript). Dieselbe Gleichung ist im Modell Stufe 5 der Grenzfall (Subsystem „Achslasten F\_z,i" mit den Konstanten „statisch vorn/hinten" = $F\_{z,i0}$). Referenz im Projekt: Der Block Vehicle Body 1DOF Longitudinal \[1\] berechnet die Achslasten ebenso quasistatisch.
%[text] Namen im Code: $L$ fRadstand · $F\_{z,v0}$, $F\_{z,h0}$ fLastVoStat, fLastHiStat · $m h/L$ fLastJeBeschl · $F\_{z,v}$, $F\_{z,h}$ afLastVoS4, afLastHiS4 · $a\_{max}$ fBeschlHaftHi, fBeschlHaftVo
% S4 "welche Achse? F_z,i(a), Haftgrenze" -> Momentengleichgewicht um die Aufstandspunkte wie simuliereStufe4.m
fRadstand = sParameter.PAR_Ach_AbstVo_f64 + sParameter.PAR_Ach_AbstHi_f64;  % Radstand L [m]
fLastVoStat = fMasse * sParameter.PAR_Lng_BeschlErde_f64 * sParameter.PAR_Ach_AbstHi_f64 / fRadstand;  % F_z,v0 = m g l_h/L [N]
fLastHiStat = fMasse * sParameter.PAR_Lng_BeschlErde_f64 * sParameter.PAR_Ach_AbstVo_f64 / fRadstand;  % F_z,h0 = m g l_v/L [N]
fLastJeBeschl = fMasse * sParameter.PAR_Ach_SchwerpHoehe_f64 / fRadstand;  % Verlagerung je Beschleunigung m h/L [kg]
fBeschlHaftHi = sParameter.PAR_Ach_BeiwHaft_f64 * sParameter.PAR_Lng_BeschlErde_f64 * sParameter.PAR_Ach_AbstVo_f64 ...
    / (fRadstand - sParameter.PAR_Ach_BeiwHaft_f64 * sParameter.PAR_Ach_SchwerpHoehe_f64);  % a_max Heckantrieb [m/s^2]
fBeschlHaftVo = sParameter.PAR_Ach_BeiwHaft_f64 * sParameter.PAR_Lng_BeschlErde_f64 * sParameter.PAR_Ach_AbstHi_f64 ...
    / (fRadstand + sParameter.PAR_Ach_BeiwHaft_f64 * sParameter.PAR_Ach_SchwerpHoehe_f64);  % a_max Frontantrieb [m/s^2]
afLastVoS4 = fLastVoStat - fLastJeBeschl * afBeschlAna;                 % Achslast vorn F_z,v nach Stufe 4 [N]
afLastHiS4 = fLastHiStat + fLastJeBeschl * afBeschlAna;                 % Achslast hinten F_z,h nach Stufe 4 [N]

figure; %[output:879b98dc]
plot(afZeit,afLastVoS4,'b',afZeit,afLastHiS4,'r'); %[output:879b98dc]
title('Stufe 4: Achslasten bei der Bremsrampe (quasistatisch)'); xlabel('Zeit t [s]'); ylabel('Achslast F_{z,i} [N]'); %[output:879b98dc]
legend('F_{z,v} (vorn)','F_{z,h} (hinten)','Location','east'); %[output:879b98dc]
fontsize(gcf,SCHRIFT_GROESSE,'points'); %[output:879b98dc]
fprintf('S4 Leitszenario (berechnet): F_z,v0 = %.1f N, F_z,h0 = %.1f N, Verlagerung %.1f N je m/s^2, F_z,h,min = %.1f N, F_z,v,max = %.1f N\n', ... %[output:group:36f22dcb] %[output:82216253]
    fLastVoStat,fLastHiStat,fLastJeBeschl,min(afLastHiS4),max(afLastVoS4)); %[output:group:36f22dcb] %[output:82216253]
fprintf('S4 Haftgrenze (berechnet, mu = %.1f): a_max Heckantrieb %.3f m/s^2, Frontantrieb %.3f m/s^2\n', ... %[output:group:5084aedf] %[output:8f008a55]
    sParameter.PAR_Ach_BeiwHaft_f64,fBeschlHaftHi,fBeschlHaftVo); %[output:group:5084aedf] %[output:8f008a55]
fprintf('S4 Projektlauf (gespeichert): Referenzblock 1DOF [1] max. Abweichung %.1e N (Toleranz %d N)\n',sS4.sErgebnis.AbwReferenz_N,TOL_LAST); %[output:9d53d6ca]
%[text] **Ergebnis:** Lesehinweis: Die Achslasten folgen der Rampe ohne Verzögerung und ohne Überschwingen – das ist die Annahme „starrer Aufbau", kein Ergebnis. Die Summe beider Lasten bleibt $m g$. Statisch tragen die Achsen 8175,0 N und 6540,0 N; je m/s² wandern 305,6 N nach vorn. Die Hinterachse sinkt beim Bremsen mit 8 m/s² auf 4095,6 N, verliert also mehr als ein Drittel ihrer statischen Last (berechnet). Beim Anfahren ist es umgekehrt: Der Frontantrieb erreicht die Haftgrenze zuerst (4,528 gegen 5,475 m/s² bei Heckantrieb), weil seine Achse entlastet wird.
%[text] **Übergang:** Stufe 5 übernimmt $a(t)$ als Anregung, über das Nickmoment $M\_y = -m a h$, und $F\_{z,i0}$ als Ruhelage. Stufe 4 ist ihr Grenzfall für langsame Änderungen.

%%
%[text] ## Stufe 5 – 3DOF: Der gefederte Aufbau taucht ein, nickt und schwingt nach
%[text] **Frage** („zeitlich?", Übergang zu Stufe 5): Folgen die Achslasten der Verzögerung sofort, oder braucht der gefederte Aufbau Zeit?
%[text] **Zweck:** Ein realer Aufbau steht auf Federn und Dämpfern. Beim Bremsen nickt er nach vorn und schwingt nach; die Achslasten folgen nicht sofort. Stufe 5 fügt die Freiheitsgrade **Hub** $z$ (Vertikalbewegung des Schwerpunkts) und **Nickwinkel** $\\theta$ (Drehung um die Querachse) hinzu; mit $x$ sind das drei Freiheitsgrade (3DOF).
%[text] **Eingänge und Parameter:**
%[text] - aus Stufe 0: $a(t)$ → Nickmoment $M\_y = -m a h$ \[N m\]
%[text] - aus Stufe 4: statische Achslasten $F\_{z,v0}$, $F\_{z,h0}$ \[N\] (Ruhelage)
%[text] - Parameter: $k\_v$, $k\_h$ \[N/m\], $c\_v$, $c\_h$ \[N s/m\] (je Achse), $I$ \[kg m²\], $l\_v$, $l\_h$, $h$, $m$ \
%[text] **Physikalisches Modell:** Annahmen des Projekts: linear und kleine Winkel; $z$ nach unten, $\\theta$ mit dem Bug nach unten positiv; $z$ und $\\theta$ ab der statischen Ruhelage, das Gewicht steckt in $F\_{z,i0}$; keine ungefederten Massen und Reifenfedern; die Längskräfte greifen am Boden an, $h$ unter dem Schwerpunkt, und erzeugen das Nickmoment $M\_y = -m a h$; kein Schwerkraftmoment $m g h \\theta$ und kein Bremsnickausgleich der Achskinematik \[4, Abschn. 14.9; Abschnittsnummer am Buch zu prüfen\]. Der Referenzblock 3DOF \[2\] enthält beides anders und dient deshalb nur als Modellvergleich.
%[text] Einfederung an den Achsen: $z\_v = z + l\_v \\theta$, $z\_h = z - l\_h \\theta$; Kraftänderung je Achse $\\Delta F\_{z,i} = k\_i z\_i + c\_i \\dot{z}\_i$. Newton für den Hub und Drallsatz für das Nicken:
%[text] $m \\ddot{z} = -\\Delta F\_{z,v} - \\Delta F\_{z,h}$, $I \\ddot{\\theta} = -l\_v \\Delta F\_{z,v} + l\_h \\Delta F\_{z,h} + M\_y$.
%[text] Mit $q = (z, \\theta)^T$ in Matrixform: $\\mathbf{M} \\ddot{q} + D \\dot{q} + K q = (0, M\_y)^T$ mit der Massenmatrix $\\mathbf{M} = \\mathrm{diag}(m, I)$, der Steifigkeitsmatrix $K$ mit $K\_{11} = k\_v + k\_h$, $K\_{12} = K\_{21} = k\_v l\_v - k\_h l\_h$, $K\_{22} = k\_v l\_v^2 + k\_h l\_h^2$ und der Dämpfungsmatrix $D$ ebenso mit $c\_i$. Achslasten: $F\_{z,i} = F\_{z,i0} + \\Delta F\_{z,i}$.
%[text] **Eigenwertproblem** (Perle ★2): Ungedämpft führt der Ansatz $q = \\hat{q} e^{i \\omega t}$ auf $(K - \\omega^2 \\mathbf{M}) \\hat{q} = 0$; die zwei Lösungen sind die Eigenfrequenzen $f = \\omega/(2\\pi)$. Weil $k\_v l\_v \\ne k\_h l\_h$, sind Hub und Nicken gekoppelt. Die Nickperiode $T\_N = 1/f\_2$ ist die Zeitskala, an der Stufe 7 die Gültigkeit von Stufe 4 misst. **Grenzfall Stufe 4:** Bei konstantem $a$ und abgeklungener Schwingung gilt $K q = (0, M\_y)^T$; daraus folgt genau die Verlagerung von Stufe 4. Belege für die Bausteine: Einmassenschwinger \[4, Abschn. 11.1\], Hub- und Nickfrequenz \[4, Abschn. 14.8\]; die Gesamtform ist eine Herleitung des Projekts (Gl. (3.5) der Themen-PDF liegt nicht vor).
%[text] **Umsetzung:** ode45 auf den Zustand $(z, \\theta, \\dot{z}, \\dot{\\theta})$, erweitert um die Arbeiten $W\_M$, $W\_D$ für Stufe 6; Eigenfrequenzen mit eig(K, M). Im Simulink-Modell Stufe5\_Laengsdyn3DOF.slx: Gain „Nickmoment -m h"; Subsystem „Aufbau Hub und Nicken" (Sum „Kraftbilanz Hub" und „Momentbilanz Nicken", Gains „Kehrwert Masse" und „Kehrwert I", Integratoren „Hubgeschwindigkeit", „Hub z", „Nickgeschwindigkeit", „Nickwinkel theta"); Subsystem „Federung" (Einfederung, Federn $k\_i$, Dämpfer $c\_i$); Subsystem „Achslasten F\_z,i".
%[text] Namen im Code: $\\mathbf{M}$, $D$, $K$ afMasseMat, afDaempfMat, afFederMat · $M\_y$ fhMoment (Signal Auf\_MomentBrems\_f64) · $z$, $\\theta$, $\\dot{z}$, $\\dot{\\theta}$ Spalten 1–4 von afZustand (Auf\_Hub\_f64, Auf\_Nick\_f64, Auf\_GeschwHub\_f64, Auf\_GeschwNick\_f64) · $F\_{z,v}$, $F\_{z,h}$ afLastVo, afLastHi (Ach\_LastVo\_f64, Ach\_LastHi\_f64) · $f$ afFrequEig
% S5 "zeitlich? M q'' + D q' + K q = (0, -m a h)" -> Matrizen, Eigenwertproblem, ode45 wie simuliereStufe5.m und simuliereStufe6.m
afHebel = [sParameter.PAR_Ach_AbstVo_f64; -sParameter.PAR_Ach_AbstHi_f64];      % Hebel l_v, -l_h der Einfederung [m]
afFeder = [sParameter.PAR_Auf_FederVo_f64; sParameter.PAR_Auf_FederHi_f64];     % k_v, k_h [N/m]
afDaempf = [sParameter.PAR_Auf_DaempfVo_f64; sParameter.PAR_Auf_DaempfHi_f64];  % c_v, c_h [N s/m]
afMasseMat = diag([fMasse, sParameter.PAR_Auf_TraeghNick_f64]);                 % Massenmatrix M [kg, kg m^2]
afFederMat = [sum(afFeder), afFeder' * afHebel; afFeder' * afHebel, afFeder' * afHebel.^2];       % Steifigkeitsmatrix K [N/m, N, N m]
afDaempfMat = [sum(afDaempf), afDaempf' * afHebel; afDaempf' * afHebel, afDaempf' * afHebel.^2];  % Daempfungsmatrix D [N s/m, N s, N m s]
afFrequEig = sort(sqrt(eig(afFederMat,afMasseMat))) / (2 * pi);                % Eigenfrequenzen ungedaempft [Hz]
fhMoment = @(fZeit) -fMasse * sParameter.PAR_Ach_SchwerpHoehe_f64 * BerechneRampe(fZeit,sParameter);  % Nickmoment M_y = -m a h [N m]
fhAbleitung = @(fZeit,afZust) [afZust(3:4); afMasseMat \ ([0; fhMoment(fZeit)] - afFederMat * afZust(1:2) - afDaempfMat * afZust(3:4)); ...
    fhMoment(fZeit) * afZust(4); afZust(3:4)' * afDaempfMat * afZust(3:4)];  % Zustandsableitung [m/s, rad/s, m/s^2, rad/s^2, W, W]
sLinear = ode45(fhAbleitung,[0 ZEIT_ENDE],zeros(6,1),odeset('RelTol',1e-10,'AbsTol',1e-12));  % Loesung ab Ruhelage [struct]
afZustand = deval(sLinear,afZeit)';                                     % z, theta, dz/dt, dtheta/dt, W_M, W_D [m, rad, m/s, rad/s, J, J]
afLastVo = fLastVoStat + afFeder(1) * (afZustand(:,1:2) * [1; afHebel(1)]) + afDaempf(1) * (afZustand(:,3:4) * [1; afHebel(1)]);  % F_z,v [N]
afLastHi = fLastHiStat + afFeder(2) * (afZustand(:,1:2) * [1; afHebel(2)]) + afDaempf(2) * (afZustand(:,3:4) * [1; afHebel(2)]);  % F_z,h [N]
afLageStat = afFederMat \ [0; fMasse * sParameter.PAR_Ach_BeschlBrems_f64 * sParameter.PAR_Ach_SchwerpHoehe_f64];  % Grenzfall: z, theta stationaer [m, rad]

figure; tiledlayout(3,1); %[output:32a6e0c2]
nexttile; plot(afZeit,1e3 * afZustand(:,1),'g'); %[output:32a6e0c2]
title('Stufe 5: Hub des Schwerpunkts'); xlabel('Zeit t [s]'); ylabel('Hub z [mm]'); %[output:32a6e0c2]
nexttile; plot(afZeit,1e3 * afZustand(:,2),'m'); %[output:32a6e0c2]
title('Stufe 5: Nickwinkel (Bug nach unten positiv)'); xlabel('Zeit t [s]'); ylabel('Nickwinkel \theta [mrad]'); %[output:32a6e0c2]
nexttile; plot(afZeit,afLastVo,'b',afZeit,afLastVoS4,'b--',afZeit,afLastHi,'r',afZeit,afLastHiS4,'r--'); %[output:32a6e0c2]
title('Stufe 5 gegen Stufe 4: Achslasten'); xlabel('Zeit t [s]'); ylabel('Achslast F_{z,i} [N]'); %[output:32a6e0c2]
legend('F_{z,v} Stufe 5','F_{z,v} Stufe 4','F_{z,h} Stufe 5','F_{z,h} Stufe 4','Location','east'); %[output:32a6e0c2]
fontsize(gcf,SCHRIFT_GROESSE,'points'); %[output:32a6e0c2]
fprintf('S5 Eigenwerte (berechnet): f = %.4f / %.4f Hz, T_N = %.4f s; stationaer z = %.2f mm (nach unten), theta = %.4f rad\n', ... %[output:group:3989da3c] %[output:31f31856]
    afFrequEig,1 / afFrequEig(2),1e3 * afLageStat(1),afLageStat(2)); %[output:group:3989da3c] %[output:31f31856]
fprintf('S5 Leitszenario (berechnet): F_z,h,min = %.1f N (Stufe 4: %.1f N), F_z,v,max = %.1f N bei %.2f s (Stufe 4: %.1f N)\n', ... %[output:group:98a59c15] %[output:04584689]
    min(afLastHi),min(afLastHiS4),max(afLastVo),afZeit(afLastVo == max(afLastVo)),max(afLastVoS4)); %[output:group:98a59c15] %[output:04584689]
fprintf('S5 Projektlauf (gespeichert): FFT ungedaempft f = %.4f / %.4f Hz; Referenzblock 3DOF [2] max. %.0f N (Modellvergleich)\n', ... %[output:group:18fa6007] %[output:59c2c39f]
    sAusschw.afFrequMess,sS5.sErgebnis.AbwReferenz_N); %[output:group:18fa6007] %[output:59c2c39f]
%[text] **Ergebnis:** Lesehinweis: Beim Bremsen taucht der Aufbau ein, und der Bug senkt sich; nach dem Rampenende schwingt er über die stationäre Lage hinaus und klingt mit der Dämpfung ab. In der unteren Abbildung bleibt die Vorderachse am Rampenende zunächst hinter Stufe 4 zurück und schwingt dann über (11 436 N bei 1,50 s gegen 10 619 N). Die Hinterachse fällt kurzzeitig auf 3393,2 N statt 4095,6 N: Die Haftgrenze ist dynamisch früher erreicht, als Stufe 4 vorhersagt. Am Laufende nähern sich beide Stufen an (Grenzfall). Die Eigenfrequenzen 1,2474 und 1,3430 Hz ergeben die Nickperiode $T\_N$ = 0,7446 s (berechnet); die FFT des ungedämpften Projektlaufs trifft sie innerhalb der halben Frequenzauflösung.
%[text] **Übergang:** Stufe 6 übernimmt $z$, $\\theta$, $\\dot{z}$, $\\dot{\\theta}$ und $M\_y$; im Skript zusätzlich die Zustände $W\_M$ und $W\_D$.

%%
%[text] ## Stufe 6 – Energiebilanz 3DOF: Verbucht das Aufbaumodell die Energie richtig?
%[text] **Frage:** Ist die Lösung von Stufe 5 richtig – und warum prüft die Bilanz hier schärfer als in Stufe 3?
%[text] **Zweck:** Prüfstufe für Stufe 5. Mit zwei gekoppelten Speichern (Federn und bewegte Masse) und den Dämpfern deckt die Bilanz Kopplungsfehler auf, die beim Blick auf eine einzelne Gleichung nicht auffallen (Perle ★1).
%[text] **Eingänge und Parameter:**
%[text] - aus Stufe 5: $z$, $\\theta$, $\\dot{z}$, $\\dot{\\theta}$ sowie $W\_M$, $W\_D$ (afZustand)
%[text] - Parameter: $k\_i$, $m$, $I$, $l\_v$, $l\_h$ \
%[text] **Physikalisches Modell:** kinetische Energie des Aufbaus $E\_{kin,A} = \\frac{1}{2} m \\dot{z}^2 + \\frac{1}{2} I \\dot{\\theta}^2$; Federenergie $E\_{Feder} = \\frac{1}{2} k\_v z\_v^2 + \\frac{1}{2} k\_h z\_h^2$; Dämpferarbeit $W\_D = \\int (c\_v \\dot{z}\_v^2 + c\_h \\dot{z}\_h^2)\\, dt$ (in Wärme umgesetzt); Arbeit des Nickmoments $W\_M = \\int M\_y \\dot{\\theta}\\, dt$ (zugeführt). Herleitung: Die Bewegungsgleichung von links mit $\\dot{q}^T$ multipliziert ergibt $\\frac{d}{dt}\\left(\\frac{1}{2} \\dot{q}^T \\mathbf{M} \\dot{q} + \\frac{1}{2} q^T K q\\right) = -\\dot{q}^T D \\dot{q} + M\_y \\dot{\\theta}$; integriert: $E\_{kin,A} + E\_{Feder} + W\_D - W\_M = 0$. Toleranz des Projekts: RelTol · größte gespeicherte Energie.
%[text] **Umsetzung:** Im Modell Stufe 5 das Subsystem „Energiebilanz Stufe 6": Gains „Hub 0.5 m", „Nicken 0.5 I", „Feder 0.5 k\_v/k\_h", Produkte der Quadrate, Integratoren „Arbeit W\_D" und „Arbeit W\_M", Sum „Bilanzrest". Im Skript sind $W\_M$ und $W\_D$ die Zustände 5 und 6 der ode45-Lösung von Stufe 5.
%[text] Namen im Code: $E\_{kin,A}$ afEnergKin (Ene\_EnergKin\_f64) · $E\_{Feder}$ afEnergFeder (Ene\_EnergFeder\_f64) · $W\_D$ afArbeitDaempf · $W\_M$ afArbeitMoment · Bilanzrest afEnergRest (Ene\_EnergRest\_f64)
% S6 "Bilanz E_kin,A + E_Feder + W_D - W_M = 0" -> Energien aus den Zustaenden von Stufe 5 wie simuliereStufe6.m
afEnergKin = 0.5 * fMasse * afZustand(:,3).^2 + 0.5 * sParameter.PAR_Auf_TraeghNick_f64 * afZustand(:,4).^2;  % kinetische Energie Hub und Nicken E_kin,A [J]
afEnergFeder = 0.5 * (afZustand(:,1:2) * [1 1; afHebel']).^2 * afFeder;  % Federenergie mit z_v, z_h [J]
afArbeitMoment = afZustand(:,5);                                         % Arbeit des Nickmoments W_M [J]
afArbeitDaempf = afZustand(:,6);                                         % Daempferarbeit W_D [J]
afEnergRest = afEnergKin + afEnergFeder + afArbeitDaempf - afArbeitMoment;  % Bilanzrest [J]

figure; tiledlayout(2,1); %[output:7e6e2d67]
nexttile; plot(afZeit,afEnergKin,'b',afZeit,afEnergFeder,'g',afZeit,afArbeitDaempf,'r',afZeit,afArbeitMoment,'k', ... %[output:7e6e2d67]
    afZeit,afEnergKin + afEnergFeder + afArbeitDaempf,'m--'); %[output:7e6e2d67]
title('Stufe 6: Energie des Aufbaus'); xlabel('Zeit t [s]'); ylabel('Energie E, Arbeit W [J]'); %[output:7e6e2d67]
legend('E_{kin,A}','E_{Feder}','W_D','W_M','E_{kin,A} + E_{Feder} + W_D','Location','east'); %[output:7e6e2d67]
nexttile; plot(afZeit,afEnergRest,'k'); %[output:7e6e2d67]
title('Stufe 6: Bilanzrest'); xlabel('Zeit t [s]'); ylabel('Rest [J]'); %[output:7e6e2d67]
fontsize(gcf,SCHRIFT_GROESSE,'points'); %[output:7e6e2d67]
fprintf('S6 Leitszenario (berechnet): Ende %.1f s: E_Feder = %.2f J (stationaer %.2f J), W_M = %.2f J, W_D = %.2f J, Rest %.1e J\n', ... %[output:group:17d77c07] %[output:82aa86d6]
    afZeit(end),afEnergFeder(end),0.5 * afLageStat' * afFederMat * afLageStat,afArbeitMoment(end),afArbeitDaempf(end),max(abs(afEnergRest))); %[output:group:17d77c07] %[output:82aa86d6]
fprintf('S6 Projektlauf (gespeichert): Fehlerprobe l_v x 1,1 nur in der Federung: Rest %.2f J (Toleranz %.1e J)\n', ... %[output:group:7f5e772d] %[output:0ff94e5f]
    sS6.sErgebnis.MaxRestFehler_J,sS6.sErgebnis.Toleranz_J); %[output:group:7f5e772d] %[output:0ff94e5f]
%[text] **Ergebnis:** Lesehinweis: Die gestrichelte Summe liegt auf $W\_M$. Von der Arbeit, die das Nickmoment zuführt, bleibt ein Teil als Federenergie in der neuen Ruhelage; der Rest wird im Dämpfer zu Wärme. Am Ende (4,5 s): $W\_M$ = 212,30 J, davon 126,13 J in den Federn (stationär 126,15 J) und 86,17 J im Dämpfer (berechnet). Die Bewegungsenergie des Aufbaus ist nur während des Einschwingens nennenswert. Die Energien des Aufbaus liegen bei rund 200 J, die Bremsarbeit (Stufe 3) bei über 600 000 J – energetisch ist der Aufbau vernachlässigbar, für die Achslasten nicht (Stufe 5).
%[text] Schärfe der Bilanz: Im Projekt ergab eine absichtlich falsche Kopplung ($l\_v$ × 1,1 nur in der Federung) einen Rest von 8,47 J, gut vier Größenordnungen über der Toleranz von 3,9·10⁻⁴ J (gespeichert). In Stufe 3 bliebe ein falscher Parameterwert unentdeckt.
%[text] **Übergang:** Ende der Kette in diesem Skript. Stufe 7 fragt, wann Stufe 4 genügt (Abschnitt „Grenzen und Ausblick").

%%
%[text] ## Prüfungen auf einen Blick
%[text] Art: **Rechenkontrolle** = Identität, prüft nur die Umsetzung; **Projektlauf** = Nachbildung gegen eine gespeicherte Ergebnisdatei; **Physik** = exakte Lösung, Bilanz oder Grenzfall. Toleranzen nach dem Projekt: Kräfte 1 N, Geschwindigkeit 10 · RelTol · $v\_0$, Energie RelTol · größte Energie; Rechenkontrollen wie simuliereStufe1.m. Zeile „FFT gegen eig": Abweichung und Toleranz gespeichert, nicht nachgerechnet.
caPruefung = { ...
    'P', 'Parametersatz in allen Projektlaeufen gleich (Anzahl Abweichungen)', 'Projektlauf', sum(~[caParameter{:,8}]), 0, '-'; ...
    '0', 'Rueckintegration a_k -> v', 'Rechenkontrolle', max(abs(afGeschw(1) + [0; cumsum(afBeschl .* diff(afZeit))] - afGeschw)), 1e-9, 'm/s'; ...
    '0', 'v gegen Modell Stufe 5 (Lng_Geschw_f64)', 'Projektlauf', max(abs(afGeschw - sS5.afGeschw(nIndex))), 10 * sS5.sSolver.RelTol * fGeschwStart, 'm/s'; ...
    '0', 'x gegen Modell Stufe 5 (Lng_Weg_f64)', 'Projektlauf', max(abs(afWeg - sS5.afWeg(nIndex))), 10 * sS5.sSolver.RelTol * max(afWeg), 'm'; ...
    '0', 'FTP75: a_k nachgerechnet gegen Stufe1_FTP75.mat', 'Projektlauf', max(abs(diff(sS1.afGeschw) ./ diff(sS1.afZeit) - sS1.afBeschl)), 1e-9, 'm/s^2'; ...
    '1', 'Beschleunigungsarbeit gegen Delta E_kin', 'Rechenkontrolle', abs(sum(fMasse * afBeschl .* afGeschwMitte .* diff(afZeit)) ...
        - 0.5 * fMasse * (afGeschw(end)^2 - afGeschw(1)^2)), 1e-3, 'J'; ...
    '1', 'FTP75: F_x nachgerechnet gegen Stufe1_FTP75.mat', 'Projektlauf', max(abs(fMasse * diff(sS1.afGeschw) ./ diff(sS1.afZeit) ...
        + fKraftRoll * ((sS1.afGeschw(1:end - 1) + sS1.afGeschw(2:end)) > 0) ...
        + fKonstLuft * ((sS1.afGeschw(1:end - 1) + sS1.afGeschw(2:end)) / 2).^2 - sS1.afKraft)), TOL_LAST, 'N'; ...
    '2', 'Rundlauf: v aus Stufe 2 gegen v aus Stufe 0', 'Rechenkontrolle', max(abs(afGeschwVorw - afGeschw)), 10 * sS2.sSolver.RelTol * fGeschwStart, 'm/s'; ...
    '2', 'Ausrollen: exakte Loesung gegen Simulink-Lauf', 'Physik', max(abs(afGeschwAna - sS2.afGeschw)), 10 * sS2.sSolver.RelTol * fGeschwStart, 'm/s'; ...
    '3', 'Bilanzrest Leitszenario', 'Physik', max(abs(afEnergRestFzg)), sS2.sSolver.RelTol * afEnergKinFzg(1), 'J'; ...
    '4', 'statisch: F_z,v0 + F_z,h0 = m g', 'Physik', abs(fLastVoStat + fLastHiStat - fMasse * sParameter.PAR_Lng_BeschlErde_f64), TOL_LAST, 'N'; ...
    '4', 'F_z,v0, F_z,h0, m h/L, F_z,h,min gegen Stufe4_Bremsrampe.mat', 'Projektlauf', max(abs([fLastVoStat, fLastHiStat, fLastJeBeschl, min(afLastHiS4)] ...
        - [sS4.sErgebnis.LastVoStat_N, sS4.sErgebnis.LastHiStat_N, sS4.sErgebnis.LastJeBeschl_kg, sS4.sErgebnis.LastHiMin_N])), TOL_LAST, 'N'; ...
    '4', 'a_max gegen Stufe4_Bremsrampe.mat', 'Projektlauf', max(abs([fBeschlHaftHi, fBeschlHaftVo] ...
        - [sS4.sErgebnis.BeschlHaftHi_m_s2, sS4.sErgebnis.BeschlHaftVo_m_s2])), 1e-9, 'm/s^2'; ...
    '5', 'F_z,v, F_z,h gegen Modell Stufe 5 (Ach_Last...)', 'Projektlauf', max(abs([afLastVo - sS5.afLastVo(nIndex); afLastHi - sS5.afLastHi(nIndex)])), TOL_LAST, 'N'; ...
    '5', 'Grenzfall Stufe 4 stationaer (K q = (0, m a_B h))', 'Physik', max(abs(afFeder .* ([1, afHebel(1); 1, afHebel(2)] * afLageStat) ...
        - [1; -1] * fLastJeBeschl * sParameter.PAR_Ach_BeschlBrems_f64)), TOL_LAST, 'N'; ...
    '5', 'Eigenfrequenzen gegen Stufe5_Ausschwingen.mat', 'Projektlauf', max(abs(afFrequEig - sAusschw.afFrequEig)), 1e-9, 'Hz'; ...
    '5', 'FFT gegen eig (gespeichert)', 'Physik', max(abs(sAusschw.afFrequMess - sAusschw.afFrequEig)), sAusschw.afFrequ(2) / 2, 'Hz'; ...
    '6', 'Bilanzrest Leitszenario', 'Physik', max(abs(afEnergRest)), sS6.sErgebnis.Toleranz_J, 'J'; ...
    '6', 'E_Feder, W_M, W_D am Ende gegen Stufe6_Energiebilanz.mat', 'Projektlauf', max(abs([afEnergFeder(end), afArbeitMoment(end), afArbeitDaempf(end)] ...
        - [sS6.sErgebnis.EnergFederEnde_J, sS6.sErgebnis.ArbeitMomentEnde_J, sS6.sErgebnis.ArbeitDaempfEnde_J])), sS6.sErgebnis.Toleranz_J, 'J'};  % Stufe, Pruefung, Art, Abweichung, Toleranz, Einheit [-]
caPruefung(:,7) = num2cell([caPruefung{:,4}]' <= [caPruefung{:,5}]');  % Abweichung innerhalb der Toleranz [Wahrheitswert]
convertvars(cell2table(caPruefung,'VariableNames',{'Stufe','Pruefung','Art','Abweichung','Toleranz','Einheit','bestanden'}),@iscell,'string') %[output:061e0a82]
%[text] Nicht nachgebildet, nur als gespeicherte Werte genannt: Referenzblöcke 1DOF \[1\] (Stufen 2 und 4) und 3DOF \[2\] (Stufe 5, Modellvergleich ohne Bestehen), FFT des ungedämpften Laufs (Stufe 5) und die Fehlerprobe (Stufe 6).

%%
%[text] ## Grenzen und Ausblick: Wann reicht welche Stufe?
%[text] - **Längsbewegung:** Für $v(t)$, Energie und Verbrauch genügen die Stufen 1 und 2. Hub und Nicken wirken im Modell nicht auf die Längsbewegung zurück; ihre Energie ist gegenüber der Bremsarbeit vernachlässigbar (Stufe 6).
%[text] - **Achslasten:** Stufe 4 genügt, wenn sich $a$ langsam gegenüber der Nickperiode ändert. Stufe 7 des Projekts (nicht Teil dieses Skripts) misst das mit der Kennzahl $\\Pi = t\_r/T\_N$; im Leitszenario ist $\\Pi \\approx$ 0,40, und Stufe 4 unterschätzt die Entlastung der Hinterachse um 28,7 % der Verlagerung $m a\_B h/L$ (10\_SEMINAR.md, Abschnitt 9). Leitsatz: Ein Modell reicht nicht mehr, wenn eine Zeitskala der Anregung die Zeitskala einer vernachlässigten Dynamik erreicht.
%[text] - **Nicht modelliert:** Rad-Schlupf (Ausblick der Themen-PDF), ungefederte Massen, Achskinematik, Rotationsenergie, Luftwiderstandsmoment. Ein Antiblockiersystem regelt vermutlich auf der Zeitskala von $T\_N$; dann reicht auch Stufe 5 nicht mehr \[ungeprüft\].
%[text] - Alle Werte gelten nur für den Parametersatz oben; Federn, Dämpfer, $I$, $t\_r$ und $a\_B$ sind Annahmen. \
%[text] **Quellen**
%[text] \[1\] MathWorks: Vehicle Body 1DOF Longitudinal, https://www.mathworks.com/help/vdynblks/ref/vehiclebody1doflongitudinal.html, abgerufen 12.11.2026.
%[text] \[2\] MathWorks: Vehicle Body 3DOF Longitudinal, https://www.mathworks.com/help/vdynblks/ref/vehiclebody3doflongitudinal.html, abgerufen 12.11.2026.
%[text] \[3\] MathWorks: Drive Cycle Source, https://www.mathworks.com/help/autoblks/ref/drivecyclesource.html, abgerufen 12.11.2026 (Herkunft des Fahrzyklus FTP75).
%[text] \[4\] M. Mitschke, H. Wallentowitz: Dynamik der Kraftfahrzeuge. Springer Fachmedien Wiesbaden, 2014.

function sParameter = LeseParameter()
% LeseParameter: fuehrt parameterAufbau.m (ruft parameterFahrzeug.m auf) aus und sammelt alle PAR_-Werte
% Eingabe:  keine
% Ausgabe:  sParameter [struct]: ein Feld je PAR_-Parameter [Einheit wie dort]
    parameterAufbau;
    caName = who('PAR_*');
    sParameter = struct();
    for k = 1:numel(caName)
        sParameter.(caName{k}) = eval(caName{k});
    end
end

function [afBeschl,afGeschw] = BerechneRampe(afZeit,sParameter)
% BerechneRampe: Bremsrampe des Leitszenarios in geschlossener Form (Stufe 0)
%    a = -a_B/t_r (u(t - t_0) - u(t - t_0 - t_r)) mit u(s) = max(s,0); v durch Integration, Integral von u ist u^2/2
% Eingabe:  afZeit     [n x 1]: Zeit t [s]
%           sParameter [struct]: PAR_-Werte mit v_0, a_B, t_0, t_r [m/s, m/s^2, s, s]
% Ausgabe:  afBeschl   [n x 1]: Beschleunigung a [m/s^2]
%           afGeschw   [n x 1]: Geschwindigkeit v [m/s]
    afBeschl = -sParameter.PAR_Ach_BeschlBrems_f64 / sParameter.PAR_Ach_ZeitBrems_f64 ...
        * (max(afZeit - sParameter.PAR_Ach_ZeitStart_f64,0) ...
        - max(afZeit - sParameter.PAR_Ach_ZeitStart_f64 - sParameter.PAR_Ach_ZeitBrems_f64,0));
    afGeschw = sParameter.PAR_Lng_GeschwStart_f64 - sParameter.PAR_Ach_BeschlBrems_f64 / (2 * sParameter.PAR_Ach_ZeitBrems_f64) ...
        * (max(afZeit - sParameter.PAR_Ach_ZeitStart_f64,0).^2 ...
        - max(afZeit - sParameter.PAR_Ach_ZeitStart_f64 - sParameter.PAR_Ach_ZeitBrems_f64,0).^2);
end

