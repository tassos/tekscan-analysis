function plot3dConfInter(measurements)
%PLOT3DCONFINTER Summary of this function goes here
%   Detailed explanation goes here
    meanValue = mean(measurements,2)';
    sdValue=std(measurements,0,2)';
    X1=[1:1:100,fliplr(1:1:100)];
    X2=[meanValue+sdValue,fliplr(meanValue-sdValue)];
    fill(X1,X2,[0.9,0.9,1]);
    for k=1:size(measurements,2)
        hold on
        plot(measurements(:,k),'Color',[0.75,0.75,1]);
    end
    plot(meanValue,'Color','b','LineWidth',3)
end

