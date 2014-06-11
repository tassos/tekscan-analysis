function [dist1, dist2] = plotKinematics (measPathName, fileName, threshold)

    % Defining the root path for the foot
    voetPath=[measPathName '../'];
    fileList = dir([voetPath 'Results/*.mat']);

    % Finding the measurement files that correspond to the tekscan
    % measurements that are being analysed. Then saving the kinematics of
    % the ankle in an array and saving which tekscan measurements have
    % corresponding kinematics measurements.
    string = regexprep(fileName,'(foot\d* )','Acquisition@position3D@');
    string = strrep(string,' ','_');
    index = findFile(string,fileList);
    if index~=0
        load([voetPath,'Results/',fileList(index).name],'datamatrixtosave');
        kinematicsData(:,:) = datamatrixtosave(3:102,38:40);
        
        [dist1, dist2] = plotAnkle3D(voetPath, kinematicsData, threshold);
    else
        % If no corresponding kinematics measurements are found, display a
        % warning message
        warndlg(['No kinematics measurements were found for ',fileName,' measurement'],'!! Warning !!')
        dist1=0;
        dist2=0;
    end
end

