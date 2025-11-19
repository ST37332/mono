hook.Add("PlayerInitialSpawn", "APIPlayerCheck", function(ply)
    if not api_core.ServerData.isAuthenticated then
        ply:Kick("Сервер не авторизован. Попробуйте позже.")
        return
    end
end)

function api_core:SecureDatabaseQuery(query, callback)
    return self:SecureCall("database_query", callback, query)
end

function api_core:ProcessTransaction(ply, amount, reason)
    return self:SecureCall("economy_transaction", function(result)
        if result.success then
            print("[API] Operation error: " .. result.error)
        end
    end, ply:SteamID64(), amount, reason)
end
