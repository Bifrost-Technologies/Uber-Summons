local U=Uber
local P={hosts={},last={},hosting=false};U.phaseKeepers=P
local function now()return GetServerTime()end
local function realm()return GetNormalizedRealmName and GetNormalizedRealmName()or GetRealmName()end
local function clean(s,n)return type(s)=='string'and #s>0 and #s<=n and not s:find('[%c|]')end
local function zone()return GetZoneText()end
local function alone()return not IsInGroup()and not IsInRaid()end
local function safe()return not InCombatLockdown()and not IsInInstance()and not UnitOnTaxi('player')end
local function eligible(r)return r and (r.state==nil or r.state=='READY')and (not r.remaining or r.remaining>0)and r.realm==realm()and r.faction==UnitFactionGroup('player')and r.zone==zone()and now()-r.at<=90 end
-- Local invitation budget; not a claim about the server's guest swap quota.
function P:Budget()
 U.db.phaseKeeperHistory=U.db.phaseKeeperHistory or {}
 local key=GetUnitName('player',true)..':'..realm()
 local old=U.db.phaseKeeperHistory[key]or {};local history={}
 for _,stamp in ipairs(old)do if type(stamp)=='number'and stamp<=now()and now()-stamp<600 then history[#history+1]=stamp end end
 table.sort(history);U.db.phaseKeeperHistory[key]=history
 local left=math.max(0,6-#history);local retry=left==0 and history[#history-5]+600 or 0
 return left,retry,history
end
function P:State()
 local left,retry=self:Budget()
 if not self.hosting then return 'OFF',left,retry end
 if left==0 then return 'COOLDOWN',left,retry end
 if not safe()or not alone()or self.pending then return 'BUSY',left,retry end
 return 'READY',left,retry
end
function P:RecordInvite()
 local _,_,history=self:Budget();history[#history+1]=now()
 self.advertisedAt=0;self:Advertise()
end
function P:Advertise(target)
 local state,left,retry=self:State()
 local parts={'KEEP2',realm(),UnitFactionGroup('player')or 'Unknown',zone(),state,self.label or 'Unverified',tostring(left),tostring(retry)}
 if not clean(parts[2],80)or not clean(parts[4],80)then return end
 self.watchers=self.watchers or {}
 if target then self.watchers[target]=now();U:Send(parts,target)else
  if IsInGuild()then U:Send(parts,nil,'GUILD')end
  for who,stamp in pairs(self.watchers)do if now()-stamp<600 then U:Send(parts,who)else self.watchers[who]=nil end end
 end
end
function P:Request(who)
 if not safe()or not alone()then U:Notice('Leave combat, instances, flights and existing groups before requesting a phase.');return end
 local r=self.hosts[who];if not eligible(r)then U:Notice('Host must be freshly listed in your realm, faction and zone.');return end
 if now()-(self.requestAt or 0)<60 then U:Notice('Wait 60 seconds between phase requests.');return end
 self.requestAt=now();self.requestHost=who
 U:Send({'PHASE1',realm(),UnitFactionGroup('player'),zone()},who)
 U:Notice('Phase request sent. The keeper must accept; accept their native group invite manually. A layer change is not guaranteed.')
end
function P:Reply(accept,data)
 local r=self.pending;self.pending=nil
 if not r or r~=data or now()-r.at>30 then return end
 if accept and self:State()=='READY'and r.zone==zone()then
  local invite=C_PartyInfo and C_PartyInfo.InviteUnit or InviteUnit
  if not invite then U:Notice('Group invitation API unavailable.');return end
  local ok,result=pcall(invite,r.sender);ok=ok and result~=false
  if ok then self:RecordInvite()end
  U:Send({'PHASER1',ok and 'INVITED'or 'DECLINED'},r.sender)
  U:Notice(ok and 'Group invitation attempted. The game controls phasing; verify the result with your guest.'or 'Invitation failed.')
 else U:Send({'PHASER1','DECLINED'},r.sender)end
end
StaticPopupDialogs.UBER_PHASE_KEEPER={text='%s requests your phase. Invite them to a temporary party? The game controls the resulting layer.',button1='Invite',button2='Decline',timeout=30,whileDead=false,hideOnEscape=true,preferredIndex=3,
 OnAccept=function(_,data)P:Reply(true,data)end,OnCancel=function(_,data)P:Reply(false,data)end}
local receive=U.Receive
function U:Receive(text,sender,channel)
 if type(text)~='string'or not clean(sender,100)then return receive(self,text,sender,channel)end
 local parts={};for v in (text..'|'):gmatch('(.-)|')do parts[#parts+1]=v end
 if parts[1]=='KEEPQ1'then
  if #parts~=1 or not P.hosting then return end
  if now()-(P.last[sender..':query']or 0)<30 then return end
  P.last[sender..':query']=now();P:Advertise(sender);return
 elseif parts[1]=='KEEP2'then
  local left,retry=tonumber(parts[7]),tonumber(parts[8])
  if #parts~=8 or not clean(parts[2],80)or not clean(parts[4],80)or not clean(parts[6],40)or(parts[3]~='Alliance'and parts[3]~='Horde')or not ({READY=true,OFF=true,BUSY=true,COOLDOWN=true})[parts[5]]or not left or left%1~=0 or left<0 or left>6 or not retry or retry<0 or retry>now()+660 then return end
  if parts[5]=='OFF'then P.hosts[sender]=nil;return end
  local count=0;for who,r in pairs(P.hosts)do if now()-r.at>90 then P.hosts[who]=nil else count=count+1 end end
  if count>=100 and not P.hosts[sender]then return end
  P.hosts[sender]={realm=parts[2],faction=parts[3],zone=parts[4],label=parts[6],at=now(),state=parts[5],remaining=left,retry=retry};return
 elseif parts[1]=='KEEP1'then
  if #parts~=6 or not clean(parts[2],80)or not clean(parts[4],80)or not clean(parts[6],40)or(parts[3]~='Alliance'and parts[3]~='Horde')or(parts[5]~='0'and parts[5]~='1')then return end
  if parts[5]=='0'then P.hosts[sender]=nil;return end
  local count=0;for who,r in pairs(P.hosts)do if now()-r.at>90 then P.hosts[who]=nil else count=count+1 end end
  if count>=100 and not P.hosts[sender]then return end
  P.hosts[sender]={realm=parts[2],faction=parts[3],zone=parts[4],label=parts[6],at=now()};return
 elseif parts[1]=='PHASE1'then
  if channel~='WHISPER'or #parts~=4 or parts[2]~=realm()or parts[3]~=UnitFactionGroup('player')or parts[4]~=zone()then return end
  if P:State()~='READY'or P.pending or now()-(P.last[sender]or 0)<60 then return end
  P.last[sender]=now();P.pending={sender=sender,zone=parts[4],at=now()}
  StaticPopup_Show('UBER_PHASE_KEEPER',sender,nil,P.pending);return
 elseif parts[1]=='PHASER1'then
  if channel=='WHISPER'and sender==P.requestHost and now()-(P.requestAt or 0)<60 and #parts==2 then
   U:Notice(parts[2]=='INVITED'and 'Keeper attempted an invite. Accept the native party invitation to try phasing.'or 'Keeper declined or is unavailable.');P.requestHost=nil
  end
  return
 end
 return receive(self,text,sender,channel)
end
local function button(f,text,y,fn)local b=CreateFrame('Button',nil,f,'UIPanelButtonTemplate');b:SetSize(520,28);b:SetPoint('TOPLEFT',20,y);b:SetText(text);b:SetScript('OnClick',fn);return b end
function P:Show()
 if not self.frame then
  local f=CreateFrame('Frame','UberPhaseKeepers',UIParent,'BackdropTemplate');self.frame=f;f:SetSize(565,530);f:SetPoint('CENTER');f:SetFrameStrata('FULLSCREEN_DIALOG');f:SetToplevel(true);f:SetClampedToScreen(true);f:EnableMouse(true)
  f:SetMovable(true);f:RegisterForDrag('LeftButton');f:SetScript('OnDragStart',f.StartMoving);f:SetScript('OnDragStop',f.StopMovingOrSizing)
  f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=16});f:SetBackdropColor(.02,.045,.10,1);f:SetBackdropBorderColor(.16,.36,.65)
  local t=f:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');t:SetPoint('TOPLEFT',20,-20);t:SetText('UBER / PHASE KEEPERS');t:SetTextColor(.30,.65,1)
  local close=CreateFrame('Button',nil,f,'UIPanelButtonTemplate');close:SetSize(30,28);close:SetPoint('TOPRIGHT',-14,-14);close:SetText('X');close:SetScript('OnClick',function()f:Hide()end)
  table.insert(UISpecialFrames,'UberPhaseKeepers')
  self.hostButton=button(f,'Host OFF — click to host',-55,function()
   if not self.hosting and(not safe()or not alone())then U:Notice('Host while solo, outdoors, on the ground and out of combat.');return end
   self.hosting=not self.hosting;self.label=self.labelEdit:GetText();if not clean(self.label,40)then self.label='Unverified'end
   self.hostButton:SetText(self.hosting and 'Host ON — click to stop'or 'Host OFF — click to host');self:Advertise()
   if not self.hosting then StaticPopup_Hide('UBER_PHASE_KEEPER');self.pending=nil end
  end)
  self.labelEdit=CreateFrame('EditBox',nil,f,'InputBoxTemplate');self.labelEdit:SetSize(520,25);self.labelEdit:SetPoint('TOPLEFT',20,-100);self.labelEdit:SetAutoFocus(false);self.labelEdit:SetMaxLetters(40);self.labelEdit:SetText('Unverified layer — manual label')
  self.labelEdit:SetScript('OnEscapePressed',function(s)s:ClearFocus()end);self.labelEdit:SetScript('OnEnterPressed',function(s)s:ClearFocus()end)
  button(f,'Refresh known keepers / ask guild',-140,function()
   if now()-(self.discoverAt or 0)<15 then return end;self.discoverAt=now()
   if IsInGuild()then U:Send({'KEEPQ1'},nil,'GUILD')end
   local sent=0;for who in pairs(self.hosts)do if sent<20 then U:Send({'KEEPQ1'},who);sent=sent+1 end end
  end)
  self.rows={};for i=1,6 do local row=button(f,'No keeper',-185-(i-1)*40,function()local r=self.rows[i];if r.who then self:Request(r.who)end end);self.rows[i]=row end
  local note=f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');note:SetPoint('TOPLEFT',20,-430);note:SetSize(520,45);note:SetText('Layer labels are manual/unverified. Local host limit: 6 invitation attempts per rolling 10 minutes; auto pauses/resumes while enabled. This is not the guest’s server swap allowance. Click hosting to cancel auto-resume.')
  button(f,'Close',-485,function()f:Hide()end)
  f:SetScript('OnUpdate',function(_,dt)
   self.elapsed=(self.elapsed or 0)+dt;if self.elapsed<1 then return end;self.elapsed=0
   local list={};for who,r in pairs(self.hosts)do if now()-r.at<=90 then list[#list+1]=who end end;table.sort(list)
   for i,row in ipairs(self.rows)do local who=list[i];row.who=who;local r=who and self.hosts[who];row:SetText(r and (who..' · '..r.zone..' · '..r.label..(r.remaining and (' · '..r.remaining..'/6 invites left')or '')..(r.state=='COOLDOWN'and (' · '..math.max(0,r.retry-now())..'s cooldown')or r.state=='BUSY'and ' · Paused'or ''))or 'No known keeper');row:SetEnabled(eligible(r)==true)end
  end)
 end
 self.frame:Show();self.frame:Raise()
end
local tick=U.Tick
function U:Tick()
 tick(self);if not self.db then return end
 if P.pending and now()-P.pending.at>30 then P.pending=nil end
 local state,left,retry=P:State()
 if P.hostButton then P.hostButton:SetText(state=='COOLDOWN'and ('Cooldown '..math.max(0,retry-now())..'s — auto resume enabled')or state=='BUSY'and 'Host paused — waiting for solo / outdoor / out of combat'or state=='READY'and ('Hosting — '..left..'/6 invitations left')or 'Host OFF — click to enable')end
 if P.hosting and (state~=P.lastState or now()-(P.advertisedAt or 0)>=30)then P.advertisedAt=now();P:Advertise()end
 P.lastState=state
 if self.frame and not self.phaseButton then P.entry=true;local b=CreateFrame('Button',nil,self.frame,'UIPanelButtonTemplate');self.phaseButton=b;b:SetPoint('BOTTOMLEFT',20,12);b:SetSize(180,26);b:SetText('Phase keepers');b:SetScript('OnClick',function()P:Show()end)end
end
SLASH_UBERPHASE1='/uberphase';SlashCmdList.UBERPHASE=function()P:Show()end
