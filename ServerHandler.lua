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
