function plotPeakLocation (pos, x, y, data)
    % Plotting location of center of pressure in the two directions
    fig=figure('name','Peak pressure location in two directions');
    set(fig,'OuterPosition',pos);
    
    coleurMeas=hsv(size(data,1));
    coleurStat={[0.9,0.9,1],'b'};

    subplot(2,1,1)
    plot3dConfInter(data,coleurMeas,coleurStat,1);
    ylabel('Peak Location in A/P direction (sensel)')
    ylim([min(x(:)),max(x(:))])
    title('Position of the peak Location in A/P direction (sensor row)')
    grid on
    subplot(2,1,2)
    plot3dConfInter(data,coleurMeas,coleurStat,2);
    ylabel('Peak location in M/L direction (sensel)')
    xlabel('Stance phase (%)')
    ylim([min(y(:)),max(y(:))])
    title('Position of the peak location in M/L direction (sensor col)')
    grid on
end