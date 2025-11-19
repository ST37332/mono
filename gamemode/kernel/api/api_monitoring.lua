function api_core:LogSecurityEvent(eventType, details)
    self:SecureCall("log_security_event", function() end, {
        type = eventType,
        details = details,
        timestamp = os.time(),
        server_id = self.ServerData.serverID
    })
end

hook.Add("Think", "APISecurityMonitor", function()
    if api_core.ServerData.securityViolations > 5 then
        api_core:BlockServerOperation("Multiple security breaches have been detected")
    end
end)
