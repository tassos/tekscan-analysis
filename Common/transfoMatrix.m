function [M] = transfoMatrix(theta, beta, omega)

    RotX = [1, 0, 0;0 cosd(theta) -sind(theta); 0 sind(theta) cosd(theta)];
    RotY = [cosd(beta) 0 sind(beta);0, 1, 0;-sind(beta) 0 cosd(beta)];
    RotZ = [cosd(omega) -sind(omega) 0;sind(omega) cosd(omega) 0;0, 0, 1];
    
    M = RotX*RotY*RotZ;
end