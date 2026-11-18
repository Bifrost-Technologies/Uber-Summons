local passed=0
local function check(v,msg)assert(v,msg);passed=passed+1 end
local time,current,realm=100000,"","Realm"
local clients,hooks={},{}
local widget={};setmetatable(widget,{__index=function()return function()end end})
function widget:SetScript(event,fn)self.scripts[event]=fn end
function widget:RegisterEvent(event)self.events[event]=true end
function widget:SetText(v)self.text=v end;function widget:GetText()return self.text or ""end
function widget:Show()self.shown=true end;function widget:IsShown()return self.shown==true end
function widget:SetShown(v)self.shown=v end
function widget:SetChecked(v)self.checked=v end;function widget:GetChecked()return self.checked end
function widget:CreateFontString()return setmetatable({},{__index=widget})end
widget.CreateTexture=widget.CreateFontString
local frames={}
CreateFrame=function()local f=setmetatable({events={},scripts={},text=""},{__index=widget});frames[#frames+1]=f;return f end
GetServerTime=function()return time end;GetRealmName=function()return realm end;GetNormalizedRealmName=GetRealmName
GetUnitName=function(unit)return unit=="player"and current or nil end
UnitClass=function()if current=="Mage-Realm"then return "Mage","MAGE"end;return "Warlock","WARLOCK"end
C_ChatInfo={RegisterAddonMessagePrefix=function()end};IsInGuild=function()return true end
C_Map={GetBestMapForUnit=function()return 1 end,GetPlayerMapPosition=function()return {GetXY=function()return .2,.4 end}end}
UIParent={};UISpecialFrames={};SlashCmdList={};unpack=unpack or table.unpack
local sendCalls=0
SendMail=function(recipient,subject)sendCalls=sendCalls+1;if hooks[current]then hooks[current](recipient,subject)end end
hooksecurefunc=function(_,fn)hooks[current]=fn end
local function make(name)
 current=name
 UberDB={dispatcher="House-Realm",drivers={
  ["driver-realm"]={name="Driver-Realm",class="WARLOCK",approved=true,authority="House-Realm",at=time},
  ["mage-realm"]={name="Mage-Realm",class="MAGE",approved=true,authority="House-Realm",at=time}}}
 local first=#frames
 for _,file in ipairs({"Uber","Orders","Drivers","Presence","Billing","Interface","Roster","ServiceUI"})do assert(loadfile("Uber/"..file..".lua"))()end
 local u=Uber;u:Init();clients[name]=u
 for i=first+1,#frames do if frames[i].events.MAIL_SHOW then u.mailEvents=frames[i].scripts.OnEvent end end
 return u
end
local driver=make("Driver-Realm");local buyer=make("Buyer-Realm")
local function pump()
 for _=1,100 do
  local moved=false
  for sender,u in pairs(clients)do local p=table.remove(u.queue,1)
   if p then moved=true;for name,target in pairs(clients)do
    if p.channel=="GUILD"or p.target==name then current=name;target:Receive(p.text,sender,p.channel)end
   end end
  end
  if not moved then return end
 end
 error("Network did not settle")
end
current="Driver-Realm";check(driver:OpenService(),"Approved driver opens without house online")
check(driver:SavePrices("1","0.5","Bifrost Titan"),"Driver saves independent prices")
pump();current="Buyer-Realm";check(#buyer:ActiveDrivers()==1,"Active driver replicated without an active order or house connection")
local p=buyer.peers[buyer.NameKey("Driver-Realm")];check(p.standard==10000 and p.priority==5000,"Standard and priority prices replicated")
buyer:Receive("H3|Other realm|1|0|0|AVAILABLE|100000","Driver-Realm","WHISPER")
check(buyer.peers[buyer.NameKey("Driver-Realm")].standard==10000,"Cross-realm presence rejected")
check(buyer:Gold("0.0001")==1 and not buyer:Gold("-1")and not buyer:Gold("1.12345"),"Gold input uses exact bounded copper")
local split=buyer:SplitFee(10000,5000,2500)
check(split.house==3000 and split.driver==14500 and split.total==17500,"House split excludes optional tip; all tip reaches driver")
buyer.db.provider="Driver-Realm"
local request=buyer:Request("Scarlet Monastery",nil,{priority=true,tip=2500,party=5})
check(request,"Buyer sends versioned priority order")
pump();local r=driver.db.inbox["Buyer-Realm:"..request]
check(r and r.protocol==3 and r.intent.priority and r.intent.tip==2500,"Priority intent bound to exact buyer order")
current="Buyer-Realm";local q=buyer:Billing()[buyer.lastQuote]
check(q and q.total==17500 and q.houseRecipient=="Bifrost Titan","Buyer receives itemized quote with unaccented house recipient")
check(buyer:AcceptQuote(q.id)and not q.accepted,"Quote acceptance waits for driver acknowledgement")
current="Driver-Realm";driver:QuoteRequest("Buyer-Realm:"..request)
pump();check(q.accepted and driver:Billing()[q.id].accepted,"Quote accepted at both endpoints")
current="Driver-Realm";check(not driver:Accept("Buyer-Realm:"..request,5),"Paid order does not start from a quote alone")
current="Buyer-Realm";check(buyer:ReportMailSent(q.id,"H",false),"Buyer can send clearly unverified house notice")
pump();check(not driver:AllowReportedPayment(q.id),"Partial report cannot authorize setup")
current="Buyer-Realm";check(buyer:ReportMailSent(q.id,"D",false),"Buyer sends driver notice")
pump();current="Driver-Realm";check(driver:PaymentReported(driver:Billing()[q.id]),"Active driver gets notices while house offline")
check(q.deliveredReports.H and q.deliveredReports.D,"Driver acknowledges payment notices to buyer")
check(not driver:Billing()[q.id].receipts.H,"A report is not upgraded to a house receipt")
check(driver:AllowReportedPayment(q.id)and driver:Accept("Buyer-Realm:"..request,5),"Driver can explicitly accept sent-notice risk and begin setup")
pump()
current="Buyer-Realm";time=time+91
check(#buyer:ActiveDrivers()==0 and buyer:AvailabilityMessage():find("Come back later",1,true),"Stale drivers expire with useful no-drivers message")
current="Driver-Realm";driver:Advertise();pump();current="Buyer-Realm"
check(#buyer:ActiveDrivers()==1,"Driver heartbeat restores availability")
current="Driver-Realm";check(driver:OpenService(),"Driver closes service")
pump();current="Buyer-Realm";check(#buyer:ActiveDrivers()==0,"Explicit close removes active driver")
-- Free standard service must stay usable without optional-tip payment.
time=time+16;current="Driver-Realm";driver:SetStatus("COMPLETE",0);driver.db.active.status="COMPLETE";driver:OpenService();driver:SavePrices("0","0.5","Bifrost Titan");pump()
current="Buyer-Realm";local free=buyer:Request("Camp",nil,{priority=false,tip=1000});pump()
local fq=buyer:Billing()[buyer.lastQuote];check(fq and fq.base==0 and fq.premium==0 and fq.house==0,"Free order has no mandatory house fee")
current="Buyer-Realm";buyer:AcceptQuote(fq.id);pump();current="Driver-Realm"
check(driver:Accept("Buyer-Realm:"..free,1),"Optional tip never blocks free standard setup")
-- Preparing native mail never calls SendMail; matching native success only reports submission.
current="Buyer-Realm";buyer.mailEvents(nil,"MAIL_SHOW")
SendMailFrame=CreateFrame();SendMailFrame:Show()
SendMailNameEditBox=CreateFrame();SendMailSubjectEditBox=CreateFrame();SendMailBodyEditBox=CreateFrame()
SendMailSendMoneyButton=CreateFrame();SendMailSendMoneyButton:SetChecked(true)
SendMailMoney={};local amount=1000
MoneyInputFrame_GetCopper=function()return amount end
local prepared=buyer:ComposePayment(fq.id,"D")
check(prepared and sendCalls==0,"Preparing a payment draft cannot transfer gold: "..tostring(buyer.notice))
SendMail(SendMailNameEditBox:GetText(),SendMailSubjectEditBox:GetText())
buyer.mailEvents(nil,"MAIL_SEND_SUCCESS")
check(fq.reports.D=="CLIENT_SEND_SUCCESS","Matching native success becomes a sent notice, not a receipt")
check(not fq.receipts.D,"Native send success is not recipient-confirmed")
for i=#buyer.queue,1,-1 do if buyer.queue[i].text:match("^M3|")then table.remove(buyer.queue,i)end end
time=time+6;buyer:Tick()
local retried=false;for _,packet in ipairs(buyer.queue)do if packet.text:match("^M3|")then retried=true end end
check(retried and fq.pendingReports.D.tries==2,"Dropped payment notice retries without resending gold")
pump();check(fq.deliveredReports.D and not fq.pendingReports.D,"Acknowledgement stops notice retries")
current="Driver-Realm";driver.mailEvents(nil,"MAIL_SHOW")
GetInboxNumItems=function()return 1 end
GetInboxHeaderInfo=function()return nil,nil,"Buyer-Realm","UBER3:"..fq.id..":D",1000,0 end
check(driver:CheckOwnInbox(),"Recipient can inspect matching mail in own inbox")
pump();check(fq.receipts.D==1000,"Recipient observation is replicated separately from buyer report")
current="Buyer-Realm"
buyer:Show();buyer:ShowBilling();check(buyer.billingFrame:IsShown(),"Pricing and payment UI initializes")
local mage=make("Mage-Realm");current="Mage-Realm"
check(mage:OpenService(),"Reviewed Mage hosts independently")
pump();current="Buyer-Realm"
check(buyer.peers[buyer.NameKey("Mage-Realm")].standard==2200,"Mage advertises mandatory 22 silver even with no base extra")
time=time+16;buyer.db.provider="Mage-Realm"
local portal=buyer:Request("Stormwind",nil,{tip=0,priority=false});pump()
local mq=buyer:Billing()[buyer.lastQuote]
check(mq and mq.reagent==2200 and mq.total==2200 and mq.driverAmount==2200 and mq.house==0,"Entire portal minimum goes to Mage")
local retained=mq.total
buyer:Receive("Q3|"..portal.."|fake-free|0|0|0|Bifrost Titan|"..(time+1200).."|0|1","Mage-Realm","WHISPER")
check(buyer:Billing()[mq.id].total==retained and not buyer:Billing()["fake-free"],"Portal minimum cannot be removed by a quote")
buyer:AcceptQuote(mq.id);pump();current="Mage-Realm"
check(not mage:Accept("Buyer-Realm:"..portal,2),"Mage portal minimum blocks unpaid setup")
local fee=mage:SplitFee(10000,5000,2500,2200)
check(fee.total==19700 and fee.house==3000 and fee.driver==16700,"Reagents and tips protected from house split")
current="Buyer-Realm";buyer:ReportMailSent(mq.id,"D",false);pump();current="Mage-Realm"
check(mage:AllowReportedPayment(mq.id)and mage:Accept("Buyer-Realm:"..portal,2),"Mage explicitly authorizes setup from reported payment")
time=time+16;current="Buyer-Realm"
local two=buyer:Request("Stormwind and Ironforge",nil,{portals=2,tip=0,priority=false});pump()
local twoQuote=buyer:Billing()[buyer.lastQuote]
check(two and twoQuote.portals==2 and twoQuote.reagent==4400 and twoQuote.total==4400,"Portal minimum charged per cast, not per group member")
print("PASS: "..passed.." Uber services assertions")
