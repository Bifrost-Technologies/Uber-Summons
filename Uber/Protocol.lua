-- Final public protocol boundary: validate before older wrappers can mutate caches.
local U=Uber
local counts={Q={1},R={4,5},A={3},S={9},D={4},HELLO3={2},H3={7},SCOPE1={3},SCOPE2={6},DISCOVER5={2},
 B3={5},Q3={10},C3={2},CA3={2},M3={5},MA3={3},END3={3},RC3={4},TIME4={3},RESERVED4={3},
 LINK4={3},CAST4={8},PARTYCAST4={8},ARRIVE4={8},PARTYARRIVE4={8},DELIVERED4={4},
 ADMINPING4={1},ADMINHERE4={1},ADMIN4={9},ROSTER={1},ROSTER4={2},ROSTERNEXT4={2},DRIVER={4,5},APPLY={2,3},
 LOCATION4={5},EVIDENCE4={7},EVIDENCEACK4={2},ME7={4},ACK7={3},LEAVE7={1},CAP7={5},KEEP1={6},KEEP2={8},KEEPQ1={1},PHASE1={4},PHASER1={2},RATE5={3},STARS5={3}}
local shared={Q=true,S=true,HELLO3=true,H3=true,SCOPE1=true,SCOPE2=true,DISCOVER5=true,ADMIN4=true,DRIVER=true,LOCATION4=true,ME7=true,LEAVE7=true,CAP7=true,KEEP1=true,KEEP2=true,KEEPQ1=true}
local channels={WHISPER=true,GUILD=true,PARTY=true,RAID=true}
local function clean(s,max)return type(s)=='string'and #s>0 and #s<=max and not s:find('[%c|]')end
function U:CheckPacket(text,channel)
 if type(text)~='string'or #text==0 or #text>240 or text:find('[%c]')then return nil,'invalid payload'end
 if not channels[channel]then return nil,'unsupported channel'end
 local p={};for value in(text..'|'):gmatch('(.-)|')do p[#p+1]=value;if #p>10 then return nil,'too many fields'end end
 local spec=counts[p[1]];if not spec then return nil,'unknown packet'end
 local found=false;for _,n in ipairs(spec)do if #p==n then found=true end end
 if not found then return nil,'wrong field count'end
 if not shared[p[1]]and channel~='WHISPER'then return nil,'requires whisper'end
 if p[1]=='H3'and(p[3]=='0'and p[6]~='OFFLINE'or p[3]=='1'and p[6]=='OFFLINE')then return nil,'contradictory presence'end
 if p[1]=='S'then
  for _,i in ipairs({4,6,7,8,9})do local n=tonumber(p[i]);if not n or n~=n or n==math.huge or n==-math.huge then return nil,'nonfinite status'end end
  local map=tonumber(p[6]);if map<0 or map>999999 or map%1~=0 then return nil,'invalid map'end
 end
 return p
end
function U:ProtocolReject(reason,sender,kind)
 self.protocolRejected=(self.protocolRejected or 0)+1
 self.lastProtocolReject={at=GetServerTime(),reason=reason,sender=type(sender)=='string'and sender:gsub('[%c|]',''):sub(1,100)or 'invalid',kind=type(kind)=='string'and kind:sub(1,16)or '?'}
end
function U:ReceiveBudget(sender)
 self.receiveWindows=self.receiveWindows or {};local now=GetServerTime();local count=0
 for key,row in pairs(self.receiveWindows)do if now-row.at>120 then self.receiveWindows[key]=nil else count=count+1 end end
 local key=self.NameKey(sender);local row=self.receiveWindows[key]
 if not row then if count>=200 then return false end;row={at=now,start=now,total=0,second=now,burst=0};self.receiveWindows[key]=row end
 if now-row.start>=10 then row.start=now;row.total=0 end
 if row.second~=now then row.second=now;row.burst=0 end
 if row.total>=120 or row.burst>=20 then return false end
 row.at=now;row.total=row.total+1;row.burst=row.burst+1;return true
end
local background=U.IsBackgroundPacket
function U:IsBackgroundPacket(kind)return kind=='SCOPE2'or background(self,kind)end
local send=U.Send
function U:Send(parts,target,channel)
 channel=channel or 'WHISPER'
 if type(parts)~='table'then return false end
 for _,value in ipairs(parts)do if type(value)~='string'and type(value)~='number'then return false end end
 local packet,reason=self:CheckPacket(table.concat(parts,'|'),channel)
 if not packet or channel=='WHISPER'and not clean(target,100)then self:ProtocolReject(reason or 'missing target',GetUnitName('player',true),packet and packet[1]);return false end
 return send(self,parts,target,channel)
end
local receive=U.Receive
function U:Receive(text,sender,channel)
 if issecretvalue and(issecretvalue(text)or issecretvalue(sender)or issecretvalue(channel))then return end
 if not clean(sender,100)then self:ProtocolReject('invalid sender',nil);return end
 local p,reason=self:CheckPacket(text,channel)
 if not p then self:ProtocolReject(reason,sender);return end
 if not self:ReceiveBudget(sender)then self:ProtocolReject('sender rate limit',sender,p[1]);return end
 -- New ride requests cannot cross a known incompatible network, even in All view.
 if p[1]=='R'then
  local scope=self:DriverScope(sender)
  if not self:ScopeRealmAllowed(sender,self:LocalScope().realm)or scope and not self:ScopeMatches(scope)then self:ProtocolReject('incompatible request scope',sender,p[1]);return end
 end
 return receive(self,text,sender,channel)
end
local diagnostics=U.NetworkDiagnostics
function U:NetworkDiagnostics()
 diagnostics(self)
 local r=self.lastProtocolReject
 if r and DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(('Uber: Protocol rejected %d packets; latest %s from %s (%s).'):format(self.protocolRejected or 0,r.kind,r.sender,r.reason))end
end
