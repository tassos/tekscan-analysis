function plotVert(hObject, fig, measurement)
    n = floor(get(hObject,'Value')*99+1);
    figure(fig)
    lines = findall(0,'type','line');
    delete(lines(1));
    line([n n], [min(measurement(:)) max(measurement(:))]);
    refreshdata;
end