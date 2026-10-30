PTO_arch = "basic"; resistance = "low"; membrane = "solution";
feed_x = 36; perm_x = 0.7;  % feed and permeate concentrations
Hs = 2.64; Tp = 9.86;       % wave settings
savename = strcat(PTO_arch,resistance,membrane,decimalToString(Hs),decimalToString(Tp),decimalToString(feed_x))

try
    MODEL_NAME = 'waveDrivenDesal';
    OUTFILE = strcat("/mnt/drive2/degoede/waveDrivenDesal_",savename);
    s = settings;
    s.simscape.StreamToDisk.PersonalValue = true;

    % Directory containing this script
    scriptDir = fileparts(mfilename('fullpath'));

    % Project is one directory above ./scripts/
    projectDir = fileparts(scriptDir);

    openProject(fullfile(projectDir, 'ssc_desal.prj'));

    % WEC-Sim source script
    run(fullfile(projectDir, '..', 'WEC-Sim', 'addWecSimSource.m'));

    % Run Simulation and save results
    run run_wdd

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

catch ME
    fprintf(2, '%s\n', getReport(ME, 'extended'));
    exit(1);
end

exit(0);

function str = decimalToString(num)
    str = replace(sprintf("%.2f", num), ".", "_");
end
