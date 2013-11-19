function [pressureData, forceLevels] = staticProtocolAnalysis(calibratedData, measPathName, filename)
%STATICPROTOCOLANALYSIS Analysing different TekScan static
% protocol measurements
% Function: Comparing the results of different static protocol
% measurements. No inputs or outputs from this function. 
   
    %Sampling rate of the TekScan measurements
    sRateT=10;
    sRateRt=500;
    
    pathRt = [measPathName '../Real-Time/'];
    filesRt = dir([pathRt '*.tdms']);
    
    %Searching for the corresponding Real-Time file. If no
    % corresponding rT file is found, then move to the next measurement

    indexRt = findFile([filename,'_'],filesRt);

    if indexRt == 0
        warndlg(['No Real-Time measurement was found for ' filename ' measurement file'],'!! Warning !!')
        uiwait
        TDMSfile = uigetfile('.tdms',['Please select appropriate Real-time file for ' filename 'measurement'],pathRt);
    else
        TDMSfile = filesRt(indexRt).name;
    end

    % Loading the TDMS file and extracting the muscle input file of the
    % simulation and the syncronisation signal
    loadcelldata = TDMS_readTDMSFile([pathRt TDMSfile]);

    forces = downsample([loadcelldata.data{8}',loadcelldata.data{9}',...
        loadcelldata.data{10}',loadcelldata.data{11}',loadcelldata.data{12}',...
        loadcelldata.data{13}',loadcelldata.data{14}',loadcelldata.data{15}',...
        loadcelldata.data{16}'],sRateRt/sRateT);

    %Calculating number of steps in the static protocol measurement.
    %Checking which measurement (TekScan or Rt) is smaller and taking that
    %as a reference.
    stepsT=floor((length(calibratedData)+10)/40);
    stepsRt=floor((length(forces)+10)/40);
    steps=min(stepsT,stepsRt);

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
        pressureData(steps+1,:,:) = mean(calibratedData(steps*40+1:finalRow,:,:),1);
        forceLevels(steps+1,:) = mean(forces(steps*40+1:finalRow,:),1);
    end
end