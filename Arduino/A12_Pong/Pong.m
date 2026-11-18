% CLK: Encoder-Signal A zur Positionsauswertung; DT: E-S B zur Richtungserkennung;

% CLK und DT phasenverschoben: beim drehen ändert sich eines der beiden Signale
% zuerst -> l/r daraus abgeleitet. rotaryEncoder extra bib dafür

% Signalkette: Drehbewegung → Encoderzählwert → ∆n → block_vel → block_pos → Schlägerposition im Plot
% Startsignal: Tasterdruck → bButton → Flankenerkennung → game_on = true
% Hauptaenderung zum Template: KY-040-Steuerung ersetzt Tastatursteuerung 

function Pong
    
    % KY-040: Taster startet Spiel, Drehgeber bewegt Block   
    % Schritt: Arduino und KY-040 einrichten. hEncoder zur Auswertung D2;D3
    hArduino = arduino('COM3', 'Uno', 'Libraries', 'rotaryEncoder');
    hEncoder = rotaryEncoder(hArduino, 'D2','D3');
    stSwPin = 'D4';
    
    configurePin(hArduino, stSwPin, 'Pullup');
    
    % speichert alte Zustaende zur Auswertung
    % Encoder Prinzip: neuer Wert - alter Wert = Aenderung
    nCountAlt = readCount(hEncoder);
    bButtonAlt = false;
    game_on = false;
    
    % Graphics: figure, axes, ball and block
    % Tastaturfunktionen aus Template entfernt; Fkt. Schliessen Fenster
    % bleibt nur
    figure( ...
        'closerequestfcn',@close_window, ...
        'menubar', 'none', ...
        'numbertitle', 'off');
    
    axes( ...
        'position', [0, 0, 1, 1], ...
        'color', 'black',  ...
        'xlim', [-10, 10], ...
        'ylim', [-10, 10]);
  
    ball = line( ...
        'color', 'blue',  ...
        'marker', '.', ...
        'markersize',50);
    
    block = line( 'color', 'green', 'linewidth', 7);
    
    % Numbers: ball/block position and velocity
    
    ball_pos = [ 5,  5];
    ball_vel = [.1, .1];
    
    block_pos = 0;
    block_vel = 0;
     
    % Game loop
       
    program_on = true;
    
    while program_on
        
        % Schritt: Taster startet Spiel, darf aber nicht bei jedem
        % Schleifendurchlauf erneut auslösen -> Flankenerkennung löst nur aus        
        bButton = ~readDigitalPin(hArduino, stSwPin);
        
        if bButton && ~bButtonAlt
            game_on = true;
        end
        
        bButtonAlt = bButton;
        
        % Schritt: Drehgeberposition des KY-040 fuer Blockbewegung auswerten
        % keine absolute Spannung sondern digitale Signalwechsel durch
        % Drehrichtung bestimmen Position
       
        nCount = readCount(hEncoder);
         % Encoder-Zählerdifferenz bestimmt Bewegumg -> skaliert! Anp.?
        block_vel = (nCount - nCountAlt) * .2;
        nCountAlt = nCount;
        
        % Ball bounce if out of bounds left/right/top 
        
        if game_on
            if abs(ball_pos(1)) > 10
                ball_vel(1) = - ball_vel(1);
            end
        
            if ball_pos(2) > 10
                ball_vel(2) = - ball_vel(2); 
            end
        
            % If ball low, check positions then bounce or reset
    
            if ball_pos(2) < - 9
                
                % miss
                if abs(block_pos - ball_pos(1)) > 2
                    
                    ball.Color = rand(1,3);          
                    ball_pos(2) = 9;
                    game_on = false;
                    
                % not miss
                else 
                    ball_vel(2) = - ball_vel(2);
                end
            end
            
            % Update ball numbers
            % erst Taster gedrückt dann Ballbew.
            ball_pos = ball_pos + ball_vel;
        end
        
        % Update block number
        
        block_pos = block_pos + block_vel;
        block_pos = max(min(block_pos, 9), -9);   % begrenzt Mitte Schlaeger->sichtbarkeit!
        
        % Update ball/block graphics objects
        
        set(ball, ...
            'XData', ball_pos(1), ...
            'YData', ball_pos(2));
        
        set(block, ...
            'XData', [ block_pos-1, block_pos+1], ...
            'YData', [ -9, -9]);
        
        % Update screen
        
        pause(.01);
    end

    % If loop was exited, delete figure and Arduino connection
    % entfernt zusaetzlich alte Verbindungen
    delete(gcf);
    delete(hArduino)
    clear hEncoder hArduino;
    
    % Figure window close request function

    function close_window(~,~)
        program_on = 0;
    end
end

