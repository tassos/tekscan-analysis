function updateSource
    git('checkout lite');
    result = git('pull origin lite');
    if strfind(result,'Already up-to-date.')
        msgbox('Software was already in the latest version');
    elseif strfind(result,'fatal')||strfind(result,'error')
        msgbox(sprintf(['There was a problem with the software ',...
        'update.\nIt returned the following error:\n\n%s'],result));
    else
        msgbox('The newest version of the software was installed');
    end
end