local U={prefix="UBERSUM1",queue={},seen={},last={}}
_G.Uber=U
local states={ACCEPTED=true,TRAVELING=true,PAUSED=true,REQUESTED=true,SETTING_UP=true,READY=true,COMPLETE=true,CANCELLED=true}
local function safe(s,max)
    return type(s)=="string" and #s>0 and #s<=(max or 100) and not s:find("[%c|]") and s or nil
end
local function now()return GetServerTime()end
local function name()return GetUnitName("player",true)end
local function identity(n)
    if type(n)~="string"then return ""end
    if not n:find("-",1,true)then n=n.."-"..(GetNormalizedRealmName and GetNormalizedRealmName()or GetRealmName and GetRealmName()or "")end
    return n:lower()
end
local function same(a,b)return a and b and identity(a)==identity(b)end
local function tell(s)if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Uber: "..s)end end
local function fields(s)local t={};for v in (s.."|"):gmatch("(.-)|")do t[#t+1]=v end;return t end
local function count(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
function U:Init()
    UberDB=type(UberDB)=='table'and UberDB or {};self.db=UberDB
    self.db.provider=type(self.db.provider)=='string'and self.db.provider or ''
    for _,field in ipairs({'inbox','orders','outbox'})do if type(self.db[field])~='table'then self.db[field]={}end end
    self.db.serial=type(self.db.serial)=='number'and self.db.serial==self.db.serial and self.db.serial>=0 and self.db.serial<1000000000000 and math.floor(self.db.serial)or 0
    -- Provider availability always requires an explicit click after login.
    self.online=false
    local register=C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
    self.transportAvailable=register and pcall(register,self.prefix)or false
end
function U:ID()self.db.serial=self.db.serial+1;return tostring(now()).."-"..self.db.serial end
function U:Send(parts,target,channel)
    local text=table.concat(parts,"|")
    if #text>240 or #self.queue>=100 then tell("Network queue full or message too long.");return false end
    self.queue[#self.queue+1]={text=text,target=target,channel=channel or "WHISPER"};return true
end
function U:Tick()
    if not self.db then return end
    local p=table.remove(self.queue,1)
    if p then
        local send=C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
        if send then
            local ok,result=pcall(send,self.prefix,p.text,p.channel,p.target)
            if not ok or result==false or type(result)=="number" and result~=0 then
                -- Offline discovery peers are normal; do not turn them into visible chat spam.
                if not p.text:match("^HELLO3|")and p.text~="ADMINPING4"and p.text~="ROSTER"and not p.text:match("^ME7|")and not p.text:match("^ACK7|")and p.text~="LEAVE7"then tell("Delivery failed; refresh/retry when the recipient is online.")end
            end
        end
    end
    if self.online and self.db.active and self.db.active.status~="COMPLETE" and self.db.active.status~="CANCELLED" and now()-(self.announced or 0)>=30 and #self.queue<50 then self:Publish()end
    if now()~=(self.refreshedAt or 0)then self.refreshedAt=now();self:Refresh()end
end
function U:Request(destination,join)
    destination=safe(destination,100)
    if not destination or not safe(self.db.provider,100)then tell("Enter a provider and destination (100 bytes maximum).");return false end
    if count(self.db.outbox)>=100 then tell("Outbox full; clear old requests first.");return false end
    local id=self:ID()
    self.db.outbox[id]={destination=destination,at=now(),provider=self.db.provider,status="Awaiting receipt",join=join}
    if not self:Send({"R",id,join or "-",destination},self.db.provider)then self.db.outbox[id]=nil;return false end
    return id
end
function U:Location()
    if not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetPlayerMapPosition then return "0","0","0" end
    local ok,map=pcall(C_Map.GetBestMapForUnit,"player")
    if not ok or (issecretvalue and issecretvalue(map))or type(map)~="number"or map~=map or map<=0 or map%1~=0 then return "0","0","0" end
    local good,pos=pcall(C_Map.GetPlayerMapPosition,map,"player")
    if not good or not pos or not pos.GetXY then return "0","0","0" end
    local valid,x,y=pcall(pos.GetXY,pos)
    if not valid or (issecretvalue and (issecretvalue(x)or issecretvalue(y)))or type(x)~="number"or type(y)~="number"or x~=x or y~=y or x<0 or x>1 or y<0 or y>1 then return "0","0","0" end
    return tostring(map),tostring(math.floor(x*10000)),tostring(math.floor(y*10000))
end
function U:Publish(target)
    local o=self.db.active;if not o then return end
    local map,x,y=self:Location();o.map,o.x,o.y=tonumber(map),tonumber(x)/10000,tonumber(y)/10000
    o.updated=now();self.announced=now()
    local packet={"S",o.id,o.status,tostring(o.eta),o.destination,map,x,y,tostring(o.updated)}
    if target then self:Send(packet,target);return end
    if IsInGuild and IsInGuild()then self:Send(packet,nil,"GUILD")end
    for who in pairs(o.riders)do if not same(who,name())then self:Send(packet,who)end end
end
function U:SetStatus(status,minutes)
    local o=self.db.active;minutes=tonumber(minutes)
    if not self.online or not o or not states[status] or not minutes or minutes<0 or minutes>1440 then return false end
    o.status=status;o.eta=now()+math.floor(minutes*60);self:Publish();self:Refresh();return true
end
function U:Accept(id,minutes)
    local r=self.db.inbox[id]
    minutes=tonumber(minutes);if not minutes or minutes~=minutes or minutes<0 or minutes>1440 then return false end
    if not self.online or not r or r.status~="New" or r.join~="-" then return false end
    local old=self.db.active
    if old and old.status~="COMPLETE" and old.status~="CANCELLED" then tell("Complete or cancel your current camp first.");return false end
    self.db.active={id=self:ID(),destination=r.destination,status="REQUESTED",eta=now(),riders={[r.sender]=true}}
    r.status="Accepted";return self:SetStatus("SETTING_UP",minutes)
end
function U:Receive(text,sender,channel)
    if type(text)~="string" or #text>240 or text:find("[%c]")or not safe(sender,100)then return end
    local p=fields(text);local kind=p[1]
    if kind=="S" then
        -- Status authority is the provider selected by this client, never payload text.
        if not same(sender,self.db.provider)or #p~=9 or not safe(p[2],40)or not states[p[3]]or not safe(p[5],100)then return end
        local eta,map,x,y,updated=tonumber(p[4]),tonumber(p[6]),tonumber(p[7]),tonumber(p[8]),tonumber(p[9])
        if not eta or not map or not x or not y or not updated or eta~=eta or map~=map or x~=x or y~=y or updated~=updated or x<0 or x>10000 or y<0 or y>10000 or map<0 or map%1~=0 or updated>now()+60 or updated<now()-3600 or eta>now()+86460 then return end
        local old=self.db.orders[self.db.provider];if old and updated<old.updated then return end
        self.db.orders[self.db.provider]={id=p[2],status=p[3],eta=eta,destination=p[5],map=map,x=x/10000,y=y/10000,updated=updated}
        for _,r in pairs(self.db.outbox)do if same(r.provider,sender)and (r.camp==p[2]or r.join==p[2]or not r.scheduledAt and not r.camp and r.destination==p[5])then r.status=p[3]end end
    elseif kind=="A" then
        local r=self.db.outbox[p[2]]
        if #p==3 and r and same(sender,r.provider)and r.status=="Awaiting receipt"then r.status=p[3]=="OK" and "Received by provider" or "Rejected / camp unavailable" end
    elseif kind=="Q" then
        if self.online and now()-(self.last[sender.."Q"]or 0)>=10 then self.last[sender.."Q"]=now();self:Publish(sender)end
    elseif kind=="R" and channel=="WHISPER" and self.online then
        if (#p~=4 and not (#p==5 and p[5]=="3"))or not safe(p[2],40)or not p[2]:match("^[%d%-]+$")or not safe(p[4],100)then return end
        local id=sender..":"..p[2]
        if self.db.inbox[id]then if now()-(self.last[id]or 0)>=15 then self.last[id]=now();self:Send({"A",p[2],"OK"},sender)end;return end
        if now()-(self.last[sender]or 0)<15 or count(self.db.inbox)>=100 then return end
        self.last[sender]=now()
        if p[3]~="-" then
            local o=self.db.active
            if not o or o.id~=p[3]or o.status=="COMPLETE"or o.status=="CANCELLED"or count(o.riders)>=40 then self:Send({"A",p[2],"NO"},sender);return end
            o.riders[sender]=true;self:Publish(sender)
        end
        self.db.inbox[id]={sender=sender,destination=p[4],join=p[3],at=now(),status=p[3]=="-"and "New"or "Joined",request=p[2],protocol=p[5]=="3"and 3 or nil}
        self:Send({"A",p[2],"OK"},sender);tell("New summons request from "..sender..". Open /uber.")
    end
    self:Refresh()
end
function U:Map()
    local o=self.online and self.db.active or self.db.orders[self.db.provider]
    if not o or now()-o.updated>120 or o.map<=0 then tell("No fresh provider location. Refresh while they are online.");return end
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint then C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(o.map,o.x,o.y))end
    if WorldMapFrame and WorldMapFrame.SetMapID then WorldMapFrame:Show();WorldMapFrame:SetMapID(o.map)end
end
local frame=CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED");frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent",function(_,event,...)
    if event=="ADDON_LOADED"then if (...)=="Uber"then U:Init()end
    else local prefix,text,channel,sender=...;if prefix==U.prefix and U.db then U:Receive(text,sender,channel)end end
end)
local elapsed=0
frame:SetScript("OnUpdate",function(_,dt)elapsed=elapsed+dt;if elapsed>=0.25 then elapsed=0;U:Tick()end end)
SLASH_UBER1="/uber";SlashCmdList.UBER=function()U:Show()end
