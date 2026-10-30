try
    MODEL_NAME = 'waveDrivenDesal';
    OUTFILE = '/mnt/drive2/degoede/waveDrivenDesal_run1';

    % Directory containing this script
    scriptDir = fileparts(mfilename('fullpath'));

    % Project is one directory above ./scripts/
    projectDir = fileparts(scriptDir);

    openProject(fullfile(projectDir, 'ssc_desal.prj'));

    % WEC-Sim source script
    run(fullfile(projectDir, '..', 'WEC-Sim', 'addWecSimSource.m'));

    % Change Model Settings
    load_system('waveDrivenDesal.slx');
    set_param('waveDrivenDesal/SWRO PTO', 'Commented', 'on');
    set_param('waveDrivenDesal/SWRO PTO w// ERU', 'Commented', 'off');
    set_param('waveDrivenDesal','SimscapeLogDecimation',10);
    close_system('waveDrivenDesal.slx',1)
    
    % Run WEC-Sim
    wecSim;

    % Save Main Results
    %save('results','simout');

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
