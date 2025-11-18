mono.data = mono.data or {}
mono.data.stored = mono.data.stored or {}

file.CreateDir("mono")

function mono.data.Set(key, value, bGlobal, bIgnoreMap)
	local path = "mono/" .. (bGlobal and "") .. (bIgnoreMap and "" or game.GetMap() .. "/")

	file.CreateDir(path)
	file.Write(path .. key .. ".txt", util.TableToJSON({value}))

	mono.data.stored[key] = value

	return path
end

function mono.data.Get(key, default, bGlobal, bIgnoreMap, bRefresh)
	if (!bRefresh) then
		local stored = mono.data.stored[key]

		if (stored != nil) then
			return stored
		end
	end

	local path = "mono/" .. (bGlobal and "") .. (bIgnoreMap and "" or game.GetMap() .. "/")
	local contents = file.Read(path .. key .. ".txt", "DATA")

	if (contents and contents != "") then
		local status, decoded = pcall(util.JSONToTable, contents)

		if (status and decoded) then
			local value = decoded[1]

			if (value != nil) then
				return value
			end
		end

		status, decoded = pcall(pon.decode, contents)

		if (status and decoded) then
			local value = decoded[1]

			if (value != nil) then
				return value
			end
		end
	end

	return default
end

function mono.data.Delete(key, bGlobal, bIgnoreMap)
	local path = "mono/" .. (bGlobal and "") .. (bIgnoreMap and "" or game.GetMap() .. "/")
	local contents = file.Read(path .. key .. ".txt", "DATA")

	if (contents and contents != "") then
		file.Delete(path .. key .. ".txt")
		mono.data.stored[key] = nil
		return true
	end

	return false
end

if (SERVER) then
	timer.Create("monoSaveData", 600, 0, function()
		hook.Run("SaveData")
	end)
end
