DeriveGamemode("sandbox")


mono = mono or {
	util = {}, 
	meta = {}
}

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("core/sh_util.lua")
AddCSLuaFile("core/sh_data.lua")
AddCSLuaFile("shared.lua")

include("core/sh_util.lua")
include("core/sh_data.lua")
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
