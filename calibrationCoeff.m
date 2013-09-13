function [x] = calibrationCoeff(h,pathName,meanData,loads, index)
    global xdata ydata
    
    %Getting screen size for calculating the proper position of the figures
    set(0,'Units','pixels') 
    scnsize = get(0,'ScreenSize');
    
    waitbar(0,h,'Calculating calibration coefficients');
    
    %Choose order of polynomial to be used for the fitting curve
    prompt = {'Choose order for the fitted polynomial'};
    order = str2double(inputdlg(prompt,'Input',1,{'3'}));

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
    save([pathName 'calibration.mat'], 'x','error');
end