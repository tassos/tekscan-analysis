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

            text = fileread(strtrim([calibPathName calibFileName(i,:)]));

            %Reading out information about the sensor (number of columns, rows etc).
            ncols=str2double(regexp(text,'(?<=COLS )\d*','match'));
            nrows=str2double(regexp(text,'(?<=ROWS )\d*','match'));
            endFrame=str2double(regexp(text,'(?<=END_FRAME )\d*','match'));
            startFrame=str2double(regexp(text,'(?<=START_FRAME )\d*','match'));
            sensitivity = regexp(text,'(?<=SENSITIVITY )\S*','match');
            sensitivity = strrep(sensitivity{1},'-','');
            data=zeros(nrows*ncols,endFrame);

            for j=startFrame:endFrame
                waitbar(((i-1)*endFrame+j)/(endFrame*size(calibFileName,1)),h,'Reading calibration files');

                %Reading the data from the correct frame
                rawData=regexp(text,['(?<=Frame ' num2str(j) '\r\n)((\d*,\d*)*\r\n)*'],'match');
                cellData=textscan(rawData{1},'%f','Delimiter',',');
                data(:,j)=cellData{1};

            end
            %Checking if the index for the sensitivity that is calculated has
            %been created. If not, then it is created.
            if exist('index','var')==0; index.(sensitivity)=0; end
            if isfield(index,sensitivity)==0; index.(sensitivity)=0; end
                index.(sensitivity)=index.(sensitivity)+1;

                %Averaging the data for the whole measurement duration 
                meanData.(sensitivity)(index.(sensitivity),1)=mean(mean(data,2));
                loads.(sensitivity)(index.(sensitivity),1)=str2double(calibFileName(i,1:length(regexp(calibFileName(i,:),'\d'))))/loadArea;
        end
        save(file_target, 'meanData','loads');
    end
end