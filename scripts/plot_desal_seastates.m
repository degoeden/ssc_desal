function fig = plot_desal_seastates(Hs, Tp, production, rr_plus, varargin)
% PLOT_DESAL_SEASTATES  Bubble chart of wave-driven desalination performance.
%
%   fig = plot_desal_seastates(Hs, Tp, production, rr_plus)
%   fig = plot_desal_seastates(Hs, Tp, production, rr_plus, Name, Value, ...)
%
%   Positional inputs (all length-N vectors)
%   ----------------------------------------
%   Hs          Significant wave height (m)
%   Tp          Peak wave period (s)
%   production  Daily water production (m3/day)  -> bubble size
%   rr_plus     Modified recovery ratio RR+ (-)  -> bubble colour
%
%   Optional name-value arguments
%   -----------------------------
%   Labels          Cell array of strings, e.g. {'SS1','SS2',...}  (default: none)
%   Colormap        Colormap name or Nx3 matrix                     (default: 'RdYlGn')
%   MaxBubbleArea   Max marker area in pt^2                         (default: 800)
%   ProductionLabel Legend title for bubble size                    (default: 'm^3/day')
%   RRLabel         Colourbar label                                 (default: 'RR+ (-)')
%   Title           Plot title                                      (default: see below)
%   Ax              Existing axes handle to draw into               (default: new figure)
%
%   Output
%   ------
%   fig             Figure handle
%
%   Example
%   -------
%   fig = plot_desal_seastates(Hs, Tp, production, rr_plus, ...
%             'Labels', cellstr("SS" + string(1:20)));
%   exportgraphics(fig, 'seastate_performance.png', 'Resolution', 150);

    % --- input parsing ---
    p = inputParser;
    addRequired(p, 'Hs',         @(x) isnumeric(x) && isvector(x));
    addRequired(p, 'Tp',         @(x) isnumeric(x) && isvector(x));
    addRequired(p, 'production', @(x) isnumeric(x) && isvector(x));
    addRequired(p, 'rr_plus',    @(x) isnumeric(x) && isvector(x));
    addParameter(p, 'Labels',          [],        @(x) iscell(x) || isstring(x));
    addParameter(p, 'Colormap',        'RdYlGn',  @(x) ischar(x) || isstring(x) || (isnumeric(x) && size(x,2)==3));
    addParameter(p, 'MaxBubbleArea',   800,       @isnumeric);
    addParameter(p, 'ProductionLabel', 'm^3/day', @(x) ischar(x) || isstring(x));
    addParameter(p, 'RRLabel',         'RR+ (-)', @(x) ischar(x) || isstring(x));
    addParameter(p, 'Title',           'Wave-driven desalination — performance across seastates', ...
                                                  @(x) ischar(x) || isstring(x));
    addParameter(p, 'Ax',             [],         @(x) isempty(x) || isa(x,'matlab.graphics.axis.Axes'));
    parse(p, Hs, Tp, production, rr_plus, varargin{:});
    opt = p.Results;

    % --- flatten to column vectors ---
    Hs         = opt.Hs(:);
    Tp         = opt.Tp(:);
    production = opt.production(:);
    rr_plus    = opt.rr_plus(:);
    N = numel(Hs);

    if ~isequal(numel(Tp), numel(production), numel(rr_plus), N)
        error('plot_desal_seastates:inputSize', ...
              'Hs, Tp, production and rr_plus must all be the same length.');
    end

    % --- bubble areas (proportional to production) ---
    area = (production ./ max(production)) .* opt.MaxBubbleArea;

    % --- axes / figure ---
    if isempty(opt.Ax)
        fig = figure('Color', 'w');
        ax  = axes(fig);
    else
        ax  = opt.Ax;
        fig = ax.Parent;
    end

    % --- scatter plot ---
    sc = scatter(ax, Tp, Hs, area, rr_plus, 'filled', ...
        'MarkerEdgeColor', 'w', 'LineWidth', 0.8, 'MarkerFaceAlpha', 0.88);

    % --- colourmap ---
    if ischar(opt.Colormap) || isstring(opt.Colormap)
        colormap(ax, opt.Colormap);
    else
        colormap(ax, opt.Colormap);
    end
    clim(ax, [min(rr_plus), max(rr_plus)]);

    cb = colorbar(ax);
    cb.Label.String   = opt.RRLabel;
    cb.Label.FontSize = 10;
    cb.FontSize       = 9;

    % --- seastate labels inside bubbles ---
    if ~isempty(opt.Labels)
        lbls = opt.Labels;
        if isstring(lbls), lbls = cellstr(lbls); end
        for i = 1:N
            text(ax, Tp(i), Hs(i), lbls{i}, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment',   'middle', ...
                'FontSize', 7, 'FontWeight', 'bold', 'Color', 'w');
        end
    end

    % --- bubble size legend (min / median / max) ---
    ref_prods = [min(production); median(production); max(production)];
    ref_areas = (ref_prods ./ max(production)) .* opt.MaxBubbleArea;
    hold(ax, 'on');
    h_leg = gobjects(3,1);
    for k = 1:3
        h_leg(k) = scatter(ax, NaN, NaN, ref_areas(k), [0.6 0.6 0.6], 'filled', ...
            'MarkerEdgeColor', 'w', 'LineWidth', 0.8);
    end
    legend(ax, h_leg, ...
        {sprintf('%.0f %s', ref_prods(1), opt.ProductionLabel), ...
         sprintf('%.0f %s', ref_prods(2), opt.ProductionLabel), ...
         sprintf('%.0f %s', ref_prods(3), opt.ProductionLabel)}, ...
        'Title', 'Production', ...
        'Location', 'northwest', ...
        'FontSize', 8, 'Box', 'on');
    hold(ax, 'off');

    % --- labels and formatting ---
    xlabel(ax, 'Peak wave period  \itT_p\rm  (s)',          'FontSize', 10);
    ylabel(ax, 'Significant wave height  \itH_s\rm  (m)',   'FontSize', 10);
    title(ax,  opt.Title, 'FontSize', 11);
    grid(ax, 'on');
    ax.GridLineStyle    = '--';
    ax.GridAlpha        = 0.4;
    ax.TickDir          = 'out';
    ax.FontSize         = 9;
    ax.Box              = 'off';

    % pad axes so edge bubbles are not clipped
    x_pad = (max(Tp) - min(Tp)) * 0.08;
    y_pad = (max(Hs) - min(Hs)) * 0.12;
    xlim(ax, [min(Tp) - x_pad,       max(Tp) + x_pad]);
    ylim(ax, [max(0, min(Hs)-y_pad),  max(Hs) + y_pad]);
end


% =========================================================================
%  EXAMPLE SCRIPT  (run this section or save as a separate .m file)
% =========================================================================
%{
% --- Option A: load from a .mat file ---
% Expected variables inside the .mat: Hs, Tp, production, rr_plus
% (and optionally a cell/string array called 'labels')

data = load('my_results.mat');
fig  = plot_desal_seastates(data.Hs, data.Tp, data.production, data.rr_plus, ...
           'Labels', cellstr("SS" + string(1:numel(data.Hs))));
exportgraphics(fig, 'seastate_performance.png', 'Resolution', 150);

% --- Option B: inline example data ---
Hs         = [0.5 0.75 1.0 1.5 1.5 2.0 2.0 2.5 2.5 3.0 ...
              3.0 3.5 3.5 4.0 4.0 4.5 4.5 5.0 5.0 5.5];
Tp         = [5   6    7   7   8   8   9   9  10  10  ...
              11  11  12  12  13  13  14  14  15  15];
production = [20  35  55  80  95 130 150 170 185 200 ...
             210 215 205 190 170 145 120  90  60  35];
rr_plus    = [0.22 0.28 0.33 0.38 0.41 0.44 0.46 0.47 0.47 0.46 ...
              0.44 0.42 0.39 0.36 0.32 0.28 0.24 0.20 0.16 0.12];

fig = plot_desal_seastates(Hs, Tp, production, rr_plus, ...
          'Labels', cellstr("SS" + string(1:20)), ...
          'Colormap', 'RdYlGn', ...
          'RRLabel',  'RR+ (-)');
%}