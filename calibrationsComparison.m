function calibrationsComparison
    initialFolder = 'C:/users/u0074517/Documents/PhD/Foot-ankle project/Measurements';
    directories = uipickfiles('FilterSpec',initialFolder);
    
    h=waitbar(0,'Initialising waitbar...');
    
    for z=1:size(directories,2)
        coleur = hsv(size(directories,2));
        [meanData,loads]=readCalibrationFiles(h,directories{z},1);
        for sens=fieldnames(meanData)'
            sensit = sens{1};
            scatter([meanData.(sensit)],[loads.(sensit)],10,coleur(z,:));
            hold on
        end
    end
    close(h)
end