classdef SWD < handle
    
    properties
        folder
        data
        KPI @man.KPI
        dataPlot
    end
    
    properties (Constant)
        file = '*SWD_SF_*.erg'
    end

    methods
        function bool = exists(obj,folder)
            bool = ~isempty(folder) && ~isempty(dir(fullfile(folder,obj.file)));
        end

        function obj = SWD(folder)
            obj.folder = folder;
            if exists(obj, folder)
                nfiles = dir(fullfile(folder,obj.file));

                obj.data = cmread(fullfile(folder,nfiles(1).name));  % INIT Struct
                for i=1:numel(nfiles)
                    obj.data(i) = cmread(fullfile(folder,nfiles(i).name));
                    obj.dataPlot.swd_SF(i) = str2double(strrep(regexp(nfiles(i).name,'(\d+p?\d*)','match'), 'p','.'));

                    t_steer_peak  = obj.data(i).Time.data(obj.data(i).Driver_Steer_Ang.data==max(obj.data(i).Driver_Steer_Ang.data));
                    t_steer_end   = t_steer_peak + 1/0.7 * 3/4 + 0.5;
                    t_steer_begin = t_steer_peak - 1/0.7 * 1/4;
                    [~, idx_steer_begin] = min(abs(t_steer_begin-obj.data(i).Time.data));

                %     figure
                %     plot(obj.data(i).Time.data, obj.data(i).Car_YawRate.data)

                    obj.dataPlot.swd_yr_max(i)   = max(abs(obj.data(i).Car_YawRate.data));
                    obj.dataPlot.swd_yr_1s(i)    = spline(obj.data(i).Time.data, obj.data(i).Car_YawRate.data,  t_steer_end + 1);
                    obj.dataPlot.swd_yr_1p75s(i) = spline(obj.data(i).Time.data, obj.data(i).Car_YawRate.data,  t_steer_end + 1.75);
                    obj.dataPlot.swd_beta_max(i) = max(abs(obj.data(i).Car_SideSlipAngle.data));
                    obj.dataPlot.swd_dy_max(i)   = max(obj.data(i).Car_ty.data);
                    obj.dataPlot.swd_fz_min(i)   = min( [obj.data(i).Car_FzFL.data(idx_steer_begin:end), ...
                                                         obj.data(i).Car_FzFR.data(idx_steer_begin:end), ...
                                                         obj.data(i).Car_FzRL.data(idx_steer_begin:end), ...
                                                         obj.data(i).Car_FzRR.data(idx_steer_begin:end)]);
                    obj.dataPlot.swd_swa(i)      = max(obj.data(i).Driver_Steer_Ang.data);

                %     figure
                %     plot(obj.data(i).Time.data, obj.data(i).Car_ty.data)
                end
            end
        end

        
        function KPI = calcKPI (obj)
            if isempty(obj.data), return; end

            KPI = obj.KPI;
        end
        
        function plot (obj)
            if isempty(obj.data), return; end
            
            fs = 8;
            cl = 'k';
            lw = 2;

            xrange = [min(obj.dataPlot.swd_SF)-1 max(obj.dataPlot.swd_SF)+1];
            
            swd_yr_1s_perc    = abs(obj.dataPlot.swd_yr_1s./obj.dataPlot.swd_yr_max) *100;
            swd_yr_1p75s_perc = abs(obj.dataPlot.swd_yr_1p75s./obj.dataPlot.swd_yr_max) *100;

            sp = subplot(2,3,1);
            scatter(obj.dataPlot.swd_SF, obj.dataPlot.swd_swa *180/pi, 'markerfacecolor', cl, 'markeredgecolor', cl)
            x_int = (min(obj.dataPlot.swd_SF)-0.5):0.05:(max(obj.dataPlot.swd_SF)+0.5);
            s_int = pchip(obj.dataPlot.swd_SF, obj.dataPlot.swd_swa *180/pi, x_int);
            hold on; plot(x_int, s_int, 'LineWidth',lw, 'Color',cl);
            xlabel('Steering Factor')
            ylabel('SWA Amplitude [deg]')
            xlim(xrange)
            sp.LabelFontSizeMultiplier = 1;             
            sp.FontSize = fs;             
            grid on          
            
            sp = subplot(2,3,2);         
            scatter(obj.dataPlot.swd_SF, swd_yr_1s_perc, 'markerfacecolor', cl, 'markeredgecolor', cl)
            x_int = (min(obj.dataPlot.swd_SF)-0.5):0.05:(max(obj.dataPlot.swd_SF)+0.5);
            s_int = pchip(obj.dataPlot.swd_SF, swd_yr_1s_perc, x_int);
            hold on; plot(x_int,s_int, 'LineWidth',lw, 'Color',cl);
            xlabel('Steering Factor')
            ylabel('Yaw Rate(t=1s)/Yaw Rate Max[%]')
            xlim(xrange)
            ylim([-10 40])
            sp.LabelFontSizeMultiplier = 1;             
            sp.FontSize = fs;             
            grid on

            sp = subplot(2,3,3);            
            scatter(obj.dataPlot.swd_SF, swd_yr_1p75s_perc, 'markerfacecolor', cl, 'markeredgecolor', cl)
            x_int = (min(obj.dataPlot.swd_SF)-0.5):0.05:(max(obj.dataPlot.swd_SF)+0.5);
            s_int = pchip(obj.dataPlot.swd_SF, swd_yr_1p75s_perc, x_int);
            hold on; plot(x_int,s_int, 'LineWidth',lw, 'Color',cl);
            xlabel('Steering Factor')
            ylabel('Yaw Rate(t=1.75s)/Yaw Rate Max[%]')
            xlim(xrange)
            ylim([-10 40])
            sp.LabelFontSizeMultiplier = 1;             
            sp.FontSize = fs;             
            grid on

            sp = subplot(2,3,4);
            scatter(obj.dataPlot.swd_SF, obj.dataPlot.swd_dy_max, 'markerfacecolor', cl, 'markeredgecolor', cl)
            x_int = (min(obj.dataPlot.swd_SF)-0.5):0.05:(max(obj.dataPlot.swd_SF)+0.5);
            s_int = pchip(obj.dataPlot.swd_SF, obj.dataPlot.swd_dy_max, x_int);
            hold on; plot(x_int,s_int, 'LineWidth',lw, 'Color',cl);
            xlabel('Steering Factor')
            ylabel('Lateral Displacement [m]')
            xlim(xrange)
            % ylim([-10 40])
            sp.LabelFontSizeMultiplier = 1;             
            sp.FontSize = fs;             
            grid on

            sp = subplot(2,3,5);
            scatter(obj.dataPlot.swd_SF, obj.dataPlot.swd_beta_max *180/pi, 'markerfacecolor', cl, 'markeredgecolor', cl)
            x_int = (min(obj.dataPlot.swd_SF)-0.5):0.05:(max(obj.dataPlot.swd_SF)+0.5);
            s_int = pchip(obj.dataPlot.swd_SF, obj.dataPlot.swd_beta_max *180/pi, x_int);
            hold on; plot(x_int,s_int, 'LineWidth',lw, 'Color',cl);
            xlabel('Steering Factor')
            ylabel('Maximal SideSlipAngle [deg]')
            xlim(xrange)
            ylim([-10 40])
            sp.LabelFontSizeMultiplier = 1;             
            sp.FontSize = fs;             
            grid on

            sp = subplot(2,3,6);
            scatter(obj.dataPlot.swd_SF, obj.dataPlot.swd_fz_min, 'markerfacecolor', cl, 'markeredgecolor', cl)
            x_int = (min(obj.dataPlot.swd_SF)-0.5):0.05:(max(obj.dataPlot.swd_SF)+0.5);
            s_int = pchip(obj.dataPlot.swd_SF, obj.dataPlot.swd_fz_min, x_int);
            hold on; plot(x_int, s_int, 'LineWidth',lw, 'Color',cl);
            xlabel('Steering Factor')
            ylabel('Minimal Tyre Fz [N]')
            xlim(xrange)
            sp.LabelFontSizeMultiplier = 1;             
            sp.FontSize = fs;
            grid on
        end
    end 
end



