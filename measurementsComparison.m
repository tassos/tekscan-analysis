%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%                       Comparing the different measurements
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Function: Comparing the results of different measurements
%
% Input
% None
%
% Output 
% None
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function measurementsComparison
    %Choose files to 
    [measFileName,measPathName] = uigetfile('.mat','Select measurement files',...
        'MultiSelect','on','C:\users\u0074517\Documents\PhD\Foot-Ankle Project\Measurements');
    
    %Calculate the size of the array data. First dimension is for different
    %measurements, the rest are following the same convention as all the
    %Tekscan related files.
    load([measPathName measFileName{1}],'calibratedData');
    data=squeeze(zeros([size(measFileName),size(calibratedData)]));
    
    for i=1:size(measFileName,2)
        load([measPathName measFileName{i}],'calibratedData');
        data(i,:,:,:) = calibratedData;
    end
    
    %Now we can do statistics

end