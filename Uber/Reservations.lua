local U=Uber
local function now()return GetServerTime()end
local function same(a,b)return U.NameKey(a)==U.NameKey(b)end
function U:Reservations()self.db.reservations=type(self.db.reservations)=='table'and self.db.reservations or {};return self.db.reservations end
function U:ParseBookingTime(text)
 if text==""then return nil end
 if type(text)~="string"then return false end
 local y,m,d,h,n=text:match("^(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d)$")
 if not y or not time or not date then return false end
 y,m,d,h,n=tonumber(y),tonumber(m),tonumber(d),tonumber(h),tonumber(n)
 if m<1 or m>12 or d<1 or d>31 or h>23 or n>59 then return false end
 local ok,t=pcall(time,{year=y,month=m,day=d,hour=h,min=n,sec=0})
 if not ok or not t or date("%Y-%m-%d %H:%M",t)~=text or t<now()+300 or t>now()+30*86400 then return false end
 return t
end
local request=U.Request
function U:Request(destination,join,details)
 details=details or {};local at=details.scheduledAt or self.bookingTime
 if at and (type(at)~="number"or at~=at or at%1~=0 or at<now()+300 or at>now()+30*86400 or join)then return false end
 if not self:Approved(self.db.provider)then return false end
 if not self:ProviderLive(self.db.provider)then
  if not at then self:Notice("Provider offline. Choose a date/time up to 30 days ahead; delivery and acceptance are pending.");return false end
  if type(destination)~="string"or #destination==0 or #destination>100 or destination:find("[%c|]")then return false end
  local pending=self:Reservations();local n=0;for _ in pairs(pending)do n=n+1 end;if n>=100 then return false end
  local outboxCount=0;for _ in pairs(self.db.outbox)do outboxCount=outboxCount+1 end;if outboxCount>=100 then return false end
  if now()-(self.requestAt or 0)<15 then return false end
  local options=self.bookingOptions or {};local copy={party=details.party,supplies=details.supplies,note=details.note,tip=details.tip or options.tip or 0,priority=details.priority==true or options.priority==true,portals=details.portals or options.portals or 1,scheduledAt=at}
  if copy.note and (type(copy.note)~="string"or #copy.note>480 or copy.note:find("[%c|]"))then return false end
  if copy.supplies and (type(copy.supplies)~="string"or #copy.supplies>120 or copy.supplies:find("[%c|]"))then return false end
  local party=tonumber(copy.party or 1);if not party or party~=party or party%1~=0 or party<1 or party>40 then return false end
  copy.party=party
  for _,v in ipairs({copy.tip,copy.portals})do if type(v)~="number"or v~=v or v<0 or v%1~=0 then return false end end
  if copy.tip>100000000 or copy.portals<1 or copy.portals>40 then return false end
  local id=self:ID();pending[id]={id=id,provider=self.db.provider,destination=destination,details=copy,scheduledAt=at,at=now(),status="LOCAL ONLY — provider offline; not delivered"}
  self.requestAt=now()
  self.db.outbox[id]=pending[id];self:Audit("RESERVATION_QUEUED",self.db.provider,destination);self:Notice("Saved on this character. Provider offline: not delivered or accepted. Keep Uber running to send when they return.");return id
 end
 local id=request(self,destination,join,details)
 if id and at then self.db.outbox[id].scheduledAt=at;self:Send({"TIME4",id,tostring(at)},self.db.provider)end
 if id then self:Audit("ORDER_SENT",self.db.provider,id)end
 return id
end
function U:CancelReservation(id)
 local r=self:Reservations()[id];if not r or r.deliveredID then return false end
 self:Reservations()[id]=nil;self.db.outbox[id]=nil;self:Audit("RESERVATION_CANCELLED",r.provider,id);return true
end
local tick=U.Tick
function U:Tick()
 tick(self);if not self.db or now()-(self.reservationTick or 0)<5 then return end;self.reservationTick=now()
 local awaiting=false;for _,r in pairs(self:Reservations())do if not r.deliveredID and r.scheduledAt>now()+300 then awaiting=true;break end end
 if awaiting and now()-(self.reservationDiscover or 0)>=60 then self.reservationDiscover=now();self:DiscoverDrivers()end
 for id,r in pairs(self:Reservations())do
  if not r.deliveredID and r.scheduledAt<=now()+300 then r.status="EXPIRED — not delivered in time"
  elseif not r.deliveredID and self:Approved(r.provider)and self:ProviderLive(r.provider)and (not self.CanBookDriver or self:CanBookDriver(r.provider))and #self.queue<70 then
   local saved,at=self.db.provider,self.bookingTime;self.db.provider=r.provider;self.bookingTime=nil
   local sent=self:Request(r.destination,nil,r.details);self.db.provider=saved;self.bookingTime=at
   if sent then r.deliveredID=sent;r.status="Sent — awaiting provider receipt / acceptance";return end
  elseif r.deliveredID then
   local sent=self.db.outbox[r.deliveredID];if sent then r.status=sent.status end
  end
 end
end
local accept=U.Accept
function U:Accept(id,minutes)
 local r=self.db.inbox[id]
 if r and r.scheduledAt and r.scheduledAt>now()+900 then
  if not self.online or not self:Approved(GetUnitName("player",true))or (r.status~="New"and r.status~="Reserved")then return false end
  if not tonumber(minutes)or tonumber(minutes)<0 or tonumber(minutes)>1440 then return false end
  r.status="Reserved";self:Send({"RESERVED4",r.request,tostring(r.scheduledAt)},r.sender)
  self:Audit("RESERVATION_CONFIRMED",r.sender,r.request);self:Notice("Advance reservation confirmed. Select it again near the scheduled time to start setup.");return true
 end
 if r and r.status=="Reserved"then r.status="New"end
 return accept(self,id,minutes)
end
local receive=U.Receive
function U:Receive(text,sender,channel)
 if type(text)~="string"or #text>240 or text:find("[%c]")or type(sender)~="string"then return end
 local p={};for v in (text.."|"):gmatch("(.-)|")do p[#p+1]=v end
 if p[1]=="TIME4"then
  local r=self.db.inbox[sender..":"..(p[2]or "")];local at=tonumber(p[3])
  if channel~="WHISPER"or #p~=3 or not r or r.status~="New"or not at or at~=at or at%1~=0 or at<now()+240 or at>now()+30*86400 then return end
  if r.scheduledAt and r.scheduledAt~=at then return end;r.scheduledAt=at;self:Audit("RESERVATION_RECEIVED",sender,r.request);self:Refresh();return
 elseif p[1]=="RESERVED4"then
  local r=self.db.outbox[p[2]]
  if channel=="WHISPER"and #p==3 and r and same(r.provider,sender)and r.scheduledAt==tonumber(p[3])then r.status="Advance reservation accepted";self:Refresh()end;return
 end
 receive(self,text,sender,channel)
end
