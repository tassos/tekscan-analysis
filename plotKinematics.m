function plotKinematics (measPathName, fileNames)

    voetPath=[measPathName '../'];
    fileList = dir([voetPath 'Results/*.mat']);

    for i=1:size(fileNames,2)
        string = [strrep(fileNames{i},' ','_'),'.mat'];
        index = findFile(string,fileList);
        if index~=0
            load([voetPath,'Results/',fileList(index).name]);
        end
    end
    
    load([voetPath 'Foot details.mat']);
    
    toLoadTib = [voetPath,'SpecimenData/KADAVERVOET ',footnumber(5:6),'B - tekscan - Tibia.stl'];
    toLoadTal = [voetPath,'SpecimenData/KADAVERVOET ',footnumber(5:6),'B - tekscan - Talus.stl'];
    
    [F_Tib, V_Tib] = STL_ReadFile(toLoadTib, 1, 'Select TIBIA stl-file', Inf, 0, 1);
    [F_Tal, V_Tal] = STL_ReadFile(toLoadTal, 1, 'Select TALUS stl-file', Inf, 0, 1);

end