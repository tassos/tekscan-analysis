function [data, sensitivity] = readTekscan(calibPathName, calibFileName)
    text = fileread(strtrim([calibPathName calibFileName]));

    %Reading out information about the sensor (number of columns, rows etc).
    ncols=str2double(regexp(text,'(?<=COLS )\d*','match'));
    nrows=str2double(regexp(text,'(?<=ROWS )\d*','match'));
    endFrame=str2double(regexp(text,'(?<=END_FRAME )\d*','match'));
    startFrame=str2double(regexp(text,'(?<=START_FRAME )\d*','match'));
    sensitivity = regexp(text,'(?<=SENSITIVITY )\S*','match');
    sensitivity = strrep(sensitivity{1},'-','');
    data=zeros(endFrame,nrows,ncols);

    for j=startFrame:endFrame
        %Reading the data from the correct frame
        rawData=regexp(text,['(?<=Frame ' num2str(j) '\r\n)((\d*,\d*)*\r\n)*'],'match');
        cellData=textscan(rawData{1},'%f','Delimiter',',');
        rawdata=reshape(cellData{1},ncols,nrows)';
        data(j,:,:)=rawdata;
    end
end