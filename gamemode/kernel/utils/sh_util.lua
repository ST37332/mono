mono.type = mono.type or {
	[2] = "string",
	[4] = "text",
	[8] = "number",
	[16] = "player",
	[32] = "steamid",
	[64] = "character",
	[128] = "bool",
	[1024] = "color",
	[2048] = "vector",

	string = 2,
	text = 4,
	number = 8,
	player = 16,
	steamid = 32,
	character = 64,
	bool = 128,
	color = 1024,
	vector = 2048,

	optional = 256,
	array = 512
}

mono.transmit = mono.transmit or {
	[2] = "none",
	[4] = "owner",
	[8] = "all",
	[16] = "closelook",

	none = 2,
	owner = 4,
	all = 8,
	closelook = 16
}

mono.blurRenderQueue = {}


function mono.util.Include(fileName, realm)
	if (!fileName) then
		error("No file name specified for including.")
	end

    
	if ((realm == "server" or fileName:find("sv_")) and SERVER) then
		return include(fileName)
        
	elseif (realm == "shared" or fileName:find("shared.lua") or fileName:find("sh_")) then
		if (SERVER) then
			AddCSLuaFile(fileName)
		end

		return include(fileName)
	elseif (realm == "client" or fileName:find("cl_")) then
		if (SERVER) then
			AddCSLuaFile(fileName)
		else
			return include(fileName)
		end
	end
end


function mono.util.IncludeDir(directory, bFromLua, realm)

	bDir = "mono/gamemode/"

	for _, v in ipairs(file.Find((bFromLua and "" or bDir)..directory.."/*.lua", "LUA")) do
		mono.util.Include(directory.."/"..v, realm)
	end
end

function mono.util.G(id, data)
	if !mono[id] then
		local object = {}
		object.__index = object

		if data then
			table.Merge(object, data)
		end

		mono[id] = object
	end
	
	return mono[id]
end


function mono.util.StripRealmPrefix(name)
	local prefix = name:sub(1, 3)

	return (prefix == "sh_" or prefix == "sv_" or prefix == "cl_") and name:sub(4) or name
end


function mono.util.IsColor(input)
	return istable(input) and
		isnumber(input.a) and isnumber(input.g) and isnumber(input.b) and (input.a and isnumber(input.a) or input.a == nil)
end


function mono.util.DimColor(color, multiplier, alpha)
	return Color(color.r * multiplier, color.g * multiplier, color.b * multiplier, alpha or 255)
end


function mono.util.SanitizeType(type, input)
	if (type == mono.type.string) then
		return tostring(input)
	elseif (type == mono.type.text) then
		return tostring(input)
	elseif (type == mono.type.number) then
		return tonumber(input or 0) or 0
	elseif (type == mono.type.bool) then
		return tobool(input)
	elseif (type == mono.type.color) then
		return istable(input) and
			Color(tonumber(input.r) or 255, tonumber(input.g) or 255, tonumber(input.b) or 255, tonumber(input.a) or 255) or
			color_white
	elseif (type == mono.type.vector) then
		return isvector(input) and input or vector_origin
	elseif (type == mono.type.array) then
		return input
	else
		error("attempted to sanitize " .. (mono.type[type] and ("invalid type " .. mono.type[type]) or "unknown type " .. type))
	end
end

do
	local typeMap = {
		string = mono.type.string,
		number = mono.type.number,
		Player = mono.type.player,
		boolean = mono.type.bool,
		Vector = mono.type.vector
	}

	local tableMap = {
		[mono.type.character] = function(value)
			return getmetatable(value) == mono.meta.character
		end,

		[mono.type.color] = function(value)
			return mono.util.IsColor(value)
		end,

		[mono.type.steamid] = function(value)
			return isstring(value) and (value:match("STEAM_(%d+):(%d+):(%d+)")) != nil
		end
	}

    
	function mono.util.GetTypeFromValue(value)
		local result = typeMap[type(value)]

		if (result) then
			return result
		end

		if (istable(value)) then
			for k, v in pairs(tableMap) do
				if (v(value)) then
					return k
				end
			end
		end
	end
end

function mono.util.Bind(self, callback)
	return function(_, ...)
		return callback(self, ...)
	end
end


function mono.util.GetAddress()
	local address = tonumber(GetConVarString("hostip"))

	if (!address) then
		return "127.0.0.1"..":"..GetConVarString("hostport")
	end

	local ip = {}
		ip[1] = bit.rshift(bit.band(address, 0xFF000000), 24)
		ip[2] = bit.rshift(bit.band(address, 0x00FF0000), 16)
		ip[3] = bit.rshift(bit.band(address, 0x0000FF00), 8)
		ip[4] = bit.band(address, 0x000000FF)
	return table.concat(ip, ".")..":"..GetConVarString("hostport")
end


function mono.util.GetMaterial(materialPath)
    
	mono.util.cachedMaterials = mono.util.cachedMaterials or {}
	mono.util.cachedMaterials[materialPath] = mono.util.cachedMaterials[materialPath] or Material(materialPath)

	return mono.util.cachedMaterials[materialPath]
end


function mono.util.FindPlayer(identifier, bAllowPatterns)
	if (string.find(identifier, "STEAM_(%d+):(%d+):(%d+)")) then
		return player.GetBySteamID(identifier)
	end

	if (!bAllowPatterns) then
		identifier = string.PatternSafe(identifier)
	end

	for _, v in ipairs(player.GetAll()) do
		if (mono.util.StringMatches(v:Name(), identifier)) then
			return v
		end
	end
end


function mono.util.StringMatches(a, b)
	if (a and b) then
		local a2, b2 = a:utf8lower(), b:utf8lower()

		if (a == b) then return true end
		if (a2 == b2) then return true end

		if (a:find(b)) then return true end
		if (a2:find(b2)) then return true end
	end

	return false
end


function mono.util.FormatStringNamed(format, ...)
	local arguments = {...}
	local bArray = false
	local input
    
	if (istable(arguments[1])) then
		input = arguments[1]
	else
		input = arguments
		bArray = true
	end

	local i = 0
	local result = format:gsub("{(%w-)}", function(word)
		i = i + 1
		return tostring((bArray and input[i] or input[word]) or word)
	end)

	return result
end

do
	local upperMap = {
		["ooc"] = true,
		["looc"] = true,
		["afk"] = true,
		["url"] = true
	}

    
	function mono.util.ExpandCamelCase(input, bNoUpperFirst)
		input = bNoUpperFirst and input or input:utf8sub(1, 1):utf8upper() .. input:utf8sub(2)

		return string.TrimRight((input:gsub("%u%l+", function(word)
			if (upperMap[word:utf8lower()]) then
				word = word:utf8upper()
			end

			return word .. " "
		end)))
	end
end

function mono.util.GridVector(vec, gridSize)
	if (gridSize <= 0) then
		gridSize = 1
	end

	for i = 1, 3 do
		vec[i] = vec[i] / gridSize
		vec[i] = math.Round(vec[i])
		vec[i] = vec[i] * gridSize
	end

	return vec
end

do
	local i
	local value
	local character

	local function iterator(table)
		repeat
			i = i + 1
			value = table[i]
			character = value and value:GetCharacter()
		until character or value == nil

		return value, character
	end

    
	function mono.util.GetCharacters()
		i = 0
		return iterator, player.GetAll()
	end
end

if (CLIENT) then
	local blur = mono.util.GetMaterial("pp/blurscreen")
	local surface = surface


	function mono.util.DrawBlur(panel, amount, passes, alpha)
		amount = amount or 5

		if (mono.setting.Get("cheapBlur", false)) then
			surface.SetDrawColor(50, 50, 50, alpha or (amount * 20))
			surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
		else
			surface.SetMaterial(blur)
			surface.SetDrawColor(255, 255, 255, alpha or 255)

			local x, y = panel:LocalToScreen(0, 0)

			for i = -(passes or 0.2), 1, 0.2 do
				blur:SetFloat("$blur", i * amount)
				blur:Recompute()

				render.UpdateScreenEffectTexture()
				surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
			end
		end
	end


	function mono.util.DrawBlurAt(x, y, width, height, amount, passes, alpha)
		amount = amount or 5

		if (mono.setting.Get("cheapBlur", false)) then
			surface.SetDrawColor(30, 30, 30, amount * 20)
			surface.DrawRect(x, y, width, height)
		else
			surface.SetMaterial(blur)
			surface.SetDrawColor(255, 255, 255, alpha or 255)

			local scrW, scrH = ScrW(), ScrH()
			local x2, y2 = x / scrW, y / scrH
			local w2, h2 = (x + width) / scrW, (y + height) / scrH

			for i = -(passes or 0.2), 1, 0.2 do
				blur:SetFloat("$blur", i * amount)
				blur:Recompute()

				render.UpdateScreenEffectTexture()
				surface.DrawTexturedRectUV(x, y, width, height, x2, y2, w2, h2)
			end
		end
	end

    
	function mono.util.PushBlur(drawFunc)
		mono.blurRenderQueue[#mono.blurRenderQueue + 1] = drawFunc
	end

    
	function mono.util.DrawText(text, x, y, color, alignX, alignY, font, alpha)
		color = color or color_white

		return draw.TextShadow({
			text = text,
			font = font or "Default",
			pos = {x, y},
			color = color,
			xalign = alignX or TEXT_ALIGN_LEFT,
			yalign = alignY or TEXT_ALIGN_LEFT
		}, 1, alpha or (color.a * 0.575))
	end
    

	function mono.util.WrapText(text, maxWidth, font)
		font = font or "Default"
		surface.SetFont(font)

		local words = string.Explode("%s", text, true)
		local lines = {}
		local line = ""
		local lineWidth = 0
        

		if (surface.GetTextSize(text) <= maxWidth) then
			return {text}
		end

		for i = 1, #words do
			local word = words[i]
			local wordWidth = surface.GetTextSize(word)

            
			if (wordWidth > maxWidth) then
				local newWidth

				for i2 = 1, word:utf8len() do
					local character = word[i2]
					newWidth = surface.GetTextSize(line .. character)

					if (newWidth > maxWidth) then
						lines[#lines + 1] = line
						line = ""
					end

					line = line .. character
				end

				lineWidth = newWidth
				continue
			end

			local space = (i == 1) and "" or " "
			local newLine = line .. space .. word
			local newWidth = surface.GetTextSize(newLine)

			if (newWidth > maxWidth) then
				lines[#lines + 1] = line

				line = word
				lineWidth = wordWidth
			else
				line = newLine
				lineWidth = newWidth
			end
		end

		if (line != "") then
			lines[#lines + 1] = line
		end

		return lines
	end

	local cos, sin, abs, rad1, log, pow = math.cos, math.sin, math.abs, math.rad, math.log, math.pow

    
	function mono.util.DrawArc(cx, cy, radius, thickness, startang, endang, roughness, color)
		surface.SetDrawColor(color)
		mono.util.DrawPrecachedArc(mono.util.PrecacheArc(cx, cy, radius, thickness, startang, endang, roughness))
	end

	function mono.util.DrawPrecachedArc(arc)
		for _, v in ipairs(arc) do
			surface.DrawPoly(v)
		end
	end

	function mono.util.PrecacheArc(cx, cy, radius, thickness, startang, endang, roughness)
		local quadarc = {}

        
		startang = startang or 0
		endang = endang or 0

        
		local diff = abs(startang - endang)
		local smoothness = log(diff, 2) / 2
		local step = diff / (pow(2, smoothness))

		if startang > endang then
			step = abs(step) * -1
		end

        
		local inner = {}
		local outer = {}
		local ct = 1
		local r = radius - thickness

		for deg = startang, endang, step do
			local rad = rad1(deg)
			local cosrad, sinrad = cos(rad), sin(rad)

			local ox, oy = cx + (cosrad * r), cy + (-sinrad * r)
			inner[ct] = {
				x = ox,
				y = oy,
				u = (ox - cx) / radius + .5,
				v = (oy - cy) / radius + .5
			}

			local ox2, oy2 = cx + (cosrad * radius), cy + (-sinrad * radius)
			outer[ct] = {
				x = ox2,
				y = oy2,
				u = (ox2 - cx) / radius + .5,
				v = (oy2 - cy) / radius + .5
			}

			ct = ct + 1
		end

		for tri = 1, ct do
			local p1, p2, p3, p4
			local t = tri + 1
			p1 = outer[tri]
			p2 = outer[t]
			p3 = inner[t]
			p4 = inner[tri]

			quadarc[tri] = {p1, p2, p3, p4}
		end

		return quadarc
	end

    
	function mono.util.ResetStencilValues()
		render.SetStencilWriteMask(0xFF)
		render.SetStencilTestMask(0xFF)
		render.SetStencilReferenceValue(0)
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		render.ClearStencil()
	end


	function derma.SkinFunc(name, panel, a, b, c, d, e, f, g)
		local skin = (ispanel(panel) and IsValid(panel)) and panel:GetSkin() or derma.GetDefaultSkin()

		if (!skin) then
			return
		end

		local func = skin[name]

		if (!func) then
			return
		end

		return func(skin, panel, a, b, c, d, e, f, g)
	end

    
	function derma.GetColor(name, panel, default)
		default = default or mono.option.Get("color")

		local skin = panel:GetSkin()

		if (!skin) then
			return default
		end

		return skin.Colours[name] or default
	end


	hook.Add("OnScreenSizeChanged", "mono.OnScreenSizeChanged", function(oldWidth, oldHeight)
		hook.Run("ScreenResolutionChanged", oldWidth, oldHeight)
	end)
end


do
	local VECTOR = FindMetaTable("Vector")
	local CrossProduct = VECTOR.Cross
	local right = Vector(0, -1, 0)

	function VECTOR:Right(vUp)
		if (self[1] == 0 and self[2] == 0) then
			return right
		end

		if (vUp == nil) then
			vUp = vector_up
		end

		local vRet = CrossProduct(self, vUp)
		vRet:Normalize()

		return vRet
	end

	function VECTOR:Up(vUp)
		if (self[1] == 0 and self[2] == 0) then return Vector(-self[3], 0, 0) end

		if (vUp == nil) then
			vUp = vector_up
		end

		local vRet = CrossProduct(self, vUp)
		vRet = CrossProduct(vRet, self)
		vRet:Normalize()

		return vRet
	end
end


FCAP_IMPULSE_USE = 0x00000010
FCAP_CONTINUOUS_USE = 0x00000020
FCAP_ONOFF_USE = 0x00000040
FCAP_DIRECTIONAL_USE = 0x00000080
FCAP_USE_ONGROUND = 0x00000100
FCAP_USE_IN_RADIUS = 0x00000200

function mono.util.IsUseableEntity(entity, requiredCaps)
	if (IsValid(entity)) then
		local caps = entity:ObjectCaps()

		if (bit.band(caps, bit.bor(FCAP_IMPULSE_USE, FCAP_CONTINUOUS_USE, FCAP_ONOFF_USE, FCAP_DIRECTIONAL_USE))) then
			if (bit.band(caps, requiredCaps) == requiredCaps) then
				return true
			end
		end
	end
end

do
	local function IntervalDistance(x, x0, x1)
        
		if (x0 > x1) then
			local tmp = x0

			x0 = x1
			x1 = tmp
		end

		if (x < x0) then
			return x0-x
		elseif (x > x1) then
			return x - x1
		end

		return 0
	end

	local NUM_TANGENTS = 8
	local tangents = {0, 1, 0.57735026919, 0.3639702342, 0.267949192431, 0.1763269807, -0.1763269807, -0.267949192431}
	local traceMin = Vector(-16, -16, -16)
	local traceMax = Vector(16, 16, 16)

	function mono.util.FindUseEntity(player, origin, forward)
		local tr
		local up = forward:Up()
        
		local searchCenter = origin
        

		local useableContents = bit.bor(MASK_SOLID, CONTENTS_DEBRIS, CONTENTS_PLAYERCLIP)

        
		local pObject

		local nearestDist = 1e37
        
		local pNearest = NULL

		for i = 1, NUM_TANGENTS do
			if (i == 0) then
				tr = util.TraceLine({
					start = searchCenter,
					endpos = searchCenter + forward * 1024,
					mask = useableContents,
					filter = player
				})

				tr.EndPos = searchCenter + forward * 1024
			else
				local down = forward - tangents[i] * up
				down:Normalize()

				tr = util.TraceHull({
					start = searchCenter,
					endpos = searchCenter + down * 72,
					mins = traceMin,
					maxs = traceMax,
					mask = useableContents,
					filter = player
				})

				tr.EndPos = searchCenter + down * 72
			end

			pObject = tr.Entity

			local bUsable = mono.util.IsUseableEntity(pObject, 0)

			while (IsValid(pObject) and !bUsable and pObject:GetMoveParent()) do
				pObject = pObject:GetMoveParent()
				bUsable = mono.util.IsUseableEntity(pObject, 0)
			end

			if (bUsable) then
				local delta = tr.EndPos - tr.StartPos
				local centerZ = origin.z - player:WorldSpaceCenter().z
				delta.z = IntervalDistance(tr.EndPos.z, centerZ - player:OBBMins().z, centerZ + player:OBBMaxs().z)
				local dist = delta:Length()

				if (dist < 80) then
					pNearest = pObject

                    
					if (i == 0) then
						return pObject
					end
				end
			end
		end
        

		if (IsValid(player:GetGroundEntity()) and mono.util.IsUseableEntity(player:GetGroundEntity(), FCAP_USE_ONGROUND)) then
			pNearest = player:GetGroundEntity()
		end

		if (IsValid(pNearest)) then
			local point = pNearest:NearestPoint(searchCenter)
			nearestDist = util.DistanceToLine(searchCenter, forward, point)
		end

		for _, v in pairs(ents.FindInSphere(searchCenter, 80)) do
			if (!mono.util.IsUseableEntity(v, FCAP_USE_IN_RADIUS)) then
				continue
			end

			local point = v:NearestPoint(searchCenter)

			local dir = point - searchCenter
			dir:Normalize()
			local dot = dir:Dot(forward)

			if (dot < 0.8) then
				continue
			end

			local dist = util.DistanceToLine(searchCenter, forward, point)

			if (dist < nearestDist) then
				local trCheckOccluded = {}

				util.TraceLine({
					start = searchCenter,
					endpos = point,
					mask = useableContents,
					filter = player,
					output = trCheckOccluded
				})

				if (trCheckOccluded.fraction == 1.0 or trCheckOccluded.Entity == v) then
					pNearest = v
					nearestDist = dist
				end
			end
		end

		return pNearest
	end
end

function mono.util.FindEmptySpace(entity, filter, spacing, size, height, tolerance)
	spacing = spacing or 32
	size = size or 3
	height = height or 36
	tolerance = tolerance or 5

	local position = entity:GetPos()
	local mins, maxs = Vector(-spacing * 0.5, -spacing * 0.5, 0), Vector(spacing * 0.5, spacing * 0.5, height)
	local output = {}

	for x = -size, size do
		for y = -size, size do
			local origin = position + Vector(x * spacing, y * spacing, 0)

			local data = {}
				data.start = origin + mins + Vector(0, 0, tolerance)
				data.endpos = origin + maxs
				data.filter = filter or entity
			local trace = util.TraceLine(data)

			data.start = origin + Vector(-maxs.x, -maxs.y, tolerance)
			data.endpos = origin + Vector(mins.x, mins.y, height)

			local trace2 = util.TraceLine(data)

			if (trace.StartSolid or trace.Hit or trace2.StartSolid or trace2.Hit or !util.IsInWorld(origin)) then
				continue
			end

			output[#output + 1] = origin
		end
	end

	table.sort(output, function(a, b)
		return a:DistToSqr(position) < b:DistToSqr(position)
	end)

	return output
end


do
	function mono.util.GetUTCTime()
		local date = os.date("!*t")
		local localDate = os.date("*t")
		localDate.isdst = false

		return os.difftime(os.time(date), os.time(localDate))
	end

    
	local TIME_UNITS = {}
	TIME_UNITS["s"] = 1					
	TIME_UNITS["m"] = 60				
	TIME_UNITS["h"] = 3600				
	TIME_UNITS["d"] = TIME_UNITS["h"] * 24
	TIME_UNITS["w"] = TIME_UNITS["d"] * 7
	TIME_UNITS["mo"] = TIME_UNITS["d"] * 30
	TIME_UNITS["y"] = TIME_UNITS["d"] * 365

    
	function mono.util.GetStringTime(text)
		local minutes = tonumber(text)

		if (minutes) then
			return math.abs(minutes * 60)
		end

		local time = 0

		for amount, unit in text:lower():gmatch("(%d+)(%a+)") do
			amount = tonumber(amount)

			if (amount and TIME_UNITS[unit]) then
				time = time + math.abs(amount * TIME_UNITS[unit])
			end
		end

		return time
	end
end


local debug = false
local sprint = debug and print or function() end

originalSoundDuration = originalSoundDuration or SoundDuration

local MP3Data = {
	versions = {"2.5", "x", "2", "1"},
	layers = {"x", "3", "2", "1"},
	bitrates = {
		["V1Lx"] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		["V1L1"] = {0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448},
		["V1L2"] = {0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384},
		["V1L3"] = {0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320},
		["V2Lx"] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		["V2L1"] = {0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 288},
		["V2L2"] = {0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160},
		["V2L3"] = {0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160},
		["VxLx"] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		["VxL1"] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		["VxL2"] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		["VxL3"] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	},
	sampleRates = {
		["x"] = {0, 0, 0},
		["1"] = {44100, 48000, 32000},
		["2"] = {22050, 24000, 16000},
		["2.5"] = {11025, 12000, 8000}
	},
	samples = {
		x = {
			["x"] = 0,
			["1"] = 0,
			["2"] = 0,
			["3"] = 0
		},
		["1"] = {
			["x"] = 0,
			["1"] = 384,
			["2"] = 1152,
			["3"] = 1152
		},
		["2"] = {
			["x"] = 0,
			["1"] = 384,
			["2"] = 1152,
			["3"] = 576
		}
	}
}

local function MP3FrameSize(samples, layer, bitrate, sampleRate, paddingBit)
	local size

	if layer == 1 then
		size = math.floor(((samples * bitrate * 125) / sampleRate) + paddingBit * 4)
	else
		size = math.floor(((samples * bitrate * 125) / sampleRate) + paddingBit)
	end

	return (size == size and size < math.huge) and size or 0
end

local function ParseMP3FrameHeader(buffer)
	buffer:Skip(1)
	local b1, b2 = buffer:ReadByte(), buffer:ReadByte()

	local versionBits = bit.rshift(bit.band(b1, 0x18), 3)
	local version = MP3Data.versions[versionBits + 1]
	local simpleVersion = version == "2.5" and "2" or version

	local layerBits = bit.rshift(bit.band(b1, 0x06), 1)
	local layer = MP3Data.layers[layerBits + 1]

	local bitrateKey = "V" .. simpleVersion .. "L" .. layer
	local bitrateIndex = bit.rshift(bit.band(b2, 0xf0), 4)
	local bitrate = MP3Data.bitrates[bitrateKey][bitrateIndex + 1] or 0

	local sampleRateIdx = bit.rshift(bit.band(b2, 0x0c), 2)
	local sampleRate = MP3Data.sampleRates[version][sampleRateIdx + 1] or 0

	local sample = MP3Data.samples[simpleVersion][layer]

	local paddingBit = bit.rshift(bit.band(b2, 0x02), 1)

	buffer:Skip(-3)

	return {
		bitrate = bitrate,
		sampleRate = sampleRate,
		frameSize = MP3FrameSize(sample, layer, bitrate, sampleRate, paddingBit),
		samples = sample
	}
end

local soundDecoders = {
	mp3 = function(buffer)
		local duration = 0

		if buffer:Read(3) == "ID3" then
			sprint("ID3v2 metadata detected")

			buffer:Skip(2)

			local ID3Flags = buffer:ReadByte()

			local footerSize = bit.band(ID3Flags, 0x10) == 0x10 and 10 or 0

			local z0, z1, z2, z3 = buffer:ReadByte(), buffer:ReadByte(), buffer:ReadByte(), buffer:ReadByte()
			local ID3Size = 10 + ((bit.band(z0, 0x7f) * 2097152) + (bit.band(z1, 0x7f) * 16384) + (bit.band(z2, 0x7f) * 128) + bit.band(z3, 0x7f)) + footerSize
			sprint("Total ID3v2 size: ", ID3Size, " bytes")

			buffer:Skip(ID3Size - 10)
        else
			buffer:Skip(-buffer:Tell())
		end

		local prevTell = buffer:Tell()
		while buffer:Tell() < buffer:Size() - 10 do
			local b1, b2, b3, b4 = buffer:ReadByte(), buffer:ReadByte(), buffer:ReadByte(), buffer:ReadByte()

			buffer:Seek(prevTell + 4)

			if b1 == 0xff and bit.band(b2, 0xe0) == 0xe0 then
				buffer:Skip(-4)

                
				local frameHeader = ParseMP3FrameHeader(buffer)
				sprint("Found next MP3 frame header @ ", buffer:Tell(), ":", frameHeader.frameSize)

				if frameHeader.frameSize > 0 and frameHeader.samples > 0 then
					buffer:Skip(frameHeader.frameSize)
					duration = duration + (frameHeader.samples / frameHeader.sampleRate)
				else
					buffer:Skip(1)
				end
			elseif b1 == 0x54 and b2 == 0x41 and b3 == 0x47 then
				if b4 == 0x2b then
					sprint("Skipping ID3v1+ metadata")
					buffer:Skip(227 - 4)
				else
					sprint("Skipping ID3v1 metadata")
					buffer:Skip(128 - 4)
				end
			else
                
				buffer:Skip(-3)
			end

			prevTell = buffer:Tell()
		end

		return duration
	end,
    
	wav = function(buffer)
		buffer:Seek(22)
		local channels = buffer:ReadShort()

		local sampleRate = buffer:ReadLong()

		buffer:Seek(34)
		local bitsPerSample = buffer:ReadShort()
		local divisor = bitsPerSample / 8
		local samples = (buffer:Size() - 44) / divisor

		return samples / sampleRate / channels
	end
}

local function SoundDurationLinux(soundPath)
	local extension = soundPath:GetExtensionFromFilename()
	if extension and soundDecoders[extension] then
		local buffer = file.Open("sound/" .. soundPath, "r", "GAME")
		local result = soundDecoders[extension](buffer)
		buffer:Close()
		return result
	end

	return originalSoundDuration(soundPath)
end

SoundDuration = SoundDurationLinux

local ADJUST_SOUND = SoundDuration("npc/metropolice/pain1.wav") > 0 and "" or "../../hl2/sound/"


function mono.util.EmitQueuedSounds(entity, sounds, delay, spacing, volume, pitch)
	delay = delay or 0
	spacing = spacing or 0.1

	for _, v in ipairs(sounds) do
		local postSet, preSet = 0, 0

		if (istable(v)) then
			postSet, preSet = v[2] or 0, v[3] or 0
			v = v[1]
		end

		local length = SoundDuration(ADJUST_SOUND..v)
		delay = delay + preSet

		timer.Simple(delay, function()
			if (IsValid(entity)) then
				entity:EmitSound(v, volume, pitch)
			end
		end)

		delay = delay + length + postSet + spacing
	end

	return delay
end

mono.util.Include("mono/gamemode/kernel/meta/sh_entity.lua")
mono.util.Include("mono/gamemode/kernel/meta/sh_player.lua")
