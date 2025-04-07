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
