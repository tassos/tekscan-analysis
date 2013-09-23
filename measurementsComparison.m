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
    %Choose files to 
    [measFileName,measPathName] = uigetfile('.mat','Select measurement files',...
        'MultiSelect','on','C:\users\u0074517\Documents\PhD\Foot-Ankle Project\Measurements');
    
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
    x=repmat(1:size(data,4),size(data,5),1)';
    y=repmat(1:size(data,5),size(data,4),1);
    
    hplot = plot3dErrorbars(x,y,meanMeas(1,:,:),sdMeas(1,:,:));
    h = uicontrol('style','slider','units','pixel','position',[20 20 300 20]);
    addlistener(h,'ActionEvent',@(hObject, event) makeplot(hObject,x,y,meanMeas,sdMeas));

    function makeplot(hObject,x,y,meanMeas,sdMeas)
        n = floor(get(hObject,'Value')*99+1);
        plot3dErrorbars(x,y,meanMeas(n,:,:),sdMeas(n,:,:));
        refreshdata;
    end

end