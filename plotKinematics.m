function plotKinematics (h, measPathName, fileNames)

    % Defining the root path for the foot
    voetPath=[measPathName '../'];
    fileList = dir([voetPath 'Results/*.mat']);

    % Finding the measurement files that correspond to the tekscan
    % measurements that are being analysed. Then saving the kinematics of
    % the ankle in an array and saving which tekscan measurements have
    % corresponding kinematics measurements.
    incr = 0;
    filesIndex=[];
    for i=1:size(fileNames,2)
        string = [strrep(fileNames{i},' ','_'),'.mat'];
        index = findFile(string,fileList);
        if index~=0
            filesIndex = [filesIndex i];
            load([voetPath,'Results/',fileList(index).name],'datamatrixtosave');
            kinematicsData(size(filesIndex,2),:,:) = datamatrixtosave(3:end,38:40);            
        end
    end
    
    if size(filesIndex,2) == 0
        % If no corresponding kinematics measurements are found, display a
        % warning message
        warndlg('No kinematics measurements were found for the corresponding TekScan files','!! Warning !!')
    else    
        % Load the needed data from kinematics analysis
        load([voetPath 'Foot details.mat'],'footnumber');
        load([voetPath 'RefPosition - tekscan.mat']);
        load([voetPath,'SpecimenData/AxisTransfoStlToBone_',footnumber,' - 1 - Stl to Bone - Bone with pins']);
        
        % Load the STL files of the two bones
        toLoadTib = [voetPath,'SpecimenData/KADAVERVOET ',footnumber(5:6),'B - tekscan - Tibia.stl'];
        toLoadTal = [voetPath,'SpecimenData/KADAVERVOET ',footnumber(5:6),'B - tekscan - Talus.stl'];
        [F_Tib, V_Tib] = STL_ReadFile(toLoadTib, 1, 'Select TIBIA stl-file', Inf, 0, 1);
        [F_Tal, V_Tal] = STL_ReadFile(toLoadTal, 1, 'Select TALUS stl-file', Inf, 0, 1);

        % Determine rotation in the 3 axes based on the kinematics measurements
        M = transfoMatrix(kinematicsData(1,1,1),kinematicsData(1,1,2),kinematicsData(1,1,3));

        % Apply rotation on the mesh of the tibia bone (needs to be
        % improved, doesn't take into account the reference angles)
        V_Tib_New = (TransfoMatrixStlBone_Tib*V_Tib.'+TranslationMatrixStlBone_Tib*ones(1,size(V_Tib,1)))';
        V_Tib_New2 = (M*V_Tib_New'-TranslationMatrixStlBone_Tib*ones(1,size(V_Tib,1)))'*TransfoMatrixStlBone_Tib;

        % Draw the bones
        figure
        g = axes;
        GUI_PlotShells(g, F_Tib, V_Tib_New2, [], 0, [], 0, 0);
        GUI_PlotShells(g, F_Tal, V_Tal, [], 0, [], 0, 0);

        % Listen to changes on the button of the 3dErrorBar plot and change
        % the joint rotation to that of the corresponding time point
        addlistener(h,'ContinuousValueChange',@(hObject, event) rePlotBones(hObject,g,kinematicsData,...
            V_Tib,V_Tal,F_Tib,F_Tal,TransfoMatrixStlBone_Tib,TranslationMatrixStlBone_Tib));
    end
end

function rePlotBones(hObject,g,rotations,V_Tib,V_Tal,F_Tib,F_Tal,TransfoMatrixStlBone_Tib,TranslationMatrixStlBone_Tib)
    n = floor(get(hObject,'Value')*99+1);
    M = transfoMatrix(rotations(1,n,1),rotations(1,n,2),rotations(1,n,3));
    V_Tib_New = (TransfoMatrixStlBone_Tib*V_Tib.'+TranslationMatrixStlBone_Tib*ones(1,size(V_Tib,1)))';
    V_Tib_New2 = (M*V_Tib_New'-TranslationMatrixStlBone_Tib*ones(1,size(V_Tib,1)))'*TransfoMatrixStlBone_Tib;
    
    cla(g,'reset')
    GUI_PlotShells(g, F_Tib, V_Tib_New2, [], 0, [], 0, 0);
    GUI_PlotShells(g, F_Tal, V_Tal, [], 0, [], 0, 0);
end