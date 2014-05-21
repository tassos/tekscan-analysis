function [forceArea, forceAreaHeader, contactArea, contactAreaHeader] =...
    plotForceArea (pos1, pos2, data, rows, cols, rowsPlot, colsPlot, senselArea, toPlot)

    if strcmp(toPlot,'Yes')
        fig=figure('name','Resulting force in different areas of the sensor');
        % Defining the regions that the mean will be calculated for
        set(fig,'OuterPosition',pos1);
        fig3=figure('name','Contact area in different areas of the sensor');
        set(fig3,'OuterPosition',pos2);
        
        coleurMeas=hsv(size(data,2));
        coleurStat={[0.9,0.9,1],'b'};
    end
    
    forceArea=zeros(size(data,2),size(data,3),length(rows)*length(cols));
    contactArea=forceArea;
    forceAreaHeader = cell(1,length(cols)*length(rows));
    contactAreaHeader = cell(1,length(cols)*length(rows));
    
    paThreshold = 5e5; %Pa Based on matricalli and the super low pressure fujiFilm prescale
    %http://www.fujifilm.com/products/prescale/prescalefilm/#overview
    
    for i=1:length(rows)
        for j=1:length(cols)
            for k=1:size(data,2)
                %Calculating the mean for each region at each timestep
                for l=1:size(data,3)
                    areaPressure=data(1,k,l,rows{i},cols{j});
                    forceArea(k,l,j+length(cols)*(i-1)) = sum(areaPressure(:))*senselArea;
                    contactArea(k,l,j+length(cols)*(i-1)) = size(areaPressure(areaPressure>paThreshold),1)*senselArea;
                end
            end
            Range = {['rows: ',num2str(min(rowsPlot{i})),' to ',num2str(max(rowsPlot{i}))],...
                    ['cols: ',num2str(min(colsPlot{j})),' to ',num2str(max(colsPlot{j}))]};
            
            forceAreaHeader{j+length(cols)*(i-1)}=['ForceArea ' Range{:}];
            contactAreaHeader{j+length(cols)*(i-1)}=['ContactArea ' Range{:}];
            
            if strcmp(toPlot,'Yes')
                figure(2)
                subplot(length(rows),length(cols),j+(i-1)*length(cols))
                plot3dConfInter(forceArea, coleurMeas, coleurStat, j+length(cols)*(i-1));
                if j==1, ylabel('Force (N)'), end
                if i==length(rows), xlabel('Stance phase (%)'), end
                title([Range{:}])
                grid minor
                figure(3)
                subplot(length(rows),length(cols),j+(i-1)*length(cols))
                plot3dConfInter(contactArea, coleurMeas, coleurStat, j+length(cols)*(i-1));
                if j==1, ylabel('Contact Area (m^2)'), end
                if i==length(rows), xlabel('Stance phase (%)'), end
                title([Range{:}])
                grid minor
            end
        end
    end
end