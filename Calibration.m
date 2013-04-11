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

%Read calibration files
[calibFileName,calibPathName] = uigetfile('.asf','Select calibration measurement files','MultiSelect','on');
calibFileName=char(calibFileName);

%Read measurements files
[measFileName,measPathName] = uigetfile('.asf','Select measurement files','MultiSelect','on');
measFileName=char(measFileName);

%Opening file
text = fileread(strtrim([calibPathName calibFileName(1,:)]));

%Defining constants
loadArea=4e-3^2; %40mmx40mm

%Reading out information about the sensor (number of columns, rows etc).
ncols=str2double(regexp(text,'(?<=COLS )\d*','match'));
nrows=str2double(regexp(text,'(?<=ROWS )\d*','match'));
senselArea = str2double(regexp(text,'(?<=SENSEL_AREA )\d*\.\d*e-\d*','match'));

%Initialising arrays to gain speed
loads=zeros(size(calibFileName,1),1);
meanData=zeros(size(calibFileName,1),1);

%Initialising a waitbar that shows the progress to the user
h=waitbar(0,'Initialising waitbar...');

%Importing calibration data and inserting in a 3dimensional array. The
%first dimension are the rows of the sensor, the second are the columns and
%the third are for the different loading levels
for i=1:size(calibFileName,1)
    text = fileread(strtrim([calibPathName calibFileName(i,:)]));
    endFrame=str2double(regexp(text,'(?<=END_FRAME )\d*','match'));
    data=zeros(nrows*ncols,endFrame);
    
    for j=1:endFrame
        waitbar(((i-1)*endFrame+j)/(endFrame*size(calibFileName,1)),h,'Reading calibration files');
        
        %Reading the data from the correct frame
        rawData=regexp(text,['(?<=Frame ' num2str(j) '\r\n)((\d*,\d*)*\r\n)*'],'match');
        cellData=textscan(rawData{1},'%f','Delimiter',',');
        data(:,j)=cellData{1};
        
        %Averaging the data for the whole measurement duration 
    end
    meanData(i,1)=mean(mean(data,2));

    %calibration(i,:,:)=reshape(meanData,ncols,nrows)';
	loads(i,1)=str2double(calibFileName(i,1:length(regexp(calibFileName(i,:),'\d'))))*senselArea/loadArea;
end

%Define the quadratic equation that we'll use for fitting our data
function F = myfun(x,xdata)
    F = x(1)*xdata.^3+x(2)*xdata.^2+x(3)*xdata+x(4);
end

%Check to see if calibration with this sensor is already made. If
%calibration file doesn't exists, go on with calculating the fitting
%coefficients.
if (exist([calibPathName 'calibration.mat'],'file')==2);
    load([calibPathName 'calibration.mat'],'x');
else
    lsqopts = optimset('Display','off');
    coeffs = lsqcurvefit(@myfun,[0,0,0,0],loads,meanData,[],[],lsqopts)';

    %Storing in a structured way
    x.a=coeffs(1);    x.b=coeffs(2);    x.c=coeffs(3);    x.d=coeffs(4);

    save([calibPathName 'calibration.mat'], 'x');
end

for i=1:size(measFileName,1)
    text = fileread(strtrim([measPathName measFileName(i,:)]));
    endFrame=str2double(regexp(text,'(?<=END_FRAME )\d*','match'));
    calibratedData=zeros(endFrame,nrows,ncols);
    
    for j=1:endFrame
        waitbar(((i-1)*endFrame+j)/(endFrame*size(measFileName,1)),h,'Generating calibrated measurements');
        
        %Reading the data from the correct frame
        rawData=regexp(text,['(?<=Frame ' num2str(j) '\r\n)((\d*,\d*)*\r\n)*'],'match');
        cellData=textscan(rawData{1},'%f','Delimiter',',');
        data=reshape(cellData{1},ncols,nrows)';
        calibratedData(j,:,:)=x.a.*data(:,:).^3+x.b.*data(:,:).^2+x.c.*data(:,:)+x.d;
    end
    fileName=strtrim(measFileName(i,:));
    save([measPathName 'Calibrated_' fileName(1:end-4) '.mat'],'calibratedData');
end

close(h);
end