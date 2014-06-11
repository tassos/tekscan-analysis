function pressureArea =...
    plotPeakAreaTalus (data, rows, cols, measPathName, legendNames, threshold, rowSpacing, colSpacing)

    k=0;
    for i=1:size(data,2)
        [point1, point2] = plotKinematics (measPathName, legendNames{i}, threshold);
        
        if ~(size(point1,1)==1||size(point2,1)==1)
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
            for p=1:length(point1)
                for j=1:2
                    slope=(point2(p,1)-point1(p,1))/(point2(p,2)-point1(p,2));
                    x(p,j)=(ylim(j)-point1(p,1))/slope+point1(p,2);
                    y(p,j)=ylim(j);
                    y(p,j+2)=-(1/slope)*(xlim(j)-point1(p,2))+point1(p,1);
                    x(p,j+2)=xlim(j);
                    y(p,j+4)=-(1/slope)*(xlim(j)-point2(p,2))+point2(p,1);
                    x(p,j+4)=xlim(j);
                end
            end
            %Defining points at the corners of the sensor, to make sure that all
            %the sensing area inside the polygon is selected.
            clear poix poiy
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
            
            k=k+1;
            for j=1:size(data,3)
                for region=1:size(regions,1)
                    points = inpolygon(X,Y,poix(j,regions(region,:)),poiy(j,regions(region,:)));
                    if isempty(max(data(1,i,j,points))); 
                        pressureArea(k,j,region) = 0;
                    else
                        pressureArea(k,j,region) = max(data(1,i,j,points));
                    end
                end
            end       
        end
    end
end