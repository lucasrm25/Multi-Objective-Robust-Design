classdef ManEval < handle
    properties
        KPI @man.KPI
        DP  @man.DP
        mans            % maneuver (+man) classes
        plot_parent_h   % Panel or Figure
    end

    methods
        function obj = ManEval(varargin)
            if nargin < 2
                obj.plot_parent_h = cgf;
            else
                obj.plot_parent_h = varargin{2};
            end
            if nargin < 1
                folder = 'C:';
            else
                folder = varargin{1};
            end
            obj.create(folder);
        end
        
        function sim(obj, nSamples)  % inicio e mudaram DP.sol_box... 
        end
        
        function save(obj, folder)
            [sfile, sfolder]= uiputfile({'*.mat','Maneuver Evaluation File';...
            '*.*','All Files' },'Save Maneuver Evaluation File',...
            fullfile(folder,'Man_Eval.mat'));
            if isa(sfile,'char')
                save(fullfile(sfolder, sfile), 'obj');
            end
        end
        
        function create(obj, direc) % no inicio
            folder = uigetdir(direc,'Select the main folder');
            if isa(folder,'double'), return; end
            
            man_names = what('man');
            for i=1:numel(man_names.classes)
                obj.mans{i} = man.(man_names.classes{i}) (folder);
                if obj.mans{i}.exists(folder)
                    obj.KPI = [obj.KPI obj.mans{i}.calcKPI];                    
                end
            end
            
            fileID = fopen(fullfile(folder,'DoEInfo.txt'),'r');
            fileData = textscan(fileID,'%s %f');
            fclose(fileID);
            
            for i=1:numel(fileData)
                dp_new = man.DP;
                dp_new.name  = fileData{1}{i};
                dp_new.value = fileData{2}(i);
                obj.DP = [obj.DP dp_new];
            end
        end

        function plot(obj) % inicio e mudaram DP.sol_box ou KPI.target
            delete(obj.plot_parent_h.Children);
            tabgroup = uitabgroup('Parent', obj.plot_parent_h, 'Tag','TabGroup');
            for i=1:numel(obj.mans)
                addTab(tabgroup, class(obj.mans{i}));
                obj.mans{i}.plot;
            end
        end
    end

end

