function [matrix, ref] = DeleteUnreferencedElements(matrix, ref, filler)
%DeleteUnreferencedElements  Delete rows that aren't referenced.
%wb20060102
%
%   Syntax:
%    [matrix, ref] = DeleteUnreferencedElements(matrix, ref, filler)
%
%   Input:
%    matrix: M-by-N array.
%    ref:    M-by-N array containing row indices into matrix.
%    filler: Scalar used as a null reference to fill empty spaces in ref.
%            Will be ignored if ref is sparse. Optional.
%
%   Output:
%    matrix: M-by-N array.
%    ref:    M-by-N array containing row indices into matrix.
%
%   Effect: This function will assemble a new version of matrix by keeping
%   only the rows to which the elements of ref refer. Also, ref will be
%   recalculated to ensure matrix(ref,:) returns the same result. The
%   sequence of elements in matrix and ref will remain unchanged, although
%   the values in ref will change due to the re-indexing of matrix. For
%   this function to work properly, matrix must not contain any rows filled
%   with NaNs.
%
%   Dependencies: DeleteUnreferencedElements.m (recursive)
%
%   Known parents: DeleteUnreferencedElements.m (recursive)
%                  STL_RemoveRedundancy.m
%                  TRI_CutWithPlane.m
%                  Contour_Loops.m
%                  TRI_IntersectWithBoundedPlane.m
%                  TRI_RemoveInvalidTriangles.m
%                  TRI_SeparateShells.m
%                  TRI_CutWithContour.m
%                  TRI_RegionCutter.m
%                  TRI_RemoveBadlyConnectedTriangles.m
%                  Muscle_CutByRegionBorder.m

%Created on 02/01/2006 by Ward Bartels.
%WB, 05/10/2006: Reference matrix can now be sparse.
%Stabile, fully functional.


%Wrapper code for sparse reference arrays <<DeleteUnreferencedElements.m>>
if issparse(ref)
    [rows, cols, r] = find(ref);
    [matrix, r] = DeleteUnreferencedElements(matrix, r);
    ref = sparse(rows, cols, r, size(ref, 1), size(ref, 2));
    return
end

%Add dummy row to the end of matrix and replace fillers with reference to
%this element
if nargin==3
    matrix(end+1,:) = NaN;
    ref(ref==filler) = size(matrix, 1);
end

%Extract indices to rows used in matrix
[ref_unique, ignoble, jnd] = unique(ref);

%Translate indices in ref into new indices into matrix
ref = reshape(jnd, [], size(ref, 2));

%Limit matrix to rows referenced in ref
matrix = matrix(ref_unique,:);

%Delete dummy row and replace reference to dummy with fillers
if ~isempty(matrix) && all(isnan(matrix(end,:)))
    ref(ref==size(matrix, 1)) = filler;
    matrix = matrix(1:end-1,:);
end