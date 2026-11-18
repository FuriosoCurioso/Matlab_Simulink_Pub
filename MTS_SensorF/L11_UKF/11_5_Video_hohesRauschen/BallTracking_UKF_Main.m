
% Ball-Tracking mittels UKF aus Video

close all; clear all; clc;

%% Video laden
vidObj = VideoReader('BouncingBall.mp4');
dt = 1/vidObj.FrameRate;  % Zykluszeit

%% Initialisierung
nFrames = 60;  % Laut Schritt: 60 Frames
zSaved = zeros(2, nFrames);
xSaved = zeros(4, nFrames);

%% Hauptschleife: UKF über alle Frames
for k = 1:nFrames
    % Messung einlesen
    z = messeBallPos(k);

    % UKF ausführen
    x = UnscentedKalmanFilter(z, dt);

    % Ergebnisse speichern
    zSaved(:, k) = z;
    xSaved(:, k) = x;

    %% Ergebnis darstellen
    vidFrame = readFrame(vidObj);
    imshow(vidFrame);
    hold on

    if ~isnan(z)
        h1 = plot(z(1), z(2), 'yo', 'MarkerSize', 8, 'LineWidth', 2);
        h2 = plot(x(1), x(3), 'b*', 'MarkerSize', 10, 'LineWidth', 2);
        xlabel(['Frame: ', num2str(k)])
        legend([h1 h2], {'Messwert', 'UKF'})
    else
        % Kein Messwert, nur UKF-Schätzung anzeigen
        h2 = plot(x(1), x(3), 'b*', 'MarkerSize', 10, 'LineWidth', 2);
        xlabel(['Frame: ', num2str(k)])
        legend(h2, {'UKF'})
    end

    hold off

    % Kurze Pause für Visualisierung (optional)
    pause(0.05);
end

function z = messeBallPos(k)
% Funktion zum Auslesen der Ball-Positionsmessungen
% Input: k - Frame-Nummer (1-60)
% Output: z - Messvektor [x; y] oder [NaN; NaN]

    % Laden der persistenten Messdaten
    persistent zSaved

    if isempty(zSaved)
        % Messdaten beim ersten Aufruf laden
        data = load('MessungenBallPosition.mat');
        zSaved = data.zSaved;  % [60×2] Matrix
    end

    % Messwert für Frame k extrahieren
    % WICHTIG: zSaved ist [60×2], also [Frame × [x,y]]
    if k >= 1 && k <= size(zSaved, 1)
        z = zSaved(k, :)';  % Transponieren zu [2×1] Spaltenvektor
    else
        z = [NaN; NaN];
    end
end

function x = UnscentedKalmanFilter(z, dt)
% Unscented Kalman Filter für Ball-Tracking mit Gravitation
% Input:  z - Messvektor [x; y] oder [NaN; NaN]
%         dt - Zeitschritt [s]
% Output: x - Zustandsvektor [x_pos; v_x; y_pos; v_y]

    persistent x_prev P_prev initialized kappa

    % Parameter
    g = 300;  % Gravitation in Pixel/s² (geschätzt aus Video)

    if isempty(initialized)
        %% INITIALISIERUNG beim ersten Aufruf

        % Zustandsvektor: [x_pos; v_x; y_pos; v_y]
        x_prev = [130; 0; 10; 0];  % Startposition geschätzt

        % Kovarianzmatrix (Startunsicherheit)
        P_prev = diag([100, 50, 100, 50]);

        % UKF Parameter
        kappa = 0;  % Standard: n - 3, für n=4 → kappa = 1, aber oft kappa=0

        initialized = 1;
    end

    n = length(x_prev);  % Zustandsdimension (4)

    %% PROZESSRAUSCHEN
    % Q = Unsicherheit im Systemmodell
    Q = diag([0.1, 0.1, 1, 10]);  % [x_pos, v_x, y_pos, v_y]

    %% MESSRAUSCHEN
    % R = Unsicherheit in den Messungen
    R = diag([1, 1]);  % [x, y] Messunsicherheit in Pixel

    %% PRÄDIKTION

    % Sigma-Punkte erzeugen
    [Xi, W] = SigmaPunkte(x_prev, P_prev, kappa);

    % Sigma-Punkte durch nichtlineares Systemmodell propagieren
    Xi_pred = zeros(n, 2*n+1);
    for i = 1:(2*n+1)
        Xi_pred(:, i) = systemModell(Xi(:, i), dt, g);
    end

    % Prädiktion durch Unscented Transformation
    [x_pred, P_pred] = UT(Xi_pred, W, Q);

    %% UPDATE (nur wenn Messung verfügbar)

    if all(~isnan(z))
        % Messung vorhanden → Update durchführen

        % Neue Sigma-Punkte für Update erzeugen
        [Xi_pred_new, W_new] = SigmaPunkte(x_pred, P_pred, kappa);

        % Sigma-Punkte durch Messmodell transformieren
        m = length(z);  % Messdimension (2)
        Zi = zeros(m, 2*n+1);
        for i = 1:(2*n+1)
            Zi(:, i) = messModell(Xi_pred_new(:, i));
        end

        % Erwartete Messung durch UT
        [z_pred, Pzz] = UT(Zi, W_new, R);

        % Cross-Kovarianz berechnen
        Pxz = zeros(n, m);
        for i = 1:(2*n+1)
            Pxz = Pxz + W_new(i) * (Xi_pred_new(:, i) - x_pred) * (Zi(:, i) - z_pred)';
        end

        % Kalman Gain
        K = Pxz / Pzz;

        % Update
        x = x_pred + K * (z - z_pred);
        P = P_pred - K * Pzz * K';

    else
        % Keine Messung → nur Prädiktion
        x = x_pred;
        P = P_pred;
    end

    %% Zustand für nächsten Schritt speichern
    x_prev = x;
    P_prev = P;
end


%% HILFSFUNKTIONEN

function x_next = systemModell(x, dt, g)
% Nichtlineares Systemmodell: Ball mit konstanter x-Geschwindigkeit und Gravitation
% x = [x_pos; v_x; y_pos; v_y]

    x_next = zeros(4, 1);

    % x-Position: konstante Geschwindigkeit
    x_next(1) = x(1) + x(2) * dt;

    % x-Geschwindigkeit: konstant
    x_next(2) = x(2);

    % y-Position: mit aktueller Geschwindigkeit
    x_next(3) = x(3) + x(4) * dt;

    % y-Geschwindigkeit: mit Gravitation
    x_next(4) = x(4) + g * dt;
end


function z = messModell(x)
% Lineares Messmodell: Messe nur Position [x, y]
% x = [x_pos; v_x; y_pos; v_y]
% z = [x_pos; y_pos]

    z = [x(1); x(3)];
end


%% Ergebnisse für die automatische Auswertung
x20 = xSaved(:, 20)  % Zustandsvektor für Frame 20
x40 = xSaved(:, 40)  % Zustandsvektor für Frame 40
x59 = xSaved(:, 59)  % Zustandsvektor für Frame 59

%% Ausgabe der finalen Ergebnisse
fprintf('\n=== UKF Ball-Tracking Ergebnisse ===\n');
fprintf('Frame 20: x=%.2f, v_x=%.2f, y=%.2f, v_y=%.2f\n', x20);
fprintf('Frame 40: x=%.2f, v_x=%.2f, y=%.2f, v_y=%.2f\n', x40);
fprintf('Frame 59: x=%.2f, v_x=%.2f, y=%.2f, v_y=%.2f\n', x59);

% close all; clear all; clc;
% 
% vidObj = VideoReader('BouncingBall.mp4');
% dt = 1/vidObj.FrameRate;
% 
% zSaved = zeros(2, 60);
% xSaved = zeros(4, 60);
% 
% for k = 1:60
%     z = messeBallPos(k);
%     x = UnscentedKalmanFilter(z, dt);
% 
%     zSaved(:, k) = z;
%     xSaved(:, k) = x;
% 
%     vidFrame = readFrame(vidObj);
%     imshow(vidFrame);
%     hold on
%     if ~isnan(z(1))
%         h1 = plot(z(1), z(2), 'yo', 'MarkerSize', 8, 'LineWidth', 2);
%         h2 = plot(x(1), x(3), 'b*', 'MarkerSize', 10, 'LineWidth', 2);
%         legend([h1 h2], {'Messwert', 'UKF'})
%     else
%         plot(x(1), x(3), 'b*', 'MarkerSize', 10, 'LineWidth', 2);
%         legend('UKF')
%     end
%     xlabel(['Frame: ', num2str(k)])
%     hold off
%     pause(0.05);
% end
% 
% function z = messeBallPos(k)
%     persistent zSaved
%     if isempty(zSaved)
%         data = load('MessungenBallPosition.mat');
%         zSaved = data.zSaved;
%     end
%     if k >= 1 && k <= size(zSaved, 1)
%         z = zSaved(k, :)';
%     else
%         z = [NaN; NaN];
%     end
% end
% 
% function x = UnscentedKalmanFilter(z, dt)
%     persistent x_prev P_prev initialized kappa
% 
%     g = 300;
% 
%     if isempty(initialized)
%         x_prev = [130; 0; 10; 0];
%         P_prev = diag([100, 50, 100, 50]);
%         kappa = 0;
%         initialized = 1;
%     end
% 
%     n = 4;
%     Q = diag([1, 0.1, 1, 10]);
%     R = diag([5, 5]);
% 
%     [Xi, W] = SigmaPunkte(x_prev, P_prev, kappa);
% 
%     Xi_pred = zeros(n, 2*n+1);
%     for i = 1:(2*n+1)
%         x_temp = Xi(:, i);
%         Xi_pred(:, i) = [x_temp(1) + x_temp(2)*dt; 
%                          x_temp(2); 
%                          x_temp(3) + x_temp(4)*dt; 
%                          x_temp(4) + g*dt];
%     end
% 
%     [x_pred, P_pred] = UT(Xi_pred, W, Q);
% 
%     if all(~isnan(z))
%         [Xi_pred_new, W_new] = SigmaPunkte(x_pred, P_pred, kappa);
% 
%         Zi = [Xi_pred_new(1,:); Xi_pred_new(3,:)];
% 
%         [z_pred, Pzz] = UT(Zi, W_new, R);
% 
%         Pxz = zeros(n, 2);
%         for i = 1:(2*n+1)
%             Pxz = Pxz + W_new(i) * (Xi_pred_new(:, i) - x_pred) * (Zi(:, i) - z_pred)';
%         end
% 
%         K = Pxz / Pzz;
%         x = x_pred + K * (z - z_pred);
%         P = P_pred - K * Pzz * K';
%     else
%         x = x_pred;
%         P = P_pred;
%     end
% 
%     x_prev = x;
%     P_prev = P;
% end
% 
% x20 = xSaved(:, 20)
% x40 = xSaved(:, 40)
% x59 = xSaved(:, 59)
