function [boneCol, plane, direction] = plotPressureGradient(points_tal, points_tib, V, data, rowSpacing, colSpacing)
    [Y,X]=meshgrid(floor(-size(data,2)/2)+1:1:floor(size(data,2)/2),...
            floor(-size(data,1)/2)+1:1:floor(size(data,1)/2));
    [rows,~] = areaDivision (X, Y, 3, 2, rowSpacing);
    X=-X*rowSpacing*1000+5; % Converting to mm, to be in the same unit as the STL
    Y=-Y*colSpacing*1000; % Converting to mm, to be in the same unit as the STL
    midDistance=max(rows{end})/3*rowSpacing*1000; % Defining the physical distance between the two points of the grid
    scale=sqrt(sum(diff(points_tal).^2))/midDistance; % And setting a scale between the actual dimensions and the virtual dimensions of the sensor.
    ap=diff(points_tib([1,2],:));
    dp=diff(points_tib([1,3],:));
    ml=cross(dp,ap);
    dp=cross(ap,ml);
    ap=ap/sqrt(sum(ap.^2));
    dp=dp/sqrt(sum(dp.^2));
    ml=ml/sqrt(sum(ml.^2));
    direction=[-ap;ml;dp];
    X=X*scale;
    Y=Y*scale*1.5;
    plane=[X(:),Y(:),zeros(length(X(:)),1)]*direction;
    plane=plane+repmat([points_tal(1,1),points_tal(1,2),points_tal(1,3)],length(X(:)),1);
    
    normData=data(:)/max(data(:));
    colors=jet(size(unique(normData),1));
    vertices = dsearchn(V,plane);
    boneCol=repmat([0.8 0.8 0.8],length(V),1);
    boneCol(vertices,:)=colors(ceil(normData*(length(colors)-1))+1,:);
end