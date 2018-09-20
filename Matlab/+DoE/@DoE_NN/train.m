function train( obj )

    neurons_start = 10;
    neurons_step  = 10;
    neurons_max   = 60;

    n_trainnings = 100;
    R2_desired = 0.98;
    epoches = 200;
    transferFcn = 'logsig';


    correlation_plot = true;
    out_path = fullfile(pwd, 'ANN_training');
    if ~exist(out_path,'dir')
        mkdir(out_path);
    end
    addpath(out_path)

    X_data = reshape([obj.DP.sim_fun],  numel(obj.DP(1).sim_fun),  numel(obj.DP))';      % lines are different inputs
    Y_data = reshape([obj.KPI.sim_fun], numel(obj.KPI(1).sim_fun), numel(obj.KPI))';     % lines are different outputs

    for i=1:numel(obj.DP)
        [x_meta(i,:),settings_x(i)] = mapminmax(X_data(i,:));
        obj.DP(i).sim_fun = struct('set', settings_x(i));
    end
%     [x_meta2,settings_x2] = mapminmax(X_data);

    for i=1:numel(obj.KPI)    

        [y_meta(i,:),settings_y(i)] = mapminmax(Y_data(i,:));
        R2_test_val{i} = -Inf;
        neurons_act = neurons_start;

        while neurons_act <= neurons_max && R2_test_val{i} <= R2_desired

            net_new = feedforwardnet(neurons_act);
            net_new.trainParam.epochs      = epoches;
            net_new.trainParam.goal        = 1e-5;
            net_new.trainParam.showWindow  = true;     
            net_new.layers{1:end-1}.transferFcn = transferFcn;

            net_new.outputs{end}.userdata.outputname = obj.KPI(i).cname;

            for k=1:n_trainnings
                [net_new,tr_new] = train(net_new,x_meta,y_meta(i,:));

                % Auswertung (normiert)
                id_val_test_val_new = [tr_new.valInd, tr_new.testInd];

                % Obtain Neural Network quality 
                y_hat_norm          = net_new(x_meta);
                y_hat_norm_test_val = y_hat_norm(id_val_test_val_new);
                y_meta_test_val     = y_meta(i,id_val_test_val_new);

                R2_tr_new       = 1 - ( sum( (y_meta(i,:)-y_hat_norm).^2 ) / sum( (y_meta(i,:)-mean(y_meta(i,:))).^2 ) );
                R2_test_val_new = 1 - ( sum( (y_meta_test_val-y_hat_norm_test_val).^2 ) / sum( (y_meta_test_val-mean(y_meta_test_val)).^2 ));

                if R2_test_val_new > R2_test_val{i}
                    id_val_test_val{i} = id_val_test_val_new;
                    R2_tr{i} = R2_tr_new;
                    R2_test_val{i} = R2_test_val_new;
                    net{i} = net_new;
                    tr{i}  = tr_new;
                end

                if R2_test_val{i} > R2_desired
                    break;
                end
            end

            neurons_act = neurons_act + neurons_step;
        end

        % Plota os gráficos de correlação para cada rede neural na pasta out_path
        if correlation_plot        
            X_test = X_data(:,id_val_test_val{i});
            Y_test = Y_data(i,id_val_test_val{i});

            for j=1:numel(obj.DP)
                input_norm(j,:) = mapminmax('apply',X_test(j,:),settings_x(j));
            end
%                 input_norm2=mapminmax('apply',X_test,settings_x2);     
            F_x_norm = net{i}(input_norm);
            par_out=mapminmax('reverse',F_x_norm ,settings_y(i) );

            figurename=['ANN_',net{i}.outputs{end}.userdata.outputname,'.png'];

            f1=figure('name',figurename(1:end-4),'visible','on','color','w');
            plot(Y_test,par_out,'r*')
            hold on
            xlabel('original')
            ylabel('ANN')
            title([ net{i}.outputs{end}.userdata.outputname,'  N = ',num2str(net{i}.layers{1}.dimensions),' R²val =', num2str(R2_test_val{i}), ', R²tr =',num2str(R2_tr{i})], 'Interpreter','none')
            grid on
            xlim=get(gca,'xlim');
            ylim=get(gca,'ylim');
            plot([max(xlim(1),ylim(1)),min(xlim(2),ylim(2))],[max(xlim(1),ylim(1)),min(xlim(2),ylim(2))],'k-.')
            savename = fullfile(out_path, strrep(strrep(figurename,'*',''),'/',''));
            saveas(f1,savename)
            close(f1)
        end
        
        obj.KPI(i).sim_fun = struct('net', net{i}, 'set', settings_y(i));
%         obj.KPI(i).sim_fun.net = net{i};
%         obj.KPI(i).sim_fun.set = settings_y(i);
    end
end

