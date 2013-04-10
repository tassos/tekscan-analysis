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

%Read file
[fileName,pathName] = uigetfile('.asf','Select calibration measurement files','MultiSelect','on');
fileName=char(fileName);

%Opening file
text = fileread([pathName fileName(1,:)]);

%Defining constants
loadArea=4e-3^2; %40mmx40mm

%Reading out information about the sensor (number of columns, rows etc).
ncols=str2double(regexp(text,'(?<=COLS )\d*','match'));
nrows=str2double(regexp(text,'(?<=ROWS )\d*','match'));
senselArea = str2double(regexp(text,'(?<=SENSEL_AREA )\d*\.\d*','match'));

%Initialising arrays to gain speed
calibration=zeros(size(fileName,1),nrows,ncols);
loads=zeros(size(fileName,1),1);

%Importing calibration data and inserting in a 3dimensional array. The
%first dimension are the rows of the sensor, the second are the columns and
%the third are for the different loading levels
for i=1:size(fileName,1)
    text = fileread([pathName fileName(i,:)]);
    data=regexp(text,'(?>=Frame 1\n)\d*','match');
    
%     fid = fopen([pathName fileName(i,:)]);
%     inputArray=textscan(fid,'%d','Delimiter',',','HeaderLines',30);
%     calibration(i,:,:)=reshape(inputArray{1},ncols,nrows)';
%     fclose(fid);
     loads(i,1)=str2double(fileName(i,1:length(regexp(fileName(i,:),'\d'))))*senselArea/loadArea;
end

%Define the quadratic equation that we'll use for fitting our data
function F = myfun(x,xdata)
    F = x(1)*xdata.^3+x(2)*xdata.^2+x(3)*xdata+x(4);
end

%Check to see if calibration with this sensor is already made. If
%calibration file doesn't exists, go on with calculating the fitting
%coefficients.
if (exist([pathName 'calibration.mat'],'file')==2);
    load([pathName 'calibration.mat'],'x');
else
    %Initialising arrays to gain speed
    x.a=zeros(nrows,ncols);
    x.b=zeros(nrows,ncols);
    x.c=zeros(nrows,ncols);
    x.d=zeros(nrows,ncols);
    
    %Fitting our data and storing them in the X array.
    for i=1:nrows
        for j=1:ncols
            temp = lsqcurvefit(@myfun,[0;0.00015;0.64;-3.3e2],loads,calibration(:,i,j))';
            x.a(i,j)=temp(1);
            x.b(i,j)=temp(2);
            x.c(i,j)=temp(3);
            x.d(i,j)=temp(4);
        end
    end
    save([pathName 'calibration.mat'], 'x');
end

end