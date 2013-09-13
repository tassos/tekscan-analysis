function [x, meanData, loads] = readCalibrationFiles(h,measPathName)
    global xdata ydata
    
    %Getting screen size for calculating the proper position of the figures
    set(0,'Units','pixels') 
    scnsize = get(0,'ScreenSize');
    
    %Read calibration files
    [calibFileName,calibPathName] = uigetfile('.asf','Select folder containing calibration measurement files',...
        'MultiSelect','on',measPathName);
    calibFileName=char(calibFileName);

    %Defining loading area
    prompt = {'Enter loading area width (mm):','Enter loading area length (mm):'};
    dimensions = str2double(inputdlg(prompt,'Input',1,{'40','40'}));
    loadArea = dimensions(1)*dimensions(2)*1e-6;

    %Choose order of polynomial to be used for the fitting curve
    prompt = {'Choose order for the fitted polynomial'};
    order = str2double(inputdlg(prompt,'Input',1,{'3'}));

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

    waitbar(0,h,'Calculating calibration coefficients');

    %Defining a counter for the progress bar
    prog=0;

    %Positioning the figures in a nice array
    pos1 = [0, scnsize(4) * (1/3), scnsize(3)/2, 2*scnsize(4)/3];
    pos2 = [scnsize(3)/2, pos1(2), pos1(3), pos1(4)];
    fig1 =figure(1);
    set(fig1,'OuterPosition',pos1);
    set(h,'Units','pixels','OuterPosition',[(scnsize(3)-366)/2, (pos1(2)-103)/2, 366, 103]);

    for sens = fieldnames(index)'
        sensit=sens{1};
        waitbar(prog/size(fieldnames(index),1),h,['Calculating calibration coefficients for ',sensit,' sensitivity']);

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

        problem = createOptimProblem('lsqnonlin','x0',xo,'objective',@fitFun,'lb',lb,'ub',ub);
        ms = MultiStart('PlotFcns',{@gsplotfunccount,@gsplotbestf},'UseParallel','always');
        [x.(sensit),error.(sensit)]=run(ms,problem,50);
        gEval = gcf;
        set(gEval,'OuterPosition',pos2);

        figure(1)
        hold on
        % Plotting for confirming least squares convergence
        scatter([meanData.(sensit)],[loads.(sensit)],'b');
        ycub=polyval(x.(sensit),t0);
        plot(t0,ycub,'r','LineWidth',2);

        %Updating progress bar
        prog=prog+1;
        figure(gEval)
    end
    save([measPathName 'calibration.mat'], 'x','error');
end