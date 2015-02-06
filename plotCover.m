function plotCover

    voetPath = 'C:\Users\u0074517\Documents\PhD\Foot-ankle project\Measurements\Voet 4D\';
    bones={'TibiaFibula','Talus','Calcaneus','Cuboid','Navicular','Lateral_Cuneiform',...
        'Medium_Cuneiform','Medial_Cuneiform','MT1','MT2','MT3','MT4','MT5','Phalanx1',...
        'Phalanx2','Phalanx3','Phalanges4-5','Unknown','Sesamoid1','Sesamoid2'};
    
    F=cell(length(bones));
    V=cell(length(bones));
    col=cell(length(bones));
    for i=1:length(bones)
       [F{i}, V{i}] = STL_ReadFile([voetPath,'SpecimenData\',bones{i},'.stl'], 1, 'Select stl-file', Inf, 0, 1);
       col{i}=[0.8 0.8 0.8];
    end
    
    [~,~,~,screwTal] = extractLandmarksFromXML([voetPath,'/SpecimenData'],'Talus','Tekscan');
    [~,~,~,screwTib] = extractLandmarksFromXML([voetPath,'/SpecimenData'],'Tibia','Tekscan');    

    Proj_Tib=V{1}(dsearchn(V{1},screwTib),:);
    Proj_Tal=V{2}(dsearchn(V{2},screwTal),:);
    
    load([voetPath,'Tekscan\Calibrated_foot45_Tekscan_3.mat'],'calibratedData','spacing','fileName');

    colSpacing=spacing{1}/1e3; %#ok<USENS> The variable is loaded two lines above
    rowSpacing=spacing{2}/1e3;
    data(:,:,:) = smooth3(squeeze(calibratedData(:,:,:))); %#ok<NODEF> The variable is loaded four lines above
          
    col{2} = plotPressureGradient(Proj_Tal, Proj_Tib, V{2}, squeeze(data(70,:,:)), rowSpacing, colSpacing);
    
    GUI_PlotShells(gca,F(2:end),V(2:end),col(2:end));
    
    hold on
    patch('Parent', gca, ...
        'Vertices', V{1}, 'Faces', F{1}, ...
        'FaceAlpha', 0.4,...
        'EdgeColor', 'none',...
        'FaceColor', [0.8 0.8 0.8]);
    view(60,50);
end