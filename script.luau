local Services = setmetatable({}, {
    __index = function(self, name)
        local s, v = pcall(function()
            return cloneref(game:GetService(name))
        end)
        if s then
            rawset(self, name, v)
            return v
        else
            error("Invalid Service: " .. tostring(name))
        end
    end
})

local TextChatService = Services.TextChatService
local ReplicatedStorage = Services.ReplicatedStorage
local Players = Services.Players
local Plr = Players.LocalPlayer
local Chr = Plr.Character
local RunService = game:GetService("RunService")
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"))()

local localPlayer = Players.LocalPlayer
local isLegacyChat = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService

local targetUsername = ""
local targetHumanoid = ""

local Window = OrionLib:MakeWindow({
    Name = "Copy player hacks",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "GioCopyHacks"
})
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Function to get all player names
local function GetPlayerNames()
    local names = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        table.insert(names, player.Name)
    end
    return names
end

local CopyPlayer = MainTab:AddToggle({
    Name = "CopyPlayer",
    Default = false,
    Save = false,
    Flag = "CopyToggle"
})

local PlayerDropdown = MainTab:AddDropdown({
	Name = "Player",
	Default = "",
	Options = GetPlayerNames(),
	Callback = function(Value)
		targetUsername = Value
        targetHumanoid = Players[targetUsername].Character.Humanoid
	end    
})
MainTab:AddButton({
	Name = "Teleport",
	Callback = function()
      	if targetUsername ~= "" then
            Chr:MoveTo(targetHumanoid.Parent.HumanoidRootPart.Position)
        end
  	end    
})
local ConfTab = Window:MakeTab({
    Name = "Config",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local DestroyBind = ConfTab:AddBind({
    Name = "Destroy",
    Default = Enum.KeyCode.J,
    Hold = false,
    Callback = function()
        OrionLib:Destroy()
    end    
})


-- Update dropdown when players join/leave
game.Players.PlayerAdded:Connect(function()
    PlayerDropdown:Refresh(GetPlayerNames(), true)
end)

game.Players.PlayerRemoving:Connect(function()
    PlayerDropdown:Refresh(GetPlayerNames(), true)
end)

-- Function to send a message
local function say(str)
    str = tostring(str)
    if not isLegacyChat then
        TextChatService.TextChannels.RBXGeneral:SendAsync(str)
    else
        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(str, "All")
    end
end

if not isLegacyChat then
    -- New chat system
    local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
    if ch then
        ch.MessageReceived:Connect(function(m)
            local sender = m.TextSource and m.TextSource.Name or "System"
            local text = m.Text

            -- Only trigger when RECEIVED from target user
            if sender == targetUsername and sender ~= localPlayer.Name then
                -- Store in variables
                local receivedUsername = sender
                local receivedMessage = text
                if OrionLib.Flags["CopyToggle"].Value then
                    print("Received from:", receivedUsername, "Message:", receivedMessage)
                    say(receivedMessage) -- Example action
                end
            end
        end)
    end
else
    -- Legacy chat system
    local ev = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("OnMessageDoneFiltering")
    ev.OnClientEvent:Connect(function(d)
        local sender = d.FromSpeaker
        local text = d.Message

        if sender == targetUsername and sender ~= localPlayer.Name then
            local receivedUsername = sender
            local receivedMessage = text
            if OrionLib.Flags["CopyToggle"].Value then
                print("Received from:", receivedUsername, "Message:", receivedMessage)
                say(receivedMessage) -- Example action
            end
        end
    end)
end

local function onRenderStepped()
    Chr = Workspace:FindFirstChild(Plr.Name)
    if OrionLib.Flags["CopyToggle"].Value then
        if Chr then
            Chr.Humanoid:Move(targetHumanoid.MoveDirection)
            Chr.Humanoid.WalkSpeed = targetHumanoid.WalkSpeed
            Chr.Humanoid.Jump = targetHumanoid.Jump
            Chr.Humanoid.Sit = targetHumanoid.Sit
            for i,tool in pairs(targetHumanoid.Parent:GetChildren()) do
                if tool and tool:IsA("Tool") then
                    obj = Plr.Backpack:FindFirstChild(tool.Name)
                    if obj then
                        Plr.Backpack[tool.Name].Parent = Chr
                    else
                        for i,tool in pairs(Chr:GetChildren()) do
                            if tool and tool:IsA("Tool") then
                                tool.Parent = Plr.Backpack
                            end
                        end
                    end
                else
                    for i,tool in pairs(Chr:GetChildren()) do
                        if tool and tool:IsA("Tool") then
                            tool.Parent = Plr.Backpack
                        end
                    end
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(onRenderStepped)
OrionLib:Init()
