local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Toggle_Keys = {
	Highlight = {Key = Enum.KeyCode.Z, Enabled = false},
	AimBot = {Key = Enum.KeyCode.X, Enabled = false},
	Click = {Key = Enum.KeyCode.L, Enabled = false},
	Disable = {Key = Enum.KeyCode.P},
	Rejoin = {Key = Enum.KeyCode.Minus}
}

local function IsSameTeam(Player1, Player2)
	if not Player1.Neutral or not Player2.Neutral then
		return Player1.Team and Player2.Team and Player1.Team == Player2.Team
	end
	return false
end

local function IsVisible(Origin, Target, IgnoreList)
	local RaycastParams = RaycastParams.new()
	RaycastParams.FilterDescendantsInstances = IgnoreList
	RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local Direction = (Target - Origin).Unit
	local Distance = (Target - Origin).Magnitude
	local RaycastResult = workspace:Raycast(Origin, Direction * Distance, RaycastParams)

	return not RaycastResult
end

local function AddHighlight(Char)
	if Char:IsA("Model") and Char:FindFirstChild("Humanoid") then
		if not Char:FindFirstChild("Highlight") then
			local New_Highlight = Instance.new("Highlight", Char)
			New_Highlight.FillTransparency = 0.5
			New_Highlight.FillColor = Color3.fromRGB(20, 255, 196)
			New_Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
			New_Highlight.Enabled = true
		end
	end
end

local function ToggleHighlights(Enable)
	for _, Char in workspace:GetDescendants() do
		if Char:IsA("Model") and Char:FindFirstChild("Humanoid") then
			local Player = Players:GetPlayerFromCharacter(Char)
			if Player and not IsSameTeam(LocalPlayer, Player) then
				local Highlight = Char:FindFirstChild("Highlight")
				if Highlight then
					Highlight.Enabled = Enable
				else
					AddHighlight(Char)
				end
			end
		end
	end
end

local function OnCLick(Enabled)
	Mouse.Button1Down:Connect(function()
		local Target = Mouse.Target
		if Target ~= nil then
			if not Target:IsA("BasePart") or Target:IsA("MeshPart") then end
			if Target.Locked == true then end
			if Target.CanCollide == true then
				Target.CanCollide = false
			else
				Target.CanCollide = true
			end
		end
	end)
end

local function DeleteHighlights()
	for _, Character in workspace:GetDescendants() do
		if Character:IsA("Model") and Character:FindFirstChild("Humanoid") then
			local Highlight = Character:FindFirstChild("Highlight")
			if Highlight then
				Highlight:Destroy()
			end
		end
	end
end

workspace.ChildAdded:Connect(AddHighlight)
for _, Player in Players:GetPlayers() do
	local Character = Player:FindFirstChild("Character")
	if Character then AddHighlight(Character) end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Toggle_Keys.AimBot.Key then
		Toggle_Keys.AimBot.Enabled = not Toggle_Keys.AimBot.Enabled
	end

	if input.KeyCode == Toggle_Keys.Highlight.Key then
		Toggle_Keys.Highlight.Enabled = not Toggle_Keys.Highlight.Enabled
		ToggleHighlights(Toggle_Keys.Highlight.Enabled)
	end

	if input.KeyCode == Toggle_Keys.Click.Key then
		Toggle_Keys.Click.Enabled = not Toggle_Keys.Click.Enabled
		OnCLick(Toggle_Keys.Click.Enabled)
	end

	if input.KeyCode == Toggle_Keys.Disable.Key then
		Toggle_Keys.Highlight.Enabled = false
		Toggle_Keys.AimBot.Enabled = false
		ToggleHighlights(false)
		DeleteHighlights()
		script:Destroy()
	end

	if input.KeyCode == Toggle_Keys.Rejoin.Key then
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end
end)

RunService.Heartbeat:Connect(function()
	if not Toggle_Keys.AimBot.Enabled then return end

	local PlayersTable = {}
	local LocalCharacter = LocalPlayer.Character
	if not LocalCharacter then return end

	local LocalRootPart = LocalCharacter:FindFirstChild("HumanoidRootPart") or LocalCharacter:FindFirstChild("Torso")
	if not LocalRootPart then return end

	for _, Player in Players:GetPlayers() do
		if Player ~= LocalPlayer and Player.Character then
			local Character = Player.Character
			local RootPart = Character:FindFirstChild("Head") -- AnyBody Part
			if RootPart and not IsSameTeam(LocalPlayer, Player) then
				local IgnoreList = {LocalCharacter, Character}
				if IsVisible(LocalRootPart.Position, RootPart.Position, IgnoreList) then
					PlayersTable[Character] = RootPart.CFrame
				end
			end
		end
	end

	local ClosestCFrame = nil
	local ShortestDistance = math.huge

	for Character, CFrame in PlayersTable do
		local Distance = (LocalRootPart.Position - CFrame.Position).Magnitude
		if Distance < ShortestDistance then
			ShortestDistance = Distance
			ClosestCFrame = CFrame
		end
	end

	-- Pivot the camera to the closest CFrame
	if ClosestCFrame then
		local Camera = workspace.CurrentCamera
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, ClosestCFrame.Position)
	end
end)
