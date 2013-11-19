function overwriteXLS(measPathName, dataToSave, headers, legendNames)
    [FileName,PathName] = uiputfile([measPathName,'/*.xls'],'Save measurements as...');
    warning('off','MATLAB:xlswrite:AddSheet');
    for j=1:size(dataToSave,3)
        xlswrite([PathName,FileName],headers,legendNames{j});
        xlswrite([PathName,FileName],dataToSave(:,: ,j),legendNames{j},'A2');
    end
    warning('on','MATLAB:xlswrite:AddSheet');
    removeEmptySheets([PathName,FileName]);     
end