local playerMeta = FindMetaTable("Player")

do
	util.AddNetworkString("bData")
	util.AddNetworkString("bDataSync")

	function playerMeta:LoadData(callback)
		local name = self:SteamName()
		local steamID64 = self:SteamID64()
		local timestamp = math.floor(os.time())
		local ip = self:IPAddress():match("%d+%.%d+%.%d+%.%d+")

		local query = mysql:Select("b_players")
			query:Select("data")
			query:Select("play_time")
			query:Where("steamid", steamID64)
			query:Callback(function(result)
				if (IsValid(self) and istable(result) and #result > 0 and result[1].data) then
					local updateQuery = mysql:Update("b_players")
						updateQuery:Update("last_join_time", timestamp)
						updateQuery:Update("address", ip)
						updateQuery:Where("steamid", steamID64)
					updateQuery:Execute()

					self.bPlayTime = tonumber(result[1].play_time) or 0
					self.bData = util.JSONToTable(result[1].data)

					if (callback) then
						callback(self.bData)
					end
				else
					local insertQuery = mysql:Insert("b_players")
						insertQuery:Insert("steamid", steamID64)
						insertQuery:Insert("steam_name", name)
						insertQuery:Insert("play_time", 0)
						insertQuery:Insert("address", ip)
						insertQuery:Insert("last_join_time", timestamp)
						insertQuery:Insert("data", util.TableToJSON({}))
					insertQuery:Execute()

					if (callback) then
						callback({})
					end
				end
			end)
		query:Execute()
	end

	function playerMeta:SaveData()
		local name = self:SteamName()
		local steamID64 = self:SteamID64()

		local query = mysql:Update("b_players")
			query:Update("steam_name", name)
			query:Update("play_time", math.floor((self.bPlayTime or 0) + (RealTime() - (self.bJoinTime or RealTime() - 1))))
			query:Update("data", util.TableToJSON(self.bData))
			query:Where("steamid", steamID64)
		query:Execute()
	end

	function playerMeta:SetData(key, value, bNoNetworking)
		self.bData = self.bData or {}
		self.bData[key] = value

		if (!bNoNetworking) then
			net.Start("bData")
				net.WriteString(key)
				net.WriteType(value)
			net.Send(self)
		end
	end
end

do
	playerMeta.bGive = playerMeta.bGive or playerMeta.Give

	function playerMeta:Give(className, bNoAmmo)
		local weapon

		self.bWeaponGive = true
			weapon = self:bGive(className, bNoAmmo)
		self.bWeaponGive = nil

		return weapon
	end
end
