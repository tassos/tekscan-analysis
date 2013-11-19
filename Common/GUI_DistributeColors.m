function colors = GUI_DistributeColors(number);
%GUI_DistributeColors  Distribute colors evenly.
%wb20060324
%
%   Syntax:
%    colors = GUI_DistributeColors(number);
%
%   Input:
%    number: The number of colors to return.
%
%   Output:
%    colors: N-by-3 array containing color definitions. The first, second
%            and third columns represent red, green and blue values
%            respectively. Each element lies between 0 and 1.
%
%   Effect: This function will calculate the requested number of colors in
%   such a way that they are evenly distributed over the hue spectrum.
%
%   Dependencies: none
%
%   Known parents: GUI_PlotShells.m
%                  TRI_MeshCutter.m
%                  GUI_SelectShells.m
%                  TRI_RegionCutter.m

%Created on 15/03/2006 by Ward Bartels.
%WB, 24/03/2006: Eliminated bug causing crash when number is 0.
%Stabile, fully functional.

%Distribute hue of colors evenly between 0 and 1
hue = linspace(0, 1, number+1).';
hue(end,:) = [];

%Calculate RGB colors
colors = hsv2rgb([hue ones(size(hue))*0.4 ones(size(hue))]);