mono.date = mono.date or {}
mono.date.lib = mono.date.lib or include("thirdparty/sh_date.lua")
mono.date.timeScale = mono.date.timeScale or mono.option.Get("secondsPerMinute", 60) 
mono.date.current = mono.date.current or mono.date.lib()
mono.date.start = mono.date.start or CurTime()

if (SERVER) then
	util.AddNetworkString("bDateSync")

    
	function mono.date.Initialize()
		local currentDate = mono.data.Get("date", nil, false, true)

		if (!currentDate) then
			currentDate = {
				year = mono.option.Get("year"),
				month = mono.option.Get("month"),
				day = mono.option.Get("day"),
				hour = tonumber(os.date("%H")) or 0,
				min = tonumber(os.date("%M")) or 0,
				sec = tonumber(os.date("%S")) or 0
			}

			currentDate = mono.date.lib.serialize(mono.date.lib(currentDate))
			mono.data.Set("date", currentDate, false, true)
		end

		mono.date.timeScale = mono.option.Get("secondsPerMinute", 60)
		mono.date.current = mono.date.lib.construct(currentDate)
	end

    
	function mono.date.ResolveOffset()
		mono.date.current = mono.date.Get()
		mono.date.start = CurTime()
	end
    

	function mono.date.UpdateTimescale(secondsPerMinute)
		mono.date.ResolveOffset()
		mono.date.timeScale = secondsPerMinute
	end

    

	function mono.date.Send(client)
		net.Start("bDateSync")

		net.WriteFloat(mono.date.timeScale)
		net.WriteTable(mono.date.current)
		net.WriteFloat(mono.date.start)

		if (client) then
			net.Send(client)
		else
			net.Broadcast()
		end
	end

    
	function mono.date.Save()
		mono.date.bSaving = true

		mono.data.Set("date", mono.date.lib.serialize(mono.date.current), false, true)

		mono.option.Set("year", mono.date.current:getyear())
		mono.option.Set("month", mono.date.current:getmonth())
		mono.option.Set("day", mono.date.current:getday())

		mono.date.bSaving = nil
	end
else
	net.Receive("bDateSync", function()
		local timeScale = net.ReadFloat()
		local currentDate = mono.date.lib.construct(net.ReadTable())
		local startTime = net.ReadFloat()

		mono.date.timeScale = timeScale
		mono.date.current = currentDate
		mono.date.start = startTime
	end)
end


function mono.date.Get()
	local minutesSinceStart = (CurTime() - mono.date.start) / mono.date.timeScale

	return mono.date.current:copy():addminutes(minutesSinceStart)
end


function mono.date.GetFormatted(format, currentDate)
	return (currentDate or mono.date.Get()):fmt(format)
end


function mono.date.GetSerialized(currentDate)
	return mono.date.lib.serialize(currentDate or mono.date.Get())
end


function mono.date.Construct(currentDate)
	return mono.date.lib.construct(currentDate)
end
