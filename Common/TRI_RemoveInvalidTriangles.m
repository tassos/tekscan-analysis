function [F, ind, V] = TRI_RemoveInvalidTriangles(F, V)
%TRI_RemoveInvalidTriangles  Remove triangles no larger than a line.
%wb20060103
%
%   Syntax:
%    [F, ind, V] = TRI_RemoveInvalidTriangles(F, V)
%    [F, ind] = TRI_RemoveInvalidTriangles(F)
%
%   Input:
%    F: N-by-3 array containing indices into V. Each row represents a
%       triangle, each element is a link to a vertex in V.
%    V: N-by-3 array containing vertex coordinates. Each row represents a
%       vertex; the first, second and third columns represent X-, Y- and
%       Z-coordinates respectively.
%
%   Output:
%    F:   N-by-3 array containing indices into V. Each row represents a
%         triangle, each element is a link to a vertex in V.
%    ind: Column vector of logicals indicating which rows have been removed
%         from F. A "true" in this vector means that the corresponding row
%         in F has been removed.
%    V:   N-by-3 array containing vertex coordinates. Each row represents a
%         vertex; the first, second and third columns represent X-, Y- and
%         Z-coordinates respectively.
%
%   Effect: This function will remove invalid triangles from a mesh. A
%   triangle is invalid if at least two of its vertices are equal, reducing
%   the triangle to a line or a point. If the first syntax is used, this
%   function will remove redundant and unused vertices; if the second
%   syntax is used, redundant vertices must be removed from F for this
%   function to run properly (see STL_RemoveRedundancy.m).
%
%   Dependencies: DeleteUnreferencedElements.m
%
%   Known parents: STL_RemoveRedundancy.m
%                  TRI_CutWithPlane.m
%                  TRI_CutWithMultiPlane.m
%                  TRI_CutWithContour.m
%                  STL_ReadFile.m

%Created on 03/01/2006 by Ward Bartels.
%Stabile, fully functional.


%Remove redundant vertices or ensure output of V is not required
if nargin==2
    [V, jnd, knd] = unique(V, 'rows');
    F = knd(F);
else
    error(nargoutchk(1, 2, nargout));
end

%Check for equal elements on each row of F and remove row if any are found
ind = any(~diff([F F(:,1)], 1, 2), 2);
F(ind,:) = [];

%Remove unused vertices
if nargin==2
    [V, F] = DeleteUnreferencedElements(V, F);
end