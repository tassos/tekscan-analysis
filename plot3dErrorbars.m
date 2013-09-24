function [h]=plot3dErrorbars(x, y, z, e, plotSD)
    % Source: http://code.izzid.com/2007/08/19/How-to-make-a-3D-plot-with-errorbars-in-matlab.html

    % This matlab function plots 3d data using the plot3 function
    % it adds vertical errorbars to each point symmetric around z
    % I experimented a little with creating the standard horizontal hash
    % tops the error bars in a 2d plot, but it creates a mess when you 
    % rotate the plot
    %
    % x = xaxis, y = yaxis, z = zaxis, e = error value
    
    if ~isempty(findall(0,'Type','figure'))
        hold off
        viewAngle = get(gca,'CameraViewAngle');
        cameraPos = get(gca,'CameraPosition');
    end
    
    zMax = z(:) + e(:);
    
    % now we want to fit a surface to our data
    % the  0.25 and 0.1 define the density of the fit surface
    % adjust them to your liking
    tt1=floor(min(min(x))):0.35:max(max(x));
    tt2=floor(min(min(y))):0.35:max(max(y));

    % prepare for fitting the surface
    [xg,yg]=meshgrid(tt1,tt2);

    % fit the surface to the data;
    % matlab has several choices for the fit;  below is "linear"
    zg=griddata(x(:), y(:), z(:), xg,yg,'linear')/1e6;
    zgSd=griddata(x(:), y(:), zMax(:), xg,yg,'linear')/1e6;
    % draw the mesh on our plot
    surf(xg,yg,zg,'EdgeColor','r'), xlabel('Sensor columns'), ylabel('Sensor rows'), zlabel('Pressure (MPa)')
    if exist('viewAngle','var')
        set(gca,'CameraViewAngle',viewAngle,'CameraPosition',cameraPos);
    end
    if plotSD
        hold on
        surf(xg,yg,zgSd,'FaceAlpha',0.15,'FaceColor','b','EdgeColor','none')
    end
    axis tight 
    axis normal
end