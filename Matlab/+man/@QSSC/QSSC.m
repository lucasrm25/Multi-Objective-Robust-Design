classdef QSSC < handle
    
    properties
        folder
        data
        KPI @man.KPI
    end
    
    properties (Constant)
        file = 'QSSC_50m.erg'
    end
    
    
    methods 
        function bool = exists(obj, folder)
            bool = ~isempty(folder) && ~isempty(dir(fullfile(folder,obj.file)));
        end
        
        function obj = QSSC(folder)
            obj.folder = folder;
            if ~exists(obj, folder), return; end  
            
            obj.data   = cmread(fullfile(folder,obj.file));
            
            % Yaw Rate calculation
            obj.data.Car_YawGain.data = obj.data.Car_YawRate.data ./ (obj.data.Driver_Steer_Ang.data);
            obj.data.Car_YawGain.unit = '1/s';
            obj.data.Car_YawGain.name = 'Car.YawGain';

            % Fz Difference calculation
            obj.data.Fz_diff_FA.data = (obj.data.Car_FzFL.data + obj.data.Car_FzFR.data) ./ (obj.data.Car_FzRL.data + obj.data.Car_FzRR.data) * 100;
            obj.data.Fz_diff_FA.unit = '%FA';
            obj.data.Fz_diff_FA.name = 'Fz Dfference % at Front Axle';
        end
        
        
        function KPI = calcKPI (obj)
            if isempty(obj.data), return; end
            
                idx = obj.data.Car_ay.data>2 & obj.data.Car_ay.data<4;
                X = [ones(length(obj.data.Car_ay.data(idx)),1) obj.data.Car_ay.data(idx)'];
                b = X\(obj.data.Driver_Steer_Ang.data(idx)' *180/pi);
            obj.KPI(end+1)     = man.KPI;
            obj.KPI(end).value = b(2);
            obj.KPI(end).name  = 'US Gradient - Linear (2<ay<4)';
            obj.KPI(end).unit  = 'deg/(m/s²)';
            obj.KPI(end).cname = 'QSSC_US_Grad_lin';
            
                idx = obj.data.Car_ay.data > 0.95*max(obj.data.Car_ay.data);
                X = [ones(length(obj.data.Car_ay.data(idx)),1) obj.data.Car_ay.data(idx)'];
                b = X\(obj.data.Driver_Steer_Ang.data(idx)' *180/pi);
            obj.KPI(end+1)     = man.KPI;
            obj.KPI(end).value = b(2);
            obj.KPI(end).name  = 'US Gradient - NonLinear (0.95*ay_max<ay<ay_max)';
            obj.KPI(end).unit  = 'deg/(m/s²)';
            obj.KPI(end).cname = 'QSSC_US_Grad_nonlin';

            obj.KPI(end+1)     = man.KPI;
            obj.KPI(end).value = max(obj.data.Car_ay.data);
            obj.KPI(end).name  = 'Maximal Lateral Acceleration';
            obj.KPI(end).unit  = 'm/s²';
            obj.KPI(end).cname = 'QSSC_ay_max';

            obj.KPI(end+1)     = man.KPI;
            obj.KPI(end).value = max(obj.data.Car_v.data( obj.data.Car_YawGain.data==max(obj.data.Car_YawGain.data) )) * 3.6;
            obj.KPI(end).name  = 'Characteristic/Critical Velocity';
            obj.KPI(end).unit  = 'km/h';
            obj.KPI(end).cname = 'QSSC_ch_cr_vel';

            obj.KPI(end+1)     = man.KPI;
            obj.KPI(end).value = max(abs(obj.data.Car_SideSlipAngle.data( obj.data.Car_ay.data==max(obj.data.Car_ay.data) ))) * 180/pi;
            obj.KPI(end).name  = 'Car SideSlip Angle at Maximal Lateral Acceleration';
            obj.KPI(end).unit  = 'deg';
            obj.KPI(end).cname = 'QSSC_beta_at_ay_max';

            obj.KPI(end+1)     = man.KPI;
            obj.KPI(end).value = max(obj.data.Driver_Steer_Trq.data);
            obj.KPI(end).name  = 'Maximal Steering Wheel Torque';
            obj.KPI(end).unit  = 'Nm';
            obj.KPI(end).cname = 'QSSC_StrWhelTrq_max';
            
            KPI = obj.KPI;
        end
        
        function plot (obj)
            if isempty(obj.data), return; end
            
            fs = 8;
            cl = 'k';
            lw = 2;
            
            sp = subplot(2,3,1);
            plot(obj.data.Car_ay.data, obj.data.Driver_Steer_Ang.data *180/pi, 'LineWidth',lw, 'Color',cl)
            xlabel( [obj.data.Car_ay.name ' [' obj.data.Car_ay.unit ']'])
            ylabel( [obj.data.Driver_Steer_Ang.name ' [deg]'])
            xlim([1.5 max(obj.data.Car_ay.data)+1])
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(2,3,2);
            plot(obj.data.Car_ay.data, obj.data.Car_SideSlipAngle.data *180/pi, 'LineWidth',lw, 'Color',cl)
            xlabel( [obj.data.Car_ay.name ' [' obj.data.Car_ay.unit ']'])
            ylabel( [obj.data.Car_SideSlipAngle.name ' [deg]'])
            xlim([1.5 max(obj.data.Car_ay.data)+1])
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(2,3,3);
            plot(obj.data.Car_ay.data, obj.data.Driver_Steer_Trq.data, 'LineWidth',lw, 'Color',cl)
            xlabel( [obj.data.Car_ay.name ' [' obj.data.Car_ay.unit ']'])
            ylabel( [obj.data.Driver_Steer_Trq.name ' [' obj.data.Driver_Steer_Trq.unit ']'])
            xlim([1.5 max(obj.data.Car_ay.data)+1])
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(2,3,4);
            plot(obj.data.Car_ay.data, obj.data.Car_Roll.data * 180/pi, 'LineWidth',lw, 'Color',cl)
            xlabel( [obj.data.Car_ay.name ' [' obj.data.Car_ay.unit ']'])
            ylabel( [obj.data.Car_Roll.name ' [deg]'])
            xlim([1.5 max(obj.data.Car_ay.data)+1])
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(2,3,5);
            plot(obj.data.Car_ay.data, obj.data.Fz_diff_FA.data, 'LineWidth',lw, 'Color',cl)
            xlabel( [obj.data.Car_ay.name ' [' obj.data.Car_ay.unit ']'])
            ylabel( strrep( [obj.data.Fz_diff_FA.name ' [' obj.data.Fz_diff_FA.unit ']'], '%','\%'))
            xlim([1.5 max(obj.data.Car_ay.data)+1])
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(2,3,6);
            plot(obj.data.Car_v.data*3.6, obj.data.Car_YawGain.data, 'LineWidth',lw, 'Color',cl)
            xlabel( [obj.data.Car_v.name ' [km/h]'])
            ylabel( [obj.data.Car_YawGain.name ' [' obj.data.Car_YawGain.unit ']'])
            ylim([0 min(10,max(obj.data.Car_YawGain.data)+1)])
            xlim([20 inf])
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on
        end
    end 
end

