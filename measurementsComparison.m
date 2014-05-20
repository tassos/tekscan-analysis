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
    addToPath;
    
    [cases, directories, toPlot, saveToFile] = Questions;
    
    for z=1:size(directories,2)
        %% Loading measurement files
        measPathName = [directories{z},'/Tekscan/'];
        measFileName = dir([measPathName,'*.mat']);
        measFileName = filesCleanUp(cases,{measFileName.name});

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

        legendNames{size(measFileName,2)}=[]; %#ok<AGROW> Not true
        % Load calibrated data from measurement files
        for i=1:size(measFileName,2)
            if static
                load([measPathName measFileName{i}],'forceLevels');
            end
            load([measPathName measFileName{i}],'calibratedData','spacing','fileName');
            data(1,:,length(data)+1:length(calibratedData),:,:)=NaN;
            data(1,i,1:size(calibratedData,1),:,:) = calibratedData;
            %Converting mm to m
            colSpacing=spacing{1}/1e3; %#ok<USENS> The variable is loaded three lines above
            rowSpacing=spacing{2}/1e3;
            senselArea = colSpacing*rowSpacing;
            legendNames{i}=strrep(fileName,'_',' '); %#ok<AGROW> Not true
        end
        % Trimming the sensor by 2 rows and columns in each side to get rid of
        % high pressure artefacts
        trim = 2;
        data(:,:,:,[1:trim,end-trim+1:end],:)=[];
        data(:,:,:,:,[1:trim,end-trim+1:end])=[];

        if ~static            
            for i=1:size(measFileName,2)
                data(1,i,1:size(calibratedData,1),:,:) = smooth3(data(1,i,1:size(calibratedData,1),:,:));
            end
        end

        %% Statistics
        % We are calculating the mean pressure of each sensel for the different
        % measurements. Then we calculate the standard deviation of each sensel
        % for the different measurements
        meanMeas=squeeze(nanmean(data,2));
        sdMeas=squeeze(nanstd(data,0,2));

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

        % Plot peak pressure for the different sub-areas
        [pressureArea, pressureAreaHeader] = plotPeakArea (pos6, data, rows, cols, rowsPlot, colsPlot, toPlot);

        % Plot location of center of pressure in two directions over stance
        % phase
        CoP = plotCenterPressure (pos4, x, y, data, toPlot);

        % Plot total force through the joint over stance phase
        forceTotal = plotForceTotal (pos5, h, data, senselArea, legendNames, toPlot);

        if strcmp(toPlot,'Yes')
            % Plot location of peak pressure in two directions over stance phase
            plotPeakLocation (pos4, x, y, peakLocation);

            % Plot kinematics information for the roll-offs
            % plotKinematics (h, measPathName, legendNames);
        end

        %% Saving

        if strcmp(saveToFile,'Yes')
            headers = [forceAreaHeader, contactAreaHeader, pressureAreaHeader,...
                {'PeakPressure','PeakLocation A/P','PeakLocation M/L','CoP A/P','CoP M/L','forceTotal'}];
            dataToSave = permute(cat(3,forceArea,contactArea,pressureArea,...
                peakPressure(:,:,2),peakLocation,CoP,forceTotal(:,:,2)),[2 3 1]);
            if static
                headersStatic = {'Peronei','Tib Ant','Tib Post','Flex Dig','Gatroc','Flex Hal','GRF','Hor pos','Sag rot'};
                headers = [headers, headersStatic]; %#ok<AGROW> Not true
                dataToSave = [dataToSave,repmat(forceLevels,[1 1 size(dataToSave,3)])]; %#ok<AGROW> Not true
            end

            for j=1:length(cases);
                k=0;
                for i=1:size(dataToSave,3)
                    if ~isempty(strfind(legendNames{i},cases{j}))
                        k=k+1;
                        Rdata.(cases{j}(1:end-1)).data(k,:,:) = dataToSave(:,:,i);
                        Rdata.(cases{j}(1:end-1)).names{k} = ['Trial ' sprintf('%02d',k)];
                    end
                end
            end
            name = strsplit(legendNames{i},' ');
            Rdata.Foot = name{1};
            Rdata.Variables = headers;

            save([measPathName '../../Voet 99/Results/Tekscan_Data_' name{1} '.mat'],'Rdata');

    %         legendNames = [legendNames{:},{'mean','std'}];
    %         dataToSave(:,:,end+1)=nanmean(dataToSave,3);
    %         dataToSave(:,:,end+1)=nanstd(dataToSave,0,3);
    %         overwriteXLS(measPathName, dataToSave, headers, legendNames)
        end
    end
end

function [cases, directories, toPlot, saveToFile] = Questions
    directories = uipickfiles('FilterSpec',OSDetection);
    
    cases = {'Tekscan_','TAP_','TA_'};
    figure('Position',[300 300 200 300],'Name','Selection');
    parentpanel2 = uipanel('Units','pixels','Title','Choose combos','Position',[5 50 180 200]);
    lbs = uicontrol ('Parent',parentpanel2,'Style','listbox','Max',3,'String',cases,'Units','Pixels','Position',[5 5 170 100]);
    uicontrol('Style','pushbutton','String','Done','Position',[50 5 100 30],'Callback',@hDoneCallback);
    uiwait
    cases = cases(get(lbs,'Value'));
    close
    
    toPlot = questdlg('Do you want to plot?','Plot graphs?','Yes','No','No');
    saveToFile = questdlg('Do you want to save to a file?','Save to file?','Yes','No','Yes');
end

function newFileNames = filesCleanUp(cases,fileNames)

    newFileNames={};
    for i=1:length(cases)
        newFileNames = [newFileNames,fileNames(not(cellfun('isempty',strfind(fileNames,cases{i}))))]; %#ok<AGROW> Nothing I can do about it
    end
end

function hDoneCallback(~, ~)
    uiresume
end