function updateSource
    prompt='Are you sure you want to install the latest version? All changes you made in the source will be lost forever!';
    if strcmp(questdlg(prompt,'Update source?','Yes','No','No'),'Yes');
        git('checkout library');
        git('reset --hard HEAD');
        result = git('pull mech library');
        if strfind(result,'Already up-to-date.')
            msgbox('Software was already in the latest version');
        elseif ~isempty(strfind(result,'fatal')) || ~isempty(strfind(result,'error')) || ~isempty(strfind(result,'git --help'))
            msgbox(sprintf(['There was a problem with the software ',...
            'update.\nIt returned the following error:\n\n%s'],result));
        else
            msgbox('The newest version of the software was installed');
        end
    end
end