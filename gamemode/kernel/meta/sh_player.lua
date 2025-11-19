local meta = FindMetaTable("Player")

if (SERVER) then
	function meta:GetPlayTime()
		return self.playTime + (RealTime() - (self.bJoinTime or RealTime()))
	end
else
	mono.playTime = mono.playTime or 0

	function meta:GetPlayTime()
		return mono.playTime + (RealTime() - mono.joinTime or 0)
	end
end

local vectorLength2D = FindMetaTable("Vector").Length2D

function meta:IsRunning()
	return vectorLength2D(self:GetVelocity()) > (self:GetWalkSpeed() + 10)
end

function meta:GetID()
	return self:SteamID() .."_"..self:SteamID64().. mono.Server.API
end

function meta:IsStuck()
	return util.TraceEntity({
		start = self:GetPos(),
		endpos = self:GetPos(),
		filter = self
	}, self).StartSolid
end

function meta:ResetBodygroups()
	for i = 0, (self:GetNumBodyGroups() - 1) do
		self:SetBodygroup(i, 0)
	end
end

if (CLIENT) then
	net.Receive("monoStringRequest", function()
		local time = net.ReadUInt(32)
		local title, subTitle = net.ReadString(), net.ReadString()
		local default = net.ReadString()

		if (title:sub(1, 1) == "@") then
			title = L(title:sub(2))
		end

		if (subTitle:sub(1, 1) == "@") then
			subTitle = L(subTitle:sub(2))
		end

		Derma_StringRequest(title, subTitle, default or "", function(text)
			net.Start("monoStringRequest")
				net.WriteUInt(time, 32)
				net.WriteString(text)
			net.SendToServer()
		end)
	end)
end

if (SERVER) then
	util.AddNetworkString("monoStringRequest")

	function meta:RequestString(title, subTitle, callback, default)
		local time = math.floor(os.time())

		self.bStrReqs = self.bStrReqs or {}
		self.bStrReqs[time] = callback

		net.Start("monoStringRequest")
			net.WriteUInt(time, 32)
			net.WriteString(title)
			net.WriteString(subTitle)
			net.WriteString(default)
		net.Send(self)
	end
end
