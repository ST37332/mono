mono.setting = mono.setting or {}
mono.setting.stored = mono.setting.stored or {}
mono.setting.categories = mono.setting.categories or {}

function mono.setting.Add(key, settingType, default, data)
	assert(isstring(key) and key:find("%S"), "expected a non-empty string for the key")

	data = data or {}

	local categories = mono.setting.categories
	local category = data.category or "misc"
	local upperName = key:sub(1, 1):upper() .. key:sub(2)

	categories[category] = categories[category] or {}
	categories[category][key] = true


	mono.setting.stored[key] = {
		key = key,
		phrase = "opt" .. upperName,
		description = "optd" .. upperName,
		type = settingType,
		default = default,
		min = data.min or 0,
		max = data.max or 10,
		decimals = data.decimals or 0,
		category = data.category or "misc",
		bNetworked = data.bNetworked and true or false,
		hidden = data.hidden or nil,
		populate = data.populate or nil,
		OnChanged = data.OnChanged or nil
	}
end


function mono.setting.Load()
	mono.util.Include("mono/gamemode/kernel/cfg/sh_settings.lua")

	if (CLIENT) then
		local settings = mono.data.Get("settings", nil, true, true)

		if (settings) then
			for k, v in pairs(settings) do
				mono.setting.client[k] = v
			end
		end

		mono.setting.Sync()
	end
end


function mono.setting.GetAll()
	return mono.setting.stored
end


function mono.setting.GetAllByCategories(bRemoveHidden)
	local result = {}

	for k, v in pairs(mono.setting.categories) do
		for k2, _ in pairs(v) do
			local setting = mono.setting.stored[k2]

			if (bRemoveHidden and isfunction(setting.hidden) and setting.hidden()) then
				continue
			end

			result[k] = result[k] or {}
			result[k][#result[k] + 1] = setting
		end
	end

	return result
end

if (CLIENT) then
	mono.setting.client = mono.setting.client or {}

	
	function mono.setting.Set(key, value, bNoSave)
		local setting = assert(mono.setting.stored[key], "invalid setting key \"" .. tostring(key) .. "\"")

		if (setting.type == mono.type.number) then
			value = math.Clamp(math.Round(value, setting.decimals), setting.min, setting.max)
		end

		local oldValue = mono.setting.client[key]
		mono.setting.client[key] = value

		if (setting.bNetworked) then
			net.Start("bSettingSet")
				net.WriteString(key)
				net.WriteType(value)
			net.SendToServer()
		end

		if (!bNoSave) then
			mono.setting.Save()
		end

		if (isfunction(setting.OnChanged)) then
			setting.OnChanged(oldValue, value)
		end
	end

	
	function mono.setting.Get(key, default)
		local setting = mono.setting.stored[key]

		if (setting) then
			local localValue = mono.setting.client[key]

			if (localValue != nil) then
				return localValue
			end

			return setting.default
		end

		return default
	end

	
	function mono.setting.Save()
		mono.data.Set("setting", mono.setting.client, true, true)
	end

	
	function mono.setting.Sync()
		local settings = {}

		for k, v in pairs(mono.setting.stored) do
			if (v.bNetworked) then
				settings[#settings + 1] = {k, mono.setting.client[k]}
			end
		end

		if (#settings > 0) then
			net.Start("bSettingSync")
			net.WriteUInt(#settings, 8)

			for _, v in ipairs(settings) do
				net.WriteString(v[1])
				net.WriteType(v[2])
			end

			net.SendToServer()
		end
	end
else
	util.AddNetworkString("bSettingSet")
	util.AddNetworkString("bSettingSync")

	mono.setting.clients = mono.setting.clients or {}

	
	function mono.setting.Get(client, key, default)
		assert(IsValid(client) and client:IsPlayer(), "expected valid player for argument #1")

		local setting = mono.setting.stored[key]

		if (setting) then
			local clientSettings = mono.setting.clients[client:SteamID64()]

			if (clientSettings) then
				local clientSetting = clientSettings[key]

				if (clientSetting != nil) then
					return clientSetting
				end
			end

			return setting.default
		end

		return default
	end

	
	net.Receive("bSettingSet", function(length, client)
		local key = net.ReadString()
		local value = net.ReadType()

		local steamID = client:SteamID64()
		local setting = mono.setting.stored[key]

		if (setting) then
			mono.setting.clients[steamID] = mono.setting.clients[steamID] or {}
			mono.setting.clients[steamID][key] = value
		else
			ErrorNoHalt(string.format(
				"'%s' attempted to set setting with invalid key '%s'\n", tostring(client) .. client:SteamID(), key
			))
		end
	end)

	
	net.Receive("bSettingSync", function(length, client)
		local indices = net.ReadUInt(8)
		local data = {}

		for _ = 1, indices do
			data[net.ReadString()] = net.ReadType()
		end

		local steamID = client:SteamID64()
		mono.setting.clients[steamID] = mono.setting.clients[steamID] or {}

		for k, v in pairs(data) do
			local setting = mono.setting.stored[k]

			if (setting) then
				mono.setting.clients[steamID][k] = v
			else
				return ErrorNoHalt(string.format(
					"'%s' attempted to sync setting with invalid key '%s'\n", tostring(client) .. client:SteamID(), k
				))
			end
		end
	end)
end
