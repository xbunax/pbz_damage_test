local M={}
function M.parse(text,keys)
    local section,name='','F8'
    for line in (text..'\n'):gmatch('(.-)\n') do
        line=line:gsub('\r',''):gsub('[;#].*$',''):match('^%s*(.-)%s*$')
        local header=line:match('^%[(.-)%]$')
        if header then section=header:lower() end
        if section=='keybinds' then
            local key,value=line:match('^(%w+)%s*=%s*(.-)%s*$')
            if key and key:lower()=='menutoggle' then name=value:upper() end
        end
    end
    if not name:match('^[A-Z0-9_]+$') or type(keys[name])~='number'
        or name=='ESCAPE' or name:find('MOUSE') or name:find('BUTTON') then
        return {key=keys.F8,name='F8'},'Invalid MenuToggle; using F8'
    end
    return {key=keys[name],name=name}
end
function M.load(path,keys)
    local file=io.open(path,'rb')
    if not file then return {key=keys.F8,name='F8'} end
    local text=file:read('*a');file:close()
    return M.parse(text:gsub('^\239\187\191',''),keys)
end
return M
