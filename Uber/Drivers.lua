local U=Uber
local function key(n)
    if type(n)~="string"then return ""end
    if not n:find("-",1,true)then n=n.."-"..(GetNormalizedRealmName and GetNormalizedRealmName()or GetRealmName and GetRealmName()or "")end
    return n:lower()
end
function U:IsDispatcher()return key(GetUnitName("player",true))==key(self.db.dispatcher)and self.db.dispatcher~=""end
function U:DriverDB()
    self.db.dispatcher=self.db.dispatcher or "";self.db.drivers=self.db.drivers or {};self.db.applications=self.db.applications or {}
end
function U:Approved(who)
    self:DriverDB();local r=self.db.drivers[key(who)]
    return r and r.approved and key(r.authority)==key(self.db.dispatcher)and self.db.dispatcher~=""
end
function U:DriverClass(who)
    self:DriverDB();local r=self.db.drivers[key(who)]
    return r and r.class=="MAGE"and "MAGE"or "WARLOCK"
end
function U:ApplyDriver(note)
    self:DriverDB()
    if self.db.dispatcher==""or type(note)~="string"or #note>160 or note:find("[%c|]")then return false end
    local _,class=UnitClass("player");if class~="WARLOCK"and class~="MAGE"then return false end
    if GetServerTime()-(self.appliedAt or 0)<60 then return false end
    self.appliedAt=GetServerTime()
    return self:Send({"APPLY",note~=""and note or "Travel provider application",class},self.db.dispatcher)
end
function U:ReviewDriver(who,approve)
    self:DriverDB();if not self:IsDispatcher()or not self.db.applications[key(who)]then return false end
    local r={name=who,approved=approve,authority=self.db.dispatcher,at=GetServerTime(),class=self.db.applications[key(who)].class or "WARLOCK"}
    self.db.drivers[key(who)]=r;self.db.applications[key(who)].status=approve and "Approved"or "Declined / revoked"
    self:Send({"DRIVER",who,approve and "1"or "0",tostring(r.at),r.class},who)
    if IsInGuild and IsInGuild()then self:Send({"DRIVER",who,approve and "1"or "0",tostring(r.at),r.class},nil,"GUILD")end
    self:Refresh();return true
end
function U:OpenService()
    if self.online then self.online=false;if self.db.active then self.db.active.status="CANCELLED";self:Publish()end;self:Refresh();return true end
    local _,class=UnitClass("player")
    if (class~="WARLOCK"and class~="MAGE")or not self:Approved(GetUnitName("player",true))or self:DriverClass(GetUnitName("player",true))~=class then return false end
    self.online=true;self:Refresh();return true
end
local init=U.Init
function U:Init()init(self);self:DriverDB()end
local receive=U.Receive
function U:Receive(text,sender,channel)
    self:DriverDB()
    if type(text)~="string"or #text>240 or text:find("[%c]")or type(sender)~="string"or #sender>100 then return end
    local p={};for s in (text.."|"):gmatch("(.-)|")do p[#p+1]=s end
    if p[1]=="APPLY"then
        if not self:IsDispatcher()or channel~="WHISPER"or (#p~=2 and #p~=3)or #p[2]>160 or (p[3]and p[3]~="WARLOCK"and p[3]~="MAGE")then return end
        if not self.db.applications[key(sender)]and (function()local n=0;for _ in pairs(self.db.applications)do n=n+1 end;return n end)()>=100 then return end
        local old=self.db.applications[key(sender)];if old and GetServerTime()-old.at<60 then return end
        self.db.applications[key(sender)]={name=sender,note=p[2],class=p[3]or "WARLOCK",at=GetServerTime(),status="Needs review"}
        self:Refresh();return
    elseif p[1]=="DRIVER"then
        if key(sender)~=key(self.db.dispatcher)or self.db.dispatcher==""or (#p~=4 and #p~=5)or #p[2]>100 or p[2]:find("[%c|]")or (p[3]~="1"and p[3]~="0")or (p[5]and p[5]~="WARLOCK"and p[5]~="MAGE")then return end
        local at=tonumber(p[4]);if not at or at~=at or at<0 or at>GetServerTime()+60 then return end
        local old=self.db.drivers[key(p[2])];if old and old.at>at then return end
        self.db.drivers[key(p[2])]={name=p[2],approved=p[3]=="1",authority=self.db.dispatcher,class=p[5]or "WARLOCK",at=at}
        if key(p[2])==key(GetUnitName("player",true))and p[3]=="0"then self.online=false end
        self:Refresh();return
    elseif p[1]=="ROSTER"then
        if self:IsDispatcher()and channel=="WHISPER"and GetServerTime()-(self.last[sender.."roster"]or 0)>=30 then
            self.last[sender.."roster"]=GetServerTime()
            for _,r in pairs(self.db.drivers)do self:Send({"DRIVER",r.name,r.approved and "1"or "0",tostring(r.at),r.class or "WARLOCK"},sender)end
        end
        return
    end
    if p[1]=="S"and not self:Approved(sender)then return end
    receive(self,text,sender,channel)
end
local request=U.Request
function U:Request(...)
    if not self:Approved(self.db.provider)then return false end
    return request(self,...)
end
