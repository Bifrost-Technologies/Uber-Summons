local passed=0;local function check(v,m)assert(v,m);passed=passed+1 end
local w={};local frames={}
setmetatable(w,{__index=function()return function()end end})
function w:SetScript(k,v)self.scripts[k]=v end
function w:Show()self.shown=true end;function w:Hide()self.shown=false end;function w:IsShown()return self.shown==true end
function w:SetText(t)self.text=t end;function w:SetShown(v)self.shown=v end
function w:SetSize(width,height)self.width=width;self.height=height end
function w:SetTexture(texture)self.texture=texture end
function w:SetTexCoord(...)self.texCoord={...}end
function w:CreateFontString()return CreateFrame()end;w.CreateTexture=w.CreateFontString
CreateFrame=function()local f=setmetatable({scripts={},shown=false}, {__index=w});frames[#frames+1]=f;return f end
UIParent={};Minimap=CreateFrame();UISpecialFrames={};SlashCmdList={}
local clock=10000;GetServerTime=function()return clock end;GetUnitName=function()return 'Provider-Realm'end
GetNormalizedRealmName=function()return 'Realm'end;IsInGuild=function()return false end
C_ChatInfo={RegisterAddonMessagePrefix=function()end};local buzzes=0;PlaySound=function()buzzes=buzzes+1 end
assert(loadfile('Uber/Uber.lua'))()
local u=Uber;u.Refresh=function()end;u.Audit=function()end;u.Show=function(self)self.frame=self.frame or CreateFrame();self.frame:Show()end
assert(loadfile('Uber/Notifications.lua'))();u:Init()
check(u.minimapButton~=nil,'Minimap launcher created after initialization')
check(u:ShowWelcome()and u.welcomeFrame:IsShown(),'First-run welcome splash can be opened')
check(u.welcomeFrame.width==768 and u.welcomeFrame.height==512,'Splash is centered at a compact 3:2 size')
local splash
for _,frame in ipairs(frames)do if frame.texture=='Interface\\AddOns\\Uber\\UberSplash'then splash=frame end end
check(splash and splash.texCoord[1]==.21875 and splash.texCoord[2]==.78125 and splash.texCoord[3]==.125 and splash.texCoord[4]==.875,'Texture coordinates crop the padded image canvas without stretching')
u.welcomeContinue.scripts.OnClick()
check(u.db.notifications.welcomeSeen and u.minimapGuide:IsShown()and u.minimapGlow:IsShown(),'Continue marks welcome seen and spotlights the minimap icon')
check(not u:ShowWelcome(),'Welcome is not repeated after acknowledgement')
u:ShowWelcome(true);check(u.welcomeFrame:IsShown(),'Welcome can be replayed')
u.welcomeContinue.scripts.OnClick();u.minimapGuideDone.scripts.OnClick()
check(not u.minimapGuide:IsShown()and not u.minimapGlow:IsShown(),'Minimap guide dismisses cleanly')
check(SlashCmdList.UBERINTRO~=nil,'Welcome replay slash command registered')
check(u:NotifyInbox('First','Body','one'),'Notification inserted')
check(not u:NotifyInbox('Duplicate','Body','one'),'Duplicate event suppressed')
check(select(1,u:NotificationCounts())==1 and buzzes==1,'Unread count and sound updated')
u:NotifyInbox('Second','Body','two');check(buzzes==1,'Sound bursts rate limited')
u:ReadNotification(1);local unread,total=u:NotificationCounts();check(unread==1 and total==2,'Read operation preserves history and updates count')
u:ShowMailbox();check(u.mailFrame:IsShown()and u.mailRows[1].item.id==2,'Mailbox shows newest notification first')
u.mailRows[1].scripts.OnClick(u.mailRows[1]);check(select(1,u:NotificationCounts())==0,'Click marks individual item read')
u.minimapButton.scripts.OnClick(nil,'LeftButton');check(u.frame:IsShown(),'Left click opens Uber')
u.minimapButton.scripts.OnClick(nil,'LeftButton');check(not u.frame:IsShown(),'Left click closes Uber')
u.minimapButton.scripts.OnClick(nil,'RightButton');check(u.mailFrame:IsShown(),'Right click opens mailbox')
u.online=true;clock=11000
u:Receive('R|11000-1|-|Camp','Rider-Realm','WHISPER')
check(select(1,u:NotificationCounts())==1,'Validated new request notifies driver')
local _,before=u:NotificationCounts();u:Receive('R|11000-1|-|Camp','Rider-Realm','WHISPER');check(select(2,u:NotificationCounts())==before,'Repeated request produces no extra notification')
u:Receive('R|bad','Imposter-Realm','WHISPER');check(select(2,u:NotificationCounts())==before,'Invalid request produces no notification')
u.db.provider='Chosen-Realm';u.db.outbox.test={provider='Chosen-Realm',destination='Camp',status='Awaiting receipt'}
u:Receive('A|test|OK','Imposter-Realm','WHISPER');check(select(2,u:NotificationCounts())==before,'Unauthorized receipt produces no notification')
u:Receive('A|test|OK','Chosen-Realm','WHISPER');check(select(2,u:NotificationCounts())==before+1,'Authorized order receipt creates notification')
u:Init();check(select(2,u:NotificationCounts())==before+1,'Notification history survives reinitialization')
u:NotificationDB().sound=false;local n=buzzes;clock=12000;u:NotifyInbox('Quiet','Body','quiet');check(buzzes==n,'Sound toggle suppresses buzz')
for i=1,110 do u:NotifyInbox('Item','Body','cap'..i)end;check(select(2,u:NotificationCounts())==100,'Mailbox storage bounded to 100 entries')
print('PASS: '..passed..' Uber notification assertions')
