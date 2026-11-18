local U=Uber
local function stamp(t)return date and date("%Y-%m-%d %H:%M",t)or tostring(t)end
local function label(f,text,x,y,w,h,big)
 local t=f:CreateFontString(nil,"OVERLAY",big and "GameFontNormalLarge"or "GameFontHighlightSmall");t:SetPoint("TOPLEFT",x,y);t:SetSize(w,h or 26);t:SetJustifyH("LEFT");t:SetJustifyV("TOP");t:SetText(text);return t
end
local function button(f,text,x,y,w,fn)
 local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,30);b:SetText(text);b:SetScript("OnClick",fn);return b
end
local function edit(f,text,x,y,w,max)
 local e=CreateFrame("EditBox",nil,f,"InputBoxTemplate");e:SetPoint("TOPLEFT",x,y);e:SetSize(w,28);e:SetAutoFocus(false);e:SetMaxLetters(max or 70);e:SetText(text or "");e:SetScript("OnEscapePressed",function(s)s:ClearFocus()end);e:SetScript("OnEnterPressed",function(s)s:ClearFocus()end);return e
end
local function modal(name,w,h,title)
 local f=CreateFrame("Frame",name,UIParent,"BackdropTemplate");f:SetSize(w,h);f:SetPoint("CENTER");f:SetFrameStrata("FULLSCREEN_DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true)
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16});f:SetBackdropColor(.025,.035,.055,1)
 label(f,title,24,-20,w-90,32,true):SetTextColor(.35,.85,.72);button(f,"X",w-52,-14,30,function()f:Hide()end)
 f:SetMovable(true);f:RegisterForDrag("LeftButton");f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
 table.insert(UISpecialFrames,name);return f
end
function U:ShowSchedule()
 if not self.scheduleFrame then
  local f=modal("UberReservations",780,610,"UBER · ADVANCE RESERVATIONS");self.scheduleFrame=f
  self.scheduleDriver=label(f,"",24,-64,730,70)
  label(f,"Requested time · your computer's local time · up to 30 days ahead",24,-144,730)
  self.scheduleInput=edit(f,"",24,-180,370,16);label(f,"YYYY-MM-DD HH:MM",410,-185,320)
  button(f,"Use requested time",24,-224,350,function()
   local at=self:ParseBookingTime(self.scheduleInput:GetText())
   if at==false then self:Notice("Enter a real future date/time, at least 5 minutes and at most 30 days ahead.");return end
   self.bookingTime=at;self:Notice(at and "Advance time selected: "..stamp(at)..". Send your request from Book a summon."or "Immediate request selected. Driver must be live.");f:Hide()
  end)
  button(f,"Book now instead",400,-224,350,function()self.bookingTime=nil;f:Hide();self:Refresh()end)
  label(f,"Offline requests remain on this character until you are online together. They are NOT delivered, accepted or paid until acknowledged. Prices may change before the driver quotes. Published hours are informational; wait for confirmation.",24,-274,730,66)
  self.reservationLabel=label(f,"",24,-356,730,140)
  button(f,"Previous",24,-520,165,function()self.reservationPage=math.max(1,(self.reservationPage or 1)-1);self:Refresh()end)
  button(f,"Next",206,-520,165,function()self.reservationPage=(self.reservationPage or 1)+1;self:Refresh()end)
  button(f,"Cancel local reservation",390,-520,360,function()if self.reservationSelected then self:CancelReservation(self.reservationSelected)end;self:Refresh()end)
 end
 self.scheduleFrame:Show();self:Refresh()
end
function U:AdminSelect(who)
 local p=self:ProviderPolicy(who);self.adminName:SetText(who);self.adminClass= self:DriverClass(who)
 self.adminBase:SetText(("%.4f"):format((p.standard or 0)/10000));self.adminPriority:SetText(("%.4f"):format((p.priority or 0)/10000))
 self.adminHours:SetText(p.hours);self.adminReason:SetText(p.reason or "Manual review");self.adminState:SetText((p.state or "APPROVED").." · "..self.adminClass)
end
function U:ShowAdmin()
 if not self:IsDispatcher()then self:Notice("Provider administration is restricted to "..self.FOUNDER.." on this realm.");return false end
 if not self.adminFrame then
  local f=modal("UberAdministration",900,700,"UBER · CREATOR CONTROL ROOM");self.adminFrame=f
  label(f,"Bîfrost Titan · Character-authenticated reviews · Changes are logged and published",24,-60,850)
  label(f,"Provider name (exact native name, including realm if required)",24,-102,700)
  self.adminName=edit(f,self.FOUNDER,24,-136,600,60)
  button(f,"Load provider",644,-136,230,function()self:AdminSelect(self.adminName:GetText())end)
  self.adminState=label(f,"WARLOCK",24,-182,850)
  button(f,"Toggle Mage / Warlock",24,-216,280,function()self.adminClass=self.adminClass=="MAGE"and "WARLOCK"or "MAGE";self.adminState:SetText(self.adminClass)end)
  label(f,"Additional base (gold)",330,-216,240);self.adminBase=edit(f,"0",580,-210,120,20)
  label(f,"Priority extra (gold)",330,-260,240);self.adminPriority=edit(f,"0",580,-254,120,20)
  label(f,"Regular hours + timezone",24,-304,220);self.adminHours=edit(f,"Hours not published",260,-298,610,70)
  label(f,"Review / moderation reason",24,-348,230);self.adminReason=edit(f,"Manual review",260,-342,610,40)
  local function change(state)
   local ok=self:ManageProvider(self.adminName:GetText(),state,self.adminClass or "WARLOCK",self.adminBase:GetText(),self.adminPriority:GetText(),self.adminHours:GetText(),self.adminReason:GetText())
   self:Notice(ok and "Provider policy saved and queued for distribution."or "Check identity, class, amounts, hours and reason. Founder cannot be removed or banned.");self:Refresh()
  end
  button(f,"Add / approve / unban",24,-392,270,function()change("APPROVED")end)
  button(f,"Remove provider",314,-392,270,function()change("REMOVED")end)
  button(f,"Ban provider",604,-392,270,function()change("BANNED")end)
  label(f,"Provider directory · includes removed/banned entries for review",24,-444,830)
  self.adminDirectory=label(f,"",24,-478,830,106)
  button(f,"Load mailbox application",24,-596,270,function()
   local apps={};for _,a in pairs(self.db.applications)do if a.status=="Needs review"then apps[#apps+1]=a end end;table.sort(apps,function(a,b)return a.at>b.at end)
   if #apps==0 then self:Notice("Inspect your open mailbox first. No pending application has been read yet.");return end
   self.adminApplicationIndex=(self.adminApplicationIndex or 0)%#apps+1;local a=apps[self.adminApplicationIndex]
   self:AdminSelect(a.name);self.adminClass=a.class;self.adminState:SetText("APPLICATION · "..a.class.." · Read the original letter before approving.")
  end)
  button(f,"Next / load provider",314,-596,270,function()
   self.adminIndex=(self.adminIndex or 1)+1;self:Refresh();if self.adminSelected then self:AdminSelect(self.adminSelected)end
  end)
  button(f,"Receipts & delivery audit",604,-596,270,function()self:ShowAudit()end)
  label(f,"22s per Mage portal stays with the Mage. Pricing edits affect new quotes; accepted quotes retain their amounts. Ban reasons are internal moderation records, not a public finding of fraud.",24,-640,840,42)
 end
 self.adminClass=self.adminClass or "WARLOCK";self.adminFrame:Show();self:Refresh();return true
end
function U:ShowAudit()
 if not self.auditFrame then
  local f=modal("UberAudit",900,680,"UBER · RECEIPTS & DELIVERY TIMELINE");self.auditFrame=f
  label(f,"Local observations and remote reports are labeled separately. Character names and timestamps are retained. No private chat or keystrokes are recorded. Last 2,000 audit events retained per character.",24,-64,850,58)
  self.auditFilter=edit(f,"",24,-130,570,100)
  button(f,"Filter by character / order",620,-130,250,function()self.auditPage=1;self:Refresh()end)
  self.auditLines=label(f,"",24,-182,845,350)
  button(f,"Previous records",24,-550,270,function()self.auditPage=math.max(1,(self.auditPage or 1)-1);self:Refresh()end)
  button(f,"Next records",314,-550,270,function()self.auditPage=(self.auditPage or 1)+1;self:Refresh()end)
  button(f,"Inspect my open mailbox",604,-550,270,function()self:CheckOwnInbox();self:Refresh()end)
  label(f,"A cast is not delivery. Automatic delivery requires party + cast + matching customer travel. Summons additionally need a matching native summon offer. Remote reports can be modified by their sender; unavailable evidence remains unconfirmed.",24,-606,845,52)
 end
 self.auditFrame:Show();self:Refresh()
end
local show=U.Show
function U:Show()
 show(self)
 if not self.adminEntry then
  local v=self.views["Recruitment"]
  -- Replace the old configurable-dispatcher controls with a single fixed-founder flow.
  for _,child in ipairs({v:GetChildren()})do child:Hide()end
  for _,region in ipairs({v:GetRegions()})do region:Hide()end
  label(v,"Become an Uber provider",12,-4,850,38,true):SetTextColor(.35,.85,.72)
  label(v,"Creator & reviewer: "..self.FOUNDER..". Mage and Warlock applications go to his in-game mailbox for manual review. Open a mailbox to prepare your draft, then use WoW's Send button.",12,-54,850,68)
  label(v,"Experience, spells, helpers, supplies, usual hours and timezone",12,-146,850)
  self.application=edit(v,"",12,-184,850,160)
  button(v,"Prepare application mail",12,-232,410,function()self:ApplyDriver(self.application:GetText())end)
  button(v,"Refresh reviewed providers",450,-232,410,function()self:RefreshProvider()end)
  label(v,"Your character is your identity. Applications do not open service until reviewed. Existing users must refresh the admin roster to receive revocations.",12,-292,850,64)
  self.adminEntry=button(v,"Creator · manage providers",12,-382,410,function()self:ShowAdmin()end)
  button(v,"My receipts & delivery timeline",450,-382,410,function()self:ShowAudit()end)
  label(v,"Player-operated travel · Native addon messages · No chat input interception",12,-450,850,36)
  button(self.views["Book a summon"],"Schedule ahead / offline reservations",12,-494,865,function()self:ShowSchedule()end)
  button(self.views["Drivers"],"Receipts & delivery timeline",12,-502,865,function()self:ShowAudit()end)
  -- These invisible legacy references are still used by the shared refresh renderer.
  self.dispatcher:SetText(self.FOUNDER);self.dispatcher:Disable()
 end
 self:Refresh()
end
local refresh=U.Refresh
function U:Refresh()
 refresh(self);if not self.db then return end
 if self.adminEntry then self.adminEntry:SetEnabled(self:IsDispatcher())end
 if self.locationLabel and self:ProviderLive(self.db.provider)then
  local p=self.providerPositions and self.providerPositions[self.NameKey(self.db.provider)]
  if p and GetServerTime()-p.updated<=90 then
   local info=C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(p.map)
   self.locationLabel:SetText((info and info.name or "Map "..p.map).." · "..("%.1f, %.1f"):format(p.x*100,p.y*100).."\nLive service position · updated "..(GetServerTime()-p.updated).."s ago\nOpen the world map to view the provider.")
  end
 end
 if self.orderDetail and self.selected then
  local r=self.db.inbox[self.selected]
  if r then self.orderDetail:SetText((self.orderDetail:GetText()or "")..(r.scheduledAt and "\nReserved: "..stamp(r.scheduledAt).." (local time)"or "")..(r.delivery and "\n"..r.delivery or ""))end
 end
 if self.scheduleFrame and self.scheduleFrame:IsShown()then
  local p=self:ProviderPolicy(self.db.provider)
  self.scheduleDriver:SetText(self.db.provider.." · "..(self:ProviderLive(self.db.provider)and "LIVE"or "OFFLINE — advance requests only").."\nHours: "..p.hours.."\nSelected time: "..(self.bookingTime and stamp(self.bookingTime)or "Now"))
  local list={};for id,r in pairs(self:Reservations())do list[#list+1]=id end;table.sort(list)
  self.reservationPage=math.min(self.reservationPage or 1,math.max(1,#list));self.reservationSelected=list[self.reservationPage]
  local r=self.reservationSelected and self:Reservations()[self.reservationSelected]
  self.reservationLabel:SetText(r and ("Reservation "..self.reservationPage.." / "..#list.."\n"..r.provider.." · "..r.destination.."\n"..stamp(r.scheduledAt).."\n"..r.status)or "No saved offline reservations.")
 end
 if self.adminFrame and self.adminFrame:IsShown()then
  if not self:IsDispatcher()then self.adminFrame:Hide();return end
  local list={};for _,r in pairs(self.db.drivers)do list[#list+1]=r.name end;table.sort(list)
  self.adminIndex=math.min(self.adminIndex or 1,math.max(1,#list));self.adminSelected=list[self.adminIndex]
  local n=self.adminSelected;local p=n and self:ProviderPolicy(n)
  self.adminDirectory:SetText(n and (self.adminIndex.." / "..#list.." · "..n.."\n"..(p.state or "APPROVED").." · "..self:DriverClass(n).."\n"..p.hours.."\n"..(p.reason or "Creator provider"))or "No providers.")
 end
 if self.auditFrame and self.auditFrame:IsShown()then
  local entries={};local filter=self.auditFilter:GetText():lower()
  for i=#(self.db.audit or {}),1,-1 do local e=self.db.audit[i];local text=stamp(e.at).." · "..e.kind.." · "..e.source.."\n"..e.subject.." · "..e.detail
   if filter==""or text:lower():find(filter,1,true)then entries[#entries+1]=text end
  end
  self.auditPage=math.min(self.auditPage or 1,math.max(1,math.ceil(#entries/5)));local lines={}
  for i=(self.auditPage-1)*5+1,math.min(#entries,self.auditPage*5)do lines[#lines+1]=entries[i]end
  self.auditLines:SetText("Page "..self.auditPage.." · "..#entries.." events\n\n"..(#lines>0 and table.concat(lines,"\n\n")or "No matching records."))
 end
end
