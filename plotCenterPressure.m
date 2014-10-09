function CoP = plotCenterPressure (pos, x, y, data, toPlot, rowSpacing, colSpacing)
    CoP=zeros(size(data,2),size(data,3),2);
    data(:)=data(:).*(data(:)>1e5);
    for k=1:size(data,2)
        for l=1:size(data,3)
            dataTemp = squeeze(data(1,k,l,:,:));
            CoP(k,l,1)=sum(sum(x.*dataTemp))/sum(dataTemp(:))*rowSpacing*1000;
            CoP(k,l,2)=sum(sum(y.*dataTemp))/sum(dataTemp(:))*colSpacing*1000;
        end
    end
    if strcmp(toPlot,'Yes')
        % Plotting location of center of pressure in the two directions
        fig=figure('name','CoP position in two directions');
        set(fig,'OuterPosition',pos);
        
        coleurMeas=hsv(size(data,2));
        coleurStat={[0.9,0.9,1],'b'};
        
        subplot(2,1,1)
        plot3dConfInter(CoP,coleurMeas,coleurStat,1);
        ylabel('CoP in A/P direction (sensel)')
        ylim([min(x(:)),max(x(:))])
        title('Position of the CoP in A/P direction (sensor row)')
        grid on
        subplot(2,1,2)
        plot3dConfInter(CoP,coleurMeas,coleurStat,2);
        ylabel('CoP in M/L direction (sensel)')
        xlabel('Stance phase (%)')
        ylim([min(y(:)),max(y(:))])
        title('Position of the CoP in M/L direction (sensor col)')
        grid on
    end
end