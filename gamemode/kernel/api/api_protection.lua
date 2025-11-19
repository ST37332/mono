function api_core:GenerateServerHash()
    local components = {
        GetConVar("hostname"):GetString(),
        game.GetIPAddress(),
        GetConVar("hostport"):GetInt(),
        os.time(),
        util.CRC(tostring(math.random(1, 999999)))
    }
    
    return util.SHA256(table.concat(components, "|"))
end


function api_core:ValidateServerUniqueness()
    local currentServer = {
        ip = game.GetIPAddress(),
        port = GetConVar("hostport"):GetInt()
    }
    
    HTTP({
        url = self.Config.API_BASE_URL .. "/validate/server",
        method = "POST",
        body = util.TableToJSON({
            session_token = self.ServerData.sessionToken,
            server_data = currentServer
        }),
        success = function(code, body)
            local response = util.JSONToTable(body)
            
            if not response.valid then
                self:BlockServerOperation("The API key can only be used on 1 server!")
            end
        end
    })
end

function api_core:BlockServerStart(reason)
    MsgC("[API BLOCK] " .. reason, Color(255, 0, 0))
    
    timer.Simple(5, function()
        game.ConsoleCommand("exit\n")
    end)
    
    for i = 1, 10 do
        MsgC("=== SERVER BLOCKED: ===\n           [API] " .. reason, Color(255, 0, 0))
    end
end
