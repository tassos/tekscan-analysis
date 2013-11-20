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
    g = genpath('/Common');
    addpath(g);
    
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
    
    static = regexp(measFileName{1},'Organised');
   
    % Calculate the size of the array data.
    % First dimension is for different measurements, the rest
    % are following the same convention as all the Tekscan related files.
    load([measPathName measFileName{1}],'calibratedData');
    data=nan([size(measFileName),size(calibratedData)]);
        
    % Remove files that are not really measurements
    faulty= ~cellfun('isempty',strfind(measFileName,'calibration.mat'));
    measFileName(faulty)=[];
    faulty= ~cellfun('isempty',strfind(measFileName,'meanData.mat'));
    measFileName(faulty)=[];
    
    legendNames{size(measFileName,2)}=[];
    % Load calibrated data from measurement files
    for i=1:size(measFileName,2)
        if static
            load([measPathName measFileName{i}],'forceLevels');
        end
            load([measPathName measFileName{i}],'calibratedData','spacing','fileName');
        data(1,:,length(data):length(calibratedData),:,:)=NaN;
        if static
            data(1,i,1:size(calibratedData,1),:,:) = calibratedData;
        else
            data(1,i,1:size(calibratedData,1),:,:) = smooth3(calibratedData);
        end
        %Converting mm to m
        colSpacing=spacing{1}/1e3; %#ok<USENS> The variable is loaded three lines above
        rowSpacing=spacing{2}/1e3;
        senselArea = colSpacing*rowSpacing;
        legendNames{i}=strrep(fileName,'_',' ');
    end
    
    %% Statistics
    % We are calculating the mean pressure of each sensel for the different
    % measurements. Then we calculate the standard deviation of each sensel
    % for the different measurements
    meanMeas=squeeze(nanmean(data,2));
    sdMeas=squeeze(nanstd(data,0,2));
    
    %% Plotting
    
    toPlot = questdlg('Do you want to plot?','Plot graphs?','Yes','No','No');
    
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
    [rows,cols,rowsPlot,colsPlot] = areaDivision (x, y, 3, 2);
    
    % Plot pressure using a 3D mesh. The area divisions and standard
    % deviation between the measurements is also plotted
    if  size(data,2)==1
        plotSD=0;
    else
        plotSD=1;
    end
    
    if strcmp(toPlot,'Yes')
        h = plot3Dpressure(pos1, x, y, meanMeas, sdMeas, rowsPlot, colsPlot, plotSD);
    else
        h=0;
    end

    % Plot pressure and force of the different areas over stance phase
    [forceArea, forceAreaHeader, contactArea, contactAreaHeader] =...
        plotForceArea (pos2, pos3, data, rows, cols, rowsPlot, colsPlot, senselArea, toPlot);
    
    % Plot peak pressure over stance phase
    [peakPressure, peakLocation] = plotPeakPressure (pos6, h, x, y, data, legendNames, toPlot);

    % Plot location of center of pressure in two directions over stance
    % phase
    CoP = plotCenterPressure (pos4, x, y, data, toPlot);
    
    if strcmp(toPlot,'Yes')
        % Plot location of peak pressure in two directions over stance phase
        plotPeakLocation (pos4, x, y, peakLocation);
        
        % Plot kinematics information for the roll-offs
        plotKinematics (h, measPathName, legendNames);
    end

    % Plot total force through the joint over stance phase
    forceTotal = plotForceTotal (pos5, h, data, senselArea, legendNames, toPlot);
    
    %% Saving
    prompt = {'Do you want to save to a file?'};
    saveToFile = questdlg(prompt,'Save to file?','Yes','No','Yes');
    
    if strcmp(saveToFile,'Yes')
        legendNames = [legendNames{:},{'mean','std'}];
        
        headers = [forceAreaHeader, contactAreaHeader, {'PeakPressure','PeakLocation A/P','PeakLocation M/L','CoP A/P','CoP M/L','forceTotal'}];
        dataToSave = permute(cat(3,forceArea,contactArea,peakPressure(:,:,2),peakLocation,CoP,forceTotal(:,:,2)),[2 3 1]);
        if static
            headersStatic = {'Peronei','Tib Ant','Tib Post','Flex Dig','Gatroc','Flex Hal','GRF','Hor pos','Sag rot'};
            headers = [headers, headersStatic];
            dataToSave = [dataToSave,repmat(forceLevels,[1 1 size(dataToSave,3)])];
        end
        dataToSave(:,:,end+1)=nanmean(dataToSave,3);
        dataToSave(:,:,end+1)=nanstd(dataToSave,0,3);
        overwriteXLS(measPathName, dataToSave, headers, legendNames)
    end
end