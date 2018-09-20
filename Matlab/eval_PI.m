%% Initialize CarMarker

clearvars; close all; clc;

root_folder = 'C:\Users\Renata\Desktop\CarMaker\Examples\FS_Generic_2018';
addpath(genpath(root_folder));
cmenv

results_folder = fullfile(root_folder,'SimOutput\LAPTOP-GM5N43L8\Results');

% for i=1:numel()
% ler nome de cada pasta comecando por 'Variant_'
% Obter KPI de cada pasta
% Escrever em Excel
% end

f = figure;
tgroup = uitabgroup('Parent', f);


%% QSSC

QSSC_out  = cmread(fullfile(results_folder,'QSSC_50m.erg'));


% Yaw Rate calculation
QSSC_out.Car_YawGain.data = QSSC_out.Car_YawRate.data ./ (QSSC_out.Driver_Steer_Ang.data);
QSSC_out.Car_YawGain.unit = '1/s';
QSSC_out.Car_YawGain.name = 'Car.YawGain';

% Fz Difference calculation
QSSC_out.Fz_diff_FA.data = (QSSC_out.Car_FzFL.data + QSSC_out.Car_FzFR.data) ./ (QSSC_out.Car_FzRL.data + QSSC_out.Car_FzRR.data) * 100;
QSSC_out.Fz_diff_FA.unit = '%FA';
QSSC_out.Fz_diff_FA.name = 'Fz Dfference % at Front Axle';


% figure('Name','QSSC Analysis','Color','white')
tabname = 'QSSC';
if ~isempty(tgroup.Children) tgroup.Children(find(ismember({tgroup.Children.Title},tabname))).delete; end
tab_QSSC = uitab('Parent', tgroup, 'Title', tabname, 'BackgroundColor', 'white');
axes('parent',tab_QSSC, 'Color','white')


subplot(2,3,1)
plot(QSSC_out.Car_ay.data, QSSC_out.Driver_Steer_Ang.data *180/pi)
xlabel( [QSSC_out.Car_ay.name ' [' QSSC_out.Car_ay.unit ']'])
ylabel( [QSSC_out.Driver_Steer_Ang.name ' [deg]'])
xlim([1.5 max(QSSC_out.Car_ay.data)+1])
grid on

subplot(2,3,2)
plot(QSSC_out.Car_ay.data, QSSC_out.Car_SideSlipAngle.data *180/pi)
xlabel( [QSSC_out.Car_ay.name ' [' QSSC_out.Car_ay.unit ']'])
ylabel( [QSSC_out.Car_SideSlipAngle.name ' [deg]'])
xlim([1.5 max(QSSC_out.Car_ay.data)+1])
grid on

subplot(2,3,3)
plot(QSSC_out.Car_ay.data, QSSC_out.Driver_Steer_Trq.data)
xlabel( [QSSC_out.Car_ay.name ' [' QSSC_out.Car_ay.unit ']'])
ylabel( [QSSC_out.Driver_Steer_Trq.name ' [' QSSC_out.Driver_Steer_Trq.unit ']'])
xlim([1.5 max(QSSC_out.Car_ay.data)+1])
grid on

subplot(2,3,4)
plot(QSSC_out.Car_ay.data, QSSC_out.Car_Roll.data * 180/pi)
xlabel( [QSSC_out.Car_ay.name ' [' QSSC_out.Car_ay.unit ']'])
ylabel( [QSSC_out.Car_Roll.name ' [deg]'])
xlim([1.5 max(QSSC_out.Car_ay.data)+1])
grid on

subplot(2,3,5)
plot(QSSC_out.Car_ay.data, QSSC_out.Fz_diff_FA.data)
xlabel( [QSSC_out.Car_ay.name ' [' QSSC_out.Car_ay.unit ']'])
ylabel( [QSSC_out.Fz_diff_FA.name ' [' QSSC_out.Fz_diff_FA.unit ']'])
xlim([1.5 max(QSSC_out.Car_ay.data)+1])
grid on

subplot(2,3,6)
plot(QSSC_out.Car_v.data*3.6, QSSC_out.Car_YawGain.data)
xlabel( [QSSC_out.Car_v.name ' [km/h]'])
ylabel( [QSSC_out.Car_YawGain.name ' [' QSSC_out.Car_YawGain.unit ']'])
ylim([0 10])
grid on




    idx = QSSC_out.Car_ay.data>2 & QSSC_out.Car_ay.data<4;
    X = [ones(length(QSSC_out.Car_ay.data(idx)),1) QSSC_out.Car_ay.data(idx)'];
    b = X\(QSSC_out.Driver_Steer_Ang.data(idx)' *180/pi);
KPI.QSSC.YG_lin.value = b(2);
KPI.QSSC.YG_lin.name  = 'US/OS Gradient Coefficient - Linear (2<ay<4)';
KPI.QSSC.YG_lin.unit  = 'deg/(m/s²)';

KPI.QSSC.ay_max.value = max(QSSC_out.Car_ay.data);
KPI.QSSC.ay_max.name  = 'Maximal Lateral Acceleration';
KPI.QSSC.ay_max.unit  = 'm/s²';

KPI.QSSC.v_ch_cr.value = QSSC_out.Car_v.data( QSSC_out.Car_YawGain.data==max(QSSC_out.Car_YawGain.data) ) * 3.6;
KPI.QSSC.v_ch_cr.name  = 'Characteristic/Critical Velocity';
KPI.QSSC.v_ch_cr.unit  = 'km/h';

KPI.QSSC.beta_at_ay_max.value = abs(QSSC_out.Car_SideSlipAngle.data( QSSC_out.Car_ay.data==max(QSSC_out.Car_ay.data) )) * 180/pi;
KPI.QSSC.beta_at_ay_max.name  = 'Car SideSlip Angle at Maximal Lateral Acceleration';
KPI.QSSC.beta_at_ay_max.unit  = 'deg';

KPI.QSSC.swt_max.value = max(QSSC_out.Driver_Steer_Trq.data);
KPI.QSSC.swt_max.name  = 'Maximal Steering Wheel Torque';
KPI.QSSC.swt_max.unit  = 'Nm';



fprintf('KEY PERFORMANCE INDICATORS - QSSC\n')
fnames = fieldnames(KPI.QSSC);
for i=1:numel(fnames)
    fprintf('    %5.2f %15s - %s\n' , KPI.QSSC.(fnames{i}).value, ['[' KPI.QSSC.(fnames{i}).unit ']'], KPI.QSSC.(fnames{i}).name );
end

% plot_Maneuver(QSSC_out, {'Car_ay','Driver_Steer_Ang';
%                          'Car_ay','Car_SideSlipAngle';
%                          'Car_v','Car_YawGain'})



%% WEAVE

nfiles = dir(fullfile(results_folder,'*WEAVE_Speed_*.erg'));

for i=1:numel(nfiles)
    WEAVE_out(i).data  = cmread(fullfile(results_folder,nfiles(i).name));
    WEAVE_out(i).vel   = max(WEAVE_out(i).data.Car_v.data) *3.6;
    
%     figure
%     plot(WEAVE_out(i).data.Time.data, WEAVE_out(i).data.Driver_Steer_Ang.data)
    
    idx_cut = WEAVE_out(i).data.Time.data >= (WEAVE_out(i).data.Time.data(end) - 30);
    
    weave_swa  = sort( WEAVE_out(i).data.Driver_Steer_Ang.data( idx_cut ) ); 
    weave_yr   = sort( WEAVE_out(i).data.Car_YawRate.data( idx_cut ) );
    weave_ay   = sort( WEAVE_out(i).data.Car_ay.data( idx_cut ) );
    weave_lm   = sort( WEAVE_out(i).data.Driver_Steer_Trq.data( idx_cut ) );

    % get the peak values for each oscillatory signal
    yawgain(i) = mean(weave_yr(end-5:end)) / mean(weave_swa(end-5:end));
    aygain(i)  = mean(weave_ay(end-5:end)) / mean(weave_swa(end-5:end));
    swa(i)     = mean(weave_swa(end-5:end));
    lm_yr(i)   = mean(weave_yr(end-5:end)) / mean(weave_lm(end-5:end));
end

% sort velocities
[vel0 idxs] = sort([0 WEAVE_out.vel]);
yawgain = [0 yawgain]; yawgain = yawgain(idxs);
aygain  = [0 aygain];  aygain  = aygain(idxs);

[vel idxs] = sort([WEAVE_out.vel]);
swa   = swa(idxs) * 180/pi;
lm_yr = lm_yr(idxs);


% figure('Name','WEAVE Analysis','Color','white')
tabname = 'WEAVE';
if ~isempty(tgroup.Children) tgroup.Children( find(ismember({tgroup.Children.Title},tabname))).delete; end
tab_WEAVE = uitab('Parent', tgroup, 'Title', tabname, 'BackgroundColor', 'white');
tgroup.SelectedTab = tab_WEAVE;
axes('parent',tab_WEAVE, 'Color','white')

subplot(2,2,1)
scatter(vel0,yawgain);
x_int = 0:.01:120;
s_int = spline(vel0,yawgain,x_int);
hold on; plot(x_int,s_int);
ylim([0 1.2*max(yawgain)])
xlabel('Car.v [km/h]')
ylabel('Yaw Gain [1/s]')
grid on

subplot(2,2,2)
scatter(vel0,aygain);
x_int = 0:.01:120;
s_int = spline(vel0,aygain,x_int);
hold on; plot(x_int,s_int);
ylim([0 1.2*max(aygain)])
xlabel('Car.v [km/h]')
ylabel('Ay Gain [m/s²/deg]')
grid on

subplot(2,2,3)
scatter(vel,swa);
x_int = 0:.01:120;
s_int = spline(vel,swa,x_int);
hold on; plot(x_int,s_int);
ylim([0 1.2*max(swa)])
xlabel('Car.v [km/h]')
ylabel('Steering Wheel Angle at 4m/s² [deg]')
grid on

subplot(2,2,4)
scatter(vel,lm_yr);
x_int = 0:.01:120;
s_int = spline(vel,lm_yr,x_int);
hold on; plot(x_int,s_int);
ylim([0 1.2*max(lm_yr)])
xlabel('Car.v [km/h]')
ylabel('Yaw Rate to SteerTorq [deg/s/Nm]')
grid on


% KPI calculation
vels = [20 40 60 80 100];
for i=1:numel(vels)
    KPI.WEAVE.(['YawGain_at_' num2str(vels(i))]) = struct();
    KPI.WEAVE.(['YawGain_at_' num2str(vels(i))]).value = spline(vel0,yawgain,vels(i));
    KPI.WEAVE.(['YawGain_at_' num2str(vels(i))]).unit  = '1/s';
    KPI.WEAVE.(['YawGain_at_' num2str(vels(i))]).name  = ['Yaw Gain at ' num2str(vels(i))];
end

fprintf('KEY PERFORMANCE INDICATORS - WEAVE\n')
fnames = fieldnames(KPI.WEAVE);
for i=1:numel(fnames)
    fprintf('    %5.2f %15s - %s\n' , KPI.WEAVE.(fnames{i}).value, ['[' KPI.WEAVE.(fnames{i}).unit ']'], KPI.WEAVE.(fnames{i}).name );
end



%% SWD SF=X

SF = 4;
SWD_out  = cmread(fullfile(results_folder,['SWD_SF_' num2str(SF) '.erg']));


t_peak = SWD_out.Time.data(SWD_out.Driver_Steer_Ang.data==max(SWD_out.Driver_Steer_Ang.data));
t_plot_range = [t_peak-0.5 t_peak+3];

% figure('Name','SWD Analysis','Color','white')
tabname = ['SWD SF=' num2str(SF)];
if ~isempty(tgroup.Children) tgroup.Children( find(ismember({tgroup.Children.Title},tabname))).delete; end
tab_SWD = uitab('Parent', tgroup, 'Title', tabname, 'BackgroundColor', 'white');
tgroup.SelectedTab = tab_SWD;
axes('parent',tab_SWD, 'Color','white')

subplot(3,3,1)
plot(SWD_out.Time.data,SWD_out.Driver_Steer_Ang.data *180/pi)
xlabel( [SWD_out.Time.name ' [' SWD_out.Time.unit ']'])
ylabel( [SWD_out.Driver_Steer_Ang.name ' [deg]'])
xlim(t_plot_range)
grid on

subplot(3,3,2)
plot(SWD_out.Time.data,SWD_out.Car_v.data *3.6)
xlabel( [SWD_out.Time.name ' [' SWD_out.Time.unit ']'])
ylabel( [SWD_out.Car_v.name ' [' SWD_out.Car_v.unit ']'])

xlim(t_plot_range)
grid on

subplot(3,3,3)
plot(SWD_out.Time.data,SWD_out.Car_SideSlipAngle.data *180/pi)
xlabel( [SWD_out.Time.name ' [' SWD_out.Time.unit ']'])
ylabel( [SWD_out.Car_SideSlipAngle.name ' [deg]'])
xlim(t_plot_range)
grid on

subplot(3,3,4)
plot(SWD_out.Time.data,SWD_out.Car_YawRate.data *180/pi)
xlabel( [SWD_out.Time.name ' [' SWD_out.Time.unit ']'])
ylabel( [SWD_out.Car_YawRate.name ' [deg/s]'])
xlim(t_plot_range)
grid on

subplot(3,3,5)
plot(SWD_out.Time.data,SWD_out.Car_ay.data)
xlabel( [SWD_out.Time.name ' [' SWD_out.Time.unit ']'])
ylabel( [SWD_out.Car_ay.name ' [' SWD_out.Car_ay.unit ']'])
xlim(t_plot_range)
grid on

subplot(3,3,6)
plot(SWD_out.Time.data, SWD_out.Car_FzRL.data); hold on
plot(SWD_out.Time.data, SWD_out.Car_FzRR.data);
plot(SWD_out.Time.data, SWD_out.Car_FzFL.data);
plot(SWD_out.Time.data, SWD_out.Car_FzFR.data);
xlabel( [SWD_out.Time.name ' [' SWD_out.Time.unit ']'])
ylabel( ['Tyre Normal Force [' SWD_out.Car_FzRL.unit ']'])
xlim(t_plot_range)
ylim([0 inf])
grid on

subplot(3,3,7)
plot(SWD_out.Time.data, SWD_out.Car_ty.data);
xlabel( [SWD_out.Time.name ' [' SWD_out.Time.unit ']'])
ylabel( [SWD_out.Car_ty.name ' [' SWD_out.Car_ty.unit ']'])
xlim(t_plot_range)
grid on

subplot(3,3,8)
plot(SWD_out.Time.data, SWD_out.Driver_Steer_Trq.data);
xlabel( [SWD_out.Time.name ' [' SWD_out.Time.unit ']'])
ylabel( [SWD_out.Driver_Steer_Trq.name ' [' SWD_out.Driver_Steer_Trq.unit ']'])
xlim(t_plot_range)
grid on

subplot(3,3,9)
plot(SWD_out.Time.data, SWD_out.Car_Roll.data *180/pi);
xlabel( [SWD_out.Time.name ' [' SWD_out.Time.unit ']'])
ylabel( [SWD_out.Car_Roll.name ' [deg]'])
xlim(t_plot_range)
grid on


KPI.SWD.beta_max.value = max(abs(SWD_out.Car_SideSlipAngle.data *180/pi));
KPI.SWD.beta_max.name  = 'Maximal Car SideSlip Angle';
KPI.SWD.beta_max.unit  = 'deg';

KPI.SWD.yawrate_max.value = max(abs(SWD_out.Car_YawRate.data *180/pi));
KPI.SWD.yawrate_max.name  = 'Maximal Yaw Rate';
KPI.SWD.yawrate_max.unit  = 'deg/s';

KPI.SWD.ay_max.value = max(abs(SWD_out.Car_ay.data));
KPI.SWD.ay_max.name  = 'Maximal Lateral Acceleration';
KPI.SWD.ay_max.unit  = 'm/s²';

KPI.SWD.Fz_min.value = min([SWD_out.Car_FzFL.data SWD_out.Car_FzFR.data SWD_out.Car_FzRL.data SWD_out.Car_FzRR.data]);
KPI.SWD.Fz_min.name  = 'Minimal Tyre Normal Force';
KPI.SWD.Fz_min.unit  = 'N';

clc
fprintf('KEY PERFORMANCE INDICATORS - SWD\n')
fnames = fieldnames(KPI.SWD);
for i=1:numel(fnames)
    fprintf('    %5.2f %15s - %s\n' , KPI.SWD.(fnames{i}).value, ['[' KPI.SWD.(fnames{i}).unit ']'], KPI.SWD.(fnames{i}).name );
end




%% SWD

nfiles = dir(fullfile(results_folder,'*SWD_SF_*.erg'));

for i=1:numel(nfiles)
    SWD_data(i) = cmread(fullfile(results_folder,nfiles(i).name));
    swd_SF(i) = str2double(strrep(regexp(nfiles(i).name,'(\d+p?\d*)','match'), 'p','.'));
    
    t_steer_peak  = SWD_data(i).Time.data(SWD_data(i).Driver_Steer_Ang.data==max(SWD_data(i).Driver_Steer_Ang.data));
    t_steer_end   = t_steer_peak + 1/0.7 * 3/4 + 0.5;
    t_steer_begin = t_steer_peak - 1/0.7 * 1/4;
    [x idx_steer_begin] = min(abs(t_steer_begin-SWD_data(i).Time.data));
    
%     figure
%     plot(SWD_data(i).Time.data, SWD_data(i).Car_YawRate.data)
    
    swd_yr_max(i)   = max(abs(SWD_data(i).Car_YawRate.data));
    swd_yr_1s(i)    = spline(SWD_data(i).Time.data, SWD_data(i).Car_YawRate.data,  t_steer_end + 1);
    swd_yr_1p75s(i) = spline(SWD_data(i).Time.data, SWD_data(i).Car_YawRate.data,  t_steer_end + 1.75);
    swd_beta_max(i) = max(abs(SWD_data(i).Car_SideSlipAngle.data));
    swd_dy_max(i)   = max(SWD_data(i).Car_ty.data);
    swd_fz_min(i)   = min( [SWD_data(i).Car_FzFL.data(idx_steer_begin:end), ...
                            SWD_data(i).Car_FzFR.data(idx_steer_begin:end), ...
                            SWD_data(i).Car_FzRL.data(idx_steer_begin:end), ...
                            SWD_data(i).Car_FzRR.data(idx_steer_begin:end)]);
    swd_swa(i)      = max(SWD_data(i).Driver_Steer_Ang.data);
    
%     figure
%     plot(SWD_data(i).Time.data, SWD_data(i).Car_ty.data)
end

% figure('Name','SWD Analysis','Color','white')
tabname = 'SWD';
if ~isempty(tgroup.Children) tgroup.Children( find(ismember({tgroup.Children.Title},tabname))).delete; end
tab_SWD_SF = uitab('Parent', tgroup, 'Title', tabname, 'BackgroundColor', 'white');
tgroup.SelectedTab = tab_SWD_SF;
axes('parent',tab_SWD_SF, 'Color','white')

xrange = [min(swd_SF)-1 max(swd_SF)+1];

subplot(2,3,1)
scatter(swd_SF, swd_swa *180/pi)
x_int = (min(swd_SF)-0.5):0.05:(max(swd_SF)+0.5);
s_int = pchip(swd_SF, swd_swa *180/pi, x_int);
hold on; plot(x_int, s_int);
xlabel('Steering Factor')
ylabel('Steering Wheel Angle Amplitude [deg]')
xlim(xrange)
grid on

subplot(2,3,2)
swd_yr_1s_perc = swd_yr_1s./swd_yr_max *100;
scatter(swd_SF, swd_yr_1s_perc)
x_int = (min(swd_SF)-0.5):0.05:(max(swd_SF)+0.5);
s_int = pchip(swd_SF, swd_yr_1s_perc, x_int);
hold on; plot(x_int,s_int);
xlabel('Steering Factor')
ylabel('Yaw Rate (t=1s) / Yaw Rate Max [%]')
xlim(xrange)
ylim([-10 40])
grid on

subplot(2,3,3)
swd_yr_1p75s_perc = swd_yr_1p75s./swd_yr_max *100;
scatter(swd_SF, swd_yr_1p75s_perc)
x_int = (min(swd_SF)-0.5):0.05:(max(swd_SF)+0.5);
s_int = pchip(swd_SF, swd_yr_1p75s_perc, x_int);
hold on; plot(x_int,s_int);
xlabel('Steering Factor')
ylabel('Yaw Rate (t=1.75s) / Yaw Rate Max [%]')
xlim(xrange)
ylim([-10 40])
grid on

subplot(2,3,4)
scatter(swd_SF, swd_dy_max)
x_int = (min(swd_SF)-0.5):0.05:(max(swd_SF)+0.5);
s_int = pchip(swd_SF, swd_dy_max, x_int);
hold on; plot(x_int,s_int);
xlabel('Steering Factor')
ylabel('Lateral Displacement [m]')
xlim(xrange)
% ylim([-10 40])
grid on

subplot(2,3,5)
scatter(swd_SF, swd_beta_max *180/pi)
x_int = (min(swd_SF)-0.5):0.05:(max(swd_SF)+0.5);
s_int = pchip(swd_SF, swd_beta_max *180/pi, x_int);
hold on; plot(x_int,s_int);
xlabel('Steering Factor')
ylabel('Maximal Car SideSlipAngle [deg]')
xlim(xrange)
ylim([-10 40])
grid on

subplot(2,3,6)
scatter(swd_SF, swd_fz_min)
x_int = (min(swd_SF)-0.5):0.05:(max(swd_SF)+0.5);
s_int = pchip(swd_SF, swd_fz_min, x_int);
hold on; plot(x_int, s_int);
xlabel('Steering Factor')
ylabel('Minimal Tyre Normal Force [N]')
xlim(xrange)
grid on



%% CSST

CSST_out  = cmread(fullfile(results_folder,'CSST.erg'));
    
%     figure;
%     plot(time,input_Sinus)    
%     hold on
%     plot(time,output_Sinus)
%     title(nfiles(i).name)

tabname = 'CSST';
if ~isempty(tgroup.Children) tgroup.Children( find(ismember({tgroup.Children.Title},tabname))).delete; end
tab_CSST = uitab('Parent', tgroup, 'Title', tabname, 'BackgroundColor', 'white');
tgroup.SelectedTab = tab_CSST;
axes('parent',tab_CSST, 'Color','white')

time         = CSST_out.Time.data(CSST_out.Time.data >= 30);
dt = time(2)-time(1);
freq_range = [0 4.5];
t_man_start = 30;  % seconds

[H_yr f_yr] = fft_tf( CSST_out.Driver_Steer_Ang.data(CSST_out.Time.data >= t_man_start),...
                      CSST_out.Car_YawRate.data(CSST_out.Time.data >= t_man_start),...
                      freq_range, dt );
firf = designfilt('lowpassfir','FilterOrder',50,'CutoffFrequency',1,'SampleRate',1/dt);
H_yr_ftr   = filtfilt(firf,H_yr);

[H_ay f_yr] = fft_tf( CSST_out.Driver_Steer_Ang.data(CSST_out.Time.data >= t_man_start),...
                      CSST_out.Car_ay.data(CSST_out.Time.data >= t_man_start),...
                      freq_range, dt );
firf = designfilt('lowpassfir','FilterOrder',50,'CutoffFrequency',1,'SampleRate',1/dt);
H_ay_ftr   = filtfilt(firf,H_ay);



[val idx] = min(abs(phase(H_yr)*180/pi+45))
idx = floor(interp1(phase(H_yr)*180/pi,1:numel(H_yr),-45));
KPI.CSST.Teq_yr = 1/(2*pi*f_yr(idx));

idx = floor(interp1(phase(H_ay)*180/pi,1:numel(H_yr),-45));
KPI.CSST.Teq_ay = 1/(2*pi*f_yr(idx));


plot_freq_range = [0 4];
subplot(2,3,1)
plot(f_yr, abs(H_yr), 'Color',[0.8 0.8 0.8]); hold on; 
plot(f_yr, abs(H_yr_ftr), 'LineWidth',2); hold off;
xlabel('Frequency [Hz]')
ylabel('MOD (Yaw Rate / Steering Wheel Angle)')
xlim(plot_freq_range)
grid on

subplot(2,3,4)
plot(f_yr, phase(H_yr)*180/pi, 'Color',[0.8 0.8 0.8]); hold on; 
plot(f_yr, phase(H_yr_ftr)*180/pi, 'LineWidth',2); hold off;
xlabel('Frequency [Hz]')
ylabel('PHASE (Yaw Rate / Steering Wheel Angle)')
xlim(plot_freq_range)
grid on

subplot(2,3,2)
plot(f_yr,abs(H_ay), 'Color',[0.8 0.8 0.8]); hold on; 
plot(f_yr, abs(H_ay_ftr), 'LineWidth',2); hold off;
xlabel('Frequency [Hz]')
ylabel('MOD (Lat. Acc. / Steering Wheel Angle)')
xlim(plot_freq_range)
grid on

subplot(2,3,5)
plot(f_yr, phase(H_ay)*180/pi, 'Color',[0.8 0.8 0.8]); hold on; 
plot(f_yr, phase(H_ay_ftr)*180/pi, 'LineWidth',2); hold off;
xlabel('Frequency [Hz]')
ylabel('PHASE (Lat. Acc. / Steering Wheel Angle)')
xlim(plot_freq_range)
grid on

subplot(2,3,6)
cm = colormap(lines(2))
plot(f_yr, (phase(H_ay_ftr)-phase(H_yr_ftr))*180/pi, 'LineWidth',2, 'Color', cm(2,:));
xlabel('Frequency [Hz]')
ylabel('PHASE (Lat. Acc. / Yaw Rate)')
xlim(plot_freq_range)
grid on

spl = subplot(2,3,3)
cm = colormap(lines(2));
scatter(KPI.CSST.Teq, abs(H_yr_ftr(1)), 'markerfacecolor', cm(2,:), 'markeredgecolor', cm(2,:));
xlabel('Equivalent Time Delay [s]')
ylabel('Stat. Yaw Gain [1/s]')
xlim([0 0.3])
ylim([0 2])
text( (spl.XLim(2)-spl.XLim(1))*0.1+spl.XLim(1) ,(spl.YLim(2)-spl.YLim(1))*0.5+spl.YLim(1),'Agil');
text( (spl.XLim(2)-spl.XLim(1))*0.75+spl.XLim(1) ,(spl.YLim(2)-spl.YLim(1))*0.5+spl.YLim(1),'Sluggish');
text( (spl.XLim(2)-spl.XLim(1))*0.5+spl.XLim(1) ,(spl.YLim(2)-spl.YLim(1))*0.9+spl.YLim(1),'Direct','HorizontalAlignment','center');
text( (spl.XLim(2)-spl.XLim(1))*0.5+spl.XLim(1) ,(spl.YLim(2)-spl.YLim(1))*0.1+spl.YLim(1),'Indirect','HorizontalAlignment','center');
grid on




%% ACC

ACC_out  = cmread(fullfile(results_folder,'ACC_FSG.erg'));
 
tabname = 'ACC';
if ~isempty(tgroup.Children) tgroup.Children( find(ismember({tgroup.Children.Title},tabname))).delete; end
tab_ACC = uitab('Parent', tgroup, 'Title', tabname, 'BackgroundColor', 'white');
tgroup.SelectedTab = tab_ACC;
axes('parent',tab_ACC, 'Color','white')

lw = 1.5;

st_begin = find( ACC_out.Car_tx.data >= (ACC_out.Car_tx.data(1)+0.05) ,1);
st_end   = find( ACC_out.Car_tx.data >= (75) ,1);
ACC_out.Time.data = ACC_out.Time.data - ACC_out.Time.data(st_begin);
idx = st_begin:st_end;

KPI.ACC.acc_time = ACC_out.Time.data(idx(end));

subplot(2,2,1)
yyaxis left
plot(ACC_out.Time.data(idx), ACC_out.Car_tx.data(idx),'LineWidth',lw); hold on;
ylabel( [ACC_out.Car_tx.name ' [' ACC_out.Car_tx.unit ']'])
yyaxis right
plot(ACC_out.Time.data(idx), ACC_out.Car_vx.data(idx)*3.6,'LineWidth',lw); hold off;
ylabel( [ACC_out.Car_vx.name ' [km/h]'])
xlabel( [ACC_out.Time.name ' [' ACC_out.Time.unit ']'])
grid on

subplot(2,2,2)
yyaxis left
plot(ACC_out.Time.data(idx), ACC_out.Driver_Clutch.data(idx),'LineWidth',lw); hold on;
ylabel( [ACC_out.Driver_Clutch.name ' [%]'])
ylim([-0.2 1.2])
yyaxis right
plot(ACC_out.Time.data(idx), ACC_out.Driver_Gas.data(idx),'LineWidth',lw); hold off;
ylabel( [ACC_out.Driver_Gas.name ' [%]'])
ylim([-0.2 1.2])
xlabel( [ACC_out.Time.name ' [' ACC_out.Time.unit ']'])
grid on

subplot(2,2,3)
hold on;
lgd = {};
for i=1:6
    idx_gn = (ACC_out.Driver_GearNo.data(idx)==i);
    plot(ACC_out.PT_Engine_rotv.data(idx(idx_gn)), ACC_out.PT_Engine_Trq.data(idx(idx_gn)),'LineWidth',lw)
    lgd(end+1) = {['Gear ' num2str(i)]};
end
xlabel( [ACC_out.PT_Engine_rotv.name ' [' ACC_out.PT_Engine_rotv.unit ']'])
ylabel( [ACC_out.PT_Engine_Trq.name ' [' ACC_out.PT_Engine_Trq.unit ']'])
legend(lgd);
grid on


wheel_trq = (ACC_out.Car_FxRL.data       + ACC_out.Car_FxRR.data)/2 .* ...
            (ACC_out.Car_WRL_Radius.data + ACC_out.Car_WRR_Radius.data)/2;
wheel_speed = (ACC_out.Car_WheelSpd_RL.data + ACC_out.Car_WheelSpd_RR.data)/2;

subplot(2,2,4)
hold on;
lgd = {};
for i=1:6
    idx_gn = (ACC_out.Driver_GearNo.data(idx)==i);
    plot(ACC_out.Car_v.data(idx(idx_gn))*3.6, wheel_trq(idx(idx_gn)),'LineWidth',lw);
    lgd(end+1) = {['Gear ' num2str(i)]};
end
ylabel('Wheel Torque [Nm]')
xlabel( [ACC_out.Car_v.name ' [km/h]'])
legend(lgd);
grid on
