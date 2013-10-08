function measurementsComparison
%MEASUREMENTSCOMPARISON Comparing the different TekScan measurements
% Function: Comparing the results of different measurements. No inputs or
% outputs from this function. The mean pressure distribution between the
% different measurements, the mean pressure in various areas for all the
% measurements and the position of the center of pressure for all the
% measurements are plotted.
    clear
    close all force
    clc
    
    %% Loading measurement files
    
    % Choose measurements files to load and compare
    [measFileName,measPathName] = uigetfile('.mat','Select measurement files',...
        'MultiSelect','on',OSDetection);
    
    % If the array of filenames is not a cell, convert it (e.g. in case only one
    % file is selected)
    if ~iscell(measFileName)
        if measFileName == 0
            return
        else
            measFileName={measFileName};
        end
    end
    
    % Calculate the size of the array data.
    % First dimension is for different measurements, the rest
    % are following the same convention as all the Tekscan related files.
    load([measPathName measFileName{1}],'calibratedData');
    data=zeros([size(measFileName),size(calibratedData)]);
    
    paThreshold = 5e4;
    
    % Remove files that are not really measurements
    faulty= ~cellfun('isempty',strfind(measFileName,'calibration.mat'));
    measFileName(faulty)=[];
    faulty= ~cellfun('isempty',strfind(measFileName,'meanData.mat'));
    measFileName(faulty)=[];
    
    legendNames{size(measFileName,2)}=[];
    % Load calibrated data from measurement files
    for i=1:size(measFileName,2)
        load([measPathName measFileName{i}],'calibratedData','spacing','fileName');
        data(1,i,:,:,:) = smooth3(calibratedData);
        %Converting mm to m
        colSpacing=spacing{1}/1e3; %#ok<USENS> The variable is loaded three lines above
        rowSpacing=spacing{2}/1e3;
        legendNames{i}=fileName;
    end
    
    %% Statistics
    % We are calculating the mean pressure of each sensel for the different
    % measurements. Then we calculate the standard deviation of each sensel
    % for the different measurements
    meanMeas=squeeze(mean(data,2));
    sdMeas=squeeze(std(data,0,2));
    
    %% Plotting
    
    %Getting screen size for calculating the proper position of the figures
    set(0,'Units','pixels') 
    scnsize = get(0,'ScreenSize');
    
    pos1 = [0, scnsize(4)/2, scnsize(3)/3, scnsize(4)/2];
    pos2 = [scnsize(3)/3, pos1(2), scnsize(3)/3, pos1(4)];
    pos3 = [2*scnsize(3)/3, pos1(2), scnsize(3)/3, pos1(4)];
    pos4 = [2*scnsize(3)/3, 0, scnsize(3)/3, pos1(4)];
    pos5 = [scnsize(3)/3, 0, scnsize(3)/3, pos1(4)];
    pos6 = [0, 0, pos1(3), pos1(4)];
    
    % Define a grid to plot the results and then plot them
    [y,x]=meshgrid(floor(-size(data,5)/2)+1:1:floor(size(data,5)/2),...
        floor(-size(data,4)/2)+1:1:floor(size(data,4)/2));
    
    % Decide how the sensor will be split in areas in a clever way
    rowDiv = 3;
    colDiv = 2;
    rows{rowDiv}=[];
    rowsPlot=rows;
    cols{colDiv}=[];
    colsPlot=cols;
    previous=0;
    rowsTemp = 1:1:max(x(:))-min(x(:))+1;
    for i=1:rowDiv
        rows{i} = (1:ceil(max(rowsTemp(:))/rowDiv)) + previous;
        previous = max([rows{:}]);
        rowsPlot{i} = rows{i} + min(x(:)) -1;
    end
    rows{rowDiv}(rows{rowDiv}>max(rowsTemp(:)))=[];
    previous=0;
    colsTemp = 1:1:max(y(:))-min(y(:))+1;
    for i=1:colDiv
        cols{i} = (1:ceil(max(colsTemp(:))/colDiv)) + previous;
        previous = max([cols{:}]);
        colsPlot{i} = cols{i} + min(y(:)) -1;
    end
    cols{colDiv}(cols{colDiv}>max(colsTemp(:)))=[];
    
    fig1=figure('name','Pressure distribution over the area of the sensor');
    set(fig1,'OuterPosition',pos1);
    plot3dErrorbars(x,y,meanMeas,sdMeas,1,rowsPlot,colsPlot,1,size(data,2)-1,1);
    zlim([0 max(meanMeas(:))]);
    set(gca,'CameraPosition',[0 0 3.75*1e7],'DataAspectRatio',[1 1 3e5]);
    xlabel('A(-)/P(+) direction'), ylabel('M(-)/L(+) direction'), zlabel('Pressure (Pa)');
    title('Pressure distribution over the area of the sensor')
    h = uicontrol('style','slider','units','pixel','position',[20 20 300 20]);
    g = uicontrol('string','Plot SD','style','checkbox','units','pixel','position',[20 50 60 20],'Value',~~(size(data,2)-1));
    f = uicontrol('string','Plot Area division','style','checkbox','units','pixel','position',[20 80 105 20],'Value',1);
    s = uicontrol('string','Shading interpolation','style','checkbox','units','pixel','position',[20 110 115 20],'Value',1);
    addlistener(h,'ContinuousValueChange',@(hObject, event) makeplot(hObject,x,y,meanMeas,sdMeas,rowsPlot,colsPlot,f,g,s));

    function makeplot(hObject,x,y,meanMeas,sdMeas,rows,cols,f,g,s)
        n = floor(get(hObject,'Value')*99+1);
        plot3dErrorbars(x,y,meanMeas,sdMeas,n,rows,cols,get(f,'value'),get(g, 'value'),get(s,'value'));
        zlim([0 max(meanMeas(:))]);
        xlabel('A(-)/P(+) direction'), ylabel('M(-)/L(+) direction'), zlabel('Pressure (Pa)');
        title('Pressure distribution over the area of the sensor')
        refreshdata;
    end

    fig2=figure('name','Resulting force in different areas of the sensor');
    % Defining the regions that the mean will be calculated for
    set(fig2,'OuterPosition',pos2);
    fig3=figure('name','Contact area in different areas of the sensor');
    set(fig3,'OuterPosition',pos3);
    forceArea=zeros(size(data,2),size(data,3),2);
    forceTotal=forceArea;
    contactArea=forceArea;
    coleurMeas=hsv(size(data,2));
    coleurStat={[0.9,0.9,1],'b'};
    for i=1:length(rows)
        for j=1:length(cols)
            figure(2)
            subplot(length(rows),length(cols),j+(i-1)*length(cols))
            for k=1:size(data,2)
                %Calculating the mean for each region at each timestep
                for l=1:size(data,3)
                    areaPressure=data(1,k,l,rows{i},cols{j});
                    forceArea(k,l,2) = sum(areaPressure(:))*rowSpacing*colSpacing;
                    forceTotal(k,l,2) = sum(sum(data(1,k,l,:,:)))*rowSpacing*colSpacing;
                    contactArea(k,l,2) = size(areaPressure(areaPressure>paThreshold),1)*rowSpacing*colSpacing;
                end
            end
            plot3dConfInter(forceArea, coleurMeas, coleurStat, 2)
            if j==1, ylabel('Force (N)'), end
            if i==length(rows), xlabel('Stance phase (%)'), end
            title({['rows: ',num2str(min(rowsPlot{i})),' to ',num2str(max(rowsPlot{i}))],...
                ['cols: ',num2str(min(colsPlot{j})),' to ',num2str(max(colsPlot{j}))]})
            figure(3)
            subplot(length(rows),length(cols),j+(i-1)*length(cols))
            plot3dConfInter(contactArea, coleurMeas, coleurStat, 2)
            if j==1, ylabel('Contact Area (m^2)'), end
            if i==length(rows), xlabel('Stance phase (%)'), end
            title({['rows: ',num2str(min(rowsPlot{i})),' to ',num2str(max(rowsPlot{i}))],...
                ['cols: ',num2str(min(colsPlot{j})),' to ',num2str(max(colsPlot{j}))]})
        end
    end

    
    % Plotting location of center of pressure in the two directions
    fig4=figure('name','CoP position in two directions');
    set(fig4,'OuterPosition',pos4);
    xCen=zeros(size(data,2),size(data,3),2);
    yCen=zeros(size(data,2),size(data,3),2);
    for k=1:size(data,2)
        for l=1:size(data,3)
            dataTemp = squeeze(data(1,k,l,:,:));
            xCen(k,l,2)=sum(sum(x.*dataTemp))/sum(dataTemp(:));
            yCen(k,l,2)=sum(sum(y.*dataTemp))/sum(dataTemp(:));
        end
    end
    subplot(2,1,1)
    plot3dConfInter(xCen,coleurMeas,coleurStat,2)
    ylabel('CoP in A/P direction (sensel)')
    ylim([min(x(:)),max(x(:))])
    title('Position of the CoP in A/P direction (sensor row)')
    subplot(2,1,2)
    plot3dConfInter(yCen,coleurMeas,coleurStat,2)
    ylabel('CoP in M/L direction (sensel)')
    xlabel('Stance phase (%)')
    ylim([min(y(:)),max(y(:))])
    title('Position of the CoP in M/L direction (sensor col)')
        
    %Plotting sum of forces that are measured with the sensor
    fig5=figure('name','Total force through the ankle joint');
    set(fig5,'OuterPosition',pos5);
    plot3dConfInter(forceTotal, coleurMeas, coleurStat, 2)
    ylabel('Force (N)'), xlabel('Stance phase (%)')
    title('Total force through the ankle joint')
    
    fig6=figure('name','Peak pressure over stance phase duration');
    set(fig6,'OuterPosition',pos6);
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
end