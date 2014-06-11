function [rows, cols, rowsPlot, colsPlot, threshold] = areaDivision (x, y, rowDiv, colDiv, rowSpacing)
    rows{rowDiv}=[];
    rowsPlot=rows;
    cols{colDiv}=[];
    colsPlot=cols;
    previous=0;
    rowsTemp = 1:1:max(x(:))-min(x(:))+1;
    for i=1:rowDiv
        rows{i} = (1:ceil(max(rowsTemp(:))/rowDiv)) + previous;
        previous = max([rows{:}]);
        rowsPlot{i} = rows{i} + min(x(:)) -1;
    end
    %This is used to detect the 'point of interest' on the sensor. We
    %multiply by 1000 to convert to mm and we add 10mm, for the distance of
    %the sensing area from the screw.
    threshold=rowSpacing*max(rows{i})/rowDiv.*[1,2]*1000+10;
    rows{rowDiv}(rows{rowDiv}>max(rowsTemp(:)))=[];
    previous=0;
    colsTemp = 1:1:max(y(:))-min(y(:))+1;
    for i=1:colDiv
        cols{i} = (1:ceil(max(colsTemp(:))/colDiv)) + previous;
        previous = max([cols{:}]);
        colsPlot{i} = cols{i} + min(y(:)) -1;
    end
    cols{colDiv}(cols{colDiv}>max(colsTemp(:)))=[];
end