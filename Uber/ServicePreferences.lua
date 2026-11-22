local U=Uber
function U:ServicePreferences()
 self.db.servicePreferences=self.db.servicePreferences or {}
 local key=GetUnitName('player',true)..':'..(GetNormalizedRealmName and GetNormalizedRealmName()or GetRealmName())
 self.db.servicePreferences[key]=self.db.servicePreferences[key]or {remember=false,open=true}
 return self.db.servicePreferences[key]
end
local open=U.OpenService
function U:OpenService(...)
 local ok=open(self,...)
 if ok then self:ServicePreferences().open=self.online==true end
 return ok
end
function U:ApplyStartupService()
 if not self.db or self.serviceStartupApplied then return end
 self.serviceStartupApplied=true
 local cfg=self:ServicePreferences();local _,class=UnitClass('player')
 local allowed=(class=='WARLOCK'or class=='MAGE')and self:Approved(GetUnitName('player',true))and self:DriverClass(GetUnitName('player',true))==class
 local wanted=not cfg.remember or cfg.open~=false
 if wanted and allowed and not self.online then
  -- Opening availability does not resume an old summon camp after login.
  if self.db.active and self.db.active.status~='COMPLETE'and self.db.active.status~='CANCELLED'then self.db.active.status='CANCELLED' end
  open(self)
 end
 self:Refresh()
end
local init=U.Init
function U:Init(...)
 init(self,...)
 if IsLoggedIn and IsLoggedIn()then self:ApplyStartupService()end
end
local events=CreateFrame('Frame');events:RegisterEvent('PLAYER_LOGIN')
events:SetScript('OnEvent',function()U:ApplyStartupService()end)
local refresh=U.Refresh
function U:Refresh(...)
 refresh(self,...)
 local view=self.views and self.views['Driver desk']
 if view and not self.rememberServiceCheck then
  local box=CreateFrame('CheckButton',nil,view,'UICheckButtonTemplate');self.rememberServiceCheck=box
  box:SetSize(25,25);box:SetPoint('TOPLEFT',555,-64)
  local label=box:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');label:SetPoint('LEFT',box,'RIGHT',4,0);label:SetWidth(300);label:SetJustifyH('LEFT');label:SetText('Remember service ON/OFF after restart');label:SetTextColor(.30,.65,1)
  box:SetScript('OnClick',function(b)local cfg=self:ServicePreferences();cfg.remember=b:GetChecked()==true;cfg.open=self.online==true;self:Notice(cfg.remember and 'Current service choice will be restored after login.'or 'Approved drivers open service at login by default.');end)
 end
 if self.rememberServiceCheck then self.rememberServiceCheck:SetChecked(self:ServicePreferences().remember==true)end
end
