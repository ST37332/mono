DeriveGamemode("sandbox")



mono = mono or {
	util = {}, 
	meta = {}
}

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("kernel/utils/sh_util.lua")
AddCSLuaFile("kernel/utils/sh_data.lua")
AddCSLuaFile("shared.lua")

include("kernel/utils/sh_util.lua")
include("kernel/utils/sh_data.lua")
include("shared.lua")

cvars.AddChangeCallback("sbox_persist", function(name, old, new)
	timer.Create("sbox_persist_change_timer", 1, 1, function()
		hook.Run("PersistenceSave", old)

		if (new == "") then
			return
		end

		hook.Run("PersistenceLoad", new)
	end)
end, "sbox_persist_load")
function GM:PlayerInitialSpawn(client)
	client.bJoinTime = RealTime()

	mono.option.Send(client)
	mono.date.Send(client)

	client:LoadData(function(data)
		if (!IsValid(client)) then return end

		-- Don't use the character cache if they've connected to another server using the same database
		local address = mono.util.GetAddress()
		local bNoCache = client:GetData("lastIP", address) != address
		client:SetData("lastIP", address)

		net.Start("bDataSync")
			net.WriteTable(data or {})
			net.WriteUInt(client.bPlayTime or 0, 32)
		net.Send(client)

	end)

	client:SetNoDraw(true)
	client:SetNotSolid(true)
	client:Lock()

	timer.Simple(1, function()
		if (!IsValid(client)) then
			return
		end

		client:KillSilent()
		client:StripAmmo()
	end)
end
