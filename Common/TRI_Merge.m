function [F, V] = TRI_Merge(F, V, cleanup)
%TRI_Merge  Merge shells into one.
%wb20070430
%
%   Syntax:
%    [F, V] = TRI_Merge(F, V, cleanup)
%
%   Input:
%    F:       N-by-1 cell array containing separate F-matrices for each
%             shell.
%    V:       N-by-1 cell array containing separate V-matrices for each
%             shell.
%    cleanup: Logical indicating whether or not redundant vertices should
%             be removed after merging the shells. Optional, defaults to
%             false.
%   Output:
%    F: N-by-3 array containing indices into V. Each row represents a
%       triangle, each element is a link to a vertex in V.
%    V: N-by-3 array containing vertex coordinates. Each row represents a
%       vertex; the first, second and third columns represent X-, Y- and
%       Z-coordinates respectively.
%
%   Effect: This function will merge all shells provided in the input into
%   one shell, and remove redundant vertices if requested. Single F- and V-
%   arrays are returned.
%
%   Dependencies: none
%
%   Known parents: GUI_PlotShells.m
%                  TRI_RegionCutter.m
%                  Muscle_CutByRegionBorder.m

%Created on 07/04/2006 by Ward Bartels.
%WB, 30/04/2007: Added fail-safe for empty shell lists.
%Stabile, fully functional.


%Handle input
if nargin<3, cleanup = false; end

%Determine increment for each array in F
incr = cumsum([0; cellfun(@(v) size(v, 1), V(1:end-1,1))]);

%Assemble new V
V = vertcat(V{:});

%Fail-safe: return empty shells if F is empty
if isempty(F)
    F = zeros(0, 3);
    if isempty(V) || cleanup
        V = zeros(0, 3);
    end
    return
end

%Increment each array in F in order to preserve references
F = cellfun(@plus, F, num2cell(incr), 'UniformOutput', false);

%Assemble new F
F = vertcat(F{:});

%Clean out redundant vertices if requested
if cleanup
    [V, ind, jnd] = unique(V, 'rows');
    jnd = jnd.';
    F = jnd(F);
end