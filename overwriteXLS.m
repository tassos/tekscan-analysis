function overwriteXLS(measPathName, dataToSave, headers, legendNames)
%OVERWRITEXLS Create (and overwrite) xls files
    [FileName,PathName] = uiputfile([measPathName,'/*.xls'],'Save measurements as...');
    xlsFile = [PathName,FileName];
    if exist(xlsFile,'file');
        delete(xlsFile)
    end
    warning('off','MATLAB:xlswrite:AddSheet');
    for j=1:size(dataToSave,3)
        xlswrite(xlsFile,headers,legendNames{j});
        xlswrite(xlsFile,dataToSave(:,: ,j),legendNames{j},'A2');
    end
    warning('on','MATLAB:xlswrite:AddSheet');
    removeEmptySheets(xlsFile);
end