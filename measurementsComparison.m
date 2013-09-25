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
        load([measPathName measFileName{i}],'calibratedData');
        data(1,i,:,:,:) = calibratedData/1e6;
    end
    
    %% Statistics
    % We are calculating the mean pressure of each sensel for the different
    % measurements. Then we calculate the standard deviation of each sensel
    % for the different measurements
    meanMeas=squeeze(mean(data,2));
    sdMeas=squeeze(std(data,0,2));
    
    %% Plotting
    % Define a grid to plot the results and then plot them
    [y,x]=meshgrid(1:1:size(data,5),1:1:size(data,4));
    
    figure(1)
    plot3dErrorbars(x,y,meanMeas(1,:,:),sdMeas(1,:,:),1);
    h = uicontrol('style','slider','units','pixel','position',[20 20 300 20]);
    g = uicontrol('string','Plot SD','style','checkbox','units','pixel','position',[20 50 150 20],'Value',1);
    addlistener(h,'ContinuousValueChange',@(hObject, event) makeplot(hObject,x,y,meanMeas,sdMeas,g));

    function makeplot(hObject,x,y,meanMeas,sdMeas,g)
        n = floor(get(hObject,'Value')*99+1);
        plot3dErrorbars(x,y,meanMeas(n,:,:),sdMeas(n,:,:),get(g, 'value'));
        refreshdata;
    end

    figure(2)
    % Defining the regions that the mean will be calculated for
    meanMeas=zeros(size(data,2),size(data,3),2);
    coleurMeas=hsv(size(data,2));
    coleurStat={[0.9,0.9,1],'b'};
    rows = {1:15, 16:30, 31:46};
    cols = {1:16, 17:32};
    for i=1:length(rows)
        for j=1:length(cols)
            subplot(length(rows),length(cols),j+(i-1)*length(cols))
            for k=1:size(data,2)
                %Calculating the mean for each region at each timestep
                for l=1:size(data,3)
                    area=data(1,k,l,rows{i},cols{j});
                    meanMeas(k,l,2) = mean(area(:));
                end
            end
            plot3dConfInter(meanMeas, coleurMeas, coleurStat, 2)
            xlabel('Stance phase (%)'), ylabel('Pressure (MPa)')
        end
    end
    
    % Plotting location of center of pressure in the two directions
    figure(3)
    xCen=zeros(size(data,2),size(data,3),2);
    yCen=zeros(size(data,2),size(data,3),2);
    for k=1:size(data,2)
        for l=1:size(data,3)
            xCen(k,l,2)=sum(sum(x.*squeeze(data(1,k,l,:,:))))/sum(sum(squeeze(data(1,k,l,:,:))));
            yCen(k,l,2)=sum(sum(y.*squeeze(data(1,k,l,:,:))))/sum(sum(squeeze(data(1,k,l,:,:))));
        end
    end
    subplot(2,1,1)
    plot3dConfInter(xCen,coleurMeas,coleurStat,2)
    ylabel('Center of pressure in A/P direction (sensel)')
    ylim([1,max(x(:))])
    subplot(2,1,2)
    plot3dConfInter(yCen,coleurMeas,coleurStat,2)
    ylabel('Center of pressure in M/L direction (sensel)')
    xlabel('Stance phase (%)')
    ylim([1,max(y(:))])
end