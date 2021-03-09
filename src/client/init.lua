--[[
    Author: csqrl

    ContainerService (Client):
    Provides events and methods for interacting with replicated instances.

    Public API:
        Properties:
        * Service.RootContainer: ScreenGui?
        * Service.Containers: Dictionary<string, Folder>

        Methods:
        * Service.GetRootContainer(): Promise<ScreenGui>
        * Service.GetContainer(containerId: string): Promise<Folder>

        Events:
        * Service.Replicated: RBXScriptSignal
        * Service.Dereplicated: RBXScriptSignal
--]]
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Promise)
local TryDestroy = require(script.Parent.TryDestroy)

local Remotes = script.Parent:WaitForChild("Networking")
local PostSimulation = RunService.Heartbeat

local Signals = {
    ServiceReadySignal = Instance.new("BindableEvent"),
    ReplicatedSignal = Instance.new("BindableEvent"),
    DereplicatedSignal = Instance.new("BindableEvent"),
    ContainerAddedSignal = Instance.new("BindableEvent"),
}

local Service = {
    Containers = {},
    Replicated = Signals.ReplicatedSignal.Event,
    Dereplicated = Signals.DereplicatedSignal.Event,
}

local function Service_ProcessContainerAdded(container: Instance)
    local containerId = container:GetAttribute("__CONTAINER_ID__")

    if not containerId then
        return
    end

    container.ChildAdded:Connect(function(child)
        PostSimulation:Wait()
        Signals.ReplicatedSignal:Fire(containerId, child)
    end)

    container.ChildRemoved:Connect(function(child)
        Signals.DereplicatedSignal:Fire(containerId, child)
    end)

    Service.Containers[containerId] = container
    Signals.ContainerAddedSignal:Fire(containerId)
end

local function Service_ProcessContainerRemoved(container: Instance)
    local containerId = container:GetAttribute("__CONTAINER_ID__")

    if not containerId then
        return
    end

    TryDestroy(Service.Containers[containerId])
    Service.Containers[containerId] = nil
end

local function Service_Init()
    local rootContainer = Remotes.GetRootContainer:InvokeServer()

    rootContainer.ChildAdded:Connect(Service_ProcessContainerAdded)
    rootContainer.ChildRemoved:Connect(Service_ProcessContainerRemoved)

    rootContainer.Parent = ServerStorage
    Service.RootContainer = rootContainer

    Signals.ServiceReadySignal:Fire()
    Signals.ServiceReadySignal:Destroy()
end

function Service.GetRootContainer()
    if Service.RootContainer then
        return Promise.resolve(Service.RootContainer)
    end

    return Promise.new(function(resolve)
        if Service.RootContainer then
            return resolve(Service.RootContainer)
        end

        Signals.ServiceReadySignal.Event:Wait()
        resolve(Service.RootContainer)
    end)
end

function Service.GetContainer(containerId: string)
    if Service.Containers[containerId] then
        return Promise.resolve(Service.Containers[containerId])
    end

    return Promise.new(function(resolve)
        if Service.Containers[containerId] then
            return resolve(Service.Containers[containerId])
        end

        return resolve(Promise.fromEvent(Signals.ContainerAddedSignal.Event, function(resolvedId)
            return resolvedId == containerId
        end):andThen(function()
            return Service.Containers[containerId]
        end))
    end)
end

Service_Init()

return Service
