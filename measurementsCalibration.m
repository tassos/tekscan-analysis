%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%                              TekScan sensor calibration
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Function: Calibrating TekScan measurement files based on calibration
% measurements.
%
% Input: none, the software opens a file dialog for loading the calibration
% measurements and the actual measurements
%
% Output: Gives the actual measurement files calibrated.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function measurementsCalibration
clear
close all force
clc

directories = uipickfiles('FilterSpec',OSDetection);
prompt = {'Do you want to perform the calibration in batch mode?'};
batch = questdlg(prompt,'Batch mode of calibration','Yes','No','Yes');
for z=1:size(directories,2)
    measFileName = dir([directories{z},'/*.asf']);
    measFileName = {measFileName.name};

    %Initialising a waitbar that shows the progress to the user
    h=waitbar(0,'Initialising waitbar...');
    
    % Checking if a file with the sensor information exists
    toLoad = [directories{z} '/Specimen_details.yml'];
    if ~exist(toLoad,'file')
        % If it doesn't, then the user is asked to select it him/herself
        [footFile, footPath] = uigetfile([directories{z},'*.xml'],'Select variable with details for the specimen');
        toLoad = [footPath, footFile];
    end
    [side, flip, sensor, specimen] = ExtractDetails(toLoad);

    for i=1:size(measFileName,2)
        label = strrep(measFileName{i}(1:end-4),'_',' ');
        waitbar((i/size(measFileName,2)),h,['Calibrating ' label ' measurement of ' lower(specimen)]);
        [data,sensit,spacing] = readTekscan([directories{z} '\' measFileName{i}]); %#ok<NASGU> Used later for saving
        
        cleanData = pressureCleanUp(data);
        
        %Detecting the foot case of the measurement and constructing
        %appropriate paths and filenames.
        specimenCase = cell2mat(lower(regexp(measFileName{i},'^[a-zA-Z\d]*','match')));
        sensorFileName=[OSDetection, '/Calibration matrices/',sensor.(lower(specimenCase)),'.mat'];
        
        %Check to see if calibration for this sensor is already made. If
        %calibration file doesn't exists, calculate the calibration matrix.
        if (exist(sensorFileName,'file')==2);
            load(sensorFileName,'x','yi');
        else
            calibrationFolder=[OSDetection '/Calibration measurements/',sensor.(lower(specimenCase))];
            [meanData,loads,index] = readCalibrationFiles(h,calibrationFolder,batch);
            [x, yi] = calibrationCoeff(h,measPathName,sensorFileName,meanData,loads,index);
        end
        
        % Asking the user which calibration curve to be used
        prompt = {'Choose calibration curve to be used'};
        calibrationCurve = questdlg(prompt,'Calibration curve','PCHIP','Polynomial fitting','PCHIP');
        
        % Deciding which calibration curve to use for calibrating the data,
        % based on user selection above.
        switch calibrationCurve
            case 'Curve fitting'
                calibratedData=polyval(x.(sensit),cleanData);
            case 'PCHIP'
                calibratedData=yi.(sensit)(cleanData+1);
        end       
        
        % Loading specimen side and positining of the sensor for deciding whether
        % flipping of the data is needed, so that all measurements are aligned
        % in the same direction. If it is a right side speciment and the sensor was
        % upside Down, or if it's a left foot and the sensor was upside Up,
        % flipping is needed.
        calibratedData(calibratedData < 0) =0;
        if xor(strcmp(side,'RIGHT'),flip.(lower(specimenCase)))
            for k=1:size(calibratedData,1)
                calibratedData(k,:,:)=fliplr(squeeze(calibratedData(k,:,:)));
            end
        end
        
        fileName = [lower(specimen) '_' strtrim(measFileName{i}(1:end-4))];
        save([directories{z} 'Calibrated_' fileName '.mat'],'calibratedData','spacing','fileName');
    end
    close(h);
end
end