local U=Uber
local function realm()return GetNormalizedRealmName and GetNormalizedRealmName()or GetRealmName()end
local function normalize(s)return tostring(s or ''):lower():gsub('%s','')end
function U:DriverScope(who)
 self.db.driverScopes=self.db.driverScopes or {}
 if self.NameKey(who)==self.NameKey(GetUnitName('player',true))then return {realm=realm(),faction=UnitFactionGroup('player'),at=GetServerTime()}end
 return self.db.driverScopes[self.NameKey(who)]
end
function U:CanBookDriver(who)
 local s=self:DriverScope(who)
 return s and type(s.at)=='number'and GetServerTime()-s.at>=0 and GetServerTime()-s.at<=90 and normalize(s.realm)==normalize(realm())and s.faction==UnitFactionGroup('player')
end
local request=U.Request
function U:Request(...)if not self:CanBookDriver(self.db.provider)then self:Notice('Booking unavailable: different or unconfirmed realm/faction.');return false end;return request(self,...)end
local selectDriver=U.SelectDriver
function U:SelectDriver(who,...)if not self:CanBookDriver(who)then self:Notice('This provider cannot serve your realm/faction.');return false end;return selectDriver(self,who,...)end
local advertise=U.Advertise
function U:Advertise(target)
 local packet={'SCOPE1',realm(),UnitFactionGroup('player')or 'Unknown'}
 if target then self:Send(packet,target)elseif IsInGuild and IsInGuild()then self:Send(packet,nil,'GUILD')end
 for who in pairs(self.subscribers or {})do if who~=target then self:Send(packet,who)end end
 return advertise(self,target)
end
local receive=U.Receive
function U:Receive(text,sender,channel)
 if type(text)=='string'and text:sub(1,7)=='SCOPE1|'then
  local r,f=text:match('^SCOPE1|([^|]+)|([^|]+)$')
  if r and #r<=80 and not r:find('[%c]')and(f=='Alliance'or f=='Horde')and self:Approved(sender)then
   self.db.driverScopes=self.db.driverScopes or {};self.db.driverScopes[self.NameKey(sender)]={realm=r,faction=f,at=GetServerTime()};self:Refresh()
  end
  return
 end
 return receive(self,text,sender,channel)
end
local directory=U.ProviderDirectory
function U:ProviderDirectory()
 local list=directory(self);if not self.db.realmFilter or self.db.realmFilter==''then return list end
 local out={};for _,who in ipairs(list)do local s=self:DriverScope(who);if s and normalize(s.realm)==normalize(self.db.realmFilter)then out[#out+1]=who end end;return out
end
local refresh=U.Refresh
function U:Refresh(...)
 refresh(self,...)
 for _,row in ipairs(self.rosterRows or {})do if row.driver then
  local allowed=self:CanBookDriver(row.driver);row:SetAlpha(allowed and 1 or .4)
  if row.order then row.order:SetEnabled(allowed==true)end
  local s=self:DriverScope(row.driver);if s then row.title:SetText(row.title:GetText()..' · '..s.realm..' / '..s.faction)end
 end end
 if self.frame and not self.realmFilterEdit then
  local e=CreateFrame('EditBox',nil,self.frame,'InputBoxTemplate');self.realmFilterEdit=e;e:SetSize(190,25);e:SetPoint('TOPRIGHT',-65,-20);e:SetAutoFocus(false);e:SetText(self.db.realmFilter or '');e:SetMaxLetters(80)
  e:SetScript('OnEnterPressed',function(box)self.db.realmFilter=box:GetText();box:ClearFocus();self.rosterPage=1;self:Refresh()end)
  e:SetScript('OnEnter',function()GameTooltip:SetOwner(e,'ANCHOR_BOTTOM');GameTooltip:SetText('Realm filter: blank = everyone. Enter to apply.');GameTooltip:Show()end)
  e:SetScript('OnLeave',function()GameTooltip:Hide()end)
 end
end
