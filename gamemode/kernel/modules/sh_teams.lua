local jobs = mono.util.G("Jobs", {})
local factions = mono.util.G("Factions", {})



///////////////////////////////////////////////////////////////////////////////
//////////////////////////////      FACTION      //////////////////////////////
///////////////////////////////////////////////////////////////////////////////

mono.Faction = {}

function mono.Faction:Add(factionData)
    factionData.id = factionData.name
    factions[factionData.name] = factionData

    for teamId, jobData in pairs(mono.Jobs) do
        if jobData.faction == factionData.name then
            local cmd = jobData.command
            if cmd then
                concommand.Add("changejob_" .. cmd, function(ply)
                    if not ply:IsValid() then return end
                    ply:ChangeTeam(teamId, true)
                end)
            end
        end
    end

    return factionData
end



///////////////////////////////////////////////////////////////////////////////
////////////////////////////////      JOBS      ///////////////////////////////
///////////////////////////////////////////////////////////////////////////////

function jobs:Add(name, jobData)
    local teamId = table.Count(jobs) + 1
    
    jobData.name = name
    jobData.team = teamId
    
    jobData.color = jobData.color or Color(255, 255, 255, 255)
    jobData.model = jobData.model or {"models/player/kleiner.mdl"}
    jobData.description = jobData.description or "Описание отсутствует."
    jobData.weapons = jobData.weapons or {}
    jobData.command = jobData.command or string.lower(string.gsub(name, "%s+", ""))
    jobData.max = jobData.max or 0
    jobData.salary = jobData.salary or 0
    jobData.haveWeapon = jobData.haveWeapon or false
    jobData.demote = jobData.demote or false
    jobData.faction = jobData.faction or "Citizens"
    jobData.sortOrder = jobData.sortOrder or teamId * 10
    
    jobs[teamId] = jobData
    
    if jobData.command then
        concommand.Add("changejob_" .. jobData.command, function(ply)
            if not ply:IsValid() then return end
            ply:ChangeTeam(teamId, true)
        end)
    end
    
    return teamId
end

function jobs:GetJob(teamId)
    return jobs[teamId]
end

function jobs:GetPlayerCount(teamId)
    local count = 0
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == teamId then
            count = count + 1
        end
    end
    return count
end

function jobs:IsJobAvailable(teamId)
    local job = jobs:GetJob(teamId)
    if not job then return false end
    if job.max == 0 then return true end
    
    return jobs:GetPlayerCount(teamId) < job.max
end

concommand.Add("changejob", function(ply, cmd, args)
    if not ply:IsValid() then return end
    if not args[1] then 
        ply:ChatPrint("Использование: changejob <команда_профессии>")
        return 
    end
    
    local targetJob
    for teamId, jobData in pairs(mono.Jobs) do
        if jobData.command == args[1] then
            targetJob = teamId
            break
        end
    end
    
    if not targetJob then
        ply:ChatPrint("Профессия не найдена!")
        return
    end
    
    ply:ChangeTeam(targetJob, true)
end)

concommand.Add("demote", function(ply, cmd, args)
    if not args[1] then 
        ply:ChatPrint("Использование: demote <имя_игрока> [причина]")
        return 
    end
    
    local target = player.GetByUniqueID(args[1]) or player.GetBySteamID(args[1]) or player.GetBySteamID64(args[1])
    if not IsValid(target) then
        for _, v in ipairs(player.GetAll()) do
            if string.find(string.lower(v:Nick()), string.lower(args[1])) then
                target = v
                break
            end
        end
    end
    
    if not IsValid(target) then
        ply:ChatPrint("Игрок не найден!")
        return
    end
    
    local targetJob = mono.Jobs.GetJob(target:Team())
    if not targetJob then
        ply:ChatPrint("Ошибка: профессия игрока не найдена!")
        return
    end
    
    if not targetJob.demote then
        ply:ChatPrint("Этого игрока нельзя уволить!")
        return
    end
    
    local reason = args[2] and table.concat(args, " ", 2) or "Причина не указана"
    
    local citizenTeam = 1
    target:ChangeTeam(citizenTeam, true)
    
    for _, v in ipairs(player.GetAll()) do
        v:ChatPrint(string.format("[ADMIN] %s был уволен с должности %s. Причина: %s", 
            target:Nick(), targetJob.name, reason))
    end
end)