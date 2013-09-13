%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%                       Reading tekScan ASCII files
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Function: Reading TekScan ASCII files and deriving useful information
% such as sensitivity
%
% Input
% - fileName: Path and filename of TekScan ASCII file
%
% Output 
% - Data: Pressure data from ASCII file in a 3 dimentional matrix. First
% dimension is for the time, second for the rows and third for the columns
% - Sensitivity: Selected sensitivity for the TekScan measurement
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [data, sensitivity] = readTekscan(fileName)
    text = fileread(strtrim(fileName));

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