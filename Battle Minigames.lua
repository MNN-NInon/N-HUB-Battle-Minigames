-- =====================================================
-- N-HUB | Universal V3 PRO
-- Stable • Black UI • Full Feature
-- =====================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
   Name = "N-HUB | Universal V3 PRO",
   LoadingTitle = "N-HUB",
   LoadingSubtitle = "Black Pro Edition",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "NHub",
      FileName = "UniversalV3PRO"
   },
   KeySystem = false
})

pcall(function()
    Rayfield:SetTheme("Dark")
end)

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

-- Character reference updater
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
end)

-- =====================================================
-- PLAYER TAB
-- =====================================================

local PlayerTab = Window:CreateTab("Player", 4483362458)

-- =====================================================
-- WALK SPEED (LOCK SYSTEM FIX)
-- =====================================================

local speedValue = 16
local speedEnabled = false
local speedConnection

-- ฟังก์ชันดักการเปลี่ยนค่า
local function hookWalkSpeed(hum)
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end

    speedConnection = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if speedEnabled and hum.WalkSpeed ~= speedValue then
            hum.WalkSpeed = speedValue
        end
    end)
end

-- Slider
PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        speedValue = v
        speedEnabled = true

        if Character then
            local hum = Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = v
                hookWalkSpeed(hum)
            end
        end
    end
})

-- รีฮุคตอนรีสปอน
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    local hum = char:WaitForChild("Humanoid")

    if speedEnabled then
        hum.WalkSpeed = speedValue
        hookWalkSpeed(hum)
    end
end)

-- JumpPower
PlayerTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 200},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(v)
        local hum = Character and Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end
})

-- Infinite Jump
local infJump = false
PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v)
        infJump = v
    end
})

UIS.JumpRequest:Connect(function()
    if infJump then
        local hum = Character and Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- =====================================================
-- FLY (Stable)
-- =====================================================

local flying = false
local flySpeed = 60
local flyBV, flyBG, flyConn

PlayerTab:CreateSlider({
    Name = "Fly Speed",
    Range = {20, 200},
    Increment = 5,
    CurrentValue = 60,
    Callback = function(v)
        flySpeed = v
    end
})

PlayerTab:CreateToggle({
    Name = "Fly Mode",
    CurrentValue = false,
    Callback = function(state)
        flying = state

        if not Character then return end
        local hrp = Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if state then
            flyBV = Instance.new("BodyVelocity", hrp)
            flyBG = Instance.new("BodyGyro", hrp)

            flyBV.MaxForce = Vector3.new(1e9,1e9,1e9)
            flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)

            flyConn = RunService.RenderStepped:Connect(function()
                if not flying then return end
                local cam = workspace.CurrentCamera
                flyBG.CFrame = cam.CFrame

                local dir = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end

                flyBV.Velocity = dir * flySpeed
            end)
        else
            if flyConn then flyConn:Disconnect() end
            if flyBV then flyBV:Destroy() end
            if flyBG then flyBG:Destroy() end
        end
    end
})

-- =====================================================
-- GOD MODE (Loop Protected)
-- =====================================================

local god = false

PlayerTab:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Callback = function(v)
        god = v
    end
})

RunService.Heartbeat:Connect(function()
    if god and Character then
        local hum = Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        end
    end
end)

-- =====================================================
-- NOCLIP
-- =====================================================

local noclip = false

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        noclip = v
    end
})

RunService.Stepped:Connect(function()
    if noclip and Character then
        for _,p in pairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end
end)

-- =====================================================
-- ADVANCED TEAM ESP (RESPAWN FIX)
-- =====================================================

local VisualTab = Window:CreateTab("Visual", 4483362458)

local espEnabled = false
local enemyOnly = true
local espConnections = {}

-- ลบ ESP
local function removeESP(player)
    if player.Character then
        local h = player.Character:FindFirstChild("NHubHighlight")
        if h then h:Destroy() end

        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bb = hrp:FindFirstChild("NHubBillboard")
            if bb then bb:Destroy() end
        end
    end

    if espConnections[player] then
        espConnections[player]:Disconnect()
        espConnections[player] = nil
    end
end

-- เช็คว่าเป็นศัตรูไหม
local function isEnemy(player)
    if not LocalPlayer.Team or not player.Team then
        return true
    end
    return player.Team ~= LocalPlayer.Team
end

-- สร้าง ESP
local function createESP(player)
    if player == LocalPlayer then return end
    if not player.Character then return end

    if enemyOnly and not isEnemy(player) then
        removeESP(player)
        return
    end

    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Highlight
    if not player.Character:FindFirstChild("NHubHighlight") then
        local h = Instance.new("Highlight")
        h.Name = "NHubHighlight"
        h.FillColor = Color3.fromRGB(255,0,0)
        h.FillTransparency = 0.5
        h.Parent = player.Character
    end

    -- Billboard
    if not hrp:FindFirstChild("NHubBillboard") then
        local bb = Instance.new("BillboardGui")
        bb.Name = "NHubBillboard"
        bb.Size = UDim2.new(0,200,0,50)
        bb.StudsOffset = Vector3.new(0,3,0)
        bb.AlwaysOnTop = true
        bb.Parent = hrp

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1,0,1,0)
        txt.BackgroundTransparency = 1
        txt.TextScaled = true
        txt.TextStrokeTransparency = 0
        txt.Font = Enum.Font.GothamBold
        txt.Parent = bb

        espConnections[player] = RunService.RenderStepped:Connect(function()
            if not espEnabled then return end
            if not player.Character or not Character then return end

            local myHRP = Character:FindFirstChild("HumanoidRootPart")
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")

            if myHRP and targetHRP then
                local dist = (myHRP.Position - targetHRP.Position).Magnitude
                txt.Text = player.Name.." | "..math.floor(dist).."m"
            end
        end)
    end
end

-- Toggle ESP
VisualTab:CreateToggle({
    Name = "Enemy ESP (Name + Distance)",
    CurrentValue = false,
    Callback = function(state)
        espEnabled = state

        if state then
            for _,plr in pairs(Players:GetPlayers()) do
                createESP(plr)
            end
        else
            for _,plr in pairs(Players:GetPlayers()) do
                removeESP(plr)
            end
        end
    end
})

-- รองรับ Player เข้าใหม่
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if espEnabled then
            createESP(player)
        end
    end)
end)

-- รองรับรีสปอน
for _,player in pairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if espEnabled then
            createESP(player)
        end
    end)
end
-- =====================================================
-- TELEPORT TAB
-- =====================================================

local TeleportTab = Window:CreateTab("Teleport", 4483362458)
local clickTP = false

TeleportTab:CreateToggle({
    Name = "CTRL + Click TP",
    CurrentValue = false,
    Callback = function(v)
        clickTP = v
    end
})

UIS.InputBegan:Connect(function(input, gp)
    if clickTP and not gp then
        if input.UserInputType == Enum.UserInputType.MouseButton1
        and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            local mouse = LocalPlayer:GetMouse()
            if mouse.Hit and Character then
                Character:MoveTo(mouse.Hit.Position)
            end
        end
    end
end)

-- =====================================================
-- UTILITY TAB
-- =====================================================

local UtilityTab = Window:CreateTab("Utility", 4483362458)

UtilityTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

UtilityTab:CreateButton({
    Name = "Anti AFK",
    Callback = function()
        LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end)
    end
})

UtilityTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Rayfield:Destroy()
    end
})

Rayfield:Notify({
    Title = "N-HUB V3 PRO Loaded",
    Content = "All Systems Ready 😈",
    Duration = 4
})
