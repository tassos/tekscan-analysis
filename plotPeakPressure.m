function [peakPressure, peakLocation] = plotPeakPressure(pos, h, x, y, data, legendNames, toPlot, rowSpacing, colSpacing)
    
    coleurMeas=hsv(size(data,2));
    coleurStat={[0.9,0.9,1],'b'};

    peakPressure=zeros(size(data,2),size(data,3),2);
    peakLocation = zeros(size(data,2),size(data,3),2);
    for k=1:size(data,2)
        for l=1:size(data,3)
            peakPressure(k,l,2) = max(max(data(1,k,l,:,:)));
            [r,c] = find(squeeze(data(1,k,l,:,:))==peakPressure(k,l,2));
            if isempty(r) || isempty(c)
                r=NaN;
                c=NaN;
            end
            peakLocation(k,l,1)=(mean(r)-max(x(:)))*rowSpacing*1000;
            peakLocation(k,l,2)=(mean(c)-max(y(:)))*colSpacing*1000;
        end
    end
    
    if strcmp(toPlot,'Yes')
        %Plotting peak preassure that is measured with the sensor
        fig=figure('name','Peak pressure over stance phase duration');
        set(fig,'OuterPosition',pos);
        plot3dConfInter(peakPressure, coleurMeas, coleurStat, 2);
        line([0 0],[min(peakPressure(:)) max(peakPressure(:))]);
        ylabel('Maximum Pressure (Pa)'), xlabel('Stance phase (%)')
        title('Peak pressure over stance phase duration')
        addlistener(h,'ContinuousValueChange',@(hObject, event) plotVert(hObject, fig, peakPressure, legendNames));
        grid on
        legend([{'Std'} legendNames {'Mean'}])
    end
end