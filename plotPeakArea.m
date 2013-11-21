function [pressureArea, pressureAreaHeader] =...
    plotPeakArea (pos1, data, rows, cols, rowsPlot, colsPlot, toPlot)

    if strcmp(toPlot,'Yes')
        fig=figure('name','Peak pressure in different areas of the sensor');
        % Defining the regions that the mean will be calculated for
        set(fig,'OuterPosition',pos1);
        
        coleurMeas=hsv(size(data,2));
        coleurStat={[0.9,0.9,1],'b'};
    end
    
    pressureArea=zeros(size(data,2),size(data,3),length(rows)*length(cols));
    pressureAreaHeader = cell(1,length(cols)*length(rows));
        
    for i=1:length(rows)
        for j=1:length(cols)
            for k=1:size(data,2)
                %Calculating the mean for each region at each timestep
                for l=1:size(data,3)
                    areaPressure=data(1,k,l,rows{i},cols{j});
                    pressureArea(k,l,j+length(cols)*(i-1)) = max(areaPressure(:));
                end
            end
            Range = {['rows: ',num2str(min(rowsPlot{i})),' to ',num2str(max(rowsPlot{i}))],...
                    ['cols: ',num2str(min(colsPlot{j})),' to ',num2str(max(colsPlot{j}))]};
            
            pressureAreaHeader{j+length(cols)*(i-1)}=['PeakPressure ' Range{:}];
            
            if strcmp(toPlot,'Yes')
                figure(5)
                subplot(length(rows),length(cols),j+(i-1)*length(cols))
                plot3dConfInter(pressureArea, coleurMeas, coleurStat, j+length(cols)*(i-1))
                if j==1, ylabel('Pressure (Pa)'), end
                if i==length(rows), xlabel('Stance phase (%)'), end
                title([Range{:}])
                grid minor
            end
        end
    end
end