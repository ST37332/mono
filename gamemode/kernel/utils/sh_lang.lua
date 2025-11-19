mono.lang = mono or {}
mono.stored = mono.stored or {}
mono.names = mono.names or {}

function mono.LoadFromDir(directory)
	for _, v in ipairs(file.Find(directory.."/sh_*.lua", "LUA")) do
		local niceName = v:sub(4, -5):lower()

		mono.util.Include(directory.."/"..v, "shared")

		if (LANGUAGE) then
			if (NAME) then
				mono.names[niceName] = NAME
				NAME = nil
			end

			mono.AddTable(niceName, LANGUAGE)
			LANGUAGE = nil
		end
	end
end

function mono.AddTable(language, data)
	language = tostring(language):lower()
	mono.stored[language] = table.Merge(mono.stored[language] or {}, data)
end

if (SERVER) then
	function L(key, client, ...)
		local languages = mono.stored
		local langKey = mono.setting.Get(client, "language", "russian")
		local info = languages[langKey] or languages.russian

		return string.format(info and info[key] or languages.russian[key] or key, ...)
	end

	function L2(key, client, ...)
		local languages = mono.stored
		local langKey = mono.setting.Get(client, "language", "russian")
		local info = languages[langKey] or languages.russian

		if (info and info[key]) then
			return string.format(info[key], ...)
		end
	end
else
	function L(key, ...)
		local languages = mono.stored
		local langKey = mono.setting.Get("language", "russian")
		local info = languages[langKey] or languages.russian

		return string.format(info and info[key] or languages.russian[key] or key, ...)
	end

	function L2(key, ...)
		local langKey = mono.setting.Get("language", "russian")
		local info = mono.stored[langKey]

		if (info and info[key]) then
			return string.format(info[key], ...)
		end
	end
end
