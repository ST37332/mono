
if (!system.IsWindows()) then
	local fontOverrides = {
		["Roboto"] = "Roboto Regular",
		["Roboto Th"] = "Roboto Thin",
		["Roboto Lt"] = "Roboto Light",
		["Roboto Bk"] = "Roboto Black",
		["coolvetica"] = "Coolvetica",
		["tahoma"] = "Tahoma",
		["Harmonia Sans Pro Cyr"] = "Roboto Regular",
		["Harmonia Sans Pro Cyr Light"] = "Roboto Light",
		["Century Gothic"] = "Roboto Regular"
	}

	if (system.IsOSX()) then
		fontOverrides["Consolas"] = "Monaco"
	else
		fontOverrides["Consolas"] = "Courier New"
	end

	local CreateFont = surface.CreateFont

	function surface.CreateFont(name, info)
		local font = info.font

		if (font and fontOverrides[font]) then
			info.font = fontOverrides[font]
		end

		CreateFont(name, info)
	end
end

DeriveGamemode("sandbox")
mono = mono or {
	gui = {}, 
	meta = {}, 
	util = {}
}

include("core/sh_util.lua")
include("core/sh_data.lua")
include("shared.lua")

CreateConVar("cl_weaponcolor", "0.30 1.80 2.10", {
	FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD
}, "The value is a Vector - so between 0-1 - not between 0-255")

timer.Remove("HintSystem_OpeningMenu")
timer.Remove("HintSystem_Annoy1")
timer.Remove("HintSystem_Annoy2")
