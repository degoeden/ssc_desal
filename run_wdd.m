load_system('waveDrivenDesal.slx');
% Select PTO Architecture
set_param('waveDrivenDesal/SWRO PTO', 'Commented', 'on');
set_param('waveDrivenDesal/SWRO PTO w// ERU', 'Commented', 'on');
set_param('waveDrivenDesal/BRO PTO', 'Commented', 'on');
switch PTO_arch
    case "basic"
        pto = 'SWRO PTO';
        if strcmp(resistance, "low")
            set_param('waveDrivenDesal/SWRO PTO/Linear Resistance (SS)','R','95e6');
        else
            set_param('waveDrivenDesal/SWRO PTO/Linear Resistance (SS)','R','285e6');
        end
    case "eru"
        pto = 'SWRO PTO w// ERU';
    case "bro"
        pto = 'BRO PTO';
end
set_param(['waveDrivenDesal/',pto], 'Commented', 'off');

% Select Membrane
switch membrane
    case "solution"
        set_param(['waveDrivenDesal/',pto,'/Membrane/Membrane'],'Commented','off');
        set_param(['waveDrivenDesal/',pto,'/Membrane/Bad Membrane'],'Commented','on');
    case "fixed"
        pi = (@(x) x*0.741829 + x^2*0.00111004)/10; % [MPa]
        delta_pi = pi(feed_x) - pi(perm_x);
        set_param(['waveDrivenDesal/',pto,'/Membrane/Membrane'],'Commented','on');
        set_param(['waveDrivenDesal/',pto,'/Membrane/Bad Membrane'],'Commented','off');
        set_param(['waveDrivenDesal/',pto,'/Membrane/Bad Membrane/Delta Pi'],'pressure_differential',num2str('delta_pi'));
end

% Other settings
set_param('waveDrivenDesal','SimscapeLogType','all');

% Close and Run
save_system('waveDrivenDesal', 'SaveDirtyReferencedModels','on')
close_system('waveDrivenDesal.slx',1)
wecSim

% Save Results
function str = decimalToString(num)
    str = replace(sprintf("%.2f", num), ".", "_");
end
save(strcat(PTO_arch,resistance,membrane,decimalToString(Hs),decimalToString(Tp),decimalToString(feed_x)),'simout')

