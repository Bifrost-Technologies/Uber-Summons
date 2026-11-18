local U=Uber
local colors={bg={.025,.035,.055},card={.055,.075,.11},accent={.35,.85,.72}}
local function panel(parent,w,h,x,y)
    local f=CreateFrame("Frame",nil,parent,"BackdropTemplate");f:SetSize(w,h);f:SetPoint("TOPLEFT",x,y)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
    f:SetBackdropColor(unpack(colors.card));return f
end
local function label(f,text,x,y,w,h,big)
    local t=f:CreateFontString(nil,"OVERLAY",big and "GameFontNormalLarge"or "GameFontHighlightSmall")
    t:SetPoint("TOPLEFT",x,y);t:SetSize(w,h or 24);t:SetJustifyH("LEFT");t:SetJustifyV("TOP");t:SetText(text);return t
end
local function button(f,text,x,y,w,fn)
    local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,30);b:SetText(text);b:SetScript("OnClick",fn);return b
end
local function edit(f,text,x,y,w,multi)
    local b=CreateFrame("EditBox",nil,f,"InputBoxTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,multi and 82 or 28)
    b:SetAutoFocus(false);b:SetMaxLetters(multi and 480 or 100);b:SetText(text or "")
    if multi then b:SetMultiLine(true);b:SetFontObject("ChatFontNormal")end
    b:SetScript("OnEscapePressed",function(s)s:ClearFocus()end);b:SetScript("OnEnterPressed",function(s)if not multi then s:ClearFocus()end end);return b
end
local function check(f,text,x,y,w)
    local b=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(26,26);label(f,text,x+32,y-5,w or 180);return b
end
function U:Notice(text)self.notice=text;self:Refresh()end
function U:Tab(tab)
    if self.menu then self.menu:Hide()end
    self.tab=tab
    for name,view in pairs(self.views)do view:SetShown(name==tab)end
    for name,b in pairs(self.tabs)do b:SetEnabled(name~=tab)end
    self:Refresh()
end
function U:RefreshProvider()
    if self.DiscoverDrivers then self:DiscoverDrivers(true)end
    if self.db.dispatcher and self.db.dispatcher~=""then self:Send({"ROSTER"},self.db.dispatcher)end
    if self.db.provider~=""then self:Send({"Q"},self.db.provider)end
end
function U:Show()
    if not self.db then return end
    if not self.frame then
        local f=CreateFrame("Frame","UberPanel",UIParent,"BackdropTemplate");self.frame=f
        f:SetSize(940,700);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true)
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16});f:SetBackdropColor(unpack(colors.bg))
        f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton");f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
        label(f,"UBER",28,-22,180,32,true):SetTextColor(unpack(colors.accent))
        label(f,"Summons, portals and your next adventure.",180,-27,550)
        button(f,"X",880,-18,34,function()f:Hide()end)
        self.views={};self.tabs={}
        for i,title in ipairs({"Drivers","Book a summon","Track & map","Driver desk","Recruitment"})do
            local key=title;self.tabs[key]=button(f,title,26+(i-1)*180,-72,168,function()self:Tab(key)end)
            local view=CreateFrame("Frame",nil,f);view:SetPoint("TOPLEFT",24,-120);view:SetSize(892,520);self.views[key]=view
        end
        self.footer=label(f,"",28,-654,880,30)
        button(f,"Guild LFG",760,-14,110,function()
            if _G.TranquilityLFG then _G.TranquilityLFG:Show()else self:Notice("Enable TranquilityLFG to open your guild's private group finder.")end
        end)
        local v=self.views["Book a summon"]
        label(v,"Where are we setting up?",12,-4,700,34,true)
        label(v,"Driver character-realm",12,-48,250);self.provider=edit(v,self.db.provider,260,-44,390)
        button(v,"Use driver",668,-44,208,function()
            local n=self.provider:GetText();if #n<=100 and not n:find("[%c|]")then self.db.provider=n;self:RefreshProvider();self:Notice(self:Approved(n)and "Driver selected."or "Driver awaits dispatcher approval / roster refresh.")end
        end)
        label(v,"Dungeon, zone or custom FOB",12,-92,250);self.destination=edit(v,"",260,-88,615)
        label(v,"Party size (1–40)",12,-134,240);self.party=edit(v,"5",260,-130,90)
        label(v,"Bring / prepare",12,-178,240);self.supplyChecks={}
        for i,s in ipairs(self.services)do self.supplyChecks[s]=check(v,s,260+((i-1)%3)*200,-170-math.floor((i-1)/3)*34,155)end
        label(v,"Notes & setup instructions",12,-258,800)
        local box=panel(v,860,104,12,-286);self.note=edit(box,"",14,-12,824,true)
        label(v,"Include entrance, quest needs, meeting time, buffs and any safety information. 480 bytes maximum.",12,-402,865,35)
        button(v,"Send camp request",12,-448,280,function()
            local supplies={};for _,s in ipairs(self.services)do if self.supplyChecks[s]:GetChecked()then supplies[#supplies+1]=s end end
            local id=self:Request(self.destination:GetText(),nil,{note=self.note:GetText(),supplies=table.concat(supplies,", "),party=self.party:GetText()})
            self:Notice(id and (self.db.outbox[id].status or "Request queued. Waiting for the driver's receipt.")or self.notice or "Select an approved driver, enter a destination and valid details, or wait 15 seconds.")
            if id then self:Tab("Track & map")end
        end)
        button(v,"Join driver's active camp",310,-448,280,function()
            local o=self.db.orders[self.db.provider];local id=self:IsFresh(o)and o.status~="COMPLETE"and o.status~="CANCELLED"and self:Request(o.destination,o.id,{party=self.party:GetText(),note=self.note:GetText()})
            self:Notice(id and "Join request queued."or "Refresh a live camp and select an approved driver first.")
        end)
        button(v,"Refresh driver",610,-448,264,function()self:RefreshProvider();self:Notice("Requested driver update.")end)
        v=self.views["Track & map"]
        local hero=panel(v,866,112,12,-4);self.tracking=label(hero,"",18,-18,830,85,true)
        self.stages={};for i,s in ipairs({"Accepted","On the way","Setting up","Service open"})do
            local card=panel(v,207,62,12+(i-1)*220,-134);self.stages[i]=label(card,tostring(i).."  "..s,12,-20,188,30)
        end
        local location=panel(v,866,152,12,-216)
        label(location,"DRIVER LOCATION",18,-16,600,30,true);self.locationLabel=label(location,"",18,-56,810,66)
        button(v,"Open live location on world map",12,-390,420,function()self:Map()end)
        button(v,"Refresh location & status",452,-390,425,function()self:RefreshProvider()end)
        self.summonButton=button(v,"Summon now!",12,-444,420,function()self:Notice(self:SummonNow()and "Summon request whispered to your driver."or "Join the camp and wait for Service open. Requests have a 30-second cooldown.")end)
        label(v,"Available once your driver opens service. Your click sends one whisper; the driver casts manually.",452,-448,425,36)
        v=self.views["Driver desk"]
        self.driverHeader=label(v,"",12,-4,860,46,true)
        button(v,"Open / close my service",12,-62,275,function()self:Notice(self:OpenService()and "Availability updated."or "Only approved Warlock or Mage drivers can open service.")end)
        label(v,"ETA minutes",310,-68,130);self.minutes=edit(v,"15",450,-62,80)
        for i,s in ipairs({"ACCEPTED","TRAVELING","SETTING_UP","READY","PAUSED","COMPLETE","CANCELLED"})do local status=s
            button(v,self.statusLabels[s],12+((i-1)%4)*220,-110-math.floor((i-1)/4)*38,208,function()self:Notice(self:SetStatus(status,self.minutes:GetText())and "Camp status published."or "Open service and accept an order first.")end)
        end
        label(v,"REQUEST INBOX — select to inspect before accepting",12,-200,860)
        self.rows={};self.visible={}
        for i=1,4 do local index=i;self.rows[i]=button(v,"",12,-230-(i-1)*34,400,function()self.selected=self.visible[index];self:Refresh()end)end
        local scroll=CreateFrame("ScrollFrame",nil,v,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",440,-230);scroll:SetSize(403,152)
        local detailBody=CreateFrame("Frame",nil,scroll);detailBody:SetSize(383,500);scroll:SetScrollChild(detailBody)
        self.orderDetail=label(detailBody,"",0,0,380,490)
        button(v,"Accept selected + set ETA",440,-398,425,function()
            self:Notice(self.selected and self:Accept(self.selected,self.minutes:GetText())and "Order accepted; setting up camp."or "Select a new order, choose ETA, and complete any active camp first.")
        end)
        button(v,"Previous",12,-390,190,function()self.page=math.max(1,(self.page or 1)-1);self:Refresh()end)
        button(v,"Next",220,-390,190,function()self.page=(self.page or 1)+1;self:Refresh()end)
        button(v,"Clear completed inbox",12,-440,400,function()for id,r in pairs(self.db.inbox)do if r.status=="COMPLETE"or r.status=="CANCELLED"or r.delivery then self.db.inbox[id]=nil end end;self:Refresh()end)
        button(v,"Clear completed requests",440,-440,425,function()for id,r in pairs(self.db.outbox)do if r.status=="COMPLETE"or r.status=="CANCELLED"then self.db.outbox[id]=nil end end;self:Refresh()end)
        v=self.views["Recruitment"]
        label(v,"Trusted guild dispatcher",12,-4,860,34,true)
        label(v,"Use the same exact character-realm as your guild. Only that character's reviews are trusted.",12,-44,860,32)
        self.dispatcher=edit(v,self.db.dispatcher,12,-84,580)
        button(v,"Save / request roster",610,-84,265,function()
            local n=self.dispatcher:GetText();if #n>0 and #n<=100 and not n:find("[%c|]")then
                if n~=self.db.dispatcher then self.online=false;self.db.drivers={};self.db.orders={}end
                self.db.dispatcher=n;self:RefreshProvider();self:Notice("Dispatcher saved. Verify this character with your guild.")
            end
        end)
        label(v,"Apply as a Warlock or Mage driver",12,-134,860,34,true)
        label(v,"Describe your summoning experience, available buffs/supplies, schedule and preferred zones.",12,-174,860)
        self.application=edit(v,"",12,-210,860);self.application:SetMaxLetters(160)
        button(v,"Send driver application",12,-250,400,function()self:Notice(self:ApplyDriver(self.application:GetText())and "Application sent for manual review."or "Warlocks and Mages only. Configure your dispatcher and wait 60 seconds between applications.")end)
        label(v,"DISPATCHER REVIEW",12,-304,860,30,true)
        self.reviewLabel=label(v,"",12,-344,860,70)
        button(v,"Next application",12,-420,270,function()self.reviewIndex=(self.reviewIndex or 1)+1;self:Refresh()end)
        self.verified=check(v,"Verified class, spells/reagents/helpers, conduct and setup readiness",12,-464,820)
        button(v,"Approve driver",300,-420,275,function()if self.reviewName and self.verified:GetChecked()then self:ReviewDriver(self.reviewName,true);self:Notice("Driver approved.")else self:Notice("Review the application and verify readiness first.")end end)
        button(v,"Decline / revoke",590,-420,285,function()if self.reviewName then self:ReviewDriver(self.reviewName,false)end end)
        table.insert(UISpecialFrames,"UberPanel")
    end
    self.frame:Show();self:Tab(self.tab or "Drivers");self:RefreshProvider()
end
function U:Refresh()
    if not self.frame or not self.frame:IsShown()then return end
    self:DriverDB();self.footer:SetText(self.notice or "Free, player-operated summons coordination. No automatic casting. /uber to reopen.")
    local o=self:Current();local fresh=self:IsFresh(o);local stage=o and o.status
    self.tracking:SetText(o and ((self.statusLabels[stage]or stage).."\n"..o.destination.."  |  ETA "..math.max(0,math.ceil((o.eta-GetServerTime())/60)).." min  |  "..(fresh and "Updated "..math.max(0,GetServerTime()-o.updated).."s ago"or "Offline / stale — refresh"))or "No active camp yet\nSend a request or refresh your selected driver.")
    local latest
    for _,r in pairs(self.db.outbox)do if r.provider==self.db.provider and (not latest or (r.at or 0)>(latest.at or 0))then latest=r end end
    if latest then self.tracking:SetText((self.tracking:GetText() or "").."\nYour request: "..latest.status)end
    local steps={ACCEPTED=1,TRAVELING=2,SETTING_UP=3,READY=4}
    for i,s in ipairs(self.stages)do s:SetTextColor(unpack(i==(steps[stage]or 0)and colors.accent or {.6,.65,.7}))end
    local info=o and o.map and o.map>0 and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(o.map)
    self.locationLabel:SetText(o and o.map and o.map>0 and ((info and info.name or "Map "..o.map).."\n"..("%.1f, %.1f"):format(o.x*100,o.y*100).."  |  "..(fresh and "Current driver position"or "Last known position (stale)").."\nOpen the world map below to view the waypoint.")or "Location unavailable. The driver must open service and publish a supported map position.")
    self.summonButton:SetText(self:DriverClass(self.db.provider)=="MAGE"and "Portal now!"or "Summon now!")
    self.summonButton:SetEnabled(fresh and stage=="READY"and not self.online)
    self.driverHeader:SetText((self.online and "SERVICE OPEN"or "SERVICE CLOSED").."  |  "..(self:Approved(GetUnitName("player",true))and "Approved driver"or "Driver approval required"))
    local ids={};for id in pairs(self.db.inbox)do ids[#ids+1]=id end;table.sort(ids,function(a,b)return self.db.inbox[a].at>self.db.inbox[b].at end)
    self.page=math.min(self.page or 1,math.max(1,math.ceil(#ids/4)));self.visible={}
    for i,b in ipairs(self.rows)do local id=ids[(self.page-1)*4+i];self.visible[i]=id;local r=id and self.db.inbox[id];b:SetText(r and (r.sender.." — "..r.destination)or "No request");b:SetEnabled(r~=nil)end
    local r=self.selected and self.db.inbox[self.selected];local d=r and r.details or {}
    self.orderDetail:SetText(r and (r.sender.."\n"..r.destination.." | "..r.status.."\nParty: "..(d.party or "pending").."\nPrepare: "..(d.supplies or "pending").."\n"..(d.note or "Notes pending / no notes"))or "Select an inbox order to inspect its notes and setup needs.")
    local apps={};for _,a in pairs(self.db.applications)do apps[#apps+1]=a end;table.sort(apps,function(a,b)return a.at>b.at end)
    self.reviewIndex=((self.reviewIndex or 1)-1)%math.max(1,#apps)+1;local a=apps[self.reviewIndex]
    if self.reviewName~=(a and a.name)then self.verified:SetChecked(false)end
    self.reviewName=a and a.name
    self.reviewLabel:SetText(self:IsDispatcher()and (a and (a.name.." | "..(a.class or "WARLOCK").." | "..a.status.."\n"..a.note)or "No driver applications yet.")or "Only the configured dispatcher can review applications. Ask your guild which character to trust.")
end
