function xTPF = Tiefpass(x)

% TIEFPASS Tiefpassfilter 1. Ordnung (rekursiver Exponentialfilter)

% Syntax:
%     xTPF = Tiefpass(x)

% Beschreibung:
%     Filtert den Eingangswert x mit einem gleitenden Exponentialfilter.
%     Beim ersten Aufruf werden persistente Variablen initialisiert.

% Eingangswerte:
%     x: Aktueller Messwert (beliebige Einheit)

% Rückgabewerte:
%     xTPF: Gefilterter Ausgangswert (gleiche Einheit wie x)

% Beispiel:
%     xTPF = Tiefpass(0.35)

%% Bleibende Variablen anlegen
persistent prevX alpha

%% Beim ersten Durchlauf Initialisierung
if isempty(alpha)
    prevX = x;      % Letztes Ergebnis
    alpha = 0.95;   % Filterfrequenz/Wichtung
end

%% Tiefpass 1. Ordnung
xTPF  = alpha * prevX + (1 - alpha) * x;
prevX = xTPF;