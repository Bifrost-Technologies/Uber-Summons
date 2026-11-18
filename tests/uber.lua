local assertions=0
local function check(v)assert(v);assertions=assertions+1 end
local widget={}
setmetatable(widget,{__index=function()return function()end end})
CreateFrame=function()return setmetatable({},{__index=widget})end
SlashCmdList={};GetServerTime=function()return 10000 end
GetUnitName=function()return "Provider-Realm"end
C_ChatInfo={RegisterAddonMessagePrefix=function()end}
IsInGuild=function()return false end
assert(loadfile("Uber/Uber.lua"))()
local u=Uber;u.Refresh=function()end;u:Init();u.online=true
u:Receive("R|100-1|-|Scarlet Monastery","Rider-Realm","WHISPER")
check(u.db.inbox["Rider-Realm:100-1"].destination=="Scarlet Monastery")
u:Receive("R|100-1|-|Changed","Rider-Realm","WHISPER")
check(u.db.inbox["Rider-Realm:100-1"].destination=="Scarlet Monastery")
check(not u:Accept("Rider-Realm:100-1","bad"))
check(u:Accept("Rider-Realm:100-1",15))
check(u.db.active.status=="SETTING_UP" and u.db.active.eta==10900)
check(not u:Accept("Rider-Realm:100-1",15))
local id=u.db.active.id
u:Receive("R|100-2|"..id.."|Scarlet Monastery","Friend-Realm","WHISPER")
check(u.db.active.riders["Friend-Realm"])
u:Receive("R|100-3|wrong|Elsewhere","Other-Realm","WHISPER")
check(not u.db.active.riders["Other-Realm"])
check(u:SetStatus("READY",0));check(u:SetStatus("COMPLETE",0))
u.db.provider="Provider-Realm"
u:Receive("S|1|READY|10000|Camp|12|5000|6000|10000","Imposter-Realm","GUILD")
check(not u.db.orders["Imposter-Realm"])
u:Receive("S|1|READY|10000|Camp|12|5000|6000|10000","Provider-Realm","GUILD")
check(u.db.orders["Provider-Realm"].x==.5)
u:Receive("S|1|READY|10000|Bad|12|50001|6000|10000","Provider-Realm","GUILD")
check(u.db.orders["Provider-Realm"].destination=="Camp")
u:Init();check(not u.online)
UIParent={};UISpecialFrames={}
unpack=unpack or table.unpack
UnitClass=function()return "Warlock","WARLOCK"end
GetNormalizedRealmName=function()return "Realm"end
widget.CreateFontString=function()return setmetatable({},{__index=widget})end
widget.CreateTexture=widget.CreateFontString
widget.IsShown=function()return true end
assert(loadfile("Uber/Orders.lua"))()
assert(loadfile("Uber/Drivers.lua"))()
assert(loadfile("Uber/Interface.lua"))()
assert(loadfile("Uber/Roster.lua"))()
u:DriverDB();u.db.dispatcher="Dispatcher-Realm"
check(not u:OpenService())
u:Receive("DRIVER|Provider-Realm|1|10000","Imposter-Realm","WHISPER")
check(not u:Approved("Provider-Realm"))
u:Receive("DRIVER|Provider-Realm|1|10000","Dispatcher-Realm","WHISPER")
check(u:Approved("Provider-Realm"));check(u:OpenService())
u:Receive("DRIVER|Provider-Realm|0|10001","Dispatcher-Realm","WHISPER")
check(not u.online and not u:Approved("Provider-Realm"))
u.db.dispatcher="Provider-Realm"
u:Receive("APPLY|Experienced Warlock, have helpers","Applicant-Realm","WHISPER")
check(u.db.applications["applicant-realm"].status=="Needs review")
check(u:ReviewDriver("Applicant-Realm",true));check(u:Approved("Applicant-Realm"))
u:Receive("R|200-1|-|Camp","New-Realm","WHISPER")
-- Receiving order details requires an open driver service and matching sender request.
u.online=true
u:Receive("R|200-1|-|Camp","New-Realm","WHISPER")
u:Receive("D|200-1|party|5","New-Realm","WHISPER")
u:Receive("D|200-1|note1|Bring buffs","New-Realm","WHISPER")
check(u.db.inbox["New-Realm:200-1"].details.party==5)
check(u.db.inbox["New-Realm:200-1"].details.note=="Bring buffs")
u:Receive("D|200-1|party|500","New-Realm","WHISPER")
check(u.db.inbox["New-Realm:200-1"].details.party==5)
u:Receive("D|200-1|note1|Forged","Other-Realm","WHISPER")
check(u.db.inbox["New-Realm:200-1"].details.note=="Bring buffs")
u:Show();check(u.frame and #u.rows==4 and #u.rosterRows==4)
for _,tab in ipairs({"Drivers","Book a summon","Track & map","Driver desk","Recruitment"})do u:Tab(tab);check(u.tab==tab)end
local friend,guild
C_FriendList={AddFriend=function(who)friend=who end}
SendChatMessage=function(text,channel,_,who)guild={text,channel,who}end
check(u:DriverAction("Applicant-Realm","friend")and friend=="Applicant-Realm")
check(u:DriverAction("Applicant-Realm","guild")and guild[2]=="WHISPER"and guild[3]=="Applicant-Realm")
check(not u:DriverAction("Unknown-Realm","guild"))
u:DriverMenu("Applicant-Realm",u.rosterRows[1]);check(u.menuName=="Applicant-Realm")
u:Tab("Drivers");check(u.tab=="Drivers")
u.db.provider="Applicant-Realm";u.requestAt=nil;u.queue={}
local longNote=string.rep("A",160)..string.rep("B",160)..string.rep("C",160)
local request=u:Request("Dungeon",nil,{note=longNote,supplies="Food, Water",party=5})
check(request and #u.queue==6)
check(u.queue[4].text:sub(-160)==string.rep("A",160)and u.queue[6].text:sub(-160)==string.rep("C",160))
check(not u:Request("Dungeon",nil,{party=41}))
u.db.orders[u.db.provider]={id="camp-ready",status="READY",destination="Dungeon",eta=10000,updated=10000,map=1,x=.2,y=.3}
u.db.outbox[request].status="READY"
check(u:SummonNow());check(not u:SummonNow())
u.summonAt=nil;u.db.orders[u.db.provider].updated=9000;check(not u:SummonNow())
u.db.orders[u.db.provider].updated=10000
u:ReviewDriver("Applicant-Realm",false);check(not u:SummonNow())
print("PASS: "..assertions.." Uber request, receipt, authority, camp, location and panel assertions")
