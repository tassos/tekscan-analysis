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
    
    %Read measurements files
    [measFileName,measPathName] = uigetfile('.asf','Select measurement files',...
        'MultiSelect','on',OSDetection);

    if ~iscell(measFileName)
        if measFileName == 0
            return
        else
            measFileName={measFileName};
        end
    end

    %Initialising a waitbar that shows the progress to the user
    h=waitbar(0,'Initialising waitbar...');
    
    % Loading foot side and position of the sensor for deciding whether
    % flipping of the data is needed, so that all measurements are aligned
    % in the same direction. If it is a Right foot and the sensor was
    % upside Down, or if it's a left foot and the sensor was upside Up,
    % flipping is needed.
    
    % Checking if a file with the sensor information exists
    toLoad = [measPathName '../Foot details.mat'];
    if exist(toLoad,'file')
        load([measPathName '../Foot details.mat'],'foottype','upsideUp','sensor');
        Right=strcmp(foottype,'RIGHT');
        manual = 0;
    % If it doesn't, then the user is asked to select the sensor
    else
        filesList = dir([OSDetection '/Calibration measurements']);
        isub = [filesList(:).isdir];
        sensorsList = {filesList(isub).name}';
        sensorsList(ismember(sensorsList,{'.','..'}))=[];
        g = figure('Position',[300 300 200 500],'Name','Selection');
        parentpanel = uipanel('Units','pixels','Title','Choose sensor','Position',[5 50 180 400]);
        lbs = uicontrol ('Parent',parentpanel,'Style','listbox','String',sensorsList,'Units','Pixels','Position',[5 5 170 300]);
        uicontrol('Style','pushbutton','String','Done','Position',[50 5 100 30],'Callback',@hDoneCallback);
        uiwait
        sensor.tekscan=sensorsList(get(lbs,'Value'),1);
        footcase = 'tekscan';
        upsideUp.tekscan=0;
        Right=0;
        manual = 1;
        close(g)
    end

    for i=1:size(measFileName,2)
        waitbar((i/size(measFileName,2)),h,'Calibrating measurement files');
        [data,sensit,spacing] = readTekscan([measPathName measFileName{i}]);...
            %#ok<NASGU> The variable is actually used in the save function few lines below.
        
        cleanData = pressureCleanUp(data);
        
        %Detecting the foot case of the measurement (tekscan,tap,ta) and
        %constructing appropriate paths and filenames. If we are in
        %'manual' mode, then the case is defined earlier
        if ~manual
            footcase = cell2mat(lower(regexp(measFileName{i},'^[a-zA-Z\d]*','match')));
            static = 0;
            switch footcase
                case 'static2'
                    footcase = 'tekscan';
                    static = 1;
                case 'static3'
                    footcase = 'tap';
                    static = 1;
                case 'static4'
                    footcase = 'ta';
                    static = 1;
            end
        end
        sensorFileName=[OSDetection, '/Calibration matrices/',sensor.(footcase){:},'.mat'];
        calibrationFolder=[OSDetection '/Calibration measurements/',sensor.(footcase){:}];
        
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
        if xor(Right,upsideUp.(footcase))
            for k=1:size(calibratedData,1)
                calibratedData(k,:,:)=fliplr(squeeze(calibratedData(k,:,:)));
            end
        end
        
        fileName=strtrim(measFileName{i}(1:end-4));
        if static
            [calibratedData, forceLevels] =...
                staticProtocolAnalysis(calibratedData,measPathName,fileName); %#ok<NASGU> Variables are saved below
            if length(calibratedData)~=1
                save([measPathName 'Organised_' fileName '.mat'],'forceLevels','calibratedData','spacing','fileName');
            end
        else
            save([measPathName 'Calibrated_' fileName '.mat'],'calibratedData','spacing','fileName');
        end
    end
    close(h);
end

function hDoneCallback(~, ~)
    uiresume
end