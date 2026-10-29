% Set Options
PTO_arch = "basic"; resistance = "low"; membrane = "solution";
feed_x = 36; perm_x = 0.7;  % feed and permeate concentrations
Hs = 2.64; Tp = 9.86;       % wave settings

% Load Results
function str = decimalToString(num)
    str = replace(sprintf("%.2f", num), ".", "_");
end
load(strcat(PTO_arch,resistance,membrane,decimalToString(Hs),decimalToString(Tp),decimalToString(feed_x)))

t_v = simout.Velocity.Time;
v_in =  simout.Velocity.Data;
t = simout.In_Flow.Time;
Q_in = simout.In_Flow.Data;
Q_perm = simout.Perm_Flow.Data;
Q_brine = simout.Brine_Flow.Data;
Q_PRV = simout.PRV_Flow.Data;
figure('Name','Flows')
c = load_colors();
colororder([1 1 1;c.vel])
%yyaxis left
line(t,Q_in,'DisplayName','In flow','color',c.in)
line(t,Q_PRV,'DisplayName','PRV flow','color',c.prv,'LineStyle','-')
line(t,Q_brine,'DisplayName','Brine flow','color',c.brine,'LineWidth',2,'LineStyle','-')
line(t,Q_perm,'DisplayName','Permeate flow','color',c.perm,'LineWidth',2,'LineStyle','-')
ylabel('Flow rate [m^3/s]')
ylim([0,0.3])
%yyaxis right
%line(t_v,v_in,'DisplayName','Velocity','LineWidth',2)
%ylabel('Velocity [m/s]')
%xlim([200,250])
xlabel('Time [s]')
legend('location','best')
figure('Name','Pressure')
line(t,simout.Feed_Pressure.Data/1e6,'Color',c.vel,'LineWidth',2)
%xlim([200,250])
ylabel('Pressure [MPa]')
figure('Name','Concentrations');
colororder([c.brine;c.perm])
yyaxis left
line(t,simout.Brine_Concentration.Data,'DisplayName','Brine','LineWidth',2)
line(t,simout.Feed_Concentration.Data,'DisplayName','Feed')
ylabel('Salt Concentration [g/L]')
yyaxis right
line(t,simout.Perm_Concentration.Data*1e3,'DisplayName','Permeate','LineWidth',2)
ylabel('Salt Concentration [mg/L]')
%xlim([200,250])
legend('Location','best')
t = simout.In_Flow.Time;
E_in = trapz(t,simout.In_Flow.Data.*simout.Feed_Pressure.Data);
E_prv = trapz(t,simout.PRV_Flow.Data.*simout.Feed_Pressure.Data);
E_brine = trapz(t,simout.Brine_Flow.Data.*simout.Brine_Pressure.Data);
E_perm = trapz(t,simout.Perm_Flow.Data.*simout.Feed_Pressure.Data);
E_other = max([E_in - E_prv - E_brine - E_perm,0]);
figure('Name','basic energy')
energy = [E_perm,E_brine,E_prv,E_other];
energy_initial = energy;
labels = {'Permeate','Brine','PRV','Other'};
p = piechart(energy,labels,ExplodedWedges=2);
p.ColorOrder = [c.perm;c.brine;c.prv;c.other];


function c = load_colors()
    c = struct();
    c.perm  =   [0.4230    0.9560    1.0000];
    c.brine =   [0.1210    0.8110    0.7450];
    c.prv   =   [1.0000    0.4780    0.4540];
    c.in    =   [0.1490    0.5490    0.8660];
    c.other =   [0.8620    0.6000    0.4230];
    c.vel   =   [0.9490    0.4030    0.7720];
    c.base  =   [1 1 1];
    bg = get(groot,'DefaultFigureColor');
    isDark = mean(bg) < 0.5;

    if ~isDark
        darken = @(x) 0.75*x; 

        c.perm  = [0.5210    0.0860    0.8190];
        c.brine = darken(c.brine);
        c.prv   = darken(c.prv);
        c.in    = darken(c.in);
        c.vel   = darken(c.vel);
        c.other = darken(c.other);
        c.base  = [0 0 0];
    end
end