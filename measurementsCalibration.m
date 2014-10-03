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
for z=1:size(directories,2)
    measPathName = [directories{z},'/Tekscan/'];
    measFileName = dir([measPathName,'*.asf']);
    measFileName = {measFileName.name};

    %Initialising a waitbar that shows the progress to the user
    h=waitbar(0,'Initialising waitbar...');
    
    % Loading foot side and position of the sensor for deciding whether
    % flipping of the data is needed, so that all measurements are aligned
    % in the same direction. If it is a Right foot and the sensor was
    % upside Down, or if it's a left foot and the sensor was upside Up,
    % flipping is needed.
    
    % Checking if a file with the sensor information exists
    toLoad = [measPathName '../Foot details.mat'];
    if ~exist(toLoad,'file')
        % If it doesn't, then the user is asked to select it him/herself
        [footFile, footPath] = uigetfile([measPathName,'*.mat'],'Select variable with foot details');
        toLoad = [footPath, footFile];
    end
    load(toLoad,'foottype','upsideUp','sensor','footnumber');

    for i=1:size(measFileName,2)
        label = strrep(measFileName{i}(1:end-4),'_',' ');
        waitbar((i/size(measFileName,2)),h,['Calibrating ' label ' measurement of ' lower(footnumber)]);
        [data,sensit,spacing] = readTekscan([measPathName measFileName{i}]);...
            %#ok<NASGU> The variable is actually used in the save function few lines below.
        
        cleanData = pressureCleanUp(data);
        
        %Detecting the foot case of the measurement (tekscan,tap,ta) and
        %constructing appropriate paths and filenames. If we are in
        %'manual' mode, then the case is defined earlier
        footcase = cell2mat(lower(regexp(measFileName{i},'^[a-zA-Z\d]*','match')));
        static = 0;
        switch footcase
            case 'static2'
                footcase = 'Tekscan';
                static = 1;
            case 'static3'
                footcase = 'TAP';
                static = 1;
            case 'static4'
                footcase = 'TA';
                static = 1;
        end
        sensorFileName=[OSDetection, '/Calibration matrices/',sensor.(lower(footcase)){:},'.mat'];
        calibrationFolder=[OSDetection '/Calibration measurements/',sensor.(lower(footcase)){:}];
        
        %Check to see if calibration with this sensor is already made. If
        %calibration file doesn't exists, go on with calculating the fitting
        %coefficients.
        if (exist(sensorFileName,'file')==2);
            load(sensorFileName,'x','yi');
            calibrationCurve = 'PCHIP';
        else
            [meanData,loads,index] = readCalibrationFiles(h,calibrationFolder,1);
            [x, yi] = calibrationCoeff(h,measPathName,sensorFileName,meanData,loads,index);
            
            % Asking the user which calibration curve to be used
            prompt = {'Choose calibration curve to be used'};
            calibrationCurve = questdlg(prompt,'Calibration curve','PCHIP','Polynomial fitting','PCHIP');
        end
        
        % Deciding which calibration curve to use for calibrating the data,
        % based on user selection above.
        switch calibrationCurve
            case 'Curve fitting'
                calibratedData=polyval(x.(sensit),cleanData);
            case 'PCHIP'
                calibratedData=yi.(sensit)(cleanData+1);
        end       
        
        calibratedData(calibratedData < 0) =0;
        if xor(strcmp(foottype,'RIGHT'),upsideUp.(lower(footcase)))
            for k=1:size(calibratedData,1)
                calibratedData(k,:,:)=fliplr(squeeze(calibratedData(k,:,:)));
            end
        end
        
        fileNameRt = strtrim(measFileName{i}(1:end-4));
        fileName = [lower(footnumber) '_' fileNameRt];
        if static
            fileName = regexprep(fileName,'Static*\d',footcase); %Replacing Static# with the foot case
            [calibratedData, forceLevels, origForceLevels] =...
                staticProtocolAnalysis(calibratedData,measPathName,fileNameRt,foottype,footnumber,'pres'); %#ok<*ASGLU,NASGU> Variables are saved below
            if length(calibratedData)~=1
                save([measPathName 'StaticProtocol/Organised_' fileName '.mat'],'forceLevels','origForceLevels','calibratedData','spacing','fileName');
            end
        else
            save([measPathName 'Calibrated_' fileName '.mat'],'calibratedData','spacing','fileName');
        end
    end
    close(h);
end
end