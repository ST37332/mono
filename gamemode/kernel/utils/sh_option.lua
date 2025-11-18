mono.option = mono.option or {}
mono.option.stored = mono.option.stored or {}


if (SERVER) then
	util.AddNetworkString("bOptionList")
	util.AddNetworkString("bOptionSet")
	util.AddNetworkString("bOptionRequestUnloadedList")
	util.AddNetworkString("bOptionUnloadedList")
	util.AddNetworkString("bOptionPluginToggle")

	mono.option.server = ix.yaml.Read("gamemodes/mono/mono.yml") or {}
end


CAMI.RegisterPrivilege({
	Name = "Mono - Manage Option",
	MinAccess = "superadmin"
})


function mono.option.Add(key, value, description, callback, data, bNoNetworking)
	data = istable(data) and data or {}

	local oldOption = mono.option.stored[key]
	local type = data.type or mono.util.GetTypeFromValue(value)

	if (!type) then
		ErrorNoHalt("attempted to add option with invalid type\n")
		return
	end

	local default = value
	data.type = nil

	if (oldOption != nil) then
		if (oldOption.value != nil) then
			value = oldOption.value
		end

		if (oldOption.default != nil) then
			default = oldOption.default
		end
	end

	mono.option.stored[key] = {
		type = type,
		data = data,
		value = value,
		default = default,
		description = description,
		bNoNetworking = bNoNetworking,
		callback = callback,
		hidden = data.hidden or nil
	}
end


function mono.option.SetDefault(key, value)
	local option = mono.option.stored[key]

	if (option) then
		option.default = value
	else
		mono.option.stored[key] = {
			value = value,
			default = value
		}
	end
end


function mono.option.ForceSet(key, value, noSave)
	local option = mono.option.stored[key]

	if (option) then
		option.value = value
	end

	if (noSave) then
		mono.option.Save()
	end
end


function mono.option.Set(key, value)
	local option = mono.option.stored[key]

	if (option) then
		local oldValue = value
		option.value = value

		if (SERVER) then
			if (!option.bNoNetworking) then
				net.Start("bOptionSet")
					net.WriteString(key)
					net.WriteType(value)
				net.Broadcast()
			end

			if (option.callback) then
				option.callback(oldValue, value)
			end

			mono.option.Save()
		end
	end
end


function mono.option.Get(key, default)
	local option = mono.option.stored[key]

	
	if (option and option.type) then
		if (option.value != nil) then
			return option.value
		elseif (option.default != nil) then
			return option.default
		end
	end

	return default
end


function mono.option.Load()
	if (SERVER) then
		local globals = mono.data.Get("option", nil, true, true)
		local data = mono.data.Get("option", nil, false, true)

		if (globals) then
			for k, v in pairs(globals) do
				mono.option.stored[k] = mono.option.stored[k] or {}
				mono.option.stored[k].value = v
			end
		end

		if (data) then
			for k, v in pairs(data) do
				mono.option.stored[k] = mono.option.stored[k] or {}
				mono.option.stored[k].value = v
			end
		end
	end

	mono.util.Include("mono/gamemode/kernel/cfg/sh_option.lua")

	if (SERVER) then
		hook.Run("InitializedOption")
	end
end

if (SERVER) then
	function mono.option.GetChangedValues()
		local data = {}

		for k, v in pairs(mono.option.stored) do
			if (v.default != v.value) then
				data[k] = v.value
			end
		end

		return data
	end

	function mono.option.Send(client)
		net.Start("bOptionList")
			net.WriteTable(mono.option.GetChangedValues())
		net.Send(client)
	end

	
	function mono.option.Save()
		local globals = {}
		local data = {}

		for k, v in pairs(mono.option.GetChangedValues()) do
			if (mono.option.stored[k].global) then
				globals[k] = v
			else
				data[k] = v
			end
		end

		
		mono.data.Set("option", globals, true, true)
		mono.data.Set("option", data, false, true)
	end

	net.Receive("bOptionSet", function(length, client)
		local key = net.ReadString()
		local value = net.ReadType()

		if (CAMI.PlayerHasAccess(client, "Mono - Manage Option", nil) and
			type(mono.option.stored[key].default) == type(value)) then
			mono.option.Set(key, value)

			if (mono.util.IsColor(value)) then
				value = string.format("[%d, %d, %d]", value.r, value.g, value.b)
			elseif (istable(value)) then
				local value2 = "["
				local count = table.Count(value)
				local i = 1

				for _, v in SortedPairs(value) do
					value2 = value2 .. v .. (i == count and "]" or ", ")
					i = i + 1
				end

				value = value2
			elseif (isstring(value)) then
				value = string.format("\"%s\"", tostring(value))
			elseif (isbool(value)) then
				value = string.format("[%s]", tostring(value))
			end

			mono.util.NotifyLocalized("cfgSet", nil, client:Name(), key, tostring(value))
			mono.log.Add(client, "cfgSet", key, value)
		end
	end)

	net.Receive("bOptionRequestUnloadedList", function(length, client)
		if (!CAMI.PlayerHasAccess(client, "Mono - Manage Option", nil)) then
			return
		end

		net.Start("bOptionUnloadedList")
			net.WriteTable(ix.plugin.unloaded)
		net.Send(client)
	end)

	net.Receive("bOptionPluginToggle", function(length, client)
		if (!CAMI.PlayerHasAccess(client, "Mono - Manage Option", nil)) then
			return
		end

		local uniqueID = net.ReadString()
		local bUnloaded = !!ix.plugin.unloaded[uniqueID]
		local bShouldEnable = net.ReadBool()

		if ((bShouldEnable and bUnloaded) or (!bShouldEnable and !bUnloaded)) then
			ix.plugin.SetUnloaded(uniqueID, !bShouldEnable)

			mono.util.NotifyLocalized(bShouldEnable and "pluginLoaded" or "pluginUnloaded", nil, client:GetName(), uniqueID)
			mono.log.Add(client, bShouldEnable and "pluginLoaded" or "pluginUnloaded", uniqueID)

			net.Start("bOptionPluginToggle")
				net.WriteString(uniqueID)
				net.WriteBool(bShouldEnable)
			net.Broadcast()
		end
	end)
else
	net.Receive("bOptionList", function()
		local data = net.ReadTable()

		for k, v in pairs(data) do
			if (mono.option.stored[k]) then
				mono.option.stored[k].value = v
			end
		end

		hook.Run("InitializedOption", data)
	end)

	net.Receive("bOptionSet", function()
		local key = net.ReadString()
		local value = net.ReadType()
		local option = mono.option.stored[key]

		if (option) then
			if (option.callback) then
				option.callback(option.value, value)
			end

			option.value = value

			local properties = ix.gui.properties

			if (IsValid(properties)) then
				local row = properties:GetCategory(L(option.data and option.data.category or "misc")):GetRow(key)

				if (IsValid(row)) then
					if (istable(value) and value.r and value.g and value.b) then
						value = Vector(value.r / 255, value.g / 255, value.b / 255)
					end

					row:SetValue(value)
				end
			end
		end
	end)

	net.Receive("bOptionUnloadedList", function()
		ix.plugin.unloaded = net.ReadTable()
		ix.gui.bReceivedUnloadedPlugins = true

		if (IsValid(ix.gui.pluginManager)) then
			ix.gui.pluginManager:UpdateUnloaded()
		end
	end)

	net.Receive("bOptionPluginToggle", function()
		local uniqueID = net.ReadString()
		local bEnabled = net.ReadBool()

		if (bEnabled) then
			ix.plugin.unloaded[uniqueID] = nil
		else
			ix.plugin.unloaded[uniqueID] = true
		end

		if (IsValid(ix.gui.pluginManager)) then
			ix.gui.pluginManager:UpdatePlugin(uniqueID, bEnabled)
		end
	end)

	hook.Add("CreateMenuButtons", "bOption", function(tabs)
		if (!CAMI.PlayerHasAccess(LocalPlayer(), "Mono - Manage Option", nil)) then
			return
		end

		tabs["option"] = {
			Create = function(info, container)
				container.panel = container:Add("bOptionManager")
			end,

			OnSelected = function(info, container)
				container.panel.searchEntry:RequestFocus()
			end,

			Sections = {
				plugins = {
					Create = function(info, container)
						ix.gui.pluginManager = container:Add("bPluginManager")
					end,

					OnSelected = function(info, container)
						ix.gui.pluginManager.searchEntry:RequestFocus()
					end
				}
			}
		}
	end)
end
