function plot3dConfInter(measurements, coleurMeas, coleurStat, k)
%PLOT3DCONFINTER Beautiful ploting of 3 dimensional arrays
%   Plotting of 3 dimensional arrays, where 1st dimension is different
%   observations, 2nd dimension is time and 3rd dimension is different
%   variables. The mean and confidence intervals for the different
%   observations for each variable is plotted.
    for j=1:size(measurements,1)
        hold on
        plot(measurements(j,:,k),'Color',coleurMeas(j,:));
    end
    meanM = squeeze(nanmean(measurements,1));
    sdM = squeeze(nanstd(measurements,0,1));
    X2=[(meanM(:,k)+sdM(:,k))',fliplr((meanM(:,k)-sdM(:,k))')];
    X1=[1:1:size(meanM,1),fliplr(1:1:size(meanM,1))];
    h= fill(X1,X2,coleurStat{1},'EdgeColor','none');
    uistack(h,'bottom')
    plot(meanM(:,k),'Color',coleurStat{2},'LineWidth',3)
end