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

function [data, sensitivity, spacing] = readTekscan(fileName)
    text = fileread(strtrim(fileName));

    %Reading out information about the sensor (number of columns, rows etc).
    ncols=str2double(regexp(text,'(?<=COLS )\d*','match'));
    nrows=str2double(regexp(text,'(?<=ROWS )\d*','match'));
    colSpacing=str2double(regexp(text,'(?<=COL_SPACING )\d*.\d*','match'));
    rowSpacing=str2double(regexp(text,'(?<=ROW_SPACING )\d*.\d*','match'));
    spacing = {colSpacing, rowSpacing};
    endFrame=str2double(regexp(text,'(?<=END_FRAME )\d*','match'));
    startFrame=str2double(regexp(text,'(?<=START_FRAME )\d*','match'));
    sensitivity = regexp(text,'(?<=SENSITIVITY )\S*','match');
    sensitivity = strrep(sensitivity{1},'-','');
    
    frameStr = ['Frame ' num2str(startFrame) '\r\n'];
    strEnd = strfind(text,sprintf(frameStr)) + length(sprintf(frameStr));
    
    rawData = regexprep(text(strEnd:end),'Frame \d*|@@','');
    rawData = strrep(rawData,sprintf('\r\n'),';');
    rawData = strrep(rawData,';;',';');
    rawData = strrep(rawData,';;',';');
    rawData = strrep(rawData,',',';');
    rawData = textscan(rawData,'%f','Delimiter',';');
    data = reshape(rawData{1},ncols,nrows,(endFrame-startFrame+1));
    data = permute(data,[3 2 1]);
end