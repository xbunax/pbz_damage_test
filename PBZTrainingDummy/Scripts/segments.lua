-- Immutable local DPS records. No UObject, weapon, or world references are stored.
local M={LIMIT=100,MAX_BYTES=262144}
local function identity(key,...)if select('#',...)>0 then return string.format(key,...)end;return key end
function M.name(row,T)return row.autoLabel and (T or identity)('分段 %d',row.id)or row.label end
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function integer(n)return finite(n) and n>=0 and n%1==0 end
local function copy(row)local out={};for k,v in pairs(row)do out[k]=v end;return out end
local function text(s,limit)
    if type(s)~='string' or not utf8.len(s)then return nil end
    s=s:gsub('[%z\1-\31\127]',' '):match('^%s*(.-)%s*$')
    local cut=utf8.offset(s,limit+1)
    return cut and s:sub(1,cut-1) or s
end
local function read(fs,path)
    local f=fs.open(path,'rb');if not f then return nil end
    local data=f:read(M.MAX_BYTES+1);f:close()
    return data
end
local function write(fs,path,data)
    local f=fs.open(path,'wb');if not f then return false end
    local ok=f:write(data);local closed=f:close()
    return ok~=nil and ok~=false and closed~=nil and closed~=false and read(fs,path)==data
end
function M.new(path,json,fs)
    fs=fs or io
    local s={rows={},nextId=1,warning=nil,blocked=false,path=path}
    local currentRaw
    local function decode(data)
        if type(data)~='string' or #data>M.MAX_BYTES then return nil end
        local ok,doc=pcall(json.Decode,data)
        if not ok or type(doc)~='table' or doc.version~=1 or not integer(doc.nextId) or doc.nextId<1 or
            type(doc.records)~='table' or #doc.records>M.LIMIT then return nil end
        local rows,ids,maxId={},{},0
        for index,row in pairs(doc.records)do
            if not integer(index)or index<1 or index>#doc.records or type(row)~='table' or
                not integer(row.id)or row.id<1 or ids[row.id]then return nil end
            for _,key in ipairs({'label','targetId','targetName','mode','created'})do
                if not text(row[key],128)or text(row[key],128)~=row[key]then return nil end
            end
            for _,key in ipairs({'seconds','total','maximum','maxHP','dps'})do
                if not finite(row[key])or row[key]<0 then return nil end
            end
            if row.total<=0 or row.maxHP<10 or not integer(row.events)or row.events<1 or
                not integer(row.refills)or math.abs(row.dps-row.total/math.max(1,row.seconds))>math.max(0.000001,row.dps*0.000001)then return nil end
            if row.autoLabel~=nil and type(row.autoLabel)~='boolean'then return nil end
            ids[row.id]=true;maxId=math.max(maxId,row.id);rows[index]=copy(row)
        end
        if doc.nextId<=maxId then return nil end
        return rows,doc.nextId
    end
    local data=read(fs,path)
    if data then
        local rows,nextId=decode(data)
        if rows then s.rows=rows;s.nextId=nextId;currentRaw=data
        else
            local backup=read(fs,path..'.bak');rows,nextId=decode(backup)
            if rows then
                s.rows=rows;s.nextId=nextId;currentRaw=backup
                s.warning='历史主文件异常，已从本地备份恢复'
            else s.blocked=true;s.warning='历史文件无法读取；请先备份并检查 dps_segments.json' end
        end
    else
        local backup=read(fs,path..'.bak')
        if backup then
            local rows,nextId=decode(backup)
            if rows then s.rows=rows;s.nextId=nextId;currentRaw=backup;s.warning='已恢复历史备份'
            else s.blocked=true;s.warning='历史备份无法读取，请先检查文件' end
        end
    end
    local function persist(rows,nextId)
        if s.blocked then return false,s.warning end
        local ok,encoded=pcall(json.Encode,{version=1,nextId=nextId,records=rows})
        if not ok or type(encoded)~='string' or #encoded>M.MAX_BYTES then return false,'分段数据无法保存或已超过大小限制' end
        if not write(fs,path..'.tmp',encoded)then return false,'临时分段文件写入失败，当前统计已保留' end
        if currentRaw and not write(fs,path..'.bak',currentRaw)then return false,'历史备份写入失败，当前统计已保留' end
        if not write(fs,path,encoded)then
            if currentRaw then write(fs,path,currentRaw)end
            return false,'历史文件写入未确认，当前统计已保留'
        end
        s.rows=rows;s.nextId=nextId;s.warning=nil;currentRaw=encoded
        return true
    end
    function s:add(snapshot,meta,label,created)
        if #self.rows>=M.LIMIT then return nil,'已保存 100 段，请先删除不需要的对比记录' end
        if not snapshot or not finite(snapshot.total)or snapshot.total<=0 or
            not finite(snapshot.seconds)or snapshot.seconds<0 or not finite(snapshot.maximum)or snapshot.maximum<0 or
            not integer(snapshot.events)or snapshot.events<1 or not integer(snapshot.refills)then return nil,'本段还没有有效伤害，无法保存' end
        if type(meta)~='table' or not finite(meta.maxHP)or meta.maxHP<10 then return nil,'本段目标信息不完整' end
        local name=text(label or '',64)
        if not name then return nil,'分段名称不是有效文字' end
        local autoLabel=name==''
        if autoLabel then name='分段 '..self.nextId end
        local row={id=self.nextId,label=name,targetId=text(meta.targetId,128),targetName=text(meta.targetName,128),
            mode=text(meta.mode or 'hold',128),maxHP=meta.maxHP,seconds=snapshot.seconds,total=snapshot.total,
            events=snapshot.events,refills=snapshot.refills,maximum=snapshot.maximum,
            dps=snapshot.total/math.max(1,snapshot.seconds),created=text(created or os.date('%Y-%m-%d %H:%M:%S'),128),autoLabel=autoLabel}
        if not row.targetId or row.targetId=='' or not row.targetName or row.targetName=='' or
            not row.mode or not row.created then return nil,'本段目标名称无效' end
        local rows={};for _,old in ipairs(self.rows)do rows[#rows+1]=copy(old)end
        rows[#rows+1]=row
        local ok,why=persist(rows,self.nextId+1)
        return ok and copy(row)or nil,why
    end
    function s:get(id)
        for _,row in ipairs(self.rows)do if tostring(row.id)==tostring(id)then return copy(row)end end
    end
    function s:delete(id)
        local rows,found={},false
        for _,row in ipairs(self.rows)do
            if tostring(row.id)==tostring(id)then found=true else rows[#rows+1]=copy(row)end
        end
        if not found then return false,'没有选中保存记录' end
        return persist(rows,self.nextId)
    end
    function s:options(T)
        T=T or identity
        local out={}
        for _,row in ipairs(self.rows)do
            out[#out+1]={label=string.format('#%d %s | DPS %.2f',row.id,M.name(row,T),row.dps),value=tostring(row.id)}
        end
        if #out==0 then out[1]={label=T('暂无保存分段'),value='none'}end
        return out
    end
    return s
end
function M.describe(row,T,targetName)
    T=T or identity
    if not row then return T('请选择保存分段') end
    return T('#%d %s\n目标：%s / 血量 %.0f\n平均 DPS %.2f | 伤害 %.2f\n有效时间 %.2f 秒 | 命中 %d 次',
        row.id,M.name(row,T),targetName or row.targetName,row.maxHP,row.dps,row.total,row.seconds,row.events)
end
function M.compare(a,b,T)
    T=T or identity
    if not a or not b then return T('保存两段后，可选择 A 与 B 比较') end
    local difference=b.dps-a.dps
    local percent=a.dps>0 and T('（%+.2f%%）',difference/a.dps*100)or T('（A 的 DPS 为零）')
    local condition=a.targetId==b.targetId and a.maxHP==b.maxHP and a.mode==b.mode
    return T('B 相比 A：DPS %+.2f %s\n%s',difference,percent,
        T(condition and '目标、血量与训练模式相同；请保持其他测试条件一致' or '目标、血量或训练模式不同，比较时请注意条件差异'))
end
return M
