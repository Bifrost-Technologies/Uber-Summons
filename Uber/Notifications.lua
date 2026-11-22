local U=Uber
U.icon='Interface\\AddOns\\Uber\\UberIcon'
local function now()return GetServerTime()end
local function clean(v,n)return type(v)=='string'and v:gsub('[%c|]',''):sub(1,n)or ''end
function U:NotificationDB()
 self.db.notifications=type(self.db.notifications)=='table'and self.db.notifications or {}
 local d=self.db.notifications;d.items=type(d.items)=='table'and d.items or {};d.serial=d.serial or 0
 if d.sound==nil then d.sound=true end;if d.toast==nil then d.toast=true end
 return d
end
function U:NotificationCounts()
 local unread=0;local d=self:NotificationDB();for _,item in ipairs(d.items)do if not item.read then unread=unread+1 end end
 return unread,#d.items
end
function U:NotifyInbox(title,body,key)
 local d=self:NotificationDB();key=clean(key,200)
 for _,item in ipairs(d.items)do if key~=''and item.key==key then return false end end
 d.serial=d.serial+1;table.insert(d.items,1,{id=d.serial,at=now(),title=clean(title,100),body=clean(body,500),key=key,read=false})
 while #d.items>100 do table.remove(d.items)end
 if d.sound and now()-(self.notificationSoundAt or -10)>=3 then
  self.notificationSoundAt=now();if PlaySound then pcall(PlaySound,SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856,'Master')end
 end
 if d.toast and UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage('Uber: '..clean(title,100),.35,1,.75,1,5)end
 self:RefreshNotifications();return true
end
function U:PlayFeedback(kind)
 if not self.db or not self:NotificationDB().sound or not PlaySound then return end
 local t=GetTime and GetTime()or now()
 if t-(self.uiSoundAt or -10)<.15 then return end;self.uiSoundAt=t
 local sounds={open=SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPEN or 850,tab=SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB or 841,mail=SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPEN or 850,read=SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856}
 pcall(PlaySound,sounds[kind]or 856,'SFX')
end
function U:ReadNotification(id)
 for _,item in ipairs(self:NotificationDB().items)do if item.id==id then item.read=true;self:PlayFeedback("read");self:RefreshNotifications();return true end end
 return false
end
function U:RefreshNotifications()
 if not self.db then return end
 local unread,total=self:NotificationCounts()
 if self.minimapBadge then self.minimapBadge:SetText(unread>0 and tostring(unread)or '');self.minimapBadge:SetShown(unread>0)end
 if self.mailEntry then self.mailEntry:SetText('Mailbox ('..unread..')')end
 if not self.mailFrame or not self.mailFrame:IsShown()then return end
 local d=self:NotificationDB();local pages=math.max(1,math.ceil(total/6));self.mailPage=math.max(1,math.min(self.mailPage or 1,pages))
 self.mailSummary:SetText(unread..' unread / '..(total-unread)..' read / '..total..' total · Page '..self.mailPage..'/'..pages)
 for i,b in ipairs(self.mailRows)do local item=d.items[(self.mailPage-1)*6+i];b.item=item
  if item then b:SetText((item.read and '[Read] 'or '[NEW] ')..item.title..'\n'..item.body:sub(1,140)..(#item.body>140 and '…'or '')..'\n'..(date and date('%d %b %H:%M',item.at)or tostring(item.at)));b:Show()else b:Hide()end
 end
 self.mailSound:SetText((d.sound and '[ON] 'or '[OFF] ')..'Notification sound')
 self.mailToast:SetText((d.toast and '[ON] 'or '[OFF] ')..'Popup notices')
end
local function button(p,t,x,y,w,h,fn)
 local b=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');b:SetSize(w,h);b:SetPoint('TOPLEFT',x,y);b:SetText(t);b:SetScript('OnClick',fn);return b
end
function U:ShowMailbox()
 if not self.db then return end
 self:PlayFeedback("mail")
 if not self.mailFrame then
  local f=CreateFrame('Frame','UberMailbox',UIParent,'BackdropTemplate');self.mailFrame=f;f:SetSize(740,640);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag('LeftButton');f:SetScript('OnDragStart',f.StartMoving);f:SetScript('OnDragStop',f.StopMovingOrSizing)
  f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=16});f:SetBackdropColor(.015,.035,.085,.98)
  local title=f:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');title:SetPoint('TOPLEFT',25,-22);title:SetText('UBER / NOTIFICATION MAILBOX')
  self.mailSummary=f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');self.mailSummary:SetPoint('TOPLEFT',25,-56)
  button(f,'X',690,-15,30,25,function()f:Hide()end);table.insert(UISpecialFrames,'UberMailbox')
  self.mailRows={};for i=1,6 do self.mailRows[i]=button(f,'',25,-90-(i-1)*70,690,64,function(b)if b.item then U:ReadNotification(b.item.id)end end)
   self.mailRows[i]:SetScript('OnEnter',function(b)if b.item and GameTooltip then GameTooltip:SetOwner(b,'ANCHOR_RIGHT');GameTooltip:SetText(b.item.title);GameTooltip:AddLine(b.item.body,1,1,1,true);GameTooltip:Show()end end)
   self.mailRows[i]:SetScript('OnLeave',function()if GameTooltip then GameTooltip:Hide()end end)
  end
  button(f,'Previous',25,-520,140,28,function()U.mailPage=math.max(1,(U.mailPage or 1)-1);U:RefreshNotifications()end)
  button(f,'Next',175,-520,140,28,function()U.mailPage=(U.mailPage or 1)+1;U:RefreshNotifications()end)
  button(f,'Mark all read',325,-520,180,28,function()for _,item in ipairs(U:NotificationDB().items)do item.read=true end;U:RefreshNotifications()end)
  self.mailSound=button(f,'',25,-565,220,28,function()local d=U:NotificationDB();d.sound=not d.sound;U:RefreshNotifications()end)
  self.mailToast=button(f,'',260,-565,220,28,function()local d=U:NotificationDB();d.toast=not d.toast;U:RefreshNotifications()end)
  button(f,'Clear read',495,-565,220,28,function()local d=U:NotificationDB();for i=#d.items,1,-1 do if d.items[i].read then table.remove(d.items,i)end end;U:RefreshNotifications()end)
 end
 self.mailFrame:Show();self:RefreshNotifications()
end
function U:PositionMinimap()
 local angle=self:NotificationDB().angle or 35
 if type(angle)~='number'then angle=35 end
 self.minimapButton:ClearAllPoints();self.minimapButton:SetPoint('CENTER',Minimap,'CENTER',math.cos(angle*math.pi/180)*82,math.sin(angle*math.pi/180)*82)
end
function U:CreateMinimap()
 if self.minimapButton or not Minimap then return end
 local b=CreateFrame('Button','UberMinimapButton',Minimap);self.minimapButton=b;b:SetSize(32,32);b:SetFrameStrata('MEDIUM');b:SetFrameLevel(10);b:RegisterForClicks('LeftButtonUp','RightButtonUp');b:RegisterForDrag('LeftButton');b:EnableMouse(true)
 local icon=b:CreateTexture(nil,'ARTWORK');icon:SetAllPoints();icon:SetTexture(self.icon)
 self.minimapBadge=b:CreateFontString(nil,'OVERLAY','GameFontNormalSmall');self.minimapBadge:SetPoint('TOPRIGHT',4,4);self.minimapBadge:SetTextColor(1,.85,.1)
 b:SetScript('OnClick',function(_,which)U:HideMinimapGuide();if which=='RightButton'then U:ShowMailbox()elseif U.frame and U.frame:IsShown()then U.frame:Hide()else U:Show()end end)
 b:SetScript('OnDragStart',function(self)self:SetScript('OnUpdate',function()
  if not GetCursorPosition or not Minimap.GetCenter then return end
  local x,y=GetCursorPosition();local cx,cy=Minimap:GetCenter();local scale=Minimap:GetEffectiveScale()
  if not cx or not cy or not scale or scale==0 then return end
  local angle=math.atan2 and math.atan2(y/scale-cy,x/scale-cx)
  if angle then U:NotificationDB().angle=angle*180/math.pi;U:PositionMinimap()end
 end)end)
 b:SetScript('OnDragStop',function(self)self:SetScript('OnUpdate',nil)end)
 b:SetScript('OnEnter',function(self)if GameTooltip then local unread,total=U:NotificationCounts();GameTooltip:SetOwner(self,'ANCHOR_LEFT');GameTooltip:SetText('Uber');GameTooltip:AddLine('Left-click: open/close · Right-click: mailbox',1,1,1);GameTooltip:AddLine(unread..' unread / '..total..' notifications',.4,1,.7);GameTooltip:AddLine('Drag to move around minimap.',.8,.8,.8);GameTooltip:Show()end end)
 b:SetScript('OnLeave',function()if GameTooltip then GameTooltip:Hide()end end)
 self:PositionMinimap();self:RefreshNotifications()
end
function U:HideMinimapGuide()
 if self.minimapGuide then self.minimapGuide:Hide()end
 if self.minimapGlow then self.minimapGlow:Hide();self.minimapGlow:SetScript('OnUpdate',nil)end
end
function U:ShowMinimapGuide()
 if not self.minimapButton then self:CreateMinimap()end
 local b=self.minimapButton;if not b then return false end
 if not self.minimapGlow then
  local ring=CreateFrame('Frame',nil,UIParent);ring:SetSize(54,54);ring:SetFrameStrata('TOOLTIP');ring:SetFrameLevel(100);ring:EnableMouse(false)
  ring.texture=ring:CreateTexture(nil,'OVERLAY');ring.texture:SetAllPoints();ring.texture:SetTexture('Interface\\Buttons\\UI-ActionButton-Border');ring.texture:SetBlendMode('ADD')
  self.minimapGlow=ring
 end
 self.minimapGlow:ClearAllPoints();self.minimapGlow:SetPoint('CENTER',b,'CENTER',0,0);self.minimapGlow:Show()
 self.minimapGlow:SetScript('OnUpdate',function(frame)frame.texture:SetAlpha(.58+.35*math.sin((GetTime and GetTime()or now())*5))end)
 if not self.minimapGuide then
  local f=CreateFrame('Frame','UberMinimapGuide',UIParent,'BackdropTemplate');self.minimapGuide=f;f:SetSize(285,112);f:SetFrameStrata('TOOLTIP');f:SetClampedToScreen(true);f:EnableMouse(true)
  f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12});f:SetBackdropColor(.025,.045,.075,.98)
  local title=f:CreateFontString(nil,'OVERLAY','GameFontNormal');title:SetPoint('TOPLEFT',16,-13);title:SetText('UBER IS ON YOUR MINIMAP')
  local text=f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');text:SetPoint('TOPLEFT',16,-36);text:SetWidth(252);text:SetJustifyH('LEFT');text:SetText('Left-click the glowing icon to open or close Uber. Right-click opens your notification mailbox.')
  self.minimapGuideDone=button(f,'Got it',100,-78,85,24,function()U:HideMinimapGuide()end)
 end
 local x=b.GetCenter and b:GetCenter();local rightOfCenter=x and UIParent.GetWidth and x>UIParent:GetWidth()/2
 self.minimapGuide:ClearAllPoints()
 if rightOfCenter then self.minimapGuide:SetPoint('RIGHT',b,'LEFT',-14,0)else self.minimapGuide:SetPoint('LEFT',b,'RIGHT',14,0)end
 self.minimapGuide:Show();return true
end
function U:ShowWelcome(force)
 if not self.db or(self:NotificationDB().welcomeSeen and not force)then return false end
 if not self.welcomeFrame then
  local f=CreateFrame('Frame','UberWelcome',UIParent,'BackdropTemplate');self.welcomeFrame=f;f:SetSize(768,512);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true);f:EnableMouse(true)
  f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=18});f:SetBackdropColor(.015,.03,.09,1)
  local art=f:CreateTexture(nil,'BACKGROUND');art:SetAllPoints();art:SetTexture('Interface\\AddOns\\Uber\\UberSplash');art:SetTexCoord(.21875,.78125,.125,.875)
  local shade=f:CreateTexture(nil,'ARTWORK');shade:SetAllPoints();shade:SetTexture('Interface\\Buttons\\WHITE8X8');shade:SetVertexColor(.015,.02,.055);shade:SetAlpha(.34)
  local title=f:CreateFontString(nil,'OVERLAY','GameFontNormalHuge');title:SetPoint('TOP',0,-30);title:SetText('UBER SUMMONS');title:SetTextColor(.75,.95,1)
  local subtitle=f:CreateFontString(nil,'OVERLAY','GameFontHighlight');subtitle:SetPoint('TOP',title,'BOTTOM',0,-8);subtitle:SetText('WARLOCK SUMMONS  |  MAGE PORTALS  |  DIMENSIONAL TRAVEL');subtitle:SetTextColor(.78,.85,1)
  local prompt=f:CreateFontString(nil,'OVERLAY','GameFontNormal');prompt:SetPoint('BOTTOM',0,88);prompt:SetText('Your next adventure is only a click away.')
  local continue=CreateFrame('Button',nil,f,'UIPanelButtonTemplate');self.welcomeContinue=continue;continue:SetSize(300,42);continue:SetPoint('BOTTOM',0,34);continue:SetText('Show me the Uber minimap icon')
  local function continueWelcome()
   U:NotificationDB().welcomeSeen=true;f:Hide();U:ShowMinimapGuide()
  end
  continue:SetScript('OnClick',continueWelcome)
  button(f,'X',723,-15,28,25,continueWelcome)
  table.insert(UISpecialFrames,'UberWelcome')
 end
 self.welcomeFrame:Show();return true
end
local init=U.Init
function U:Init()init(self);self:NotificationDB();self:CreateMinimap()end
local show=U.Show
function U:Show()
 local wasShown=self.frame and self.frame:IsShown()
 show(self)
 if not wasShown then self:PlayFeedback("open")end
 if self.frame and not self.mailEntry then self.mailEntry=button(self.frame,'Mailbox',674,-12,196,26,function()U:ShowMailbox()end)end
 self:RefreshNotifications()
end
-- Observe accepted state transitions only. Raw packets cannot create notifications.
local receive=U.Receive
function U:Receive(message,sender,channel)
 local relevant=type(message)=='string'and (message:match('^R|')or message:match('^S|')or message:match('^A|'))
 if not relevant or not self.db then return receive(self,message,sender,channel)end
 local beforeIn,beforeOut={},{}
 for id,r in pairs(self.db.inbox)do beforeIn[id]=r.status end
 for id,r in pairs(self.db.outbox)do beforeOut[id]=r.status end
 receive(self,message,sender,channel)
 for id,r in pairs(self.db.inbox)do if not beforeIn[id]then self:NotifyInbox('New service request',clean(r.sender,100)..': '..clean(r.destination,100),'request:'..id)end end
 for id,r in pairs(self.db.outbox)do if beforeOut[id]and r.status~=beforeOut[id]then self:NotifyInbox('Order update: '..clean(r.status,60),clean(r.provider,100)..' · '..clean(r.destination,100),'status:'..id..':'..r.status)end end
end
local audit=U.Audit
local noteworthy={RESERVATION_RECEIVED=true,RESERVATION_CONFIRMED=true,APPLICATION_RECEIVED=true,DELIVERY_ACK=true,DELIVERY_CORROBORATED=true,MAIL_OBSERVED=true,PAYMENT_RECEIVED=true,PROVIDER_BANNED=true}
function U:Audit(kind,subject,detail,source)
 audit(self,kind,subject,detail,source)
 if noteworthy[kind]then self:NotifyInbox(kind:gsub('_',' '),clean(subject,100)..' · '..clean(detail,300),kind..':'..clean(subject,100)..':'..clean(detail,100))end
end
SLASH_UBERMAIL1='/ubermail';SlashCmdList.UBERMAIL=function()U:ShowMailbox()end
SLASH_UBERINTRO1='/uberintro';SlashCmdList.UBERINTRO=function()U:ShowWelcome(true)end
local ready=CreateFrame('Frame');ready:RegisterEvent('PLAYER_LOGIN');ready:SetScript('OnEvent',function()if U.db then U:CreateMinimap();if not U:NotificationDB().welcomeSeen then U:ShowWelcome()end end end)
