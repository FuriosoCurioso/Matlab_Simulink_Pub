%[text] # Analyse der Läufe Stufen 0–3: was in den Ergebnisdateien steht und was es bedeutet
%[text] Herkunft jeder Zahl: **gespeichert** (steht so in der Datei), **berechnet** (hier aus den gespeicherten Werten und den Parametern nachgerechnet) oder **simuliert** (Simulink-Modell Stufe2\_Laengsdyn1DOF.slx, ode45, RelTol $10^{-6}$, größter Schritt 1 s).

close all; clear; clc;

stOrdner = fileparts(mfilename('fullpath'));  % Stufenordner [-]
if startsWith(stOrdner,tempdir)  % Live Editor meldet seinen Temp-Ordner statt des Stufenordners
    stOrdner = fileparts(matlab.desktop.editor.getActiveFilename);  % Stufenordner der geoeffneten Datei [-]
end

sS1 = load(fullfile(stOrdner,'Stufe1_FTP75.mat'));      % Lauf Stufen 0/1, FTP75 Phase 1 [-]
sS2 = load(fullfile(stOrdner,'Stufe2_Ausrollen.mat'));  % Lauf Stufen 2/3, Ausrollen [-]
set(groot,'defaultAxesFontSize',14,'defaultLineLineWidth',1.5,'defaultAxesXGrid','on','defaultAxesYGrid','on');

%%
%[text] ## Was steckt in den beiden Dateien?
%[text] **Stufe1\_FTP75.mat** – Stufen 0 und 1. Eingang: die Sollgeschwindigkeit $v(t)$ des genormten Stadtfahrzyklus FTP75, Phase 1, einmal pro Sekunde (t = 1 … 506 s), aus der Datei cycleFTP75.mat des Powertrain Blockset \[3\].
%[text] - je Zeitpunkt (506 Werte): afZeit $t$ \[s\], afGeschw $v$ \[m/s\], afWeg $x$ \[m\]
%[text] - je Sekundenintervall (505 Werte): afBeschl $a$ \[m/s²\], afKraft $F\_x$ \[N\], afLeistung $P$ \[W\]
%[text] - sErgebnis: Kennwerte (Strecke, größte Kraft und Leistung, Energie je 100 km, Prüfergebnisse); sParameter: Fahrzeugdaten des Laufs \
%[text] **Stufe2\_Ausrollen.mat** – Stufen 2 und 3. Eingang: Anfangsgeschwindigkeit $v\_0$ = 30 m/s, danach keine Antriebskraft ($F\_x = 0$). Das Fahrzeug rollt aus, bis es steht.
%[text] - je Zeitpunkt (211 Werte, Abstand vom Löser gewählt, nicht gleichmäßig): afZeit, afGeschw $v$, afGeschwRef $v$ des MathWorks-Referenzblocks \[1\], afWeg $x$
%[text] - Arbeiten \[J\]: afArbeitAntr $W\_x$ (überall 0), afArbeitRoll $W\_R$, afArbeitLuft $W\_L$; afRest: Rest der Energiebilanz
%[text] - sErgebnis: Kennwerte; sParameter: Fahrzeugdaten; sSolver: Löser und Genauigkeit \
%[text] Warum 505 statt 506 Werte? Zwischen 506 Zeitpunkten liegen 505 Intervalle; Beschleunigung, Kraft und Leistung gelten je Intervall.

%%
%[text] ## Die Fahrzeugdaten sind für beide Läufe dieselben
%[text] Beide Dateien enthalten denselben Parametersatz (Lernhilfe-Satz, Herkunft je Wert in parameterFahrzeug.m). Daraus folgen zwei Kenngrößen:
%[text] - Rollwiderstandskraft $F\_R = f\_R\\, m\\, g$ = 147,2 N: konstante Bremskraft der Reifen, solange das Fahrzeug rollt (berechnet)
%[text] - Luftwiderstandskonstante $C = \\frac{1}{2} \\rho\\, c\_w A$ = 0,396 kg/m: die Luftkraft ist $C v^2$, wächst also mit dem Quadrat der Geschwindigkeit (berechnet) \
%[text] Die Werte für die Achsen ($l\_v$, $l\_h$, $h$) werden erst ab Stufe 4 gebraucht; $v\_0$ nur in den Stufen 2 und 3.
caParameter = { ...
    'm',   sS2.sParameter.PAR_Lng_MasseFzg_f64,    'kg',    'Fahrzeugmasse',                   'Stufen 1-3'; ...
    'c_w', sS2.sParameter.PAR_Lng_BeiwLuft_f64,    '-',     'Luftwiderstandsbeiwert (Form)',   'Stufen 1-3'; ...
    'A',   sS2.sParameter.PAR_Lng_Stirnfl_f64,     'm^2',   'Stirnflaeche',                    'Stufen 1-3'; ...
    'rho', sS2.sParameter.PAR_Lng_DichteLuft_f64,  'kg/m^3','Luftdichte',                      'Stufen 1-3'; ...
    'f_R', sS2.sParameter.PAR_Lng_BeiwRoll_f64,    '-',     'Rollwiderstandsbeiwert',          'Stufen 1-3'; ...
    'g',   sS2.sParameter.PAR_Lng_BeschlErde_f64,  'm/s^2', 'Erdbeschleunigung',               'Stufen 1-3'; ...
    'v_0', sS2.sParameter.PAR_Lng_GeschwStart_f64, 'm/s',   'Anfangsgeschwindigkeit Ausrollen','Stufen 2-3'; ...
    'l_v', sS2.sParameter.PAR_Ach_AbstVo_f64,      'm',     'Abstand Schwerpunkt-Vorderachse', 'hier nicht verwendet'; ...
    'l_h', sS2.sParameter.PAR_Ach_AbstHi_f64,      'm',     'Abstand Schwerpunkt-Hinterachse', 'hier nicht verwendet'; ...
    'h',   sS2.sParameter.PAR_Ach_SchwerpHoehe_f64,'m',     'Schwerpunkthoehe',                'hier nicht verwendet'};  % Parameteruebersicht [-]
convertvars(cell2table(caParameter,'VariableNames',{'Zeichen','Wert','Einheit','Bedeutung','Verwendung'}),@iscell,'string')
fMasse = sS2.sParameter.PAR_Lng_MasseFzg_f64;  % Fahrzeugmasse m [kg]
fKraftRoll = sS2.sParameter.PAR_Lng_BeiwRoll_f64 * fMasse * sS2.sParameter.PAR_Lng_BeschlErde_f64;  % Rollwiderstandskraft F_R [N]
fKonstLuft = 0.5 * sS2.sParameter.PAR_Lng_DichteLuft_f64 * sS2.sParameter.PAR_Lng_BeiwLuft_f64 ...
    * sS2.sParameter.PAR_Lng_Stirnfl_f64;     % Luftwiderstandskonstante C [kg/m]

%%
%[text] ## Stufe 0: Aus der Geschwindigkeit folgt der zurückgelegte Weg
%[text] Kinematik heißt: Bewegung beschreiben, ohne nach Kräften zu fragen. Der Weg ist die aufsummierte Geschwindigkeit, $x(t) = \\int v\\, dt$; die Fläche unter der blauen Kurve ist die Strecke.
%[text] Ergebnis (berechnet): 5779,2 m in 505 s. Die vielen Stopps sind typisch für einen Stadtzyklus; höchstens 25,3 m/s (91 km/h).
figure; tiledlayout(2,1);
nexttile; plot(sS1.afZeit,sS1.afGeschw,'b');
title('Eingang: Sollgeschwindigkeit FTP75 Phase 1'); xlabel('Zeit t [s]'); ylabel('Geschwindigkeit v [m/s]');
nexttile; plot(sS1.afZeit,sS1.afWeg / 1e3,'k');
title('Ausgang: zurueckgelegter Weg'); xlabel('Zeit t [s]'); ylabel('Weg x [km]');

%%
%[text] ## Stufe 0: Die Beschleunigung ist die Änderung der Geschwindigkeit je Sekunde
%[text] Zwischen zwei Sekundenwerten wird $v$ geradlinig verbunden; dann ist $a\_k = (v\_{k+1} - v\_k)/\\Delta t$ im ganzen Intervall konstant (Treppe). Positiv heißt schneller werden, negativ langsamer werden.
%[text] Ergebnis (berechnet): $a$ zwischen −1,48 und 1,48 m/s², das sind etwa 15 % der Erdbeschleunigung $g$.
%[text] Prüfung: Addiert man alle Änderungen wieder auf, ergibt sich $v(t)$ mit einem Fehler von 4,4·10⁻¹⁶ m/s (Toleranz 10⁻⁹ m/s). Das ist eine Rechenkontrolle (Rundung), keine Prüfung der Physik.
figure;
stairs(sS1.afZeit(1:end - 1),sS1.afBeschl,'r');
title('Beschleunigung je Sekundenintervall'); xlabel('Zeit t [s]'); ylabel('Beschleunigung a [m/s^2]');

%%
%[text] ## Stufe 1: Die Antriebskraft setzt sich aus drei Anteilen zusammen
%[text] Rückwärtsrechnung: Die Bewegung ist vorgegeben, gesucht ist die Kraft am Rad, die sie erzeugt. Je Intervall mit der mittleren Geschwindigkeit $v\_m$:
%[text] $F\_x = m\\, a + F\_R + C\\, v\_m^2$ – Kraft zum Beschleunigen + Rollwiderstand + Luftwiderstand. $F\_R$ wirkt nur, wenn das Fahrzeug rollt ($v\_m \> 0$); im Stand ist $F\_x = 0$.
%[text] Ergebnis (berechnet): höchstens 2408 N. Die Spitzen kommen vom Beschleunigen (bis 2213 N); Luft höchstens 254 N, Rollen konstant 147 N. Über die Antriebsphasen gerechnet ($P \> 0$) entfallen aber nur etwa 50 % der Energie aufs Beschleunigen, je etwa 25 % auf Rollen und Luft. Negative Werte: Die Bremsen müssen Kraft aufnehmen.
afGeschwMitte = (sS1.afGeschw(1:end - 1) + sS1.afGeschw(2:end)) / 2;  % mittlere Geschwindigkeit je Intervall v_m [m/s]
afKraftTraeg = fMasse * sS1.afBeschl;                                    % Anteil Beschleunigen m a [N]
afKraftLuftPro = fKonstLuft * afGeschwMitte.^2;                          % Anteil Luftwiderstand C v_m^2 [N]
figure;
stairs(sS1.afZeit(1:end - 1),[afKraftTraeg, fKraftRoll * (afGeschwMitte > 0), afKraftLuftPro, sS1.afKraft]);
colororder({'r','g','m','k'});
title('Laengskraft am Rad und ihre Anteile'); xlabel('Zeit t [s]'); ylabel('Kraft F [N]');
legend('m a (Beschleunigen)','F_R (Rollwiderstand)','C v_m^2 (Luftwiderstand)','F_x (Summe)','Location','southwest');

%%
%[text] ## Stufe 1: Die Leistung zeigt, wann der Motor arbeitet und wann gebremst wird
%[text] Leistung ist Kraft mal Geschwindigkeit, $P = F\_x\\, v\_m$; die Fläche unter der Kurve ist Energie. $P \> 0$: Antrieb; $P \< 0$: Bremsen.
%[text] Ergebnis (berechnet): höchstens 32,0 kW; beim stärksten Bremsen etwa −25 kW. Antriebsenergie am Rad 12,53 kWh je 100 km – gezählt nur $P \> 0$, also ohne Rückgewinnung der Bremsenergie; nicht verifiziert, Luftarbeit mit $v\_m$ genähert.
%[text] Prüfung: Die Beschleunigungsarbeit $\\sum m\\, a\\, v\_m\\, \\Delta t$ gleicht der Änderung der Bewegungsenergie, Rest −1,5·10⁻¹¹ J (Toleranz 10⁻³ J). Auch das ist eine Rechenkontrolle; $F\_R$ und $C$ gehen nicht ein.
figure;
stairs(sS1.afZeit(1:end - 1),sS1.afLeistung / 1e3,'k');
title('Radleistung je Sekundenintervall'); xlabel('Zeit t [s]'); ylabel('Leistung P [kW]');

%%
%[text] ## Stufe 2: Ohne Antrieb rollt das Fahrzeug in 196 s aus – Simulation, Formel und Referenzblock stimmen überein
%[text] Vorwärtsrechnung: Jetzt ist die Kraft vorgegeben ($F\_x = 0$) und die Bewegung gesucht. Newton: $m\\, \\dot{v} = -F\_R - C\\, v |v|$. Die Gleichung hat eine exakte Lösung:
%[text] $v(t) = v\_c \\tan\\left(\\arctan(v\_0/v\_c) - t/T\_c\\right)$ mit $v\_c = \\sqrt{F\_R/C}$ = 19,28 m/s und $T\_c = m/(C\\, v\_c)$ = 196,50 s (berechnet).
%[text] $v\_c$: Bei dieser Geschwindigkeit sind Luft- und Rollwiderstand gleich groß. $T\_c$ ist eine Zeitkonstante der Formel; nicht zu verwechseln mit der Abklingzeit $\\tau\_v = m/(2 C v\_0)$ = 63,1 s (gespeichert), die angibt, wie schnell bei 30 m/s eine kleine Störung abklingt.
%[text] Ergebnis (simuliert): Stillstand nach 196,44 s und 2330,0 m. Abweichung zur Formel 4,3·10⁻¹³ m/s, zum Referenzblock 1DOF \[1\] 4,4·10⁻⁹ m/s (Toleranz je 3·10⁻⁴ m/s). Der letzte Wert $v$ = −1,8·10⁻¹³ m/s ist Rundung am Haltepunkt.
fGeschwKrit = sqrt(fKraftRoll / fKonstLuft);         % Geschwindigkeit mit F_R = C v^2, v_c [m/s]
fZeitKrit = fMasse / (fKonstLuft * fGeschwKrit);     % Zeitkonstante der Ausroll-Loesung T_c [s]
afGeschwAna = max(fGeschwKrit * tan(atan(sS2.sParameter.PAR_Lng_GeschwStart_f64 / fGeschwKrit) ...
    - sS2.afZeit / fZeitKrit),0);                    % analytische Geschwindigkeit v [m/s]
figure;
plot(sS2.afZeit,sS2.afGeschw,'b',sS2.afZeit,afGeschwAna,'k--',sS2.afZeit,sS2.afGeschwRef,'r:');
yline(fGeschwKrit,'g');
title('Ausrollen ab v_0 = 30 m/s'); xlabel('Zeit t [s]'); ylabel('Geschwindigkeit v [m/s]');
legend('Simulation (eigenes Modell)','Formel (analytisch)','Referenzblock 1DOF','v_c (F_R = C v^2)');

%%
%[text] ## Stufe 2: Bei hoher Geschwindigkeit bremst die Luft, bei niedriger der Rollwiderstand
%[text] Die Verzögerung ist die Summe beider Widerstände geteilt durch die Masse: $a = -(F\_R + C\\, v^2)/m$ (berechnet aus der gespeicherten $v(t)$).
%[text] Bei 30 m/s ist die Luftkraft 356 N, mehr als doppelt so groß wie $F\_R$ = 147 N; unterhalb von $v\_c$ überwiegt der Rollwiderstand. Deshalb wird das Fahrzeug anfangs stark, später schwächer verzögert. Weil $F\_R$ auch bei kleiner Geschwindigkeit voll wirkt, steht es nach endlicher Zeit; mit Luftwiderstand allein würde es nie ganz anhalten.
%[text] Im Stand wirkt keine Widerstandskraft mehr; deshalb springen $F\_R$ und $a$ am letzten Zeitpunkt auf 0. Das ist kein Fehler, sondern das Anhalten.
afKraftLuft = fKonstLuft * sS2.afGeschw .* abs(sS2.afGeschw);              % Luftwiderstandskraft F_L [N]
afBeschlAus = -(fKraftRoll * (sS2.afGeschw > 0) + afKraftLuft) / fMasse;   % Verzoegerung beim Ausrollen a [m/s^2]
figure; tiledlayout(2,1);
nexttile; plot(sS2.afZeit,fKraftRoll * (sS2.afGeschw > 0),'g',sS2.afZeit,afKraftLuft,'m');
title('Widerstandskraefte beim Ausrollen'); xlabel('Zeit t [s]'); ylabel('Kraft F [N]');
legend('F_R (Rollwiderstand)','F_L (Luftwiderstand)');
nexttile; plot(sS2.afZeit,afBeschlAus,'r');
title('Beschleunigung beim Ausrollen'); xlabel('Zeit t [s]'); ylabel('Beschleunigung a [m/s^2]');

%%
%[text] ## Stufe 3: Die Bewegungsenergie geht vollständig in Roll- und Luftwiderstand über
%[text] Energiebilanz: Am Anfang hat das Fahrzeug die Bewegungsenergie $E\_{kin,0} = \\frac{1}{2} m v\_0^2$ = 675 000 J (berechnet). Sie wird beim Ausrollen in Wärme umgesetzt: $W\_R$ = 342 857 J durch die Reifen, $W\_L$ = 332 143 J durch die Luft (simuliert); ein Antrieb fehlt ($W\_x = 0$).
%[text] Prüfung: Rest $= E\_{kin} - E\_{kin,0} - W\_x + W\_R + W\_L$ höchstens 3,6·10⁻⁸ J (Toleranz RelTol · $E\_{kin,0}$ = 0,675 J). Die Bilanz prüft, ob das Modell Energie richtig verbucht; einen falschen Parameterwert erkennt sie nicht.
fEnergStart = 0.5 * fMasse * sS2.sParameter.PAR_Lng_GeschwStart_f64^2;  % Bewegungsenergie am Start E_kin,0 [J]
figure; tiledlayout(2,1);
nexttile; plot(sS2.afZeit,0.5 * fMasse * sS2.afGeschw.^2 / 1e3,'b',sS2.afZeit,sS2.afArbeitRoll / 1e3,'g', ...
    sS2.afZeit,sS2.afArbeitLuft / 1e3,'m',sS2.afZeit,(sS2.afArbeitRoll + sS2.afArbeitLuft) / 1e3,'k--');
yline(fEnergStart / 1e3,'k:');
title('Energie beim Ausrollen'); xlabel('Zeit t [s]'); ylabel('Energie E [kJ]');
legend('E_{kin}','W_R','W_L','W_R + W_L','E_{kin,0}','Location','east');
nexttile; plot(sS2.afZeit,sS2.afRest,'k');
title('Rest der Energiebilanz (Rundung des Loesers)'); xlabel('Zeit t [s]'); ylabel('Rest [J]');

%%
%[text] ## Prüfungen auf einen Blick: Alle bestanden, aber nur Stufen 2 und 3 prüfen die Physik
%[text] - Stufe 0, Rückintegration $a \\to v$: 4,4·10⁻¹⁶ m/s (Toleranz 10⁻⁹ m/s) – Rechnung richtig umgesetzt (Identität)
%[text] - Stufe 1, Radenergie gegen Profil: 1,5·10⁻¹¹ J (Toleranz 10⁻³ J) – Rechnung richtig umgesetzt (Identität)
%[text] - Stufe 2, Simulation gegen Formel: 4,3·10⁻¹³ m/s (Toleranz 3·10⁻⁴ m/s) – Modell löst die Bewegungsgleichung richtig
%[text] - Stufe 2, Simulation gegen Referenzblock \[1\]: 4,4·10⁻⁹ m/s (Toleranz 3·10⁻⁴ m/s) – gleiche Physik wie das MathWorks-Modell
%[text] - Stufe 3, Energiebilanz: 3,6·10⁻⁸ J (Toleranz 0,675 J) – keine Energie geht verloren oder entsteht \
%[text] Alle Werte gelten nur für den Parametersatz oben. Ob die Parameter zu einem realen Fahrzeug passen, prüft keine dieser Rechnungen.
%[text] Quellen: \[1\] MathWorks, Vehicle Body 1DOF Longitudinal, https://www.mathworks.com/help/vdynblks/ref/vehiclebody1doflongitudinal.html, abgerufen 12.11.2026. \[3\] MathWorks, Drive Cycle Source, https://www.mathworks.com/help/autoblks/ref/drivecyclesource.html, abgerufen 12.11.2026.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
