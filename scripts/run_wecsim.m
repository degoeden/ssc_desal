% RUN_SIM Run WEC-Sim on waveDrivenDesal and export the Simscape log.
% Set any of these before running; anything unset uses the default below.
%   matlab -batch "PTO_arch='eru'; Hs=3.0; run('./scripts/run_sim.m')"

% Defaults
if ~exist('PTO_arch',   'var'), PTO_arch   = "basic";    end
if ~exist('resistance', 'var'), resistance = "low";      end
if ~exist('membrane',   'var'), membrane   = "solution"; end
if ~exist('feed_x',     'var'), feed_x     = 36;         end  % feed concentration
if ~exist('perm_x',     'var'), perm_x     = 0.7;        end  % permeate concentration
if ~exist('Hs',         'var'), Hs         = 2.64;       end  % significant wave height
if ~exist('Tp',         'var'), Tp         = 9.86;       end  % peak period

try
    % Validate
    PTO_arch = string(PTO_arch); resistance = string(resistance); membrane = string(membrane);
    mustBeMember(PTO_arch, ["basic","eru","bro"]);
    mustBeMember(membrane, ["solution","fixed"]);
    mustBeNonnegative([feed_x perm_x]);
    mustBePositive([Hs Tp]);

    % resistance only matters (and only goes in the filename) for the basic PTO
    if PTO_arch == "basic"
        mustBeMember(resistance, ["low","high"]);
        resTag = resistance;
    else
        resTag = "";
    end

    savename = PTO_arch + resTag + membrane + ...
        decimalToString(Hs) + decimalToString(Tp) + decimalToString(feed_x);
    fprintf('Case: %s\n', savename);

    MODEL_NAME = 'waveDrivenDesal';
    %OUTFILE = "/scratch/mhaji_root/mhaji0/degoeden/waveDrivenDesal_" + savename;
    s = settings;
    s.simscape.StreamToDisk.PersonalValue = true;

    % Project is one directory above ./scripts/
    scriptDir  = fileparts(mfilename('fullpath'));
    projectDir = fileparts(scriptDir);
    openProject(fullfile(projectDir, 'ssc_desal.prj'));

    % WEC-Sim source script
    run(fullfile(projectDir, '..', 'WEC-Sim', 'addWecSimSource.m'));

    % Run Simulation and save results
    wecSim
    save(savename, 'simout');

    % Get Simscape log
    node = simscape.logging.getSimulationLog(MODEL_NAME);

    if isempty(node)
        error('No simlog node found for %s.', MODEL_NAME);
    end

    if ~node.exportable
        error(['Simscape log is not exportable. ', ...
               'The log appears to be in memory rather than disk-backed.']);
    end

    simscape.logging.export(node, OUTFILE);

    fprintf('Exported simlog to: %s.mldatx\n', OUTFILE);
    close_system(MODEL_NAME, 0);

catch ME
    fprintf(2, '%s\n', getReport(ME, 'extended'));
    cleanupAndExit(1);
end
cleanupAndExit(0);

function str = decimalToString(num)
    str = replace(sprintf("%.2f", num), ".", "_");
end

function cleanupAndExit(code)
    try
        bdclose('all');                                   % close all models, discarding changes
        Simulink.data.dictionary.closeAll('-discard');    % in case the project uses data dictionaries
        proj = matlab.project.rootProject;
        if ~isempty(proj)
            close(proj);
        end
    catch cleanupErr
        fprintf(2, 'Cleanup warning: %s\n', cleanupErr.message);
    end
    exit(code, 'force');
end