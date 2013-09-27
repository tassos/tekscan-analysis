function measurementsComparison
%MEASUREMENTSCOMPARISON Comparing the different TekScan measurements
% Function: Comparing the results of different measurements. No inputs or
% outputs from this function. The mean pressure distribution between the
% different measurements, the mean pressure in various areas for all the
% measurements and the position of the center of pressure for all the
% measurements are plotted.
    clear all
    close all force
    clc
    
    %% Loading measurement files
    
    % Choose measurements files to load and compare
    [measFileName,measPathName] = uigetfile('.mat','Select measurement files',...
        'MultiSelect','on',OSDetection);
    
    % If the array of filenames is not a cell, convert it (e.g. in case only one
    % file is selected)
    if ~iscell(measFileName)
        measFileName={measFileName};
    end
    
    % Calculate the size of the array data.
    % First dimension is for different measurements, the rest
    % are following the same convention as all the Tekscan related files.
    load([measPathName measFileName{1}],'calibratedData');
    data=zeros([size(measFileName),size(calibratedData)]);
    
    % Remove files that are not really measurements
    faulty= ~cellfun('isempty',strfind(measFileName,'calibration.mat'));
    measFileName(faulty)=[];
    faulty= ~cellfun('isempty',strfind(measFileName,'meanData.mat'));
    measFileName(faulty)=[];
    
    % Load calibrated data from measurement files
    for i=1:size(measFileName,2)
        load([measPathName measFileName{i}],'calibratedData','spacing');
        data(1,i,:,:,:) = calibratedData;
        %Converting mm to m
        colSpacing=spacing{1}/1e3; %#ok<USENS> The variable is loaded three lines above
        rowSpacing=spacing{2}/1e3;
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
    
    pos1 = [0, scnsize(4) * (1/2), scnsize(3)/3, scnsize(4)/2];
    pos2 = [scnsize(3)/3, pos1(2), 2*scnsize(3)/3, pos1(4)];
    pos3 = [scnsize(3)/3, 0, pos2(3), pos2(4)];
    
    % Define a grid to plot the results and then plot them
    [y,x]=meshgrid(1:1:size(data,5),1:1:size(data,4));
    
    % Decide how the sensor will be split in areas in a clever way
    rowDiv = 3;
    colDiv = 2;
    rows{rowDiv}=[];
    cols{colDiv}=[];
    previous=0;
    for i=1:rowDiv
        rows{i} = (1:ceil(max(x(:))/rowDiv)) + previous;
        previous = max([rows{:}]);
    end
    rows{rowDiv}(rows{rowDiv}>max(x(:)))=[];
    previous=0;
    for i=1:colDiv
        cols{i} = (1:ceil(max(y(:))/colDiv)) + previous;
        previous = max([cols{:}]);
    end
    cols{colDiv}(cols{colDiv}>max(y(:)))=[];
    
    figure(1)
    set(1,'OuterPosition',pos1);
    plot3dErrorbars(x,y,meanMeas(1,:,:),sdMeas(1,:,:),rows,cols,1,1);
    xlabel('Sensor columns'), ylabel('Sensor rows'), zlabel('Pressure (Pa)');
    h = uicontrol('style','slider','units','pixel','position',[20 20 300 20]);
    g = uicontrol('string','Plot SD','style','checkbox','units','pixel','position',[20 50 150 20],'Value',1);
    f = uicontrol('string','Plot Area division','style','checkbox','units','pixel','position',[20 80 150 20],'Value',1);
    addlistener(h,'ContinuousValueChange',@(hObject, event) makeplot(hObject,x,y,meanMeas,sdMeas,rows,cols,f,g));

    function makeplot(hObject,x,y,meanMeas,sdMeas,rows,cols,f,g)
        n = floor(get(hObject,'Value')*99+1);
        plot3dErrorbars(x,y,meanMeas(n,:,:),sdMeas(n,:,:),rows,cols,get(f,'value'),get(g, 'value'));
        xlabel('Sensor columns'), ylabel('Sensor rows'), zlabel('Pressure (Pa)');
        refreshdata;
    end

    figure(2)
    % Defining the regions that the mean will be calculated for
    set(2,'OuterPosition',pos2);
    forceArea=zeros(size(data,2),size(data,3),2);
    coleurMeas=hsv(size(data,2));
    coleurStat={[0.9,0.9,1],'b'};
    for i=1:length(rows)
        for j=1:length(cols)
            subplot(length(rows),length(cols),j+(i-1)*length(cols))
            for k=1:size(data,2)
                %Calculating the mean for each region at each timestep
                for l=1:size(data,3)
                    area = ((max(cols{j})-min(cols{j}))*colSpacing)*((max(rows{i})-min(rows{i}))*rowSpacing);
                    areaPressure=data(1,k,l,rows{i},cols{j});
                    forceArea(k,l,2) = sum(areaPressure(:))*area;
                end
            end
            plot3dConfInter(forceArea, coleurMeas, coleurStat, 2)
            if j==1, ylabel(['Force (N) (rows ',num2str(min(rows{i})),'-',num2str(max(rows{i})),')']), end
            if i==3, xlabel(['Stance phase (%) (cols ',num2str(min(cols{j})),'-',num2str(max(cols{j})),')']), end
        end
    end
    
    % Plotting location of center of pressure in the two directions
    figure(3)
    set(3,'OuterPosition',pos3);
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
    ylim([1,max(x(:))])
    subplot(2,1,2)
    plot3dConfInter(yCen,coleurMeas,coleurStat,2)
    ylabel('CoP in M/L direction (sensel)')
    xlabel('Stance phase (%)')
    ylim([1,max(y(:))])
end