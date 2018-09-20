classdef DoE_CM < handle
    properties
        KPI     @man.KPI
        DP      @man.DP
        plots   @DoE.DoE_plot
        
        good_perc = 0.95;
        nSamples = 200;
        
        DP_draging @man.DP
        bound_draging
    end
    
    properties (Constant)    
        colors = [128 215 0;            % light green
                  170 38  0;            % red
                  39  91  162;          % blue
                  232 121 252;          % violet
                  232 121 44;           % orange
                  20  253 254;          % light blue 
                  216 45  194]/256;     % pink
    end
    
    methods
        function obj = DoE_CM(varargin)
            if nargin < 1
                folder = 'C:';
            else
                folder = varargin{1};
            end
            obj.create(folder);
        end
        
        function save(obj, folder)
            [sfile, sfolder]= uiputfile({'*.dcm','DoE CarMaker File'},'Save DoE',...
                                        fullfile(folder,'DoE_CM.dcm'));
            if isa(sfile,'char')
                save(fullfile(sfolder, sfile), 'obj');
            end
        end
        
        function create(obj, direc)
            folder = uigetdir(direc,'Select the main folder');
            if isa(folder,'double'), return; end
            
            nfiles = dir(fullfile(folder, '*Variant*'));           
            h = waitbar(0,'Calculating DoE KPIs...');
            
            
%             use_parallel = true;
%             if use_parallel && isempty(gcp('nocreate'))
%                 parpool(6);
%             end
%             
%             man_names = what('man');
%             parfor i=1:numel(nfiles)   % for each DoE folder
%                 import man.*
%                 waitbar(i/numel(nfiles))
%                 folder_man = fullfile(folder, nfiles(i).name);        
%                 for j=1:numel(man_names.classes)    % for each maneuver
%                     maneuver = man.(man_names.classes{j}) (folder_man);
%                     if maneuver.exists(folder_man)
%                         KPIs{i,j} = maneuver.calcKPI;
%                     end
%                 end
%             end
                    
            for i=1:numel(nfiles)   % for each DoE folder
                waitbar(i/numel(nfiles))
                folder_man = fullfile(folder, nfiles(i).name);        
                man_names = what('man');
                for j=1:numel(man_names.classes)    % for each maneuver
                    maneuver = man.(man_names.classes{j}) (folder_man);
                    if maneuver.exists(folder_man)
                        maneuver.calcKPI;
                        for k=1:numel(maneuver.KPI)     % for each KPI
                            KPI_idx = find(ismember({obj.KPI.cname}, maneuver.KPI(k).cname));
                            if isempty(KPI_idx)
                                maneuver.KPI(k).sim_fun = maneuver.KPI(k).value;
                                maneuver.KPI(k).color = randi(size(obj.colors,1)-1) +1;     % if KPI is new, set a color
                                obj.KPI = [obj.KPI maneuver.KPI(k)];
                            else                                
                                obj.KPI(KPI_idx).sim_fun(end+1) = maneuver.KPI(k).value; 
                            end
                        end
                    end
                end
   
                fileID = fopen(fullfile(folder_man,'DoEInfo.txt'),'r');
                fileData = textscan(fileID,'%s %f');
                fclose(fileID);
                
                for j=1:numel(fileData{1})
                    DP_idx = find(ismember({obj.DP.name}, fileData{1}{j}));
                    if isempty(DP_idx)
                        dp_new = man.DP;
                        dp_new.name    = fileData{1}{j};
                        dp_new.value   = fileData{2}(j);
                        dp_new.sim_fun = fileData{2}(j);
                        obj.DP = [obj.DP dp_new];
                    else
                        obj.DP(DP_idx).sim_fun(end+1) = fileData{2}(j); 
                    end
                end
            end
            for i=1:numel(obj.DP)
                obj.DP(i).design_box   = [min(obj.DP(i).sim_fun) max(obj.DP(i).sim_fun)];
                obj.DP(i).solution_box = obj.DP(i).design_box;
            end
            close(h);
        end
                         
        function sim(obj, doePlot, nSamples)
            nSamples = min(nSamples, numel(obj.KPI(1).sim_fun));
            idx_projection = ones(1,numel(obj.KPI(1).sim_fun));
            for i=1:numel(obj.DP)
                if obj.DP(i) ~= doePlot.DP(1) && obj.DP(i) ~= doePlot.DP(2)
                    idxOut = obj.DP(i).sim_fun < obj.DP(i).solution_box(1) | obj.DP(i).sim_fun > obj.DP(i).solution_box(2);
                    idx_projection(idxOut) = 0;
                end
            end
            idx_projection = find(idx_projection);
            idxs = randperm( numel(idx_projection), min(nSamples,numel(idx_projection)) );
            for i=1:numel(obj.KPI)
                obj.KPI(i).sim_res = obj.KPI(i).sim_fun(idx_projection(idxs));
            end
            for i=1:numel(obj.DP)
                obj.DP(i).sim_res = obj.DP(i).sim_fun(idx_projection(idxs));
            end
        end
        
        function plotSS(obj, axes)
            for i=1:numel(obj.plots)
                obj.sim(obj.plots(i), obj.nSamples);
                color = ones(size(obj.plots(i).KPI(1).sim_res));
                for j=1:numel(obj.plots(i).KPI)
                    idxBad = obj.plots(i).KPI(j).sim_res > obj.plots(i).KPI(j).target(2) | ...
                             obj.plots(i).KPI(j).sim_res < obj.plots(i).KPI(j).target(1);
                    color(idxBad) = obj.plots(i).KPI(j).color;
                end
                
                idx_sol_space = ...
                obj.plots(i).DP(1).sim_res > obj.plots(i).DP(1).solution_box(1) & ...
                obj.plots(i).DP(1).sim_res < obj.plots(i).DP(1).solution_box(2) & ...
                obj.plots(i).DP(2).sim_res > obj.plots(i).DP(2).solution_box(1) & ...
                obj.plots(i).DP(2).sim_res < obj.plots(i).DP(2).solution_box(2);   
                good_perc = sum(color(idx_sol_space)==1)/sum(idx_sol_space);
                if good_perc >= obj.good_perc
                    colorGood = 'green';
                else
                    colorGood = 'red';
                end
                if numel(obj.plots(i).KPI)==1
                    title_firstname = obj.plots(i).KPI(1).cname;
                else
                    title_firstname = 'Multiple KPIs';
                end
                titlelab = { strrep(title_firstname,'_',' '), ['{\color' sprintf('{%s} Good: %4.1f%%}', colorGood, good_perc*100)] };

                % Plot samples
                hold(axes(i), 'on');
                delete(axes(i).Children);
                set(0,'defaulttextInterpreter','none')
                
                sct = scatter(axes(i), obj.plots(i).DP(1).sim_res, obj.plots(i).DP(2).sim_res, 50, obj.colors(color,:), 'filled'); 
                xlabel(axes(i), obj.plots(i).DP(1).name)
                ylabel(axes(i), obj.plots(i).DP(2).name) 
                title(axes(i), titlelab, 'Interpreter','tex')
                xlim(axes(i), obj.plots(i).DP(1).design_box)
                ylim(axes(i), obj.plots(i).DP(2).design_box)

                % Enable mouse click Callback
                sct.HitTest = 'on';
                sct.ButtonDownFcn       = axes(i).ButtonDownFcn;
                                            
                % Add dotted line constraining Solution Box         
                p1 = plot(axes(i), [obj.plots(i).DP(1).solution_box(1) obj.plots(i).DP(1).solution_box(1)], [obj.plots(i).DP(2).design_box(1) obj.plots(i).DP(2).design_box(2)],'--', 'Color', 'k', 'LineWidth',2);
                p2 = plot(axes(i), [obj.plots(i).DP(1).solution_box(2) obj.plots(i).DP(1).solution_box(2)], [obj.plots(i).DP(2).design_box(1) obj.plots(i).DP(2).design_box(2)],'--', 'Color', 'k', 'LineWidth',2);
                p3 = plot(axes(i), [obj.plots(i).DP(1).design_box(1) obj.plots(i).DP(1).design_box(2)], [obj.plots(i).DP(2).solution_box(1) obj.plots(i).DP(2).solution_box(1)],'--', 'Color', 'k', 'LineWidth',2);
                p4 = plot(axes(i), [obj.plots(i).DP(1).design_box(1) obj.plots(i).DP(1).design_box(2)], [obj.plots(i).DP(2).solution_box(2) obj.plots(i).DP(2).solution_box(2)],'--', 'Color', 'k', 'LineWidth',2);
                hold(axes(i), 'off');
                
                p1.ButtonDownFcn = @(src,event) lineButtonDown (obj, src, event, obj.plots(i).DP(1), 'lx');
                p2.ButtonDownFcn = @(src,event) lineButtonDown (obj, src, event, obj.plots(i).DP(1), 'ux');
                p3.ButtonDownFcn = @(src,event) lineButtonDown (obj, src, event, obj.plots(i).DP(2), 'ly');
                p4.ButtonDownFcn = @(src,event) lineButtonDown (obj, src, event, obj.plots(i).DP(2), 'uy');   
            end
        end
        
        function lineButtonDown(obj, ~, ~, DP, bound)
            obj.DP_draging = DP;
            obj.bound_draging = bound;
        end
        
        function find_SS(obj) 
        end
    end  
end



