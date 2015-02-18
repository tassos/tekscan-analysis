function [side, flip, sensor, specimen] = extractSpecimenDetails(filename)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    % Reading details regarding the specimen: side (Left/Right),
    % positioning (0 for upsideUp 1 for upsideDown), sensor (sensor id),
    % specimen (specimen id)
    info=ReadYaml(filename);
    
    side = info.side;
    specimen = info.specimen;
    
    for i=1:length(info.cases)
       sensor.(info.cases{i}.name) = info.cases{i}.sensor;
       flip.(info.cases{i}.name) = info.cases{i}.flip;
    end
end
