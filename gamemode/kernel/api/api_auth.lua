function api_core:InitializeAPI()
    local apiKey = GetConVar('sv_api_key'):GetString()
    local serverID = self:GenerateServerID()

    if apiKey == '' then
        self:BlockServerStart('Error: Key is not found.')
        return false 
    end

    self.ServerData.apiKey = apiKey
    self.ServerData.serverID = serverID

    return self:AuthenticateWithMaster()
end

function api_core:AuthenticateWithMaster()
    local payload = {
        api_key = self.ServerData.apiKey,
        server_id = self.ServerData.serverID,
        server_ip = game.GetIPAddress(),
        server_port = GetConVar("hostport"):GetInt(),
        server_version = self:GetServerVersion(),
        unique_hash = self:GenerateServerHash()
    }
    
    HTTP({
        url = self.Config.API_BASE_URL .. "/auth/server",
        method = "POST",
        body = util.TableToJSON(payload),
        success = function(code, body)
            local response = util.JSONToTable(body)
            
            if response.success then
                self.ServerData.sessionToken = response.session_token
                self.ServerData.isAuthenticated = true
                self:StartHeartbeat()
                print("[API] Successful authentication")
            else
                self:BlockServerStart("Authentication error: " .. response.error)
            end
        end,
        failed = function(err)
            self:BlockServerStart("Couldn't connect to the API server")
        end
    })
end
