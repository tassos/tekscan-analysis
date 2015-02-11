function [rows, cols, rowsPlot, colsPlot] = areaDivision (x, y, rowDiv, colDiv)
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