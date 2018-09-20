classdef SWD_SF < handle
    
    properties
        folder
        data
        KPI @man.KPI
        SF
    end
    
    properties (Constant)
        file = 'SWD_SF_'
    end

    methods 
        function bool = exists(obj, folder, varargin)
            if isempty(varargin)
                bool = ~isempty(folder) && ~isempty(dir(fullfile(folder,[obj.file '*.erg'])));
            else
                sf = varargin{1};
                bool = ~isempty(folder) && ~isempty(dir(fullfile(folder,[obj.file num2str(sf) '.erg'])));
            end
        end
        
        function obj = SWD_SF(folder, varargin)
            obj.folder = folder;
            if ~obj.exists(folder), return; end
            
            if isempty(varargin)
                sf_files = dir(fullfile(folder,[obj.file '*.erg']));
                for i=1:numel(sf_files)
                    sf_numbers(i) = str2double(strrep(regexp(sf_files(i).name,'(\d+p?\d*)','match'), 'p','.'));
                end
                obj.SF = 3; %max(sf_numbers);
            else
                obj.SF = SF;                
            end           
            obj.data  = cmread(fullfile(folder,[obj.file num2str(obj.SF) '.erg']));
        end
        
        function KPI = calcKPI (obj)
            if isempty(obj.data), return; end
            
            obj.KPI(end+1)     = man.KPI;
            obj.KPI(end).value = max(abs(obj.data.Car_SideSlipAngle.data *180/pi));
            obj.KPI(end).name  = 'Maximal Car SideSlip Angle';
            obj.KPI(end).unit  = 'deg';
            obj.KPI(end).cname = 'SWD_SF_beta_max';

            obj.KPI(end+1)     = man.KPI;
            obj.KPI(end).value = max(abs(obj.data.Car_YawRate.data *180/pi));
            obj.KPI(end).name  = 'Maximal Yaw Rate';
            obj.KPI(end).unit  = 'deg/s';
            obj.KPI(end).cname = 'SWD_SF_yr_max';

            obj.KPI(end+1)     = man.KPI;
            obj.KPI(end).value = max(abs(obj.data.Car_ay.data));
            obj.KPI(end).name  = 'Maximal Lateral Acceleration';
            obj.KPI(end).unit  = 'm/s²';
            obj.KPI(end).cname = 'SWD_SF_ay_max';

            obj.KPI(end+1)     = man.KPI;
            obj.KPI(end).value = min([obj.data.Car_FzFL.data obj.data.Car_FzFR.data obj.data.Car_FzRL.data obj.data.Car_FzRR.data]);
            obj.KPI(end).name  = 'Minimal Tyre Normal Force';
            obj.KPI(end).unit  = 'N';
            obj.KPI(end).cname = 'SWD_SF_Fz_min';
            
            obj.KPI(end+1)     = man.KPI;
            if obj.data.Car_ty.data(end) <= 0
                obj.KPI(end).value = max(obj.data.Car_ty.data);
            else
                obj.KPI(end).value = NaN;
            end
            obj.KPI(end).name  = 'Minimal Lateral Displacement';
            obj.KPI(end).unit  = 'm';
            obj.KPI(end).cname = 'SWD_SF_dy_max';
            
            KPI = obj.KPI;
        end
        
        function plot (obj)
            if isempty(obj.data), return; end
            
            fs = 8;
            cl = 'k';
            lw = 2;
            
            t_peak = obj.data.Time.data(obj.data.Driver_Steer_Ang.data==max(obj.data.Driver_Steer_Ang.data));
            t_plot_range = [t_peak-0.5 t_peak+3];
            
            sp = subplot(3,3,1);
            plot(obj.data.Time.data,obj.data.Driver_Steer_Ang.data *180/pi, 'LineWidth',lw, 'Color',cl)
            xlabel( [obj.data.Time.name ' [' obj.data.Time.unit ']'])
            ylabel( [obj.data.Driver_Steer_Ang.name ' [deg]'])
            xlim(t_plot_range)
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(3,3,2);
            plot(obj.data.Time.data,obj.data.Car_v.data *3.6, 'LineWidth',lw, 'Color',cl)
            xlabel( [obj.data.Time.name ' [' obj.data.Time.unit ']'])
            ylabel( [obj.data.Car_v.name ' [' obj.data.Car_v.unit ']'])
            xlim(t_plot_range)
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(3,3,3);
            plot(obj.data.Time.data,obj.data.Car_SideSlipAngle.data *180/pi, 'LineWidth',lw, 'Color',cl)
            xlabel( [obj.data.Time.name ' [' obj.data.Time.unit ']'])
            ylabel( [obj.data.Car_SideSlipAngle.name ' [deg]'])
            xlim(t_plot_range)
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(3,3,4);
            plot(obj.data.Time.data,obj.data.Car_YawRate.data *180/pi, 'LineWidth',lw, 'Color',cl)
            xlabel( [obj.data.Time.name ' [' obj.data.Time.unit ']'])
            ylabel( [obj.data.Car_YawRate.name ' [deg/s]'])
            xlim(t_plot_range)
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(3,3,5);
            plot(obj.data.Time.data,obj.data.Car_ay.data, 'LineWidth',lw, 'Color',cl)
            xlabel( [obj.data.Time.name ' [' obj.data.Time.unit ']'])
            ylabel( [obj.data.Car_ay.name ' [' obj.data.Car_ay.unit ']'])
            xlim(t_plot_range)
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(3,3,6);
            plot(obj.data.Time.data, obj.data.Car_FzRL.data, 'LineWidth',lw, 'Color',cl); hold on
            plot(obj.data.Time.data, obj.data.Car_FzRR.data, 'LineWidth',lw, 'Color',cl);
            plot(obj.data.Time.data, obj.data.Car_FzFL.data, 'LineWidth',lw, 'Color',cl);
            plot(obj.data.Time.data, obj.data.Car_FzFR.data, 'LineWidth',lw, 'Color',cl);
            xlabel( [obj.data.Time.name ' [' obj.data.Time.unit ']'])
            ylabel( ['Tyre Normal Force [' obj.data.Car_FzRL.unit ']'])
            xlim(t_plot_range)
            ylim([0 inf])
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(3,3,7);
            plot(obj.data.Time.data, obj.data.Car_ty.data, 'LineWidth',lw, 'Color',cl);
            xlabel( [obj.data.Time.name ' [' obj.data.Time.unit ']'])
            ylabel( [obj.data.Car_ty.name ' [' obj.data.Car_ty.unit ']'])
            xlim(t_plot_range)
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(3,3,8);
            plot(obj.data.Time.data, obj.data.Driver_Steer_Trq.data, 'LineWidth',lw, 'Color',cl);
            xlabel( [obj.data.Time.name ' [' obj.data.Time.unit ']'])
            ylabel( [obj.data.Driver_Steer_Trq.name ' [' obj.data.Driver_Steer_Trq.unit ']'])
            xlim(t_plot_range)
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(3,3,9);
            plot(obj.data.Time.data, obj.data.Car_Roll.data *180/pi, 'LineWidth',lw, 'Color',cl);
            xlabel( [obj.data.Time.name ' [' obj.data.Time.unit ']'])
            ylabel( [obj.data.Car_Roll.name ' [deg]'])
            xlim(t_plot_range)
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on
        end
    end 
end


