local U=Uber
local function now()return GetServerTime()end
local function key(n)
 if type(n)~="string"then return ""end
 if not n:find("-",1,true)then n=n.."-"..(GetNormalizedRealmName and GetNormalizedRealmName()or GetRealmName and GetRealmName()or "")end
 return n:lower()
end
local function realm()return GetRealmName and GetRealmName()or GetNormalizedRealmName and GetNormalizedRealmName()or "Local realm"end
local function clean(v,n)return type(v)=="string"and #v>0 and #v<=n and not v:find("[%c|]")and v end
local function integer(v,max)local n=tonumber(v);return n and n==n and n>=0 and n<=max and n%1==0 and n end
U.NameKey=key
function U:Network()
 self.peers=self.peers or {};self.subscribers=self.subscribers or {}
 self.db.realmServices=self.db.realmServices or {}
 local id=realm();self.db.realmServices[id]=self.db.realmServices[id]or {house="Bifrost Titan",profiles={}}
 local settings=self.db.realmServices[id];settings.profiles=settings.profiles or {}
 local who=key(GetUnitName("player",true));settings.profiles[who]=settings.profiles[who]or {standard=settings.standard or 0,priority=settings.priority or 0}
 local profile=settings.profiles[who];profile.house=settings.house or "Bifrost Titan"
 return profile,id
end
function U:Money(copper)
 copper=math.floor(tonumber(copper)or 0)
 return ("%dg %ds %dc"):format(math.floor(copper/10000),math.floor(copper%10000/100),copper%100)
end
function U:PortalCost(who)return self:DriverClass(who)=="MAGE"and 2200 or 0 end
function U:Gold(text)
 if type(text)~="string"or not text:match("^%d+%.?%d?%d?%d?%d?$")then return nil end
 local whole,fraction=text:match("^(%d+)%.?(%d*)$")
 local n=tonumber(whole)*10000+tonumber((fraction.."0000"):sub(1,4))
 return integer(n,100000000)
end
function U:SavePrices(standard,priority,house)
 local a,b=self:Gold(standard),self:Gold(priority)
 if not a or not b or not clean(house,60)or house:find("[/\\]")then return false end
 local p,id=self:Network()
 if house~=p.house and not self:IsDispatcher()then return false end
 p.standard,p.priority=a,b;self.db.realmServices[id].house=house;p.house=house
 if self.online then self:Advertise()end
 return true
end
function U:PresencePacket()
 local prices,id=self:Network()
 local state=self.online and "AVAILABLE"or "OFFLINE"
 if self.online and self.db.active and self.db.active.status~="COMPLETE"and self.db.active.status~="CANCELLED"then state=self.db.active.status end
 return {"H3",id,self.online and "1"or "0",tostring(prices.standard+self:PortalCost(GetUnitName("player",true))),tostring(prices.priority),state,tostring(now())}
end
function U:Advertise(target)
 self:Network();local packet=self:PresencePacket()
 if target then self:Send(packet,target);return end
 self.presenceAt=now()
 if IsInGuild and IsInGuild()then self:Send(packet,nil,"GUILD")end
 for who,at in pairs(self.subscribers)do
  if now()-at>180 then self.subscribers[who]=nil else self:Send(packet,who)end
 end
end
function U:DiscoverDrivers(force)
 self:Network()
 if now()-(self.discoveredAt or 0)<(force and 10 or 30)then return false end
 self.discoveredAt=now();local _,id=self:Network()
 for _,r in pairs(self.db.drivers or {})do
  if self:Approved(r.name)and #self.queue<85 then self:Send({"HELLO3",id},r.name)end
 end
 return true
end
function U:ActiveDrivers()
 self:Network();local list,seen={},{};local mine=GetUnitName("player",true)
 for _,r in pairs(self.db.drivers or {})do
  local p=self.peers[key(r.name)]
  if key(r.name)~=key(mine)and not seen[key(r.name)]and self:Approved(r.name)and p and p.online and now()-p.at<=90 then seen[key(r.name)]=true;list[#list+1]=r.name end
 end
 if self.online and self:Approved(GetUnitName("player",true))then
  local mine=GetUnitName("player",true);local exists=false;for _,n in ipairs(list)do if key(n)==key(mine)then exists=true end end
  if not exists then list[#list+1]=mine end
 end
 table.sort(list);return list
end
function U:AvailabilityMessage()
 if #self:ActiveDrivers()>0 then return "Active drivers publish their own status. Your dispatcher does not need to stay online." end
 if self.discoveredAt and now()-self.discoveredAt<8 then return "Checking your driver directory for available providers…"end
 return "No active drivers found in your Uber network on this realm. Come back later and check who is available."
end
local open=U.OpenService
function U:OpenService()
 local result=open(self)
 if result then self:Advertise();self:Refresh()end
 return result
end
local tick=U.Tick
function U:Tick()
 tick(self);if not self.db then return end;self:Network()
 if self.online and now()-(self.presenceAt or 0)>=30 and #self.queue<40 then self:Advertise()end
 if self.frame and self.frame:IsShown()and now()-(self.discoveredAt or 0)>=45 then self:DiscoverDrivers()end
end
local receive=U.Receive
function U:Receive(text,sender,channel)
 if type(text)~="string"or #text>240 or text:find("[%c]")or not clean(sender,100)then return end
 local p={};for v in (text.."|"):gmatch("(.-)|")do p[#p+1]=v end
 local _,id=self:Network()
 if p[1]=="HELLO3"then
  if channel~="WHISPER"or #p~=2 or p[2]~=id or not self:Approved(GetUnitName("player",true))then return end
  if now()-(self.last[sender.."hello"]or 0)<10 then return end
  self.last[sender.."hello"]=now();local total=0;for _ in pairs(self.subscribers)do total=total+1 end
  if self.subscribers[sender]or total<100 then self.subscribers[sender]=now()end
  self:Advertise(sender);if self.online and self.db.active then self:Publish(sender)end;return
 elseif p[1]=="H3"then
  if #p~=7 or p[2]~=id or not self:Approved(sender)or (p[3]~="0"and p[3]~="1")then return end
  local base,priority,at=integer(p[4],100000000),integer(p[5],100000000),integer(p[7],9999999999)
  if not base or not priority or not at or at>now()+10 or at<now()-90 or (p[6]~="AVAILABLE"and p[6]~="OFFLINE"and not self.statusLabels[p[6]])then return end
  if base<self:PortalCost(sender)then return end
  local old=self.peers[key(sender)];if old and at<old.at then return end
  self.peers[key(sender)]={online=p[3]=="1",standard=base,priority=priority,state=p[6],at=at}
  self:Refresh();return
 elseif p[1]=="S"and self:Approved(sender)then
  -- Cache every approved driver's state, not just the currently selected card.
  local saved=self.db.provider;self.db.provider=sender;receive(self,text,sender,channel)
  local order=self.db.orders[sender];self.db.provider=saved
  if order and key(sender)==key(saved)then self.db.orders[saved]=order end
  self:Refresh();return
 end
 receive(self,text,sender,channel)
end
