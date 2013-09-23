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
    
    plot3dErrorbars(x,y,meanMeas(1,:,:),sdMeas(1,:,:));
    h = uicontrol('style','slider','units','pixel','position',[20 20 300 20]);
    addlistener(h,'ContinuousValueChange',@(hObject, event) makeplot(hObject,x,y,meanMeas,sdMeas));

    function makeplot(hObject,x,y,meanMeas,sdMeas)
        n = floor(get(hObject,'Value')*99+1);
        plot3dErrorbars(x,y,meanMeas(n,:,:),sdMeas(n,:,:));
        refreshdata;
    end

    figure(2)
    % Defining the regions that will be plotted
    meanValue=zeros(size(data,3));
    cols = {1:16, 17:32};
    rows = {1:15, 16:30, 31:46};
    for i=1:length(rows)
        for j=1:length(cols)
            subplot(3,2,j+(i-1)*length(cols))
            for k=1:size(data,2)
                hold on
                %Calculating the mean for each region at each timestep
                for l=1:size(data,3)
                    test=data(1,k,l,rows{i},cols{j});
                    meanValue(l) = mean(test(:));
                end
                plot(meanValue/1e6);
            end
            xlabel('Stance phase 0-100%'), ylabel('Pressure (MPa)')
        end
    end

end