function plot_Maneuver( res, names )

nfigures = ceil(numel(names)/6);

for i=1:nfigures
    figure('Name','Analysis','Color','white')
    for j=(i-1)*6+1:min([i*6 size(names,1)])
        subplot(2,3,floor(j/nfigures))
        plot( res.(names{j,1}).data, res.(names{j,2}).data )
        xlabel( [res.(names{j,1}).name '[' res.(names{j,1}).unit ']'])
        ylabel( [res.(names{j,2}).name '[' res.(names{j,2}).unit ']'])
%         xlim(t_plot_range)
        grid on
    end
end

end

