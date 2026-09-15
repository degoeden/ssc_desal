load_system('waveDrivenDesal.slx');
set_param('waveDrivenDesal/SWRO PTO', 'Commented', 'off');
set_param('waveDrivenDesal/SWRO PTO w// ERU', 'Commented', 'on');
close_system('waveDrivenDesal.slx',1)
wecSim

save("results","simout","simlog")
