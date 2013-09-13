function [meanData, loads, index] = readCalibrationFiles(h,pathName,batch)
    if batch
        calibPathName = [pathName,'/'];
        calibFileName = dir([calibPathName,'*.asf']);
        calibFileName = char(calibFileName.name);
    else
    %Read calibration files
        [calibFileName,calibPathName] = uigetfile('.asf','Select calibration measurement files',...
            'MultiSelect','on',pathName);
        calibFileName=char(calibFileName);
    end
    
    file_target = [calibPathName 'meanData.mat'];
    if exist(file_target,'file')
        load(file_target,'-mat','meanData','loads')
    else  
        %Defining loading area
        if ~batch
            prompt = {'Enter loading area width (mm):','Enter loading area length (mm):'};
            dimensions = str2double(inputdlg(prompt,'Input',1,{'40','40'}));
        else
            dimensions(1:2)=40;
        end
        loadArea = dimensions(1)*dimensions(2)*1e-6;

        %Importing calibration data and inserting in a 2 dimensional array. The
        %first dimension is the rows times the columns of the sensor and the
        %second is for the different loading levels
        for i=1:size(calibFileName,1)
            waitbar((i/size(calibFileName,1)),h,'Reading calibration files');
            [data,sensitivity] = readTekscan(calibPathName,calibFileName(i,:));

            %Checking if the index for the sensitivity that is calculated has
            %been created. If not, then it is created.
            if exist('index','var')==0; index.(sensitivity)=0; end
            if isfield(index,sensitivity)==0; index.(sensitivity)=0; end
                index.(sensitivity)=index.(sensitivity)+1;

                %Averaging the data for the whole measurement duration 
                meanData.(sensitivity)(index.(sensitivity),1)=mean(data(:));
                loads.(sensitivity)(index.(sensitivity),1)=str2double(calibFileName(i,1:length(regexp(calibFileName(i,:),'\d'))))/loadArea;
        end
        save(file_target, 'meanData','loads');
    end
end