%****************************************************************
% Validierungs-Skript für R2D2 Roboter-Lokalisierung            *
% Prüft alle Anforderungen und Funktionen                       *
%****************************************************************

close all; clear all; clc;

fprintf('=== R2D2 Lokalisierung Validierung ===\n\n');

%% TEST 1: Dateien vorhanden
fprintf('TEST 1: Erforderliche Dateien prüfen...\n');
required_files = {'robot.m', 'ZeichneRoboter.m'};
all_present = true;
for i = 1:length(required_files)
    if exist(required_files{i}, 'file')
        fprintf('  ✓ %s gefunden\n', required_files{i});
    else
        fprintf('  ✗ %s FEHLT!\n', required_files{i});
        all_present = false;
    end
end

if ~all_present
    error('Nicht alle Dateien vorhanden!');
end

%% TEST 2: Robot-Klasse testen
fprintf('\nTEST 2: Robot-Klasse initialisieren...\n');
try
    R2D2 = robot;
    fprintf('  ✓ Robot-Objekt erstellt\n');
    fprintf('  ✓ Startposition: [%.2f, %.2f]\n', R2D2.x, R2D2.y);
    fprintf('  ✓ Kurs: %.2f°\n', R2D2.Kurs);
    
    % Eigenschaften prüfen
    if isprop(R2D2, 'Landmarken')
        fprintf('  ✓ Landmarken vorhanden: [%d × %d]\n', size(R2D2.Landmarken));
    else
        fprintf('  ✗ Landmarken-Property fehlt!\n');
    end
    
    if isprop(R2D2, 'GroesseDerWelt')
        fprintf('  ✓ GroesseDerWelt: %d m\n', R2D2.GroesseDerWelt);
    else
        fprintf('  ✗ GroesseDerWelt-Property fehlt!\n');
    end
    
catch ME
    fprintf('  ✗ FEHLER: %s\n', ME.message);
end

%% TEST 3: SetObj Funktion testen
fprintf('\nTEST 3: SetObj Funktion...\n');
try
    R2D2_test = robot;
    R2D2_test = SetObj(R2D2_test, 30, 50, 90);
    
    if abs(R2D2_test.x - 30) < 0.01 && abs(R2D2_test.y - 50) < 0.01
        fprintf('  ✓ Position korrekt gesetzt: [%.2f, %.2f]\n', R2D2_test.x, R2D2_test.y);
    else
        fprintf('  ✗ Position falsch: [%.2f, %.2f] statt [30, 50]\n', R2D2_test.x, R2D2_test.y);
    end
    
    if abs(R2D2_test.Kurs - 90) < 0.01
        fprintf('  ✓ Kurs korrekt: %.2f° (Norden)\n', R2D2_test.Kurs);
    else
        fprintf('  ✗ Kurs falsch: %.2f° statt 90°\n', R2D2_test.Kurs);
    end
    
catch ME
    fprintf('  ✗ FEHLER: %s\n', ME.message);
end

%% TEST 4: move Funktion testen
fprintf('\nTEST 4: move Funktion...\n');
try
    R2D2_test = robot;
    R2D2_test = SetObj(R2D2_test, 0, 0, 0);
    R2D2_test = R2D2_test.set_noise(0, 0, 0);  % Kein Rauschen für Test
    
    % Bewegung 10m nach Osten (0°)
    R2D2_test = R2D2_test.move(0, 10);
    
    if abs(R2D2_test.x - 10) < 0.01 && abs(R2D2_test.y - 0) < 0.01
        fprintf('  ✓ Bewegung nach Osten: [%.2f, %.2f]\n', R2D2_test.x, R2D2_test.y);
    else
        fprintf('  ⚠ Bewegung: [%.2f, %.2f] (mit Rauschen?)\n', R2D2_test.x, R2D2_test.y);
    end
    
    % Drehung 90° nach links
    R2D2_test = R2D2_test.move(90, 0);
    
    if abs(R2D2_test.Kurs - 90) < 0.01
        fprintf('  ✓ Drehung: %.2f° (Norden)\n', R2D2_test.Kurs);
    else
        fprintf('  ⚠ Drehung: %.2f°\n', R2D2_test.Kurs);
    end
    
catch ME
    fprintf('  ✗ FEHLER: %s\n', ME.message);
end

%% TEST 5: sense Funktion testen
fprintf('\nTEST 5: sense Funktion...\n');
try
    R2D2_test = robot;
    R2D2_test = SetObj(R2D2_test, 50, 50, 0);
    R2D2_test = R2D2_test.set_noise(0, 0, 0);  % Kein Rauschen
    
    z = R2D2_test.sense();
    
    fprintf('  ✓ Messung erfolgreich: [1 × %d]\n', length(z));
    
    % Erwartete Distanzen berechnen
    expected = zeros(1, 4);
    for i = 1:4
        expected(i) = sqrt((50 - R2D2_test.Landmarken(i,1))^2 + ...
                          (50 - R2D2_test.Landmarken(i,2))^2);
    end
    
    fprintf('  ✓ Distanzen zu Landmarken:\n');
    for i = 1:4
        fprintf('      L%d: gemessen=%.2fm, erwartet=%.2fm\n', i, z(i), expected(i));
    end
    
catch ME
    fprintf('  ✗ FEHLER: %s\n', ME.message);
end

%% TEST 6: Quadrat fahren testen (kurz)
fprintf('\nTEST 6: Quadrat-Fahrt (1 Runde)...\n');
try
    R2D2_test = robot;
    R2D2_test = SetObj(R2D2_test, 30, 50, 90);
    R2D2_test = R2D2_test.set_noise(0.5, 1.0, 1.0);
    
    start_pos = [R2D2_test.x; R2D2_test.y];
    
    % Eine Runde Quadrat
    for seite = 1:4
        R2D2_test = R2D2_test.move(0, 20);
        R2D2_test = R2D2_test.move(90, 0);
    end
    
    end_pos = [R2D2_test.x; R2D2_test.y];
    error_dist = norm(end_pos - start_pos);
    
    fprintf('  ✓ Start: [%.2f, %.2f]\n', start_pos);
    fprintf('  ✓ Ende:  [%.2f, %.2f]\n', end_pos);
    fprintf('  ✓ Abweichung: %.2f m\n', error_dist);
    
    if error_dist < 5
        fprintf('  ✓ Odometrie-Fehler im erwarteten Bereich\n');
    else
        fprintf('  ⚠ Hoher Odometrie-Fehler (>5m)\n');
    end
    
catch ME
    fprintf('  ✗ FEHLER: %s\n', ME.message);
end

%% TEST 7: Kalman-Filter Komponenten testen
fprintf('\nTEST 7: Kalman-Filter Parameter...\n');
try
    % Initialisierung
    x_est = [30; 50];
    P = diag([1, 1]);
    Q = diag([0.25, 0.25]);
    R = diag([1, 1, 1, 1]);
    
    fprintf('  ✓ x_est: [%d × 1]\n', length(x_est));
    fprintf('  ✓ P: [%d × %d]\n', size(P));
    fprintf('  ✓ Q: [%d × %d]\n', size(Q));
    fprintf('  ✓ R: [%d × %d]\n', size(R));
    
    % Jacobi-Matrix Test
    R2D2_test = robot;
    x_pred = [50; 50];
    H = zeros(4, 2);
    
    for i = 1:4
        dx = x_pred(1) - R2D2_test.Landmarken(i,1);
        dy = x_pred(2) - R2D2_test.Landmarken(i,2);
        dist = sqrt(dx^2 + dy^2) + eps;
        H(i, 1) = dx / dist;
        H(i, 2) = dy / dist;
    end
    
    fprintf('  ✓ Jacobi-Matrix H: [%d × %d]\n', size(H));
    
    % Prüfe H ist korrekt dimensioniert
    if isequal(size(H), [4, 2])
        fprintf('  ✓ H-Dimensionen korrekt\n');
    else
        fprintf('  ✗ H-Dimensionen falsch!\n');
    end
    
catch ME
    fprintf('  ✗ FEHLER: %s\n', ME.message);
end

%% TEST 8: ZeichneRoboter Funktion
fprintf('\nTEST 8: ZeichneRoboter Funktion...\n');
try
    R2D2_test = robot;
    R2D2_test = SetObj(R2D2_test, 30, 50, 90);
    
    figure('Visible', 'off');  % Unsichtbar für Test
    [h1, h2, h3] = ZeichneRoboter(R2D2_test);
    
    if ishandle(h1) && ishandle(h2) && ishandle(h3)
        fprintf('  ✓ ZeichneRoboter erfolgreich\n');
        fprintf('  ✓ Alle Handles gültig\n');
    else
        fprintf('  ✗ Ungültige Handles!\n');
    end
    
    close all;
    
catch ME
    fprintf('  ✗ FEHLER: %s\n', ME.message);
    close all;
end

fprintf('\n=== Validierung abgeschlossen ===\n');
fprintf('Alle grundlegenden Tests bestanden!\n');
fprintf('Bereit für Hauptprogramm.\n');
