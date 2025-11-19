local ITEM = class "Item"

local ITEM_DROP_ACTION = {
	OnRun = function(item, items)
		ix.Item:DropItem(item.player, item.id)
		
		item.player:EmitSound('npc/zombie/foot_slide' .. math.random(1, 3) .. '.wav', 75, math.random(90, 120), 1)

		return false
	end,
	OnCanRun = function(item)
		return !IsValid(item:GetEntity())
	end
}

local ITEM_TAKE_ACTION = {
	OnRun = function(item)
		local inventory = item.player:GetInventory('main')
		local canTake, reason = hook.Run('CanPlayerTakeItem', item.player, item)

		if canTake == false then 
			item.player:NotifyLocalized(reason or 'unknownError')
			return false
		end

		local bSuccess, error = inventory:AddItem(item)

		if !bSuccess then
			local backpack = item.player:GetBackpack()

			if backpack then
				inventory = backpack:GetInventory()
				
				bSuccess, error = inventory:AddItem(item)
			end
		end
		
		if bSuccess then
			item.entity:Delete()
			item.player:EmitSound('npc/zombie/foot_slide' .. math.random(1, 3) .. '.wav', 75, math.random(90, 120), 1)

			inventory:Sync()
		else
			item.player:NotifyLocalized(error or 'unknownError')
		end

		return bSuccess
	end,
	OnCanRun = function(item)
		return IsValid(item:GetEntity())
	end
}

function ITEM:Init(uniqueID)
	self.uniqueID = uniqueID or "undefined"
	self.id = self.id or 0
	self.data = self.data or {}

	self.vars = self.vars or {}
	self.var_max = self.var_max or 0
	self.var_max_bits = self.var_max_bits or 0
	self.vars_id = self.vars_id or {}

	self.closelook_sync = self.closelook_sync or {}

	self.bases = self.bases or {}
	self.base_count = 0

	self.name = self.name or "Undefined"
	self.description = self.description or "An item that is undefined."
	self.category = self.category or "Other"
	
	self.weight = self.weight or 1
	self.width = self.width or 1
	self.height = self.height or 1
	self.stackable = self.stackable or false
	self.max_stack = self.max_stack or 1
	self.cost = self.cost or 0
	self.rarity = self.rarity or 0

	self.rotated = self.rotated or false
	self.x = self.x or 0
	self.y = self.y or 0

	self.functions = self.functions or {}
	self.functions.drop = self.functions.drop or {
		tip = "dropTip",
		icon = "icon16/world.png",
		OnRun = ITEM_DROP_ACTION.OnRun,
		OnCanRun = ITEM_DROP_ACTION.OnCanRun
	}

	self.functions.take = self.functions.take or {
		tip = "takeTip",
		icon = "icon16/box.png",
		OnRun = ITEM_TAKE_ACTION.OnRun,
		OnCanRun = ITEM_TAKE_ACTION.OnCanRun
	}

	self.mark_as_save = false
end

function ITEM:__tostring() return "item["..self.uniqueID.."]["..self.id.."]" end
function ITEM:__eq(other) return self:GetID() == other:GetID() end

function ITEM:GetID() return self.id end
function ITEM:GetPrintName() return CLIENT and L(self.name or 'unknown') or self.name end
function ITEM:GetName() return self.name end
function ITEM:GetDescription() return CLIENT and L(self.description or 'noDesc') or self.description end

function ITEM:GetIconModel() return self.icon_model end
function ITEM:GetModel() return self.model end
function ITEM:GetSkin() return self.skin or 0 end
function ITEM:GetMaterial() return nil end
function ITEM:GetWeight() return self.weight end
function ITEM:GetMaxStack() return self.max_stack end
function ITEM:GetRarity() return self.rarity end

function ITEM:GetCharacterID() return self.characterID end
function ITEM:GetPlayerID() return self.playerID end

function ITEM:Base(base)
	if isstring(base) then
		base = ix.Item.base[base]
	end

	if !istable(base) then 
		ErrorNoHalt("[Mono] Item '"..self.uniqueID.."' has a non-existent base!\n")
		return 
	end

	for k, v in pairs(base) do
		if !self[k] or isfunction(v) then
			self[k] = v
		end
	end

	self:Init(self.uniqueID)

	self.bases[base.uniqueID] = base
	self.base_count = self.base_count + 1
end

function ITEM:Is(base)
	if isstring(base) then
		return self.bases[base] != nil
	elseif istable(base) then
		for k, v in pairs(self.bases) do
			if base.uniqueID == v.uniqueID then
				return true
			end
		end
	end

	return false
end

function ITEM:Call(method, client, ...)
	local oldPlayer = self.player

	self.player = client or self.player

	if isfunction(self[method]) then
		local results = {self[method](self, ...)}

		self.player = nil

		return unpack(results)
	end

	self.player = oldPlayer
end

function ITEM:GetOwner()
	for _, v in ipairs(player.GetAll()) do
		if v:HasItemByID(self.id) then
			return v
		end
	end
end

do
	if SERVER then
		function net.WriteItemData(item, key, value)
			value = value or item.data[key]

			local data = item.vars[key]

			net.WriteUInt(item:GetID(), 32)
			net.WriteUInt(data.index, item.var_max_bits)

			if isfunction(data.Write) then 
				data.Write(item, value)
			else
				net.WriteType(value)
			end
		end
	end

	function net.ReadItemData()
		local item_id = net.ReadUInt(32)
		local item = ix.Item.instances[item_id]

		if !item then
			return
		end

		local index = net.ReadUInt(item.var_max_bits)
		local key = item.vars_id[index]
		local data = item.vars[key]
		local value

		if data then
			if isfunction(data.Read) then 
				value = data.Read(item)
			else
				value = net.ReadType()
			end

			return item, key, value
		end
	end
end

function ITEM:AddData(key, data)
	self.vars[key] = data

	self.var_max = table.Count(self.vars)
	self.var_max_bits = net.ChooseOptimalBits(self.var_max)

	data.index = self.var_max

	self.vars_id[data.index] = key

	local transmit = data.Transmit

	if istable(transmit) then
		local var = transmit[1]

		for k, v in ipairs(transmit) do
			var = bit.bor(var, v)
		end

		transmit = var
		data.Transmit = var
	end

	if bit.band(transmit, ix.transmit.none) != ix.transmit.none then
		if bit.band(transmit, ix.transmit.all) == ix.transmit.all then
			data.Sync = function(self, receiver)
				local receivers

				if receiver then
					receivers = receiver

					goto send
				end

				if !self:GetEntity() then
					local inventory = self.inventory_id and ix.Inventory:Get(self.inventory_id)

					if inventory then
						receivers = inventory:GetReceivers()
					end
				end

				::send::
				net.Start("item.data")
					net.WriteItemData(self, key)
				if receivers then
					net.Send(receivers)
				else
					net.Broadcast()
				end
			end
		elseif bit.band(transmit, ix.transmit.owner) == ix.transmit.owner then
			data.Sync = function(self, receiver)
				local receivers

				if receiver then
					receivers = receiver

					goto send
				end

				if !self:GetEntity() then
					local inventory = self.inventory_id and ix.Inventory:Get(self.inventory_id)

					if inventory then
						receivers = inventory:GetReceivers()
					end
				end

				::send::
				if receivers then
					net.Start("item.data")
						net.WriteItemData(self, key)
					net.Send(receivers)
				end
			end
		end
	end
end

function ITEM:SetData(key, value, receivers, noSave, noCheckEntity)
	if !self.vars[key] then
		return
	end
	
	self.data[key] = value

	if SERVER then
		/*
		local isCloseLook = bit.band(self.vars[key].Transmit, ix.transmit.closelook) == ix.transmit.closelook

		if isCloseLook then
			self.closelook_sync[key] = {}
		end*/

		if self.vars[key].Sync then
			self.vars[key].Sync(self, receivers)
		end

		if !self.vars[key].NoSave then
			ix.Item.items_to_savedata[self:GetID()] = true
			ix.Item:Async_SaveData()
		end
	end
	
	/*
	if (SERVER) then
		if (!noCheckEntity) then
			local ent = self:GetEntity()

			if (IsValid(ent)) then
				local data = ent:GetNetVar("data", {})
				data[key] = value

				ent:SetNetVar("data", data)
			end
		end
	end

	if (receivers != false and (receivers or self:GetOwner())) then
		net.Start("ixInventoryData")
			net.WriteUInt(self:GetID(), 32)
			net.WriteString(key)
			net.WriteType(value)
		net.Send(receivers or self:GetOwner())
	end

	if (!noSave and ix.db) then
		local query = mysql:Update("ix_items")
			query:Update("data", util.TableToJSON(self.data))
			query:Where("item_id", self:GetID())
		query:Execute()
	end
	*/
end

function ITEM:GetData(key, default)
	if !key then return end

	return self.data[key] or default
end

function ITEM:Remove(bNoDelete, dontSync)
	if SERVER then
		if self.OnRemoved then
			self:OnRemoved()
		end

		if !IsValid(self:GetEntity()) then
			local inventory = self.inventory_id and ix.Inventory:Get(self.inventory_id)

			if inventory then
				inventory:TakeItemTable(self)

				if !dontSync then
					inventory:Sync()
				end
			end
		end

		if bNoDelete then
			local query = mysql:Delete("ix_items")
				query:Where("item_id", self.id)
			query:Execute()

			ix.Item.instances[self.id] = nil
		end
	end

	return true
end

function ITEM:Register()
	if self.OnRegistered then
		self:OnRegistered()
	end

	ix.Item:Register(self.uniqueID, self)
end

function ITEM:SetEntity(entity)
	self.entity = entity
end

function ITEM:GetEntity()
	return self.entity
end

if SERVER then
	function ITEM:SaveData()
		local query = mysql:Update("ix_items")
			local data = {}
			for _, key in ipairs(self.vars_id) do
				local info = self.vars[key]

				if info.NoSave then continue end

				local value = self.data[key]
				local saveValue

				if isfunction(info.Save) then
					saveValue = info.Save(self, value)
				end
				
				data[key] = saveValue or value
			end

			query:Update("data", util.TableToJSON(data))
			query:Where("item_id", self:GetID())
		query:Execute()
	end

	function ITEM:Save()
		/*
		if !self.mark_as_save then
			return
		end*/

		if self.OnSave then
			self:OnSave()
		end
		
		local query = mysql:Update("ix_items")
			query:Update("x", self.x)
			query:Update("y", self.y)
			query:Update("rotated", self.rotated)
			query:Update("inventory_type", self.inventory_type)
			query:Update("character_id", tonumber(self.character_id) or 0)
			query:Update("player_id", tonumber(self.player_id) or 0)
			
			if istable(self.items) then
				query:Update("items", util.TableToJSON(self.items or {}))
			end

			local data = {}
			for _, key in ipairs(self.vars_id) do
				local info = self.vars[key]

				if info.NoSave then continue end

				local value = self.data[key]
				local saveValue

				if isfunction(info.Save) then
					saveValue = info.Save(self, value)
				end
				
				data[key] = saveValue or value
			end

			query:Update("data", util.TableToJSON(data))

			query:Where("item_id", self:GetID())
		query:Execute()

		self.mark_as_save = false
	end
		
	function ITEM:Sync(receiver, transmit)
		if receiver == nil then
			for k, v in ipairs(player.GetAll()) do
				self:Sync(v, transmit)
			end
		else
			local entity = self:GetEntity()
			local data = {}

			for k, info in pairs(self.vars) do
				if bit.band(info.Transmit, ix.transmit.none) == ix.transmit.none then continue end
				if bit.band(info.Transmit, ix.transmit.owner) == ix.transmit.owner then 
					local inventory = self.inventory_id and ix.Inventory:Get(self.inventory_id)

					local has

					if inventory then
						local receivers = inventory:GetReceivers()

						for k, v in ipairs(receivers) do
							if v == receiver then
								has = true
								break
							end
						end
					end
					
					if !has then
						continue
					end
				end

				data[k] = self.data[k]
			end

			data = pon.encode(data)
			data = util.Compress(data)

			local length = #data

			net.Start('item.sync')
				net.WriteString(self.uniqueID)
				net.WriteUInt(self:GetID(), 32)
				if IsValid(entity) then
					net.WriteUInt(entity:EntIndex(), 16)
				elseif self.inventory_id then
					net.WriteUInt(0, 16)
					net.WriteUInt(self.inventory_id, 32)
					net.WriteUInt(self.x, 8)
					net.WriteUInt(self.y, 8)
					net.WriteBool(self.rotated)
				end
				net.WriteUInt(length, 32)
				net.WriteData(data, length)
			net.Send(receiver)

			if self.OnSync then
				self:OnSync(receiver, transmit)
			end
		end
	end
else
	function ITEM:GetIconModel()
		return self.icon_model or self:GetModel()
	end

	function ITEM:GetIconData()
		return self.iconCam
	end

	local queue_ents = {}
	local function SetupItemEntity(entity)
		local index = entity:EntIndex()

		if queue_ents[index] then
			local itemID = queue_ents[index]
			local item = ix.Item.instances[itemID]

			entity.ixItemID = itemID
			ix.Item.entities[itemID] = entity

			item.entity = entity

			queue_ents[index] = nil
		end
	end

	hook.Add("OnEntityCreated", "item.sync", function(entity)
		SetupItemEntity(entity)
	end)

	net.Receive('item.sync', function(len)
		local uniqueID = net.ReadString()
		local itemID = net.ReadUInt(32)
		local entityID = net.ReadUInt(16)
		local entity
		local invID
		local x, y

		if entityID <= 0 then
			invID = net.ReadUInt(32)
			x, y, rotated = net.ReadUInt(8), net.ReadUInt(8), net.ReadBool()
		end

		local length = net.ReadUInt(32)
		local data = net.ReadData(length)

		local item = ix.Item:New(uniqueID, itemID)

		if item then
			if x and y then
				item.x = x
				item.y = y
				item.rotated = rotated
			end

			if entityID > 0 then
				item.character_id = nil
				item.inventory_id = nil
				item.inventory_type = nil

				queue_ents[entityID] = itemID

				local entity = Entity(entityID)
				
				if IsValid(entity) then
					SetupItemEntity(entity)
				end
			elseif invID then
				item.entity = nil
				item.inventory_id = invID

				ix.Item.entities[itemID] = nil
			end

			data = util.Decompress(data)
			data = pon.decode(data)

			if data then
				for k, v in pairs(data) do
					item.data[k] = v

					if item.data_callbacks and isfunction(item.data_callbacks[k]) then
						item.data_callbacks[k](item, v)
					end
				end
			end
		end
	end)

	net.Receive('item.data', function(len)
		local item, key, value = net.ReadItemData()

		if item and key then
			item.data[key] = value

			if item.data_callbacks and isfunction(item.data_callbacks[key]) then
				item.data_callbacks[key](item, value)
			end
		end
	end)
end

