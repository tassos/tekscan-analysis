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
        senselArea = colSpacing*rowSpacing;
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
    [rows,cols,rowsPlot,colsPlot] = areaDivision (x, y, 3, 2);
    
    % Plot pressure using a 3D mesh. The area divisions and standard
    % deviation between the measurements is also plotted
    plot3Dpressure(pos1, x, y, meanMeas, sdMeas, rowsPlot, colsPlot, ~~(size(data,2)-1))

    % Plot pressure and force of the different areas over stance phase
    plotForceArea (pos2, pos3, data, rows, cols, rowsPlot, colsPlot, senselArea);

    % Plot location of center of pressure in two directions over stance
    % phase
    plotCenterPressure (pos4, x, y, data)

    % Plot total force through the joint over stance phase
    plotForceTotal (pos5, data, senselArea)
    
    % Plot peak pressure over stance phase
    plotPeakPressure (pos6, data, legendNames)
    
    % Plot kinematics information for the roll-offs
    plotKinematics (measPathName, legendNames)
end