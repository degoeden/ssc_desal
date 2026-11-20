function fig = plot_desal_seastates(Hs, Tp, production, rr_plus, varargin)
% PLOT_DESAL_SEASTATES  Bubble chart of wave-driven desalination performance.
%
%   fig = plot_desal_seastates(Hs, Tp, production, rr_plus)
%   fig = plot_desal_seastates(Hs, Tp, production, rr_plus, Name, Value, ...)
%   fig = plot_desal_seastates(Hs, Tp, production, conc, 'ColorBy', 'concentration')
%
%   Positional inputs (all length-N vectors)
%   ----------------------------------------
%   Hs          Significant wave height (m)
%   Tp          Peak wave period (s)
%   production  Daily water production (m3/day)  -> bubble size
%   rr_plus     Modified recovery ratio RR+ (-)  -> bubble colour
%               (or permeate concentration when 'ColorBy' is 'concentration')
%
%   Optional name-value arguments
%   -----------------------------
%   ColorBy         'rr' or 'concentration'. Sets the default colormap
%                   ('nebula' / 'winter') and colourbar label; explicit
%                   'Colormap' / 'RRLabel' values still take precedence.  (default: 'rr')
%   Labels          Cell array of strings, e.g. {'SS1','SS2',...}  (default: none)
%   Colormap        Colormap name or Nx3 matrix                     (default: 'nebula')
%   MaxBubbleArea   Max marker area in pt^2                         (default: 800)
%   ProductionMax   Production (m^3/day) drawn at MaxBubbleArea. Fix this
%                   across plots for comparable bubble sizes.       (default: max(production))
%   CLim            [lo hi] colour limits. Fix this across plots for
%                   comparable colours.                             (default: data range)
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
    addParameter(p, 'ColorBy',         'rr',      @(x) any(strcmpi(x, {'rr','rr+','concentration','brine'})));
    addParameter(p, 'Labels',          [],        @(x) iscell(x) || isstring(x));
    addParameter(p, 'Colormap',        'jet',  @(x) ischar(x) || isstring(x) || (isnumeric(x) && size(x,2)==3));
    addParameter(p, 'MaxBubbleArea',   1600,       @isnumeric);
    addParameter(p, 'ProductionMax',   [],        @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > 0));
    addParameter(p, 'CLim',            [],        @(x) isempty(x) || (isnumeric(x) && numel(x)==2 && x(2) > x(1)));
    addParameter(p, 'ProductionLabel', 'm^3/day', @(x) ischar(x) || isstring(x));
    addParameter(p, 'RRLabel',         'RR+ (-)', @(x) ischar(x) || isstring(x));
    addParameter(p, 'Title',           'Wave-driven desalination — performance across seastates', ...
                                                  @(x) ischar(x) || isstring(x));
    addParameter(p, 'Ax',             [],         @(x) isempty(x) || isa(x,'matlab.graphics.axis.Axes'));
    parse(p, Hs, Tp, production, rr_plus, varargin{:});
    opt = p.Results;

    % --- colour-variable defaults ---
    if strcmpi(opt.ColorBy, 'concentration')
        if ismember('Colormap', p.UsingDefaults), opt.Colormap = 'nebula'; end
        if ismember('RRLabel',  p.UsingDefaults), opt.RRLabel  = 'Permeate concentration (mg/L)'; end
    end

    if strcmpi(opt.ColorBy, 'brine')
        if ismember('Colormap', p.UsingDefaults), opt.Colormap = 'nebula'; end
        if ismember('RRLabel',  p.UsingDefaults), opt.RRLabel  = 'Brine concentration (g/L)'; end
    end

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
    if isempty(opt.ProductionMax)
        prod_max = max(production);
    else
        prod_max = opt.ProductionMax;
        if max(production) > prod_max
            warning('plot_desal_seastates:prodExceedsMax', ...
                'Max production (%.3g) exceeds ProductionMax (%.3g); some bubbles exceed MaxBubbleArea.', ...
                max(production), prod_max);
        end
    end
    area = (production ./ prod_max) .* opt.MaxBubbleArea;

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
    colormap(ax, opt.Colormap);
    if ~isempty(opt.CLim)
        clim(ax, opt.CLim);
    else
        c_lo = min(rr_plus);  c_hi = max(rr_plus);
        if c_hi > c_lo, clim(ax, [c_lo, c_hi]); end
    end

    cb = colorbar(ax);
    cb.Label.String   = opt.RRLabel;
    cb.Label.FontSize = 10;
    cb.FontSize       = 9;

    % --- seastate labels inside bubbles ---
    %if ~isempty(opt.Labels)
    %    lbls = opt.Labels;
    %    if isstring(lbls), lbls = cellstr(lbls); end
    %    for i = 1:N
    %        text(ax, Tp(i), Hs(i), lbls{i}, ...
    %            'HorizontalAlignment', 'center', ...
    %            'VerticalAlignment',   'middle', ...
    %            'FontSize', 7, 'FontWeight', 'bold', 'Color', 'w');
    %    end
    %end

    % --- manual bubble size legend ---
    % With a fixed ProductionMax the legend uses fixed reference values so it
    % is identical across plots; otherwise it shows this dataset's min/median/max.
    if isempty(opt.ProductionMax)
        ref_prods = [min(production); median(production); max(production)];
    else
        ref_prods = prod_max .* [0.25; 0.5; 1];
    end
    % legend circle diameter scales with sqrt(production), like bubble area
    ref_scale = sqrt(ref_prods ./ prod_max);

    % position legend in normalised axes units (top-left)
    lx = 0.03;   % left edge
    ly = 0.97;   % top edge  
    row_h = 0.09;

    annotation_texts = { ...
        sprintf('%.0f m^3/day', ref_prods(1)), ...
        sprintf('%.0f m^3/day', ref_prods(2)), ...
        sprintf('%.0f m^3/day', ref_prods(3))};

    % legend background box
    annotation(fig, 'rectangle', [lx-0.01, ly-3*row_h-0.03, 0.22, 3*row_h+0.05], ...
        'FaceColor', 'w', 'EdgeColor', [0.8 0.8 0.8], 'LineWidth', 0.5);

    % title
    annotation(fig, 'textbox', [lx, ly-0.03, 0.2, 0.03], ...
        'String', 'Production', 'FontSize', 8, 'FontWeight', 'bold', ...
        'EdgeColor', 'none', 'FitBoxToText', 'off');

    % one row per reference size
    for k = 1:3
        row_y = ly - 0.03 - k*row_h;
        annotation(fig, 'ellipse', ...
            [lx + 0.01, row_y + 0.01, 0.03*ref_scale(k), 0.05*ref_scale(k)], ...
            'FaceColor', [0.6 0.6 0.6], 'EdgeColor', 'w', 'LineWidth', 0.8);
        annotation(fig, 'textbox', [lx + 0.06, row_y, 0.15, row_h], ...
            'String', annotation_texts{k}, 'FontSize', 8, ...
            'VerticalAlignment', 'middle', 'EdgeColor', 'none');
    end

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