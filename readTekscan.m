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
% - Spacing: the spacing of the rows and columns, used later on to
% calculate the pressure from the force
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
    
    % Detecting how many columns of 'B' there are, by counting all the 'B,'
    % found in the string, and dividing by the number of rows and frames.
    % Then substracting that number of columns, by the number provided by
    % the sensor. The new ncols will be used for the reshaping of the array at the end.
    ncols = ncols - length(regexp(text(strEnd:end),'B,'))/(nrows*(endFrame-startFrame+1));
    
    % Finally, removing all the 'B,' from the string.
    text = strrep(text(strEnd:end),'B,','');
    rawData = textscan(text,'%f','CommentStyle','Frame','Delimiter',',');
    
%     % This is a slightly faster way to scrap the data, but less robust
%     % than the 'textscan' solution. The speedup is around .5" for a
%     % string of 25M chars (a tekscan measurement of 15' at 10Hz).
%     % More info: http://stackoverflow.com/questions/19977984/replace-multiple-substrings-using-strrep-in-matlab
%     rawData = strrep(text(strEnd:end),sprintf('\r\n\r\nFrame '),',');
%     rawData = strrep(rawData,sprintf('\r\n'),',');
%     rawData = textscan(rawData,'%n','Delimiter',',');
%     rawData{1}(ncols*nrows*startFrame+startFrame:ncols*nrows+1:nrows*ncols*(endFrame-1)+endFrame-1)=[];
    
    data = reshape(rawData{1},ncols,nrows,(endFrame-startFrame+1));
    data = permute(data,[3 2 1]);
end