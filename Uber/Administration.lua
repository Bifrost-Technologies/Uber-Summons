local U=Uber
U.FOUNDER="Bîfrost Titan"
U.SEEDED_DRIVERS={
 {name=U.FOUNDER,class="WARLOCK",founder=true},
 {name="Krazyito Isamage",class="MAGE",ruleset="Normal",faction="Horde",seeded=true},
}
local function now()return GetServerTime()end
local function me()return GetUnitName("player",true)end
local function key(n)return U.NameKey(n)end
local function same(a,b)return key(a)==key(b)end
local function clean(s,n)return type(s)=="string"and #s>0 and #s<=n and not s:find("[%c|]")end
local function integer(s,max)local n=tonumber(s);return n and n==n and n>=0 and n<=max and n%1==0 and n end
function U:SeededDriver(who)
 if type(who)~="string"or who==""then return nil end
 for _,d in ipairs(self.SEEDED_DRIVERS)do
  if same(who,d.name)then return d end
  local base,suffix=who:match("^([^-]+)%-(.+)$")
  if base and base:lower()==d.name:lower()and not d.name:find("-",1,true)then
   local rs=self.NormalizeRuleset and self:NormalizeRuleset(suffix)
   if not d.ruleset or not rs or rs==d.ruleset then return d end
  end
 end
 return nil
end
function U:Audit(kind,subject,detail,source)
 self.db.audit=self.db.audit or {};local a=self.db.audit
 a[#a+1]={at=now(),kind=kind,subject=subject or "",detail=detail or "",source=source or me()}
 while #a>2000 do table.remove(a,1)end
end
local driverDB=U.DriverDB
function U:DriverDB()
 driverDB(self);self.db.dispatcher=self.FOUNDER
 self.db.providerPolicies=type(self.db.providerPolicies)=='table'and self.db.providerPolicies or {};self.db.audit=type(self.db.audit)=='table'and self.db.audit or {}
 for _,d in ipairs(self.SEEDED_DRIVERS)do
  local k=key(d.name)
  local ghost=d.name:lower().."-"
  if k~=ghost then self.db.drivers[ghost]=nil end
  local r=self.db.drivers[k]
  if type(r)~="table"or not r.approved or r.class~=d.class or r.authority~=self.FOUNDER then
   self.db.drivers[k]={name=d.name,class=d.class,approved=true,authority=self.FOUNDER,at=(type(r)=="table"and r.at)or 0,founder=d.founder,seeded=d.seeded,ruleset=d.ruleset,faction=d.faction}
  else
   if d.founder then r.founder=true end
   if d.seeded then r.seeded=true end
   if d.ruleset and not r.ruleset then r.ruleset=d.ruleset end
   if d.faction and not r.faction then r.faction=d.faction end
  end
 end
end
function U:IsDispatcher()return false end -- Creator tools are supplied only by the private UberAdmin addon.
local approved=U.Approved
function U:Approved(who)
 self:DriverDB();if same(who,self.FOUNDER)then return true end
 local p=self.db.providerPolicies[key(who)];if p and (p.state=="BANNED"or p.state=="REMOVED")then return false end
 return approved(self,who)or self:SeededDriver(who)~=nil
end
local driverClass=U.DriverClass
function U:DriverClass(who)
 self:DriverDB()
 local r=self.db.drivers[key(who)]
 if r and (r.class=="MAGE"or r.class=="WARLOCK")then return r.class end
 local s=self:SeededDriver(who)
 if s and s.class then return s.class end
 return driverClass and driverClass(self,who)or "WARLOCK"
end
function U:ProviderPolicy(who)
 self:DriverDB();return self.db.providerPolicies[key(who)]or {hours="Hours not published — request a time; confirmation required"}
end
function U:ProviderLive(who)
 if same(who,me())then return self.online==true end
 local p=self.peers and self.peers[key(who)];return p and p.online and now()-p.at<=90 or false
end
function U:ProviderPresence(who)
 if same(who,me())then return true,self.online==true,self.online and "Service open"or "Online · bookings closed"end
 local p=self.peers and self.peers[key(who)]
 if p and now()-p.at<=90 then return p.online==true,p.online==true,p.online and (self.statusLabels[p.state]or "Service open")or "Recently seen · bookings closed"end
 return false,false,"Offline / no recent presence"
end
function U:ProviderDirectory()
 self:DriverDB();local names,seen={},{}
 local mine=me()
 for _,r in pairs(self.db.drivers)do if type(r.name)=="string"and self:Approved(r.name)then
  local id=key(r.name)
  if not seen[id]then seen[id]=true;names[#names+1]=same(r.name,mine)and mine or r.name end
 end end
 table.sort(names,function(a,b)if a==b then return false end;if same(a,self.FOUNDER)then return true elseif same(b,self.FOUNDER)then return false end;return a<b end)
 return names
end
local function packet(who,p)
 return {"ADMIN4",who,p.state,p.class,tostring(p.revision),tostring(p.standard),tostring(p.priority),p.hours,p.reason}
end
-- Prepare native mail only. WoW's send button remains the player's action.
function U:ApplyDriver(note)
 local _,class=UnitClass("player")
 if (class~="MAGE"and class~="WARLOCK")or type(note)~="string"or #note>160 or note:find("[%c|]")then return false end
 if not self.mailOpen or not SendMailFrame or not SendMailFrame:IsShown()then self:Notice("Open a mailbox → Send Mail to prepare your application to "..self.FOUNDER..".");return false end
 if not SendMailNameEditBox or not SendMailSubjectEditBox or not SendMailBodyEditBox then return false end
 for _,box in ipairs({SendMailNameEditBox,SendMailSubjectEditBox,SendMailBodyEditBox})do if box:GetText()~=""then self:Notice("Finish or clear your existing mail draft first.");return false end end
 if GetSendMailMoney and GetSendMailMoney()~=0 or GetSendMailCOD and GetSendMailCOD()~=0 then return false end
 for i=1,12 do if HasSendMailItem and HasSendMailItem(i)then return false end end
 SendMailNameEditBox:SetText(self.FOUNDER);SendMailSubjectEditBox:SetText("UBER DRIVER APPLICATION "..class)
 SendMailBodyEditBox:SetText("Character: "..me().."\nClass: "..class.."\n"..note.."\nPlease review my driver application manually.")
 self:Audit("APPLICATION_DRAFT",self.FOUNDER,class);self:Notice("Application draft ready. Review and click WoW's Send button. Not yet sent.");return true
end
local network=U.Network
function U:Network()
 local profile,id=network(self);local p=self.db.providerPolicies and self.db.providerPolicies[key(me())]
 if p and p.state=="APPROVED"then profile.standard,profile.priority=p.standard,p.priority end
 return profile,id
end
local prices=U.SavePrices
function U:SavePrices(...)
 local p=self.db.providerPolicies and self.db.providerPolicies[key(me())]
 if p and not self:IsDispatcher()then self:Notice("Your published rates are managed by Bîfrost Titan. Contact the admin for changes.");return false end
 if p then local standard,priority,house=...;local own=self:Network();if house~=own.house then return false end;return self:ManageProvider(me(),"APPROVED",p.class,standard,priority,p.hours,"Creator price update")end
 return prices(self,...)
end
local receive=U.Receive
function U:Receive(text,sender,channel)
 if type(text)~="string"or #text>240 or text:find("[%c]")or not clean(sender,100)then return end
 self:DriverDB();local p={};for v in (text.."|"):gmatch("(.-)|")do p[#p+1]=v end
 if p[1]=="Q3"and not self:Approved(sender)then return end
 if p[1]=="Q3"and not (self.db.quotes and self.db.quotes[p[3]])then
  local policy=self.db.providerPolicies[key(sender)];local r=self.db.outbox[p[2]]
  if policy and r and (tonumber(p[4])~=policy.standard or tonumber(p[5])~=(r.priority and policy.priority or 0))then self:Notice("Quote does not match the admin's published rates. Refresh policy or contact the creator before paying.");return end
 end
 if p[1]=="LOCATION4"then
  if #p~=5 or not self:Approved(sender)then return end
  local map,x,y,at=integer(p[2],999999),integer(p[3],10000),integer(p[4],10000),integer(p[5],9999999999)
  if not map or map==0 or not x or not y or not at or math.abs(now()-at)>90 then return end
  self.providerPositions=self.providerPositions or {};local old=self.providerPositions[key(sender)]
  if not old or at>=old.updated then self.providerPositions[key(sender)]={map=map,x=x/10000,y=y/10000,updated=at}end;self:Refresh();return
 elseif p[1]=="ADMIN4"then
  if not same(sender,self.FOUNDER)or (#p~=9)or not clean(p[2],60)or not ({APPROVED=true,REMOVED=true,BANNED=true})[p[3]]or (p[4]~="WARLOCK"and p[4]~="MAGE")then return end
  local rev,a,b=integer(p[5],9999999999),integer(p[6],100000000),integer(p[7],100000000)
  if not rev or rev>now()+3600 or not a or not b or not clean(p[8],70)or not clean(p[9],40)then return end
  if same(p[2],self.FOUNDER)and (p[3]~="APPROVED"or p[4]~="WARLOCK")then return end
  local old=self.db.providerPolicies[key(p[2])];if old and rev<=old.revision then return end
  local count=0;for _ in pairs(self.db.providerPolicies)do count=count+1 end;if count>=200 and not old then return end
  self.db.providerPolicies[key(p[2])]={name=p[2],state=p[3],class=p[4],revision=rev,standard=a,priority=b,hours=p[8],reason=p[9]}
  self.db.drivers[key(p[2])]={name=p[2],approved=p[3]=="APPROVED",authority=self.FOUNDER,class=p[4],at=now()}
  if same(p[2],me())and p[3]~="APPROVED"then self.online=false end
  self:Audit("ADMIN_"..p[3],p[2],p[9],sender);self:Refresh();return
 elseif p[1]=="ROSTERNEXT4"then
  local cursor=integer(p[2],201)
  if channel=="WHISPER"and #p==2 and same(sender,self.FOUNDER)and cursor and cursor>0 then self:Send({"ROSTER4",tostring(cursor)},self.FOUNDER)end;return
 elseif (p[1]=="ROSTER"or p[1]=="ROSTER4")then
  if not self:IsDispatcher()or channel~="WHISPER"or (p[1]=="ROSTER"and #p~=1)or (p[1]=="ROSTER4"and #p~=2)then return end
  local cursor=p[1]=="ROSTER"and 0 or integer(p[2],201)
  if not cursor or #self.queue>=94 or self.last[sender.."policyCursor"]==cursor and now()-(self.last[sender.."policyPage"]or 0)<2 then return end
  self.last[sender.."policyCursor"]=cursor;self.last[sender.."policyPage"]=now()
  local rows={};for _,r in pairs(self.db.drivers)do rows[#rows+1]=r end;table.sort(rows,function(a,b)return a.name<b.name end)
  local stop=math.min(#rows,cursor+16,cursor+94-#self.queue)
  for i=cursor+1,stop do
   local r=rows[i]
   if self.db.providerPolicies[key(r.name)]then self:SendPolicy(r.name,sender)
   else self:Send({"DRIVER",r.name,r.approved and "1"or "0",tostring(r.at),r.class or "WARLOCK"},sender)end
  end
  self:Send({"ROSTERNEXT4",stop<#rows and tostring(stop)or "0"},sender);return
 elseif p[1]=="DRIVER"and self.db.providerPolicies[key(p[2])]then return
 elseif p[1]=="APPLY"then return end -- Applications use real mailbox delivery, including while admin is offline.
 if (p[1]=="H3"or p[1]=="S")and not self:Approved(sender)then return end
 receive(self,text,sender,channel)
end
local advertise=U.Advertise
function U:Advertise(target)
 advertise(self,target)
 if not self.online then return end
 local map,x,y=self:Location();local parts={"LOCATION4",map,x,y,tostring(now())}
 if target then self:Send(parts,target);return end
 if IsInGuild and IsInGuild()then self:Send(parts,nil,"GUILD")end
 for who,at in pairs(self.subscribers or {})do if now()-at<=180 and #self.queue<80 then self:Send(parts,who)end end
end
local map=U.Map
function U:Map()
 local camp=self.online and self.db.active or self.db.orders[self.db.provider]
 if camp and self:IsFresh(camp)then return map(self)end
 local p=self.providerPositions and self.providerPositions[key(self.db.provider)]
 if not p or now()-p.updated>90 or not self:ProviderLive(self.db.provider)then self:Notice("No live provider position. Refresh when service is open.");return end
 if C_Map and C_Map.SetUserWaypoint and UiMapPoint then C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(p.map,p.x,p.y))end
 if WorldMapFrame and WorldMapFrame.SetMapID then WorldMapFrame:Show();WorldMapFrame:SetMapID(p.map)end
end
