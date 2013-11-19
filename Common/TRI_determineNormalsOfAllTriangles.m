function N=TRI_determineNormalsOfAllTriangles(EEN,TRI)
%fg20050609
%written for: CalculateThickness.m
%
%%wb20051116
%   Syntax:
%    normals = TRI_DetermineNormalsOfAllTriangles(EEN, TRI)
%
%   Input:
%    EEN: N-by-3 array containing vertex coordinates. Each row
%         represents a vertex; the first, second and third columns
%         represent X-, Y- and Z-coordinates respectively.
%    TRI: N-by-3 array containing indices into EEN. Each row represents a
%         triangle, each element is a link to a vertex in EEN.
%
%   Output:
%    normals: N-by-3 array containing normal vectors. Each row represents a
%             normal vector and corresponds to a row in TRI; the first,
%             second and third columns contain X-, Y- and Z-coordinates
%             respectively.
%
%   Effect: This function calculates the normal vectors of each triangle.
%           The normal vector directions are chosen according to the
%           sequence in which indices into EEN appear in TRI. All normal
%           vectors have length equal to 1.
%
%   Dependencies: none.
%
%   Known parents: TRI_FlipNormalsToConvex.m
%                  TRI_DistanceFromVertexToPlane.m
%                  TRI_DetermineTriangleConnections.m



p2minp1 = EEN(TRI(:,2),1:3)-EEN(TRI(:,1),1:3);
p3minp1 = EEN(TRI(:,3),1:3)-EEN(TRI(:,1),1:3);
N       = cross(p2minp1, p3minp1, 2); %vectorieel product %wb20050223: added argument to function call (dimension 2) 
deler   = sqrt(N(:,1).^2+N(:,2).^2+N(:,3).^2);%normeren
N       = N./[deler,deler,deler];




%begin
%ALTERNATIVE CODE by wb:
% % %Vertex coordinates for each triangle corner point
% % EEN1 = EEN(TRI(:,1),:);
% % EEN2 = EEN(TRI(:,2),:);
% % EEN3 = EEN(TRI(:,3),:);
% %
% % %Calculate normals
% % normals = cross(EEN2-EEN1, EEN3-EEN2, 2);
% %
% % %Normalise normals
% % normals = normals./repmat(sqrt(sum(normals.^2, 2)), 1, 3);
%einde
