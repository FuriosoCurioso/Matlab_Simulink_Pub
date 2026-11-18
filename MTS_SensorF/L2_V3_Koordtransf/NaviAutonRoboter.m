% Transformation Welt- in Roboterkoordinaten
%% Startpose
pRobotWorld = randi([-5 5], [2 1])   % Roboterposition in Weltkoordinaten [-5 5] m
theta = 360*rand                     % Rotation (Kurs) des Roboters in deg
pObjectWorld = randi([-5 5], [2 1])  % Objektposition in Weltkoordinaten [-5 5] m
%% Koordinatentransformation - Navigation eines Autonomen Mobilen Roboters (AMR)
% Schritt: Transformation von Weltkoordinaten in Roboterkoordinaten
% Eingangsgrößen: Zufaellige Roboterpose und Objektposition im Welt-KOS
% Ergebnisgrößen: Objektposition im Roboter-KOS nach mehreren Bewegungen
clear all ;clc; close all;
%% Startpose
pRobotWorld = randi([-5 5], [2 1]); % Roboterposition in Weltkoordinaten [-5 5] m
theta = 360 * rand; % Rotation (Kurs) des Roboters in deg
pObjectWorld = randi([-5 5], [2 1]); % Objektposition in Weltkoordinaten [-5 5] m

% OUTPUT Startparameter
disp('=== AMR Navigation - Koordinatentransformation ===')
disp(['Roboter Startposition (Welt-KOS): [', ...
    num2str(pRobotWorld(1)), ', ', num2str(pRobotWorld(2)), '] m'])
disp(['Roboter Startkurs: ', num2str(theta), ' deg'])
disp(['Objekt Position (Welt-KOS): [', ...
    num2str(pObjectWorld(1)), ', ', num2str(pObjectWorld(2)), '] m'])
disp(' ')

%% ALLOCATE Speicherplatz
pRoboterPose = zeros(3, 6); % [x; y; theta] fuer 6 Posen
pObjectRobot = zeros(2, 6); % Objektposition im Roboter-KOS

%% Figur vorbereiten
hfigure = figure('Name', 'AMR Navigation', 'NumberTitle', 'off');

%% Hauptschleife (6 Iterationen)
for i = 1:6
    % STORE Roboterpose speichern
    pRoboterPose(:, i) = [pRobotWorld(:, 1); theta];
    
    % TRANSFORM Transformation berechnen
    T = KOSTrafo(pRobotWorld, theta);
    
    % CALCULATE Objektposition im Roboter-KOS berechnen
    % Objektvektor im Welt-KOS (homogen)
    pObjectWorldHom = [pObjectWorld; 1];
    
    % Inverse Transformation: Welt-KOS -> Roboter-KOS
    % D_rw = inv(D_wr)
    pObjectRobotHom = inv(T) * pObjectWorldHom;
    
    % Extrahiere kartesische Koordinaten
    pObject = pObjectRobotHom(1:2);
    
    % STORE Ermittelte Positionen sichern
    pObjectRobot(:, i) = pObject;
    
    %% PLOT Welt-KOS
    subplot(1, 2, 1)
    hold on
    PlotBot(pRobotWorld, theta)
    plot(pObjectWorld(1), pObjectWorld(2), 'sr', 'MarkerSize', 8, ...
        'MarkerFaceColor', 'r')
    xlabel('x in m')
    ylabel('y in m')
    axis equal
    limMax = 6;
    xlim([-limMax limMax])
    ylim([-limMax limMax])
    quiver(0, 0, 5, 0, 'Color', 'blue', 'LineWidth', 2)
    quiver(0, 0, 0, 5, 'Color', 'blue', 'LineWidth', 2)
    text(-0.2, 6, 'y_W', 'FontSize', 12)
    text(6, 0, 'x_W', 'FontSize', 12)
    title('Welt-Koordinatensystem')
    grid minor
    
    %% PLOT Roboter-KOS
    subplot(1, 2, 2)
    hold on
    plot(pObjectRobot(1, :), pObjectRobot(2, :), 'sr', 'MarkerSize', 8, ...
        'MarkerFaceColor', 'r')
    
    % DRAW Verbindungslinie zwischen aufeinanderfolgenden Positionen
    if i > 1
        dx = pObjectRobot(1, i) - pObjectRobot(1, i - 1);
        dy = pObjectRobot(2, i) - pObjectRobot(2, i - 1);
        quiver(pObjectRobot(1, i - 1), pObjectRobot(2, i - 1), ...
            dx, dy, 0, 'Color', 'red', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
    end
    
    xlabel('x in m')
    ylabel('y in m')
    axis equal
    xlim([-limMax limMax])
    ylim([-limMax limMax])
    quiver(0, 0, 5, 0, 'Color', 'blue', 'LineWidth', 2)
    quiver(0, 0, 0, 5, 'Color', 'blue', 'LineWidth', 2)
    text(-0.2, 6, 'y_R', 'FontSize', 12)
    text(6, 0, 'x_R', 'FontSize', 12)
    title('Roboter-Koordinatensystem')
    grid minor
    
    %% UPDATE Roboter bewegen (vor letzter Iteration)
    if i < 6
        [pRobotWorld, theta] = BewegeRoboter(pRobotWorld, theta);
    end
end

hold off

%% OUTPUT Endergebnisse
disp('=== Ergebniszusammenfassung ===')
disp('Roboter-Trajektorie (Welt-KOS):')
disp(['  Start: [', num2str(pRoboterPose(1, 1)), ', ', ...
    num2str(pRoboterPose(2, 1)), '] m, Kurs: ', ...
    num2str(pRoboterPose(3, 1)), ' deg'])
disp(['  Ende:  [', num2str(pRoboterPose(1, 6)), ', ', ...
    num2str(pRoboterPose(2, 6)), '] m, Kurs: ', ...
    num2str(pRoboterPose(3, 6)), ' deg'])
disp(' ')
disp('Objekt-Trajektorie im Roboter-KOS:')
disp(['  Start: [', num2str(pObjectRobot(1, 1)), ', ', ...
    num2str(pObjectRobot(2, 1)), '] m'])
disp(['  Ende:  [', num2str(pObjectRobot(1, 6)), ', ', ...
    num2str(pObjectRobot(2, 6)), '] m'])

%% Transformationsfunktion
function Dwr = KOSTrafo(pRobotWorld, theta)
    % KOSTrafo erzeugt homogene Transformationsmatrix
    % vom Roboter-KOS zum Welt-KOS
    % Input: pRobotWorld - Roboterposition im Welt-KOS [x; y]
    %        theta - Roboterausrichtung in Grad
    % Output: Dwr - Homogene Transformationsmatrix 3x3 (2D)
    
    % CONVERT Winkel von Grad in Radiant
    thetaRad = deg2rad(theta);
    
    % SETUP Rotationsmatrix (2D)
    R = [cos(thetaRad), -sin(thetaRad);
         sin(thetaRad),  cos(thetaRad)];
    
    % SETUP Translationsvektor
    T = pRobotWorld; % [x; y]
    
    % ASSEMBLE Homogene Transformationsmatrix
    % D_wr transformiert vom Roboter-KOS ins Welt-KOS
    Dwr = [R, T;
           0, 0, 1];
end

%% Hilfsfunktionen (unverändert)
function PlotBot(pRobotWorld, theta)
    % PlotBot zeichnet Roboter als Punkt mit Richtungspfeil
    % Input: pRobotWorld - Position [x; y] in m
    %        theta - Ausrichtung in Grad
    
    fLaenge = 0.4; % Pfeillänge in m
    
    % DRAW Roboter als blauen Kreis
    plot(pRobotWorld(1), pRobotWorld(2), 'ob', 'MarkerSize', 8, ...
        'MarkerFaceColor', 'b')
    
    % DRAW Richtungspfeil
    line([pRobotWorld(1), pRobotWorld(1) + fLaenge * cosd(theta)], ...
         [pRobotWorld(2), pRobotWorld(2) + fLaenge * sind(theta)], ...
         'Color', 'blue', 'LineWidth', 2)
end

function [pRobotWorld, theta] = BewegeRoboter(pRobotWorld, theta)
    % BewegeRoboter bewegt Roboter vorwaerts mit zufaelliger Drehung
    % Input: pRobotWorld - aktuelle Position [x; y]
    %        theta - aktuelle Ausrichtung in Grad
    % Output: pRobotWorld - neue Position
    %         theta - neue Ausrichtung
    
    persistent s dTheta
    
    % INITIALIZE beim ersten Aufruf
    if isempty(s)
        s = 0.5; % Schrittweite in m
        dTheta = (20 * rand - 10); % Zufaellige Drehung [-10, +10] deg
    end
    
    % UPDATE Ausrichtung
    theta = theta + dTheta;
    
    % UPDATE Position (Vorwaertsbewegung in Blickrichtung)
    pRobotWorld = pRobotWorld + [s * cosd(theta); s * sind(theta)];
end
