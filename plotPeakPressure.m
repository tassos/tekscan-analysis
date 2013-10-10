function plotPeakPressure(pos, h, data, legendNames)
    
    coleurMeas=hsv(size(data,2));
    coleurStat={[0.9,0.9,1],'b'};

    fig=figure('name','Peak pressure over stance phase duration');
    set(fig,'OuterPosition',pos);
    maxPressure=zeros(size(data,2),size(data,3),2);
    for k=1:size(data,2)
        for l=1:size(data,3)
            maxPressure(k,l,2) = max(max(data(1,k,l,:,:)));
        end
    end
    plot3dConfInter(maxPressure, coleurMeas, coleurStat, 2);
    legend([{'Std'} legendNames {'Mean'}])
    xlabel('Stance phase (%)'), ylabel('Maximum Pressure (Pa)')
    title('Peak pressure over stance phase duration')
    addlistener(h,'ContinuousValueChange',@(hObject, event) plotVert(hObject, fig, maxPressure));
end