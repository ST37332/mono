local meta = FindMetaTable("Entity")
local CHAIR_CACHE = {}

for _, v in pairs(list.Get("Vehicles")) do
	if (v.Category == "#spawnmenu.category.chairs") then
		CHAIR_CACHE[v.Model] = true
	end
end

function meta:IsChair()
	return CHAIR_CACHE[self:GetModel()]
end

function meta:IsDoor()
	local class = self:GetClass()

	return (class and class:find("door") != nil)
end

if (SERVER) then
	function meta:IsLocked()
		if (self:IsVehicle()) then
			local datatable = self:GetSaveTable()

			if (datatable) then
				return datatable.VehicleLocked
			end
		else
			local datatable = self:GetSaveTable()

			if (datatable) then
				return datatable.m_bLocked
			end
		end

		return false
	end

	function meta:GetBlocker()
		local datatable = self:GetSaveTable()

		return datatable.pBlocker
	end
end
