local U=Uber
local function clean(s,n)
    return type(s)=="string" and #s<=n and not s:find("[%c|]") and s or nil
end
local function same(a,b)
    local function full(n)if n and not n:find("-",1,true)then n=n.."-"..(GetNormalizedRealmName and GetNormalizedRealmName()or GetRealmName and GetRealmName()or "")end;return n and n:lower()end
    return a and b and full(a)==full(b)
end
local function clock()return GetServerTime()end
U.statusLabels={REQUESTED="Request received",ACCEPTED="Order accepted",TRAVELING="On the way",SETTING_UP="Setting up camp",READY="Service open",PAUSED="Camp paused",COMPLETE="Camp complete",CANCELLED="Cancelled"}
U.services={"Food","Water","Campfire","Buffs","Quests","PvP FOB"}
local oldRequest=U.Request
function U:Request(destination,join,details)
    details=details or {};local note=clean(details.note or "",480);local supplies=clean(details.supplies or "",120)
    local party=tonumber(details.party or 1)
    if not note or not supplies or not party or party%1~=0 or party<1 or party>40 or #self.queue>90 then return false end
    if clock()-(self.requestAt or 0)<15 then return false end
    local id=oldRequest(self,destination,join);if not id then return false end
    self.requestAt=clock();self.db.outbox[id].details={note=note,supplies=supplies,party=party}
    -- Small, ordered, bounded fields; no arbitrary deserialization or executable payloads.
    self:Send({"D",id,"party",tostring(party)},self.db.provider)
    self:Send({"D",id,"supplies",supplies~="" and supplies or "-"},self.db.provider)
    for i=1,3 do self:Send({"D",id,"note"..i,note:sub((i-1)*160+1,i*160)~="" and note:sub((i-1)*160+1,i*160)or "-"},self.db.provider)end
    return id
end
function U:Current()return self.online and self.db.active or self.db.orders[self.db.provider]end
function U:IsFresh(o)return o and o.updated and clock()-o.updated<=120 end
function U:SummonNow()
    if not self:Approved(self.db.provider)then return false end
    local o=self.db.orders[self.db.provider]
    if not self:IsFresh(o)or o.status~="READY" or clock()-(self.summonAt or 0)<30 then return false end
    local member=false
    for _,r in pairs(self.db.outbox)do if same(r.provider,self.db.provider)and (r.join==o.id or r.destination==o.destination)and r.status=="READY"then member=true end end
    if not member then return false end
    local send=SendChatMessage or C_ChatInfo and C_ChatInfo.SendChatMessage
    if not send then return false end
    local action=self:DriverClass(self.db.provider)=="MAGE"and "Portal now!"or "Summon now!"
    local ok,result=pcall(send,action.." I'm ready for "..o.destination..". [Uber]","WHISPER",nil,self.db.provider)
    if ok and result~=false then self.summonAt=clock();return true end
    return false
end
local receive=U.Receive
function U:Receive(text,sender,channel)
    if type(text)~="string"or #text>240 or text:find("[%c]")or not clean(sender,100)then return end
    local p={};for s in (text.."|"):gmatch("(.-)|")do p[#p+1]=s end
    if p[1]=="D" then
        local r=self.online and self.db.inbox[sender..":"..(p[2]or "")]
        if not r or channel~="WHISPER"or #p~=4 or clock()-r.at>120 then return end
        r.details=r.details or {};local v=p[4]=="-"and ""or p[4]
        if p[3]=="party" then local n=tonumber(v);if n and n%1==0 and n>=1 and n<=40 then r.details.party=n end
        elseif p[3]=="supplies" and clean(v,120)then r.details.supplies=v
        elseif p[3]:match("^note[123]$")and clean(v,160)then
            r.details[p[3]]=v;r.details.note=(r.details.note1 or "")..(r.details.note2 or "")..(r.details.note3 or "")
        end
        self:Refresh();return
    end
    receive(self,text,sender,channel)
end
function U:SetStatus(status,minutes)
    local o=self.db.active;minutes=tonumber(minutes)
    if not self.online or not o or not self.statusLabels[status]or not minutes or minutes~=minutes or minutes<0 or minutes>1440 then return false end
    o.status=status;o.eta=clock()+math.floor(minutes*60);self:Publish();self:Refresh();return true
end
