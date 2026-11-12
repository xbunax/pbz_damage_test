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
local function consistent(rate,total,seconds)
    return finite(rate)and rate>=0 and math.abs(rate-total/math.max(1,seconds))<=math.max(0.000001,rate*0.000001)
end
local function shachiValid(row)
    local present=false
    for _,key in ipairs({'shachiTotal','shachiMaximum','shachiDps','shachiLast','shachiRecentDps'})do
        if row[key]~=nil then present=true;if not finite(row[key])or row[key]<0 then return false end end
    end
    if not present then return true end -- v1 history did not measure this channel.
    return finite(row.shachiTotal)and finite(row.shachiMaximum)and row.shachiMaximum<=row.shachiTotal and
        consistent(row.shachiDps,row.shachiTotal,row.seconds)
end
local function metaValid(row)
    if row.testDuration~=nil then
        if row.testDuration~=0 and row.testDuration~=5 and row.testDuration~=10 and row.testDuration~=30 then return false end
        if row.timerCompleted~=nil and type(row.timerCompleted)~='boolean'then return false end
        if row.timerCompleted and (row.testDuration==0 or math.abs(row.seconds-row.testDuration)>0.000001)then return false end
        if row.testDuration>0 and row.seconds>row.testDuration+0.000001 then return false end
    elseif row.timerCompleted~=nil then return false end
    if row.maxShachi~=nil and (not finite(row.maxShachi)or row.maxShachi<=0)then return false end
    for _,key in ipairs({'healthPolicy','shachiPolicy'})do
        if row[key]~=nil and row[key]~='custom'and row[key]~='native'then return false end
    end
    if row.level~=nil and (not finite(row.level)or row.level<0)then return false end
    if row.profile~=nil and (not text(row.profile,128)or text(row.profile,128)~=row.profile)then return false end
    if row.difficulty~=nil then
        if type(row.difficulty)=='number'then return finite(row.difficulty)and row.difficulty>=0 end
        if not text(row.difficulty,128)or text(row.difficulty,128)~=row.difficulty then return false end
    end
    return true
end
function M.new(path,json,fs)
    fs=fs or io
    local s={rows={},nextId=1,warning=nil,blocked=false,path=path}
    local currentRaw
    local function decode(data)
        if type(data)~='string' or #data>M.MAX_BYTES then return nil end
        local ok,doc=pcall(json.Decode,data)
        if not ok or type(doc)~='table' or (doc.version~=1 and doc.version~=2) or not integer(doc.nextId) or doc.nextId<1 or
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
            if (row.total<=0 and (not finite(row.shachiTotal)or row.shachiTotal<=0))or row.maxHP<10 or
                not integer(row.events)or row.events<1 or not integer(row.refills)or
                not consistent(row.dps,row.total,row.seconds)or not shachiValid(row)or not metaValid(row)then return nil end
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
        local ok,encoded=pcall(json.Encode,{version=2,nextId=nextId,records=rows})
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
        if type(snapshot)~='table' or not finite(snapshot.total)or snapshot.total<0 or
            (snapshot.total==0 and (not finite(snapshot.shachiTotal)or snapshot.shachiTotal<=0))or
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
        for _,key in ipairs({'maxShachi','healthPolicy','shachiPolicy','level','difficulty','profile'})do row[key]=meta[key]end
        row.testDuration=snapshot.testDuration;row.timerCompleted=snapshot.completed
        if meta.testDuration~=nil and meta.testDuration~=row.testDuration then return nil,'本段计时设置不一致，无法保存'end
        if snapshot.shachiTotal~=nil then
            row.shachiTotal=snapshot.shachiTotal;row.shachiMaximum=snapshot.shachiMaximum
            row.shachiLast=snapshot.shachiLast;row.shachiRecentDps=snapshot.shachiRecentDps
            row.shachiDps=finite(snapshot.shachiTotal)and snapshot.shachiTotal/math.max(1,snapshot.seconds)or nil
        elseif snapshot.shachiMaximum~=nil or snapshot.shachiDps~=nil or snapshot.shachiLast~=nil or snapshot.shachiRecentDps~=nil then
            return nil,'本段杀气统计不完整，无法保存'
        end
        if not shachiValid(row)then return nil,'本段杀气统计不完整，无法保存' end
        if not metaValid(row)then return nil,'本段目标信息不完整' end
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
            local shachi=row.shachiDps~=nil and T(' | 削杀气/s %.2f',row.shachiDps)or T(' | 杀气未记录')
            out[#out+1]={label=string.format('#%d %s | DPS %.2f',row.id,M.name(row,T),row.dps)..shachi,value=tostring(row.id)}
        end
        if #out==0 then out[1]={label=T('暂无保存分段'),value='none'}end
        return out
    end
    return s
end
function M.describe(row,T,targetName)
    T=T or identity
    if not row then return T('请选择保存分段') end
    local details=T('#%d %s\n目标：%s / 血量 %.0f\n平均 DPS %.2f | 伤害 %.2f\n有效时间 %.2f 秒 | 命中 %d 次',
        row.id,M.name(row,T),targetName or row.targetName,row.maxHP,row.dps,row.total,row.seconds,row.events)
    local shachi=row.shachiTotal~=nil and T('杀气上限 %s | 累计削杀气 %.2f\n平均削杀气/s %.2f | 最高单次 %.2f',
        row.maxShachi and string.format('%.0f',row.maxShachi)or T('未记录'),row.shachiTotal,row.shachiDps,row.shachiMaximum)or T('杀气统计：未记录')
    local timer=T('计时模式：未记录')
    if row.testDuration==0 then timer=T('计时模式：不限时')
    elseif row.testDuration then
        timer=T('计时模式：%d 秒%s',row.testDuration,T(row.timerCompleted and '（已完成）'or '（未完成）'))
    end
    return details..'\n'..shachi..'\n'..timer
end
function M.compare(a,b,T)
    T=T or identity
    if not a or not b then return T('保存两段后，可选择 A 与 B 比较') end
    local difference=b.dps-a.dps
    local percent=a.dps>0 and T('（%+.2f%%）',difference/a.dps*100)or T('（A 的 DPS 为零）')
    local condition=a.maxShachi~=nil and b.maxShachi~=nil and a.healthPolicy~=nil and b.healthPolicy~=nil and
        a.shachiPolicy~=nil and b.shachiPolicy~=nil and a.testDuration~=nil and b.testDuration~=nil
    for _,key in ipairs({'targetId','maxHP','maxShachi','mode','healthPolicy','shachiPolicy','level','difficulty','profile','testDuration','timerCompleted'})do
        if a[key]~=b[key]then condition=false end
    end
    local shachi=T('削杀气比较：未记录')
    if a.shachiDps~=nil and b.shachiDps~=nil then
        local change=b.shachiDps-a.shachiDps
        local ratio=a.shachiDps>0 and T('（%+.2f%%）',change/a.shachiDps*100)or T('（A 的削杀气为零）')
        shachi=T('B 相比 A：削杀气/s %+.2f %s',change,ratio)
    end
    return T('B 相比 A：DPS %+.2f %s\n%s',difference,percent,shachi)..'\n'..
        T(condition and '目标、资源与计时设置相同；请保持其他测试条件一致' or
            '目标、资源、模式或计时设置不同或未记录，比较时请注意条件差异')
end
return M
