local U=Uber
local function now()return GetServerTime()end
function U:PeerReachable(who)
 if type(who)~='string'or who==''then return false end
 local wanted=self.NameKey(who)
 if wanted==self.NameKey(GetUnitName('player',true))then return true end
 local heard=self.peerHeardAt and self.peerHeardAt[wanted]
 if heard and now()-heard>=0 and now()-heard<=75 then return true end
 local p=self.peers and self.peers[wanted]
 if p and now()-p.at>=0 and now()-p.at<=75 then return true end
 local function matches(n,online)return online and type(n)=='string'and self.NameKey(n)==wanted end
 if GetNumGuildMembers and GetGuildRosterInfo then
  for i=1,math.min(GetNumGuildMembers()or 0,2000)do
   local n,_,_,_,_,_,_,_,online=GetGuildRosterInfo(i)
   if matches(n,online)then return true end
  end
 end
 if C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetFriendInfoByIndex then
  for i=1,C_FriendList.GetNumFriends()do local f=C_FriendList.GetFriendInfoByIndex(i);if f and matches(f.name,f.connected)then return true end end
 end
 for _,unit in ipairs({'party1','party2','party3','party4','raid1','raid2','raid3','raid4','raid5','raid6','raid7','raid8','raid9','raid10','raid11','raid12','raid13','raid14','raid15','raid16','raid17','raid18','raid19','raid20','raid21','raid22','raid23','raid24','raid25','raid26','raid27','raid28','raid29','raid30','raid31','raid32','raid33','raid34','raid35','raid36','raid37','raid38','raid39','raid40'})do
  if UnitExists and UnitExists(unit)and UnitIsConnected and UnitIsConnected(unit)and matches(GetUnitName(unit,true),true)then return true end
 end
 return false
end
local background={HELLO3=true,H3=true,LOCATION4=true,SCOPE1=true,CAP7=true,KEEP2=true,KEEPQ1=true,ADMINPING4=true,ROSTER=true,ROSTER4=true,ME7=true,ACK7=true,LEAVE7=true,EVIDENCE4=true}
local send=U.Send
function U:Send(parts,target,channel)
 if (channel==nil or channel=='WHISPER')and background[parts[1]]and not self.manualProbe and not self:PeerReachable(target)then return false end
 return send(self,parts,target,channel)
end
function U:DiscoverDrivers(force)
 self:Network()
 if now()-(self.discoveredAt or 0)<(force and 10 or 30)then return false end
 self.discoveredAt=now();local _,id=self:Network()
 if IsInGuild and IsInGuild()then self:Send({'DISCOVER5',id},nil,'GUILD')end
 if IsInRaid and IsInRaid()then self:Send({'DISCOVER5',id},nil,'RAID')
 elseif IsInGroup and IsInGroup()then self:Send({'DISCOVER5',id},nil,'PARTY')end
 for _,r in pairs(self.db.drivers or {})do
  if self:Approved(r.name)and self:PeerReachable(r.name)and #self.queue<70 then self:Send({'HELLO3',id},r.name)end
 end
 if force and self.db.provider~=''and self:Approved(self.db.provider)then
  self.manualProbe=true;self:Send({'HELLO3',id},self.db.provider);self.manualProbe=nil
 end
 return true
end
local receive=U.Receive
function U:Receive(text,sender,channel)
 if type(text)=='string'and #text<=240 and not text:find('[%c]')and type(sender)=='string'and #sender<=100 then
  self.peerHeardAt=self.peerHeardAt or {}
  local count=0;for name,at in pairs(self.peerHeardAt)do if now()-at>90 then self.peerHeardAt[name]=nil else count=count+1 end end
  local name=self.NameKey(sender);if self.peerHeardAt[name]or count<200 then self.peerHeardAt[name]=now()end
 end
 if type(text)=='string'and text:sub(1,10)=='DISCOVER5|'then
  local _,id=self:Network()
  if text~='DISCOVER5|'..id or (channel~='GUILD'and channel~='PARTY'and channel~='RAID')or self.NameKey(sender)==self.NameKey(GetUnitName('player',true))then return end
  if not self:Approved(GetUnitName('player',true))or now()-(self.last[sender..'discover5']or 0)<15 then return end
  self.last[sender..'discover5']=now()
  return receive(self,'HELLO3|'..id,sender,'WHISPER')
 end
 return receive(self,text,sender,channel)
end
