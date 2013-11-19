function varargout = TRI_RemoveBadlyConnectedTriangles(F, V)
%TRI_RemoveBadlyConnectedTriangles  Remove badly connected triangles.
%wb20070212
%
%   Syntax:
%    connections = TRI_RemoveBadlyConnectedTriangles(F)
%    triangles = TRI_RemoveBadlyConnectedTriangles(F, V)
%    [F, V] = TRI_RemoveBadlyConnectedTriangles(F, V)
%
%   Input:
%    F: N-by-3 array containing indices into V. Each row represents a
%       triangle, each element is a link to a vertex in V.
%    V: N-by-3 array containing vertex coordinates. Each row represents a
%       vertex; the first, second and third columns represent X-, Y- and
%       Z-coordinates respectively.
%
%   Output:
%    connections: M-by-N array containing row indices into F. Each row
%                 references at least three triangles that share an edge
%                 (and thus, are badly connected). Will be padded with
%                 zeros where necessary.
%    triangles:   Column vector containing row indices into F, indicating
%                 which triangles should be removed to clean up the mesh.
%    F:           N-by-3 array containing indices into V. Each row
%                 represents a triangle, each element is a link to a vertex
%                 in V.
%    V:           N-by-3 array containing vertex coordinates. Each row
%                 represents a vertex; the first, second and third columns
%                 represent X-, Y- and Z-coordinates respectively.
%
%   Effect: This function will look for edges shared by more than two
%   triangles. Such triangles are badly connected. If the first syntax is
%   used, the indices to these triangles will be returned. If the second
%   or third syntax is used, then for each shared edge, this function will
%   remove the triangles with the smallest areas, until only two remain.
%
%   Dependencies: TRI_Edges.m
%                 StackEqualElementIndices.m
%                 TRI_Normals.m
%                 DeleteUnreferencedElements.m
%
%   Known parents: TRI_CutWithMultiPlane.m
%                  TRI_CutWithContour.m
%                  STL_RemoveRedundancy.m
%                  STL_ReadFile.m

%Created on 12/02/2007 by Ward Bartels.
%Stabile, fully functional.


%See which edges are common <<TRI_Edges.m>> <<StackEqualElementIndices.m>>
stack = StackEqualElementIndices(sort(TRI_Edges(F), 2), 0, 3);

%Check which triangles are badly connected
connections = ceil(stack(stack(:,3)~=0,:)/3);

%If V was not provided, return connections
if nargin<2
    varargout = {connections};
    return
end

%Calculate squared triangle surface areas <<TRI_Normals.m>>
areas = -Inf(size(connections));
areas(connections~=0) = sum(TRI_Normals(F(nonzeros(connections),:), V, false).^2, 2);

%Isolate smallest triangles from those sharing an edge
[areas, ind] = sort(areas, 2, 'ascend');
ind = ind(:,1:end-2);
ind = ind(isfinite(areas(:,1:end-2)));
triangles = connections(sub2ind(size(connections), (1:size(connections, 1)).', ind));

%If only one output argument was requested, return triangles
if nargout<2
    varargout = {triangles};
    return
end

%Remove isolated triangles <<DeleteUnreferencedElements.m>>
F(triangles,:) = [];
[V, F] = DeleteUnreferencedElements(V, F);

%Return F and V
varargout = {F V};