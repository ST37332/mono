GM.Name = "Mono"
GM.Author = "Icey | aka Efim Andreevich"
GM.Website = ""
GM.Version = "0.1.2"

do
	local playerMeta = FindMetaTable("Player")
	playerMeta.mSteamID64 = playerMeta.mSteamID64 or playerMeta.SteamID64

	function playerMeta:SteamID64()
		return self:mSteamID64() or 0
	end

end

mono.util.Include('kernel/api/api_core.lua')

// That's for the future for now.
if GM.Version and GM.Version == "0.1.3" then
	mono.DX = mono.DX or mono.util.Include("game/cl_ui_shaders.lua")

	mono.util.Include("game/cl_ui_palette.lua")
	mono.util.Include("game/cl_ui_utils.lua")
	mono.util.Include("game/ui/generic.menu.lua", "client")
	mono.util.Include("game/ui/generic.panels.lua", "client")
	mono.util.Include("game/ui/tooltip.lua", "client")
	mono.util.Include("game/ui/mainmenu.title.lua", "client")
	mono.util.Include("game/ui/mainmenu.create.lua", "client")
	mono.util.Include("game/ui/tabmenu.frame.lua", "client")
	mono.util.Include("game/ui/tabmenu.lua", "client")

	mono.util.Include("game/items/sh_item.lua")
	mono.util.Include("game/inventory/sh_inventory.lua")
else
	::skip::
end

mono.util.IncludeDir("kernel/meta")
mono.util.IncludeDir("kernel/utils")
mono.util.IncludeDir("kernel/utils/thirdparty")
mono.util.IncludeDir("kernel/modules")


mono.lang.LoadFromDir("mono/gamemode/kernel/cfg/languages")
// mono.util.Include("kernel/cfg/sh_commands.lua")

mono.NET:AddPlayerVar("holdingObject", true, nil, mono.NET.Type.Entity)
mono.NET:AddPlayerVar("bIsHoldingObject", true, nil, mono.NET.Type.Bool)
mono.NET:AddPlayerVar("restrictNoMsg", true, nil, mono.NET.Type.Bool)
mono.NET:AddPlayerVar("blur", true, nil, mono.NET.Type.Float)
mono.NET:AddPlayerVar("ragdoll", true, nil, mono.NET.Type.EntityIndex)
mono.NET:AddPlayerVar("deathStartTime", false, nil, mono.NET.Type.Float)
mono.NET:AddPlayerVar("deathTime", false, nil, mono.NET.Type.Float)
mono.NET:AddPlayerVar("forcedSequence", false, nil, mono.NET.Type.EntityIndex)
mono.NET:AddPlayerVar("canShoot", false, nil, mono.NET.Type.Bool)
mono.NET:AddPlayerVar("raised", false, nil, mono.NET.Type.Bool)
mono.NET:AddPlayerVar("restricted", false, nil, mono.NET.Type.Bool)
mono.NET:AddPlayerVar("char", false, nil, mono.NET.Type.CharacterID)

mono.NET:AddEntityVar("data", nil, mono.NET.Type.Table)
mono.NET:AddEntityVar("owner", nil, mono.NET.Type.CharacterID)
mono.NET:AddEntityVar("player", nil, mono.NET.Type.Entity)

function GM:Initialize()
	mono.setting.Load()
	mono.option.Load()
end

function GM:OnReloaded()
	mono.setting.Load()
	mono.option.Load()
end


if (SERVER and game.IsDedicated()) then
	concommand.Remove("gm_save")

	concommand.Add("gm_save", function(client, command, arguments) end)
	// concommand.Add("gmod_admin_cleanup", function(client, command, arguments) end)
end
