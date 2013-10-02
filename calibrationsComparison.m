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
    directories = uipickfiles('FilterSpec',OSDetection);
    coleur = hsv(size(directories,2));
    
    h=waitbar(0,'Initialising waitbar...');
    
    for z=1:size(directories,2)
        [meanData,loads]=readCalibrationFiles(h,directories{z},1);
        for sens=fieldnames(meanData)'
            scatter([meanData.(sens{1})],[loads.(sens{1})],10,coleur(z,:));
            hold on
        end
    end
    close(h)
end