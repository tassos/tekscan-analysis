%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%                       Comparing the different calibrations
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Function: Comparing the results of different calibrations on different
% sensors
%
% Input
% None
%
% Output 
% None
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function calibrationsComparison
    clear
    close all force
    clc

    directories = uipickfiles('FilterSpec',OSDetection);
    if isempty(directories)
        return
    end
    coleur = hsv(size(directories,2));
    
    h=waitbar(0,'Initialising waitbar...');
    
    for z=1:size(directories,2)
        [meanData,loads]=readCalibrationFiles(h,directories{z},1);
        
        % Asking the user which different sensitivities he wants to compare
        if z==1
            sensitivities=fieldnames(meanData);
            g = figure('Position',[300 300 200 500],'Name','Selection');
            parentpanel = uipanel('Units','pixels','Title','Choose sensor','Position',[5 50 180 400]);
            lbs = uicontrol ('Parent',parentpanel,'Style','listbox','Max',8,'String',sensitivities,'Units','Pixels','Position',[5 5 170 300]);
            uicontrol('Style','pushbutton','String','Done','Position',[50 5 100 30],'Callback',@hDoneCallback);
            uiwait
            sensitivities=sensitivities(get(lbs,'Value'));
            close(g)
        end
        for sens=sensitivities'
            scatter([meanData.(sens{1})],[loads.(sens{1})],30,coleur(z,:),'fill');
            hold on
        end
        ylabel('Pressure (Pa)')
        xlabel('Sensel response (0-255)')
    end
    close(h)
end

function hDoneCallback(~, ~)
    uiresume
end