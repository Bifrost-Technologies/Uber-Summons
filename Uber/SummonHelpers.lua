if _G.SummonClickHelpers then return end
local H={sent={}}
local function notify(text)if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('Summon helpers: '..text)end end
local function db()SummonClickHelpersDB=SummonClickHelpersDB or {scope='TOWN',text='Could you help click a warlock summon near {place}? Please reply if available. Thank you!'};return SummonClickHelpersDB end
local function location()return db().scope=='TOWN'and GetSubZoneText()or GetZoneText()end
local function button(f,text,y,fn)local b=CreateFrame('Button',nil,f,'UIPanelButtonTemplate');b:SetSize(500,28);b:SetPoint('TOPLEFT',20,y);b:SetText(text);b:SetScript('OnClick',fn);return b end
function H:Stop()if self.ticker then self.ticker:Cancel();self.ticker=nil end end
function H:Send()
 self:Stop();if not self.resultsReady then notify('Wait for WHO results from your new search.');return end;local cfg=db();local place=location()
 if not place or place==''or place~=self.searchedPlace or cfg.scope~=self.searchedScope then notify('Prepare a new location WHO search first.');return end
 local count=C_FriendList and C_FriendList.GetNumWhoResults or GetNumWhoResults
 local info=C_FriendList and C_FriendList.GetWhoInfo or GetWhoInfo
 if not count or not info then notify('WHO results unavailable.');return end
 local message=self.edit:GetText():gsub('{place}',function()return place end)
 if #message<1 or #message>255 or message:find('[%c|]')then notify('Use a plain message of 1–255 characters.');return end
 cfg.text=self.edit:GetText();local queue,seen={},{}
 if cfg.scope=='REGION'and not self.queryVerified then notify('Native region query could not be confirmed; using exact-area matches only. Run the prepared WHO command for full region results.')end
 for i=1,math.min(count(),100)do
  local name,zone
  if C_FriendList and info==C_FriendList.GetWhoInfo then local r=info(i);if r then name,zone=r.fullName or r.name,r.area end
  else local n,_,_,_,_,z=info(i);name,zone=n,z end
  local matches=zone==place or cfg.scope=='REGION'and self.queryVerified==true
  if type(name)=='string'and matches and not seen[name]and name~=GetUnitName('player',true)and name~=UnitName('player')and not name:find('[%c|]')and GetTime()-(self.sent[name]or -1000)>600 then seen[name]=true;queue[#queue+1]=name end
 end
 if #queue==0 then notify('No matching '..place..' results. Town mode excludes zone-only entries.');return end
 local at=1;notify('Sending to '..#queue..' matching WHO results, one every 5 seconds. Stop cancels.')
 self.ticker=C_Timer.NewTicker(5,function()
  if location()~=place then self:Stop();notify('Location changed; stopped.');return end
  local name=queue[at];if not name then self:Stop();notify('Finished helper requests.');return end
  SendChatMessage(message,'WHISPER',nil,name);self.sent[name]=GetTime();at=at+1
 end)
end
function H:Show()
 if not self.frame then
  local f=CreateFrame('Frame','SummonClickHelpers',UIParent,'BackdropTemplate');self.frame=f;f:SetSize(550,300);f:SetPoint('CENTER');f:SetClampedToScreen(true);f:EnableMouse(true);f:SetFrameStrata('DIALOG')
  f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8'});f:SetBackdropColor(.025,.055,.12,.98)
  local title=f:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');title:SetPoint('TOPLEFT',20,-20);title:SetText('SUMMON CLICK HELPERS');title:SetTextColor(.2,.8,1)
  local scope=button(f,'Scope: '..db().scope,-55,function()H:Stop();db().scope=db().scope=='TOWN'and 'REGION'or 'TOWN';H.scope:SetText('Scope: '..db().scope)end);self.scope=scope
  self.edit=CreateFrame('EditBox',nil,f,'InputBoxTemplate');self.edit:SetSize(500,28);self.edit:SetPoint('TOPLEFT',20,-100);self.edit:SetAutoFocus(false);self.edit:SetMaxLetters(255);self.edit:SetText(db().text)
  button(f,'1. Prepare native WHO search',-145,function()
   H:Stop();local place=location();if not place or place==''or place:find('[%c"|]')then notify('Location unavailable. Exact town needs a named subzone.');return end
   H.resultsReady=false;H.queryVerified=false;H.searchedPlace,H.searchedScope=place,db().scope
   local region=GetZoneText()
   if not region or region==''or region:find('[%c"|]')then notify('Zone unavailable.');return end
   H.searchQuery='z-"'..region..'"'
   ChatFrame_OpenChat('/who '..H.searchQuery)
   notify('Run WHO for the zone, then Send. Town mode keeps only results whose reported area exactly matches your town; zone-only entries are excluded.')
  end)
  button(f,'2. Send edited request to matching WHO results',-185,function()H:Send()end)
  button(f,'STOP / Close',-225,function()H:Stop();f:Hide()end)
  f:SetScript('OnHide',function()H:Stop()end)
 end
 self.frame:Show()
end
SLASH_SUMMONCLICKHELPERS1='/summonhelpers';SlashCmdList.SUMMONCLICKHELPERS=function()H:Show()end
_G.SummonClickHelpers=H

local events=CreateFrame('Frame');events:RegisterEvent('WHO_LIST_UPDATE');events:SetScript('OnEvent',function()if H.searchedPlace then H.resultsReady=true end end)

-- A verified native query lets region mode retain town-area rows from that zone.
local function observeQuery(query)
 H.resultsReady=false;H.queryVerified=type(query)=='string'and query==H.searchQuery
end
if hooksecurefunc then
 if C_FriendList and type(C_FriendList.SendWho)=='function'then pcall(hooksecurefunc,C_FriendList,'SendWho',observeQuery)
 elseif type(SendWho)=='function'then pcall(hooksecurefunc,'SendWho',observeQuery)end
end
