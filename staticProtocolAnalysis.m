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
    
    sRate=10;
    
    for i=1:size(measFileName,1);
        fileID = regexp(measFileName{i},'(?<=Calibrated_)\w*','match');
        indexRt = findFile([fileID{1},'_'],filesRt);
        
        if indexRt == 0
            warndlg(['No Real-Time measurement was found for ' fileID{1} ' measurement file'],'!! Warning !!')
            continue
        end
        
        loadcelldata = TDMS_readTDMSFile([pathRt filesRt(indexRt).name]);
        inputFile = loadcelldata.data{5};
        
        A = importdata(inputFile{1},'\t');
        
        load([measPathName measFileName{i}],'calibratedData','spacing','fileName');
        
        pressureData = zeros(size(A,1),size(calibratedData,2),size(calibratedData,3));%#ok<NODEF> This variable is loaded a few lines above
        forceLevels = zeros(size(A,1),size(A,2)-2);
        k=0;
        for j=1:size(A,1)-1
            if (A(j+1,1)*sRate > size(calibratedData,1))
                if A(j,2:end-1) == A(j+1,2:end-1)
                    k=k+1;
                    pressureData(k,:,:) = mean(calibratedData(A(j,1)*sRate+1:end,:,:),1);
                    forceLevels(k,:) = A(j,2:end-1);
                end
                continue
            else
                if A(j,2:end-1) == A(j+1,2:end-1)
                    k=k+1;
                    pressureData(k,:,:) = mean(calibratedData(A(j,1)*sRate+1:A(j+1,1)*sRate,:,:),1);
                    forceLevels(k,:) = A(j,2:end-1);
                end
            end
        end
        pressureData(k+1:end,:,:)=[];
        forceLevels(k+1:end,:,:)=[];
    end
end