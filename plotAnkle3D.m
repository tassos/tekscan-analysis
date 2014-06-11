function [dist1, dist2] = plotAnkle3D(voetPath, rotations, threshold)
    % Load the needed data from kinematics analysis
    load([voetPath 'Foot details.mat'],'footnumber');
    load([voetPath 'RefPosition - tekscan.mat']);
    load([voetPath,'SpecimenData/AxisTransfoStlToBone_',footnumber,' - 1 - Stl to Bone - Bone with pins'],...
        'TransfoMatrixStlBone_Tib','TranslationMatrixStlBone_Tib');

    % Load the STL files of the two bones
    toLoadTib = [voetPath,'SpecimenData/KADAVERVOET ',footnumber(5:6),'B - tekscan - Tibia.stl'];
    [F_Tib, V_Tib] = STL_ReadFile(toLoadTib, 1, 'Select TIBIA stl-file', Inf, 0, 1);
    [~,~,~,screw] = extractLandmarksFromXML([voetPath,'SpecimenData'],'Tibia','Tekscan');
    [~,~,~,surfTal] = extractLandmarksFromXML([voetPath,'SpecimenData'],'Talus','Tekscan');
    
    % Determine rotation in the 3 axes based on the kinematics measurements
    M = transfoMatrix(rotations(1,1),rotations(1,2),rotations(1,3));

    % Apply rotation on the mesh of the tibia bone (needs to be
    % improved, doesn't take into account the reference angles)
    V_Tib_New = (TransfoMatrixStlBone_Tib*V_Tib.'+TranslationMatrixStlBone_Tib*ones(1,size(V_Tib,1)))';
    V_Tib_New = (M*V_Tib_New'-TranslationMatrixStlBone_Tib*ones(1,size(V_Tib,1)))'*TransfoMatrixStlBone_Tib;
    
    % Cut the bone on that plane
    V_Tib_Cut = TRI_IntersectWithPlane(F_Tib, V_Tib_New, screw);
    
    dist1=0;
    dist2=0;
    
    % Checking if the program is able to calculate the position of the
    % sensor. If not (probably due to bad kinematics data) then set the
    % distances of the points to zero (it will work but it will take the
    % areas on the talus the same as on the tibia).
    if ~isempty(V_Tib_Cut)
        dist1=zeros(length(rotations),2);
        dist2=zeros(length(rotations),2);
        dist=sqrt(sum((screw(1,:)-screw(3,:)).^2));

        sPoint=screw(1,:);
        Distance=0;
        while Distance<=threshold(2)
            [sIndex, sDist] = dsearchn(V_Tib_Cut,sPoint);
            sPoint = V_Tib_Cut(sIndex,:);
            V_Tib_Cut(sIndex,:)=[];
            if (sqrt(sum((screw(3,:)-sPoint).^2))>dist||Distance>5)
                Distance=Distance+sDist;
            else
                sPoint=screw(1,:);
            end
            if (Distance>=threshold(1)&&~exist('POI_Tib','var'))
                POI_Tib(1,:)=sPoint;
            end
        end
        POI_Tib(2,:)=sPoint;

        % Calculate projection of Points of Interest on the Talus and then
        % find the indeces of the Tibial verteces closer to those ones.
        % POI_Tal=V_Tal(dsearchn(V_Tal,POI_Tib),:);
        POI_Tal=surfTal;
        Ind=dsearchn(V_Tib_New,POI_Tib);

        for i=1:length(rotations)
            M = transfoMatrix(rotations(i,1),rotations(i,2),rotations(i,3));
            V_Tib_New = (TransfoMatrixStlBone_Tib*V_Tib.'+TranslationMatrixStlBone_Tib*ones(1,size(V_Tib,1)))';
            V_Tib_New = (M*V_Tib_New'-TranslationMatrixStlBone_Tib*ones(1,size(V_Tib,1)))'*TransfoMatrixStlBone_Tib;
            Proj_Tib = V_Tib_New(dsearchn(V_Tib_New,POI_Tal),:);
            [dist1(i,:), dist2(i,:)] = DistanceFromVertexToVertex(V_Tib_New(Ind,:),Proj_Tib,screw(3,:));
        end
    end
end