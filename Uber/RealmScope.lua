local U=Uber
local function public(v)if issecretvalue and issecretvalue(v)then return end;return v end
local function read(fn,...)
 if type(fn)~='function'then return end
 local ok,v=pcall(fn,...);if ok then return public(v)end
end
local function normalize(s)return type(s)=='string'and s:lower():gsub('%s','')or ''end
local function finite(n,max)return type(n)=='number'and n==n and n>=0 and n<=max and n%1==0 end
local function valid(s,max)return type(s)=='string'and #s>0 and #s<=max and not s:find('[%c|]')end
local function faction(f)return f=='Alliance'or f=='Horde'end
function U:LocalScope()
 local r=read(GetNormalizedRealmName);if not valid(r,80)then r=read(GetRealmName)end
 local f=read(UnitFactionGroup,'player');local id=read(GetRealmID);local region=read(GetCurrentRegion)
 return {realm=valid(r,80)and r or '',faction=faction(f)and f or 'Unknown',realmID=finite(id,9999999)and id or 0,region=finite(region,100)and region or 0,at=GetServerTime(),version=2}
end
function U:ScopeMatches(s)
 local own=self:LocalScope()
 return type(s)=='table'and valid(s.realm,80)and faction(s.faction)and faction(own.faction)and
  normalize(s.realm)==normalize(own.realm)and s.faction==own.faction and
  (not s.realmID or s.realmID==0 or own.realmID==0 or s.realmID==own.realmID)and
  (not s.region or s.region==0 or own.region==0 or s.region==own.region)
end
function U:ScopeRealmAllowed(who,r)
 if not valid(who,100)or not valid(r,80)then return false end
 local suffix=who:match('^[^-]+%-(.+)$')
 return normalize(r)==normalize(suffix or self:LocalScope().realm)
end
function U:DriverScope(who)
 self.db.driverScopes=type(self.db.driverScopes)=='table'and self.db.driverScopes or {}
 if self.NameKey(who)==self.NameKey(GetUnitName('player',true))then return self:LocalScope()end
 local s=self.db.driverScopes[self.NameKey(who)]
 if type(s)=='table'and valid(s.realm,80)and faction(s.faction)and finite(s.at,9999999999)and s.at<=GetServerTime()then return s end
end
function U:CanQueueDriver(who)
 local s=self:DriverScope(who)
 return self:Approved(who)and self:ScopeMatches(s)or false
end
function U:CanBookDriver(who)
 local s=self:DriverScope(who)
 return self:CanQueueDriver(who)and s and GetServerTime()-s.at<=90 or false
end
function U:ScopedNetworkSettings()
 local scope=self:LocalScope();local id=(read(GetRealmName)or scope.realm)
 self.db.realmServices=type(self.db.realmServices)=='table'and self.db.realmServices or {}
 local key=normalize(scope.realm)..'|'..scope.faction..'|'..scope.realmID..'|'..scope.region
 local settings=self.db.realmServices[key]
 if type(settings)~='table'then
  local old=self.db.realmServices[id]
  settings={realm=scope.realm,faction=scope.faction,profiles={}}
  -- Import only an existing profile belonging to this native character, not another faction's defaults.
  local who=self.NameKey(GetUnitName('player',true))
  local previous=type(old)=='table'and type(old.profiles)=='table'and old.profiles[who]
  if type(previous)=='table'then
   settings.profiles[who]={standard=previous.standard,priority=previous.priority}
   if valid(old.house,60)then settings.house=old.house end
  end
  self.db.realmServices[key]=settings
 end
 settings.profiles=type(settings.profiles)=='table'and settings.profiles or {}
 local who=self.NameKey(GetUnitName('player',true));local p=settings.profiles[who]
 if type(p)~='table'then p={};settings.profiles[who]=p end
 if not finite(p.standard,100000000)then p.standard=0 end
 if not finite(p.priority,100000000)then p.priority=0 end
 p.house=valid(settings.house,60)and settings.house or self.FOUNDER or 'Bifrost Titan'
 self.networkSettingsKey=key
 self.peers=self.peers or {};self.subscribers=self.subscribers or {}
 return p,id
end
function U:ProviderFilter()
 self.db.providerFilters=type(self.db.providerFilters)=='table'and self.db.providerFilters or {}
 local s=self:LocalScope();local key=self.NameKey(GetUnitName('player',true))..'|'..normalize(s.realm)..'|'..s.faction..'|'..s.realmID..'|'..s.region
 local mode=self.db.providerFilters[key]
 if mode~='ALL'and mode~='LOCAL'then mode='LOCAL';self.db.providerFilters[key]=mode end
 return mode,key
end
function U:SetProviderFilter(mode)
 if mode~='LOCAL'and mode~='ALL'then return false end
 local _,key=self:ProviderFilter();self.db.providerFilters[key]=mode;self.rosterPage=1
 if self.menu then self.menu:Hide()end
 self:Refresh();return true
end
local directory=U.ProviderDirectory
function U:ProviderDirectory()
 local list=directory(self);local mode=self:ProviderFilter()
 if mode=='ALL'then
  -- Previously authenticated cached foreign records can be browsed, never booked across scope.
  local seen={};for _,who in ipairs(list)do seen[self.NameKey(who)]=true end
  for _,r in pairs(self.db.drivers or {})do
   local p=type(r)=='table'and valid(r.name,100)and self.db.providerPolicies and self.db.providerPolicies[self.NameKey(r.name)]
   if type(r)=='table'and valid(r.name,100)and r.approved==true and (not p or p.state~='BANNED'and p.state~='REMOVED')and not seen[self.NameKey(r.name)]then
    list[#list+1]=r.name;seen[self.NameKey(r.name)]=true
   end
  end
  return list
 end
 local out={};for _,who in ipairs(list)do if self:CanQueueDriver(who)then out[#out+1]=who end end;return out
end
local request=U.Request
function U:Request(destination,join,details)
 local scheduled=details and details.scheduledAt or self.bookingTime
 if not self:CanBookDriver(self.db.provider)and not(scheduled and not join and not self:ProviderLive(self.db.provider)and self:CanQueueDriver(self.db.provider))then
  self:Notice('Booking unavailable: different or unconfirmed realm/faction. All networks is a browsing filter.');return false
 end
 return request(self,destination,join,details)
end
local selectDriver=U.SelectDriver
function U:SelectDriver(who,...)
 if not self:CanQueueDriver(who)then self:Notice('This provider is outside your confirmed realm/faction.');return false end
 selectDriver(self,who,...);return true
end
local action=U.DriverAction
function U:DriverAction(who,kind)if kind=='request'then return self:SelectDriver(who)end;return action(self,who,kind)end
local advertise=U.Advertise
function U:Advertise(target)
 local s=self:LocalScope()
 if faction(s.faction)and valid(s.realm,80)then
  local legacy={'SCOPE1',s.realm,s.faction}
  local versioned={'SCOPE2',s.realm,s.faction,tostring(s.realmID),tostring(s.region),tostring(GetServerTime())}
  local function send(who,channel)self:Send(legacy,who,channel);self:Send(versioned,who,channel)end
  if target then send(target)elseif IsInGuild and IsInGuild()then send(nil,'GUILD')end
  for who in pairs(self.subscribers or {})do if who~=target then send(who)end end
 end
 return advertise(self,target)
end
local receive=U.Receive
function U:Receive(text,sender,channel)
 if type(text)=='string'and(text:match('^SCOPE1|')or text:match('^SCOPE2|'))then
  if #text>240 or text:find('[%c]')or not valid(sender,100)or not({WHISPER=true,GUILD=true,PARTY=true,RAID=true})[channel]or not self:Approved(sender)then return end
  local p={};for value in(text..'|'):gmatch('(.-)|')do p[#p+1]=value end
  local modern=p[1]=='SCOPE2'
  if #p~=(modern and 6 or 3)or not faction(p[3])or not self:ScopeRealmAllowed(sender,p[2])then return end
  local realmID,region,at=0,0,GetServerTime()
  if modern then
   realmID,region,at=tonumber(p[4]),tonumber(p[5]),tonumber(p[6])
   if not finite(realmID,9999999)or not finite(region,100)or not finite(at,9999999999)or math.abs(GetServerTime()-at)>90 then return end
  end
  self.db.driverScopes=type(self.db.driverScopes)=='table'and self.db.driverScopes or {}
  local key=self.NameKey(sender);local old=self.db.driverScopes[key]
  if type(old)=='table'then
   if modern and old.sentAt and at<=old.sentAt then return end
   if not modern and old.version==2 and type(old.at)=='number'and GetServerTime()-old.at<90 then return end
  end
  local n=0;for _ in pairs(self.db.driverScopes)do n=n+1 end;if n>=500 and not old then return end
  self.db.driverScopes[key]={realm=p[2],faction=p[3],realmID=realmID,region=region,at=GetServerTime(),sentAt=modern and at or nil,version=modern and 2 or 1}
  self:Refresh();return
 end
 return receive(self,text,sender,channel)
end
local refresh=U.Refresh
function U:Refresh(...)
 refresh(self,...)
 for _,row in ipairs(self.rosterRows or {})do if type(row.driver)=='string'then
  local allowed=self:CanQueueDriver(row.driver);row:SetAlpha(allowed and 1 or .4)
  if row.order then row.order:SetEnabled(allowed==true)end
  local s=self:DriverScope(row.driver)
  row.title:SetText(row.title:GetText()..(s and(' · '..s.realm..' / '..s.faction)or ' · Realm/faction unknown'))
 end end
 local view=self.views and self.views.Drivers
 if view and not self.scopeFilterButton then
  local b=CreateFrame('Button',nil,view,'UIPanelButtonTemplate');self.scopeFilterButton=b
  b:SetSize(285,28);b:SetPoint('TOPRIGHT',-12,-4)
  b:SetScript('OnClick',function()self:SetProviderFilter(self:ProviderFilter()=='LOCAL'and 'ALL'or 'LOCAL')end)
  b:SetScript('OnEnter',function()GameTooltip:SetOwner(b,'ANCHOR_BOTTOM');GameTooltip:SetText('My realm + faction / All known networks');GameTooltip:AddLine('All realm types are supported. All shows known cached providers; native messaging and booking restrictions still apply.',1,1,1,true);GameTooltip:Show()end)
  b:SetScript('OnLeave',function()GameTooltip:Hide()end)
 end
 if self.scopeFilterButton then self.scopeFilterButton:SetText(self:ProviderFilter()=='LOCAL'and 'Showing: My realm + faction'or 'Showing: All known networks')end
end
