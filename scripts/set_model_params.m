function set_model_params(opts)
% SET_MODEL_PARAMS Configure waveDrivenDesal.slx for a given PTO/membrane setup.
%   set_model_params(PTO_arch="eru", membrane="fixed", feed_x=36, perm_x=0.5)

arguments
    opts.PTO_arch   (1,1) string {mustBeMember(opts.PTO_arch, ["basic","eru","bro"])} = "basic"
    opts.resistance (1,1) string = "low"
    opts.membrane   (1,1) string {mustBeMember(opts.membrane, ["solution","fixed"])} = "solution"
    opts.feed_x     (1,1) double {mustBeNonnegative} = 36
    opts.perm_x     (1,1) double {mustBeNonnegative} = 0.2
end

% Project is one directory above ./scripts/
scriptDir  = fileparts(mfilename('fullpath'));
projectDir = fileparts(scriptDir);
openProject(fullfile(projectDir, 'ssc_desal.prj'));

% WEC-Sim source script
run(fullfile(projectDir, '..', 'WEC-Sim', 'addWecSimSource.m'));

mdl = 'waveDrivenDesal';
load_system(mdl);

% Select PTO Architecture
set_param([mdl '/SWRO PTO'], 'Commented', 'on');
set_param([mdl '/SWRO PTO w// ERU'], 'Commented', 'on');
set_param([mdl '/BRO PTO'], 'Commented', 'on');
switch opts.PTO_arch
    case "basic"
        pto = 'SWRO PTO';
        switch opts.resistance
            case "low",  R = '95e6';
            case "high", R = '285e6';
            otherwise
                error('set_model_params:badResistance', ...
                    'resistance must be "low" or "high" for PTO_arch="basic", got "%s".', opts.resistance);
        end
        set_param([mdl '/SWRO PTO/Linear Resistance (SS)'], 'R', R);
        set_param([mdl '/SWRO PTO/Linear Resistance (SS)'], 'R', R);
    case "eru"
        pto = 'SWRO PTO w// ERU';
    case "bro"
        pto = 'BRO PTO';
end
set_param([mdl '/' pto], 'Commented', 'off');

% Select Membrane
membranePath = [mdl '/' pto '/Membrane'];
switch opts.membrane
    case "solution"
        set_param([membranePath '/Membrane'], 'Commented', 'off');
        set_param([membranePath '/Bad Membrane'], 'Commented', 'on');
    case "fixed"
        osmoticP = @(x) (x*0.741829 + x^2*0.00111004)/10; % [MPa]
        delta_pi = osmoticP(opts.feed_x) - osmoticP(opts.perm_x);
        set_param([membranePath '/Membrane'], 'Commented', 'on');
        set_param([membranePath '/Bad Membrane'], 'Commented', 'off');
        set_param([membranePath '/Bad Membrane/Delta Pi'], ...
            'pressure_differential', num2str(delta_pi));
end

% Other settings
set_param(mdl, 'SimscapeLogType', 'all');
set_param(mdl, 'SimscapeLogDecimation', 10);

% Save and close
save_system(mdl, 'SaveDirtyReferencedModels', 'on');
close_system(mdl, 1);
end