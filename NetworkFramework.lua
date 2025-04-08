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

