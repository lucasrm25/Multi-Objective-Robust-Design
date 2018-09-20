classdef ACC < handle
    
    properties
        folder
        data
        KPI @man.KPI
        idx
    end
    
    properties (Constant)
        file = 'ACC_FSG.erg'
    end
    
    methods
        function bool = exists(obj, folder)
            bool = ~isempty(folder) && ~isempty(dir(fullfile(folder,obj.file)));
        end

        function obj = ACC(folder)
            obj.folder = folder;
            if exists(obj, folder)
                obj.data   = cmread(fullfile(folder,obj.file));
                st_begin = find( obj.data.Car_tx.data >= (obj.data.Car_tx.data(1)+0.05) ,1);
                st_end   = find( obj.data.Car_tx.data >= (75) ,1);
                obj.data.Time.data = obj.data.Time.data - obj.data.Time.data(st_begin);
                obj.idx = st_begin:st_end;
            end  
        end
        
        function KPI = calcKPI (obj)
            if isempty(obj.data), return; end

            obj.KPI(end+1)     = man.KPI;
            obj.KPI(end).value = obj.data.Time.data(obj.idx(end));
            obj.KPI(end).name  = 'Acceleration time - 75m';
            obj.KPI(end).unit  = 's';
            obj.KPI(end).cname = 'ACC_time_75m';
            
            KPI = obj.KPI;
        end
        
        function plot (obj)
            if isempty(obj.data), return; end

            lw = 1.5;
            
            subplot(2,2,1)
            yyaxis left
            plot(obj.data.Time.data(obj.idx), obj.data.Car_tx.data(obj.idx),'LineWidth',lw); hold on;
            ylabel( [obj.data.Car_tx.name ' [' obj.data.Car_tx.unit ']'])
            yyaxis right
            plot(obj.data.Time.data(obj.idx), obj.data.Car_vx.data(obj.idx)*3.6,'LineWidth',lw); hold off;
            ylabel( [obj.data.Car_vx.name ' [km/h]'])
            xlabel( [obj.data.Time.name ' [' obj.data.Time.unit ']'])
            grid on

            subplot(2,2,2)
            yyaxis left
            plot(obj.data.Time.data(obj.idx), obj.data.Driver_Clutch.data(obj.idx),'LineWidth',lw); hold on;
            ylabel( [obj.data.Driver_Clutch.name ' [%]'])
            ylim([-0.2 1.2])
            yyaxis right
            plot(obj.data.Time.data(obj.idx), obj.data.Driver_Gas.data(obj.idx),'LineWidth',lw); hold off;
            ylabel( [obj.data.Driver_Gas.name ' [%]'])
            ylim([-0.2 1.2])
            xlabel( [obj.data.Time.name ' [' obj.data.Time.unit ']'])
            grid on

            
            wheel_trq = (obj.data.Car_FxRL.data       + obj.data.Car_FxRR.data)/2 .* ...
                        (obj.data.Car_WRL_Radius.data + obj.data.Car_WRR_Radius.data)/2;
            wheel_speed = (obj.data.Car_WheelSpd_RL.data + obj.data.Car_WheelSpd_RR.data)/2;            
            
            
            subplot(2,2,3)
            hold on;
            lgd = {};
            for i=1:max(obj.data.Driver_GearNo.data)
                idx_gn = (obj.data.Driver_GearNo.data(obj.idx)==i);
%                 plot(obj.data.PT_Engine_rotv.data(obj.idx(idx_gn)), obj.data.PT_Engine_Trq.data(obj.idx(idx_gn)),'LineWidth',lw)
                plot(obj.data.PT_Engine_rotv.data(obj.idx(idx_gn)), wheel_trq(obj.idx(idx_gn)),'LineWidth',lw)
                lgd(end+1) = {['Gear ' num2str(i)]};
            end
            xlabel( [obj.data.PT_Engine_rotv.name ' [' obj.data.PT_Engine_rotv.unit ']'])
            ylabel( [obj.data.PT_Engine_Trq.name ' [' obj.data.PT_Engine_Trq.unit ']'])
            legend(lgd);
            grid on


            subplot(2,2,4)
            hold on;
            lgd = {};
            for i=1:max(obj.data.Driver_GearNo.data)
                idx_gn = (obj.data.Driver_GearNo.data(obj.idx)==i);
                plot(obj.data.Car_v.data(obj.idx(idx_gn))*3.6, wheel_trq(obj.idx(idx_gn)),'LineWidth',lw);
                lgd(end+1) = {['Gear ' num2str(i)]};
            end
            ylabel('Wheel Torque [Nm]')
            xlabel( [obj.data.Car_v.name ' [km/h]'])
            legend(lgd);
            grid on
        end
    end 
end

