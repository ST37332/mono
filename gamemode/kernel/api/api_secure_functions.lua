function api_core:SecureCall(funcName, callback, ...)
    if not self:ValidateSession() then
        self:BlockServerOperation("Invalid API session")
        return false
    end
    
    local args = {...}
    
    HTTP({
        url = self.Config.API_BASE_URL .. "/execute/" .. funcName,
        method = "POST",
        body = util.TableToJSON({
            session_token = self.ServerData.sessionToken,
            arguments = args
        }),
        success = function(code, body)
            local response = util.JSONToTable(body)
            
            if response.success then
                callback(response.data)
            else
                print("[API] Function execution error: " .. response.error)
            end
        end
    })
    
    return true
end

function api_core:ValidateSession()
    if not self.ServerData.isAuthenticated then
        return false
    end
    
    if os.time() - self.ServerData.lastHeartbeat > self.Config.AUTH_TIMEOUT * 2 then
        return false
    end
    
    return true
end
