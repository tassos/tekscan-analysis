function [obj, li, ax] = GUI_PlotShells(varargin)
%GUI_PlotShells  Plot different shells in different colors.
%wb20060503
%
%   Syntax:
%    [obj, li, ax] = ...
%        GUI_PlotShells(F, V, colors, edgealpha, lit, translucent, merge)
%    [obj, li, ax] = GUI_PlotShells(h, ...)
%
%   Input:
%    h:           Handle to the figure, container object or axes on which
%                 the mesh is to be displayed. If h is equal to 0, a new
%                 figure will be created.
%    F:           N-by-3 array containing indices into V. Each row
%                 represents a triangle, each element is a link to a vertex
%                 in V. If the mesh contains multiple shells, the F-
%                 matrices should be placed in an N-by-1 cell array.
%                 Optional, defaults to an empty cell array.
%    V:           N-by-3 array containing vertex coordinates. Each row
%                 represents a vertex; the first, second and third columns
%                 represent X-, Y- and Z-coordinates respectively. If the
%                 mesh contains multiple shells, the V-matrices should be
%                 placed in an N-by-1 cell array. Optional, defaults to an
%                 empty cell array.
%    colors:      N-by-3 array containing color definitions. Each row
%                 corresponds with a shell in F and V. The first, second
%                 and third columns represent red, green and blue values
%                 respectively. Each element lies between 0 and 1. If only
%                 one color is provided, it will be used for every shell.
%                 If set to an empty matrix, colors will be assigned
%                 automatically. Optional, defaults to an empty matrix.
%    edgealpha:   Number between 0 and 1, indicating edge transparency.
%                 Setting this number to 0 (invisible edges) or 1 (fully
%                 opaque edges) will increase rendering speed. If edges are
%                 set invisible, lights should be present to reveal the
%                 shape of the mesh. Optional, defaults to 0.
%    lit:         Logical indicating whether or not lights should be
%                 created. If set to true, two lights will be created at
%                 infinity in directions [1 1 1] and [-1 -1 -1]. If set to
%                 an empty matrix, lights will be added only if ax has no
%                 lights yet. Optional, defaults to an empty matrix.
%    translucent: Logical indicating whether or not the mesh should be
%                 translucent. If set to true, an alpha value of 0.4 will
%                 be assigned to the triangles of the mesh, making them
%                 translucent. Optional, defaults to false.
%    merge:       Logical indicating whether or not the shells should be
%                 merged before plotting. If set to true, all shells will
%                 be merged into one, only one patch handle will be
%                 returned in obj, and only the first color will be used.
%                 Optional, defaults to false.
%
%   Output:
%    obj: Column vector of handles to the patch objects used to plot the
%         different shells.
%    li:  Column vector of handles to every light present in ax after the
%         mesh is displayed.
%    ax:  Handle to the axes on which the mesh is displayed.
%
%   Effect: This function will plot the shells defined by F and V.
%   Different colors may be assigned to each individual shell. If the
%   second syntax is used and h is a valid axes handle, the mesh will be
%   displayed on axes h, which is left unaltered except for the addition of
%   patch objects and lights. If h is a figure or container object handle,
%   the mesh will be displayed in a new axes on h. If h equals zero, the
%   mesh will be displayed on a new figure.
%
%   Dependencies: TRI_Merge.m
%                 GUI_DistributeColors.m
%
%   Known parents: GUI_IndicateMultiPlane.m
%                  TRI_FlipNormalsToConvex.m
%                  GUI_SimulateSurgery.m
%                  GUI_SelectShells.m
%                  TRI_RegionCutter.m

%Created on 24/03/2006 by Ward Bartels.
%WB, 07/04/2006: Added merging of shells.
%WB, 03/05/2006: Figure handles are now accepted as input arguments.
%WB, 05/05/2006: Container handles are now accepted as input arguments.
%Stabile, fully functional.


%Handle input
if nargin>=1 && numel(varargin{1})==1 && ishandle(varargin{1})
    h = varargin{1}; %h may be 0!
    argin = varargin(2:end);
    nin = nargin-1;
else
    h = 0;
    argin = varargin;
    nin = nargin;
end

%Create figure and axes if necessary
if strcmp(get(h, 'Type'), 'axes') %Axes handle provided
    ax = h;
else                              %Root or figure handle provided
    if ~h %Zero (root handle) provided
        fig = figure('Visible', 'off', 'Color', [1 1 1]);
        h = fig;
    else  %Figure or container handle provided
        fig = ancestor(h, 'figure');
    end
    ax = axes('Parent', h, 'Position', [0.05 0.05 0.9 0.9], 'Box', 'on', ...
              'XTick', [], 'YTick', [], 'ZTick', [], ...
              'DataAspectRatio', [1 1 1], 'Projection', 'perspective');
    set(ax, 'CameraPositionMode', 'auto', ...
        'CameraViewAngleMode', 'auto', ...
        'CameraTargetMode', 'auto');
end

%Set defaults for F, V, colors, edgealpha, lit, translucent and merge
defaults = {cell(0, 1) cell(0, 1) zeros(0, 3) 0 [] false false};
argin(7:-1:nin+1) = defaults(7:-1:nin+1);

%Transfer inputs
[F, V, colors, edgealpha, lit, translucent, merge] = argin{:};

%Merge shells if necessary <<TRI_Merge.m>>
if merge
    [F, V] = TRI_Merge(F, V, false);
    colors = colors(1,:);
end

%If F and V are not cell arrays, assume there is only one shell
if ~iscell(F)
    F = {F};
    V = {V};
end

%Automatically assign colors if necessary <<GUI_DistributeColors.m>>
if isempty(colors)
    colors = GUI_DistributeColors(length(F));
elseif size(colors, 1)~=length(F)
    colors = colors(ones(length(F), 1),:); %Replicate single color
end

%Set edge color
if edgealpha==0
    edgecolor = 'none';
else
    edgecolor = [0.2 0.2 0.2];
end

%Use patch to plot shells
obj = zeros(0, 1);
hstate = ishold(ax); hold(ax, 'on');
for ind = 1:length(F)
    if ~isempty(F{ind}) && ~isempty(V{ind})
        obj(end+1,1) = patch('Parent', ax, ...
                             'Vertices', V{ind}, 'Faces', F{ind}, ...
                             'FaceColor', colors(ind,:), ...
                             'EdgeColor', edgecolor, ...
                             'EdgeAlpha', edgealpha, ...
                             'AmbientStrength', 0.4, ...
                             'DiffuseStrength', 0.8, ...
                             'SpecularStrength', 0.2, ...
                             'SpecularColorReflectance', 0.5, ...
                             'FaceLighting', 'gouraud');
    end
end
if ~hstate, hold(ax, 'off'); end

%Set translucency if applicable
if translucent
    set(obj, 'FaceAlpha', 0.4);
end

%Set lights if applicable
li = get(ax, 'Children');
li = li(strcmp(get(li, 'Type'), 'light'));
if isempty(lit), lit = isempty(li); end
if lit
    li(end+1,1) = light('Parent', ax, 'Position', [1 1 1],    'Style', 'infinite', 'Color', [1 1 1]);
    li(end+1,1) = light('Parent', ax, 'Position', [-1 -1 -1], 'Style', 'infinite', 'Color', [1 1 1]);
end

%Set axes properties and show figure
axis(ax, 'tight');
% set(ax, 'CameraPositionMode', 'auto', ...
%         'CameraViewAngleMode', 'auto', ...
%         'CameraTargetMode', 'auto');
if exist('fig', 'var')
    view(ax, 3);
    figure(fig);
end