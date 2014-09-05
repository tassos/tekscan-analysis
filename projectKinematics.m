function [dist1, dist2] = projectKinematics (voetPath, threshold)

    % Load the needed data from kinematics analysis
    load([voetPath '/Foot details.mat'],'footnumber','foottype');
    load([voetPath '/RefPosition - tekscan.mat']);
    load([voetPath,'/SpecimenData/AxisTransfoStlToBone_',footnumber,' - 1 - Stl to Bone - Bone with pins'],...
        'TransfoMatrixStlBone_Tal','TranslationMatrixStlBone_Tal','TransfoMatrixStlBone_Tib','TranslationMatrixStlBone_Tib');
    
    % Finding the measurement files that correspond to the foot
    % that is being analysed. Then saving the kinematics of
    % the ankle in two arrays.
    load([OSDetection,'/Voet 99/Results/mean_Data_Tekscan_',footnumber(end-1:end),'.mat'],'datamatrixtosave'); %#ok<COLND>
    load([voetPath,'/RefPosition - tekscan.mat'],'RefAngles','RefTrans');
    rotTal(:,:) = datamatrixtosave(:,38:40)+repmat(RefAngles(1:3),size(datamatrixtosave,1),1);  %#ok<*NODEF> It is loaded on the line above
    trans(:,:) = datamatrixtosave(:,68:70)+repmat(RefTrans(1:3),size(rotTal,1),1);

    % Change direction of rotation for the inversion/eversion and
    % external/internal rotation for right feet.
    if strcmp(foottype,'RIGHT')
        rotTal(:,1:2)=-rotTal(:,1:2);
    end

    % Load the STL files and the landmarks of the two bones
    toLoadTib = [voetPath,'/SpecimenData/KADAVERVOET ',footnumber(5:6),'B - tekscan - Tibia.stl'];
    toLoadTal = [voetPath,'/SpecimenData/KADAVERVOET ',footnumber(5:6),'B - tekscan - Talus.stl'];
    [F_Tib, V_Tib] = STL_ReadFile(toLoadTib, 1, 'Select TIBIA stl-file', Inf, 0, 1);
    [F_Tal, V_Tal] = STL_ReadFile(toLoadTal, 1, 'Select TALUS stl-file', Inf, 0, 1);
    [~,~,~,screw] = extractLandmarksFromXML([voetPath,'/SpecimenData'],'Tibia','Tekscan');

    % Apply rotation on the mesh of the tibia and talus bone so that they
    % go to [0,0,0] position and align their Anatomical coordinate frame
    % with the Global one.
    V_Tal_Home = V_Tal*TransfoMatrixStlBone_Tal.'+repmat(TranslationMatrixStlBone_Tal',size(V_Tal,1),1);
    V_Tib_Home = V_Tib*TransfoMatrixStlBone_Tib'+repmat(TranslationMatrixStlBone_Tib',size(V_Tib,1),1);
    V_Tal_Neut = V_Tal_Home*transfoMatrix(RefAngles(1:3))'+repmat(RefTrans(1:3),size(V_Tal_Home,1),1);

    dist1=zeros(length(rotTal),2);
    dist2=zeros(length(rotTal),2);

    % Defining distance from top of the bone till screw insertion,
    % to be used for detecting the direction of the bone
    dist=sqrt(sum((screw(1,:)-screw(3,:)).^2));

    % Cutting the bone on the sagittal plane and finding the two points
    % coinciding with the location of the central points of the pressure
    % grid
    V_Tib_Cut = TRI_IntersectWithPlane(F_Tib, V_Tib, screw);
    sPoint=screw(1,:);
    Distance=0;
    while Distance<=threshold(2)
        [sIndex, sDist] = dsearchn(V_Tib_Cut,sPoint);
        sPoint = V_Tib_Cut(sIndex,:);
        V_Tib_Cut(sIndex,:)=[];
        if (sqrt(sum((sPoint-screw(3,:)).^2))>dist||Distance>5)
            Distance=Distance+sDist;
        else
            sPoint=screw(1,:);
        end
        if (Distance>=threshold(1)&&~exist('POI_Tib','var'))
            POI_Tib(1,:)=sPoint;
        end
    end
    POI_Tib(2,:)=sPoint;

    % Find the indeces of the Tibial and Talus verteces closer to the landmarks.
    IndTib=dsearchn(V_Tib,POI_Tib);
    IndTal=dsearchn(V_Tal_Neut,V_Tib_Home(IndTib,:));

    % Open Video file and prepare axis for its frames.
    videoObj = VideoWriter([voetPath,'/Tekscan/BoneKinematics.mp4'],'MPEG-4');
    open(videoObj);
    figure(1);
    set(gcf, 'Units', 'pixels', 'Position', [10, 10, 650, 850]);
    set(gca, 'Units', 'pixels', 'Position', [10, 10, 600, 800]);
    for i=1:length(rotTal)
        % Rotate and translate Talus bone
        M = transfoMatrix(rotTal(i,:));
        V_Tal_New = V_Tal_Home*M'+repmat(trans(i,:),size(V_Tal_Home,1),1);

        % Project the Tibia landmarks on the Talus and find the coordinates
        % of the projection. Then define the distances between the landmarks
        % and the projections
        Proj_Tal = V_Tal_New(dsearchn(V_Tal_New,V_Tib_Home(IndTib,:)));
        [dist1(i,:), dist2(i,:)] = DistanceFromVertexToVertex(V_Tal_New(IndTal,:),Proj_Tal,screw(3,:));

        % Draw the new joint configuration on the figure and write a frame
        % in the video file.
        cla; GUI_PlotShells(gca,F_Tib,V_Tib_Home,'red'); GUI_PlotShells(gca,F_Tal,V_Tal_New,'yellow');
        view(0,90);
        text(max(xlim)-5,max(ylim)-10,max(zlim)+5,num2str(i),'FontWeight','bold','BackgroundColor',[.7 .9 .7])
        frame = getframe(gca,[0,0,600,800]);
        writeVideo(videoObj,frame);
    end
    close(videoObj);
    close gcf;
end