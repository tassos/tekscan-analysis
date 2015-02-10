function initialFolder = OSDetection
%OSDETECTION Detecting the folder with the measurements
    % Find the folder that was selected previous time and use it
    % If it is the first time that the code run, save the folder used
    if exist('initialFolder.mat','file')
        load('initialFolder.mat','initialFolder')
    else
        initialFolder = uigetdir('.','Select folder with measurement data of all feet');
        save('initialFolder.mat','initialFolder')
    end
end