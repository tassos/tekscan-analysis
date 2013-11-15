function plotForceArea (pos1, pos2, data, rows, cols, rowsPlot, colsPlot, senselArea)

    fig=figure('name','Resulting force in different areas of the sensor');
    % Defining the regions that the mean will be calculated for
    set(fig,'OuterPosition',pos1);
    fig3=figure('name','Contact area in different areas of the sensor');
    set(fig3,'OuterPosition',pos2);
    
    forceArea=zeros(size(data,2),size(data,3),2);
    contactArea=forceArea;
    
    coleurMeas=hsv(size(data,2));
    coleurStat={[0.9,0.9,1],'b'};
    
    paThreshold = 5e4;
    
    for i=1:length(rows)
        for j=1:length(cols)
            figure(2)
            subplot(length(rows),length(cols),j+(i-1)*length(cols))
            for k=1:size(data,2)
                %Calculating the mean for each region at each timestep
                for l=1:size(data,3)
                    areaPressure=data(1,k,l,rows{i},cols{j});
                    forceArea(k,l,2) = sum(areaPressure(:))*senselArea;
                    contactArea(k,l,2) = size(areaPressure(areaPressure>paThreshold),1)*senselArea;
                end
            end
            plot3dConfInter(forceArea, coleurMeas, coleurStat, 2)
            if j==1, ylabel('Force (N)'), end
            if i==length(rows), xlabel('Stance phase (%)'), end
            title({['rows: ',num2str(min(rowsPlot{i})),' to ',num2str(max(rowsPlot{i}))],...
                ['cols: ',num2str(min(colsPlot{j})),' to ',num2str(max(colsPlot{j}))]})
            grid minor
            figure(3)
            subplot(length(rows),length(cols),j+(i-1)*length(cols))
            plot3dConfInter(contactArea, coleurMeas, coleurStat, 2)
            if j==1, ylabel('Contact Area (m^2)'), end
            if i==length(rows), xlabel('Stance phase (%)'), end
            title({['rows: ',num2str(min(rowsPlot{i})),' to ',num2str(max(rowsPlot{i}))],...
                ['cols: ',num2str(min(colsPlot{j})),' to ',num2str(max(colsPlot{j}))]})
            grid minor
        end
    end
end