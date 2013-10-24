function [h] = plot3Dpressure (pos, x, y, meanMeas, sdMeas, rowsPlot, colsPlot, plotSD)

    fig1=figure('name','Pressure distribution over the area of the sensor');
    set(fig1,'OuterPosition',pos);
    plot3dErrorbars(x,y,meanMeas,sdMeas,1,rowsPlot,colsPlot,1,plotSD,1);
    zlim([0 max(meanMeas(:))]);
    set(gca,'CameraPosition',[0 0 3.75*1e7],'DataAspectRatio',[1 1 3e5]);
    xlabel('A(-)/P(+) direction'), ylabel('M(-)/L(+) direction'), zlabel('Pressure (Pa)');
    title('Pressure distribution over the area of the sensor')
    h = uicontrol('style','slider','units','pixel','position',[20 20 300 20]);
    t = uicontrol('style','text','string',['0' char(37)],'position',[330 20 30 20]);
    g = uicontrol('string','Plot SD','style','checkbox','units','pixel','position',[20 50 60 20],'Value',plotSD);
    f = uicontrol('string','Plot Area division','style','checkbox','units','pixel','position',[20 80 105 20],'Value',1);
    s = uicontrol('string','Shading interpolation','style','checkbox','units','pixel','position',[20 110 120 20],'Value',1);
    addlistener(h,'ContinuousValueChange',@(hObject, event) makePlot(hObject,x,y,meanMeas,sdMeas,rowsPlot,colsPlot,fig1,t,f,g,s));

end

function makePlot(hObject, x, y, meanMeas, sdMeas, rows, cols, fig, t, f, g, s)
    n = floor(get(hObject,'Value')*99+1);
    set(t,'string',[num2str(n) char(37)]);
    figure(fig);
    plot3dErrorbars(x,y,meanMeas,sdMeas,n,rows,cols,get(f,'value'),get(g, 'value'),get(s,'value'));
    zlim([0 max(meanMeas(:))]);
    xlabel('A(-)/P(+) direction'), ylabel('M(-)/L(+) direction'), zlabel('Pressure (Pa)');
    title('Pressure distribution over the area of the sensor')
    refreshdata;
end