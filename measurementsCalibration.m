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

    clear all
    close all force
    clc
    
    %Read measurements files
    [measFileName,measPathName] = uigetfile('.asf','Select measurement files',...
        'MultiSelect','on',OSDetection);

    if ~iscell(measFileName)
        measFileName={measFileName};
    end

    %Initialising a waitbar that shows the progress to the user
    h=waitbar(0,'Initialising waitbar...');
    
    % Loading foot side and position of the sensor for deciding whether
    % flipping of the data is needed, so that all measurements are aligned
    % in the same direction. If it is a Right foot and the sensor was
    % upside Down, or if it's a left foot and the sensor was upside Up,
    % flipping is needed.
    load([measPathName '../Foot details.mat'],'foottype','upsideUp','sensor');
    Right=strcmp(foottype,'RIGHT');

    for i=1:size(measFileName,2)
        waitbar((i/size(measFileName,2)),h,'Calibrating measurement files');
        [data,sensit,spacing] = readTekscan([measPathName measFileName{i}]); %#ok<NASGU> The variable is actually used in the save function five lines below.
        
        %Detecting the foot case of the measurement (tekscan,tap,ta) and
        %constructing appropriate paths and filenames
        footcase = lower(regexp(measFileName{i},'^[a-zA-Z]*','match'));
        sensorFolder=[measPathName,'/../../Calibration matrices/'];
        sensorFileName=[sensorFolder,sensor.(footcase{:}){:},'.mat'];
        calibrationFolder=[measPathName,'/../../Calibration measurements/',sensor.(footcase{:}){:}];
        
        %Check to see if calibration with this sensor is already made. If
        %calibration file doesn't exists, go on with calculating the fitting
        %coefficients.
        if (exist(sensorFileName,'file')==2);
            load(sensorFileName,'x');
        else
            [meanData,loads,index] = readCalibrationFiles(h,calibrationFolder,1);
            [x] = calibrationCoeff(h,measPathName,sensorFileName,meanData,loads,index);
        end
        
        calibratedData=polyval(x.(sensit),data);
        calibratedData(calibratedData < 0) =0;
        if xor(Right,upsideUp.(footcase{:}))
            for k=1:size(calibratedData,1)
                calibratedData(k,:,:)=fliplr(squeeze(calibratedData(k,:,:)));
            end
        end
        fileName=strtrim(measFileName{i});
        save([measPathName 'Calibrated_' fileName(1:end-4) '.mat'],'calibratedData','spacing');
    end
    close(h);
end