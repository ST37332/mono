FLAG_NORMAL = 0
FLAG_SUCCESS = 1
FLAG_WARNING = 2
FLAG_DANGER = 3
FLAG_SERVER = 4
FLAG_DEV = 5

mono.log = mono.log or {}
mono.log.color = {
	[FLAG_NORMAL] = Color(200, 200, 200),
	[FLAG_SUCCESS] = Color(50, 200, 50),
	[FLAG_WARNING] = Color(255, 255, 0),
	[FLAG_DANGER] = Color(255, 50, 50),
	[FLAG_SERVER] = Color(200, 200, 220),
	[FLAG_DEV] = Color(200, 200, 220),
}

CAMI.RegisterPrivilege({
	Name = "Mono - Logs",
	MinAccess = "admin"
})

local consoleColor = Color(50, 200, 50)

if (SERVER) then
	if (!mono.db) then
		include("sv_database.lua")
	end

	util.AddNetworkString("monoLogsStream")

	function mono.log.LoadTables()
		mono.log.CallHandler("Load")
	end

	mono.log.types = mono.log.types or {}

	function mono.log.AddType(logType, format, flag)
		mono.log.types[logType] = {format = format, flag = flag}
	end

	function mono.log.Parse(client, logType, ...)
		local info = mono.log.types[logType]

		if (!info) then
			ErrorNoHalt("attempted to add entry to non-existent log type \"" .. tostring(logType) .. "\"")
			return
		end

		local text = info and info.format

		if (text) then
			if (isfunction(text)) then
				text = text(client, ...)
			end
		else
			text = -1
		end

		return text, info.flag
	end

	function mono.log.AddRaw(logString, bNoSave)
		CAMI.GetPlayersWithAccess("Mono - Logs", function(receivers)
			mono.log.Send(receivers, logString)
		end)

		Msg("[LOG] ", logString .. "\n")

		if (!bNoSave) then
			mono.log.CallHandler("Write", nil, logString)
		end
	end

	function mono.log.Add(client, logType, ...)
		local logString, logFlag = mono.log.Parse(client, logType, ...)
		if (logString == -1) then return end

		CAMI.GetPlayersWithAccess("Mono - Logs", function(receivers)
			mono.log.Send(receivers, logString, logFlag)
		end)

		Msg("[LOG] ", logString .. "\n")

		mono.log.CallHandler("Write", client, logString, logFlag)
	end

	function mono.log.Send(client, logString, flag)
		net.Start("monoLogsStream")
			net.WriteString(logString)
			net.WriteUInt(flag or 0, 4)
		net.Send(client)
	end

	mono.log.handlers = mono.log.handlers or {}
	function mono.log.CallHandler(event, ...)
		for _, v in pairs(mono.log.handlers) do
			if (isfunction(v[event])) then
				v[event](...)
			end
		end
	end

	function mono.log.RegisterHandler(name, data)
		data.name = string.gsub(name, "%s", "")
			name = name:lower()
		data.uniqueID = name

		mono.log.handlers[name] = data
	end

	do
		local HANDLER = {}

		function HANDLER.Load()
			file.CreateDir("mono/logs")
		end

		function HANDLER.Write(client, message)
			file.Append("mono/logs/" .. os.date("%x"):gsub("/", "-") .. ".txt", "[" .. os.date("%X") .. "]\t" .. message .. "\r\n")
		end

		mono.log.RegisterHandler("File", HANDLER)
	end
else
	net.Receive("monoLogsStream", function(length)
		local logString = net.ReadString()
		local flag = net.ReadUInt(4)

		if (isstring(logString) and isnumber(flag)) then
			MsgC(consoleColor, "[SERVER] ", mono.log.color[flag], logString .. "\n")
		end
	end)
end
