local playerMeta = FindMetaTable("Player")

do
	if (SERVER) then
		function playerMeta:GetData(key, default)
			if (key == true) then
				return self.bData
			end

			local data = self.bData and self.bData[key]

			if (data == nil) then
				return default
			else
				return data
			end
		end
	else
		function playerMeta:GetData(key, default)
			local data = mono.localData and mono.localData[key]

			if (data == nil) then
				return default
			else
				return data
			end
		end

		net.Receive("bDataSync", function()
			mono.localData = net.ReadTable()
			mono.playTime = net.ReadUInt(32)
		end)

		net.Receive("bData", function()
			mono.localData = mono.localData or {}
			mono.localData[net.ReadString()] = net.ReadType()
		end)
	end
end