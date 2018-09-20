classdef CSST < handle
    
    properties
        folder
        data
        KPI @man.KPI
        freqData
    end
    
    properties (Constant)
        file = 'CSST.erg'
    end
    
    methods 
        function KPI = getKPI(obj,name) 
            KPI = obj.KPI(find(ismember({obj.KPI.cname}, name)));
        end
        
        function bool = exists(obj, folder)
            bool = ~isempty(folder) && ~isempty(dir(fullfile(folder,obj.file)));
        end
        
        function obj = CSST(folder)
            obj.folder = folder;
            if exists(obj, folder)
                obj.data   = cmread(fullfile(folder,obj.file));

                time         = obj.data.Time.data(obj.data.Time.data >= 30);
                dt = time(2)-time(1);
                freq_range = [0.05 4.5];
                t_man_start = 30;  % seconds

                [obj.freqData.H_yr obj.freqData.f_yr] = fft_tf( obj.data.Driver_Steer_Ang.data(obj.data.Time.data >= t_man_start),...
                                                                obj.data.Car_YawRate.data(obj.data.Time.data >= t_man_start),...
                                                                freq_range, dt );
                firf = designfilt('lowpassfir','FilterOrder',50,'CutoffFrequency',1,'SampleRate',1/dt);
                obj.freqData.H_yr_ftr   = filtfilt(firf,obj.freqData.H_yr);

                [obj.freqData.H_ay obj.freqData.f_yr] = fft_tf( obj.data.Driver_Steer_Ang.data(obj.data.Time.data >= t_man_start),...
                                                                obj.data.Car_ay.data(obj.data.Time.data >= t_man_start),...
                                                                freq_range, dt );
                firf = designfilt('lowpassfir','FilterOrder',50,'CutoffFrequency',1,'SampleRate',1/dt);
                obj.freqData.H_ay_ftr   = filtfilt(firf,obj.freqData.H_ay);
            end
        end
        
        function KPI = calcKPI (obj)
            if isempty(obj.data), return; end

            idx = floor(interp1(phase(obj.freqData.H_yr)*180/pi,1:numel(obj.freqData.H_yr),-30));
            if isempty(idx) || isnan(idx)
                Teq_yr = NaN;
            else
                Teq_yr = 1/(obj.freqData.f_yr(idx));
            end
            obj.KPI(end+1)      = man.KPI;
            obj.KPI(end).value  = Teq_yr;
            obj.KPI(end).name = 'Equivalent Time Delay (YR to SWA)';
            obj.KPI(end).unit = 's';
            obj.KPI(end).cname = 'CSST_Teq_yr';

            idx = floor(interp1(phase(obj.freqData.H_ay)*180/pi,1:numel(obj.freqData.H_yr),-30));
            if isempty(idx) || isnan(idx)
                Teq_ay = NaN;
            else
                Teq_ay = 1/(obj.freqData.f_yr(idx));
            end
            obj.KPI(end+1)      = man.KPI;
            obj.KPI(end).value  = Teq_ay;
            obj.KPI(end).name = 'Equivalent Time Delay (Ay to SWA)';
            obj.KPI(end).unit = 's';
            obj.KPI(end).cname = 'CSST_Teq_ay';
            
            KPI = obj.KPI;
        end
        
        function plot (obj)
            if isempty(obj.data), return; end
            
            fs = 8;
            cl = 'k';
            lw = 2;
            
            plot_freq_range = [0 4];
            sp = subplot(2,3,1);
            plot(obj.freqData.f_yr, abs(obj.freqData.H_yr), 'Color',[0.8 0.8 0.8]); hold on; 
            plot(obj.freqData.f_yr, abs(obj.freqData.H_yr_ftr), 'LineWidth',lw, 'Color',cl); hold off;            
            xlabel('Frequency [Hz]')
            ylabel('MOD(Yaw Rate/SWA)')
            xlim(plot_freq_range)
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(2,3,4);
            plot(obj.freqData.f_yr, phase(obj.freqData.H_yr)*180/pi, 'Color',[0.8 0.8 0.8]); hold on; 
            plot(obj.freqData.f_yr, phase(obj.freqData.H_yr_ftr)*180/pi, 'LineWidth',lw, 'Color',cl); hold off;            
            xlabel('Frequency [Hz]')
            ylabel('PHASE(Yaw Rate/SWA)')
            xlim(plot_freq_range)
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(2,3,2);
            plot(obj.freqData.f_yr,abs(obj.freqData.H_ay), 'Color',[0.8 0.8 0.8]); hold on; 
            plot(obj.freqData.f_yr, abs(obj.freqData.H_ay_ftr), 'LineWidth',lw, 'Color',cl); hold off;            
            xlabel('Frequency [Hz]')
            ylabel('MOD(Lat.Acc./SWA)')
            xlim(plot_freq_range)
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(2,3,5);
            plot(obj.freqData.f_yr, phase(obj.freqData.H_ay)*180/pi, 'Color',[0.8 0.8 0.8]); hold on; 
            plot(obj.freqData.f_yr, phase(obj.freqData.H_ay_ftr)*180/pi, 'LineWidth',lw, 'Color',cl); hold off;            
            xlabel('Frequency [Hz]')
            ylabel('PHASE(Lat.Acc./SWA)')
            xlim(plot_freq_range)
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(2,3,6);
            cm = colormap(lines(2));
            plot(obj.freqData.f_yr, (phase(obj.freqData.H_ay_ftr)-phase(obj.freqData.H_yr_ftr))*180/pi, 'LineWidth',lw, 'Color',cl); %, 'Color', cm(2,:)
            xlabel('Frequency [Hz]')
            ylabel('PHASE(Lat.Acc./Yaw Rate)')
            xlim(plot_freq_range)
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on

            sp = subplot(2,3,3);
            cm = colormap(lines(2));
            scatter(obj.getKPI('CSST_Teq_yr').value, abs(obj.freqData.H_yr_ftr(1)), 'markerfacecolor', cl, 'markeredgecolor', cl);            
            xlabel('Equivalent Time Delay [s]')
            ylabel('Stat. Yaw Gain [1/s]')
            xlim([0.25 1])
            ylim([0 3])
            text( (sp.XLim(2)-sp.XLim(1))*0.1+sp.XLim(1) ,(sp.YLim(2)-sp.YLim(1))*0.5+sp.YLim(1),'Agile', 'FontSize',fs);
            text( (sp.XLim(2)-sp.XLim(1))*0.75+sp.XLim(1) ,(sp.YLim(2)-sp.YLim(1))*0.5+sp.YLim(1),'Sluggish', 'FontSize',fs);
            text( (sp.XLim(2)-sp.XLim(1))*0.5+sp.XLim(1) ,(sp.YLim(2)-sp.YLim(1))*0.9+sp.YLim(1),'Direct','HorizontalAlignment','center', 'FontSize',fs);
            text( (sp.XLim(2)-sp.XLim(1))*0.5+sp.XLim(1) ,(sp.YLim(2)-sp.YLim(1))*0.1+sp.YLim(1),'Indirect','HorizontalAlignment','center', 'FontSize',fs);
            sp.LabelFontSizeMultiplier = 1;
            sp.FontSize = fs;
            grid on
            
            
            set(gca,'LooseInset',get(gca,'TightInset'))
        end
    end 
end

