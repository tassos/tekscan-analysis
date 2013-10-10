function plotKinematics (h, measPathName, fileNames)

    % Defining the root path for the foot
    voetPath=[measPathName '../'];
    fileList = dir([voetPath 'Results/*.mat']);

    % Finding the measurement files that correspond to the tekscan
    % measurements that are being analysed. Then saving the kinematics of
    % the ankle in an array and saving which tekscan measurements have
    % corresponding kinematics measurements.
    filesIndex=[];
    for i=1:size(fileNames,2)
        string = [strrep(fileNames{i},' ','_'),'.mat'];
        index = findFile(string,fileList);
        if index~=0
            filesIndex = [filesIndex i]; %#ok<AGROW> No way I can predict the length of this array
            load([voetPath,'Results/',fileList(index).name],'datamatrixtosave');
            kinematicsData(size(filesIndex,2),:,:) = datamatrixtosave(3:102,38:40); %#ok<AGROW> No way I can predict the length of this array
        end
    end
    
    if size(filesIndex,2) == 0
        % If no corresponding kinematics measurements are found, display a
        % warning message
        warndlg('No kinematics measurements were found for the corresponding TekScan files','!! Warning !!')
    else    
        plotAnkle3D(h,voetPath,kinematicsData)
        
        coleurMeas=hsv(size(kinematicsData,1));
        coleurStat={[0.9,0.9,1],'b'};
        
        figure
        for i=1:3
            subplot(3,1,i)
            plot3dConfInter(kinematicsData,coleurMeas,coleurStat,i)
        end
        xlabel('Stance Phase(%)')
        title('Ankle rotation in three directions (I/E,IR/ER,PF/DF)')
        legend([{'Std'} fileNames(filesIndex) {'Mean'}])
    end
end

