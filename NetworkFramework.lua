-->>>>>>>>>>>> CLIENT HANDLER <<<<<<<<<<<<<--

-- | Global |

local Global = require(script.ClientGlobal)

-- | Variables |

local ExecutePrincipals = script.ExecutePrincipals

-- | Network |

Global.Network:Init(Global)

-- | Executions |

-- | Player Added and Removed

local function PlayerAdded()
	for _, Folder in {ExecutePrincipals.Once, ExecutePrincipals.Respawn} do
		for _, Module in Folder:GetChildren() do
			if Folder.Name == "Respawn" then repeat task.wait() until Global.Player.Character and Global.Player.Character:FindFirstChild("Humanoid") end
			
			require(Module)(Global, Folder.Name == "Respawn" and Global.Player.Character or nil)
		end
	end
	
	-- | Player Device
	
	local KeyBoardEnabled = Global.UserInputService.KeyboardEnabled
	local MouseEnabled = Global.UserInputService.MouseEnabled
	local GamepadEnabled = Global.UserInputService.GamepadEnabled

	Global.Device = ((KeyBoardEnabled and MouseEnabled) and "Computer" or (GamepadEnabled and "Console")) or "Mobile"
end

local function PlayerRemoved(Player)
	if Player ~= Global.Player then return end
	
	print(Global.Connections)
	
	Global("DisconnectAll", "Character")
	Global("DisconnectAll", "Player")
end

Global("Connect", "Player", Global.Players.PlayerRemoving, PlayerRemoved)	

PlayerAdded()

-- | Character Added and Removed

local function CharacterAdded(Character)
	repeat task.wait() until Global.Player.Character and Global.Player.Character:FindFirstChild("Humanoid")
	
	for _, Module in ExecutePrincipals.Respawn:GetChildren() do
		if not Module:IsA("ModuleScript") then continue end
		
		require(Module)(Global, Character)
	end
end

local function CharacterRemoving(Character)
	Global("DisconnectAll", "Character")
end

Global("Connect", "Player", Global.Player.CharacterAdded, CharacterAdded)
Global("Connect", "Player", Global.Player.CharacterRemoving, CharacterRemoving)



-->>>>>>>>>>>> GLOBAL MODULE <<<<<<<<<<<<<--


local Global = {
	Variables = {
		-- | Services |
		
		Player = game.Players.LocalPlayer,
		Players = game:GetService("Players"),
		ReplicatedStorage = game:GetService("ReplicatedStorage"),
		TweenService = game:GetService("TweenService"),
		UserInputService = game:GetService("UserInputService"),
		RunService = game:GetService("RunService"),
		
		-- | Folders |
		
		Assets = game.ReplicatedStorage.Assets,
		
		-- | Player Variables |
		
		Event = false,
		Stunned = false,
		MovementStatus = "Walking",
		Device = "Computer",
		
		RenderDistance = 300,
		
		Cooldowns = {},
		PlayingAnimations = {},
		PlayingSounds = {},
		
		-- | Modules |
		
		Network = require(game.ReplicatedStorage.Modules.Network),
		Info = require(game.ReplicatedStorage.Modules.Info),
		
	},
	Functions = {},
	
	Connections = {
		Character = {},
		Player = {},
	},
}

local Functions = Global.Functions
local Connections = Global.Connections

function Functions:Connect(ConnectionType: string, Connection, Function)
	local newConnection = Connection:Connect(Function)
	
	table.insert(Connections[ConnectionType], newConnection)
	
	return newConnection
end

function Functions:Disconnect(ConnectionType: string, Connection)
	local ConnectionIndex = table.find(Connections[ConnectionType], Connection)
	
	if not ConnectionIndex then return warn(`Connection {ConnectionIndex} doesn't exists or not found.`) end
	
	Connections[ConnectionType][ConnectionIndex]:Disconnect()
	table.remove(Connections[ConnectionType], ConnectionIndex)
end
	
function Functions:DisconnectAll(ConnectionType: string)
	for _, CurrentConnection in Connections[ConnectionType] do
		print(CurrentConnection)
		CurrentConnection:Disconnect()
		
		Connections[ConnectionType] = {}
	end
	
	warn(`Disconnected all connections of {ConnectionType}.`)
end

function Functions:EmitAll(Parent, EmitCount)
	for _, Particle: ParticleEmitter in Parent:GetDescendants() do
		if not Particle:IsA("ParticleEmitter") then continue end
		
		if EmitCount then
			Particle:Emit(EmitCount)
			
			continue
		end
		
		EmitCount = Particle:GetAttribute("EmitCount")
		local EmitDelay = Particle:GetAttribute("EmitDelay")
		
		if EmitCount then
			task.delay(EmitDelay and EmitDelay or 0, function()
				Particle:Emit(EmitCount)
			end)
		end
	end
end

function Functions:Animation(Animator: Animator, Name: any)
	local Animation
	
	if typeof(Name) == "string" and self.Assets.Animations:FindFirstChild(Name) then Animation = self.Assets.Animations[Name] else return warn(`Animation {Name} has not found.`) end
	
	if typeof(Name) == "number" then
		Animation = Instance.new("Animation")
		Animation.AnimationId = Name
	end
	
	return Animator:LoadAnimation(Animation)
end

function Functions:Sound(Name: string, Parent: any, DoNotRemove: boolean)
	if not self.Assets:FindFirstChild(Name) then return end
	
	if not Parent then self.Assets[Name]:Play() end
	
	local Sound: Sound = self.Assets[Name]:Clone()
	Sound.Parent = Parent
	
	if not DoNotRemove then
		Sound.Ended:Once(function()
			Sound:Destroy()
		end)
	end
	
	Sound:Play()
	
	return Sound
end

function Functions:Debris(LifeTime, ...)
	local Items = {...}
	
	task.delay(LifeTime, function()
		for _, Item in Items do
			Item:Destroy()
		end
	end)
end

function Functions:Tween(...)
	local Tween = Global.Variables.TweenService:Create(...)
	Tween:Play()
	
	return Tween
end

function Functions:RayCast(Origin: Vector3, Direction: Vector3, Filter: {Instance}, CallBack, Debugger: boolean)
	local FilterDescendants = {workspace.Game.Debris, workspace.Game.Characters, workspace.Game.NPCs}
	
	if Filter then
		for _, NewParams in Filter do
			table.insert(FilterDescendants, NewParams)
		end
	end
	
	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude
	RayParams.FilterDescendantsInstances = FilterDescendants
	
	local RayCast = workspace:Raycast(Origin, Direction, RayParams)
	
	if RayCast then
		if CallBack then CallBack() end
		
		if Debugger then
			local part = Instance.new("Part")
			part.Size = Vector3.new(0.2, 0.2, 5)
			part.CFrame = CFrame.lookAt(Origin, Origin + Direction)
			part.Color = Color3.new(1, 0, 0)
			part.Anchored = true
			part.CanCollide = false
			part.Parent = game.Workspace
			
			Functions:Debris(2, part) -- old debugger, sorry
		end
	end
	
	return RayCast
end

setmetatable(Global, {
	__index = Global.Variables,
	
	__call = function(Table, Action, ...)
		if not Functions[Action] then return warn(`Function {Action} doesn't exists or not found.`) end
		
		return Functions[Action](Global, ...)
	end,
})

return Global


-->>>>>>>>>>>> NETWORK MODULE <<<<<<<<<<<<<--


local Network = {
	Current = "",
	
	ClientServer = {},
	Remotes = {
		Event = {},
		Function = {}
	},
	LastRemotesFired = {},
}

local Remotes = Network.Remotes
local LastRemotesFired = Network.LastRemotesFired

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- | Network Functions |

function Network:InvokeServer(RemotesTable, RemoteName: string, ...)
	if self.Current ~= "Client" then error("Just client can call InvokeServer!")  return end
	if not RemotesTable.Function[RemoteName] then return warn(`Remote ({RemoteName}) doesn't exists or not found.`) end
	
	local Remote: RemoteFunction = RemotesTable.Function[RemoteName]
	LastRemotesFired[RemoteName] = Remote
	
	return Remote:InvokeServer(...)
end

function Network:FireServer(RemotesTable, RemoteName: string, ...)
	if self.Current ~= "Client" then error("Just client can call FireServer!")  return end
	if not RemotesTable.Event[RemoteName] then return warn(`Remote ({RemoteName}) doesn't exists or not found.`) end

	local Remote: RemoteEvent = RemotesTable.Event[RemoteName]

	Remote:FireServer(...)
	
	LastRemotesFired[RemoteName] = Remote
end

function Network:FireClient(Player: Player, RemoteName: string, ...)
	if self.Current ~= "Server" then error("Just Server can call FireClient!")  return end
	if not Remotes.Event[RemoteName] then return warn(`Remote ({RemoteName}) doesn't exists or not found.`) end

	local Remote: RemoteEvent = Remotes.Event[RemoteName]

	Remote:FireClient(Player, ...)
	
	LastRemotesFired[RemoteName] = Remote
end

function Network:FireAllClients(RemoteName: string, ...)
	if self.Current ~= "Server" then error("Just Server can call FireAllClients!")  return end
	if not Remotes.Event[RemoteName] then return warn(`Remote ({RemoteName}) doesn't exists or not found.`) end

	local Remote: RemoteEvent = Remotes.Event[RemoteName]

	Remote:FireAllClients(...)
	
	LastRemotesFired[RemoteName] = Remote
end

function Network:FireClientsInRadius(Player, RemoteName: string, Radius: number, ...)
	if self.Current ~= "Server" then error("Just Server can call FireAllClients!")  return end
	if not Remotes.Event[RemoteName] then return warn(`Remote ({RemoteName}) doesn't exists or not found.`) end
	
	local Players = game:GetService("Players")
	
	local Remote: RemoteFunction = Remotes.Event[RemoteName]
	
	Remote:FireClient(Player, ...)
	
	local Character = Player.Character
	local RootPart = Character.HumanoidRootPart
	
	for _, OtherPlayer in Players:GetPlayers() do
		if OtherPlayer == Player then continue end
		
		local OtherCharacter = OtherPlayer.Character or OtherPlayer.CharacterAdded:Wait()
		local OtherRootPart = OtherCharacter.HumanoidRootPart
		
		local Magnitude = (OtherRootPart.Position-RootPart.Position).Magnitude
		
		if Magnitude > Radius then continue end
		
		Remote:FireClient(OtherPlayer, ...)
	end
	
	LastRemotesFired[RemoteName] = Remote
end

function Network:CreateRemote(RemoteName: string, EventFunction: string, Parent: Folder)
	local Remote = EventFunction == "Event" and Instance.new("RemoteEvent") or Instance.new("RemoteFunction")
	Remote.Parent = Parent
	Remote.Name = ""

	if not Remotes[EventFunction][RemoteName] then Remotes[EventFunction][RemoteName] = Remote end

	return Remote
end

-- | Client n Server |

function Network.ClientServer:Server(Global)
	-- | Variables |
	
	local RemotesModules = ReplicatedStorage.Modules.Remotes
	local RemotesFolder = ReplicatedStorage.Remotes
	
	-- | Creating Remotes
	
	for _, Remote in RemotesModules:GetDescendants() do
		if not Remote:IsA("ModuleScript") then continue end
		
		local RemoteType = Remote.Parent.Name
		
		self:CreateRemote(Remote.Name, RemoteType == "Event" and "Event" or "Function", RemoteType == "Event" and RemotesFolder.Event or RemotesFolder.Function)
	end
	
	-- | Client-Server remotes sync
	
	Global.Players.PlayerAdded:Connect(function(Player)
		local ClientRemotesFunction: RemoteFunction = Instance.new("RemoteFunction") --ReplicatedStorage.Remotes.Function.ClientRemotes
		ClientRemotesFunction.Name = "_getInfo"
		ClientRemotesFunction.Parent = Player
		
		ClientRemotesFunction.OnServerInvoke = function(PlayerInvoked: Player)
			if Player ~= PlayerInvoked or ClientRemotesFunction.Name ~= "_getInfo" then return end
			
			task.delay(.4, function()
				ClientRemotesFunction:Destroy()
			end)
			
			ClientRemotesFunction.Name = "_used"
			
			return Remotes
		end
	end)
	
	
	-- | Initiating Remotes
	
	for RemoteType, RemotesTable in Remotes do
		for RemoteName, Remote in RemotesTable do
			if RemoteName == "ClientRemotes" then continue end
			
			print(RemoteName)
			
			if RemoteType == "Function" then
				-- On Server Invoke
				
				Remote.OnServerInvoke = require(RemotesModules[RemoteType][RemoteName])
			elseif RemoteType == "Event" then
				-- On Server Event
				
				local Module = require(RemotesModules[RemoteType][RemoteName])
				
				local function OnServerEvent(Player, ...)
					Module(Player, ...)
				end
				
				Remote.OnServerEvent:Connect(OnServerEvent)
			end
		end
	end
	
	-- | Connections |
	
	
	
	-- | Server Started |
	
end

function Network.ClientServer:Client(Global)
	local RemotesModules = ReplicatedStorage.Modules.Remotes
	
	local ClientRemoteFunction = Global.Player:WaitForChild("_getInfo") --ReplicatedStorage.Remotes.Function.ClientRemotes
	
	-- | Client-Server Remotes Sync table
	
	local Remotes = ClientRemoteFunction:InvokeServer()
	Network.Remotes = Remotes
	
	-- | Initiating Client Remotes
	
	for RemoteName, Remote in Remotes.Event do
		local Module = require(RemotesModules.Event[RemoteName])
		
		local function OnClientEvent(Player, ...)
			Module(Player, ...)
		end
		
		Remote.OnClientEvent:Connect(OnClientEvent)
	end
	
	-- | Client Started
	
	
end

-- | Initialing |

function Network:Init(Global)
	Network.Current = RunService:IsClient() and "Client" or "Server"
	
	warn("Inited: ".. self.Current)
	
	return self.ClientServer[Network.Current](Network, Global)
end

return Network


-->>>>>>>>>>>> SERVER HANDLER <<<<<<<<<<<<<--

-- | Folders |

local ExecutePrincipalsFolder = script.ExecutePrincipals

-- | Remotes |

local Global = require(script.ServerGlobal)

-- | Executing |

Global.Network:Init(Global)

for _, Module in ExecutePrincipalsFolder:GetChildren() do
	task.spawn(function()
		require(Module)(Global)
	end)
end

-->>>>>>>>>>>> TESTING <<<<<<<<<<<<<--																		

-- REMOTE EVENT
																		
return function(Player, Arg1)
	print(Player, Arg1)
end

-- REMOTE FUNCTION

return function(Player, Arg1)
	print("Testing", Argumento)
	
	return "dwdwwd"
end																		
							
