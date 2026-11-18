close all; clear all; clc;

%% Bell Rocket Belt — TWR-Analyse
% Systemparameter
g         = 9.81;           % Erdbeschleunigung [m/s^2]
F_nom     = 1250;           % Nennschub [N]
F_max     = 1333;           % Maximalschub [N]
Isp       = 130;            % Spezifischer Impuls [s]
m_jetpack = 30.6;           % Jetpack-Leermasse [kg]
rho_fuel  = 1.39;           % Dichte H2O2 90% [kg/L]
V_tank    = 19.0;           % Tankvolumen [L]
m_fuel    = V_tank * rho_fuel;      % 26.41 kg Treibstoff
% ve       = Isp * g;                % Effektive Ausstroemgeschwindigkeit [m/s]
% mdot_nom = F_nom / (Isp * g);     % Treibstoffmassenfluss bei Nennschub [kg/s]
% mdot_max = F_max / (Isp * g);     % Treibstoffmassenfluss bei Maximalschub [kg/s]

%% Pilotgewichte
% Szenarien: Pilotenmasse
m_pilot_vec = [65.0, 75.0, 85.0];
n_sc        = length(m_pilot_vec);
farben      = {[0.2 0.6 1], [0.0 0.8 0.3], [1 0.4 0.1]};

%% Abgeleitete TWR-Kennwerte
m_total_vec = m_pilot_vec + m_jetpack + m_fuel;  % Startmasse [kg]
W_total_vec = m_total_vec * g;                   % Gewichtskraft [N]
twr_max_vec = F_max ./ W_total_vec;     % TWR bei Maximalschub
twr_nom_vec = F_nom ./ W_total_vec;     % TWR bei Nennschub

% Command Window Systemparameter
fprintf('  %s\n', repmat('-', 1, 60));
fprintf(' *** Bell Rocket Belt — Systemparameter aus Wikipedia ***\n');
fprintf('  %s\n', repmat('-', 1, 60));
fprintf('  %-12s = %-8.2f  %-8s  (%s)\n',  'g',        g,        'm/s^2', 'Erdbeschleunigung');
fprintf('  %-12s = %-8d  %-8s  (%s)\n',    'F_max',     F_max,    'N',     'Maximalschub');
fprintf('  %-12s = %-8d  %-8s  (%s)\n',    'F_nom',     F_nom,    'N',     'Nennschub');
% fprintf('  %-12s = %-8d  %-8s  (%s)\n',    'Isp',       Isp,      's',     'Spezifischer Impuls');
% fprintf('  %-12s = %-8.1f  %-8s  (%s)\n',  've',        ve,       'm/s',   'Effektive Ausstroemgeschwindigkeit');
% fprintf('  %-12s = %-8.2f  %-8s  (%s)\n',  'm_jetpack', m_jetpack,'kg',    'Jetpack-Leermasse');
% fprintf('  %-12s = %-8.2f  %-8s  (%s)\n',  'rho_fuel',  rho_fuel, 'kg/L',  'Dichte H2O2 90%');
% fprintf('  %-12s = %-8.2f  %-8s  (%s)\n',  'V_tank',    V_tank,   'L',     'Tankvolumen');
fprintf('  %-12s = %-8.2f  %-8s  (%s)\n',  'm_fuel',    m_fuel,   'kg',    'Treibstoffmasse');
% fprintf('  %-12s = %-8.4f  %-8s  (%s)\n',  'mdot_nom',  mdot_nom, 'kg/s',  'Massenfluss bei Nennschub');
% fprintf('  %-12s = %-8.4f  %-8s  (%s)\n',  'mdot_max',  mdot_max, 'kg/s',  'Massenfluss bei Maximalschub');
fprintf('  %-12s = %-8.2f  %-8s  (%s)\n', 'm_hover',  F_nom/g,  'kg',    'TWR=1 bei Nennschub');

%% Command Window TWR-Tabelle
fprintf('  %s\n', repmat('-', 1, 60));
fprintf('  %-8s %-8s %-8s %-8s %-8s\n', ...
        'Pilot[kg]','Gesamtm.[kg]','Gewichtskr.[N]','TWR_max[-]','TWR_nom[-]');
fprintf('  %s\n', repmat('-', 1, 60));
for i = 1:n_sc
    fprintf('  %-12.0f %-12.2f %-12.1f %-12.3f %-12.3f\n', ...
            m_pilot_vec(i), m_total_vec(i), ...
            W_total_vec(i), twr_max_vec(i), twr_nom_vec(i));
end

%% TWR-Analyse
fuel_axis = linspace(0, m_fuel, 300);
figure(1);
set(gcf, 'Color', 'w', 'Position', [60 500 1100 560], ...
         'Name', 'Fig.1 — TWR-Analyse: Pilotgewicht vs. Schubkraft');
% Subplot links: Balkendiagramm Startgewicht vs. Schubkraefte
subplot(1, 2, 1);
hold on; box on; grid on;
% Horizontale Referenzlinien fuer F_max und F_nom
yline(F_max, 'r-',  'LineWidth', 1.5, ...
      'Label', sprintf('F_{max} = %d N', F_max), ...
      'LabelHorizontalAlignment', 'left', 'FontSize', 8, ...
      'HandleVisibility', 'off');    % 'off' = nicht in Legende erscheinen
yline(F_nom, 'b--', 'LineWidth', 1.0, ...
      'Label', sprintf('F_{nom} = %d N', F_nom), ...
      'LabelHorizontalAlignment', 'left', 'FontSize', 8, ...
      'HandleVisibility', 'off');
% Balken fuer jeden Piloten, eingefaerbt nach Szenariofarbe
b = bar(1:n_sc, W_total_vec, 0.45, 'FaceColor', 'flat');
for i = 1:n_sc
    b.CData(i,:) = farben{i};  % Balkenfarbe setzen

    % Beschriftung oberhalb des Balkens: Gewichtskraft und Gesamtmasse
text(i, W_total_vec(i) + 8, ...
     sprintf('%.0f N\n\nm_{ges}=%.0f kg', W_total_vec(i), m_total_vec(i)), ...
     'HorizontalAlignment', 'center', 'FontSize', 8, ...
     'Color', 'k');

    % Beschriftung im Balken: TWR-Werte 
text(i, W_total_vec(i) * 0.5, ...
     sprintf('TWR_{max}=%.3f\n\nTWR_{nom}=%.3f', twr_max_vec(i), twr_nom_vec(i)), ...
     'HorizontalAlignment', 'center', 'FontSize', 8, ...
     'Color', 'black');
end

xticks(1:n_sc);
xticklabels([]);   % Standard-Labels deaktivieren
ax = gca;

for i = 1:n_sc
    text(i, ax.YLim(1) - max(W_total_vec) * 0.06, ...
         sprintf('Pilot %.0f kg', m_pilot_vec(i)), ...
         'HorizontalAlignment', 'center', ...
         'FontSize', 11, ...
         'FontWeight', 'bold', ...
         'Color', 'k', ...
         'Clipping', 'off');
end

ylabel('Gewichtskraft [N]', 'FontSize', 9);
title('Startgewicht vs. Schubkräfte', 'FontSize', 11);
ylim([0, max(W_total_vec) * 1.2]);
% rechts: TWR-Verlauf über Treibstoffverbrauch
subplot(1, 2, 2);
hold on; box on; grid on;

for i = 1:n_sc
    m_now = m_total_vec(i) - fuel_axis;
    % F_max: durchgehende Linie MIT Legendeneintrag
    plot(fuel_axis, F_max ./ (m_now * g), '-', ...
         'Color', farben{i}, 'LineWidth', 2.0, ...
         'DisplayName', sprintf('Pilot %.0f kg | TWR_{max,0}=%.3f', ...
                                m_pilot_vec(i), twr_max_vec(i)));

    % F_nom: gestrichelte Linie OHNE Legendeneintrag
    plot(fuel_axis, F_nom ./ (m_now * g), '--', ...
         'Color', farben{i} * 0.75, 'LineWidth', 1.2, ...
         'HandleVisibility', 'off');
end

yline(1.0, 'k-', 'LineWidth', 1.3, ...
      'Label', 'TWR = 1', ...
      'LabelHorizontalAlignment', 'left', ...
      'FontSize', 10, ...
      'HandleVisibility', 'off');

for i = 1:n_sc
    %  Hover-Punkt bei F_max (Dreieck oben, gefüllt)
    fuel_hover_max = m_total_vec(i) - F_max / g;
    if fuel_hover_max >= 0 && fuel_hover_max <= m_fuel
        plot(fuel_hover_max, 1.003, 'v', 'Color', farben{i}, ...
             'MarkerSize', 4, 'MarkerFaceColor', farben{i}, ...
             'HandleVisibility', 'off');
        text(fuel_hover_max + 0.5, 1.012, ...
             sprintf('F_{max}: %.1f kg', fuel_hover_max), ...
             'FontSize', 8, 'Color', farben{i});
    end
end

xline(m_fuel, 'k--', 'LineWidth', 1.5, ...
      'Label', 'Tank leer', ...
      'LabelHorizontalAlignment', 'left', 'FontSize', 9, ...
      'HandleVisibility', 'off');

xlabel('Verbrauchter Treibstoff [kg]', 'FontSize', 11,'FontWeight', 'bold');
ylabel('TWR = F / (m \cdot g)',        'FontSize', 9);
title('TWR-Verlauf  (-- F_{nom} | -F_{max})', 'FontSize', 11);
legend('Location', 'northwest', 'FontSize', 9,'FontWeight', 'bold');
xlim([0, m_fuel * 1.05]);

sgtitle(sprintf( ...
    'TWR-Analyse Bell Rocket Belt | F_{max}= %d N | F_{nom}= %d N | m_{Jetpack}= %.0f kg', ...
    F_max, F_nom, m_jetpack + m_fuel), ...
    'FontSize', 12, 'FontWeight', 'bold');
