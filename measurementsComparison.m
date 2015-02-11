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
        
        % Last variable defines how many measurements from each foot and case should be
        % analysed. If it is set to 0, all measurements are analysed.
        % Second from the end defines the first measurement to be
        % considered.
        measFileName = filesCleanUp(cases,{measFileName.name},1,0);
        if isempty(measFileName)
            continue
        end

        % Calculate the size of the array data.
        % First dimension is for different measurements, the rest
        % are following the same convention as all the Tekscan related files.
        load([measPathName measFileName{1}],'calibratedData');
        data=nan([size(measFileName),size(calibratedData)]);
        legendNames{size(measFileName,2)}=[]; %#ok<AGROW> Not true
        % Load calibrated data from measurement files
        for i=1:size(measFileName,2)
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
        data(:,:,:,[1:trim,end-trim+1:end],:)=0;
        data(:,:,:,:,[1:trim,end-trim+1:end])=0;
        
        for i=1:size(data,2)
            data(1,i,:,:,:) = smooth3(squeeze(data(1,i,:,:,:)));
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
        plotSD = min(size(data,2)-1,1);

        if toPlot
            h = plot3Dpressure(pos1, x, y, meanMeas, sdMeas, rowsPlot, colsPlot, plotSD);
        else
            h=0;
        end

        % Plot pressure and force of the different areas over stance phase
        [forceArea, forceAreaHeader, contactArea, contactAreaHeader] = ...
            plotForceArea (pos2, pos3, data, rows, cols, rowsPlot, colsPlot, senselArea, toPlot);

        % Plot peak pressure over stance phase
        [peakPressure, peakLocation] = plotPeakPressure (pos6, h, x, y, data, legendNames, toPlot, rowSpacing, colSpacing);

        % Plot peak pressure for the different sub-areas
        [pressureArea, pressureAreaHeader] = plotPeakArea (pos6, data, rows, cols, rowsPlot, colsPlot, toPlot);

        % Plot location of center of pressure in two directions over stance
        % phase
        CoP = plotCenterPressure (pos4, x, y, data, toPlot, rowSpacing, colSpacing);

        % Plot total force through the joint over stance phase
        forceTotal = plotForceTotal (pos5, h, data, senselArea, legendNames, toPlot);

        if toPlot
            % Plot location of peak pressure in two directions over stance phase
            plotPeakLocation (pos4, x, y, peakLocation);
        end

        %% Saving

        if saveToFile          
            headers = [forceAreaHeader, contactAreaHeader, pressureAreaHeader,...
                {'PeakPressure','PeakLocation A/P','PeakLocation M/L','CoP A/P','CoP M/L','forceTotal'}];
            dataToSave = permute(cat(3,forceArea,contactArea,pressureArea,...
                peakPressure(:,:,2),peakLocation,CoP,forceTotal(:,:,2)),[2 3 1]);
            
            clear Rdata RdataS
            for j=1:length(cases);
                k=0;
                p=0;
                for i=1:size(dataToSave,3)
                    if ~isempty(strfind(measFileName{i},[cases{j},'_'])) && isempty(strfind(measFileName{i},'static'))
                        k=k+1;
                        Rdata.(cases{j}).data(k,:,:) = dataToSave(:,:,i);
                        Rdata.(cases{j}).names{k} = ['Trial ' sprintf('%02d',k)];
                    elseif ~isempty(strfind(measFileName{i},[cases{j},'_'])) && ~isempty(strfind(measFileName{i},'static'))
                        p=p+1;
                        RdataS.(cases{j}).data(p,:,:) = dataToSave(:,:,i);
                        RdataS.(cases{j}).names{p} = ['Trial ' sprintf('%02d',p)];
                    end
                end
            end
           
            name = strsplit(legendNames{1},' ');
            Rdata.Foot = name{1};
            Rdata.Variables = headers;
            RdataS.Foot = name{1};
            RdataS.Variables = headers;

            [~,~,~] = mkdir([directories{z},'\..'], 'Analysed_Results'); %Requesting three output variables, so that it does not give a warning when the folder exists
            save([directories{z} '/../Analysed_Results/Tekscan_Data_' name{1} '.mat'],'Rdata','RdataS');
        end
    end
end

function [cases, directories, toPlot, saveToFile] = Questions
    directories = uipickfiles('FilterSpec',OSDetection);
    
    info = ReadYaml([directories{1},'\Specimen_details.yml']);
    cases=cell(1,length(info.cases));
    for i=1:length(info.cases)
        cases{i} = info.cases{i}.name;
    end
    
    figure('Position',[300 300 200 300],'Name','Selection');
    parentpanel2 = uipanel('Units','pixels','Title','Choose combos','Position',[5 50 180 200]);
    lbs = uicontrol ('Parent',parentpanel2,'Style','listbox','Max',3,'String',cases,'Units','Pixels','Position',[5 5 170 100]);
    uicontrol('Style','pushbutton','String','Done','Position',[50 5 100 30],'Callback',@hDoneCallback);
    uiwait
    cases = cases(get(lbs,'Value'));
    close
    
    toPlot = strcmp(questdlg('Do you want to plot?','Plot graphs?','Yes','No','No'),'Yes');
    if toPlot
        saveToFile = strcmp(questdlg('Do you want to save to a file?','Save to file?','Yes','No','Yes'),'Yes');
    else
        saveToFile= 1;
    end
end

function newFileNames = filesCleanUp(cases,fileNames,m,n)

    newFileNames={};
    for i=1:length(cases)
        tempFileNames = fileNames(not(cellfun('isempty',strfind(lower(fileNames),[lower(cases{i}),'_']))));
        %Finding the correct order of the measurements by adding a 0 in
        %front of one digit numbers
        [~,order] = sort(regexprep(tempFileNames,'(?<=_)\d{1,1}(?=.mat)','0$0'));
        
        %Reordering the files based on the order
        tempFileNames = tempFileNames(order);
        
        %Keeping only a specific amount of measurements, defined by n
        if ~n
            p=length(tempFileNames);
        end
        if m<=length(tempFileNames)
            newFileNames = [newFileNames, tempFileNames(m:min(length(tempFileNames),m+p-1))]; %#ok<AGROW> Nothing I can do about it
        end
        if ~exist('newFileNames','var')
            newFileNames=cell(0);
        end
    end
end

function hDoneCallback(~, ~)
    uiresume
end