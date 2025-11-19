local PLAYER = {}

PLAYER.DisplayName = "Player"
PLAYER.WalkSpeed = 250
PLAYER.RunSpeed = 500
PLAYER.JumpPower = 200
PLAYER.StartHealth = 100
PLAYER.MaxHealth = 100
PLAYER.StartArmor = 0
PLAYER.TeamBased = true

function PLAYER:Init()
    self:SetModel("models/player/kleiner.mdl")
end

function PLAYER:Loadout()
    local teamId = self:Team()
    local jobData = mono.Jobs.GetJob(teamId)
    
    if not jobData then return end
    
    for _, weapon in ipairs(jobData.weapons) do
        self:Give(weapon)
    end
    
    self:SetHealth(self.StartHealth)
    self:SetArmor(self.StartArmor)
end

function PLAYER:SetModel()
    local teamId = self:Team()
    local jobData = mono.Jobs.GetJob(teamId)
    
    if jobData and jobData.model then
        local model
        if type(jobData.model) == "table" then
            model = table.Random(jobData.model)
        else
            model = jobData.model
        end
        
        self.PlayerModel = model
        self:SetModel(model)
    else
        self:SetModel("models/player/kleiner.mdl")
    end
end

function PLAYER:Spawn()
    self:SetModel()
    self:Loadout()
    
    self:SetWalkSpeed(self.WalkSpeed)
    self:SetRunSpeed(self.RunSpeed)
    self:SetJumpPower(self.JumpPower)
    
    local jobData = mono.Jobs.GetJob(self:Team())
    if jobData then
        self:ChatPrint("Вы теперь " .. jobData.name)
        self:ChatPrint(jobData.description)
    end
end

function PLAYER:GetWalkSpeed()
    return self.WalkSpeed
end

function PLAYER:GetRunSpeed()
    return self.RunSpeed
end

function PLAYER:Death(inflictor, attacker)
end

player_manager.RegisterClass("player_mono", PLAYER, "player_default")