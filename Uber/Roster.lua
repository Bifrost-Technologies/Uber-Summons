local U=Uber
function U:SelectDriver(who)
    self.db.provider=who;self.provider:SetText(who);if self.PeerReachable and self:PeerReachable(who)then self:Send({"Q"},who)end;self:Tab("Book a summon")
end
function U:DriverAction(who,action)
    if not self:Approved(who)then return false end
    if action=="request"then self:SelectDriver(who);return true end
    if action=="rate"then return self:ShowStars(who)end
    if action=="friend"then
        local add=C_FriendList and C_FriendList.AddFriend or AddFriend
        if add then local ok=pcall(add,who);self:Notice(ok and "Friend request sent to "..who.."."or "Unable to add friend.");return ok end
    elseif action=="guild"then
        local send=SendChatMessage or C_ChatInfo and C_ChatInfo.SendChatMessage
        if send and GetServerTime()-(self.guildAskAt or 0)>=30 then
            local ok,result=pcall(send,"Hi! I'd like to join your guild. Could you arrange an invitation? [Uber]","WHISPER",nil,who)
            if ok and result~=false then self.guildAskAt=GetServerTime();self:Notice("Guild invitation requested from "..who..".");return true end
        end
    end
    return false
end
function U:DriverMenu(who,anchor)
    if not self.menu then
        local f=CreateFrame("Frame",nil,self.frame,"BackdropTemplate");self.menu=f
        f:SetSize(240,186);f:SetFrameStrata("TOOLTIP");f:SetClampedToScreen(true);f:EnableMouse(true)
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12});f:SetBackdropColor(.04,.06,.09,1)
        for i,item in ipairs({{"Request summons","request"},{"Add friend","friend"},{"Ask to join guild","guild"},{"Rate completed service","rate"},{"Close",false}})do
            local action=item[2];local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");b:SetPoint("TOPLEFT",10,-10-(i-1)*34);b:SetSize(220,28);b:SetText(item[1])
            b:SetScript("OnClick",function()f:Hide();if action then self:DriverAction(self.menuName,action)end end)
        end
    end
    self.menuName=who;self.menu:ClearAllPoints();self.menu:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,0);self.menu:Show()
end
local show=U.Show
function U:Show()
    show(self)
    if not self.rosterRows then
        local f=self.views["Drivers"]
        local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");title:SetPoint("TOPLEFT",12,-4);title:SetText("Meet your approved summons & portal drivers")
        local tip=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");tip:SetPoint("TOPLEFT",12,-44);tip:SetSize(860,35);tip:SetJustifyH("LEFT");tip:SetText("Choose Order Uber, or right-click a driver for summons, friends and guild requests. Class icon shown when a live portrait is unavailable.")
        self.availability=tip
        local helpers=CreateFrame('Button',nil,f,'UIPanelButtonTemplate');helpers:SetPoint('TOPRIGHT',-12,-54);helpers:SetSize(180,26);helpers:SetText('Find summon click helpers');helpers:SetScript('OnClick',function()SummonClickHelpers:Show()end)
        self.rosterRows={}
        for i=1,4 do
            local row=CreateFrame("Button",nil,f,"BackdropTemplate");self.rosterRows[i]=row
            row:SetPoint("TOPLEFT",12,-94-(i-1)*92);row:SetSize(866,88);row:RegisterForClicks("LeftButtonUp","RightButtonUp")
            row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10});row:SetBackdropColor(.055,.075,.11,1)
            row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetPoint("TOPLEFT",12,-11);row.icon:SetSize(54,54)
            row.title=row:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");row.title:SetPoint("TOPLEFT",84,-14);row.title:SetSize(510,24);row.title:SetJustifyH("LEFT")
            row.info=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.info:SetPoint("TOPLEFT",84,-36);row.info:SetSize(510,46);row.info:SetJustifyH("LEFT")
            local order=CreateFrame("Button",nil,row,"UIPanelButtonTemplate");row.order=order;order:SetPoint("TOPRIGHT",-48,-22);order:SetSize(170,32);order:SetText("Order Uber")
            order:SetScript("OnClick",function()if row.driver then self:SelectDriver(row.driver)end end)
            local tools=CreateFrame("Button",nil,row,"UIPanelButtonTemplate");tools:SetPoint("TOPRIGHT",-10,-22);tools:SetSize(30,32);tools:SetText("...")
            tools:SetScript("OnClick",function()if row.driver then self:DriverMenu(row.driver,row)end end)
            row:SetScript("OnClick",function(_,mouse)if row.driver then if mouse=="RightButton"then self:DriverMenu(row.driver,row)else self:SelectDriver(row.driver)end end end)
        end
        for i,text in ipairs({"Previous drivers","Next drivers","Refresh roster"})do
            local index=i;local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");b:SetPoint("TOPLEFT",12+(i-1)*294,-466);b:SetSize(278,30);b:SetText(text)
            b:SetScript("OnClick",function()if index==3 then self:RefreshProvider()else self.rosterPage=math.max(1,(self.rosterPage or 1)+(index==1 and -1 or 1))end;self:Refresh()end)
        end
    end
    self:Refresh()
end
local refresh=U.Refresh
function U:Refresh()
    refresh(self)
    if not self.rosterRows or not self.frame:IsShown()then return end
    local list={}
    if self.ProviderDirectory then list=self:ProviderDirectory();self.availability:SetText("Online presence and booking availability are separate. Unavailable providers accept advance reservations only. Creator: "..self.FOUNDER)
    elseif self.ActiveDrivers then list=self:ActiveDrivers();self.availability:SetText(self:AvailabilityMessage())
    else for _,r in pairs(self.db.drivers)do if self:Approved(r.name)then list[#list+1]=r.name end end;table.sort(list)end
    self.rosterPage=math.min(self.rosterPage or 1,math.max(1,math.ceil(#list/4)))
    for i,row in ipairs(self.rosterRows)do
        local who=list[(self.rosterPage-1)*4+i];row.driver=who;row:SetShown(who~=nil)
        if who then
            row.title:SetText(who);local o=self.db.orders[who]
            local mage=self:DriverClass(who)=="MAGE"
            local peer=self.peers and self.peers[self.NameKey(who)]
            row.info:SetText((mage and "Mage · Portals | "or "Warlock · Summons | ")..(peer and ("From "..self:Money(peer.standard).." | priority +"..self:Money(peer.priority))or o and self:IsFresh(o)and (self.statusLabels[o.status]or o.status)or "Availability not confirmed"))
            row.icon:SetTexture(mage and "Interface\\Icons\\ClassIcon_Mage"or "Interface\\Icons\\ClassIcon_Warlock");row.icon:SetTexCoord(0,1,0,1)
            if self.ProviderLive then
                local live,available,presence=self:ProviderPresence(who);local policy=self:ProviderPolicy(who)
                if row.order then row.order:SetText(available and "Order Uber"or "Reserve ahead")end
                row.title:SetText((live and "|cff59dbc0[ONLINE]|r "or "|cff999999[UNAVAILABLE]|r ")..(self:NativeTranquilityMember(who)and "|cffffd166"..who.."|r · Tranquility"or who)..(self.NameKey(who)==self.NameKey(self.FOUNDER)and "  · Creator"or ""))
                row:SetAlpha(live and 1 or .72)
                row:SetBackdropColor(live and .045 or .035,live and .12 or .045,live and .13 or .06,1)
                local base=policy.standard and policy.standard+self:PortalCost(who)or peer and peer.standard
                local price=base and ("From "..self:Money(base).." · Priority +"..self:Money(policy.priority or peer and peer.priority or 0))or "Quote required"
                local hours=type(policy.hours)=="string"and policy.hours or "Hours not published"
                if #hours>46 then hours=hours:sub(1,43).."..."end
                row.info:SetText((mage and "Mage portals"or "Warlock summons").." · "..price.."\n"..presence.." · "..hours.."\n"..self:RatingSummary(who))
            end
            -- Unit tokens are only available for self / party / raid; never invent remote portrait data.
            if SetPortraitTexture and GetUnitName then
                for _,unit in ipairs({"player","party1","party2","party3","party4"})do
                    local n=GetUnitName(unit,true)
                    if n and (not issecretvalue or not issecretvalue(n))and (n==who or self.NameKey and self.NameKey(n)==self.NameKey(who))then SetPortraitTexture(row.icon,unit);break end
                end
            end
        end
    end
end
function U:NativeTranquilityMember(who)
 local wanted=self.NameKey(who)
 for _,unit in ipairs({'player','party1','party2','party3','party4'})do
  local name=GetUnitName and GetUnitName(unit,true)
  if type(name)=='string'and(not issecretvalue or not issecretvalue(name))and self.NameKey(name)==wanted then
   local guild=GetGuildInfo and GetGuildInfo(unit);return type(guild)=='string'and(not issecretvalue or not issecretvalue(guild))and guild:lower()=='tranquility'
  end
 end
 local own=GetGuildInfo and GetGuildInfo('player');if type(own)~='string'or(issecretvalue and issecretvalue(own))or own:lower()~='tranquility'or not GetNumGuildMembers or not GetGuildRosterInfo then return false end
 for i=1,math.min(2000,GetNumGuildMembers()or 0)do local name=GetGuildRosterInfo(i);if type(name)=='string'and(not issecretvalue or not issecretvalue(name))and self.NameKey(name)==wanted then return true end end
 return false
end
function U:ShowStars(who)
 local id,latest=nil,0;for key,r in pairs(self.db.outbox)do if self.NameKey(r.provider)==self.NameKey(who)and r.deliveredAt and not r.stars and r.deliveredAt>latest then id,latest=key,r.deliveredAt end end
 if not id then self:Notice('Complete a corroborated Uber order before rating. One star-only review per order.');return false end
 if not self.ratingFrame then
  local f=CreateFrame('Frame',nil,UIParent,'BackdropTemplate');self.ratingFrame=f;f:SetSize(480,160);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:EnableMouse(true);f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=16});f:SetBackdropColor(.04,.06,.09,1)
  local title=f:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');title:SetPoint('TOP',0,-20);title:SetText('Rate your completed service · 5 is best')
  for i=1,5 do local stars=i;local b=CreateFrame('Button',nil,f,'UIPanelButtonTemplate');b:SetSize(76,30);b:SetPoint('TOPLEFT',24+(i-1)*87,-66);b:SetText(i..' / 5');b:SetScript('OnClick',function()if self:RateDeliveredOrder(self.ratingOrder,stars)then f:Hide();self:Notice('Star rating sent. Thank you!')end end)end
  local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT')
 end;self.ratingOrder=id;self.ratingFrame:Show();return true
end
