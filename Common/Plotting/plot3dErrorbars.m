function plot3dErrorbars(x, y, z, e, n, rows, cols, plotAreaDiv, plotSD, shadingInt)
    % Source: http://code.izzid.com/2007/08/19/How-to-make-a-3D-plot-with-errorbars-in-matlab.html

    % This matlab function plots 3d data using the plot3 function
    % it adds vertical errorbars to each point symmetric around z
    % I experimented a little with creating the standard horizontal hash
    % tops the error bars in a 2d plot, but it creates a mess when you 
    % rotate the plot
    %
    % x = xaxis, y = yaxis, z = zaxis, e = error value
    zFrame = squeeze(z(n,:,:));
    eFrame = squeeze(e(n,:,:));
    
    if ~isempty(findall(0,'Type','axes'))
        hold off
        viewAngle = get(gca,'CameraViewAngle');
        cameraPos = get(gca,'CameraPosition');
    end
    
    zMax = zFrame + eFrame;
    
    % draw the mesh on our plot
    surf(x,y,zFrame,'EdgeColor','r')
    if shadingInt
        shading interp
    else
        shading faceted
    end
    rotate3d on
    if exist('viewAngle','var')
        set(gca,'CameraViewAngle',viewAngle,'CameraPosition',cameraPos);
    end
    hold on
    if plotSD
        surf(x,y,zMax,'FaceAlpha',0.15,'FaceColor','b','EdgeColor','none')
    end
    
    if plotAreaDiv
        for i=1:size(rows,2)-1
            surf([max(rows{i}),max(rows{i})],[min(y(:)),max(y(:))],repmat([0,max(z(:))/2],2,1),'FaceColor','g','FaceAlpha',0.3);
        end
        for j=1:size(cols,2)-1
            surf([min(x(:)),max(x(:))],[max(cols{j}),max(cols{j})],repmat([0;max(z(:)/2)],1,2),'FaceColor','g','FaceAlpha',0.3);
        end
    end
    axis tight 
    set(gca,'DataAspectRatio',[1 1 3e5]);
end