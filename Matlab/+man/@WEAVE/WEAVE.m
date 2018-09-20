classdef WEAVE < handle
    
    properties
        folder
        data
        KPI @man.KPI
        intData % interpolation data resulted from calculations for each velocity
    end
    
    properties (Constant)
        file = '*WEAVE_Speed_*.erg'
    end
    
    methods (Static)
        
    end
    
    methods  
        function bool = exists(obj,folder)
            bool = ~isempty(folder) && ~isempty(dir(fullfile(folder,obj.file)));
        end

        function obj = WEAVE(folder)
            obj.folder = folder;
            if exists(obj, folder)
                nfiles = dir(fullfile(folder, obj.file));

                obj.data = cmread(fullfile(folder,nfiles(1).name));  % INIT Struct
                for i=1:numel(nfiles)
                    obj.data(i)  = cmread(fullfile(folder,nfiles(i).name));
                    obj.intData.vel(i)   = mean(obj.data(i).Car_v.data(obj.data(i).Time.data > 40)) *3.6;

                %     figure
                %     plot(obj.data(i).Time.data, obj.data(i).Driver_Steer_Ang.data)

                    idx_cut = obj.data(i).Time.data >= (obj.data(i).Time.data(end) - 30);

                    weave_swa  = sort( obj.data(i).Driver_Steer_Ang.data( idx_cut ) ); 
                    weave_yr   = sort( obj.data(i).Car_YawRate.data( idx_cut ) );
                    weave_ay   = sort( obj.data(i).Car_ay.data( idx_cut ) );
                    weave_lm   = sort( obj.data(i).Driver_Steer_Trq.data( idx_cut ) );

                    % get the peak values for each oscillatory signal
                    obj.intData.yawgain(i) = mean(weave_yr(end-5:end)) / mean(weave_swa(end-5:end));
                    obj.intData.aygain(i)  = mean(weave_ay(end-5:end)) / mean(weave_swa(end-5:end));
                    obj.intData.swa(i)     = mean(weave_swa(end-5:end));
                    obj.intData.lm_yr(i)   = mean(weave_yr(end-5:end)) / mean(weave_lm(end-5:end));
                end

                % sort velocities
                [obj.intData.vel0, idxs] = sort([0 obj.intData.vel]);
                obj.intData.yawgain = [0 obj.intData.yawgain]; obj.intData.yawgain = obj.intData.yawgain(idxs);
                obj.intData.aygain  = [0 obj.intData.aygain];  obj.intData.aygain  = obj.intData.aygain(idxs);

                [obj.intData.vel, idxs] = sort([obj.intData.vel]);
                obj.intData.swa   = obj.intData.swa(idxs) * 180/pi;
                obj.intData.lm_yr = obj.intData.lm_yr(idxs);
            end
        end
        
        function KPI = calcKPI (obj)
            if isempty(obj.data), return; end

            vels = [20 40 60 80 100];
            for i=1:numel(vels)
                obj.KPI(end+1) = man.KPI();
                obj.KPI(end).value = spline(obj.intData.vel0, obj.intData.yawgain, vels(i));
                obj.KPI(end).unit  = '1/s';
                obj.KPI(end).name  = ['Yaw Gain at ' num2str(vels(i)) 'km/h'];
                obj.KPI(end).cname  = ['WEAVE_YawGain_at_' num2str(vels(i))];
            end 
            KPI = obj.KPI;
        end
        
        function plot (obj)
            if isempty(obj.data), return; end
            
            fs = 8;
            cl = 'k';
            lw = 2;

            sp = subplot(2,2,1);
            scatter(obj.intData.vel0,obj.intData.yawgain, 'markerfacecolor', cl, 'markeredgecolor', cl);
            x_int = 0:.01:120;
            s_int = spline(obj.intData.vel0,obj.intData.yawgain,x_int);
            hold on; plot(x_int,s_int, 'LineWidth',lw, 'Color',cl);
            ylim([0 1.2*max(obj.intData.yawgain)])
            xlabel('Car.v [km/h]')
            ylabel('Yaw Gain [1/s]')
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(2,2,2);
            scatter(obj.intData.vel0,obj.intData.aygain, 'markerfacecolor', cl, 'markeredgecolor', cl);
            x_int = 0:.01:120;
            s_int = spline(obj.intData.vel0,obj.intData.aygain,x_int);
            hold on; plot(x_int,s_int, 'LineWidth',lw, 'Color',cl);
            ylim([0 1.2*max(obj.intData.aygain)])
            xlabel('Car.v [km/h]')
            ylabel('Ay Gain [m/s^2/deg]')
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(2,2,3);
            scatter(obj.intData.vel,obj.intData.swa, 'markerfacecolor', cl, 'markeredgecolor', cl);
            x_int = 0:.01:120;
            s_int = spline(obj.intData.vel,obj.intData.swa,x_int);
            hold on; plot(x_int,s_int, 'LineWidth',lw, 'Color',cl);
            ylim([0 1.2*max(obj.intData.swa)])
            xlabel('Car.v [km/h]')
            ylabel('Steering Wheel Angle at 4m/s^2 [deg]')
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(2,2,4);
            scatter(obj.intData.vel,obj.intData.lm_yr, 'markerfacecolor', cl, 'markeredgecolor', cl);
            x_int = 0:.01:120;
            s_int = spline(obj.intData.vel,obj.intData.lm_yr,x_int);
            hold on; plot(x_int,s_int, 'LineWidth',lw, 'Color',cl);
            ylim([0 1.2*max(obj.intData.lm_yr)])
            xlabel('Car.v [km/h]')
            ylabel('Yaw Rate to SteerTorq [deg/s/Nm]')
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on
        end
    end 
end

