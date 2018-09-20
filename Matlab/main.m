%% Initialize CarMarker

clear all; close all; clc;

root_folder = 'C:\Users\Renata\Desktop\CarMaker\Examples\FS_Generic_2018';
cd('C:\Users\Renata\Desktop\CarMaker\Examples\FS_Generic_2018\Matlab')
addpath(genpath(root_folder));
cmenv


%% Clear Vars and set results folder

% dbstop if error
% dbclear if error
clearvars -except root_folder; close all; clc;
% results_folder = fullfile(root_folder,'SimOutput\LAPTOP-GM5N43L8\DoE');
results_folder = fullfile(root_folder,'SimOutput\LAPTOP-GM5N43L8\DoE_Spring_Damper');


%% Start GUI

h_main_GUI = main_GUI(results_folder);



%% Print to Latex

if false
    sfold = 'C:\Users\Renata\Desktop\Bachelor Thesis\Latex\ch-Maneuvers\figures';

    f = figure('Color','white','Position',[400   314   909   529]);
    h_main_GUI.maneval.mans{2}.plot
    matlabfrag(fullfile(sfold,'CSST_mf'))

    f = figure('Color','white','Position',[400   314   909   529]);
    h_main_GUI.maneval.mans{3}.plot
    matlabfrag(fullfile(sfold,'QSSC_mf'))

    f = figure('Color','white','Position',[400   314  682  529]);
    h_main_GUI.maneval.mans{6}.plot
    matlabfrag(fullfile(sfold,'WEAVE_mf'))

    f = figure('Color','white','Position',[400   314   909   722]);
    h_main_GUI.maneval.mans{5}.plot
    matlabfrag(fullfile(sfold,'SWD_SF_mf'))


    f = figure('Color','white','Position',[400   314   909   529]);
    h_main_GUI.maneval.mans{4}.plot
    matlabfrag(fullfile(sfold,'SWD_mf'))
end

%%
% h_main_GUI.sim.KPI.sim_fun

% a = load('C:\Users\Renata\Desktop\CarMaker\Examples\FS_Generic_2018\SimOutput\LAPTOP-GM5N43L8\DoE\DoE_CM_2plots.mat');


        
%             KPI.ay_max.target         = [13 inf];
%             KPI.beta_at_ay_max.target = [-inf inf];
%             KPI.v_ch_cr.target        = [90 inf];
%             KPI.YG_lin.target         = [0.1 inf];
%             KPI.YG_nonlin.target      = [-inf 0];
%             KPI.Teq_yr.target         = [0 1/2];
%             KPI.YawGain_at_40.target  = [0.85 inf];
%             KPI.YawGain_at_60.target  = [1.2 inf];
%             KPI.YawGain_at_80.target  = [1.5 inf];

