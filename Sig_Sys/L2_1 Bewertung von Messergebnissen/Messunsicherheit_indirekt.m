close all; clear all; clc;

%% Eingangsgrößen:
mT = 1.75647 % Bestwert der Schwingungsdauer in s
uT = 0.0003634 % Messunsicherheit in s

ml = 0.7675 % Bestwert der Pendellänge in m
ul = 0.0004263 % Messunsicherheit in m


%% Bestwert für die Erdbeschleunigung,
mg = 4*pi^2*ml/(mT^2) % in m/s^2


% Standardunsicherheit
uC_Abs = mg*sqrt((ul/ml)^2 + (2*uT/mT)^2) % absolut in m/s^2
uC_Rel = (uC_Abs/mg)*100 % relativ in %


%% Erweitertes Messergebnis der indirekten Messung
k = 2; % Grad des Vertrauens
uAbs = k*uC_Abs % absolute erweiterte Messunsicherheit
uRel = (uAbs/mg)*100 % relativeerweiterte Messunsicherheit


%% Darstellung der Ergebnisse im Command Window
disp('Erweitertes Messergebnis der indirekten Messung:')

fprintf('mT = %.5f s\n', mT)
fprintf('uT = %.7f s\n', uT)
fprintf('ml = %.4f m\n', ml)
fprintf('ul = %.7f m\n', ul)
fprintf('mg = %.4f m/s^2\n', mg)
fprintf('uC_Abs = %.7f m/s^2\n', uC_Abs)
fprintf('uC_Rel = %.4f %%\n', uC_Rel)
fprintf('k = %d\n', k)
fprintf('uAbs = %.6f m/s^2\n', uAbs)
fprintf('uRel = %.4f %%\n', uRel)
fprintf('g = (%.4f +- %.6f) m/s^2\n', mg, uAbs)


%% Ergebisplot
gWahr = 9.81;

% h: Handle auf das Figure-Objekt → wird für Position/Größe (aPos) benötigt
h = figure;

% Schritt: Figurgröße und -position setzen  [left bottom width height] in Pixeln
set(h, 'Position', [681 407 772 692]);

ax =axes;
hold(ax,'on')
    

xlim([9.75 9.85])
ylim([0 1])

hWahr = xline(gWahr,'--r','LineWidth',2);
hmg = xline(mg,'-','Color',[0.5 0.5 0.5],'LineWidth',2);
hUc1 = xline(mg-uC_Abs,'-b','LineWidth',2);
hUc2 = xline(mg+uC_Abs,'-b','LineWidth',2);
hUc2.Annotation.LegendInformation.IconDisplayStyle = 'off';
hU1 = xline(mg-uAbs,'-g','LineWidth',2);
hU2 = xline(mg+uAbs,'-g','LineWidth',2);
hU2.Annotation.LegendInformation.IconDisplayStyle = 'off';

xlabel('Erdbeschleunigung in {m}/{s^2}')
legend([hWahr hmg hUc1 hU1], ...
    {'Wahrer Wert', ...
     sprintf('{g} = %.3f {m}/{s^2}', mg), ...
     sprintf('u_C(g) = %.6f {m}/{s^2}', uC_Abs), ...
     sprintf('u_{Abs} = %.6f {m}/{s^2}  (k=%d)', uAbs, k)}, ...
    'Location','northwest')

box on
set(gca,'YTick',0:0.1:1)
hold(ax,'off')
