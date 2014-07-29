function pressureArea =...
    peakAreaTalus (data, rows, cols, measPathName, legendNames, threshold, rowSpacing, colSpacing)

    k=0;
    % Calculate distance between Tibia and Talus grid points.
    pressureArea=zeros(size(data,2),size(data,3),length(rows)*length(cols));
    [point1, point2] = projectKinematics (measPathName, threshold);

    if ~(size(point1,1)==1||size(point2,1)==1)
        [X,Y] = meshgrid(1:max(cols{end}),1:max(rows{end}));

        load([measPathName '/Foot details.mat'],'foottype');

        if strcmp(foottype,'RIGHT')
            point1(:,2)=-point1(:,2);
            point2(:,2)=-point2(:,2);
        end

        % First dimension is y (rows), second is x (cols)
        m2mm=1000; % Converting m to mm
        point1(:,1)=point1(:,1)/(colSpacing*m2mm)+max(cols{1});
        point1(:,2)=point1(:,2)/(rowSpacing*m2mm)+max(rows{1});
        point2(:,1)=point2(:,1)/(colSpacing*m2mm)+max(cols{1});
        point2(:,2)=point2(:,2)/(rowSpacing*m2mm)+max(rows{1});

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
        % Defining points at the corners of the sensor, to make sure that all
        % the sensing area inside the polygon is selected.
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
        % and one for y coordinate)
        poix=horzcat(poix,[x(:,[1,6,4,2,3,5]),point1(:,2),point2(:,2)]); %#ok<*AGROW> Not true
        poiy=horzcat(poiy,[y(:,[1,6,4,2,3,5]),point1(:,1),point2(:,1)]);

        % Defining the 6 regions by the points of interest
        regions=[11,8,3,4,1,9;
            8,11,7,2,3,4;
            11,9,4,1,10,12;
            11,12,6,2,3,7;
            12,5,2,1,4,10;
            12,6,3,2,1,5];

        % Find the peak pressure in each of the areas for each time
        % point and for each measurement
        for i=1:size(data,2)
            if strfind(legendNames{i},'Tekscan')
                k=k+1;
                for j=1:size(data,3)
                    for region=1:size(regions,1)
                        points = inpolygon(X,Y,poix(j,regions(region,:)),poiy(j,regions(region,:)));
                        if isempty(max(data(1,i,j,points))); 
                            pressureArea(k,:,region) = 0;
                        else
                            pressureArea(k,j,region) = max(data(1,i,j,points));
                        end
                    end
                end       
            end
        end
    end

    if k==0; k=1; end
    pressureArea(k+1:end,:,:)=[];
end