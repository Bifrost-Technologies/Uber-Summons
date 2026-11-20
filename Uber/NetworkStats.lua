local U=Uber
local function now()return GetServerTime()end
local function me()return GetUnitName('player',true)end
local function valid(s,n)return type(s)=='string'and #s>0 and #s<=n and not s:find('[%c|]')end
local function integer(v,max)local n=tonumber(v);return n and n==n and n%1==0 and n>=0 and n<=max and n end
local function background(parts)return ({ME7=true,ACK7=true,CAP7=true,HELLO3=true,H3=true,LOCATION4=true})[parts[1]]==true end
local send=U.Send
function U:Send(parts,target,channel)
 local low=background(parts)
 if not low and #self.queue>=100 then for i,p in ipairs(self.queue)do if p.lowPriority then table.remove(self.queue,i);break end end end
 local ok=send(self,parts,target,channel);if not ok then return false end
 local packet=self.queue[#self.queue];packet.lowPriority=low
 if not low then for i=1,#self.queue-1 do if self.queue[i].lowPriority then table.remove(self.queue);table.insert(self.queue,i,packet);break end end end
 return true
end
function U:StatsDB()
 self.db.networkPrivacy=self.db.networkPrivacy or {publicStats=true}
 self.networkUsers=self.networkUsers or {};self.privateNetworkUsers=self.privateNetworkUsers or {};self.networkReports=self.networkReports or {}
 return self.db.networkPrivacy
end
function U:PublicUserCount()
 self:StatsDB();local n=self.db.networkPrivacy.publicStats and 1 or 0
 for k,r in pairs(self.networkUsers)do if now()-r.at>120 then self.networkUsers[k]=nil elseif k~=self.NameKey(me())then n=n+1 end end
 return n
end
function U:ReportNetwork()
 local privacy=self:StatsDB();local _,realm=self:Network();local packet={'ME7',realm,privacy.publicStats and '1'or '0',tostring(now())}
 local targets={};targets[self.NameKey(self.FOUNDER)]=self.FOUNDER
 if privacy.publicStats then
  if IsInGuild and IsInGuild()then self:Send(packet,nil,'GUILD')end
  for i,who in ipairs(self:ActiveDrivers())do if i<=10 then targets[self.NameKey(who)]=who end end
 end
 for _,who in pairs(targets)do if self.NameKey(who)~=self.NameKey(me())and #self.queue<75 then self:Send(packet,who)end end
 if self:IsDispatcher()then self.privateNetworkUsers[self.NameKey(me())]={name=me(),at=now(),public=privacy.publicStats==true}end
 self.statsAt=now()
end
function U:SetPublicStats(enabled)
 self:StatsDB().publicStats=enabled==true
 if not enabled then
  if IsInGuild and IsInGuild()then self:Send({'LEAVE7'},nil,'GUILD')end
  self:Send({'LEAVE7'},self.FOUNDER)
  for _,who in ipairs(self:ActiveDrivers())do if #self.queue<70 then self:Send({'LEAVE7'},who)end end
 end
 self:ReportNetwork();self:Refresh()
end
function U:CachedSession(who)
 local direct=self.db.orders[who];if direct then return direct end
 for name,session in pairs(self.db.orders)do if self.NameKey(name)==self.NameKey(who)then return session end end
end
function U:PublishCapacity(target)
 local o=self.online and self.db.active;if not o or o.status=='COMPLETE'or o.status=='CANCELLED'then return end
 local riders=0;for _ in pairs(o.riders or {})do riders=riders+1 end
 local group=GetNumGroupMembers and GetNumGroupMembers()or 0;if issecretvalue and issecretvalue(group)then group=0 end
 local packet={'CAP7',o.id,tostring(math.min(40,riders)),tostring(math.min(40,group)),tostring(now())}
 if target then self:Send(packet,target);return end
 if IsInGuild and IsInGuild()then self:Send(packet,nil,'GUILD')end
 for who,at in pairs(self.subscribers or {})do if now()-at<=180 and #self.queue<75 then self:Send(packet,who)end end
end
local advertise=U.Advertise
function U:Advertise(target)advertise(self,target);self:PublishCapacity(target)end
function U:SessionSnapshot()
 local list={};local counts={summoners=0,portals=0,occupied=0,providers=0,users=self:PublicUserCount(),connected=false}
 for _,who in ipairs(self:ActiveDrivers())do
  local own=self.NameKey(who)==self.NameKey(me());local o=own and self.db.active or self:CachedSession(who)
  local peer=self.peers and self.peers[self.NameKey(who)];local fresh=own or peer and now()-peer.at<=90
  if fresh then
   counts.providers=counts.providers+1
   if not own then counts.connected=true end
   local class=self:DriverClass(who);local state=o and (own or self:IsFresh(o))and o.status or peer and peer.state or 'AVAILABLE'
   local capacity=self.sessionCapacity and self.sessionCapacity[self.NameKey(who)];local full=o and capacity and capacity.id==o.id and now()-capacity.at<=90 and(capacity.riders>=40 or capacity.group>=40)
   local open=not full and(state=='READY'or state=='AVAILABLE'or state=='COMPLETE'or state=='CANCELLED')
   if open then if class=='MAGE'then counts.portals=counts.portals+1 else counts.summoners=counts.summoners+1 end else counts.occupied=counts.occupied+1 end
   if o and (own or self:IsFresh(o))and o.status~='COMPLETE'and o.status~='CANCELLED'then
    list[#list+1]={full=full,provider=who,class=class,id=o.id,destination=o.destination,status=o.status,joinable=not full and(o.status=='READY'or o.status=='SETTING_UP'),own=own}
   end
  end
 end
 if self.networkAck and now()-self.networkAck<=120 then counts.connected=true end
 for k,r in pairs(self.networkReports or {})do if now()-r.at>120 then self.networkReports[k]=nil else counts.users=math.max(counts.users,r.users)end end
 table.sort(list,function(a,b)if a.joinable~=b.joinable then return a.joinable end;return a.provider<b.provider end)
 return counts,list
end
function U:JoinNetworkSession(session)
 if not session or not session.joinable or session.own or not self:Approved(session.provider)then return false end
 local capacity=self.sessionCapacity and self.sessionCapacity[self.NameKey(session.provider)];if capacity and capacity.id==session.id and now()-capacity.at<=90 and(capacity.riders>=40 or capacity.group>=40)then return false end
 local o=self:CachedSession(session.provider);if not self:IsFresh(o)or o.id~=session.id or(o.status~='READY'and o.status~='SETTING_UP')then return false end
 self.db.provider=session.provider;if self.provider then self.provider:SetText(session.provider)end
 return self:Request(o.destination,o.id,{party=1,note='Joining your existing public session.',supplies=''})
end
function U:MaybeExpandSummonRaid()
 if not self.online or not self:Approved(me())or self:DriverClass(me())~='WARLOCK'or not self.db.active or self.db.active.status=='COMPLETE'or self.db.active.status=='CANCELLED'then return false end
 if not IsInGroup or not IsInGroup()or not UnitIsGroupLeader or not UnitIsGroupLeader('player')or IsInRaid and IsInRaid()then return false end
 if InCombatLockdown and InCombatLockdown()then return false end
 if now()-(self.raidAttempt or 0)<15 then return false end
 if C_PartyInfo and C_PartyInfo.AllowedToDoPartyConversion then local ok,allowed=pcall(C_PartyInfo.AllowedToDoPartyConversion,true);if not ok or(issecretvalue and issecretvalue(allowed))or allowed~=true then return false end end
 local fn=C_PartyInfo and C_PartyInfo.ConvertToRaid or ConvertToRaid;if not fn then return false end
 self.raidAttempt=now();local ok,result=pcall(fn);return ok and result~=false
end
local setStatus=U.SetStatus
function U:SetStatus(status,minutes)
 local result=setStatus(self,status,minutes)
 if result and status=='READY'and self.db.active then self.db.active.sharedSession=true end
 return result
end
local receive=U.Receive
function U:Receive(text,sender,channel)
 if type(text)=='string'and text:match('^CAP7|')then
  if not valid(sender,100)or #text>160 or(channel~='GUILD'and channel~='WHISPER')or not self:Approved(sender)then return end
  local id,riders,group,at=text:match('^CAP7|([%d%-]+)|(%d+)|(%d+)|(%d+)$');riders,group,at=integer(riders,40),integer(group,40),integer(at,9999999999)
  if not id or #id>40 or not riders or not group or not at or math.abs(now()-at)>90 then return end
  self.sessionCapacity=self.sessionCapacity or {};local old=self.sessionCapacity[self.NameKey(sender)];if old and old.at>at then return end
  self.sessionCapacity[self.NameKey(sender)]={id=id,riders=riders,group=group,at=at};return
 end
 if type(text)=='string'and(text:match('^ME7|')or text=='LEAVE7'or text:match('^ACK7|'))then
  if not valid(sender,100)or #text>240 then return end;self:StatsDB()
  if text=='LEAVE7'then if channel=='GUILD'or channel=='WHISPER'then self.networkUsers[self.NameKey(sender)]=nil end;return end
  if text:match('^ACK7|')then
   local count,at=text:match('^ACK7|(%d+)|(%d+)$');count,at=integer(count,1000),integer(at,9999999999)
   if channel~='WHISPER'or not self:Approved(sender)or not count or not at or math.abs(now()-at)>120 then return end
   self.networkAck=now();self.networkReports[self.NameKey(sender)]={users=count,at=now()};return
  end
  local realm,public,at=text:match('^ME7|([^|]+)|([01])|(%d+)$');at=integer(at,9999999999);local _,ours=self:Network()
  if not at or realm~=ours or math.abs(now()-at)>120 or(channel~='GUILD'and channel~='WHISPER')or public=='0'and(channel~='WHISPER'or not self:IsDispatcher())then return end
  self.networkAck=now()
  local key=self.NameKey(sender);local old=self.networkUsers[key];if old and at<old.at then return end
  local n=0;for _ in pairs(self.networkUsers)do n=n+1 end
  if public=='0'then self.networkUsers[key]=nil end
  if public=='1'and(n<1000 or old)then self.networkUsers[key]={name=sender,at=at}end
  if self:IsDispatcher()then local total=0;for _ in pairs(self.privateNetworkUsers)do total=total+1 end;if total<2000 or self.privateNetworkUsers[key]then self.privateNetworkUsers[key]={name=sender,at=at,public=public=='1'}end end
  if(self.online and self:Approved(me())or self:IsDispatcher())and now()-(self.last[key..'stats']or 0)>=30 and #self.queue<75 then self.last[key..'stats']=now();self:Send({'ACK7',tostring(self:PublicUserCount()),tostring(now())},sender)end
  return
 end
 local camp=self.db.active;local previous=camp and camp.delivered and camp.delivered[sender]
 local request=text and text:match('^R|([%d%-]+)|');local inboxKey=request and(sender..':'..request);local existed=inboxKey and self.db.inbox[inboxKey]
 local result=receive(self,text,sender,channel)
 camp=self.db.active
 if camp and camp.sharedSession then
  local row=inboxKey and self.db.inbox[inboxKey]
  if not existed and row and row.join==camp.id and camp.delivered then camp.delivered[sender]=nil end
  if type(text)=='string'and text:match('^ARRIVE4|')and camp.delivered and camp.delivered[sender]and camp.delivered[sender]~=previous then camp.riders[sender]=nil;self:PublishCapacity()end
 end
 return result
end
local tick=U.Tick
function U:Tick()
 tick(self);if not self.db then return end
 if now()-(self.backgroundDiscoverAt or 0)>=60 and #self.queue<25 then self.backgroundDiscoverAt=now();self:DiscoverDrivers()end
 if now()-(self.statsAt or 0)>=45 and #self.queue<35 then self:ReportNetwork()end
 self:MaybeExpandSummonRaid()
 if self:IsDispatcher()then for k,r in pairs(self.privateNetworkUsers or {})do if now()-r.at>120 then self.privateNetworkUsers[k]=nil end end end
end
local events=CreateFrame('Frame');for _,e in ipairs({'GROUP_ROSTER_UPDATE','PLAYER_REGEN_ENABLED'})do pcall(events.RegisterEvent,events,e)end
events:SetScript('OnEvent',function()if U.db then U:MaybeExpandSummonRaid()end end)
local function label(f,text,x,y,w,h)local t=f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');t:SetPoint('TOPLEFT',x,y);t:SetSize(w,h or 26);t:SetJustifyH('LEFT');t:SetJustifyV('TOP');t:SetText(text);return t end
local function button(f,text,x,y,w,fn)local b=CreateFrame('Button',nil,f,'UIPanelButtonTemplate');b:SetPoint('TOPLEFT',x,y);b:SetSize(w,26);b:SetText(text);b:SetScript('OnClick',fn);return b end
function U:ShowNetwork()
 if not self.db then return end;self:StatsDB()
 if not self.networkFrame then
  local f=CreateFrame('Frame','UberNetworkPanel',UIParent,'BackdropTemplate');self.networkFrame=f;f:SetSize(920,680);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true);f:EnableMouse(true)
  f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=16});f:SetBackdropColor(.025,.035,.055,1)
  label(f,'UBER / SUMMONING NETWORK & OPEN SESSIONS',24,-22,820,32)
  button(f,'X',860,-18,34,function()f:Hide()end);table.insert(UISpecialFrames,'UberNetworkPanel')
  self.networkSummary=label(f,'',24,-66,870,40)
  local c=CreateFrame('CheckButton',nil,f,'UICheckButtonTemplate');self.publicStatsCheck=c;c:SetSize(26,26);c:SetPoint('TOPLEFT',24,-112);c:SetScript('OnClick',function(box)self:SetPublicStats(box:GetChecked())end)
  label(f,'Include me in public active-user statistics',58,-118,780)
  label(f,'Public opt-out hides your presence from public statistics. Your character and recent activity are still sent privately to the creator for admin counts. Providers remain visible while offering service. No offline/global census.',24,-153,870,50)
  self.sessionRows={};for i=1,5 do local row={};self.sessionRows[i]=row;row.text=label(f,'',24,-220-(i-1)*64,620,56);row.join=button(f,'Join session',674,-224-(i-1)*64,200,function()if row.session then local ok=self:JoinNetworkSession(row.session);self:Notice(ok and 'Join request sent; provider acceptance, pricing and a native group invitation may still be required.'or 'Session unavailable; refresh the network.')end end)end
  button(f,'Previous',24,-556,200,function()self.sessionPage=math.max(1,(self.sessionPage or 1)-1);self:Refresh()end);button(f,'Next',240,-556,200,function()self.sessionPage=(self.sessionPage or 1)+1;self:Refresh()end)
  button(f,'Refresh network',460,-556,200,function()self:RefreshProvider();self:ReportNetwork()end)
  self.networkAdminButton=button(f,'Creator census',674,-556,200,function()self:ShowNetworkAdmin()end)
  label(f,'Counts reflect fresh observations (120s), not every player on the realm. Public users are a conservative observed count, never a sum of overlapping provider reports. Joining a session does not mean free service or guaranteed arrival.',24,-605,870,56)
 end
 self.publicStatsCheck:SetChecked(self.db.networkPrivacy.publicStats==true);self.networkFrame:Show();self:ReportNetwork();self:Refresh()
end
function U:ShowNetworkAdmin()
 if not self:IsDispatcher()then return false end
 if not self.censusFrame then
  local f=CreateFrame('Frame','UberPrivateCensus',UIParent,'BackdropTemplate');self.censusFrame=f;f:SetSize(780,570);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:EnableMouse(true);f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=16});f:SetBackdropColor(.025,.035,.055,1)
  label(f,'CREATOR / RECENT NETWORK PRESENCE',24,-24,690);button(f,'X',720,-18,34,function()f:Hide()end);self.censusText=label(f,'',24,-74,730,420)
  button(f,'Previous',24,-514,340,function()self.censusPage=math.max(1,(self.censusPage or 1)-1);self:Refresh()end);button(f,'Next',390,-514,340,function()self.censusPage=(self.censusPage or 1)+1;self:Refresh()end);table.insert(UISpecialFrames,'UberPrivateCensus')
 end;self.censusFrame:Show();self:Refresh();return true
end
local show=U.Show
function U:Show()
 show(self);if not self.frame then return end
 if not self.networkEntry then
  self.networkStatus=label(self.frame,'Checking summoning network…',180,-48,475,20)
  self.networkEntry=button(self.frame,'Network & open sessions',674,-42,196,function()self:ShowNetwork()end)
 end;self:Refresh()
end
local refresh=U.Refresh
function U:Refresh()
 refresh(self);if not self.db then return end;local stats,sessions=self:SessionSnapshot()
 if self.networkStatus then self.networkStatus:SetText(stats.connected and '|cff55dd88Connected to summoning network|r'or '|cffffcc66Discovering summoning network|r')end
 if self.availability then self.availability:SetText(stats.summoners..' available summoners · '..stats.portals..' available portal keepers · '..stats.occupied..' occupied · '..stats.users..' public users observed\n'..(stats.providers>0 and stats.summoners+stats.portals==0 and 'All observed providers are occupied. Check open sessions to join an existing camp.'or(stats.providers==0 and 'No active providers observed. Refresh or check again later.'or 'Network & open sessions shows destinations and shared camps.')))end
 if self.availability and not self.online and self:Approved(GetUnitName('player',true))then
  self.availability:SetText(stats.summoners..' available summoners · '..stats.portals..' available portal keepers · '..stats.occupied..' occupied\nYou are ONLINE · Bookings closed. Open Driver desk to accept requests; advance reservations remain available.')
 end
 if self.networkFrame and self.networkFrame:IsShown()then
  self.networkSummary:SetText(stats.summoners..' available summoners · '..stats.portals..' available portal keepers · '..stats.occupied..' occupied\n'..stats.users..' public active users observed · '..#sessions..' active camps');self.networkAdminButton:SetEnabled(self:IsDispatcher())
  self.sessionPage=math.max(1,math.min(self.sessionPage or 1,math.max(1,math.ceil(#sessions/5))))
  for i,row in ipairs(self.sessionRows)do local session=sessions[(self.sessionPage-1)*5+i];row.session=session;row.text:SetText(session and(session.provider..' · '..(session.class=='MAGE'and 'Portals'or 'Summons')..'\n'..session.destination..' · '..(self.statusLabels[session.status]or session.status))or 'No fresh active session');row.join:SetEnabled(session and session.joinable and not session.own or false)end
 end
 if self.censusFrame and self.censusFrame:IsShown()then
  if not self:IsDispatcher()then self.censusFrame:Hide();return end
  local list,hidden={},0;for _,r in pairs(self.privateNetworkUsers or {})do if now()-r.at<=120 then list[#list+1]=r;if not r.public then hidden=hidden+1 end end end;table.sort(list,function(a,b)return a.name<b.name end)
  self.censusPage=math.max(1,math.min(self.censusPage or 1,math.max(1,math.ceil(#list/12))));local lines={#list..' directly observed active clients · '..hidden..' public opt-outs · '..stats.providers..' active providers','Private presence reports are self-reported and expire after 120 seconds; offline creator misses reports.'}
  for i=(self.censusPage-1)*12+1,math.min(#list,self.censusPage*12)do local r=list[i];lines[#lines+1]=r.name..' · '..(r.public and 'Public'or 'Public opt-out')..' · '..(now()-r.at)..'s ago' end;self.censusText:SetText(table.concat(lines,'\n'))
 end
end

local showAdmin=U.ShowAdmin
function U:ShowAdmin()
 local result=showAdmin(self)
 if self:IsDispatcher()and self.adminFrame and not self.censusEntry then self.censusEntry=button(self.adminFrame,'Private network census',24,-642,850,function()self:ShowNetworkAdmin()end)end
 return result
end
