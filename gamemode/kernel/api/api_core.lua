api_core = mono.util.G("API", {
    Config = {
        API_BASE_URL = "localhost"
        AUTH_TIMEOUT = 30,
        MAX_REQUESTS_PER_MINUTE = 600 // тут если что ~~ 5 минут
    },
    ServerData = {
        apiKey = '',
        serverID = '',
        sessionToken = '',
        lastHeartbeat = 0,
        isAuthenticated = false
    }
})

mono.util.Include('api_auth.lua')
mono.util.Include('api_heartbeat.lua')
mono.util.Include('api_integration.lua')
mono.util.Include('api_monitoring.lua')
mono.util.Include('api_protection.lua')
mono.util.Include('api_secure_functions.lua')
