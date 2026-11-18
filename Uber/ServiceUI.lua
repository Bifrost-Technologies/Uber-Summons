local U=Uber
local function label(f,text,x,y,w,h)local t=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");t:SetPoint("TOPLEFT",x,y);t:SetSize(w,h or 26);t:SetJustifyH("LEFT");t:SetJustifyV("TOP");t:SetText(text);return t end
local function edit(f,text,x,y,w)local e=CreateFrame("EditBox",nil,f,"InputBoxTemplate");e:SetPoint("TOPLEFT",x,y);e:SetSize(w,26);e:SetAutoFocus(false);e:SetText(text);e:SetMaxLetters(60);e:SetScript("OnEscapePressed",function(s)s:ClearFocus()end);return e end
local function button(f,text,x,y,w,fn)local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,28);b:SetText(text);b:SetScript("OnClick",fn);return b end
function U:CurrentQuote()
 if self.online and self.selected then local r=self.db.inbox[self.selected];if r and r.quote then return self:Billing()[r.quote]end end
 return self.lastQuote and self:Billing()[self.lastQuote]
end
function U:ShowBilling()
 if not self.billingFrame then
  local f=CreateFrame("Frame","UberBilling",UIParent,"BackdropTemplate");self.billingFrame=f
  f:SetPoint("CENTER");f:SetSize(780,650);f:SetFrameStrata("FULLSCREEN_DIALOG");f:SetClampedToScreen(true)
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16});f:SetBackdropColor(.035,.05,.08,.99)
  label(f,"UBER — PRICES, PRIORITY & PAYMENT NOTICES",24,-22,700,28)
  button(f,"X",728,-14,30,function()f:Hide()end)
  self.priceInfo=label(f,"",24,-62,730,54)
  local priority=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate");self.priorityOption=priority;priority:SetPoint("TOPLEFT",24,-118);priority:SetSize(28,28)
  label(f,"Request priority (driver must accept)",58,-124,330)
  label(f,"Optional tip in gold",420,-124,200);self.tipInput=edit(f,"0",630,-118,110)
  button(f,"Save my order options",24,-160,350,function()
   local tip=self:Gold(self.tipInput:GetText());if not tip then self:Notice("Use a nonnegative gold amount with at most four decimals.");return end
   local portals=tonumber(self.portalInput:GetText());if not portals or portals%1~=0 or portals<1 or portals>40 then self:Notice("Use 1–40 portal casts.");return end
   self.bookingOptions={priority=priority:GetChecked()==true,tip=tip,portals=portals};self:Notice("Options saved for your next request. Nothing has been paid.");self:Refresh()
  end)
  label(f,"Mage portal casts",420,-166,200);self.portalInput=edit(f,"1",630,-160,110)
  label(f,"MY DRIVER PRICES (gold)",24,-210,730)
  label(f,"Base extra",24,-250,120);self.baseInput=edit(f,"0",140,-246,105)
  label(f,"Priority extra",270,-250,140);self.premiumInput=edit(f,"0",418,-246,105)
  button(f,"Save prices",560,-246,180,function()
   local p=self:Network();self:Notice(self:SavePrices(self.baseInput:GetText(),self.premiumInput:GetText(),p.house)and "Your prices are saved and published if service is open."or "Invalid gold amount.")
  end)
  self.priceRule=label(f,"",24,-286,730,38)
  local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",24,-330);scroll:SetSize(706,94)
  local body=CreateFrame("Frame",nil,scroll);body:SetSize(680,360);scroll:SetScrollChild(body)
  self.quoteInfo=label(body,"",0,0,680,350)
  local function quote()return self:CurrentQuote()end
  button(f,"Accept this quote",24,-434,230,function()local q=quote();self:Notice(q and self:AcceptQuote(q.id)and "Quote acceptance sent; wait for driver acknowledgement."or "No current buyer quote to accept.")end)
  button(f,"Prepare house mail",272,-434,230,function()local q=quote();if not q or not self:ComposePayment(q.id,"H")then self:Notice("Open Send Mail with a clear draft and an accepted buyer quote. A zero share needs no mail.")end end)
  button(f,"Prepare driver / tip mail",520,-434,230,function()local q=quote();if not q or not self:ComposePayment(q.id,"D")then self:Notice("Open Send Mail with a clear draft and an accepted buyer quote. A zero share needs no mail.")end end)
  button(f,"Report house mail sent",24,-474,230,function()local q=quote();self:Notice(q and self:ReportMailSent(q.id,"H",false)and "Unverified sent notice queued to driver."or "No accepted payment to report, or already reported.")end)
  button(f,"Report driver mail sent",272,-474,230,function()local q=quote();self:Notice(q and self:ReportMailSent(q.id,"D",false)and "Unverified sent notice queued to driver."or "No accepted payment to report, or already reported.")end)
  button(f,"Check my own inbox",520,-474,230,function()if not self:CheckOwnInbox()then self:Notice("Open your own mailbox inbox first.")end end)
  button(f,"Driver: allow setup from buyer's sent notice",24,-514,726,function()
   local q=quote();self:Notice(q and self:AllowReportedPayment(q.id)and "Sent notice accepted for setup. This does not certify receipt. Return to Driver desk and accept the order."or "Driver only: quote must be accepted and required sent notices present.")
  end)
  self.billingNotice=label(f,"",24,-558,730,70)
  table.insert(UISpecialFrames,"UberBilling")
 end
 local p=self:Network();self.baseInput:SetText(("%.4f"):format(p.standard/10000));self.premiumInput:SetText(("%.4f"):format(p.priority/10000))
 local options=self.bookingOptions or {};self.tipInput:SetText(("%.4f"):format((options.tip or 0)/10000));self.priorityOption:SetChecked(options.priority==true)
 self.portalInput:SetText(tostring(options.portals or 1))
 self.billingFrame:Show();self:Refresh()
end
local show=U.Show
function U:Show()
 show(self)
 if not self.billingEntry then
  self.billingEntry=button(self.views["Book a summon"],"Price, priority & optional tip",380,-130,494,function()self:ShowBilling()end)
  button(self.views["Track & map"],"Quote / payment notices",12,-490,865,function()self:ShowBilling()end)
  button(self.views["Driver desk"],"My prices / order payment",672,-148,208,function()self:ShowBilling()end)
  button(self.views["Driver desk"],"Clear completed quote history",440,-478,425,function()self:ClearCompletedQuotes()end)
 end
 self:Refresh()
end
local refresh=U.Refresh
function U:Refresh()
 refresh(self)
 if self.billingFrame and self.billingFrame:IsShown()then
  local _,realm=self:Network();local p=self.peers and self.peers[self.NameKey(self.db.provider)]
  self.priceInfo:SetText("Realm: "..realm.." | Driver: "..(self.db.provider~=""and self.db.provider or "not selected").."\n"..(p and p.online and ("Starting price "..self:Money(p.standard).." | priority extra "..self:Money(p.priority))or "Driver availability / price not confirmed. Refresh the directory."))
  self.quoteInfo:SetText(self:PaymentSummary(self:CurrentQuote()))
  self.priceRule:SetText(self:PortalCost(GetUnitName("player",true))>0 and "Mage portal minimum: 22s, entirely to the Mage. Base/priority extras split 20/80. Tips go entirely to the driver."or "Zero base fee = free standard service. Base/priority fees split 20% house / 80% driver. Tips go entirely to the driver.")
  self.billingNotice:SetText((self.notice or "Mail is sent only through your native mailbox confirmation. Submitted is not received.").."\nHouse mail can arrive while its character is offline; fees cannot move across realms unless the game permits it.")
 end
 if self.online and self.orderDetail and self.selected then
  local r=self.db.inbox[self.selected];local q=r and r.quote and self:Billing()[r.quote]
  if q then self.orderDetail:SetText((self.orderDetail:GetText()or "").."\n\n"..(q.priority and "PRIORITY REQUEST — not an arrival guarantee\n"or "STANDARD REQUEST\n")..self:PaymentSummary(q))end
 end
 if self.online and self.rows then
  for i,row in ipairs(self.rows)do local id=self.visible and self.visible[i];local r=id and self.db.inbox[id]
   if r and r.intent and r.intent.priority then row:SetText("[PRIORITY] "..r.sender.." — "..r.destination)end
  end
 end
end
