%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%                       Comparing the different measurements
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Function: Comparing the results of different measurements
%
% Input
% None
%
% Output 
% None
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function measurementsComparison

    clear all
    close all force
    clc

    isWindows = exist('C:/Users/u0074517/Documents/PhD/Foot-ankle project/Measurements','dir');
    if isWindows
        initialFolder = 'C:/Users/u0074517/Documents/PhD/Foot-ankle project/Measurements';
    else
        initialFolder = '/media/storage/Storage/PhD/Measurements';
    end 
    
    %Choose files to 
    [measFileName,measPathName] = uigetfile('.mat','Select measurement files',...
        'MultiSelect','on',initialFolder);
    
    if ~iscell(measFileName)
        measFileName={measFileName};
    end
    
    %Calculate the size of the array data. First dimension is for different
    %measurements, the rest are following the same convention as all the
    %Tekscan related files.
    load([measPathName measFileName{1}],'calibratedData');
    data=zeros([size(measFileName),size(calibratedData)]);
    
    %Remove files that are not really measurements
    faulty= ~cellfun('isempty',strfind(measFileName,'calibration.mat'));
    measFileName(faulty)=[];
    faulty= ~cellfun('isempty',strfind(measFileName,'meanData.mat'));
    measFileName(faulty)=[];
    
    for i=1:size(measFileName,2)
        load([measPathName measFileName{i}],'calibratedData');
        data(1,i,:,:,:) = calibratedData;
    end
    
    %Now we can do statistics
    meanMeas=squeeze(mean(data,2));
    sdMeas=squeeze(std(data,0,2));
    
    %Define a grid to plot the results
    [y,x]=meshgrid(1:1:size(data,5),1:1:size(data,4));
    
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
    % Defining the regions that will be plotted
    meanMeas=zeros(size(data,3),size(data,2));
    cols = {1:16, 17:32};
    rows = {1:15, 16:30, 31:46};
    for i=1:length(rows)
        for j=1:length(cols)
            subplot(length(rows),length(cols),j+(i-1)*length(cols))
            for k=1:size(data,2)
                hold on
                %Calculating the mean for each region at each timestep
                for l=1:size(data,3)
                    area=data(1,k,l,rows{i},cols{j});
                    meanMeas(l,k) = mean(area(:));
                end
            end
            meanValue = mean(meanMeas,2)';
            sdValue=std(meanMeas,0,2)';
            X1=[0:1:99,fliplr(0:1:99)];
            X2=[meanValue+sdValue,fliplr(meanValue-sdValue)];
            fill(X1,X2,[0.9,0.9,1]);
            for k=1:size(data,2)
                plot(meanMeas(:,k)/1e6);
            end
            xlabel('Stance phase (%)'), ylabel('Pressure (MPa)')
            ylim([0,4]);
        end
    end
    
    % Plotting location of center of pressure in the two directions
    figure(3)
    xCen=zeros(size(data,3));
    yCen=zeros(size(data,3));
    for k=1:size(data,2)
        for l=1:size(data,3)
            xCen(l)=sum(sum(x.*squeeze(data(1,k,l,:,:))))/sum(sum(squeeze(data(1,k,l,:,:))));
            yCen(l)=sum(sum(y.*squeeze(data(1,k,l,:,:))))/sum(sum(squeeze(data(1,k,l,:,:))));
        end
        subplot(2,1,1)
        hold on
        plot(xCen)
        subplot(2,1,2)
        hold on
        plot(yCen)
    end
    subplot(2,1,1)
    ylabel('Center of pressure in A/P direction (sensel)')
    subplot(2,1,2)
    ylabel('Center of pressure in M/L direction (sensel)')
    xlabel('Stance phase (%)')
    xlim([1,max(x(:))]),ylim([1,max(y(:))])

end