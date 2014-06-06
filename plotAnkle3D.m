function [dist1, dist2] = plotAnkle3D(h, voetPath, rotations, threshold, toPlot)
    % Load the needed data from kinematics analysis
    load([voetPath 'Foot details.mat'],'footnumber');
    load([voetPath 'RefPosition - tekscan.mat']);
    load([voetPath,'SpecimenData/AxisTransfoStlToBone_',footnumber,' - 1 - Stl to Bone - Bone with pins'],...
        'TransfoMatrixStlBone_Tib','TranslationMatrixStlBone_Tib');

    % Load the STL files of the two bones
    toLoadTib = [voetPath,'SpecimenData/KADAVERVOET ',footnumber(5:6),'B - tekscan - Tibia.stl'];
    toLoadTal = [voetPath,'SpecimenData/KADAVERVOET ',footnumber(5:6),'B - tekscan - Talus.stl'];
    [F_Tib, V_Tib] = STL_ReadFile(toLoadTib, 1, 'Select TIBIA stl-file', Inf, 0, 1);
    [F_Tal, V_Tal] = STL_ReadFile(toLoadTal, 1, 'Select TALUS stl-file', Inf, 0, 1);
    [~,~,~, screw] = extractLandmarksFromXML([voetPath,'SpecimenData'],'Tibia','Tekscan');
    
    % Find distance of Sagittal plane from the screw insertion point
%     CoP=TransfoMatrixStlBone_Tib;
%     CoO=TranslationMatrixStlBone_Tib;
%     
%     d = sqrt(sum(CoO.^2))/sqrt(sum(CoP(3,:).^2));
%     D = (sum(screw.*CoP(3,:))+d)/sqrt(sum(CoP(3,:).^2));
%     
%     % Find two more points on the plane passing from the screw insertion
%     % point and being parallel to the Sagittal plane
%     screw(2,:)=-(CoP(3,1)+CoP(3,2)+d+D)/CoP(3,3);
%     screw(3,:)=-(d+D)/CoP(3,3);
    
    % Determine rotation in the 3 axes based on the kinematics measurements
    M = transfoMatrix(rotations(1,1,1),rotations(1,1,2),rotations(1,1,3));

    % Apply rotation on the mesh of the tibia bone (needs to be
    % improved, doesn't take into account the reference angles)
    V_Tib_New = (TransfoMatrixStlBone_Tib*V_Tib.'+TranslationMatrixStlBone_Tib*ones(1,size(V_Tib,1)))';
    V_Tib_New2 = (M*V_Tib_New'-TranslationMatrixStlBone_Tib*ones(1,size(V_Tib,1)))'*TransfoMatrixStlBone_Tib;
    
    % Cut the bone on that plane
    V_Tib_Cut =  TRI_IntersectWithPlane(F_Tib, V_Tib_New2, screw);
    
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
    POI_Tal=V_Tal(dsearchn(V_Tal,POI_Tib),:);
    Ind=dsearchn(V_Tib_New2,POI_Tal);
    
    dist1=zeros(length(rotations),2);
    dist2=zeros(length(rotations),2);
    for i=1:length(rotations)
        M = transfoMatrix(rotations(1,i,1),rotations(1,i,2),rotations(1,i,3));
        V_Tib_New = (TransfoMatrixStlBone_Tib*V_Tib.'+TranslationMatrixStlBone_Tib*ones(1,size(V_Tib,1)))';
        V_Tib_New2 = (M*V_Tib_New'-TranslationMatrixStlBone_Tib*ones(1,size(V_Tib,1)))'*TransfoMatrixStlBone_Tib;
        Proj_Tib = V_Tib_New2(dsearchn(V_Tib_New2,POI_Tal),:);
        [dist1(i,:), dist2(i,:)] = DistanceFromVertexToVertex(V_Tib_New2(Ind,:),Proj_Tib,screw(3,:));
    end

    if strcmp(toPlot,'Yes')
        % Draw the bones
        figure
        g = axes;
        GUI_PlotShells(gca, F_Tib, V_Tib_New2, 'red', 0, [], 0, 0);
        GUI_PlotShells(gca, F_Tal, V_Tal, 'yellow', 0, [], 0, 0);

        % Listen to changes on the button of the 3dErrorBar plot and change
        % the joint rotation to that of the corresponding time point
        addlistener(h,'ContinuousValueChange',@(hObject, event) rePlotBones(hObject,g,rotations,...
            V_Tib,V_Tal,F_Tib,F_Tal,TransfoMatrixStlBone_Tib,TranslationMatrixStlBone_Tib));     
    end
end

function rePlotBones(hObject,g,rotations,V_Tib,V_Tal,F_Tib,F_Tal,TransfoMatrixStlBone_Tib,TranslationMatrixStlBone_Tib)
    n = floor(get(hObject,'Value')*99+1);
    M = transfoMatrix(rotations(1,n,1),rotations(1,n,2),rotations(1,n,3));
    V_Tib_New = (TransfoMatrixStlBone_Tib*V_Tib.'+TranslationMatrixStlBone_Tib*ones(1,size(V_Tib,1)))';
    V_Tib_New2 = (M*V_Tib_New'-TranslationMatrixStlBone_Tib*ones(1,size(V_Tib,1)))'*TransfoMatrixStlBone_Tib;
    
    cla(g,'reset')
    GUI_PlotShells(g, F_Tib, V_Tib_New2, [], 0, [], 0, 0);
    GUI_PlotShells(g, F_Tal, V_Tal, [], 0, [], 0, 0);
end