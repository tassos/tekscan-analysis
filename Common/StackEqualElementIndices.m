function [stack, count] = StackEqualElementIndices(matrix, filler, height, sparse_out)
%StackEqualElementIndices  Put indices of equal elements on a stack.
%wb20061219
%
%   Syntax:
%    [stack, count] =
%        StackEqualElementIndices(matrix, filler, height, sparse_out)
%
%   Input:
%    matrix:     M-by-N array.
%    filler:     Scalar that will be used to fill the empty spaces in the
%                stack. Optional, defaults to 0.
%    height:     Scalar determining the "height" of the stack. If height is
%                Inf, the height will be set to the maximum number of
%                occurrences of a unique row. Optional, defaults to Inf.
%    sparse_out: Logical indicating whether or not the stack should be
%                sparse. Set this to true if the number of occurrences
%                varies greatly. If set to true, filler and height will be
%                ignored. Optional, defaults to false.
%   
%   Output:
%    stack:  M-by-N array containing row indices into matrix. M is the
%            number of unique rows in matrix and N is equal to height. Each
%            row in stack contains the indices of rows in matrix that are
%            equal to eachother. Filler elements are added when the number
%            of equal elements is smaller than height.
%    count:  Column vector indicating the number of occurrences of each
%            unique row in matrix. Each element is equal to the number of
%            non-filler elements on the corresponding row in stack.
%
%   Effect: This function will find unique rows in matrix and determine on
%   which indices these rows occur. Indices pointing to the last
%   occurrences of the unique rows in matrix will be put in the first
%   column of stack, indices pointing to the second-last occurrence will be
%   put in the second column, and so on - to put it in other words:
%   all(all(diff(stack, 1, 2)<=0))==true.
%
%   Example:
%    matrix = [1 2 2 5 3 3 4 3 4]';
%    stack = StackEqualElementIndices(matrix)
%    matrix(stack(3,:))
%
%   Dependencies: RunLengthDecode.m
%                 IncrementalRuns.m
%
%   Known parents: TRI_DetermineBorderEdges.m
%                  TRI_IntersectWithPlane.m
%                  Contour_VertexConnections.m
%                  TRI_DetermineTriangleConnections.m
%                  TRI_CutAlongContour.m
%                  TRI_SplitWithMultiPlane.m
%                  TRI_determineMeanNormalsOfAllVertices.m
%                  GUI_SimulateSurgery.m
%                  TRI_CutWithContour.m
%                  PSM_ParametriseHemisphereTRI.m
%                  Contour_DeleteSmallest.m
%                  Contour_EnclosedDepth.m
%                  Contour_Branching.m
%                  Contour_SplitInner.m
%                  TRI_SeparateShells.m
%                  TRI_RemoveBadlyConnectedTriangles.m
%                  TRI_IntersectWithLines.m
%                  TRI_CutWithBoundedPlane.m

%Created on 21/12/2005 by Ward Bartels.
%WB, 03/01/2006: Added output of counts.
%WB, 06/01/2006: Added handling of empty matrices; performance
%                improvements.
%WB, 29/03/2006: Added sparse output.
%WB, 19/12/2006: Speed-up by using RunLengthDecode.m and IncrementalRuns.m.
%Stabile, fully functional.


%Handle input
if nargin<2, filler = 0; end
if nargin<4, sparse_out = false; end

%Sort matrix and select unique elements
[matrix_sort, ind_sort] = sortrows(matrix);
ind_sort = [ind_sort; filler]; %Last element is the filler

%Calculate how often the unique rows occur (counts) and where they occur
%(stack) in the sorted matrix
stack = [find(any(matrix_sort(1:end-1,:)~=matrix_sort(2:end,:), 2)); length(ind_sort)-1];
if stack(1)==0    %Handle empty matrix
    stack = zeros(0, 1);
end
count = diff([0; stack]);

%Distinguish between sparse and non-sparse output
if sparse_out
    
    %Handle empty matrix
    if isempty(stack)
        stack = sparse(0, 1);
        return
    end
    
    %Create row and column index matrices <<RunLengthDecode.m>>
    %                                     <<IncrementalRuns.m>>
    ind_row = RunLengthDecode(count);
    ind_col = IncrementalRuns(count);
    
    %Assemble stack, directly taking ind_sort referencing into account
    stack = sparse(ind_row, ind_col, ind_sort(stack(ind_row)-ind_col+1));
    
else
    
    %Set height if necessary
    if nargin<3 || height==Inf
        height = max(count);
    end
    
    %Initialise stack and create countdown matrix
    decrement = -ones(length(stack), height-1);
    stack = cumsum([stack decrement], 2);
    counts = cumsum([count decrement], 2);
    
    %Put in reference to filler where counts has reached zero
    stack(counts<=0) = length(ind_sort);

    %Re-reference stack
    dim = size(stack);
    stack = ind_sort(stack);
    if ~isequal(size(stack), dim), stack = stack.'; end
end