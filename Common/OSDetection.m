function initialFolder = OSDetection
%OSDETECTION Detecting the machine that I am working on
    % I check if the directory where I usually store my data exists, so
    % that it uses that directory as the default in the dialog, to speed
    % things up
    isWindows = exist('C:/Users/u0074517/Documents/PhD/Foot-ankle project/Measurements','dir');
    isLinux = exist('/media/storage/Storage/PhD/Measurements','dir');
    if isWindows
        initialFolder = 'C:/Users/u0074517/Documents/PhD/Foot-ankle project/Measurements';
    elseif isLinux
        initialFolder = '/media/storage/Storage/PhD/Measurements';
    else
        if exist('initialFolder.mat','file')
            load('initialFolder.mat','initialFolder')
        else
            initialFolder = uigetdir('.','Select folder with measurement data of all feet');
            save('initialFolder.mat','initialFolder')
        end
    end 
end