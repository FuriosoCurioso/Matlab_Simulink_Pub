function pong
    
    % Press keyboard left / right to move block
    
    % Graphics: figure, axes, ball and block
    
    figure( ...
        'keypressfcn',    @key_down, ...
        'keyreleasefcn',  @key_up, ...
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
        
        % Ball bounce if out of bounds left/right/top 
        
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
                
            % not miss
            else 
                ball_vel(2) = - ball_vel(2);
            end
        end
        
        % Update ball/block numbers
        
        ball_pos  = ball_pos  + ball_vel;
        block_pos = block_pos + block_vel;
        
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

    % If loop was exited, delete figure
    
    delete(gcf);
    
    % Keyboard functions
    
    function key_down(~, event)
        switch event.Key
            case 'leftarrow',  block_vel = -.2; 
            case 'rightarrow', block_vel =  .2;
        end
    end

    function key_up(~, ~)
        block_vel = 0;
    end

    % Figure window close request function

    function close_window(~,~)
        program_on = 0;
    end
end