function fig = plot_backflow_heatmap(csv_path, varargin)
% PLOT_BACKFLOW_HEATMAP  Heatmap of backflow loss fraction across PTOs and seastates.
%
%   fig = plot_backflow_heatmap(csv_path)
%   fig = plot_backflow_heatmap(csv_path, Name, Value, ...)
%
%   Input
%   -----
%   csv_path   Path to CSV file with columns: PTO, ss0, ss1, ..., ssN
%              and rows for each PTO architecture.
%              Values are (production_gross - production_net) / production_gross
%
%   Optional name-value arguments
%   -----------------------------
%   Title      Plot title          (default: 'Backflow loss fraction by PTO and seastate')
%   Threshold  Value above which a cell is annotated with '>'  (default: 1.0)
%   Colormap   Colormap name or Nx3 matrix  (default: custom white->orange->red)
%   CLim       [min max] colour axis limits, log scale  (default: [1e-4 1];
%              cells >max are capped, cells <min (incl. zeros) are floored)
%
%   Output
%   ------
%   fig        Figure handle
%
%   Example
%   -------
%   fig = plot_backflow_heatmap('data/production_vs_net.csv');
%   exportgraphics(fig, 'backflow_heatmap.png', 'Resolution', 150);

    % --- input parsing ---
    p = inputParser;
    addRequired(p,  'csv_path',  @(x) ischar(x) || isstring(x));
    addParameter(p, 'Title',     'Backflow loss fraction  (\itproduction_{gross} - production_{net}\rm) / \itproduction_{gross}', ...
                                 @(x) ischar(x) || isstring(x));
    addParameter(p, 'Threshold', 1.0,   @isnumeric);
    addParameter(p, 'Colormap',  [],    @(x) isempty(x) || ischar(x) || isstring(x) || (isnumeric(x) && size(x,2)==3));
    addParameter(p, 'CLim',      [1e-4 1], @(x) isnumeric(x) && numel(x)==2 && all(x > 0) && x(1) < x(2));
    parse(p, csv_path, varargin{:});
    opt = p.Results;

    % --- read CSV ---
    T = readtable(csv_path, 'TextType', 'string');
    pto_names = T{:,1};                          % first column: PTO labels
    ss_names  = T.Properties.VariableNames(2:end); % ss0, ss1, ...
    data      = T{:, 2:end};                     % numeric matrix: PTOs x seastates

    [n_pto, n_ss] = size(data);

    % --- colormap: white -> yellow -> orange -> red ---
    if isempty(opt.Colormap)
        n = 256;
        cmap = interp1([0 0.3 0.7 1], ...
            [1.00 1.00 1.00;   % white  (0)
             1.00 0.85 0.30;   % yellow (0.3)
             0.95 0.45 0.10;   % orange (0.7)
             0.75 0.05 0.05],...  % red    (1)
            linspace(0,1,n));
    elseif ischar(opt.Colormap) || isstring(opt.Colormap)
        cmap = colormap(opt.Colormap);
    else
        cmap = opt.Colormap;
    end

    % --- clamp display values into CLim (log scale can't show zeros);
    %     keep originals for annotation ---
    data_display = min(max(data, opt.CLim(1)), opt.CLim(2));

    % --- figure ---
    fig = figure('Color', 'w');
    ax  = axes(fig);

    imagesc(ax, data_display);
    colormap(ax, cmap);
    ax.ColorScale = 'log';
    clim(ax, opt.CLim);

    cb = colorbar(ax);
    cb.Label.String   = 'Loss fraction (-)';
    cb.Label.FontSize = 10;
    cb.FontSize       = 9;
    % decade ticks; mark the floor and cap on the colourbar
    ticks = 10.^(ceil(log10(opt.CLim(1))):floor(log10(opt.CLim(2))));
    ticks = unique([opt.CLim(1), ticks, opt.CLim(2)]);
    labels = arrayfun(@(t) sprintf('%g', t), ticks, 'UniformOutput', false);
    labels{1}   = ['≤' labels{1}];
    labels{end} = ['≥' labels{end} ' (net –ve)'];
    cb.Ticks      = ticks;
    cb.TickLabels = labels;

    % --- cell annotations ---
    for r = 1:n_pto
        for c = 1:n_ss
            val = data(r, c);
            if val > opt.Threshold
                % above threshold: white '>' to flag net-negative production
                text(ax, c, r, '>', ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment',   'middle', ...
                    'FontSize', 9, 'FontWeight', 'bold', 'Color', 'w');
            elseif val > 0.05
                % notable loss: show value
                txt_col = 'w';
                text(ax, c, r, sprintf('%.2f', val), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment',   'middle', ...
                    'FontSize', 7, 'Color', txt_col);
            end
            % near-zero cells left blank (clean seastates)
        end
    end

    % --- axes formatting ---
    ax.XTick      = 1:n_ss;
    ax.XTickLabel = ss_names;
    ax.XTickLabelRotation = 45;
    ax.YTick      = 1:n_pto;
    ax.YTickLabel = pto_names;
    ax.FontSize   = 9;
    ax.TickLength = [0 0];
    ax.Box        = 'on';

    xlabel(ax, 'Seastate',       'FontSize', 10);
    ylabel(ax, 'PTO architecture', 'FontSize', 10);
    title(ax,  opt.Title,        'FontSize', 11, 'FontWeight', 'bold');

    % add subtle grid lines between cells
    hold(ax, 'on');
    for c = 1.5:n_ss-0.5
        plot(ax, [c c], [0.5 n_pto+0.5], 'w', 'LineWidth', 0.4);
    end
    for r = 1.5:n_pto-0.5
        plot(ax, [0.5 n_ss+0.5], [r r], 'w', 'LineWidth', 0.4);
    end
    hold(ax, 'off');

    set(fig, 'Position', [100 100 900 300]);
end


% =========================================================================
%  EXAMPLE
% =========================================================================
%{
fig = plot_backflow_heatmap('data/production_vs_net.csv');
exportgraphics(fig, 'backflow_heatmap.png', 'Resolution', 150);
%}