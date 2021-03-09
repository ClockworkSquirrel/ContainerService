--[[
    Author: csqrl

    ContainerService (Server):
    Responsible for automatic creation/cleanup of PlayerHandles. The service
    itself only provides access to a PlayerHandle in its public API.

    Public API:
        Methods:
        * Service.GetHandlePromise(player: Player): Promise<PlayerHandle>
        * Service.GetHandleSync(player: Player): PlayerHandle
--]]
local Players = game:GetService("Players")

local Promise = require(script.Parent.Promise)
local PlayerHandle = require(script.PlayerHandle)

local fmt = string.format

local PendingTrackedPlayers = {}
local PendingTrackedPlayersSignal = Instance.new("BindableEvent")
local TrackedPlayers = {}

--@outline Remotes Init
local RemoteSignals = Instance.new("Folder")
RemoteSignals.Name = "Networking"

local RemoteGetPlayerRootContainer = Instance.new("RemoteFunction")
RemoteGetPlayerRootContainer.Name = "GetRootContainer"
RemoteGetPlayerRootContainer.Parent = RemoteSignals

--@outline Player Handling
local function GetPlayerHandlePromise(player: Player)
    local userId = player.UserId

    if TrackedPlayers[userId] then
        return Promise.resolve(TrackedPlayers[userId])
    end

    return Promise.new(function(resolve, reject)
        if TrackedPlayers[userId] then
            return resolve(TrackedPlayers[userId])
        end

        if PendingTrackedPlayers[userId] then
            return resolve(Promise.fromEvent(PendingTrackedPlayersSignal.Event, function(resolvedId)
                return resolvedId == userId
            end):andThen(function()
                return TrackedPlayers[userId]
            end))
        end

        reject(fmt("%q (Player) failed to initialise automatically"))
    end)
end

local function GetPlayerHandleSync(player: Player)
   return GetPlayerHandlePromise(player):expect()
end

local function PlayerInit(player: Player)
    local userId = player.UserId

    PendingTrackedPlayers[userId] = true
    TrackedPlayers[userId] = PlayerHandle.new(player)

    PendingTrackedPlayers[userId] = nil
    PendingTrackedPlayersSignal:Fire(userId)
end

local function PlayerDeinit(player: Player)
    local userId = player.UserId

    TrackedPlayers[userId]:Destroy()
    TrackedPlayers[userId] = nil
end

--@outline Service Handling
local function ServiceInit()
    for _, player in ipairs(Players:GetPlayers()) do
        coroutine.wrap(PlayerInit)(player)
    end

    Players.PlayerAdded:Connect(PlayerInit)
    Players.PlayerRemoving:Connect(PlayerDeinit)

    RemoteSignals.Parent = script.Parent
end

ServiceInit()

--@outline Remotes Handling
RemoteGetPlayerRootContainer.OnServerInvoke = function(player: Player)
    local handle = GetPlayerHandlePromise(player):expect()
    local rootContainer = handle:GetRootContainer():expect()
    return rootContainer
end

return {
    GetHandlePromise = GetPlayerHandlePromise,
    GetHandleSync = GetPlayerHandleSync,
}
