ix.addon = ix.addon or {}
ix.addon.list = ix.addon.list or {}
ix.addon.unloaded = ix.addon.unloaded or {}

ix.util.Include("mono/gamemode/kornel/meta/sh_tool.lua")

HOOKS_CACHE = {}

function ix.addon.Load(uniqueID, path, isSingleFile, variable)
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

	if (ix.addon.list[uniqueID]) then
		ADDON = ix.addon.list[uniqueID]
	end

	_G[variable] = ADDON
	ADDON.loading = true

	if (!isSingleFile) then
		ix.lang.LoadFromDir(path.."/languages")
		ix.util.IncludeDir(path.."/libs", true)
		ix.attributes.LoadFromDir(path.."/attributes")
		ix.faction.LoadFromDir(path.."/factions")
		ix.class.LoadFromDir(path.."/classes")
		ix.item.LoadFromDir(path.."/items")
		ix.addon.LoadFromDir(path.."/addons")
		ix.util.IncludeDir(path.."/derma", true)
		ix.addon.LoadEntities(path.."/entities")

		hook.Run("DoAddonIncludes", path, ADDON)
	end

	ix.util.Include(isSingleFile and path or path.."/sh_"..variable:lower()..".lua", "shared")
	ADDON.loading = false

	local uniqueID2 = uniqueID

	function ADDON:SetData(value, global, ignoreMap)
		ix.data.Set(uniqueID2, value, global, ignoreMap)
	end

	function ADDON:GetData(default, global, ignoreMap, refresh)
		return ix.data.Get(uniqueID2, default, global, ignoreMap, refresh) or {}
	end

	hook.Run("AddonLoaded", uniqueID, ADDON)

	if (ADDON.OnLoaded) then
		ADDON:OnLoaded()
	end
end

function ix.addon.GetHook(addonName, hookName)
	local h = HOOKS_CACHE[hookName]

	if (h) then
		local p = ix.addon.list[addonName]

		if (p) then
			return h[p]
		end
	end

	return
end

function ix.addon.LoadEntities(path)
	local bLoadedTools
	local files, folders

	local function IncludeFiles(path2, bClientOnly)
		if (SERVER and !bClientOnly) then
			if (file.Exists(path2.."init.lua", "LUA")) then
				ix.util.Include(path2.."init.lua", "server")
			elseif (file.Exists(path2.."shared.lua", "LUA")) then
				ix.util.Include(path2.."shared.lua")
			end

			if (file.Exists(path2.."cl_init.lua", "LUA")) then
				ix.util.Include(path2.."cl_init.lua", "client")
			end
		elseif (file.Exists(path2.."cl_init.lua", "LUA")) then
			ix.util.Include(path2.."cl_init.lua", "client")
		elseif (file.Exists(path2.."shared.lua", "LUA")) then
			ix.util.Include(path2.."shared.lua")
		end
	end

	local function HandleEntityInclusion(folder, variable, register, default, clientOnly, create, complete)
		files, folders = file.Find(path.."/"..folder.."/*", "LUA")
		default = default or {}

		for _, v in ipairs(folders) do
			local path2 = path.."/"..folder.."/"..v.."/"
			v = ix.util.StripRealmPrefix(v)

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
			local niceName = ix.util.StripRealmPrefix(string.StripExtension(v))

			_G[variable] = table.Copy(default)

			if (!isfunction(create)) then
				_G[variable].ClassName = niceName
			else
				create(niceName)
			end

			ix.util.Include(path.."/"..folder.."/"..v, clientOnly and "client" or "shared")

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
			ix.allowedHoldableClasses[ent.ClassName] = true
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

		TOOL = ix.meta.tool:Create()
		TOOL.Mode = className
		TOOL:CreateConVars()
	end)

	HandleEntityInclusion("effects", "EFFECT", effects and effects.Register, nil, true)

	if (CLIENT and bLoadedTools) then
		RunConsoleCommand("spawnmenu_reload")
	end
end

function ix.addon.Initialize()
	ix.addon.unloaded = ix.data.Get("unloaded", {}, true, true)

	ix.addon.LoadFromDir("mono/addons")

	//ix.addon.Load("schema", engine.ActiveGamemode().."/schema")
	//hook.Run("InitializedSchema")

	//ix.addon.LoadFromDir(engine.ActiveGamemode().."/addons")
	//hook.Run("InitializedAddons")
end

function ix.addon.Get(identifier)
	return ix.addon.list[identifier]
end

function ix.addon.LoadFromDir(directory)
	local files, folders = file.Find(directory.."/*", "LUA")

	for _, v in ipairs(folders) do
		ix.addon.Load(v, directory.."/"..v)
	end

	for _, v in ipairs(files) do
		ix.addon.Load(string.StripExtension(v), directory.."/"..v, true)
	end
end

function ix.addon.SetUnloaded(uniqueID, state, bNoSave)
	local addon = ix.addon.list[uniqueID]

	if (state) then
		if (addon and addon.OnUnload) then
			addon:OnUnload()
		end

		ix.addon.unloaded[uniqueID] = true
	elseif (ix.addon.unloaded[uniqueID]) then
		ix.addon.unloaded[uniqueID] = nil
	else
		return false
	end

	if (SERVER and !bNoSave) then
		local status

		if (state) then
			status = true
		end

		local unloaded = ix.data.Get("unloaded", {}, true, true)
			unloaded[uniqueID] = status
		ix.data.Set("unloaded", unloaded, true, true)
	end

	if (state) then
		hook.Run("AddonUnloaded", uniqueID)
	end

	return true
end

if (SERVER) then
	function ix.addon.RunLoadData()
		local errors = hook.SafeRun("LoadData")

		for _, v in pairs(errors or {}) do
			if (v.addon) then
				local addon = ix.addon.Get(v.addon)

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
	hook.ixCall = hook.ixCall or hook.Call

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

		return hook.ixCall(name, gm, ...)
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

		local bSuccess, a, b, c, d, e, f = pcall(hook.ixCall, name, gm, ...)

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
