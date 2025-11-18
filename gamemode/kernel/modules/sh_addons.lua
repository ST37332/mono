mono.addon = mono.addon or {}
mono.addon.list = mono.addon.list or {}
mono.addon.unloaded = mono.addon.unloaded or {}

mono.util.Include("mono/gamemode/kornel/meta/sh_tool.lua")

HOOKS_CACHE = {}

function mono.addon.Load(uniqueID, path, isSingleFile, variable)
	if (hook.Run("AddonShouldLoad", uniqueID) == false) then return end

	variable = variable or "ADDON"

	local oldAddon = ADDON
	local ADDON = {
		folder = path,
		addon = oldAddon,
		uniqueID = uniqueID,
		name = "Unknown",
		description = "Description not available",
		author = "Anonymous"
	}

	if (mono.addon.list[uniqueID]) then
		ADDON = mono.addon.list[uniqueID]
	end

	_G[variable] = ADDON
	ADDON.loading = true

	if (!isSingleFile) then
		mono.util.IncludeDir(path.."/utils", true)
		mono.addon.LoadFromDir(path.."/addons")
		mono.addon.LoadEntities(path.."/entities")

		hook.Run("DoAddonIncludes", path, ADDON)
	end

	mono.util.Include(isSingleFile and path or path.."/sh_"..variable:lower()..".lua", "shared")
	ADDON.loading = false

	local uniqueID2 = uniqueID

	function ADDON:SetData(value, global, ignoreMap)
		mono.data.Set(uniqueID2, value, global, ignoreMap)
	end

	function ADDON:GetData(default, global, ignoreMap, refresh)
		return mono.data.Get(uniqueID2, default, global, ignoreMap, refresh) or {}
	end

	hook.Run("AddonLoaded", uniqueID, ADDON)

	if (ADDON.OnLoaded) then
		ADDON:OnLoaded()
	end
end

function mono.addon.GetHook(addonName, hookName)
	local h = HOOKS_CACHE[hookName]

	if (h) then
		local p = mono.addon.list[addonName]

		if (p) then
			return h[p]
		end
	end

	return
end

function mono.addon.LoadEntities(path)
	local bLoadedTools
	local files, folders

	local function IncludeFiles(path2, bClientOnly)
		if (SERVER and !bClientOnly) then
			if (file.Exists(path2.."init.lua", "LUA")) then
				mono.util.Include(path2.."init.lua", "server")
			elseif (file.Exists(path2.."shared.lua", "LUA")) then
				mono.util.Include(path2.."shared.lua")
			end

			if (file.Exists(path2.."cl_init.lua", "LUA")) then
				mono.util.Include(path2.."cl_init.lua", "client")
			end
		elseif (file.Exists(path2.."cl_init.lua", "LUA")) then
			mono.util.Include(path2.."cl_init.lua", "client")
		elseif (file.Exists(path2.."shared.lua", "LUA")) then
			mono.util.Include(path2.."shared.lua")
		end
	end

	local function HandleEntityInclusion(folder, variable, register, default, clientOnly, create, complete)
		files, folders = file.Find(path.."/"..folder.."/*", "LUA")
		default = default or {}

		for _, v in ipairs(folders) do
			local path2 = path.."/"..folder.."/"..v.."/"
			v = mono.util.StripRealmPrefix(v)

			_G[variable] = table.Copy(default)

			if (!isfunction(create)) then
				_G[variable].ClassName = v
			else
				create(v)
			end

			IncludeFiles(path2, clientOnly)

			if (clientOnly) then
				if (CLIENT) then
					register(_G[variable], v)
				end
			else
				register(_G[variable], v)
			end

			if (isfunction(complete)) then
				complete(_G[variable])
			end

			_G[variable] = nil
		end

		for _, v in ipairs(files) do
			local niceName = mono.util.StripRealmPrefix(string.StripExtension(v))

			_G[variable] = table.Copy(default)

			if (!isfunction(create)) then
				_G[variable].ClassName = niceName
			else
				create(niceName)
			end

			mono.util.Include(path.."/"..folder.."/"..v, clientOnly and "client" or "shared")

			if (clientOnly) then
				if (CLIENT) then
					register(_G[variable], niceName)
				end
			else
				register(_G[variable], niceName)
			end

			if (isfunction(complete)) then
				complete(_G[variable])
			end

			_G[variable] = nil
		end
	end

	local function RegisterTool(tool, className)
		local gmodTool = weapons.GetStored("gmod_tool")

		if (className:sub(1, 3) == "sh_") then
			className = className:sub(4)
		end

		if (gmodTool) then
			gmodTool.Tool[className] = tool
		else
			ErrorNoHalt(string.format("attempted to register tool '%s' with invalid gmod_tool weapon", className))
		end

		bLoadedTools = true
	end

	HandleEntityInclusion("entities", "ENT", scripted_ents.Register, {
		Type = "anim",
		Base = "base_gmodentity",
		Spawnable = true
	}, false, nil, function(ent)
		if (SERVER and ent.Holdable == true) then
			mono.allowedHoldableClasses[ent.ClassName] = true
		end
	end)

	HandleEntityInclusion("weapons", "SWEP", weapons.Register, {
		Primary = {},
		Secondary = {},
		Base = "weapon_base"
	})

	HandleEntityInclusion("tools", "TOOL", RegisterTool, {}, false, function(className)
		if (className:sub(1, 3) == "sh_") then
			className = className:sub(4)
		end

		TOOL = mono.meta.tool:Create()
		TOOL.Mode = className
		TOOL:CreateConVars()
	end)

	HandleEntityInclusion("effects", "EFFECT", effects and effects.Register, nil, true)

	if (CLIENT and bLoadedTools) then
		RunConsoleCommand("spawnmenu_reload")
	end
end

function mono.addon.Initialize()
	mono.addon.unloaded = mono.data.Get("unloaded", {}, true, true)

	mono.addon.LoadFromDir("mono/addons")

	//mono.addon.Load("schema", engine.ActiveGamemode().."/schema")
	//hook.Run("InitializedSchema")

	//mono.addon.LoadFromDir(engine.ActiveGamemode().."/addons")
	//hook.Run("InitializedAddons")
end

function mono.addon.Get(identifier)
	return mono.addon.list[identifier]
end

function mono.addon.LoadFromDir(directory)
	local files, folders = file.Find(directory.."/*", "LUA")

	for _, v in ipairs(folders) do
		mono.addon.Load(v, directory.."/"..v)
	end

	for _, v in ipairs(files) do
		mono.addon.Load(string.StripExtension(v), directory.."/"..v, true)
	end
end

function mono.addon.SetUnloaded(uniqueID, state, bNoSave)
	local addon = mono.addon.list[uniqueID]

	if (state) then
		if (addon and addon.OnUnload) then
			addon:OnUnload()
		end

		mono.addon.unloaded[uniqueID] = true
	elseif (mono.addon.unloaded[uniqueID]) then
		mono.addon.unloaded[uniqueID] = nil
	else
		return false
	end

	if (SERVER and !bNoSave) then
		local status

		if (state) then
			status = true
		end

		local unloaded = mono.data.Get("unloaded", {}, true, true)
			unloaded[uniqueID] = status
		mono.data.Set("unloaded", unloaded, true, true)
	end

	if (state) then
		hook.Run("AddonUnloaded", uniqueID)
	end

	return true
end

if (SERVER) then
	function mono.addon.RunLoadData()
		local errors = hook.SafeRun("LoadData")

		for _, v in pairs(errors or {}) do
			if (v.addon) then
				local addon = mono.addon.Get(v.addon)

				if (addon) then
					local saveDataHooks = HOOKS_CACHE["SaveData"] or {}
					saveDataHooks[addon] = nil

					local postLoadDataHooks = HOOKS_CACHE["PostLoadData"] or {}
					postLoadDataHooks[addon] = nil
				end
			end
		end

		hook.Run("PostLoadData")
	end
end

do
	hook.bCall = hook.bCall or hook.Call

	function hook.Call(name, gm, ...)
		local cache = HOOKS_CACHE[name]

		if (cache) then
			for k, v in pairs(cache) do
				local a, b, c, d, e, f = v(k, ...)

				if (a != nil) then
					return a, b, c, d, e, f
				end
			end
		end

		return hook.bCall(name, gm, ...)
	end

    
	function hook.SafeRun(name, ...)
		local errors = {}
		local gm = gmod and gmod.GetGamemode() or nil
		local cache = HOOKS_CACHE[name]

		if (cache) then
			for k, v in pairs(cache) do
				local bSuccess, a, b, c, d, e, f = pcall(v, k, ...)

				if (bSuccess) then
					if (a != nil) then
						return errors, a, b, c, d, e, f
					end
				else
					ErrorNoHalt(string.format("[Mono] hook.SafeRun error for addon hook \"%s:%s\":\n\t%s\n%s\n",
						tostring(k and k.uniqueID or nil), tostring(name), tostring(a), debug.traceback()))

					errors[#errors + 1] = {
						name = name,
						addon = k and k.uniqueID or nil,
						errorMessage = tostring(a)
					}
				end
			end
		end

		local bSuccess, a, b, c, d, e, f = pcall(hook.bCall, name, gm, ...)

		if (bSuccess) then
			return errors, a, b, c, d, e, f
		else
			ErrorNoHalt(string.format("[Mono] hook.SafeRun error for gamemode hook \"%s\":\n\t%s\n%s\n",
				tostring(name), tostring(a), debug.traceback()))

			errors[#errors + 1] = {
				name = name,
				gamemode = "gamemode",
				errorMessage = tostring(a)
			}

			return errors
		end
	end
end
