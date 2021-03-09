local RunService = game:GetService("RunService")

if RunService:IsClient() then
    script.server:Destroy()
    return require(script.client)
else
    return require(script.server)
end
