function api_core:StartHeartbeat()
    timer.Create("APIHeartbeat", self.Config.HEARTBEAT_INTERVAL, 0, function()
        self:SendHeartbeat()
    end)
end

function api_core:SendHeartbeat()
    if not self.ServerData.isAuthenticated then return end
    
    local serverInfo = {
        player_count = #player.GetAll(),
        uptime = CurTime(),
        map = game.GetMap(),
        performance = self:GetPerformanceMetrics()
    }
    
    HTTP({
        url = self.Config.API_BASE_URL .. "/heartbeat",
        method = "POST",
        body = util.TableToJSON({
            session_token = self.ServerData.sessionToken,
            server_info = serverInfo
        }),
        success = function(code, body)
            local response = util.JSONToTable(body)
            
            if not response.valid then
                self:HandleInvalidSession()
            end
        end,
        failed = function(err)
            print("[API] Error sending heartbeat")
        end
    })
end
