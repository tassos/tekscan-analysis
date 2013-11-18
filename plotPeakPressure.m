function [peakLocation] = plotPeakPressure(pos, h, data, legendNames)
    
    coleurMeas=hsv(size(data,2));
    coleurStat={[0.9,0.9,1],'b'};

    maxPressure=zeros(size(data,2),size(data,3),2);
    peakLocation = zeros(size(data,2),size(data,3),2);
    for k=1:size(data,2)
        for l=1:size(data,3)
            maxPressure(k,l,2) = max(max(data(1,k,l,:,:)));
            [r,c] = find(squeeze(data(1,k,l,:,:))==maxPressure(k,l,2));
            if isempty(r) || isempty(c)
                r=NaN;
                c=NaN;
            end
            peakLocation(k,l,1)=mean(r);
            peakLocation(k,l,2)=mean(c);
        end
    end
    
    %Plotting peak preassure that is measured with the sensor
    fig=figure('name','Peak pressure over stance phase duration');
    set(fig,'OuterPosition',pos);
    plot3dConfInter(maxPressure, coleurMeas, coleurStat, 2);
    line([0 0],[min(maxPressure(:)) max(maxPressure(:))]);
    ylabel('Maximum Pressure (Pa)'), xlabel('Stance phase (%)')
    title('Peak pressure over stance phase duration')
    addlistener(h,'ContinuousValueChange',@(hObject, event) plotVert(hObject, fig, maxPressure, legendNames));
    grid on
    legend([{'Std'} legendNames {'Mean'}])
end