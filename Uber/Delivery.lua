local U=Uber
local function now()return GetServerTime()end
local function me()return GetUnitName("player",true)end
local function same(a,b)return U.NameKey(a)==U.NameKey(b)end
local function public(v)return not issecretvalue or not issecretvalue(v)end
local function integer(s,max)local n=tonumber(s);return n and n==n and n>=0 and n<=max and n%1==0 and n end
-- Explicit spell IDs avoid localized name guessing and unrelated teleports.
local portals={ [10059]={[84]=true,[1453]=true},[11416]={[87]=true,[1455]=true},[11419]={[89]=true,[1457]=true},[11417]={[85]=true,[1454]=true},[11418]={[90]=true,[1458]=true},[11420]={[88]=true,[1456]=true},[32266]={[103]=true,[1947]=true},[32267]={[110]=true,[1954]=true},[33691]={[111]=true,[1955]=true},[35717]={[111]=true,[1955]=true},[53142]={[125]=true,[126]=true},[88345]={},[88346]={} }
local summons={[698]=true,[7720]=true}
function U:InServiceParty(who)
 if same(who,me())then return true end
 local total=GetNumGroupMembers and GetNumGroupMembers()or 0
 local raid=IsInRaid and IsInRaid()
 for i=1,math.min(40,total)do
  local unit=(raid and "raid"or "party")..i
  local n=GetUnitName(unit,true)
  if public(n)and type(n)=="string"and same(who,n)then return true end
 end
 return false
end
function U:EvidenceDB()
 self.db.delivery=self.db.delivery or {};self.db.adminReports=self.db.adminReports or {};self.db.receiptArchive=self.db.receiptArchive or {}
 return self.db.delivery
end
function U:Evidence(kind,order,subject,detail)
 self:EvidenceDB();local records=self.db.delivery
 local e={id=self:ID(),at=now(),kind=kind,order=order or "-",subject=subject or me(),detail=detail or "",source=me()}
 records[#records+1]=e;while #records>2000 do table.remove(records,1)end
 if not self:IsDispatcher()then
  local pending=self.db.adminReports
  if #pending<300 then pending[#pending+1]=e end
 end
 self:Audit(kind,e.subject,e.order.." "..e.detail);return e
end
function U:ObserveServiceCast(spell,castGUID)
 if not public(spell)or not public(castGUID)or not self.online or not self:Approved(me())or not (portals[spell]or summons[spell])then return false end
 if portals[spell]and self:DriverClass(me())~="MAGE"or summons[spell]and self:DriverClass(me())~="WARLOCK"then return false end
 if self.lastCastGUID==castGUID and castGUID then return false end;self.lastCastGUID=castGUID
 local a=self.db.active;local active=a and a.status~="COMPLETE"and a.status~="CANCELLED"and a
 local target=self.serviceCastTarget and self.serviceCastTarget.guid==castGUID and self.serviceCastTarget.target
 local event=self:Evidence(portals[spell]and "PORTAL_CAST"or "SUMMON_CAST",active and active.id or "-",target or me(),tostring(spell))
 local map,x,y=self:Location()
 event.spellID=spell;event.castGUID=castGUID;event.target=target;event.map=tonumber(map);event.x=tonumber(x);event.y=tonumber(y)
 event.serviceOpen=true;event.providerClass=self:DriverClass(me());event.policyRevision=self:ProviderPolicy(me()).revision
 event.quote=active and active.billingQuote
 if UnitGUID then local ok,guid=pcall(UnitGUID,"player");if ok and public(guid)then event.casterGUID=guid end end
 if active then
  active.deliveryCasts=active.deliveryCasts or {};active.deliveryCasts[event.id]={at=now(),spell=spell,map=tonumber(map),x=tonumber(x),y=tonumber(y)}
  -- Bound repeated casts per camp; evidence archive keeps the full retained history.
  local count,oldest,oldAt=0,nil,math.huge
  for id,c in pairs(active.deliveryCasts)do count=count+1;if c.at<oldAt then oldest,oldAt=id,c.at end end
  if count>80 then active.deliveryCasts[oldest]=nil end
  for rider in pairs(active.riders or {})do if self:InServiceParty(rider)and (not summons[spell]or not target or same(target,rider))then self:Send({"CAST4",active.id,event.id,tostring(spell),map,x,y,tostring(now())},rider)end end
 end
 -- Walk-up party customers can supply arrival evidence without pretending an order/payment exists.
 self.partyCasts=self.partyCasts or {};local session={at=now(),spell=spell,map=tonumber(map),x=tonumber(x),y=tonumber(y),members={},arrived={}}
 for id,c in pairs(self.partyCasts)do if now()-c.at>180 then self.partyCasts[id]=nil end end
 local group=GetNumGroupMembers and GetNumGroupMembers()or 0;local raid=IsInRaid and IsInRaid()
 for i=1,math.min(40,group)do
  local rider=GetUnitName((raid and "raid"or "party")..i,true)
  if public(rider)and type(rider)=="string"and not same(rider,me())and not (active and active.riders[rider])and (not summons[spell]or not target or same(target,rider))then
   session.members[rider]=true
   if #self.queue<85 then self:Send({"PARTYCAST4",event.id,event.id,tostring(spell),map,x,y,tostring(now())},rider)end
  end
 end
 if next(session.members)then
  local count=0;for _ in pairs(self.partyCasts)do count=count+1 end
  if count<80 then self.partyCasts[event.id]=session end
 end
 return true
end
function U:ObserveTravel(initial,reload)
 if initial or reload or not self.travelPending then return false end
 local p=self.travelPending;if now()-p.at>180 then self.travelPending=nil;return false end
 if summons[p.spell]and not p.summonConfirmed then return false end
 local map,x,y=self:Location();map,x,y=tonumber(map),tonumber(x),tonumber(y)
 local before=p.before
 if map==0 or not before or before.map==0 then return false end
 local moved=map~=before.map or (x-before.x)^2+(y-before.y)^2>1000000
 local destination=portals[p.spell]and portals[p.spell][map]or summons[p.spell]and map==p.map and (x-p.x)^2+(y-p.y)^2<=90000
 if not moved or not destination then return false end
 local event=self:Evidence("CUSTOMER_TRAVEL_OBSERVED",p.camp,me(),tostring(p.spell).." map "..map)
 event.spellID=p.spell;event.castID=p.cast;event.provider=p.provider;event.from=before;event.arrival={map=map,x=x,y=y};event.summonOffer=p.summonConfirmed==true
 self:Send({p.walkup and "PARTYARRIVE4"or "ARRIVE4",p.camp,p.cast,tostring(map),tostring(x),tostring(y),tostring(now()),p.summonConfirmed and "SUMMON_OFFER"or "PORTAL_TRANSITION"},p.provider)
 self.travelPending=nil;self:Notice("Travel observed; a timestamped arrival report was sent to your provider. This is client evidence, not server-certified proof.");return event
end
local receive=U.Receive
function U:Receive(text,sender,channel)
 if type(text)~="string"or #text>240 or text:find("[%c]")or type(sender)~="string"or #sender>100 then return end
 local p={};for v in (text.."|"):gmatch("(.-)|")do p[#p+1]=v end
 if p[1]=="LINK4"then
  local r=self.db.outbox[p[2]]
  if channel=="WHISPER"and #p==3 and r and same(r.provider,sender)and self:Approved(sender)and p[3]:match("^[%d%-]+$")and #p[3]<=40 then r.camp=p[3]end;return
 elseif p[1]=="CAST4"or p[1]=="PARTYCAST4"then
  if channel~="WHISPER"or #p~=8 or not self:Approved(sender)or not self:InServiceParty(sender)or not p[2]:match("^[%d%-]+$")or not p[3]:match("^[%d%-]+$")or #p[2]>40 or #p[3]>40 then return end
  local spell,map,x,y,at=integer(p[4],9999999),integer(p[5],999999),integer(p[6],10000),integer(p[7],10000),integer(p[8],9999999999)
  if not spell or not (portals[spell]or summons[spell])or not map or not x or not y or not at or math.abs(now()-at)>15 then return end
  local member=false
  for _,r in pairs(self.db.outbox)do if same(r.provider,sender)and r.status=="READY"and (r.join==p[2]or r.camp==p[2])then member=true end end
  local walkup=p[1]=="PARTYCAST4"
  if walkup and p[2]~=p[3]then return end
  if not member and not walkup then return end
  if walkup and self.travelPending and not self.travelPending.walkup then return end
  local old=self.travelPending;if old and old.cast==p[3]then return end
  local bm,bx,by=self:Location()
  self.travelPending={provider=sender,camp=p[2],cast=p[3],spell=spell,map=map,x=x,y=y,at=at,walkup=walkup,before={map=tonumber(bm),x=tonumber(bx),y=tonumber(by)}};return
 elseif p[1]=="PARTYARRIVE4"then
  local c=self.partyCasts and self.partyCasts[p[3]]
  if channel~="WHISPER"or #p~=8 or p[2]~=p[3]or not self.online or not c or not c.members[sender]or not self:InServiceParty(sender)or c.arrived[sender]then return end
  local map,x,y,at=integer(p[4],999999),integer(p[5],10000),integer(p[6],10000),integer(p[7],9999999999)
  if not map or not x or not y or not at or math.abs(now()-at)>30 or now()-c.at>180 then return end
  if not (portals[c.spell]and portals[c.spell][map]and p[8]=="PORTAL_TRANSITION"or summons[c.spell]and p[8]=="SUMMON_OFFER"and map==c.map and (x-c.x)^2+(y-c.y)^2<=90000)then return end
  c.arrived[sender]=at
  local e=self:Evidence("PARTY_TRAVEL_CORROBORATED","-",sender,tostring(c.spell).." map "..map.."; no order/payment claim")
  e.spellID=c.spell;e.castID=p[3];e.castAt=c.at;e.arrivalAt=at;e.arrival={map=map,x=x,y=y};self:Refresh();return
 elseif p[1]=="ARRIVE4"then
  local a=self.db.active;local c=a and a.deliveryCasts and a.deliveryCasts[p[3]]
  if channel~="WHISPER"or #p~=8 or not self.online or not a or a.id~=p[2]or not c or a.status~="READY"or not a.riders[sender]or not self:InServiceParty(sender)then return end
  local map,x,y,at=integer(p[4],999999),integer(p[5],10000),integer(p[6],10000),integer(p[7],9999999999)
  if not map or not x or not y or not at or math.abs(now()-at)>30 or now()-c.at>180 then return end
  if summons[c.spell]and p[8]~="SUMMON_OFFER"or portals[c.spell]and p[8]~="PORTAL_TRANSITION"then return end
  if not (portals[c.spell]and portals[c.spell][map]or summons[c.spell]and map==c.map and (x-c.x)^2+(y-c.y)^2<=90000)then return end
  a.delivered=a.delivered or {};if a.delivered[sender]then return end
  a.delivered[sender]={at=at,spell=c.spell,map=map,evidence="Cast + customer travel report"}
  local event=self:Evidence("DELIVERY_CORROBORATED",a.id,sender,tostring(c.spell).." map "..map)
  event.spellID=c.spell;event.castID=p[3];event.castAt=c.at;event.arrivalAt=at;event.arrival={map=map,x=x,y=y};event.evidence=p[8]
  for _,r in pairs(self.db.inbox)do if same(r.sender,sender)and (r.camp==a.id or r.join==a.id)then r.delivery="Delivered — customer travel reported";r.deliveredAt=at;self:Send({"DELIVERED4",r.request,a.id,tostring(at)},sender)end end
  local all=true
  for rider in pairs(a.riders)do if not a.delivered[rider]then all=false end end
  -- Party members without their own order cannot be inferred from one customer's jump.
  for _,r in pairs(self.db.inbox)do if (r.camp==a.id or r.join==a.id)and r.details and (r.details.party or 1)>1 then all=false end end
  if all and not a.sharedSession then self:SetStatus("COMPLETE",0)end
  self:Refresh();return
 elseif p[1]=="DELIVERED4"then
  local r=self.db.outbox[p[2]];local at=integer(p[4],9999999999)
  if channel=="WHISPER"and #p==4 and r and same(r.provider,sender)and (r.camp==p[3]or r.join==p[3])and at and math.abs(now()-at)<=60 then r.delivery="Delivered — party/cast/travel corroborated";r.deliveredAt=at;self:Audit("DELIVERY_ACK",sender,p[2]);self:Refresh()end;return
 elseif p[1]=="ADMINPING4"then
  if channel=="WHISPER"and #p==1 and self:IsDispatcher()and now()-(self.last[sender.."auditPing"]or 0)>=30 then self.last[sender.."auditPing"]=now();self:Send({"ADMINHERE4"},sender)end;return
 elseif p[1]=="ADMINHERE4"then
  if channel=="WHISPER"and #p==1 and same(sender,self.FOUNDER)then
   self.adminOnlineAt=now()
   if self.FlushPrivateNetworkReport then self:FlushPrivateNetworkReport()end
  end;return
 elseif p[1]=="EVIDENCE4"then
  if channel~="WHISPER"or #p~=7 or not self:IsDispatcher()or not p[2]:match("^[%d%-]+$")or #p[2]>40 or not ({PORTAL_CAST=true,SUMMON_CAST=true,SUMMON_OFFER_OBSERVED=true,CUSTOMER_TRAVEL_OBSERVED=true,DELIVERY_CORROBORATED=true,PARTY_TRAVEL_CORROBORATED=true,MAIL_OBSERVED=true})[p[3]]or #p[4]>40 or #p[5]>100 or #p[6]>70 then return end
  local at=integer(p[7],9999999999);if not at or at>now()+60 then return end
  self.db.evidenceSeen=self.db.evidenceSeen or {};local id=sender..":"..p[2]
  if not self.db.evidenceSeen[id]then
   local count=0;for _ in pairs(self.db.evidenceSeen)do count=count+1 end
   if count>=3000 then
    local oldest,oldAt=nil,math.huge
    for k,t in pairs(self.db.evidenceSeen)do if t<oldAt then oldest,oldAt=k,t end end
    if oldest then self.db.evidenceSeen[oldest]=nil end
   end
   self.db.evidenceSeen[id]=now();self:Audit("REPORT_"..p[3],p[5],p[4].." "..p[6].." (client-reported)",sender)
   if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Uber: "..sender.." reports "..p[3].." for "..p[5].." · order "..p[4].." (client-reported).")end
  end
  self:Send({"EVIDENCEACK4",p[2]},sender);return
 elseif p[1]=="EVIDENCEACK4"then
  if channel=="WHISPER"and #p==2 and same(sender,self.FOUNDER)then
   self:EvidenceDB();for i,e in ipairs(self.db.adminReports)do if e.id==p[2]then table.remove(self.db.adminReports,i);break end end
  end;return
 end
 receive(self,text,sender,channel)
 if p[1]=="R"and channel=="WHISPER"and self.online then
  local r=self.db.inbox[sender..":"..(p[2]or "")]
  if r and r.join~="-"and self.db.active and r.join==self.db.active.id then r.camp=r.join;self:Send({"LINK4",r.request,r.camp},sender)end
 end
end
local accept=U.Accept
function U:Accept(id,minutes)
 local result=accept(self,id,minutes);local r=self.db.inbox[id]
 if result and r and r.status=="Accepted"and self.db.active then r.camp=self.db.active.id;self:Send({"LINK4",r.request,r.camp},r.sender)end
 return result
end
local tick=U.Tick
function U:Tick()
 tick(self);if not self.db then return end;self:EvidenceDB()
 if self.travelPending and now()~=(self.travelTick or 0)then self.travelTick=now();self:ObserveSummonOffer();self:ObserveTravel(false,false)end
 if #self.db.adminReports==0 or #self.queue>65 then return end
 if self.RequestFounderPresence then self:RequestFounderPresence()
 elseif now()-(self.auditPingAt or 0)>=60 then self.auditPingAt=now();self:Send({"ADMINPING4"},self.FOUNDER)end
 if self.adminOnlineAt and now()-self.adminOnlineAt<90 then
  local e=self.db.adminReports[1]
  if now()-(e.sentAt or 0)>=30 then
   e.sentAt=now();self:Send({"EVIDENCE4",e.id,e.kind,e.order,e.subject,e.detail:sub(1,70),tostring(e.at)},self.FOUNDER)
  end
 end
end
function U:ArchiveMailboxReceipts()
 if not self.mailOpen or not GetInboxNumItems or not GetInboxHeaderInfo then return false end
 self:EvidenceDB();local ok,n=pcall(GetInboxNumItems);if not ok or not public(n)or not integer(n,100)then return false end
 local counts={}
 for i=1,n do
  local good,_,_,sender,subject,money,cod=pcall(GetInboxHeaderInfo,i)
  if good and public(sender)and public(subject)and public(money)and public(cod)and type(sender)=="string"and type(subject)=="string"and #sender<=100 and #subject<=100 and integer(money,300000000)and cod==0 then
   local class=subject:match("^UBER DRIVER APPLICATION (MAGE)$")or subject:match("^UBER DRIVER APPLICATION (WARLOCK)$")
   if class and self:IsDispatcher()then
    local k=self.NameKey(sender);local count=0;for _ in pairs(self.db.applications)do count=count+1 end
    if not self.db.applications[k]and count<100 then
     local note="Read original application in your mailbox."
     if GetInboxText then local valid,body=pcall(GetInboxText,i);if valid and public(body)and type(body)=="string"then note=body:gsub("[%c|]"," "):sub(1,160)end end
     self.db.applications[k]={name=sender,class=class,at=now(),status="Needs review",note=note}
     self:Audit("APPLICATION_RECEIVED",sender,class.." · native mailbox")
    end
   end
   local id,leg=subject:match("^UBER3:([%d%-]+):([HD])$")
   if id and #id<=40 then
    local signature=sender.."|"..subject.."|"..money;counts[signature]=(counts[signature]or 0)+1
    local old=self.db.receiptArchive[signature]
    local total=0;for _ in pairs(self.db.receiptArchive)do total=total+1 end
    if old or total<2000 then
     if not old or counts[signature]>old.copies then
      self.db.receiptArchive[signature]={sender=sender,subject=subject,money=money,leg=leg,order=id,at=now(),copies=counts[signature],recipient=me()}
      self:Evidence("MAIL_OBSERVED",id,sender,leg.." "..money.." copper; local inbox")
     end
    end
   end
  end
 end
 return true
end
local inbox=U.CheckOwnInbox
function U:CheckOwnInbox()local result=inbox(self);self:ArchiveMailboxReceipts();return result end
function U:ObserveSummonOffer()
 local p=self.travelPending;if not p or not summons[p.spell]or not C_SummonInfo or not C_SummonInfo.GetSummonConfirmSummoner then return false end
 if p.summonConfirmed then return true end
 local ok,who=pcall(C_SummonInfo.GetSummonConfirmSummoner)
 if not ok or not public(who)or type(who)~="string"or not same(who,p.provider)then return false end
 p.summonConfirmed=true;self:Evidence("SUMMON_OFFER_OBSERVED",p.camp,me(),"Offer from "..who);return true
end
local frame=CreateFrame("Frame")
for _,event in ipairs({"UNIT_SPELLCAST_SENT","UNIT_SPELLCAST_SUCCEEDED","PLAYER_ENTERING_WORLD","MAIL_INBOX_UPDATE","CONFIRM_SUMMON"})do pcall(frame.RegisterEvent,frame,event)end
frame:SetScript("OnEvent",function(_,event,...)
 if not U.db then return end
 if event=="UNIT_SPELLCAST_SENT"then
  local unit,target,guid,spell=...
  if public(unit)and public(target)and public(guid)and public(spell)and unit=="player"and type(target)=="string"and #target>0 and #target<=100 and (portals[spell]or summons[spell])then U.serviceCastTarget={target=target,guid=guid}end
 elseif event=="UNIT_SPELLCAST_SUCCEEDED"then local unit,guid,spell=...;if public(unit)and unit=="player"then U:ObserveServiceCast(spell,guid)end
 elseif event=="PLAYER_ENTERING_WORLD"then U:ObserveTravel(...)
 elseif event=="CONFIRM_SUMMON"then U:ObserveSummonOffer()
 elseif event=="MAIL_INBOX_UPDATE"then U:ArchiveMailboxReceipts()end
end)
-- Star-only feedback is attached to an actual, corroborated order. Never seed reviews.
function U:RateDeliveredOrder(id,stars)
 local r=self.db.outbox[id];if not r or not r.deliveredAt or r.stars or type(stars)~='number'or stars%1~=0 or stars<1 or stars>5 then return false end
 if not self:Send({'RATE5',id,tostring(stars)},r.provider)then return false end;r.stars=stars;self:Audit('RATING_SENT',r.provider,id..' '..stars);return true
end
function U:RatingSummary(who)
 self.db.ratingSummaries=self.db.ratingSummaries or {};local r=self.db.ratingSummaries[self.NameKey(who)]
 return r and r.count>0 and ('%.1f / 5 (%d ratings; provider-reported)'):format(r.total/r.count,r.count)or 'No ratings yet'
end
local ratingReceive=U.Receive
function U:Receive(text,sender,channel)
 if type(text)=='string'and (text:match('^RATE5|')or text:match('^STARS5|'))then
  if channel~='WHISPER'or #text>240 or type(sender)~='string'or #sender>100 then return end
  local id,stars=text:match('^RATE5|([%d%-]+)|([1-5])$')
  if id then
   local r=self.db.inbox[id];if not r or not r.deliveredAt or self.NameKey(r.sender)~=self.NameKey(sender)then return end
   self.db.ratings=self.db.ratings or {};if self.db.ratings[id]then return end
   local count=0;for _ in pairs(self.db.ratings)do count=count+1 end;if count>=2000 then return end
   self.db.ratings[id]={stars=tonumber(stars),customer=sender,at=GetServerTime()};local total,n=0,0;for _,v in pairs(self.db.ratings)do total=total+v.stars;n=n+1 end
   self:Send({'STARS5',tostring(total),tostring(n)},sender);self:Audit('ORDER_RATED',sender,id..' '..stars);return
  end
  local total,count=text:match('^STARS5|(%d+)|(%d+)$');total,count=tonumber(total),tonumber(count)
  if total and count and self:Approved(sender)and count>=1 and count<=2000 and total>=count and total<=5*count then
   self.db.ratingSummaries=self.db.ratingSummaries or {};local n=0;for _ in pairs(self.db.ratingSummaries)do n=n+1 end;if n>=500 and not self.db.ratingSummaries[self.NameKey(sender)]then return end
   self.db.ratingSummaries[self.NameKey(sender)]={total=total,count=count};self:Refresh()
  end;return
 end
 return ratingReceive(self,text,sender,channel)
end
