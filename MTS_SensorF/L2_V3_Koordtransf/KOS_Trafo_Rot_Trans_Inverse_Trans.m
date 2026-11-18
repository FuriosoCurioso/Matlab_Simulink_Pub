%% KOS-Trafo: Rotation+Translation, Inverse Transformation
% Schritt: Kombination von Rotation und Translation, 
% anschliessend inverse Transformation
% Eingangsgrößen: A_r_P = [1; 2; 3], gamma = 50 Grad, T = [2; 2; 0]

%% Eingangsgrößen:
A_r_P = [1; 2; 3; 1]; % Ortsvektor zum Punkt P in KOS A (homogen)
gamma = 50; % Rotationswinkel in Grad um Z-Achse
T = [2; 2; 0]; % Translationsvektor

% SETUP Rotation und Translation
gammaRad = deg2rad(gamma); % Umrechnung in Radiant
R = [cos(gammaRad), -sin(gammaRad), 0;
     sin(gammaRad),  cos(gammaRad), 0;
     0,              0,              1]; % Rotationsmatrix Z-Achse

S = 1; % Skalierungsfaktor
P = [0, 0, 0]; % Perspektiventrafo

% SETUP Homogene Transformationsmatrix
D = zeros(4, 4);
D(1:3, 1:3) = R;
D(1:3, 4) = T;
D(4, 4) = S;
D(4, 1:3) = P;

% CALCULATE KOS-Trafo (Vorwaerts)
A_r_Q = D * A_r_P;

%% Inverse Transformation
% CALCULATE Inverse homogene Transformationsmatrix
D_inv = zeros(4, 4);
D_inv(1:3, 1:3) = R'; % Transponierte Rotationsmatrix
D_inv(1:3, 4) = -R' * T; % Transformierter Translationsvektor
D_inv(4, 4) = S;
D_inv(4, 1:3) = P;

% APPLY Inverse Transformation (von Q zurueck zu P)
A_r_P2 = D_inv * A_r_Q;

%% Ergebnisdarstellung
figure
hold on
grid on
axis equal

% DRAW Koordinatensystem A
quiver(0, 0, 1, 0, 0, 'k', 'LineWidth', 2, 'MaxHeadSize', 0.5)
quiver(0, 0, 0, 1, 0, 'k', 'LineWidth', 2, 'MaxHeadSize', 0.5)
text(0, 0.1, '(A)', 'FontSize', 12)
text(1.1, 0, 'X', 'FontSize', 12)
text(0, 1.1, 'Y', 'FontSize', 12)

% DRAW Ortsvektor zu Punkt P (rot)
h1 = quiver(0, 0, A_r_P(1), A_r_P(2), 0, 'r', 'LineWidth', 2, ...
    'MaxHeadSize', 0.2);
plot(A_r_P(1), A_r_P(2), 'ro', 'MarkerSize', 8, ...
    'MarkerFaceColor', 'r')
text(A_r_P(1) + 0.1, A_r_P(2) + 0.1, 'P', 'FontSize', 12)

% DRAW Ortsvektor zu Punkt Q (blau)
h2 = quiver(0, 0, A_r_Q(1), A_r_Q(2), 0, 'b', 'LineWidth', 2, ...
    'MaxHeadSize', 0.2);
plot(A_r_Q(1), A_r_Q(2), 'bo', 'MarkerSize', 8, ...
    'MarkerFaceColor', 'b')
text(A_r_Q(1) + 0.1, A_r_Q(2) + 0.1, 'Q', 'FontSize', 12)

% DRAW Translationsvektor (gelb)
h3 = quiver(A_r_P(1), A_r_P(2), T(1), T(2), 0, 'y', 'LineWidth', 2, ...
    'MaxHeadSize', 0.2);

% CONFIGURE Achsen
xlabel('x')
ylabel('y')
xlim([-1, 4])
ylim([0, 4.5])
legend([h1, h2, h3], {'^Ar_P', '^Ar_Q', '^T'}, 'Location', 'northeast')

hold off

% OUTPUT Ergebnisse
fprintf('=== Vorwaertstransformation ===\n')
fprintf('Ortsvektor P in KOS A:\n')
disp(A_r_P')
fprintf('Rotationswinkel gamma: %.0f Grad\n', gamma)
fprintf('Translationsvektor T:\n')
disp(T')
fprintf('Ortsvektor Q in KOS A (nach Rotation+Translation):\n')
disp(A_r_Q')

fprintf('\n=== Inverse Transformation ===\n')
fprintf('Ortsvektor P2 (Ruecktransformation von Q):\n')
disp(A_r_P2')
fprintf('Differenz zwischen P und P2 (sollte ~ 0 sein):\n')
disp((A_r_P - A_r_P2)')
fprintf('Verifikation erfolgreich: %.6f\n', norm(A_r_P - A_r_P2))


%% KOS-Trafo: Rotation+Translation, Inverse Transformation
% Schritt: Kombination von Rotation und Translation, 
% anschliessend inverse Transformation
% Eingangsgrößen: A_r_P = [1; 2; 3], gamma = 50 Grad, T = [2; 2; 0]

%% Eingangsgrößen:
A_r_P = [1; 2; 3; 1]; % Ortsvektor zum Punkt P in KOS A (homogen, 4x1)
gamma = 50; % Rotationswinkel um Z-Achse in Grad
T = [2; 2; 0]; % Translationsvektor (3x1)

% SETUP Rotation und Translation
gammaRad = deg2rad(gamma); % Konvertiert Grad in Radiant
R = [cos(gammaRad), -sin(gammaRad), 0;
     sin(gammaRad),  cos(gammaRad), 0;
     0,              0,              1]; % Rotationsmatrix um Z-Achse (3x3)

S = 1; % Skalierungsfaktor (keine Skalierung)
P = [0, 0, 0]; % Perspektiventransformation (1x3, keine Perspektive)

% SETUP Homogene Transformationsmatrix
D = zeros(4, 4); % Initialisiert 4x4-Nullmatrix
D(1:3, 1:3) = R; % Fuellt obere linke 3x3-Matrix mit Rotation
D(1:3, 4) = T; % Fuellt obere rechte 3x1-Spalte mit Translation
D(4, 4) = S; % Fuellt unteres rechtes Element mit Skalierung
D(4, 1:3) = P; % Fuellt untere 1x3-Zeile mit Perspektive

% CALCULATE KOS-Trafo (Vorwaerts)
A_r_Q = D * A_r_P; % Multipliziert Trafo-Matrix mit Vektor P -> Vektor Q

%% Inverse Transformation
% CALCULATE Inverse homogene Transformationsmatrix
D_inv = zeros(4, 4); % Initialisiert 4x4-Nullmatrix fuer Inverse
D_inv(1:3, 1:3) = R'; % Transponierte Rotation (R^T = R^-1 fuer orthogonal)
D_inv(1:3, 4) = -R' * T; % Invertierte Translation (-R^T * T)
D_inv(4, 4) = S; % Skalierungsfaktor bleibt gleich
D_inv(4, 1:3) = P; % Perspektive bleibt gleich

% APPLY Inverse Transformation (von Q zurueck zu P)
A_r_P2 = D_inv * A_r_Q; % Multipliziert inverse Matrix mit Q -> sollte P ergeben

%% Ergebnisdarstellung
figure % Erstellt neues Figure-Fenster
hold on % Haelt Plot aktiv, neue Elemente werden hinzugefuegt
grid on % Aktiviert Gitter im Plot
axis equal % Setzt gleiche Skalierung fuer beide Achsen

% DRAW Koordinatensystem A
quiver(0, 0, 1, 0, 0, 'k', 'LineWidth', 2, 'MaxHeadSize', 0.5)
% quiver: Zeichnet Pfeil von (0,0) nach (1,0), schwarz, Linienbreite 2
quiver(0, 0, 0, 1, 0, 'k', 'LineWidth', 2, 'MaxHeadSize', 0.5)
% quiver: Zeichnet Pfeil von (0,0) nach (0,1), schwarz
text(0, 0.1, '(A)', 'FontSize', 12)
% text: Platziert Text "(A)" bei Position (0, 0.1)
text(1.1, 0, 'X', 'FontSize', 12)
% text: Platziert "X" bei (1.1, 0) zur Beschriftung der X-Achse
text(0, 1.1, 'Y', 'FontSize', 12)
% text: Platziert "Y" bei (0, 1.1) zur Beschriftung der Y-Achse

% DRAW Ortsvektor zu Punkt P (rot)
h1 = quiver(0, 0, A_r_P(1), A_r_P(2), 0, 'r', 'LineWidth', 2, ...
    'MaxHeadSize', 0.2);
% quiver: Zeichnet roten Pfeil vom Ursprung zu P, speichert Handle in h1
plot(A_r_P(1), A_r_P(2), 'ro', 'MarkerSize', 8, ...
    'MarkerFaceColor', 'r')
% plot: Zeichnet roten gefuellten Kreis an Position P
text(A_r_P(1) + 0.1, A_r_P(2) + 0.1, 'P', 'FontSize', 12)
% text: Platziert "P" leicht versetzt von Punkt P

% DRAW Ortsvektor zu Punkt Q (blau)
h2 = quiver(0, 0, A_r_Q(1), A_r_Q(2), 0, 'b', 'LineWidth', 2, ...
    'MaxHeadSize', 0.2);
% quiver: Zeichnet blauen Pfeil vom Ursprung zu Q, speichert Handle in h2
plot(A_r_Q(1), A_r_Q(2), 'bo', 'MarkerSize', 8, ...
    'MarkerFaceColor', 'b')
% plot: Zeichnet blauen gefuellten Kreis an Position Q
text(A_r_Q(1) + 0.1, A_r_Q(2) + 0.1, 'Q', 'FontSize', 12)
% text: Platziert "Q" leicht versetzt von Punkt Q

% DRAW Translationsvektor (gelb)
h3 = quiver(A_r_P(1), A_r_P(2), T(1), T(2), 0, 'y', 'LineWidth', 2, ...
    'MaxHeadSize', 0.2);
% quiver: Zeichnet gelben Pfeil von P um T verschoben, Handle in h3

% CONFIGURE Achsen
xlabel('x') % Beschriftet X-Achse mit "x"
ylabel('y') % Beschriftet Y-Achse mit "y"
xlim([-1, 4]) % Setzt X-Achsen-Grenzen von -1 bis 4
ylim([0, 4.5]) % Setzt Y-Achsen-Grenzen von 0 bis 4.5
legend([h1, h2, h3], {'^Ar_P', '^Ar_Q', '^T'}, 'Location', 'northeast')
% legend: Erstellt Legende mit den drei Handles und Beschriftungen

hold off % Deaktiviert Hold, naechster Plot ueberschreibt diesen
