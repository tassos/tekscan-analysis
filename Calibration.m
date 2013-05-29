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

global xdata ydata

%Getting screen size for calculating the proper position of the figures
set(0,'Units','pixels') 
scnsize = get(0,'ScreenSize');

%Read measurements files
[measFileName,measPathName] = uigetfile('.asf','Select measurement files','MultiSelect','on');
measFileName=char(measFileName);

%Define the polynomial that we'll use for fitting our data. The order
%of the polynomial is desided by the size of our x, which is decided by
%the input 'order' that is user defined
function F = FitFun(x)
    resid = polyval(x,xdata) - ydata;
    F = resid.*[2;ones(size(resid,1)-1,1)];
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
if (exist([measPathName 'calibration.mat'],'file')==2);
    load([measPathName 'calibration.mat'],'x');
else

    %Read calibration files
    [calibFileName,calibPathName] = uigetfile('.asf','Select folder containing calibration measurement files','MultiSelect','on');
    calibFileName=char(calibFileName);

    %Defining loading area
    prompt = {'Enter loading area width (mm):','Enter loading area length (mm):'};
    dimensions = str2double(inputdlg(prompt,'Input',1,{'40','40'}));
    loadArea = dimensions(1)*dimensions(2)*1e-6;

    %Choose order of polynomial to be used for the fitting curve
    prompt = {'Choose order for the fitted polynomial'};
    order = str2double(inputdlg(prompt,'Input',1,{'3'}));

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
        %Checking if the index for the sensitivity that is calculated has
        %been created. If not, then it is created.
        if exist('index','var')==0; index.(sensitivity)=0; end
        if isfield(index,sensitivity)==0; index.(sensitivity)=0; end
            index.(sensitivity)=index.(sensitivity)+1;

            %Averaging the data for the whole measurement duration 
            meanData.(sensitivity)(index.(sensitivity),1)=mean(mean(data,2));
            loads.(sensitivity)(index.(sensitivity),1)=str2double(calibFileName(i,1:length(regexp(calibFileName(i,:),'\d'))))/loadArea;
    end

    waitbar(0,h,'Calculating calibration coefficients');

    %Defining a counter for the progress bar
    prog=0;

    %Positioning the figures in a nice array
    pos1 = [0, scnsize(4) * (1/3), scnsize(3)/2, 2*scnsize(4)/3];
    pos2 = [scnsize(3)/2, pos1(2), pos1(3), pos1(4)];
    fig1 =figure(1);
    set(fig1,'OuterPosition',pos1);
    waitBarPos=get(h,'OuterPosition');
    set(h,'OuterPosition',[pos2(1)/2, pos1(2)/3, waitBarPos(3), waitBarPos(4)]);

    for sens = fieldnames(index)'
        sensit=sens{1};

        % Sorting the two arrays for Linux mode compatability.
        loads.(sensit)=sort(loads.(sensit));
        meanData.(sensit)=sort(meanData.(sensit));

        %Defining the range of the the fiting curve
        t0=min(meanData.(sensit)(:)):1:max(meanData.(sensit)(:));

        %Defining upper and lower boundary limits, and also the initial
        %values for the Least-Square fitting
        lb=-Inf(1,order+1);
        ub=Inf(1,order+1);
        xo=ones(1,order+1);

        xdata=[meanData.(sensit)];
        ydata=[loads.(sensit)];

        problem = createOptimProblem('lsqnonlin','x0',xo,'objective',@FitFun,'lb',lb,'ub',ub);%,'xdata',[meanData.(sensit)],'ydata',[loads.(sensit)]);
        ms = MultiStart('PlotFcns',{@gsplotfunccount,@gsplotbestf},'UseParallel','always');
        [x.(sensit),error.(sensit)]=run(ms,problem,50);
        gEval = gcf;
        set(gEval,'OuterPosition',pos2);

        figure(1)
        hold on
        % Plotting for confirming least squares convergence
        scatter([meanData.(sensit)],[loads.(sensit)],'b');
        ycub=double(subs(poly2sym(x.(sensit),'t'),t0));
        plot(t0,ycub,'r','LineWidth',2);

        %Updating progress bar
        prog=prog+1;
        waitbar(prog/6,h,'Calculating calibration coefficients');
        figure(gEval)
    end
    save([measPathName 'calibration.mat'], 'x','error');
end

for i=1:size(measFileName,1)
    text = fileread(strtrim([measPathName measFileName(i,:)]));
    endFrame=str2double(regexp(text,'(?<=END_FRAME )\d*','match'));
    startFrame=str2double(regexp(text,'(?<=START_FRAME )\d*','match'));

    % Read sensitivity in order to use the proper calibration sheet
    sensit = regexp(text,'(?<=SENSITIVITY )\S*','match');
    sensit = strrep(sensit{1},'-','');
    calibratedData=zeros(endFrame,nrows,ncols);

    for j=startFrame:endFrame
        waitbar(((i-1)*endFrame+j)/(endFrame*size(measFileName,1)),h,'Generating calibrated measurements');

        %Reading the data from the correct frame
        rawData=regexp(text,['(?<=Frame ' num2str(j) '\r\n)((\d*,\d*)*\r\n)*'],'match');
        cellData=textscan(rawData{1},'%f','Delimiter',',');
        data=reshape(cellData{1},ncols,nrows)';
        calibratedData(j,:,:)=double(subs(poly2sym(x.(sensit),'t'),data));
    end
    fileName=strtrim(measFileName(i,:));
    save([measPathName 'Calibrated_' fileName(1:end-4) '.mat'],'calibratedData');
end

close(h);
end