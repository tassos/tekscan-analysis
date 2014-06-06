function [dist1, dist2] = plotKinematics (h, measPathName, fileNames, threshold, toPlot)

    % Defining the root path for the foot
    voetPath=[measPathName '../'];
    fileList = dir([voetPath 'Results/*.mat']);

    % Finding the measurement files that correspond to the tekscan
    % measurements that are being analysed. Then saving the kinematics of
    % the ankle in an array and saving which tekscan measurements have
    % corresponding kinematics measurements.
    filesIndex=[];
    for i=1:size(fileNames,2)
        string = regexprep(fileNames{i},'(foot\d* )','Acquisition@position3D@');
        string = strrep(string,' ','_');
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
        [dist1, dist2] = plotAnkle3D(h,voetPath,kinematicsData, threshold, toPlot);
        
        if strcmp(toPlot,'Yes')
            coleurMeas=hsv(size(kinematicsData,1));
            coleurStat={[0.9,0.9,1],'b'};

            figure('Name','Ankle angular kinematics over stance phase')
            ylabels={'IV(-)/EV(+)°','IR(-)/ER(+)°','DF(-)/PF(+)°'};
            for i=1:3
                subplot(3,1,i)
                plot3dConfInter(kinematicsData,coleurMeas,coleurStat,i);
                ylabel(ylabels{i});
                grid on
            end
            xlabel('Stance Phase(%)')
            legend([{'Std'} fileNames(filesIndex) {'Mean'}])
        end
    end
end

