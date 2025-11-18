local meta = FindMetaTable("Player")

if (SERVER) then
	function meta:GetPlayTime()
		return self.ixPlayTime + (RealTime() - (self.ixJoinTime or RealTime()))
	end
else
	ix.playTime = ix.playTime or 0

	function meta:GetPlayTime()
		return ix.playTime + (RealTime() - ix.joinTime or 0)
	end
end

local vectorLength2D = FindMetaTable("Vector").Length2D

function meta:IsRunning()
	return vectorLength2D(self:GetVelocity()) > (self:GetWalkSpeed() + 10)
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

if (SERVER) then
	util.AddNetworkString("ixStringRequest")

	function meta:RequestString(title, subTitle, callback, default)
		local time = math.floor(os.time())

		self.ixStrReqs = self.ixStrReqs or {}
		self.ixStrReqs[time] = callback

		net.Start("ixStringRequest")
			net.WriteUInt(time, 32)
			net.WriteString(title)
			net.WriteString(subTitle)
			net.WriteString(default)
		net.Send(self)
	end
end
