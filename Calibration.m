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

function Calibration

    clear all
    close all force
    clc

    %Read measurements files
    [measFileName,measPathName] = uigetfile('.asf','Select measurement files',...
        'MultiSelect','on','C:\users\u0074517\Documents\PhD\Foot-Ankle Project\Measurements');
    measFileName=char(measFileName);

    %Initialising a waitbar that shows the progress to the user
    h=waitbar(0,'Initialising waitbar...');

    %Check to see if calibration with this sensor is already made. If
    %calibration file doesn't exists, go on with calculating the fitting
    %coefficients.
    if (exist([measPathName 'calib2ration.mat'],'file')==2);
        load([measPathName 'calibration.mat'],'x');
    else
        [x] = readCalibrationFiles(h,measPathName);
    end

    for i=1:size(measFileName,1)
        text = fileread(strtrim([measPathName measFileName(i,:)]));
        ncols=str2double(regexp(text,'(?<=COLS )\d*','match'));
        nrows=str2double(regexp(text,'(?<=ROWS )\d*','match'));
        endFrame=str2double(regexp(text,'(?<=END_FRAME )\d*','match'));
        startFrame=str2double(regexp(text,'(?<=START_FRAME )\d*','match'));

        % Read sensitivity in order to use the proper calibration sheet
        sensit = regexp(text,'(?<=SENSITIVITY )\S*','match');
        sensit = strrep(sensit{1},'-','');
        calibratedData=zeros(endFrame,nrows,ncols);

        for j=startFrame:endFrame
            waitbar(((i-1)*endFrame+j)/(endFrame*size(measFileName,1)),h,'Generating calibrated measurements');

            %Reading the data from the correct frame
            rawData=regexp(text,['(?<=Frame ' num2str(j) '\r\n)((\d*,\d*)*\r\n)*'],'match');
            cellData=textscan(rawData{1},'%f','Delimiter',',');
            data=reshape(cellData{1},ncols,nrows)';
            calibratedData(j,:,:)=polyval(x.(sensit),data);
            calibratedData(calibratedData < 0) =0;
        end
        fileName=strtrim(measFileName(i,:));
        save([measPathName 'Calibrated_' fileName(1:end-4) '.mat'],'calibratedData');
    end

    close(h);
end