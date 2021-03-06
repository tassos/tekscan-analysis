function forceTotal = plotForceTotal(pos, h, data, senselArea, legendNames, toPlot)

    coleurMeas=hsv(size(data,2));
    coleurStat={[0.9,0.9,1],'b'};

    forceTotal=nan(size(data,2),size(data,3),2);
    for k=1:size(data,2)
        for l=1:size(data,3)
            forceTotal(k,l,2) = sum(sum(data(1,k,l,:,:)))*senselArea;
        end
    end
    
    if toPlot
        %Plotting sum of forces that are measured with the sensor
        fig=figure('name','Total force through the ankle joint');
        set(fig,'OuterPosition',pos);
        plot3dConfInter(forceTotal, coleurMeas, coleurStat, 2);
        line([0 0],[min(forceTotal(:)) max(forceTotal(:))]);
        ylabel('Force (N)'), xlabel('Stance phase (%)')
        title('Total force through the ankle joint')
        addlistener(h,'ContinuousValueChange',@(hObject, event) plotVert(hObject, fig, forceTotal, legendNames));
        grid on
        legend([{'Std'} legendNames {'Mean'}])
    end
end