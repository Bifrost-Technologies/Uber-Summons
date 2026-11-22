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
local RULESET_MAP={
 normal='Normal',pve='Normal',
 pvp='PvP',
 rp='RP',roleplay='RP',
 rppvp='RPPvP',pvprp='RPPvP',roleplaypvp='RPPvP',
}
function U:NormalizeRuleset(value)
 if type(value)~='string'or value==''then return nil end
 local cleaned=value:lower():gsub('[%s%-_]','')
 if RULESET_MAP[cleaned]then return RULESET_MAP[cleaned]end
 local suffix=value:match('Realm%s*%d+%s*(%a+)$')
 return suffix and RULESET_MAP[suffix:lower()]or nil
end
function U:LocalRuleset()
 local r=read(GetNormalizedRealmName)or read(GetRealmName)
 local fromRealm=self:NormalizeRuleset(r)
 if fromRealm then return fromRealm end
 if C_GameRules and type(C_GameRules.IsGameRuleActive)=='function'and Enum and Enum.GameRule then
  local R=Enum.GameRule
  if R.PvPRuleset or R.RPRuleset then
   local pvp=R.PvPRuleset and read(C_GameRules.IsGameRuleActive,R.PvPRuleset)==true
   local rp=R.RPRuleset and read(C_GameRules.IsGameRuleActive,R.RPRuleset)==true
   if pvp and rp then return 'RPPvP'end
   if pvp then return 'PvP'end
   if rp then return 'RP'end
   return 'Normal'
  end
 end
 return nil
end
function U:LocalScope()
 local r=read(GetNormalizedRealmName);if not valid(r,80)then r=read(GetRealmName)end
 local f=read(UnitFactionGroup,'player');local id=read(GetRealmID);local region=read(GetCurrentRegion)
 return {realm=valid(r,80)and r or '',ruleset=self:LocalRuleset()or '',faction=faction(f)and f or 'Unknown',realmID=finite(id,9999999)and id or 0,region=finite(region,100)and region or 0,at=GetServerTime(),version=2}
end
function U:ScopeMatches(s)
 local own=self:LocalScope()
 if type(s)~='table'or not faction(s.faction)or not faction(own.faction)or s.faction~=own.faction then return false end
 if s.region and s.region~=0 and own.region and own.region~=0 and s.region~=own.region then return false end
 local ownRs=self:NormalizeRuleset(own.ruleset)or self:NormalizeRuleset(own.realm)
 local driverRs=self:NormalizeRuleset(s.ruleset)or self:NormalizeRuleset(s.realm)
 if ownRs and driverRs then return ownRs==driverRs end
 return valid(s.realm,80)and valid(own.realm,80)and normalize(s.realm)==normalize(own.realm)and
  (not s.realmID or s.realmID==0 or own.realmID==0 or s.realmID==own.realmID)
end
function U:ScopeRealmAllowed(who,r)
 if not valid(who,100)or not valid(r,80)then return false end
 local suffix=who:match('^[^-]+%-(.+)$')
 local target=suffix or self:LocalScope().realm
 if normalize(r)==normalize(target)then return true end
 local rsA,rsB=self:NormalizeRuleset(r),self:NormalizeRuleset(target)
 return rsA~=nil and rsA==rsB
end
function U:DriverScope(who)
 self.db.driverScopes=type(self.db.driverScopes)=='table'and self.db.driverScopes or {}
 if self.NameKey(who)==self.NameKey(GetUnitName('player',true))then return self:LocalScope()end
 local s=self.db.driverScopes[self.NameKey(who)]
 if type(s)=='table'and valid(s.realm,80)and faction(s.faction)and finite(s.at,9999999999)and s.at<=GetServerTime()then
  if not self:NormalizeRuleset(s.ruleset)then s.ruleset=self:NormalizeRuleset(s.realm)or ''end
  return s
 end
 local r=self.db.drivers and self.db.drivers[self.NameKey(who)]or(self.SeededDriver and self:SeededDriver(who))
 if type(r)=='table'then
  local rs=self:NormalizeRuleset(r.ruleset)or self:NormalizeRuleset(r.realm)
  if rs and faction(r.faction)then
   return {realm=valid(r.realm,80)and r.realm or '',ruleset=rs,faction=r.faction,realmID=0,region=0,at=GetServerTime(),seeded=true,version=2}
  end
 end
end
function U:FormatDriverScope(s)
 if type(s)~='table'then return 'Ruleset/faction unknown'end
 local fText=s.faction=='Alliance'and'|cff4aa3ffAlliance|r'or s.faction=='Horde'and'|cffff5b5bHorde|r'or tostring(s.faction or 'Unknown')
 local rs=self:NormalizeRuleset(s.ruleset)or self:NormalizeRuleset(s.realm)
 if rs then return rs..' / '..fText end
 if valid(s.realm,80)then return s.realm..' / '..fText end
 return 'Ruleset/faction unknown'
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
local FILTER_DEFAULTS={availableToMe=true,onlineOnly=true,warlock=true,mage=true}
local FILTER_OPTIONS={
 {key='availableToMe'},
 {key='onlineOnly',label='Online only'},
 {key='warlock',label='Warlocks (Summons)'},
 {key='mage',label='Mages (Portals)'},
}
local function filterScopeKey(self)
 local s=self:LocalScope()
 return self.NameKey(GetUnitName('player',true))..'|'..normalize(s.realm)..'|'..s.faction..'|'..s.realmID..'|'..s.region
end
function U:DriverFilters()
 self.db.providerFilters=type(self.db.providerFilters)=='table'and self.db.providerFilters or {}
 self.db.driverFilters=type(self.db.driverFilters)=='table'and self.db.driverFilters or {}
 local key=filterScopeKey(self);local f=self.db.driverFilters[key]
 if type(f)~='table'then
  f={availableToMe=self.db.providerFilters[key]~='ALL',onlineOnly=true,warlock=true,mage=true}
  self.db.driverFilters[key]=f
 else
  for k,def in pairs(FILTER_DEFAULTS)do if type(f[k])~='boolean'then f[k]=def end end
 end
 return f,key
end
function U:SetDriverFilter(changes)
 local f,key=self:DriverFilters()
 if changes=='RESET'then
  for k,def in pairs(FILTER_DEFAULTS)do f[k]=def end
 elseif changes=='ALL'then
  f.availableToMe=false;f.onlineOnly=false;f.warlock=true;f.mage=true
 elseif type(changes)=='table'then
  for k in pairs(FILTER_DEFAULTS)do if type(changes[k])=='boolean'then f[k]=changes[k]end end
 else
  return false
 end
 self.db.providerFilters[key]=f.availableToMe and 'LOCAL'or 'ALL'
 self.rosterPage=1;if self.menu then self.menu:Hide()end
 self:Refresh();return f
end
function U:ProviderFilter()
 local f,key=self:DriverFilters()
 local mode=f.availableToMe and 'LOCAL'or 'ALL'
 self.db.providerFilters[key]=mode
 return mode,key
end
function U:SetProviderFilter(mode)
 if mode=='AVAILABLE'then mode='LOCAL'end
 if mode~='LOCAL'and mode~='ALL'then return false end
 if mode=='ALL'then return self:SetDriverFilter('ALL')~=false end
 return self:SetDriverFilter({availableToMe=true})~=false
end
local directory=U.ProviderDirectory
function U:ProviderDirectory()
 local list=directory(self);local f=self:DriverFilters()
 if not f.availableToMe then
  -- Previously authenticated cached foreign records can be browsed, never booked across scope.
  local seen={};for _,who in ipairs(list)do seen[self.NameKey(who)]=true end
  for _,r in pairs(self.db.drivers or {})do
   local p=type(r)=='table'and valid(r.name,100)and self.db.providerPolicies and self.db.providerPolicies[self.NameKey(r.name)]
   if type(r)=='table'and valid(r.name,100)and r.approved==true and (not p or p.state~='BANNED'and p.state~='REMOVED')and not seen[self.NameKey(r.name)]then
    list[#list+1]=r.name;seen[self.NameKey(r.name)]=true
   end
  end
 end
 local out={}
 for _,who in ipairs(list)do
  local scopeOk=not f.availableToMe or self:CanQueueDriver(who)
  local liveOk=not f.onlineOnly or self:ProviderLive(who)==true
  local cls=self:DriverClass(who)
  local classOk=(cls=='WARLOCK'and f.warlock)or(cls=='MAGE'and f.mage)
  if scopeOk and liveOk and classOk then out[#out+1]=who end
 end
 local fk=self.NameKey(self.FOUNDER)
 table.sort(out,function(a,b)
  if a==b then return false end
  local la,lb=self:ProviderLive(a)==true,self:ProviderLive(b)==true
  if la~=lb then return la end
  local fa,fb=self.NameKey(a)==fk,self.NameKey(b)==fk
  if fa~=fb then return fa end
  return a<b
 end)
 self.lastDirectoryCount=#out;return out
end
local request=U.Request
function U:Request(destination,join,details)
 local scheduled=details and details.scheduledAt or self.bookingTime
 if not self:CanBookDriver(self.db.provider)and not(scheduled and not join and not self:ProviderLive(self.db.provider)and self:CanQueueDriver(self.db.provider))then
  self:Notice('Booking unavailable: driver must match your ruleset and faction. All drivers is browsing-only.');return false
 end
 return request(self,destination,join,details)
end
local selectDriver=U.SelectDriver
function U:SelectDriver(who,...)
 if not self:CanQueueDriver(who)then self:Notice('This driver is outside your ruleset and faction.');return false end
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
  self.db.driverScopes[key]={realm=p[2],ruleset=self:NormalizeRuleset(p[2])or '',faction=p[3],realmID=realmID,region=region,at=GetServerTime(),sentAt=modern and at or nil,version=modern and 2 or 1}
  self:Refresh();return
 end
 return receive(self,text,sender,channel)
end
local function scopeTag(self)
 local own=self:LocalScope()
 return (own.ruleset~=''and own.ruleset or own.realm)..' / '..own.faction
end
local function filterSummaryText(self)
 local f=self:DriverFilters();local tag=scopeTag(self)
 if not f.availableToMe and not f.onlineOnly and f.warlock and f.mage then return 'Filter: Showing all drivers'end
 local parts={f.availableToMe and tag or 'All scopes'}
 if f.onlineOnly then parts[#parts+1]='Online'end
 if f.warlock~=f.mage then parts[#parts+1]=f.warlock and 'Warlocks'or 'Mages'
 elseif not f.warlock and not f.mage then parts[#parts+1]='No classes'end
 return 'Filter: '..table.concat(parts,' · ')
end
function U:UpdateFilterMenu()
 local m=self.filterMenu;if not m then return end
 local f=self:DriverFilters();local tag=scopeTag(self)
 if m.subtitle then m.subtitle:SetText('Detected: '..tag)end
 for _,opt in ipairs(m.checks or {})do
  opt.box:SetChecked(f[opt.key]==true)
  if opt.key=='availableToMe'then opt.label:SetText('Available to me ('..tag..')')else opt.label:SetText(opt.staticLabel)end
 end
end
local function buildFilterMenu(self,anchor)
 local m=CreateFrame('Frame','UberFilterMenu',UIParent or anchor,'BackdropTemplate');self.filterMenu=m
 m:SetSize(326,224);m:SetFrameStrata('FULLSCREEN_DIALOG');m:SetToplevel(true);m:EnableMouse(true);m:SetClampedToScreen(true)
 m:SetPoint('TOPRIGHT',anchor,'BOTTOMRIGHT',0,-2)
 m:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',tile=false,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 m:SetBackdropColor(.02,.045,.10,1);m:SetBackdropBorderColor(.16,.36,.65,1);m:Hide()
 if UISpecialFrames then table.insert(UISpecialFrames,'UberFilterMenu')end
 local title=m:CreateFontString(nil,'OVERLAY','GameFontNormal');title:SetPoint('TOPLEFT',16,-14);title:SetWidth(294);title:SetJustifyH('LEFT');title:SetText('|cff60b8ffDRIVER FILTERS|r')
 local sub=m:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');sub:SetPoint('TOPLEFT',16,-32);sub:SetWidth(294);sub:SetJustifyH('LEFT');sub:SetTextColor(.70,.82,.96);m.subtitle=sub
 m.checks={}
 for i,opt in ipairs(FILTER_OPTIONS)do
  local y=-58-(i-1)*28
  local box=CreateFrame('CheckButton',nil,m,'UICheckButtonTemplate');box:SetSize(24,24);box:SetPoint('TOPLEFT',14,y)
  if box.SetHitRectInsets then box:SetHitRectInsets(0,-264,0,0)end
  local txt=m:CreateFontString(nil,'OVERLAY','GameFontHighlight');txt:SetPoint('LEFT',box,'RIGHT',6,0);txt:SetWidth(264);txt:SetJustifyH('LEFT')
  box:SetScript('OnClick',function(c)self:SetDriverFilter({[opt.key]=not not c:GetChecked()})end)
  m.checks[#m.checks+1]={key=opt.key,box=box,label=txt,staticLabel=opt.label}
 end
 local function menuBtn(text,point,x,fn)
  local btn=CreateFrame('Button',nil,m,'UIPanelButtonTemplate');btn:SetSize(94,26);btn:SetPoint(point,x,14);btn:SetText(text);btn:SetScript('OnClick',fn);return btn
 end
 menuBtn('Show all','BOTTOMLEFT',14,function()self:SetDriverFilter('ALL')end)
 menuBtn('Reset','BOTTOM',0,function()self:SetDriverFilter('RESET')end)
 menuBtn('Close','BOTTOMRIGHT',-14,function()m:Hide()end)
 return m
end
local refresh=U.Refresh
function U:Refresh(...)
 refresh(self,...)
 for _,row in ipairs(self.rosterRows or {})do if type(row.driver)=='string'then
  local allowed=self:CanQueueDriver(row.driver);row:SetAlpha(allowed and 1 or .4)
  if row.order then row.order:SetEnabled(allowed==true)end
  local s=self:DriverScope(row.driver)
  row.title:SetText(row.title:GetText()..' · '..self:FormatDriverScope(s))
 end end
 local view=self.views and self.views.Drivers
 if view and not self.scopeFilterButton then
  local b=CreateFrame('Button',nil,view,'UIPanelButtonTemplate');self.scopeFilterButton=b
  b:SetSize(330,28);b:SetPoint('TOPRIGHT',-12,-4)
  buildFilterMenu(self,b)
  if view.HookScript then view:HookScript('OnHide',function()if self.filterMenu then self.filterMenu:Hide()end end)end
  b:SetScript('OnClick',function()
   if self.filterMenu and self.filterMenu:IsShown()then self.filterMenu:Hide()
   elseif self.filterMenu then self:UpdateFilterMenu();self.filterMenu:Show();self.filterMenu:Raise()end
  end)
  b:SetScript('OnEnter',function()
   local tag=scopeTag(self)
   GameTooltip:SetOwner(b,'ANCHOR_BOTTOM');GameTooltip:SetText('Driver Filters ('..tag..')')
   GameTooltip:AddLine('Click to filter drivers by Ruleset & Faction availability, online status, and class (Warlock / Mage).',1,1,1,true)
   GameTooltip:Show()
  end)
  b:SetScript('OnLeave',function()GameTooltip:Hide()end)
 end
 if view and not self.emptyFilterLabel then
  local empty=view:CreateFontString(nil,'OVERLAY','GameFontNormal');self.emptyFilterLabel=empty
  empty:SetPoint('TOPLEFT',24,-210);empty:SetWidth(844);empty:SetJustifyH('CENTER');empty:SetTextColor(.70,.82,.96)
  empty:SetText("No drivers match your current filters.\nOpen Filter above to uncheck 'Online only', pick another class, or click 'Show all'.")
 end
 if self.emptyFilterLabel then self.emptyFilterLabel:SetShown((self.lastDirectoryCount or 0)==0)end
 if self.scopeFilterButton then self.scopeFilterButton:SetText(filterSummaryText(self))end
 self:UpdateFilterMenu()
end
