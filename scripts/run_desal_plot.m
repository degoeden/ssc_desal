% RUN_DESAL_PLOT
% Loads simulation results across seastates and calls plot_desal_seastates.
%
% Set the configuration block below, then run the script.

% =========================================================================
%  CONFIGURATION
% =========================================================================

PTO_arch   = 'basic';       % your PTO architecture string
resistance = 'low';        % your resistance string
membrane   = 'solution';        % your membrane string
feed_x     = 36;           % feed fraction (single value; extend to vector if it varies per seastate)

% Seastate grid — edit to match your 20 seastates
Hs_vec = [1.7707093836756636 1.4757467428690545 1.1146362808579522 0.8000118789813867 4.635898379970542 2.574394045126751 2.5349366630610004 1.001865613432608 1.0779023831039394 1.1922186822432743 2.063874210861717 1.681761551332142 3.315881129382017 2.732203169230346 6.713700854700875 1.91849027165957 0.9823690678767296 1.3107230273390404 3.193034002888281 3.8642559652928448];
Tp_vec = [13.23112333956173 10.234793700202095 22.584459732902232 13.81664042372318 10.638863524791551 16.56912770411745 9.191129829212345 9.976561213254367 5.855232218554694 13.593014631352435 12.833294612926467 9.84231198249586 10.284139549631792 13.011144410022865 12.274136752136759 7.900205063645171 17.167737568529763 7.344880379199283 8.939529998687709 15.374832971800414];

% =========================================================================
%  LOAD AND PROCESS
% =========================================================================

N          = numel(Hs_vec);
production = nan(1, N);   % m3/day
rr_plus    = nan(1, N);   % (-)
labels     = cell(1, N);

for i = 1:N
    Hs = Hs_vec(i);
    Tp = Tp_vec(i);

    savename = strcat(PTO_arch, resistance, membrane, ...
                      decimalToString(Hs), decimalToString(Tp), ...
                      decimalToString(feed_x));
    fpath = "data/completed/" + savename + ".mat";

    if ~isfile(fpath)
        warning('File not found, skipping: %s', fpath);
        continue
    end

    load(fpath, 'simout');

    % --- extract timeseries ---
    t_q    = simout.In_Flow.Time;       % s
    Q_in   = simout.In_Flow.Data;       % m3/s (or consistent flow units)
    Q_perm = simout.Perm_Flow.Data;     % m3/s

    % --- time-integrate with trapezoid rule ---
    V_in   = trapz(t_q, Q_in);         % total volume in  [m3]
    V_perm = trapz(t_q, Q_perm);       % total permeate   [m3]

    % --- daily production: scale permeate volume to a 24-hour equivalent ---
    sim_duration_s     = t_q(end) - t_q(1);
    production(i)      = V_perm / sim_duration_s * 86400;   % m3/day

    % --- RR+: permeate / total inlet (feedwater that entered the system) ---
    rr_plus(i) = V_perm / V_in;

    labels{i} = sprintf('SS%d', i);
end

% --- drop any seastates that failed to load ---
valid      = ~isnan(production);
Hs_plot    = Hs_vec(valid);
Tp_plot    = Tp_vec(valid);
prod_plot  = production(valid);
rr_plot    = rr_plus(valid);
lbl_plot   = labels(valid);

if sum(valid) == 0
    error('No seastate files were loaded successfully. Check paths and naming.');
end

% =========================================================================
%  PLOT
% =========================================================================

fig = plot_desal_seastates(Hs_plot, Tp_plot, prod_plot, rr_plot, ...
          'Labels',          lbl_plot, ...
          'ProductionLabel', 'm^3/day', ...
          'RRLabel',         'RR+ (-)', ...
          'Title',           sprintf('Wave desal performance — %s %s %s', ...
                                     PTO_arch, resistance, membrane));

exportgraphics(fig, 'seastate_performance.png', 'Resolution', 150);
fprintf('Saved seastate_performance.png\n');


function str = decimalToString(num)
    str = replace(sprintf("%.2f", num), ".", "_");
end