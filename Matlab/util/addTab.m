function [tab, axs]= addTab(tgroup, tabname)
    if ~isempty(tgroup.Children) 
        tgroup.Children(find(ismember({tgroup.Children.Title},tabname))).delete; 
    end
    tab = uitab('Parent', tgroup, 'Title', tabname, 'BackgroundColor', 'white');
    tgroup.SelectedTab = tab;
    axs = axes('parent',tab, 'Color','white');
end
