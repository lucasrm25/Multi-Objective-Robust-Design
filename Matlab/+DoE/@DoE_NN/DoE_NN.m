classdef DoE_NN < handle

    properties
        KPI     @man.KPI
        DP      @man.DP
        plots   @DoE.DoE_plot
        
        good_perc = 0.95;
        nSamples = 5000;
        
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
        function obj = DoE_NN(varargin)
            if nargin < 1
                folder = 'C:';
            else
                folder = varargin{1};
            end
            obj.create(folder);
        end
        
        function save(obj, folder)
            [sfile, sfolder]= uiputfile({'*.dnn','DoE Neural Network File'},'Save DoE',...
                                        fullfile(folder,'DoE_NN.dnn'));
            if isa(sfile,'char')
                save(fullfile(sfolder, sfile), 'obj');
            end
        end
        
        function create(obj, direc)
            [lfile, lfolder]= uigetfile({'*.dcm','DoE CarMaker File'},'Open DoE file',direc);
            if isa(lfile,'double'), return; end  

            lvar = load(fullfile(lfolder,lfile), '-mat');
            name = fieldnames(lvar);
            obj.KPI   = lvar.(name{1}).KPI;
            obj.DP    = lvar.(name{1}).DP;
            obj.plots = lvar.(name{1}).plots;
            
            obj.train;
        end
                         
        function sim(obj, doePlot, nSamples)
            for i=1:numel(obj.DP)
                if obj.DP(i) ~= doePlot.DP(1) && obj.DP(i) ~= doePlot.DP(2)
                    X_data(i,:) = rand(1,nSamples)*(obj.DP(i).solution_box(2)-obj.DP(i).solution_box(1)) + obj.DP(i).solution_box(1);
                else
                    X_data(i,:) = rand(1,nSamples)*(obj.DP(i).design_box(2)-obj.DP(i).design_box(1)) + obj.DP(i).design_box(1);
                    obj.DP(i).sim_res = [];
                    obj.DP(i).sim_res = X_data(i,:);
                end                
                X_norm(i,:) = mapminmax('apply',X_data(i,:), obj.DP(i).sim_fun.set);
            end          
            for i=1:numel(doePlot.KPI)
                doePlot.KPI(i).sim_res = [];
                doePlot.KPI(i).sim_res = mapminmax('reverse', doePlot.KPI(i).sim_fun.net(X_norm), doePlot.KPI(i).sim_fun.set );
            end
        end
        
        function plotSS(obj, axes)
            for i=1:numel(obj.plots)
                obj.sim(obj.plots(i), obj.nSamples);
                color = ones(1,obj.nSamples);
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
                
                sct = scatter(axes(i), obj.plots(i).DP(1).sim_res, obj.plots(i).DP(2).sim_res, 10, obj.colors(color,:), 'filled'); 
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
           
        function fitnessvalue = ga_SS_PHASEONE(obj,vec)
            fitnessvalue = ones(1, size(vec,1));
            X_norm = zeros(numel(obj.DP), size(vec,1));
            for k=1:numel(obj.DP)
                X_norm(k,:) = mapminmax('apply',vec(:,k)', obj.DP(k).sim_fun.set);
            end
            for j=1:numel(obj.KPI)                
                KPIeval = mapminmax('reverse', obj.KPI(j).sim_fun.net(X_norm), obj.KPI(j).sim_fun.set);
                if ~isnan(obj.KPI(j).target(1)) && ~isinf(obj.KPI(j).target(1))
                    fitnessvalue = fitnessvalue .* max(KPIeval-obj.KPI(j).target(1),0);
                end
                if ~isnan(obj.KPI(j).target(2)) && ~isinf(obj.KPI(j).target(2))
                    fitnessvalue = fitnessvalue .* max(obj.KPI(j).target(2)-KPIeval,0);
                end
            end
            fitnessvalue = -fitnessvalue';
        end

        function fitnessvalue = ga_SS_PHASETWO(obj,vec)
            samples = 600;
%             confirm_factor = 5;
            desired_good_perc = 1;
            
            fitnessvalue = ones(1,size(vec,1));
            X_norm = zeros(numel(obj.DP), size(vec,1)*samples);
            for i=1:numel(obj.DP)
                vec_norm_i = mapminmax('apply', vec(:,2*i-1:2*i)', obj.DP(i).sim_fun.set);
                for j=1:size(vec,1)
                    X_norm(i,((j-1)*samples+1):j*samples) = rand(1,samples)*(vec_norm_i(2,j) - vec_norm_i(1,j)) + vec_norm_i(1,j);
                    fitnessvalue(j) = fitnessvalue(j) * abs( vec_norm_i(2,j) - vec_norm_i(1,j) ) /2;
                end
            end

            good = ones(1,size(vec,1)*samples);
            idxBad = zeros(numel(obj.KPI), size(vec,1)*samples);
            for i=1:numel(obj.KPI)
                resp = mapminmax('reverse', obj.KPI(i).sim_fun.net(X_norm), obj.KPI(i).sim_fun.set );
%                 idxBad = resp > obj.KPI(i).target(2) | resp < obj.KPI(i).target(1);
%                 good(idxBad) = 0;
                idxBad(i,:) = resp > obj.KPI(i).target(2) | resp < obj.KPI(i).target(1);                
            end
            good(any(idxBad)) = 0;
            for j=1:size(vec,1)
                actual_good_perc = sum(good(((j-1)*samples+1):j*samples))/samples;
                if actual_good_perc < desired_good_perc
                    fitnessvalue(j) = (actual_good_perc - desired_good_perc);
                end
            end
            fitnessvalue = -fitnessvalue';
        end 
        
        function Population = creationFunction(obj,pop_size,LB,UB,bestPoint)            
            GenomeLength = length(LB);
            betarand = abs(betarnd(4,4,pop_size,GenomeLength)-0.5);
            for i=1:2:GenomeLength
                Population(:,i) = bestPoint((i+1)/2) - betarand(:,i) .* (bestPoint((i+1)/2) - LB(i));
                Population(:,i+1) = bestPoint((i+1)/2) + betarand(:,i+1) .* (UB(i+1) - bestPoint((i+1)/2));
            end
        end
        
        function find_SS(obj)
            use_parallel = false;
            if use_parallel && isempty(gcp('nocreate'))
                parpool(6);
            end
            
            % FIRST PHASE OPTIMIZATION 
            numberOfVariables = numel(obj.DP);
            for i=1:numel(obj.DP)
                LB(i) = obj.DP(i).design_box(1);
                UB(i) = obj.DP(i).design_box(2);
            end
            
            opts = gaoptimset(...%'PlotFcns',{@gaplotbestf,@gaplotscores,@gaplotstopping},...
                                      'PopulationSize',500,...
                                      'Generations',30,...
                                      'StallGenLimit', 20,...
                                      'UseParallel',false,...
                                      'Vectorized','on',...
                                      'Display','iter',...
                                      'OutputFcn',@obj.gaoutfun); % off         
            [besPoint_PHASEONE,Fval,exitFlag,Output, Population] = ga(@obj.ga_SS_PHASEONE,numberOfVariables,[],[],[],[],LB,UB,[],opts);
            besPoint_PHASEONE                        
            
            % SECOND PHASE OPTIMIZATION
            numberOfVariables = 2 * numel(obj.DP);
            for i=1:numel(obj.DP)
                LB(2*i-1:2*i) = obj.DP(i).design_box(1);
                UB(2*i-1:2*i) = obj.DP(i).design_box(2);
            end
            Pop_size = 100;
%             opts = gaoptimset(...%'PlotFcns',{@gaplotbestf,@gaplotscores,@gaplotstopping},...
%                                       'PopulationSize',Pop_size,...
%                                       'Generations',30,...
%                                       'StallGenLimit', 50,...
%                                       'UseParallel',use_parallel,...
%                                       'Vectorized','on',...
%                                       'Display','iter',... % off)
%                                       'InitialPopulation',obj.creationFunction(Pop_size,LB,UB,besPoint_PHASEONE) );
%             [OPTIM_vars,Fval,exitFlag,Output, Population] = ga(@obj.ga_SS_PHASETWO,numberOfVariables,[],[],[],[],LB,UB,[],opts);
            
            opts = optimoptions(...%'PlotFcns',{@gaplotbestf,@gaplotscores,@gaplotstopping},...
                                      'particleswarm',...
                                      'SwarmSize',Pop_size,...
                                      'MaxIterations',50,...
                                      'MaxStallIterations', 15,...
                                      'UseParallel',false,...
                                      'UseVectorized',true,...
                                      'Display','iter',... % off)
                                      'InitialSwarmMatrix',obj.creationFunction(Pop_size,LB,UB,besPoint_PHASEONE),...
                                      'OutputFcn',@obj.pswplotranges);
            [besPoint_PHASETWO,Fval,exitFlag,Output] = particleswarm(@obj.ga_SS_PHASETWO,numberOfVariables,LB,UB,opts);           
            besPoint_PHASETWO
            
            for i=1:numel(obj.DP)
                obj.DP(i).solution_box(1) = min( besPoint_PHASETWO(2*i-1:2*i) );
                obj.DP(i).solution_box(2) = max( besPoint_PHASETWO(2*i-1:2*i) );
            end
        end
        
        function [state,options,optchanged] = gaoutfun(obj, options,state,flag)
            optchanged = false;
            if strcmp(flag,'done')
                figure('Color','white','Position',[370.6000  529.0000  337.6000  224.8000]);
                plot(1:numel(state.Best), -state.Best)
                grid on
                xlabel('Generation')
                ylabel('Best fitness')
            end
        end
        
        function stop = pswplotranges(obj, optimValues,state)
            persistent history
            stop = false;
            history(end+1) = optimValues.bestfval;
            if strcmp(state,'done')
                figure('Color','white','Position',[370.6000  529.0000  337.6000  224.8000]);
                plot(1:numel(history), -history)
                grid on
                xlabel('Generation')
                ylabel('Best fitness')
            end
        end
    end
    
end

