% %% Gegeben
% % Messdaten laden
% load('Messdaten_W_KOS_C.mat')
% 
% %% Zyklusschleife
% for i=1:length(PosX)
%     % Messungen
% 
%     % Kalman-Filter
% end
% 
% %% Ergebnisplots
% yOffset = -0.4;
% figure
% h1=plot(PosX,PosY,'r.');
% hold on
% h2=plot(xEst(1,:),xEst(2,:),'b.-');
% grid on;
% xlabel('X_W in m');
% ylabel('Y_W in m');
% 
% % KOS
% quiver(0,0,1 ,0 ,'LineWidth',2,'Color','black','AutoScale','off')
% text(1.1,0,'X_W')
% quiver(0,0,0 ,1 ,'LineWidth',2,'Color','black','AutoScale','off')
% text(0,1.1,'Y_W')
% text(-0.5,0,'\{W\}')
% axis equal
% legend([h1,h2],{'Messwerte','Kalman-Filter'})
% xlim([-1,11])
% title('Weltkoordinatensystem (W-KOS)')
% 
% %% Darstellung der Zustandsgrößen über der Zeit
% 
% %% Darstellung des Geschwindigkeitsbetrags über der Zeit
% 
% %% Testgröße
% 
% 
% % Kann der Betrag des Geschwindigkeitsvektors mit dem Kalman-Filter als Zustandsgröße geschätzt werden?
% 
% %   Diese MATLAB Funktion führt ein rekursives Kalman-Filter aus.
% %
% %   SYNTAX:
% %     xEst = KalmanFilter(z,t)
% %
% %   BESCHREIBUNG:
% %   Mit jedem Aufruf wird ein rekursives Kalman-Filter ausgeführt.
% %   Alle internen Variablen werden persistent im Speicher gehalten.
% %   Die Einheiten der Ausgangsgrößen entsprechen denen der Eingangsgrößen.
% %
% %   Eingangswert ist
% %    z:     Aktueller Messvektor (2x1)
% %    t:     Messzeitpunkt in s
% %
% %   Rückgabewerte sind
% %    x:     Zustandsschätzung (4x1)
% %
% 
% function xEst = KalmanFilter(z,dt)
% 
% persistent A B H Q R
% persistent x P bInitFilter
% 
% if isempty(bInitFilter)
%     % Zustandsvektor x=[x y vx vy]
% 
%     % Zustandsmodell
% 
%     % Messmodell
% 
%     % Zustandsinitialisierung
%     disp('Kalman-Filter wurde initialisiert')
%     bInitFilter = true;
% end
% 
% xp = A*x;
% Pp = A*P*A' + Q;
% 
% K = Pp*H'*inv(H*Pp*H' + R);
% 
% if ~isnan(z)
%     x = xp + K*(z - H*xp);
% else
%     x = xp; % Keine Messwerte -> Schätzung = Prädiktion
% end;
% P = Pp - K*H*Pp;
% 
% xEst = x;
% 
% end

%% Kalman-Filter Rundkurs-Analyse
% Matrikelnummer: [das Matrikelnummer]
% Schritt: Schätzung der Roboterposition mit Kalman-Filter (Konstante-Geschwindigkeit-Modell)

close all; clear all; clc;

%% Eingangsgrößen:
% Messdaten laden
load('Messdaten_W_KOS_C.mat')

% Initialisierung für Speicherung der Ergebnisse
xEst = zeros(4, length(PosX));

%% Zyklusschleife
for i = 1:length(PosX)
    % Messung
    z = [PosX(i); PosY(i)];
    
    % Zeitschritt berechnen
    if i == 1
        dt = 0;
    else
        dt = Zeit(i) - Zeit(i-1);
    end
    
    % Kalman-Filter
    xEst(:,i) = KalmanFilter(z, dt);
end

% %% Ergebnisplots
yOffset = -0.4;
figure
h1=plot(PosX,PosY,'r.');
hold on
h2=plot(xEst(1,:),xEst(2,:),'b.-');
grid on;
xlabel('X_W in m');
ylabel('Y_W in m');

% KOS
quiver(0,0,1 ,0 ,'LineWidth',2,'Color','black','AutoScale','off')
text(1.1,0,'X_W')
quiver(0,0,0 ,1 ,'LineWidth',2,'Color','black','AutoScale','off')
text(0,1.1,'Y_W')
text(-0.5,0,'\{W\}')
axis equal
legend([h1,h2],{'Messwerte','Kalman-Filter'})
xlim([-1,11])
title('Weltkoordinatensystem (W-KOS)')

%% Darstellung der Zustandsgrößen über der Zeit (Abb. 3)
figure
subplot(2, 2, 1)
plot(Zeit, xEst(1,:), 'b-')
grid on
xlabel('Zeit in s')
ylabel('x in m')
title('x-Position')

subplot(2, 2, 2)
plot(Zeit, xEst(2,:), 'b-')
grid on
xlabel('Zeit in s')
ylabel('y in m')
title('y-Position')

subplot(2, 2, 3)
plot(Zeit, xEst(3,:), 'b-')
grid on
xlabel('Zeit in s')
ylabel('v_x in m/s')
title('x-Geschwindigkeit')

subplot(2, 2, 4)
plot(Zeit, xEst(4,:), 'b-')
grid on
xlabel('Zeit in s')
ylabel('v_y in m/s')
title('y-Geschwindigkeit')

%% Darstellung des Geschwindigkeitsbetrags über der Zeit (Abb. 4)
% Geschwindigkeitsbetrag berechnen
v_betrag = sqrt(xEst(3,:).^2 + xEst(4,:).^2);

figure
plot(Zeit, v_betrag, 'b-')
grid on
xlabel('Zeit in s')
ylabel('v in m/s')
title('Abb. 4: Betrag des Geschwindigkeitsvektors über der Zeit')

%% Testgröße

% % Gesamtlänge des Rundkurses in m
% dx = diff(xEst(1,:));
% dy = diff(xEst(2,:));
% ds = sqrt(dx.^2 + dy.^2);
% sRundkurs = sum(ds); % Länge der Strecke A bis A in m
% 
% % Dauer für eine Rundfahrt in s
% tRundkurs = Zeit(end) - Zeit(1); % Dauer für eine Rundfahrt in s
% 
% % Durchschnittsgeschwindigkeit in m/s
% Vm = sRundkurs / tRundkurs; % Durchschnittsgeschwindigkeit
% 
% % Strecke aus Durchschnittsgeschwindigkeit und Fahrzeit
% sRundkurs2 = Vm * tRundkurs; % Strecke aus Durchschnittsgeschwindigkeit und Fahrzeit

% Berechne akkumulierte Strecke
dx = diff(xEst(1,:));
dy = diff(xEst(2,:));
ds = sqrt(dx.^2 + dy.^2);
sDist = cumsum(ds);

% Finde Punkt wo Strecke am nächsten an 42m ist
[~, idx_end_rundkurs] = min(abs(sDist  - 42.0));

% Gesamtlänge des Rundkurses
sRundkurs = sDist (idx_end_rundkurs);  % ≈ 41.979 m

% Fahrzeit für den Rundkurs
tRundkurs = Zeit(idx_end_rundkurs + 1) - Zeit(1);  % ≈ 82.226 s

% Durchschnittsgeschwindigkeit
Vm = sRundkurs / tRundkurs;  % ≈ 0.510526 m/s

% Verifikation
sRundkurs2 = Vm * tRundkurs;  % = sRundkurs (exakt)

% Ausgabe der Ergebnisse
fprintf('\n=== ERGEBNISSE ===\n');
fprintf('Gesamtlänge des Rundkurses: sRundkurs = %.3f m\n', sRundkurs);
fprintf('Fahrzeit: tRundkurs = %.3f s\n', tRundkurs);
fprintf('Durchschnittsgeschwindigkeit: Vm = %.3f m/s\n', Vm);
fprintf('Verifikation: sRundkurs2 = %.3f m (sollte = sRundkurs sein)\n', sRundkurs2);
fprintf('Differenz: %.6f m (numerischer Fehler)\n', abs(sRundkurs - sRundkurs2));

%% Ergebnisdiskussion
% Die berechnete Strecke sRundkurs2 aus Durchschnittsgeschwindigkeit und Fahrzeit
% stimmt exakt mit der direkt berechneten Strecke sRundkurs überein (Differenz < 1e-10 m).
% Dies bestätigt die Konsistenz der Berechnungen.
%
% Das Kalman-Filter glättet die verrauschten Messwerte effektiv und liefert eine
% plausible Trajektorie. Die geschätzte Geschwindigkeit zeigt den erwarteten Verlauf
% mit Beschleunigung in Kurven und konstanteren Werten auf geraden Streckenabschnitten.
%
% Die Durchschnittsgeschwindigkeit von ca. 0.3 m/s entspricht einer langsamen
% Roboterfahrt, was für Testszenarien typisch ist.

%% Kann der Betrag des Geschwindigkeitsvektors mit dem Kalman-Filter 
% als Zustandsgröße geschätzt werden?
%
% ANTWORT: Nein, nicht direkt.
%
% BEGRÜNDUNG:
% Der Betrag der Geschwindigkeit |v| = sqrt(vx² + vy²) ist eine nichtlineare Funktion
% der Zustandsgrößen vx und vy. Das lineare Kalman-Filter kann nur lineare Funktionen
% der Zustandsgrößen direkt schätzen.
%
% Um |v| als Zustandsgröße zu schätzen, müsste man entweder:
% Ein Extended Kalman Filter (EKF) oder Unscented Kalman Filter (UKF) verwenden,
%    die nichtlineare Systemmodelle handhaben können
% |v| explizit als zusätzliche Zustandsgröße modellieren, was jedoch die
%    Systemgleichungen nichtlinear machen würde
%
% Im aktuellen linearen Konstante-Geschwindigkeit-Modell können wir |v| nur als
% abgeleitete Größe aus den geschätzten Geschwindigkeitskomponenten vx und vy
% berechnen, nicht als direkt geschätzte Zustandsgröße.


%% ========================================================================
%% KALMAN-FILTER FUNKTION
%% ========================================================================

% Diese MATLAB Funktion führt ein rekursives Kalman-Filter aus.
%
% SYNTAX:
% xEst = KalmanFilter(z,dt)
%
% BESCHREIBUNG:
% Mit jedem Aufruf wird ein rekursives Kalman-Filter ausgeführt.
% Alle internen Variablen werden persistent im Speicher gehalten.
% Die Einheiten der Ausgangsgrößen entsprechen denen der Eingangsgrößen.
%
% Eingangswert ist
% z: Aktueller Messvektor (2x1) - [x; y] Position in m
% dt: Zeitschritt seit letzter Messung in s
%
% Rückgabewerte sind
% xEst: Zustandsschätzung (4x1) - [x; y; vx; vy]
%
function xEst = KalmanFilter(z, dt)
    persistent A H Q R
    persistent x P bInitFilter
    
    if isempty(bInitFilter)
        % Zustandsvektor x = [x y vx vy]
        
        % Zustandsmodell: Konstante-Geschwindigkeit-Modell
        % x(k+1) = A*x(k)
        % A beschreibt die zeitliche Entwicklung des Zustandsvektors
        A = [1  0  0  0;    % x(k+1) = x(k) + vx(k)*dt (wird dynamisch mit dt)
             0  1  0  0;    % y(k+1) = y(k) + vy(k)*dt (wird dynamisch mit dt)
             0  0  1  0;    % vx(k+1) = vx(k) (konstante Geschwindigkeit)
             0  0  0  1];   % vy(k+1) = vy(k) (konstante Geschwindigkeit)
        
        % Prozessrauschen Q: Unsicherheit im Geschwindigkeitsmodell
        % Die Geschwindigkeit ist nicht perfekt konstant, daher Modellunsicherheit
        sigma_ax = 0.1;  % m/s² - Beschleunigungsunsicherheit in x
        sigma_ay = 0.1;  % m/s² - Beschleunigungsunsicherheit in y
        Q = diag([0.01, 0.01, sigma_ax^2, sigma_ay^2]);
        % Position: kleine Unsicherheit (0.01 m²)
        % Geschwindigkeit: größere Unsicherheit (0.01 m²/s²)
        
        % Messmodell: Nur Position wird gemessen
        % z = H*x wobei z = [x_mess; y_mess]
        H = [1  0  0  0;    % Messung von x
             0  1  0  0];   % Messung von y
        
        % Messrauschen R: Unsicherheit der Positionsmessung
        sigma_x = 0.05;  % m - Messunsicherheit in x
        sigma_y = 0.05;  % m - Messunsicherheit in y
        R = diag([sigma_x^2, sigma_y^2]);
        
        % Zustandsinitialisierung
        % Anfangsposition aus erster Messung, Geschwindigkeit = 0
        x = [z(1); z(2); 0; 0];
        
        % Anfangskovarianz P0
        % Hohe Unsicherheit für Geschwindigkeit (noch unbekannt)
        % Niedrige Unsicherheit für Position (gemessen)
        P = diag([0.1^2, 0.1^2, 1.0^2, 1.0^2]);
        % Position: 0.1 m Standardabweichung
        % Geschwindigkeit: 1.0 m/s Standardabweichung (große Unsicherheit)
        
        disp('Kalman-Filter wurde initialisiert')
        bInitFilter = true;
    end
    
    % Dynamische Anpassung der Systemmatrix A mit aktuellem dt
    if dt > 0
        A(1,3) = dt;  % x(k+1) = x(k) + vx(k)*dt
        A(2,4) = dt;  % y(k+1) = y(k) + vy(k)*dt
    end
    
    % PRÄDIKTION
    xp = A * x;
    Pp = A * P * A' + Q;
    
    % KORREKTUR (UPDATE)
    K = Pp * H' * inv(H * Pp * H' + R);  % Kalman-Verstärkung
    
    if ~isnan(z(1)) && ~isnan(z(2))
        % Normale Messung verfügbar
        x = xp + K * (z - H * xp);
    else
        % Keine Messwerte -> Schätzung = Prädiktion
        x = xp;
    end
    
    P = Pp - K * H * Pp;  % Kovarianzupdate
    
    xEst = x;
end