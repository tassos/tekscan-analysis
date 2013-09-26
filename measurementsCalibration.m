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

    %Check to see if calibration with this sensor is already made. If
    %calibration file doesn't exists, go on with calculating the fitting
    %coefficients.
    if (exist([measPathName 'calibration.mat'],'file')==2);
        load([measPathName 'calibration.mat'],'x');
    else
        [meanData,loads,index] = readCalibrationFiles(h,measPathName,0);
        [x] = calibrationCoeff(h,measPathName,meanData,loads,index);
    end

    for i=1:size(measFileName,2)        
        waitbar((i/size(measFileName,2)),h,'Calibrating measurement files');
        [data,sensit,spacing] = readTekscan([measPathName measFileName{i}]); %#ok<NASGU> The variable is actually used in the save function five lines below.
        
        calibratedData=polyval(x.(sensit),data);
        calibratedData(calibratedData < 0) =0; %#ok<NASGU> The variable is actually used in the save function two lines below.
        fileName=strtrim(measFileName{i});
        save([measPathName 'Calibrated_' fileName(1:end-4) '.mat'],'calibratedData','spacing');
    end
    close(h);
end