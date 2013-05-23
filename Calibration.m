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
close all

%Read measurements files
[measFileName,measPathName] = uigetfile('.asf','Select measurement files','MultiSelect','on');
measFileName=char(measFileName);

%Define the cubic equation that we'll use for fitting our data
function F = cubFitFun(x,xdata)
    F =x(1)*xdata.^5+x(2)*xdata.^4+x(3)*xdata.^3+x(4)*xdata.^2+x(5)*xdata+x(6);
end

%Opening file
text = fileread(strtrim([measPathName measFileName(1,:)]));

%Reading out information about the sensor (number of columns, rows etc).
ncols=str2double(regexp(text,'(?<=COLS )\d*','match'));
nrows=str2double(regexp(text,'(?<=ROWS )\d*','match'));

%Initialising a waitbar that shows the progress to the user
h=waitbar(0,'Initialising waitbar...');

%Check to see if calibration with this sensor is already made. If
%calibration file doesn't exists, go on with calculating the fitting
%coefficients.
if (exist([measPathName 'calibration2.mat'],'file')==2);
    load([measPathName 'calibration.mat'],'x');
else

    %Read calibration files
    [calibFileName,calibPathName] = uigetfile('.asf','Select folder containing calibration measurement files','MultiSelect','on');
    calibFileName=char(calibFileName);
    
    %Defining loading area
    prompt = {'Enter loading area width (mm):','Enter loading area length (mm):'};
    dimensions = str2double(inputdlg(prompt,'Input',1,{'40','40'}));
    loadArea = dimensions(1)*dimensions(2)*1e-6;
    
    %Importing calibration data and inserting in a 3dimensional array. The
    %first dimension are the rows of the sensor, the second are the columns and
    %the third are for the different loading levels
    for i=1:size(calibFileName,1)
        text = fileread(strtrim([calibPathName calibFileName(i,:)]));
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
        if exist('index','var')==0; index.(sensitivity)=0; end
        if isfield(index,sensitivity)==0; index.(sensitivity)=0; end
            index.(sensitivity)=index.(sensitivity)+1;

            %Averaging the data for the whole measurement duration 
            meanData.(sensitivity)(index.(sensitivity),1)=mean(mean(data,2));
            loads.(sensitivity)(index.(sensitivity),1)=str2double(calibFileName(i,1:length(regexp(calibFileName(i,:),'\d'))))/loadArea;
    end

    waitbar(0,h,'Calculating calibration coefficients');

    lsqopts = optimset('Display','off','MaxFunEvals',100000,'MaxIter',100000);
    prog=0;
    t=0:1:255;
    figure(1)
    hold on
    
    for sens = fieldnames(index)'
        sensit=sens{1};
        
        % Sorting the two arrays for Linux mode compatability.
        loads.(sensit)=sort(loads.(sensit));
        meanData.(sensit)=sort(meanData.(sensit));
        
        lb=[-Inf,-Inf,-Inf,-Inf,-100];
        ub=[Inf,Inf,Inf,Inf,100];
        xo=[5,5,5,5,5,0];
        coeffs = lsqcurvefit(@cubFitFun,xo,[0;meanData.(sensit)],[0;loads.(sensit)],lb,ub,lsqopts)';
        x.(sensit).a=coeffs(1);	x.(sensit).b=coeffs(2);	x.(sensit).c=coeffs(3);	x.(sensit).d=coeffs(4); x.(sensit).e=coeffs(5);	x.(sensit).f=coeffs(6);
        
        problem = createOptimProblem('lsqcurvefit','x0',xo,'objective',cubFitFun,'lb',lb,'ul',ul,'xdata',[0;meanData.(sensit)],'ydata',[0;loads.(sensit)]);
        ms = MultiStart('PlotFcns',@gsplotbestf);
        [xmulti,errormulti] = run(ms,problem,50);
        
        % Plotting for confirming least squares convergence
        plot([meanData.(sensit)],[loads.(sensit)],'b');
        ycub=x.(sensit).a*t.^5+x.(sensit).b*t.^4+x.(sensit).c*t.^3+x.(sensit).d*t.^2+x.(sensit).e*t+x.(sensit).f;
        plot(t,ycub,'r','LineWidth',2);
        prog=prog+1;
        waitbar(prog/6,h,'Calculating calibration coefficients');
    end
    
    save([measPathName 'calibration.mat'], 'x');
end

for i=1:size(measFileName,1)
    text = fileread(strtrim([measPathName measFileName(i,:)]));
    endFrame=str2double(regexp(text,'(?<=END_FRAME )\d*','match'));
    startFrame=str2double(regexp(text,'(?<=START_FRAME )\d*','match'));

    % Read sensitivity in order to use the proper calibration sheet
    sensitivity = regexp(text,'(?<=SENSITIVITY )\S*','match');
    sensitivity = strrep(sensitivity{1},'-','');
    calibratedData=zeros(endFrame,nrows,ncols);
       
    for j=startFrame:endFrame
        waitbar(((i-1)*endFrame+j)/(endFrame*size(measFileName,1)),h,'Generating calibrated measurements');
        
        %Reading the data from the correct frame
        rawData=regexp(text,['(?<=Frame ' num2str(j) '\r\n)((\d*,\d*)*\r\n)*'],'match');
        cellData=textscan(rawData{1},'%f','Delimiter',',');
        data=reshape(cellData{1},ncols,nrows)';
        calibratedData(j,:,:)=x.(sensitivity).a*data(:,:).^5+x.(sensitivity).b*data(:,:).^4+x.(sensitivity).c*data(:,:).^3+x.(sensitivity).d*data(:,:).^2+x.(sensitivity).e*data(:,:)+x.(sensitivity).f;
    end
    fileName=strtrim(measFileName(i,:));
    save([measPathName 'Calibrated_' fileName(1:end-4) '.mat'],'calibratedData');
end

close(h);
end