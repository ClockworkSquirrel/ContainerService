> This project is still a huge WIP. Use it at your own risk, and expect issues.

# ContainerService
A Roblox service for selectively replicating assets to clients.

You can download the latest version from the Releases, or find a link to the most recent version on the Roblox library.

**Download (Library):**\
https://www.roblox.com/library/6494383686

# API Overview
This is a basic overview of the ContainerService API. You should parent the module to a location which can be accessed by both the server and client, such as ReplicatedStorage.

The library heavily uses Promises, using the [Promise](https://github.com/evaera/roblox-lua-promise) (v3.1.0) library by @evaera. The Promise module is bundled with the module, but you can replace this with a reference to your pre-installed Promise library if required.
## ContainerService (Client)
```lua
local Replicated = game:GetService("ReplicatedStorage")
local ContainerService = require(Replicated.ContainerService)
```
### Properties
* `Service.RootContainer: ScreenGui?`
* `Service.Containers: Dictionary<string, Folder>`

### Methods
* `Service.GetRootContainer(): Promise<ScreenGui>`
* `Service.GetContainer(containerId: string): Promise<Folder>`

### Events
* `Service.Replicated: RBXScriptSignal<containerId: string, instance: Instance>`
* `Service.Dereplicated: RBXScriptSignal<containerId: string, instance: Instance>`
## ContainerService (Server)
```lua
local Replicated = game:GetService("ReplicatedStorage")
local ContainerService = require(Replicated.ContainerService)
```
### Methods
* `Service.GetHandlePromise(player: Player): Promise<PlayerHandle>`
* `Service.GetHandleSync(player: Player): PlayerHandle`
## PlayerHandle
```lua
PlayerHandle.new(player: Player): Handle
```

### Properties
* `Handle.Player: Player`
* `Handle.UserId: number`
* `Handle.RootContainerId: string`
* `Handle.RootContainer: ScreenGui?`
* `Handle.Containers: Dictionary<string, Folder>`
* `Handle.InstanceReferences: Dictionary<Instance, Array<Instance>>`

### Methods
* `Handle:GetRootContainer(): Promise<ScreenGui>`
* `Handle:GetContainer(containerId: string): Promise<Folder>`
* `Handle:Replicate(containerId: string, instance: Instance): Promise<Instance>`

* `Handle:Dereplicate(instance: Instance): nil`
* `Handle:Destroy(): nil`
