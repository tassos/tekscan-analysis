function plotKinematics (measPathName, fileNames)

    measurPath=[measPathName '../Results'];
    fileList = dir([measurPath '/*.mat']);

    for i=1:size(fileNames,2)
        string = [strrep(fileNames{i},' ','_'),'.mat'];
        index = findFile(string,fileList);
        if index~=0
            load([measurPath,'/',fileList(index).name]);
        end
    end

end