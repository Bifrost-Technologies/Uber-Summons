-- Independent clients; packets are delivered through the real receive handlers.
local passed=0
local function check(v,why)assert(v,why);passed=passed+1 end
local current,time,whispers=nil,100000,{}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
SlashCmdList={};GetServerTime=function()return time end
GetUnitName=function()return current end
GetNormalizedRealmName=function()return "Realm"end
UnitClass=function()if current=="Mage-Realm"then return "Mage","MAGE"end;return "Warlock","WARLOCK"end
IsInGuild=function()return true end
C_ChatInfo={RegisterAddonMessagePrefix=function()end}
SendChatMessage=function(text,channel,_,who)whispers[#whispers+1]={text=text,who=who,channel=channel}end
C_Map={GetBestMapForUnit=function()return 42 end,GetPlayerMapPosition=function()return {GetXY=function()return .25,.75 end}end}
local clients={}
local function make(name)
 current=name;UberDB=nil
 assert(loadfile("Uber/Uber.lua"))()
 assert(loadfile("Uber/Orders.lua"))()
 assert(loadfile("Uber/Drivers.lua"))()
 Uber.Refresh=function()end;Uber:Init();Uber.db.dispatcher="Dispatcher-Realm"
 clients[name]=Uber;return Uber
end
local dispatcher=make("Dispatcher-Realm")
local driver=make("Driver-Realm")
local customer=make("Customer-Realm")
local function pump()
 for round=1,50 do
  local moved=false
  for sender,client in pairs(clients)do
   local p=table.remove(client.queue,1)
   if p then
    moved=true
    for recipient,target in pairs(clients)do
     if (p.channel=="GUILD"or recipient==p.target)then current=recipient;target:Receive(p.text,sender,p.channel)end
    end
   end
  end
  if not moved then return end
 end
 error("Network did not settle")
end
current="Driver-Realm";check(not driver:OpenService(),"Unreviewed driver cannot open")
check(driver:ApplyDriver("Helpers available, buffs ready"),"Warlock can apply")
pump();check(dispatcher.db.applications["driver-realm"],"Dispatcher receives application")
current="Dispatcher-Realm";check(dispatcher:ReviewDriver("Driver-Realm",true),"Dispatcher approves")
pump();check(driver:Approved("Driver-Realm")and customer:Approved("Driver-Realm"),"Approval reaches driver/customer")
current="Driver-Realm";check(driver:OpenService(),"Reviewed Warlock opens service")
current="Customer-Realm";customer.db.provider="Driver-Realm"
local note=string.rep("é",240)
local request=customer:Request("Scarlet Monastery",nil,{note=note,party=5,supplies="Water, Buffs"})
check(request,"Customer requests approved driver")
pump()
local inbox=driver.db.inbox["Customer-Realm:"..request]
check(inbox and inbox.details.note==note and inbox.details.party==5 and inbox.details.supplies=="Water, Buffs","Accented long notes and supplies delivered intact")
check(customer.db.outbox[request].status=="Received by provider","Receipt arrives")
current="Driver-Realm";check(driver:Accept("Customer-Realm:"..request,10),"Driver accepts")
pump();check(customer:Current().status=="SETTING_UP","Setup status reaches customer")
check(customer:Current().eta==time+600 and customer:Current().map==42,"ETA and location delivered")
current="Customer-Realm";check(not customer:SummonNow(),"Summon unavailable before ready")
current="Driver-Realm";check(driver:SetStatus("TRAVELING",8),"Travel status allowed");pump()
check(customer:Current().status=="TRAVELING","Travel displayed")
current="Driver-Realm";check(driver:SetStatus("READY",0),"Driver opens summons");pump()
current="Customer-Realm";check(customer:SummonNow(),"Ready customer can whisper once")
check(#whispers==1 and whispers[1].who=="Driver-Realm","Whisper is directed to selected driver")
check(not customer:SummonNow(),"Repeated clicks throttled")
time=time+31
local join=customer:Request("Scarlet Monastery",customer:Current().id,{party=1})
check(join,"Customer joins ready camp");pump()
check(customer.db.outbox[join].status=="READY","Join receipt does not overwrite ready status")
current="Dispatcher-Realm";check(dispatcher:ReviewDriver("Driver-Realm",false),"Dispatcher revokes")
pump();check(not driver.online and not customer:Approved("Driver-Realm"),"Revocation closes driver and removes customer approval")
current="Customer-Realm";check(not customer:SummonNow(),"Revoked driver cannot receive summon action")
local mage=make("Mage-Realm")
current="Mage-Realm";check(not mage:OpenService(),"Unreviewed Mage cannot open service")
check(mage:ApplyDriver("Mage portals, reagents available"),"Mage can apply")
pump();check(dispatcher.db.applications["mage-realm"].class=="MAGE","Dispatcher sees claimed Mage class")
current="Dispatcher-Realm";check(dispatcher:ReviewDriver("Mage-Realm",true),"Dispatcher approves Mage after review")
pump();check(customer:DriverClass("Mage-Realm")=="MAGE","Reviewed Mage class reaches customer")
current="Mage-Realm";check(mage:OpenService(),"Approved Mage can open")
time=time+16;current="Customer-Realm";customer.db.provider="Mage-Realm"
local portalRequest=customer:Request("Stormwind",nil,{party=3,note="Meet at the Mage"})
check(portalRequest,"Customer requests portal service")
pump();current="Mage-Realm";check(mage:Accept("Customer-Realm:"..portalRequest,2),"Mage accepts portal order")
check(mage:SetStatus("READY",0),"Mage marks portal service ready");pump()
current="Customer-Realm";check(customer:SummonNow(),"Portal ready action sends whisper")
check(whispers[#whispers].text:find("Portal now!",1,true)and whispers[#whispers].who=="Mage-Realm","Mage receives correctly worded portal request")
local map,x,y=driver:Location();check(map=="42"and x=="2500"and y=="7500","Valid map position encoded")
C_Map.GetBestMapForUnit=function()error("Loading screen")end
check(driver:Location()=="0","Map exceptions handled without stopping addon")
C_Map.GetBestMapForUnit=function()return 42 end
C_Map.GetPlayerMapPosition=function()return {GetXY=function()return 0/0,.5 end}end
check(driver:Location()=="0","Invalid coordinates rejected")
issecretvalue=function(v)return v==42 end
check(driver:Location()=="0","Restricted map values rejected")
print("PASS: "..passed.." Uber multi-client integration assertions")
