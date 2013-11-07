function plotVert(hObject, fig, measurement, legendNames)
    n = floor(get(hObject,'Value')*(length(measurement)-1)+1);
    figure(fig)
    legend off
    lines = findall(0,'type','line');
    delete(lines(1));
    line([n n], [min(measurement(:)) max(measurement(:))]);
    refreshdata;
    legend([{'Std'} legendNames {'Mean'}])
end