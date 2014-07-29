function [dist1, dist2] = projectKinematics (voetPath, ~)

    % Load the needed data from kinematics analysis
    load([voetPath '/Foot details.mat'],'footnumber','foottype');
    load([voetPath '/RefPosition - tekscan.mat']);
    load([voetPath,'/SpecimenData/AxisTransfoStlToBone_',footnumber,' - 1 - Stl to Bone - Bone with pins'],...
        'TransfoMatrixStlBone_Tal','TranslationMatrixStlBone_Tal','TransfoMatrixStlBone_Tib','TranslationMatrixStlBone_Tib');
    
    % Finding the measurement files that correspond to the foot
    % that is being analysed. Then saving the kinematics of
    % the ankle in an array and projecting the points of intrest
    % from the talus to the tibia.
    load([OSDetection,'/Voet 99/Results/mean_Data_Tekscan_',footnumber(end-1:end),'.mat'],'datamatrixtosave'); %#ok<COLND>
    load([voetPath,'/RefPosition - tekscan.mat'],'RefAngles','RefTrans');
    rotTal(:,:) = datamatrixtosave(:,38:40)+repmat(RefAngles(1:3),size(datamatrixtosave,1),1);  %#ok<*NODEF> It is loaded on the line above
    trans(:,:) = datamatrixtosave(:,68:70)+repmat(RefTrans(1:3),size(rotTal,1),1);

    if strcmp(foottype,'RIGHT')
        rotTal(:,1:2)=-rotTal(:,1:2);
    end

    % Load the STL files of the two bones
    toLoadTib = [voetPath,'/SpecimenData/KADAVERVOET ',footnumber(5:6),'B - tekscan - Tibia.stl'];
    toLoadTal = [voetPath,'/SpecimenData/KADAVERVOET ',footnumber(5:6),'B - tekscan - Talus.stl'];
    [F_Tib, V_Tib] = STL_ReadFile(toLoadTib, 1, 'Select TIBIA stl-file', Inf, 0, 1);
    [F_Tal, V_Tal] = STL_ReadFile(toLoadTal, 1, 'Select TALUS stl-file', Inf, 0, 1);
    [~,~,~,screw] = extractLandmarksFromXML([voetPath,'/SpecimenData'],'Tibia','Tekscan');
    [~,~,~,surfTal] = extractLandmarksFromXML([voetPath,'/SpecimenData'],'Talus','Tekscan');

    % Determine rotation in the 3 axes based on the kinematics measurements
    M = transfoMatrix(rotTal(1,:));

    % Apply rotation on the mesh of the tibia bone
    V_Tal_Home = V_Tal*TransfoMatrixStlBone_Tal.'+repmat(TranslationMatrixStlBone_Tal',size(V_Tal,1),1);
    V_Tal_New = V_Tal_Home*M'+repmat(trans(1,:),size(V_Tal_Home,1),1);
    V_Tib = V_Tib*TransfoMatrixStlBone_Tib'+repmat(TranslationMatrixStlBone_Tib',size(V_Tib,1),1);
    POI_Tib = screw(1:2,:)*TransfoMatrixStlBone_Tib'+repmat(TranslationMatrixStlBone_Tib',2,1);

    % Cut the bone on that plane
%     V_Tib_Cut = TRI_IntersectWithPlane(F_Tib, V_Tib_New, screw);

    dist1=zeros(length(rotTal),2);
    dist2=zeros(length(rotTal),2);
% 
%     % Checking if the program is able to calculate the position of the
%     % sensor. If not (probably due to bad kinematics data) then set the
%     % distances of the points to zero (it will work but it will take the
%     % areas on the talus the same as on the tibia).
%     if ~isempty(V_Tib_Cut)
%         dist1=zeros(length(rotations),2);
%         dist2=zeros(length(rotations),2);
%         dist=sqrt(sum((screw(1,:)-screw(3,:)).^2));
% 
%         sPoint=screw(1,:);
%         Distance=0;
%         while Distance<=threshold(2)
%             [sIndex, sDist] = dsearchn(V_Tib_Cut,sPoint);
%             sPoint = V_Tib_Cut(sIndex,:);
%             V_Tib_Cut(sIndex,:)=[];
%             if (sqrt(sum((screw(3,:)-sPoint).^2))>dist||Distance>5)
%                 Distance=Distance+sDist;
%             else
%                 sPoint=screw(1,:);
%             end
%             if (Distance>=threshold(1)&&~exist('POI_Tib','var'))
%                 POI_Tib(1,:)=sPoint;
%             end
%         end
%         POI_Tib(2,:)=sPoint;

        % Calculate projection of Points of Interest on the Talus and then
        % find the indeces of the Tibial verteces closer to those ones.
        % POI_Tal=V_Tal(dsearchn(V_Tal,POI_Tib),:);
        POI_Tal=surfTal;
        Ind=dsearchn(V_Tal,POI_Tal);
        
        videoObj = VideoWriter([voetPath,'/Tekscan/BoneKinematics.mp4'],'MPEG-4');
        open(videoObj);
        figure(1);
        set(gcf, 'Units', 'pixels', 'Position', [10, 10, 650, 850]);
        set(gca, 'Units', 'pixels', 'Position', [10, 10, 600, 800]);
        for i=1:length(rotTal)
            M = transfoMatrix(rotTal(i,:));
            V_Tal_New = V_Tal_Home*M'+repmat(trans(i,:),size(V_Tal_Home,1),1);
            Proj_Tal = V_Tal_New(dsearchn(V_Tal_New,POI_Tib),:);
            [dist1(i,:), dist2(i,:)] = DistanceFromVertexToVertex(V_Tal_New(Ind,:),Proj_Tal,screw(3,:));
            cla; GUI_PlotShells(gca,F_Tib,V_Tib,'red'); GUI_PlotShells(gca,F_Tal,V_Tal_New,'yellow');
            view(0,90);
            text(max(xlim)-5,max(ylim)-10,max(zlim)+5,num2str(i),'FontWeight','bold','BackgroundColor',[.7 .9 .7])
            frame = getframe(gca,[0,0,600,800]);
            writeVideo(videoObj,frame);
        end
        close(videoObj);
        close gcf;
%     end
end