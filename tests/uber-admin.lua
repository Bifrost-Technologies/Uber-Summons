local passed=0
local function check(v,message)assert(v,message);passed=passed+1 end
local clock,current=100000,""
local clients,frames={},{}
local widget={};setmetatable(widget,{__index=function()return function()end end})
function widget:SetScript(e,f)self.scripts[e]=f end
function widget:RegisterEvent(e)self.events[e]=true end
function widget:SetText(v)self.text=v end;function widget:GetText()return self.text or ""end
function widget:Show()self.shown=true end;function widget:Hide()self.shown=false end;function widget:IsShown()return self.shown==true end
function widget:SetShown(v)self.shown=v end;function widget:SetChecked(v)self.checked=v end;function widget:GetChecked()return self.checked end
function widget:CreateFontString()return setmetatable({},{__index=widget})end
widget.CreateTexture=widget.CreateFontString
CreateFrame=function()local f=setmetatable({events={},scripts={},text=""},{__index=widget});frames[#frames+1]=f;return f end
UIParent={};UISpecialFrames={};SlashCmdList={};unpack=unpack or table.unpack
GetServerTime=function()return clock end;GetRealmName=function()return "Realm"end;GetNormalizedRealmName=GetRealmName
local founder="Bîfrost Titan-Realm"
local party=true
GetNumGroupMembers=function()return party and 2 or 0 end
GetUnitName=function(unit)
 if unit=="player"then return current end
 if party and unit=="party1"then return current=="Buyer-Realm"and "Mage-Realm"or "Buyer-Realm"end
end
UnitClass=function()return "",current=="Mage-Realm"and "MAGE"or "WARLOCK"end
C_ChatInfo={RegisterAddonMessagePrefix=function()end};IsInGuild=function()return true end
local positions={};C_Map={GetBestMapForUnit=function()return (positions[current]or {1,.2,.4})[1]end,GetPlayerMapPosition=function()local p=positions[current]or {1,.2,.4};return {GetXY=function()return p[2],p[3]end}end}
local sentMail=0;SendMail=function()sentMail=sentMail+1 end
local function make(name)
 current=name;UberDB={};local first=#frames
 for _,file in ipairs({"Uber","Orders","Drivers","Presence","Billing","Administration","Reservations","Delivery","Interface","Roster","ServiceUI","AdminUI","NetworkStats"})do assert(loadfile("Uber/"..file..".lua"))()end
 local u=Uber;u:Init();u:DriverDB();clients[name]=u
 for i=first+1,#frames do if frames[i].events.UNIT_SPELLCAST_SUCCEEDED then u.deliveryEvents=frames[i].scripts.OnEvent end end
 return u
end
local admin=make(founder);local mage=make("Mage-Realm");local buyer=make("Buyer-Realm")
local function pump()
 for _=1,200 do
  local changed=false
  for sender,u in pairs(clients)do
   local p=table.remove(u.queue,1)
   if p then changed=true;for name,target in pairs(clients)do
    if p.channel=="GUILD"or target.NameKey(name)==target.NameKey(p.target)then current=name;target:Receive(p.text,sender,p.channel)end
   end end
  end
  if not changed then return end
 end
 error("Network did not drain")
end
current="Buyer-Realm"
check(buyer:Approved(buyer.FOUNDER),"Founder is always approved")
check(buyer:ProviderDirectory()[1]==buyer.FOUNDER,"Founder always listed offline")
check(not buyer:ProviderLive(buyer.FOUNDER),"Founder is not falsely live")
buyer.db.dispatcher="Buyer-Realm";check(not buyer:IsDispatcher(),"Editable DB dispatcher cannot grant admin")
check(not buyer:ManageProvider("Mage-Realm","APPROVED","MAGE","0","0","Daily UTC","review"),"Non-admin cannot approve")
buyer:Receive("ADMIN4|Mage-Realm|APPROVED|MAGE|100000|0|0|Daily UTC|forged","Buyer-Realm","WHISPER")
check(not buyer:Approved("Mage-Realm"),"Forged native sender rejected")
current=founder
check(admin:IsDispatcher(),"Accented founder native identity grants admin")
check(not admin:ManageProvider(admin.FOUNDER,"BANNED","WARLOCK","0","0","Daily UTC","test"),"Founder cannot be banned")
check(admin:ManageProvider("Mage-Realm","APPROVED","MAGE","1","2","Daily 18:00–23:00 UTC","Readiness reviewed"),"Admin can add provider")
pump();current="Buyer-Realm"
check(buyer:Approved("Mage-Realm")and buyer:DriverClass("Mage-Realm")=="MAGE","Approval/class distributed")
check(buyer:ProviderPolicy("Mage-Realm").standard==10000,"Admin price cached")
buyer.db.provider="Mage-Realm";check(not buyer:Request("Stormwind",nil,{party=1}),"Offline immediate booking rejected")
check(not buyer:Request("Stormwind",nil,{party=50,scheduledAt=clock+86400}),"Invalid offline details rejected")
local offline=buyer:Request("Stormwind",nil,{party=1,note="Tomorrow",scheduledAt=clock+86400})
check(offline and buyer:Reservations()[offline]and #buyer.queue==0,"Offline reservation local, not a whisper")
check(buyer.db.outbox[offline].status:find("not delivered",1,true),"Offline warning explicit")
clock=clock+16;current="Mage-Realm"
check(mage:OpenService(),"Reviewed Mage opens service")
local profile=mage:Network();check(profile.standard==10000 and profile.priority==20000,"Provider pricing override effective")
check(not mage:SavePrices("0","0",profile.house),"Provider cannot silently override admin rate")
pump();current="Buyer-Realm";check(buyer:ProviderLive("Mage-Realm"),"Fresh driver presence observed")
buyer:Tick();pump()
check(buyer:Reservations()[offline].deliveredID,"Pending reservation delivered on fresh presence")
local deliveredID=buyer:Reservations()[offline].deliveredID
local inboxID="Buyer-Realm:"..deliveredID
check(mage.db.inbox[inboxID]and mage.db.inbox[inboxID].scheduledAt==clock-16+86400,"Native sender and scheduled time received")
current="Mage-Realm";check(mage:Accept(inboxID,2)and mage.db.inbox[inboxID].status=="Reserved","Advance acceptance does not open camp")
pump();check(buyer.db.outbox[deliveredID].status=="Advance reservation accepted","Provider acceptance visible")
current=founder
check(admin:ManageProvider("Mage-Realm","BANNED","MAGE","1","2","Daily UTC","Scam complaint under review"),"Admin ban")
pump();current="Mage-Realm";check(not mage.online and not mage:Approved("Mage-Realm"),"Ban closes service")
current="Buyer-Realm";check(#buyer:ProviderDirectory()==1,"Banned driver removed from public directory")
local newer=buyer:ProviderPolicy("Mage-Realm").revision
buyer:Receive("ADMIN4|Mage-Realm|APPROVED|MAGE|100000|0|0|Daily UTC|old",founder,"WHISPER")
check(buyer:ProviderPolicy("Mage-Realm").revision==newer and not buyer:Approved("Mage-Realm"),"Stale policy cannot unban")
current=founder;check(admin:ManageProvider("Mage-Realm","APPROVED","MAGE","0","0","Daily UTC","Unbanned after review"),"Admin unban")
pump();current="Mage-Realm";mage:OpenService();pump()
-- Isolate a ready one-person portal order. Correlate genuine party/cast/travel events.
current="Mage-Realm"
mage.db.active={id="100020-10",status="READY",eta=clock,destination="Stormwind",riders={["Buyer-Realm"]=true},updated=clock}
mage.db.inbox["Buyer-Realm:100020-11"]={sender="Buyer-Realm",destination="Stormwind",request="100020-11",join="-",camp="100020-10",details={party=1},status="Accepted"}
mage.db.inbox[inboxID]=nil
buyer.db.outbox["100020-11"]={provider="Mage-Realm",destination="Stormwind",status="READY",camp="100020-10"}
buyer.db.orders["Mage-Realm"]={id="100020-10",status="READY",destination="Stormwind",updated=clock}
check(not mage:ObserveServiceCast(116,"irrelevant"),"Unrelated spells ignored")
check(mage:ObserveServiceCast(10059,"cast-one"),"Instant successful portal cast recorded")
check(not mage:ObserveServiceCast(10059,"cast-one"),"Cast GUID deduplicated")
check(mage.db.active.status=="READY","Cast alone never completes order")
pump();current="Buyer-Realm";check(buyer.travelPending~=nil,"Party buyer receives matching cast")
check(not buyer:ObserveTravel(false,false),"No movement is not delivery")
positions[current]={85,.2,.4};check(not buyer:ObserveTravel(false,false),"Wrong portal destination ignored")
positions[current]={84,.3,.5};check(not buyer:ObserveTravel(true,false),"Login is not portal delivery")
check(not buyer:ObserveTravel(false,true),"Reload is not portal delivery")
check(buyer:ObserveTravel(false,false),"Matching destination transition produces arrival report")
pump();current="Mage-Realm"
check(mage.db.active.status=="COMPLETE","Party/cast/arrival automatically completes single-rider service")
check(mage.db.inbox["Buyer-Realm:100020-11"].delivery~=nil,"Named recipient delivery stamped")
check(mage.db.delivery[#mage.db.delivery].kind=="DELIVERY_CORROBORATED","Delivery distinct from cast")
local count=#mage.db.delivery
mage:Receive("ARRIVE4|100020-10|100016-1|84|3000|5000|"..clock.."|PORTAL_TRANSITION","Stranger-Realm","WHISPER")
check(#mage.db.delivery==count,"Unrelated customer cannot claim delivery")
party=false
mage.db.active.status="READY";mage.db.active.delivered=nil;mage:ObserveServiceCast(10059,"cast-no-party");pump()
check(not buyer.travelPending,"Non-party clients cannot arm automatic delivery")
party=true
-- Mailbox archive works without a locally stored quote and never sends mail.
current=founder;admin.mailOpen=true
GetInboxNumItems=function()return 2 end
GetInboxHeaderInfo=function(i)if i==1 then return nil,nil,"Buyer-Realm","UBER3:100020-11:H",2000,0 end;return nil,nil,"Buyer-Realm","Other mail",900,0 end
check(admin:ArchiveMailboxReceipts(),"Native mailbox scan succeeds")
local before=#admin.db.delivery;admin:ArchiveMailboxReceipts()
check(#admin.db.delivery==before,"Mailbox rescans do not double-count same receipt")
check(admin.db.delivery[before].kind=="MAIL_OBSERVED","Receipts observed rather than inferred from sender")
current="Buyer-Realm";buyer.mailOpen=true
SendMailFrame=CreateFrame();SendMailFrame:Show();SendMailNameEditBox=CreateFrame();SendMailSubjectEditBox=CreateFrame();SendMailBodyEditBox=CreateFrame()
check(buyer:ApplyDriver("Warlock; evenings UTC"),"Application native mail draft prepared")
check(SendMailNameEditBox:GetText()==buyer.FOUNDER and sentMail==0,"Application addressed to founder without auto-send")
check(not buyer:ApplyDriver("Do not overwrite"),"Existing draft preserved")
current="Buyer-Realm";buyer:Show();buyer:ShowSchedule();buyer:ShowAudit()
check(buyer.scheduleFrame:IsShown()and buyer.auditFrame:IsShown(),"Customer reservations and audit panels render")
check(not buyer:ShowAdmin(),"Admin UI denied to customer")
current=founder;admin:Show();check(admin:ShowAdmin(),"Creator control panel renders")
admin:ShowAudit();check(admin.auditFrame:IsShown(),"Admin receipt timeline renders")
check(admin.db.dispatcher==admin.FOUNDER,"Founder policy persists through UI refresh")
-- Warlock arrival requires the native summon offer in addition to travel.
local lock=make("Lock-Realm");current=founder
admin:ManageProvider("Lock-Realm","APPROVED","WARLOCK","0","0","Daily UTC","Reviewed");pump()
current="Lock-Realm";lock:OpenService();lock.db.active={id="100030-1",status="READY",eta=clock,destination="Camp",riders={["Buyer-Realm"]=true},updated=clock}
lock.db.inbox["Buyer-Realm:100030-2"]={sender="Buyer-Realm",destination="Camp",request="100030-2",join="-",camp="100030-1",details={party=1},status="Accepted"}
buyer.db.provider="Lock-Realm";buyer.db.outbox["100030-2"]={provider="Lock-Realm",destination="Camp",status="READY",camp="100030-1",at=clock};buyer.db.orders["Lock-Realm"]={id="100030-1",status="READY",destination="Camp",updated=clock,eta=clock}
positions["Buyer-Realm"]={2,.5,.5};lock:ObserveServiceCast(698,"summon-one");pump();current="Buyer-Realm"
-- Mock the party's provider token for this separate warlock session.
local names=GetUnitName;GetUnitName=function(unit)if unit=="party1"then return current=="Buyer-Realm"and "Lock-Realm"or "Buyer-Realm"end;return names(unit)end
current="Lock-Realm";lock:ObserveServiceCast(698,"summon-two");pump();current="Buyer-Realm"
check(buyer.travelPending and buyer.travelPending.spell==698,"Warlock cast armed for party customer")
positions[current]={1,.2,.4};check(not buyer:ObserveTravel(false,false),"Summon movement without offer is insufficient")
C_SummonInfo={GetSummonConfirmSummoner=function()return "Stranger-Realm"end}
check(not buyer:ObserveSummonOffer(),"Wrong summoner rejected")
C_SummonInfo.GetSummonConfirmSummoner=function()return "Lock-Realm"end
check(buyer:ObserveSummonOffer(),"Native summoner identity linked")
check(buyer:ObserveTravel(false,false),"Summon offer plus matching arrival reported")
pump();check(lock.db.active.status=="COMPLETE","Warlock order completes after corroborated arrival")
check(buyer.db.outbox["100030-2"].delivery~=nil,"Customer receives delivery acknowledgement")
current="Lock-Realm";lock.db.active.id="100040-1";lock.db.active.status="READY";lock.db.active.delivered=nil
lock.db.inbox["Buyer-Realm:100030-2"].camp="100040-1";lock.db.inbox["Buyer-Realm:100030-2"].details.party=5
buyer.db.outbox["100030-2"].camp="100040-1";buyer.db.outbox["100030-2"].status="READY"
positions["Buyer-Realm"]={2,.5,.5};lock:ObserveServiceCast(698,"summon-group");pump();current="Buyer-Realm"
check(buyer:ObserveSummonOffer(),"Group rider native offer matched")
positions[current]={1,.2,.4};buyer:ObserveTravel(false,false);pump()
check(lock.db.active.status=="READY","One arrival never completes five-person booking")
current="Lock-Realm";lock:Tick();pump();clock=clock+5;current="Lock-Realm";lock:Tick();pump()
check(#admin.db.audit>0 and #lock.db.adminReports>0,"Delivery reports use acknowledged creator channel")
for _=1,20 do clock=clock+31;current="Lock-Realm";lock:Tick();pump()end
check(#lock.db.adminReports==0,"Creator acknowledgements drain pending reports without visible whispers")
local auditCount=#admin.db.audit;current=founder
admin:Receive("EVIDENCE4|100000-999|DELIVERY_CORROBORATED|100040-1|Buyer-Realm|first|"..clock,"Lock-Realm","WHISPER")
local once=#admin.db.audit
admin:Receive("EVIDENCE4|100000-999|DELIVERY_CORROBORATED|100040-1|Buyer-Realm|replay|"..clock,"Lock-Realm","WHISPER")
check(once==auditCount+1 and #admin.db.audit==once,"Creator deduplicates replayed reports")
GetInboxNumItems=function()return 1 end;GetInboxHeaderInfo=function()return nil,nil,"Applicant-Realm","UBER DRIVER APPLICATION MAGE",0,0 end
GetInboxText=function()return "Evenings UTC. Portal spells and supplies ready."end
admin:ArchiveMailboxReceipts()
check(admin.db.applications[admin.NameKey("Applicant-Realm")].status=="Needs review","Native mailbox application imported without approving")
check(not admin:Approved("Applicant-Realm"),"Application letter is never approval")
-- Unsupported/restricted event values are skipped rather than bypassed.
issecretvalue=function(v)return v=="SECRET"end;current="Lock-Realm"
check(not lock:ObserveServiceCast("SECRET","guid"),"Secret spell data ignored")
issecretvalue=nil
current="Lock-Realm";lock.db.active=nil;positions["Buyer-Realm"]={2,.5,.5}
check(lock:ObserveServiceCast(698,"walkup-summon"),"Walk-up summon cast recorded without formal order")
pump();current="Buyer-Realm"
check(buyer.travelPending and buyer.travelPending.walkup,"Party customer can observe walk-up service")
buyer:ObserveSummonOffer();positions[current]={1,.2,.4}
check(buyer:ObserveTravel(false,false),"Walk-up native offer and arrival correlated")
pump()
check(lock.db.delivery[#lock.db.delivery].kind=="PARTY_TRAVEL_CORROBORATED"and lock.db.active==nil,"Walk-up evidence does not invent an order/payment")
current=founder
for i=1,40 do
 local name="Provider"..i.."-Realm";local k=admin.NameKey(name)
 admin.db.drivers[k]={name=name,class="MAGE",approved=true,authority=admin.FOUNDER,at=clock}
 admin.db.providerPolicies[k]={name=name,class="MAGE",state="APPROVED",revision=clock,standard=0,priority=0,hours="Daily UTC",reason="Reviewed"}
end
local fresh=make("Fresh-Realm");fresh:RefreshProvider();pump()
check(fresh:Approved("Provider40-Realm")and fresh:Approved("Provider1-Realm"),"Paged roster delivers a large directory without dropping later entries")
check(#fresh.queue==0 and #admin.queue==0,"Paged roster drains bounded queues")
current='Buyer-Realm';buyer.db.outbox['123-456']={provider='Lock-Realm',deliveredAt=clock,camp='1-2'};lock.db.inbox['123-456']={sender='Buyer-Realm',deliveredAt=clock}
check(not buyer:RateDeliveredOrder('123-456',6),'Out of range stars rejected')
check(buyer:RateDeliveredOrder('123-456',5),'Corroborated order can be rated');pump()
check(lock.db.ratings['123-456'].stars==5,'Rating bound to completed native sender order')
check(not buyer:RateDeliveredOrder('123-456',1),'No duplicate customer review');check(buyer:RatingSummary('Lock-Realm'):find('5.0',1,true),'Star summary received')
check(not fresh:RatingSummary('Provider1-Realm'):find('5.0',1,true),'No seeded five-star reviews')
current='Buyer-Realm';buyer:SetPublicStats(false);pump()
check(admin.privateNetworkUsers[admin.NameKey('Buyer-Realm')].public==false,'Creator alone receives public-opt-out identity')
check(not mage.privateNetworkUsers or not mage.privateNetworkUsers[mage.NameKey('Buyer-Realm')],'Hidden census not transmitted to other providers')
current='Buyer-Realm';check(not buyer:ShowNetworkAdmin(),'Ordinary client cannot open private census');buyer:SetPublicStats(true);pump()
current=founder;local publicCount=admin:PublicUserCount();admin:Receive('ME7|Realm|1|'..clock,'Buyer-Realm','WHISPER');check(admin:PublicUserCount()==publicCount,'Duplicate public presence counted once')
admin:Receive('ME7|WrongRealm|0|'..clock,'Fake-Realm','WHISPER');check(not admin.privateNetworkUsers[admin.NameKey('Fake-Realm')],'Other realm private report rejected')
current='Buyer-Realm';buyer:Receive('ME7|Realm|0|'..clock,'Hidden-Realm','WHISPER');check(not buyer.privateNetworkUsers[buyer.NameKey('Hidden-Realm')],'Non-admin receiver discards hidden data')
buyer.peers[buyer.NameKey('Mage-Realm')]={online=true,at=clock,state='AVAILABLE'};buyer.peers[buyer.NameKey('Lock-Realm')]={online=true,at=clock,state='SETTING_UP'}
buyer.db.orders['Lock-Realm']={id='123-99',eta=clock,status='SETTING_UP',destination='Scarlet Monastery',updated=clock};local stats,sessions=buyer:SessionSnapshot()
check(stats.connected and stats.portals>=1 and stats.occupied>=1,'Fresh provider traffic yields connection and availability counts')
local session;for _,r in ipairs(sessions)do if r.provider=='Lock-Realm'then session=r end end
check(session and session.joinable and session.destination=='Scarlet Monastery','Busy setup can expose joinable existing camp')
buyer.requestAt=0;check(buyer:JoinNetworkSession(session),'Existing session submits a normal join order')
buyer:Receive('CAP7|123-99|40|40|'..clock,'Lock-Realm','WHISPER');stats,sessions=buyer:SessionSnapshot();for _,r in ipairs(sessions)do if r.provider=='Lock-Realm'then check(r.full and not r.joinable,'Full session disabled without hiding location')end end
current='Lock-Realm';lock.online=true;lock.db.active={id='123-99',eta=clock,status='READY',riders={},destination='Camp'};local converts=0;IsInGroup=function()return true end;UnitIsGroupLeader=function()return true end;IsInRaid=function()return false end;C_PartyInfo={AllowedToDoPartyConversion=function()return true end,ConvertToRaid=function()converts=converts+1 end};InCombatLockdown=function()return false end
check(lock:MaybeExpandSummonRaid()and converts==1,'Active leading warlock requests native raid conversion');check(not lock:MaybeExpandSummonRaid()and converts==1,'No repeated conversion spam');clock=clock+16;InCombatLockdown=function()return true end;check(not lock:MaybeExpandSummonRaid(),'Combat postpones conversion');InCombatLockdown=function()return false end;UnitIsGroupLeader=function()return false end;check(not lock:MaybeExpandSummonRaid(),'Non-leader never converts group')
current='Buyer-Realm';buyer:Show();buyer:ShowNetwork();check(buyer.networkFrame:IsShown()and buyer.networkStatus:GetText()~='','Network UI renders');current=founder;admin:Show();admin:ShowAdmin();check(admin:ShowNetworkAdmin()and admin.censusFrame:IsShown(),'Creator census accessible from admin panel')
clock=clock+121;current=founder;admin:Tick();check(not admin.privateNetworkUsers[admin.NameKey('Buyer-Realm')],'Expired private presence removed')
current='Buyer-Realm';check(not buyer:JoinNetworkSession(session),'Capacity is rechecked before submitting a stale row join')
buyer.queue={};for i=1,100 do buyer:Send({'ME7','Realm','1',tostring(clock)},founder)end
check(buyer:Send({'R','123-88','-','Camp'},'Mage-Realm')and #buyer.queue==100 and buyer.queue[1].text:match('^R|'),'Order evicts a background packet and bypasses census backlog')
check(buyer:Send({'D','123-88','party','1'},'Mage-Realm')and buyer.queue[2].text:match('^D|'),'Urgent protocol packet order remains FIFO')
current='Lock-Realm';lock.online=true;lock.db.active={id='123-777',eta=clock,status='SETTING_UP',destination='Camp',riders={}};check(lock:SetStatus('READY',0)and lock.db.active.sharedSession,'Ready camp stays open for successive groups until manually closed')
check(lock:SetStatus('COMPLETE',0)and lock.db.active.status=='COMPLETE','Provider can still manually close shared camp')
current='Lock-Realm';lock.db.active={id='123-778',eta=clock,status='READY',destination='Camp',riders={['Buyer-Realm']=true},sharedSession=true};lock.db.inbox['Buyer-Realm:777-1']={sender='Buyer-Realm',request='777-1',join='123-778',camp='123-778',status='Joined'}
buyer.db.outbox['777-1']={provider='Lock-Realm',status='READY',join='123-778'};positions['Buyer-Realm']={2,.5,.5};lock:Publish('Buyer-Realm');check(lock:ObserveServiceCast(698,'shared-delivery'),'Shared camp records an actual summon cast');pump();current='Buyer-Realm';buyer:ObserveSummonOffer();positions[current]={1,.2,.4};check(buyer:ObserveTravel(false,false),'Shared camp customer reports corroborating travel');pump()
check(lock.db.active.status=='READY'and lock.db.active.delivered['Buyer-Realm']and not lock.db.active.riders['Buyer-Realm'],'Delivered rider frees session enrollment while camp remains open')
print("PASS: "..passed.." Uber administration and delivery assertions")
