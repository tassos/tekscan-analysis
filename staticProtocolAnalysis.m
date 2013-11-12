function staticProtocolAnalysis
%STATICPROTOCOLANALYSIS Analysing different TekScan static
% protocol measurements
% Function: Comparing the results of different static protocol
% measurements. No inputs or outputs from this function. 
    clear
    close all force
    clc
    
    %% Loading measurement files
    
    % Choose measurements files to load and compare
    [measFileName,measPathName] = uigetfile('.mat','Select measurement files',...
        'MultiSelect','on',OSDetection);
    
    pathRt = [measPathName '../Real-Time/'];
    filesRt = dir([pathRt '*.tdms']);
    
    % If the array of filenames is not a cell, convert it (e.g. in case only one
    % file is selected)
    if ~iscell(measFileName)
        if measFileName == 0
            return
        else
            measFileName={measFileName};
        end
    end
    
    %Sampling rate of the TekScan measurements
    sRateT=10;
    sRateRt=500;
    
    for i=1:size(measFileName,2);
        %Finding the root of the file name and searching for the
        %corresponding Real-Time file. If no corresponding rT file is
        %found, then move to the next measurement
        fileID = regexp(measFileName{i},'(?<=Calibrated_)\w*','match');
        indexRt = findFile([fileID{1},'_'],filesRt);
        
        if indexRt == 0
            warndlg(['No Real-Time measurement was found for ' fileID{1} ' measurement file'],'!! Warning !!')
            continue
        end
        
        % Loading the TDMS file and extracting the muscle input file of the
        % simulation and the syncronisation signal
        loadcelldata = TDMS_readTDMSFile([pathRt filesRt(indexRt).name]);
        
        forces = downsample([loadcelldata.data{8}',loadcelldata.data{9}',...
            loadcelldata.data{10}',loadcelldata.data{11}',...
            loadcelldata.data{12}',loadcelldata.data{13}'],sRateRt/sRateT);
        
        %Loading TekScan measurement and storing in an array the mean of
        %the pressure for each muscle activation level.
        load([measPathName measFileName{i}],'calibratedData','spacing','fileName');
        
        %Calculating number of steps in the static protocol measurement
        steps=floor(length(calibratedData)+10/40);%#ok<NODEF> Variable is loaded a few lines above
        
        %Initialising storing arrays for speed optimisation
        pressureData=zeros(steps,size(calibratedData,2),size(calibratedData,3));
        forceLevels=zeros(steps,size(forces,2));
        
        %Start storing all the data for each step in a separate row.
        for j=1:steps
            pressureData(j,:,:) = mean(calibratedData((j-1)*40+1:j*40-10,:,:),1);
            forceLevels(j,:) = mean(forces((j-1)*40+1:j*40-10,:),1);
            if (j*40+1)>length(calibratedData)
                break
            end
        end
        
        % If the number of steps is not an integer, save the last step
        if ~~mod(length(calibratedData)+10,40);
            finalRow = min(length(calibratedData),steps*40-10);
            pressureData(steps+1,:,:) = mean(calibratedData(steps*40+1:finalRow,:,:),1); %#ok<NASGU> Variable is saved a few lines below
            forceLevels(steps+1,:) = mean(forces(steps*40+1:finalRow,:),1); %#ok<NASGU> Variable is saved a few lines below
        end
        
        % Save data in a file
        save([measPathName 'Organised_' fileName '.mat'],'pressureData','forceLevels','calibratedData','spacing','fileName');
    end
end