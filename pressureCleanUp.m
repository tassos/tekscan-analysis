function cleanData = pressureCleanUp(data)
%PRESSURECLEANUP Cleaning up operations for the data
% Function: Detects potentially bad sensels of the sensor and makes their
% output equal to zero. Initially the mean of each sensel in the duration
% of time is taken and is substracted by the actual value of the sensel at
% all times. Then the result is summed for each sensel. If the result is
% zero, it means that the sensel gives a contant output during the whole
% duration of the roll-off (which is weird and it means that it's broken).
    normData = data - repmat(mean(data,1),[size(data,1),1,1]);
    sumNormData = squeeze(sum(normData,1));
    cleanData = data;
    cleanData(sumNormData == 0) = 0;
end