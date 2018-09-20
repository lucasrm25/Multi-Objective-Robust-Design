classdef DoE_plot < handle

    properties
        KPI @man.KPI
        DP  @man.DP
    end

    methods
        
        function getGUIres(obj, list_DP, list_KPI)
            obj.DP  = obj.DP(list_DP.Value);
            obj.KPI = obj.KPI(list_KPI.Value);
            close(gcf);
        end
        
        function obj = DoE_plot(DP, KPI)
            obj.KPI = KPI;
            obj.DP = DP;
            
            fig = figure('WindowStyle','modal', 'Color','white','Position',[300 300 500 300]); %modal
            list_DP = uicontrol('Style','listbox', 'Position', [20 130 200 150]); %x y lar alt
            list_DP.Max = 2;
            list_DP.Min = 0;
            list_DP.String = {DP.name};
            
            list_KPI = uicontrol('Style','listbox', 'Position', [250 130 200 150]); %x y lar alt
            list_KPI.Max = 2;
            list_KPI.Min = 0; 
            list_KPI.String = {KPI.cname};
            
            btn = uicontrol('Style', 'pushbutton', 'String', 'Add Plot',...
                            'Position', [20 20 50 20],...
                            'Callback', 'close(gcf)');
            btn.Callback = @(src,event) getGUIres(obj, list_DP, list_KPI);
            
            waitfor(fig)    
        end
    end
    
end