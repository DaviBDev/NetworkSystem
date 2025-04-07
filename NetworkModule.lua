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
