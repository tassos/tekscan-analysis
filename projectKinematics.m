function [dist1, dist2] = projectKinematics (measPathName, ~)
  
    voetPath=[measPathName,'../'];

    % Load the needed data from kinematics analysis
    load([voetPath 'Foot details.mat'],'footnumber');
    load([voetPath 'RefPosition - tekscan.mat']);
    load([voetPath,'SpecimenData/AxisTransfoStlToBone_',footnumber,' - 1 - Stl to Bone - Bone with pins'],...
        'TransfoMatrixStlBone_Tal','TranslationMatrixStlBone_Tal');
    
    % Finding the measurement files that correspond to the foot
    % that is being analysed. Then saving the kinematics of
    % the ankle in an array and projecting the points of intrest
    % from the talus to the tibia.
    load([measPathName,'../../Voet 99/Results/mean_Data_Tekscan_',footnumber(end-1:end),'.mat'],'datamatrixtosave'); %#ok<COLND>
    load([voetPath,'RefPosition - tekscan.mat'],'RefAngles','RefTrans');
    RefAngles=repmat(RefAngles(1:3),size(datamatrixtosave,1),1);
    RefTrans=repmat(RefTrans(1:3),size(datamatrixtosave,1),1);
    rotTal(:,:) = datamatrixtosave(:,38:40); %#ok<*NODEF> It is loaded on the line above
    trans(:,:) = -datamatrixtosave(:,68:70);


    % Load the STL files of the two bones
    toLoadTib = [voetPath,'SpecimenData/KADAVERVOET ',footnumber(5:6),'B - tekscan - Tibia.stl'];
    toLoadTal = [voetPath,'SpecimenData/KADAVERVOET ',footnumber(5:6),'B - tekscan - Talus.stl'];
    [F_Tib, V_Tib] = STL_ReadFile(toLoadTib, 1, 'Select TIBIA stl-file', Inf, 0, 1);
    [F_Tal, V_Tal] = STL_ReadFile(toLoadTal, 1, 'Select TALUS stl-file', Inf, 0, 1);
    [~,~,~,screw] = extractLandmarksFromXML([voetPath,'SpecimenData'],'Tibia','Tekscan');
    [~,~,~,surfTal] = extractLandmarksFromXML([voetPath,'SpecimenData'],'Talus','Tekscan');

    % Determine rotation in the 3 axes based on the kinematics measurements
    M = transfoMatrix(rotTal(1,1),rotTal(1,2),rotTal(1,3));

    % Apply rotation on the mesh of the tibia bone (needs to be
    % improved, doesn't take into account the reference angles)
    V_Tal_Home = (TransfoMatrixStlBone_Tal*V_Tal.'+TranslationMatrixStlBone_Tal*ones(1,size(V_Tal,1)))';
    V_Tal_New = (M*V_Tal_Home'+repmat(trans(1,:)',1,size(V_Tal,1))-repmat(TranslationMatrixStlBone_Tal,1,size(V_Tal,1)))'*TransfoMatrixStlBone_Tal;

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
        POI_Tib=screw(1:2,:);
        POI_Tal=surfTal;
        Ind=dsearchn(V_Tal_New,POI_Tal);
        
        videoObj = VideoWriter([voetPath,'Tekscan/BoneKinematics.mp4'],'MPEG-4');
        open(videoObj);
        for i=1:length(rotTal)
            M = transfoMatrix(rotTal(i,1),rotTal(i,2),rotTal(i,3));
            V_Tal_New = (M*V_Tal_Home'+repmat(trans(i,:)',1,size(V_Tal,1))-repmat(TranslationMatrixStlBone_Tal,1,size(V_Tal,1)))'*TransfoMatrixStlBone_Tal;
            Proj_Tal = V_Tal_New(dsearchn(V_Tal_New,POI_Tib),:);
            [dist1(i,:), dist2(i,:)] = DistanceFromVertexToVertex(V_Tal_New(Ind,:),Proj_Tal,screw(3,:));
            cla; GUI_PlotShells(gca,F_Tib,V_Tib,'red'); GUI_PlotShells(gca,F_Tal,V_Tal_New,'yellow');
            view(270,0)
            text(min(xlim)-5,max(ylim)-5,max(zlim)-5,num2str(i),'FontWeight','bold','BackgroundColor',[.7 .9 .7])
            frame = getframe;
            writeVideo(videoObj,frame);
        end
        close(videoObj);
        close gcf;
%     end
end