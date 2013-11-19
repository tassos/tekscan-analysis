function [vertices, triangles] = TRI_IntersectWithLine(F, V, alpha)
%TRI_IntersectWithLine  Intersect mesh and line.
%wb20060619
%
%   Syntax:
%    vertices = TRI_IntersectWithLine(F, V, alpha)
%
%   Input:
%    F:     N-by-3 array containing indices into V. Each row represents a
%           triangle, each element is a link to a vertex in V.
%    V:     N-by-3 array containing vertex coordinates. Each row represents
%           a vertex; the first, second and third columns represent X-, Y-
%           and Z-coordinates respectively.
%    alpha: 2-by-3 array which defines the line by specifying vertex
%           coordinates. Each row represents a vertex that lies on the
%           line; the first, second and third colums represent X-, Y- and
%           Z-coordinates respectively.
%
%   Output:
%    vertices:  N-by-3 array containing vertex coordinates. Each row
%               represents the intersection of the line with one triangle;
%               the first, second and third columns represent X-, Y- and Z-
%               coordinates respectively.
%    triangles: Column vector containing the intersected triangles. Each
%               element is a row index into F.
%
%   Effect: This function will determine which triangles in F are
%   intersected by the line defined by alpha, and return the coordinates of
%   the intersection points.
%
%   Dependencies: IntersectLineAndPlane.m
%
%   Known parents: TRI_RegionCutter.m

%Created on 19/06/2006 by Ward Bartels.
%Stabile, fully functional.


%Assemble new X-, Y- and Z-axes for projection
zax = diff(alpha, 1, 1);
[ignoble, ind] = min(abs(zax));
xax = [0 0 0]; xax(ind) = 1;
xax = cross(zax, xax);
yax = cross(zax, xax);

%Project V
tform = inv([xax; yax; zax]);
tform(4,:) = -alpha(1,:)*tform;
Vxy = [V ones(size(V, 1), 1)]*tform(:,1:2);

%Get rotation directions of triangle side vectors around origin
rotdir = cross(Vxy(F), Vxy(F+size(Vxy, 1)));

%A triangle is intersected when rotdir contains negative or positive
%numbers, but not both, on one row
triangles = xor(any(rotdir>eps, 2), any(rotdir<-eps, 2));
if nargout>=2
    triangles = find(triangles);
end

%Calculate intersection points <<IntersectLineAndPlane.m>>
beta = V(F(triangles,:).',:);
vertices = permute(IntersectLineAndPlane(alpha, beta), [3 2 1]);