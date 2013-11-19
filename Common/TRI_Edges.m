function [edges, triangles] = TRI_Edges(F)
%TRI_Edges  Determine all edges of a mesh.
%wb20070430
%
%   Syntax:
%    [edges, triangles] = TRI_Edges(F)
%
%   Input:
%    F: N-by-3 array containing vertex indices. Each row represents a
%       triangle, each element is a link to a vertex.
%
%   Output:
%    edges:     N-by-2 array containing edges. Each row represents an edge,
%               each element is a link to a vertex. Each edge in this array
%               may occur once or twice, depending on the number of
%               triangles it belongs to. Edges are listed in the same order
%               as their triangles in F, so the three edges that belong to
%               the first triangle in F are listed first, and so on.
%    triangles: Column vector indicating the triangles to which the edges
%               belong. Each row corresponds to the same row in edges and
%               each element is a row index into F.
%
%   Effect: This function will find all edges in a mesh.
%
%   Dependencies: none
%
%   Known parents: TRI_DetermineBorderEdges.m
%                  TRI_DetermineTriangleConnections.m
%                  TRI_IntersectWithPlane.m
%                  TRI_CutWithContour.m
%                  Contour_VertexConnections.m
%                  TRI_SeparateShells.m
%                  TRI_VertexNeighbourhood.m
%                  TRI_RemoveBadlyConnectedTriangles.m
%                  Contour_DelaunayContainment.m
%                  TRI_CutWithBoundedPlane.m

%Created on 19/12/2005 by Ward Bartels.
%WB, 20/12/2005: Removed sorting of output.
%WB, 19/12/2006: Added conditional for calculation of second output.
%WB, 30/04/2007: Speed improvements.
%Stabile, fully functional.


%Assemble matrix containing all edges
F = F.';
edges = [F(:) reshape(F([2 3 1],:), [], 1)];

%Triangle indices for edges
if nargout>=2
    triangles = 1:size(F, 2);
    triangles = triangles([1 1 1],:);
    triangles = triangles(:);
end