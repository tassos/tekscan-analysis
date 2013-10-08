function plotForceTotal(pos, data, senselArea)

    coleurMeas=hsv(size(data,2));
    coleurStat={[0.9,0.9,1],'b'};

    for k=1:size(data,2)
        for l=1:size(data,3)
            forceTotal(k,l,2) = sum(sum(data(1,k,l,:,:)))*senselArea;
        end
    end
    
    %Plotting sum of forces that are measured with the sensor
    fig5=figure('name','Total force through the ankle joint');
    set(fig5,'OuterPosition',pos);
    plot3dConfInter(forceTotal, coleurMeas, coleurStat, 2)
    ylabel('Force (N)'), xlabel('Stance phase (%)')
    title('Total force through the ankle joint')
end