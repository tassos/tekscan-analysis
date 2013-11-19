function [index] = findFile(string, fileslist)
    index = 0;
    for i=1:size(fileslist,1)
        if ~isempty(strfind(fileslist(i).name,string)); index=i; return; end;
    end
end