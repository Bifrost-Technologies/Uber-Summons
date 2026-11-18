local U=Uber
local function now()return GetServerTime()end
local function int(v,max)local n=tonumber(v);return n and n==n and n>=0 and n<=max and n%1==0 and n end
local function valid(s,n)return type(s)=="string"and #s>0 and #s<=n and not s:find("[%c|]")and s end
local function me()return GetUnitName("player",true)end
local function same(a,b)return U.NameKey(a)==U.NameKey(b)end
function U:Billing()
 self.db.quotes=self.db.quotes or {}
 for id,q in pairs(self.db.quotes)do if not q.accepted and now()>(q.deadline or 0)+120 then self.db.quotes[id]=nil end end
 return self.db.quotes
end
function U:SplitFee(base,premium,tip,reagent)
 reagent=reagent or 0
 if not int(base,100000000)or not int(premium,100000000)or not int(tip,100000000)or not int(reagent,88000)then return nil end
 local house=math.floor((base+premium)/5)
 return {total=reagent+base+premium+tip,house=house,driver=reagent+base+premium-house+tip,driverRequired=reagent+base+premium-house}
end
function U:QuoteRequest(inboxID)
 local r=self.db.inbox[inboxID]
 if not self.online or not r or r.protocol~=3 or not r.intent then return nil end
 local old=r.quote and self:Billing()[r.quote]
 if old and (old.accepted or now()<old.deadline)then
  if not old.accepted then self:Send({"Q3",old.request,old.id,tostring(old.base),tostring(old.premium),tostring(old.tip),old.houseRecipient,tostring(old.deadline),tostring(old.reagent or 0),tostring(old.portals or 1)},old.buyer)end
  return old
 end
 local profile=self:Network();local premium=r.intent.priority and profile.priority or 0
 local portals=r.intent.portals or 1;local reagent=self:PortalCost(me())*portals;local split=self:SplitFee(profile.standard,premium,r.intent.tip,reagent);if not split then return nil end
 local count=0;for _ in pairs(self:Billing())do count=count+1 end;if count>=200 then return nil end
 local hash=0;for i=1,#me()do hash=(hash*33+me():byte(i))%2147483647 end
 local q={id=self:ID().."-"..tostring(hash),request=r.request,buyer=r.sender,driver=me(),base=profile.standard,premium=premium,tip=r.intent.tip,reagent=reagent,total=split.total,house=split.house,driverAmount=split.driver,driverRequired=split.driverRequired,houseRecipient=profile.house,deadline=now()+1200,reports={},receipts={},role="DRIVER",inbox=inboxID,priority=r.intent.priority}
 q.portals=portals
 if not self:Send({"Q3",q.request,q.id,tostring(q.base),tostring(q.premium),tostring(q.tip),q.houseRecipient,tostring(q.deadline),tostring(q.reagent),tostring(q.portals)},r.sender)then return nil end
 self:Billing()[q.id]=q;r.quote=q.id;self.lastQuote=q.id;return q
end
function U:AcceptQuote(id)
 local q=self:Billing()[id]
 if not q or q.role~="BUYER"or q.closed or now()>q.deadline or not self:Approved(q.driver)then return false end
 if q.accepted then return true end
 if not self:Send({"C3",id},q.driver)then return false end
 q.acceptPending=true;self:Refresh();return true
end
function U:ReportMailSent(id,leg,native)
 local q=self:Billing()[id]
 if not q or q.role~="BUYER"or not q.accepted or (leg~="H"and leg~="D")then return false end
 local amount=leg=="H"and q.house or q.driverAmount
 if amount==0 then return false end
 q.pendingReports=q.pendingReports or {};q.deliveredReports=q.deliveredReports or {}
 if q.deliveredReports[leg]or q.pendingReports[leg]and now()-q.pendingReports[leg].at<2 then return false end
 local report=q.reports[leg]or (native and "CLIENT_SEND_SUCCESS"or "BUYER_REPORT")
 if not self:Send({"M3",id,leg,report,tostring(amount)},q.driver)then return false end
 q.reports[leg]=report;q.pendingReports[leg]={at=now(),tries=1};self:Refresh();return true
end
function U:PaymentSummary(q)
 if not q then return "Waiting for a quote from the driver."end
 local portal=(q.reagent or 0)>0 and ("Portal supplies ("..(q.portals or 1).." casts) "..self:Money(q.reagent).." + ")or ""
 local base=portal..("Base %s + priority %s + tip %s = %s"):format(self:Money(q.base),self:Money(q.premium),self:Money(q.tip),self:Money(q.total))
 local mandatory=(q.reagent or 0)+q.base+q.premium
 local state=not q.accepted and "Awaiting quote acceptance"or mandatory==0 and "Free service; tip is optional"or "Payment not recipient-confirmed"
 local house=q.house==0 or q.receipts.H and q.receipts.H>=q.house
 local driver=q.driverRequired==0 or q.receipts.D and q.receipts.D>=q.driverRequired
 if house and driver and mandatory>0 then state="Recipient-confirmed service payment"end
 if q.reports.H or q.reports.D then state=state.." | buyer reports mail sent (not proof of receipt)"end
 if q.closed=="CANCELLED"then state="CANCELLED — do not send new payments; review any refunds separately."elseif q.closed=="COMPLETE"then state="COMPLETE | "..state end
 return base.."\nHouse "..self:Money(q.house).." → "..q.houseRecipient.." | Driver "..self:Money(q.driverAmount).." → "..q.driver.."\n"..state.."\nHouse: "..(house and "not required / observed"or q.reports.H and "sent notice only"or "pending").." | Driver: "..(driver and "not required / observed"or q.reports.D and "sent notice only"or "pending")
end
function U:PaymentReported(q)
 return q and (q.house==0 or q.reports.H)and (q.driverRequired==0 or q.reports.D)
end
function U:AllowReportedPayment(id)
 local q=self:Billing()[id]
 if not self.online or not q or q.role~="DRIVER"or q.closed or not q.accepted or not self:PaymentReported(q)then return false end
 q.startOnReport=true;return true
end
local request=U.Request
function U:Request(destination,join,details)
 self:Network();local peer=self.peers[self.NameKey(self.db.provider)]
 if not peer or not peer.online or now()-peer.at>90 then self:Notice("Refresh and select an active driver on this realm before booking.");return false end
 details=details or {};local options=self.bookingOptions or {};local tip=details.tip
 if tip==nil then tip=options.tip or 0 end
 local priority=details.priority;if priority==nil then priority=options.priority==true end
 local portals=details.portals or options.portals or 1
 if self:DriverClass(self.db.provider)~="MAGE"then portals=1 end
 if not int(portals,40)or portals<1 then return false end
 if type(priority)~="boolean"or not int(tip,100000000)then return false end
 local before=#self.queue;local id=request(self,destination,join,details);if not id then return false end
 self.db.outbox[id].priority=priority==true;self.db.outbox[id].tip=tip;self.db.outbox[id].protocol=3;self.db.outbox[id].portals=portals
 -- Versioned requests fail closed in old clients rather than silently accepting an unquoted fee.
 for i=before+1,#self.queue do local p=self.queue[i];if p.text:sub(1,#id+3)=="R|"..id.."|"then p.text=p.text.."|3";break end end
 self:Send({"B3",id,priority and "1"or "0",tostring(tip),tostring(portals)},self.db.provider)
 return id
end
local accept=U.Accept
function U:Accept(id,minutes)
 local r=self.db.inbox[id]
 if r and r.protocol==3 then
  local q=r.quote and self:Billing()[r.quote]or self:QuoteRequest(id)
  if not q or not q.accepted then self:Notice("Send the quote and wait for the customer to accept it first.");return false end
  if (q.reagent or 0)+q.base+q.premium>0 and not q.startOnReport then
   local h=q.house==0 or q.receipts.H and q.receipts.H>=q.house
   local d=q.driverRequired==0 or q.receipts.D and q.receipts.D>=q.driverRequired
   if not h or not d then self:Notice("Payment is not confirmed. Inspect the reports and explicitly choose Start on sent notice if you accept that risk.");return false end
  end
 elseif r then
  local prices=self:Network();if prices.standard+self:PortalCost(me())>0 then self:Notice("This customer needs the current Uber version to accept your fee.");return false end
 end
 local result=accept(self,id,minutes)
 if result and r and r.quote and self.db.active then self.db.active.billingQuote=r.quote end
 return result
end
local receive=U.Receive
function U:Receive(text,sender,channel)
 if type(text)~="string"or #text>240 or text:find("[%c]")or not valid(sender,100)then return end
 local p={};for v in (text.."|"):gmatch("(.-)|")do p[#p+1]=v end
 if p[1]=="B3"then
  local id=sender..":"..(p[2]or "");local r=self.online and self.db.inbox[id]
  local tip=int(p[4],100000000)
  local portals=int(p[5],40)
  if channel~="WHISPER"or #p~=5 or not r or r.protocol~=3 or not tip or not portals or portals<1 or (p[3]~="1"and p[3]~="0")or r.intent then return end
  r.intent={priority=p[3]=="1",tip=tip,portals=self:PortalCost(me())>0 and portals or 1};self:QuoteRequest(id);self:Refresh();return
 elseif p[1]=="Q3"then
  local r=self.db.outbox[p[2]]
  if channel~="WHISPER"or #p~=10 or not r or not same(sender,r.provider)or not self:Approved(sender)or not valid(p[3],40)or not valid(p[7],60)then return end
  local base,premium,tip,deadline,reagent,portals=int(p[4],100000000),int(p[5],100000000),int(p[6],100000000),int(p[8],9999999999),int(p[9],88000),int(p[10],40)
  if not base or not premium or not tip or not deadline or deadline<now()or deadline>now()+3600 or tip~=(r.tip or 0)or (not r.priority and premium~=0)then return end
  if not portals or portals<1 or portals~=(r.portals or 1)or reagent~=self:PortalCost(sender)*portals then return end
  local profile=self:Network();if not same(p[7],profile.house)then self:Notice("Quote has a different house recipient. Confirm your realm's house policy with the dispatcher before paying.");return end
  local existing=self:Billing()[p[3]];if existing and (not same(existing.driver,sender)or existing.request~=p[2])then return end
  if existing then
   if existing.base~=base or existing.premium~=premium or existing.tip~=tip or existing.reagent~=reagent or existing.portals~=portals or existing.deadline~=deadline then return end
   r.quote=p[3];self.lastQuote=p[3];self:Refresh();return
  end
  local total=0;for _ in pairs(self:Billing())do total=total+1 end;if not existing and total>=200 then self:Notice("Quote history is full. Clear completed records before receiving more quotes.");return end
  if r.quote and self:Billing()[r.quote]and self:Billing()[r.quote].accepted then return end
  local split=self:SplitFee(base,premium,tip,reagent)
  self:Billing()[p[3]]={id=p[3],request=p[2],buyer=me(),driver=sender,base=base,premium=premium,tip=tip,reagent=reagent,total=split.total,house=split.house,driverAmount=split.driver,driverRequired=split.driverRequired,houseRecipient=p[7],deadline=deadline,reports={},receipts={},role="BUYER",priority=r.priority}
  self:Billing()[p[3]].portals=portals
  r.quote=p[3];self.lastQuote=p[3];self:Refresh();return
 elseif p[1]=="C3"then
  local q=self:Billing()[p[2]]
  if channel~="WHISPER"or #p~=2 or not q or q.role~="DRIVER"or not same(sender,q.buyer)or now()>q.deadline then return end
  q.accepted=true;self:Send({"CA3",q.id},sender);self:Refresh();return
 elseif p[1]=="CA3"then
  local q=self:Billing()[p[2]]
  if channel~="WHISPER"or #p~=2 or not q or q.role~="BUYER"or not q.acceptPending or not same(sender,q.driver)then return end
  q.accepted=true;q.acceptPending=nil;self:Refresh();return
 elseif p[1]=="M3"then
  local q=self:Billing()[p[2]];local amount=int(p[5],300000000)
  if channel~="WHISPER"or #p~=5 or not q or q.role~="DRIVER"or not q.accepted or not same(sender,q.buyer)or (p[3]~="H"and p[3]~="D")or (p[4]~="CLIENT_SEND_SUCCESS"and p[4]~="BUYER_REPORT")then return end
  if amount~=(p[3]=="H"and q.house or q.driverAmount)then return end
  q.reports[p[3]]=p[4];self:Send({"MA3",q.id,p[3]},sender);self.notice="Customer reports payment sent for order "..q.request..". Not recipient-confirmed.";self:Refresh();return
 elseif p[1]=="MA3"then
  local q=self:Billing()[p[2]]
  if channel~="WHISPER"or #p~=3 or not q or q.role~="BUYER"or not same(sender,q.driver)or not q.reports[p[3]]then return end
  q.deliveredReports=q.deliveredReports or {};q.deliveredReports[p[3]]=true
  if q.pendingReports then q.pendingReports[p[3]]=nil end
  self:Refresh();return
 elseif p[1]=="END3"then
  local q=self:Billing()[p[2]]
  if channel~="WHISPER"or #p~=3 or not q or q.role~="BUYER"or not same(sender,q.driver)or (p[3]~="COMPLETE"and p[3]~="CANCELLED")then return end
  q.closed=p[3];self:Refresh();return
 elseif p[1]=="RC3"then
  local q=self:Billing()[p[2]];local amount=int(p[4],300000000)
  if channel~="WHISPER"or #p~=4 or not q or q.role~="BUYER"or not q.accepted or p[3]~="D"or not amount or not same(sender,q.driver)then return end
  q.receipts.D=amount;self:Refresh();return
 end
 receive(self,text,sender,channel)
end
local status=U.SetStatus
function U:SetStatus(state,minutes)
 local result=status(self,state,minutes)
 if result and (state=="COMPLETE"or state=="CANCELLED")and self.db.active and self.db.active.billingQuote then
  local q=self:Billing()[self.db.active.billingQuote]
  if q then q.closed=state;self:Send({"END3",q.id,state},q.buyer)end
 end
 return result
end
function U:ClearCompletedQuotes()
 local count=0
 for id,q in pairs(self:Billing())do if q.closed=="COMPLETE"then self.db.quotes[id]=nil;count=count+1 end end
 self:Notice("Cleared "..count.." completed quote records. Pending and cancelled records were retained.")
end
local tick=U.Tick
function U:Tick()
 tick(self);if not self.db then return end
 for _,q in pairs(self:Billing())do
  if q.role=="BUYER"then for leg,pending in pairs(q.pendingReports or {})do
   if pending.tries<3 and now()-pending.at>=5 and #self.queue<80 then
    local amount=leg=="H"and q.house or q.driverAmount
    if self:Send({"M3",q.id,leg,q.reports[leg],tostring(amount)},q.driver)then pending.at=now();pending.tries=pending.tries+1 end
   end
  end end
 end
end
function U:CheckOwnInbox()
 if not self.mailOpen or not GetInboxNumItems or not GetInboxHeaderInfo then return false end
 local ok,count=pcall(GetInboxNumItems);if not ok or issecretvalue and issecretvalue(count)or not int(count,100)then return false end
 local found=0
 for i=1,count do
  local good,_,_,sender,subject,money,cod=pcall(GetInboxHeaderInfo,i)
  if good and not (issecretvalue and (issecretvalue(sender)or issecretvalue(subject)or issecretvalue(money)or issecretvalue(cod)))and valid(sender,100)and valid(subject,100)and int(money,300000000)and cod==0 then
   local id,leg=subject:match("^UBER3:([%d%-]+):([HD])$")
   local q=id and self:Billing()[id]
   if q and same(sender,q.buyer)and same(me(),leg=="H"and q.houseRecipient or q.driver)then
    q.receipts[leg]=math.max(q.receipts[leg]or 0,money);found=found+1
    if q.role=="DRIVER"and leg=="D"then self:Send({"RC3",q.id,leg,tostring(q.receipts[leg])},q.buyer)end
   end
  end
 end
 self:Notice("Observed "..found.." matching payment letters in your own inbox. Other recipients' inboxes cannot be inspected remotely.");return true
end
-- Mail is always sent by the player through the native UI. These hooks only observe.
function U:ComposePayment(id,leg)
 local q=self:Billing()[id]
 if not q or q.role~="BUYER"or q.closed=="CANCELLED"or not q.accepted or (leg~="H"and leg~="D")or q.reports[leg]then return false end
 if not self.mailOpen or not SendMailFrame or not SendMailFrame:IsShown()or not SendMailNameEditBox or not SendMailSubjectEditBox or not SendMailBodyEditBox then self:Notice("Open a mailbox and select Send Mail first.");return false end
 local amount=leg=="H"and q.house or q.driverAmount;if amount<=0 then return false end
 for _,box in ipairs({SendMailNameEditBox,SendMailSubjectEditBox,SendMailBodyEditBox})do if box:GetText()~=""then self:Notice("Finish or clear the existing mail draft first.");return false end end
 for i=1,12 do if HasSendMailItem and HasSendMailItem(i)then self:Notice("Remove attached items before preparing payment mail.");return false end end
 if SendMailSendMoneyButton and not SendMailSendMoneyButton:GetChecked()then self:Notice("Select Send Money, not C.O.D., in the mailbox.");return false end
 local recipient=leg=="H"and q.houseRecipient or q.driver;local subject="UBER3:"..q.id..":"..leg
 SendMailNameEditBox:SetText(recipient);SendMailSubjectEditBox:SetText(subject);SendMailBodyEditBox:SetText("Uber order "..q.request..". Agreed payment: "..self:Money(amount)..". Postage is separate.")
 self.mailIntent={quote=id,leg=leg,recipient=recipient,subject=subject,amount=amount}
 self:Notice("Enter "..self:Money(amount).." in the native mail money fields. Check recipient and amount, then click Send and confirm. No gold has been sent by Uber.")
 return true
end
local frame=CreateFrame("Frame")
for _,event in ipairs({"MAIL_SHOW","MAIL_CLOSED","MAIL_SEND_SUCCESS","MAIL_FAILED"})do pcall(frame.RegisterEvent,frame,event)end
frame:SetScript("OnEvent",function(_,event)
 if event=="MAIL_SHOW"then U.mailOpen=true
 elseif event=="MAIL_CLOSED"then U.mailOpen=false;U.mailIntent=nil
 elseif event=="MAIL_SEND_SUCCESS"then
  local attempt=U.mailAttempt;U.mailAttempt=nil;U.mailIntent=nil
  if attempt and now()-attempt.at<=120 then U:ReportMailSent(attempt.quote,attempt.leg,true)end
 elseif event=="MAIL_FAILED"then U.mailAttempt=nil;U:Notice("Mail failed. Payment has not been reported as sent.")end
end)
U.mailHookAvailable=false
if hooksecurefunc and SendMail then
 U.mailHookAvailable=pcall(hooksecurefunc,"SendMail",function(recipient,subject)
  U.mailAttempt=nil;local intent=U.mailIntent
  if not intent or not U.mailOpen or type(recipient)~="string"or type(subject)~="string"or not MoneyInputFrame_GetCopper or not SendMailMoney then return end
  if issecretvalue and (issecretvalue(recipient)or issecretvalue(subject))then return end
  local ok,amount=pcall(MoneyInputFrame_GetCopper,SendMailMoney)
  if not ok or issecretvalue and issecretvalue(amount)then return end
  if same(recipient,intent.recipient)and subject==intent.subject and amount==intent.amount then
   U.mailAttempt={quote=intent.quote,leg=intent.leg,at=now()}
  end
 end)
end
