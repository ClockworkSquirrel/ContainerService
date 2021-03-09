--[[
    Author: csqrl

    PlayerHandle
    Responsible for handling replication "containers" for individual
    players.

    PlayerHandle.new(player: Player): Handle

    Public API:
        Properties:
        * Handle.Player: Player
        * Handle.UserId: number
        * Handle.RootContainerId: string
        * Handle.RootContainer: ScreenGui?
        * Handle.Containers: Dictionary<string, Folder>
        * Handle.InstanceReferences: Dictionary<Instance, Array<Instance>>

        Methods:
        * Handle:GetRootContainer(): Promise<ScreenGui>
        * Handle:GetContainer(containerId: string): Promise<Folder>
        * Handle:Replicate(containerId: string, instance: Instance): Promise<Instance>

        * Handle:Dereplicate(instance: Instance): nil
        * Handle:Destroy(): nil
--]]
local HttpService = game:GetService("HttpService")

local Promise = require(script.Parent.Parent.Promise)
local TryDestroy = require(script.Parent.Parent.TryDestroy)

local PlayerHandle = {}

PlayerHandle.__index = PlayerHandle

function PlayerHandle.new(player: Player)
    local self = setmetatable({}, PlayerHandle)

    self.Player = player
    self.UserId = player.UserId

    self.RootContainerId = HttpService:GenerateGUID()
    self.RootContainer = nil
    self.RootPendingSignal = Instance.new("BindableEvent")

    self.Containers = {}
    self.ContainersPending = {}
    self.ContainersPendingSignal = Instance.new("BindableEvent")

    self.InstanceReferences = {}

    coroutine.wrap(self._CreateRootContainer)(self)

    return self
end

function PlayerHandle:Destroy()
    TryDestroy(self.RootContainer)
    TryDestroy(self.RootPendingSignal)
    TryDestroy(self.ContainersPendingSignal)

    for key, _ in pairs(self) do
        self[key] = nil
    end
end

function PlayerHandle:_CreateRootContainer()
    if self.RootContainer then
        return
    end

    local container = Instance.new("ScreenGui")
    container.Name = self.RootContainerId
    container.ResetOnSpawn = false
    container.Parent = self.Player:WaitForChild("PlayerGui")

    self.RootContainer = container

    self.RootPendingSignal:Fire()
    self.RootPendingSignal:Destroy()
end

function PlayerHandle:_CreateContainer(containerId: string)
    if self.Containers[containerId] or self.ContainersPending[containerId] then
        return
    end

    self.ContainersPending[containerId] = true

    local rootContainer = self:GetRootContainer():expect()

    local container = Instance.new("Folder")
    container.Name = HttpService:GenerateGUID()
    container:SetAttribute("__CONTAINER_ID__", containerId)
    container.Parent = rootContainer

    self.Containers[containerId] = container
    self.ContainersPending[containerId] = nil

    self.ContainersPendingSignal:Fire(containerId)
end

function PlayerHandle:_GetInstanceReference(instance: Instance)
    local reference = self.InstanceReferences[instance]

    if not reference then
        reference = {}
        self.InstanceReferences[instance] = reference
    end

    return reference
end

function PlayerHandle:GetRootContainer()
    if self.RootContainer then
        return Promise.resolve(self.RootContainer)
    end

    return Promise.new(function(resolve)
        if self.RootContainer then
            return resolve(self.RootContainer)
        end

        self.RootPendingSignal.Event:Wait()
        resolve(self.RootContainer)
    end)
end

function PlayerHandle:GetContainer(containerId: string)
    if self.Containers[containerId] then
        return Promise.resolve(self.Containers[containerId])
    end

    return Promise.new(function(resolve)
        if self.Containers[containerId] then
            return resolve(self.Containers[containerId])
        end

        if self.ContainersPending[containerId] then
            return resolve(Promise.fromEvent(self.ContainersPendingSignal.Event, function(resolvedId)
                return resolvedId == containerId
            end):andThen(function()
                return self.Containers[containerId]
            end))
        end

        self:_CreateContainer(containerId)
        resolve(self:GetContainer(containerId))
    end)
end

function PlayerHandle:Replicate(containerId: string, instance: Instance)
    return self:GetContainer(containerId):andThen(function(container)
        local instanceRef = self:_GetInstanceReference(instance)
        local clonedInstance = instance:Clone()

        table.insert(instanceRef, clonedInstance)
        clonedInstance.Parent = container

        return clonedInstance
    end)
end

function PlayerHandle:Dereplicate(instance: Instance)
    local instanceRef = self.InstanceReferences[instance]

    if not instance or not instanceRef then
        return
    end

    for _, clonedInstance in ipairs(instanceRef) do
        clonedInstance:Destroy()
    end

    self.InstanceReferences[instance] = nil
end

return PlayerHandle
