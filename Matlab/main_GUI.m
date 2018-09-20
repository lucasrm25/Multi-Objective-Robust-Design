classdef main_GUI < handle%% h_main_GUI = main_GUI(results_folder);
    
    properties
        gui_f
        gui_h
        init_folder
        sim             % simulation class
        maneval         % maneuver evaluation class
        
        SWD_SF_KPI = 4
        plots_per_tab = 6;
        
        tabGroup     = gobjects(0,0)
        tabs         = gobjects(0,0)
        subplot_axes = gobjects(0,0)
    end
    
    methods
        function obj = main_GUI(init_folder)
            obj.init_folder = init_folder;
            obj.gui_f = SS_GUI;
            obj.gui_h = guihandles(obj.gui_f);
        
            obj.gui_h.fig_SS_GUI.CloseRequestFcn        = @(src,event) Close_fcn(obj, src, event);
            obj.gui_h.evalSim.Callback                  = @(src,event) evalSim(obj, src, event);
            obj.gui_h.new_DoE_Analysis.Callback         = @(src,event) new_DoE_Analysis(obj, src, event);
            obj.gui_h.new_DoE_NN.Callback               = @(src,event) new_DoE_NN(obj, src, event);
            obj.gui_h.Save.Callback                     = @(src,event) save(obj, src, event);
            obj.gui_h.Load.Callback                     = @(src,event) load(obj, src, event);
            obj.gui_h.table_KPI.CellEditCallback        = @(src,event) table_KPI_CellEdit(obj, src, event);
            obj.gui_h.table_DP.CellEditCallback         = @(src,event) table_DP_CellEdit(obj, src, event);
            obj.gui_h.tool_plot.ClickedCallback         = @(src,event) plot(obj, src, event);
            obj.gui_h.tool_addPlot.ClickedCallback      = @(src,event) addPlot(obj, src, event);
            obj.gui_h.tool_find_Sol_box.ClickedCallback = @(src,event) find_SS(obj, src, event);
            obj.gui_h.tool_IPP_plot.ClickedCallback     = @(src,event) IPP_Plot(obj, src, event);
            obj.gui_h.tool_save_plots.ClickedCallback   = @(src,event) save_plots(obj, src, event);
            
            delete(obj.gui_h.Panel_plot.Children);     % clear gui parent object
            obj.tabGroup = uitabgroup('Parent', obj.gui_h.Panel_plot, 'Tag','TabGroup');
            
            obj.gui_f.WindowButtonUpFcn     = @(src,event) lineDrop (obj, src, event);
            obj.gui_f.WindowButtonMotionFcn = @(src,event) lineDrag (obj, src, event);
        end
        
        function find_SS(obj, src, event)
            obj.sim.find_SS;
            obj.sim.plotSS(obj.subplot_axes)
        end
        
        function lineDrag(obj, src, event)
            if ~isempty(obj.sim) && ~isempty(obj.sim.DP_draging)
                curPoint = get(gca,'CurrentPoint');
                if curPoint(1,1) > obj.sim.DP_draging.design_box(1) && curPoint(1,1) < obj.sim.DP_draging.design_box(2) &&...
                   curPoint(1,2) > obj.sim.DP_draging.design_box(1) && curPoint(1,2) < obj.sim.DP_draging.design_box(2) && ...
                   obj.sim.DP_draging.solution_box(1) <= obj.sim.DP_draging.solution_box(2)
                    switch obj.sim.bound_draging
                        case 'lx'
                            obj.sim.DP_draging.solution_box(1) = min( curPoint(1,1), obj.sim.DP_draging.solution_box(2) );
                        case 'ux'
                            obj.sim.DP_draging.solution_box(2) = max( curPoint(1,1), obj.sim.DP_draging.solution_box(1) );
                        case 'ly'
                            obj.sim.DP_draging.solution_box(1) = min( curPoint(1,2), obj.sim.DP_draging.solution_box(2) );
                        case 'uy'
                            obj.sim.DP_draging.solution_box(2) = max( curPoint(1,2), obj.sim.DP_draging.solution_box(1) );
                    end
                    obj.sim.plotSS(obj.subplot_axes);
                    obj.refresh_DP_Tab(obj.sim.DP);
                end
            end
        end
        
        function lineDrop(obj, src, event)
            if ~isempty(obj.sim)
                obj.sim.DP_draging = man.DP.empty;
                obj.sim.bound_draging = '';
            end
        end
        
        function table_KPI_CellEdit(obj, src, event)
            KPI_idx = ismember({obj.sim.KPI.cname}, obj.gui_h.table_KPI.Data(event.Indices(1),1));
            obj.sim.KPI(KPI_idx).target(1) = obj.gui_h.table_KPI.Data{event.Indices(1),3};
            obj.sim.KPI(KPI_idx).target(2) = obj.gui_h.table_KPI.Data{event.Indices(1),4};
            obj.sim.KPI(KPI_idx).color     = obj.gui_h.table_KPI.Data{event.Indices(1),5};
            
            obj.refresh_KPI_Tab(obj.sim.KPI);
            obj.plot();
        end
        
        function table_DP_CellEdit(obj, src, event)
            DP_idx = ismember({obj.sim.DP.name}, obj.gui_h.table_DP.Data(event.Indices(1),1));
            new_sol_box = [obj.gui_h.table_DP.Data{event.Indices(1),3:4}];
            new_sol_box = max(min(new_sol_box,obj.sim.DP(DP_idx).design_box(2)),obj.sim.DP(DP_idx).design_box(1));           
            obj.sim.DP(DP_idx).solution_box = new_sol_box;
            
            obj.refresh_DP_Tab(obj.sim.DP);
            obj.plot();
        end
        
        function plot(obj, src, event)
            if ~isempty(obj.sim)
                obj.sim.plotSS(obj.subplot_axes);
            end
        end
        
        function deletePlot(obj, src, event, Plotnumber)
            if (event.Button == 3)  % mouse right click
                button = questdlg(sprintf('Would you really like to delete plot number: %d ?',Plotnumber),...
                                  'Delete Plot','Yes','No','Yes');
                if strcmp(button, 'Yes')
                    obj.sim.plots(Plotnumber) = [];
                    for i=1:numel(obj.sim.plots)
                        obj.subplot_axes(i).ButtonDownFcn =  @(src,event) deletePlot(obj, src, event, i);
                    end
                    obj.resetPlots;
                    obj.plot();
                end
            end
        end
        
        function addPlot(obj, src, event)
            new_plot = DoE.DoE_plot(obj.sim.DP, obj.sim.KPI);

            if numel(new_plot.DP) ~= 2      % Do nothing if exactly 2 design parameters have not been selected
                uiwait(msgbox('(2) Design Parameters must be selected','Error','modal'));
                return;
            end
            obj.sim.plots = [obj.sim.plots new_plot];
            if mod(numel(obj.sim.plots),obj.plots_per_tab)==1
                obj.tabs(end+1) = uitab('Parent', obj.tabGroup, 'Title', 'Solution Spaces', 'BackgroundColor', 'white');
            end
            obj.subplot_axes(end+1) = subplot(2,3, mod(numel(obj.sim.plots)-1,obj.plots_per_tab)+1 , 'parent',obj.tabs(end), 'Color','white');
            obj.subplot_axes(end).ButtonDownFcn =  @(src,event) deletePlot(obj, src, event, numel(obj.sim.plots));
            obj.plot();
        end
        
        function load(obj, src, event)
            [lfile, lfolder]= uigetfile({'*.dcm; *.dnn','DoE Files'},'Open DoE file',...
                                        fullfile(obj.init_folder));
            if isa(lfile,'double'), return; end       
            lvar = load(fullfile(lfolder,lfile), '-mat');
            name = fieldnames(lvar);
            obj.sim = lvar.(name{1});
            
            obj.resetPlots;
            obj.plot();           
            obj.refresh_KPI_Tab(obj.sim.KPI);
            obj.refresh_DP_Tab(obj.sim.DP);
        end
        
        function save(obj, src, event)
            if ~isempty(obj.sim)
                obj.sim.save(obj.init_folder);
            end
        end
        
        function obj = new_DoE_NN(obj, src, event)
            obj.sim = DoE.DoE_NN(obj.init_folder, obj.gui_h.Panel_plot);
            obj.deletePlots;
            obj.plot();
            obj.refresh_KPI_Tab(obj.sim.KPI);
            obj.refresh_DP_Tab(obj.sim.DP);
        end
        
        function obj = new_DoE_Analysis(obj, src, event)
            obj.sim = DoE.DoE_CM(obj.init_folder, obj.gui_h.Panel_plot);
            obj.deletePlots;
            obj.plot();
            obj.refresh_KPI_Tab(obj.sim.KPI);
            obj.refresh_DP_Tab(obj.sim.DP);
        end
        
        function deletePlots(obj)
            delete(obj.subplot_axes);
            obj.subplot_axes = gobjects(0,1);    % preallocate graphics obj
            delete(obj.tabGroup.Children);
            obj.tabs = gobjects(0,1);    % preallocate graphics obj
            obj.sim.plots = DoE.DoE_plot.empty;
        end
        
        function resetPlots(obj)
            delete(obj.subplot_axes);
            obj.subplot_axes = gobjects(numel(obj.sim.plots),1);    % preallocate graphics obj
            delete(obj.tabGroup.Children);
            obj.tabs = gobjects(ceil(numel(obj.sim.plots)/obj.plots_per_tab),1);    % preallocate graphics obj
            for i=1:numel(obj.sim.plots)
                if mod(i,obj.plots_per_tab)==1
                    obj.tabs(end+1) = uitab('Parent', obj.tabGroup, 'Title', 'Solution Spaces', 'BackgroundColor', 'white');
                end
                obj.subplot_axes(i) = subplot(2,3, mod(i-1,obj.plots_per_tab)+1 , 'parent',obj.tabs(end), 'Color','white');
                obj.subplot_axes(i).ButtonDownFcn =  @(src,event) deletePlot(obj, src, event, i);  
            end
        end
        
        function obj = evalSim(obj, src, event)
            fig_man = figure('Color','white','Visible','off');
            obj.maneval = DoE.ManEval(obj.init_folder, fig_man);
            figure(fig_man);    % set(0,'CurrentFigure',fig_man); fig_man.Visible = 'on';
            obj.maneval.plot;
            
            for i=1:numel(obj.maneval.KPI), obj.gui_h.table_KPI.Data{i,2} = obj.maneval.KPI(i).value;   end
            for i=1:numel(obj.maneval.DP),  obj.gui_h.table_DP.Data{i,2}  = obj.maneval.DP(i).value;    end
            for i=1:numel(obj.maneval.KPI), obj.gui_h.table_KPI.Data{i,1} = obj.maneval.KPI(i).cname;    end
        end
        
        function refresh_DP_Tab(obj, DP)
            for i=1:numel(DP)
                obj.gui_h.table_DP.Data{i,1} = DP(i).name;
                obj.gui_h.table_DP.Data{i,2} = DP(i).value;
                obj.gui_h.table_DP.Data{i,3} = DP(i).solution_box(1);
                obj.gui_h.table_DP.Data{i,4} = DP(i).solution_box(2);
            end
        end
        
        function refresh_KPI_Tab(obj, KPI)
            for i=1:numel(KPI)
                obj.gui_h.table_KPI.Data{i,1} = KPI(i).cname;
                obj.gui_h.table_KPI.Data{i,2} = KPI(i).value;
                obj.gui_h.table_KPI.Data{i,3} = KPI(i).target(1);
                obj.gui_h.table_KPI.Data{i,4} = KPI(i).target(2);
                obj.gui_h.table_KPI.Data{i,5} = KPI(i).color;
            end
        end

        function delete(obj)
            obj.gui_h.fig_SS_GUI.CloseRequestFcn = '';
            delete(obj.gui_h.fig_SS_GUI);
            obj.gui_h = [];
        end
                
        function obj = Close_fcn(obj, src, event)
            delete(obj);
        end
        
        function save_plots(obj, src, event)
            out_path = fullfile(pwd, 'SS_plots');
            if ~exist(out_path,'dir')
                mkdir(out_path);
            end
            addpath(out_path)
            1;
        end
        
        function IPP_Plot(obj, src, event)
            bounds = obj.sim.DP;
            fig = figure('Position',[463.4000  579.4000  355.2000  309.6000],'Color','w');
            set(gcf,'DefaultTextInterpreter','none');
            hold on;
            xlim([0 1])
            ylim([-1  numel(bounds)-1])
%             title({'IPP Plot';''})
            grid on
            axis = gca;
            axis.YTick = 0:1:numel(bounds)-1;
            axis.YTickLabel = fliplr({obj.sim.DP.name});
%             axis.FontName = 'Courier';
            axis.TickLabelInterpreter = 'none';
            total_volume = 1;
            for i=1:numel(bounds)
                y_actual = numel(bounds)-i;
                xmin = (bounds(i).solution_box(1) - bounds(i).design_box(1))/(bounds(i).design_box(2) - bounds(i).design_box(1));
                xmax = (bounds(i).solution_box(2) - bounds(i).design_box(1))/(bounds(i).design_box(2) - bounds(i).design_box(1));
                offint = 0;
                sizint = 0.2;
                plot([xmin xmax], [y_actual y_actual],'k','LineWidth',2) 
                scatter(xmin, y_actual, 40, 'k', 'filled')
                scatter(xmax, y_actual, 40, 'k', 'filled')
                total_volume = total_volume*(xmax-xmin);
            end
            set(gca,'LooseInset',get(gca,'TightInset'));
            [filename, pathname] = uiputfile({'*.ps'},'Save as','C:\Users\Renata\Desktop\Bachelor Thesis\Latex\ch-Design-and-Solution-Spaces\figures\IPP_plot.ps');
            if filename ~= 0
                hgexport(fig,fullfile(pathname,filename));
            end
            fprintf('\nDie Lösungsbox macht %d%% vom gesamten Designraum\n',total_volume*100);
        end
    end
    
    
end

