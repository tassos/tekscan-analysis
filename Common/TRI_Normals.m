function normals = TRI_Normals(F, V, normalise)
%TRI_Normals  Calculate normal vectors of mesh triangles.
%wb20061206
%
%   Syntax:
%    normals = TRI_Normals(F, V, normalise)
%
%   Input:
%    F:         N-by-3 array containing indices into V. Each row represents
%               a triangle, each element is a link to a vertex in V.
%    V:         N-by-3 array containing vertex coordinates. Each row
%               represents a vertex; the first, second and third columns
%               represent X-, Y- and Z-coordinates respectively.
%    normalise: Logical indicating whether or not the normals should be
%               normalised to unit length. Optional, defaults to true.
%
%   Output:
%    normals: N-by-3 array containing normal vectors. Each row represents a
%             normal vector and corresponds to a row in F; the first,
%             second and third columns contain X-, Y- and Z-coordinates
%             respectively.
%
%   Effect: This function will calculate the normal vectors of all
%   triangles in the provided mesh. The normal vector directions are chosen
%   according to the sequence in which indices into V appear in F.
%
%   Dependencies: VectorNorms.m
%
%   Known parents: TRI_VertexNormals.m
%                  TRI_CutWithBoundedPlane.m
%                  TRI_MeanNormal.m
%                  TRI_RemoveBadlyConnectedTriangles.m
%                  TRI_CutWithMultiPlane.m
%                  TRI_RegionCutter.m
%                  TRI_ShellSeparationDistance.m
%                  Muscle_CutByRegionBorder.m
%                  Muscle_SelectByRegionBorder.m
%                  TRI_DetermineTriangleConnections.m
%                  TRI_Areas.m
%                  TRI_IntersectWithVectors.m
%                  ICP_RegisterSurfaces.m
%                  KIN_SurfaceRotationCenter.m

%Created on 06/12/2006 by Ward Bartels.
%Stabile, fully functional.


%Rearrange V so different triangle vertices are stacked vertically
V = reshape(V(F(:),:), [size(F, 1) 3 3]);

%Calculate two edge vectors
V = diff(V, 1, 2);

%Calculate cross product
normals = [V(:,3).*V(:,6)-V(:,5).*V(:,4) ...
           V(:,5).*V(:,2)-V(:,1).*V(:,6) ...
           V(:,1).*V(:,4)-V(:,3).*V(:,2)];

%Normalise if requested <<VectorNorms.m>>
if nargin<3 || normalise
    normals = normals./(VectorNorms(normals)*[1 1 1]);
end