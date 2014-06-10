function pressureArea =...
    plotPeakAreaTalus (data, rows, cols, point1, point2, rowSpacing, colSpacing)
    
    pressureArea=zeros(size(data,2),size(data,3),length(rows)*length(cols));
    
    [X,Y] = meshgrid(1:max(cols{end}),1:max(rows{end}));
    
    % First dimension is y (rows), second is x (cols)
    point1(:,1)=round(point1(:,1)/(colSpacing*1000))+max(cols{1});
    point1(:,2)=round(point1(:,2)/(rowSpacing*1000))+max(rows{1});
    point2(:,1)=round(point2(:,1)/(colSpacing*1000))+max(cols{1});
    point2(:,2)=round(point2(:,2)/(rowSpacing*1000))+max(rows{1});
    
    % Finding the 'contact' points of the area spliting with the borders of
    % the sensor
    xlim=[min(cols{1})-1,max(cols{end})+1];
    ylim=[max(rows{end})+1,min(rows{1})-1];
    for i=1:length(point1)
        for j=1:2
            slope=(point2(i,1)-point1(i,1))/(point2(i,2)-point1(i,2));
            x(i,j)=(ylim(j)-point1(i,1))/slope+point1(i,2);
            y(i,j)=ylim(j);
            y(i,j+2)=-(1/slope)*(xlim(j)-point1(i,2))+point1(i,1);
            x(i,j+2)=xlim(j);
            y(i,j+4)=-(1/slope)*(xlim(j)-point2(i,2))+point2(i,1);
            x(i,j+4)=xlim(j);
        end
    end
    %Defining points at the corners of the sensor, to make sure that all
    %the sensing area inside the polygon is selected.
    poix(1)=min(cols{1})-1;
    poiy(1)=max(rows{end})+1;
    poix(2)=max(cols{end})+1;
    poiy(2)=max(rows{end})+1;
    poix(3)=max(cols{end})+1;
    poiy(3)=min(rows{1})-1;
    poix(4)=min(cols{1})-1;
    poiy(4)=min(rows{1})-1;
    poix=repmat(poix,length(point1),1);
    poiy=repmat(poiy,length(point1),1);
    
    % Gathering all the points of interest (poi) in two arrays (one for x
    % one for y coordinate)
    poix(:,end+1:end+8)=[x(:,1),x(:,6),x(:,4),x(:,2),x(:,3),x(:,5),point1(:,2),point2(:,2)];
    poiy(:,end+1:end+8)=[y(:,1),y(:,6),y(:,4),y(:,2),y(:,3),y(:,5),point1(:,1),point2(:,1)]; 
    
    % Defining the 6 regions by the points of interest
    regions=[11,8,3,4,1,9;
        8,11,7,2,3,4;
        11,9,4,1,10,12;
        11,12,6,2,3,7;
        12,5,2,1,4,10;
        12,6,3,2,1,5];
    
    for i=1:size(data,2)
        for j=1:size(data,3)
            for region=1:size(regions,1)
                points = inpolygon(X,Y,poix(j,regions(region,:)),poiy(j,regions(region,:)));
                pressureArea(i,j,region) = max(data(1,i,j,points));
            end
        end        
    end
end