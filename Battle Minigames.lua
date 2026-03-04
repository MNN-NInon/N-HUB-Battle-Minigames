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
-- ESP V3.6 FIXED
-- Team Detect Improved • Smaller UI • Clean
-- =====================================================

local VisualTab = Window:CreateTab("Visual", 4483362458)

local espEnabled = false
local espConnections = {}

-- ===== TEAM CHECK (หลายระบบ) =====
local function isEnemy(player)
    if player == LocalPlayer then return false end

    -- เช็ค Team ปกติ
    if LocalPlayer.Team and player.Team then
        return player.Team ~= LocalPlayer.Team
    end

    -- เช็ค TeamColor
    if LocalPlayer.TeamColor and player.TeamColor then
        return player.TeamColor ~= LocalPlayer.TeamColor
    end

    -- ถ้าเกมไม่มีระบบทีมจริง
    return true
end

-- ===== REMOVE =====
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

-- ===== CREATE =====
local function createESP(player)
    if player == LocalPlayer then return end
    if not player.Character then return end

    local char = player.Character
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    removeESP(player)

    local enemy = isEnemy(player)

    local teamColor = enemy
        and Color3.fromRGB(255,0,0)
        or Color3.fromRGB(0,150,255)

    -- BOX
    local highlight = Instance.new("Highlight")
    highlight.Name = "NHubHighlight"
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0
    highlight.FillColor = teamColor
    highlight.OutlineColor = teamColor
    highlight.Parent = char

    -- BILLBOARD (เล็กลง)
    local bb = Instance.new("BillboardGui")
    bb.Name = "NHubBillboard"
    bb.Size = UDim2.new(0,140,0,40)
    bb.StudsOffset = Vector3.new(0,2.5,0)
    bb.AlwaysOnTop = true
    bb.Parent = hrp

    -- NAME
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1,0,0.6,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextScaled = false
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextColor3 = teamColor
    nameLabel.Parent = bb

    -- HEALTH BG
    local healthBG = Instance.new("Frame")
    healthBG.Size = UDim2.new(1,0,0.2,0)
    healthBG.Position = UDim2.new(0,0,0.7,0)
    healthBG.BackgroundColor3 = Color3.fromRGB(40,40,40)
    healthBG.BorderSizePixel = 0
    healthBG.Parent = bb

    -- HEALTH FILL
    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1,0,1,0)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBG

    -- UPDATE LOOP
    espConnections[player] = RunService.RenderStepped:Connect(function()
        if not espEnabled then return end
        if not player.Character or not Character then return end

        local myHRP = Character:FindFirstChild("HumanoidRootPart")
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        local targetHum = player.Character:FindFirstChildOfClass("Humanoid")

        if myHRP and targetHRP and targetHum then
            local dist = (myHRP.Position - targetHRP.Position).Magnitude
            nameLabel.Text = player.Name.." | "..math.floor(dist).."m"

            local hpPercent = targetHum.Health / targetHum.MaxHealth
            healthFill.Size = UDim2.new(hpPercent,0,1,0)

            if hpPercent > 0.5 then
                healthFill.BackgroundColor3 = Color3.fromRGB(0,255,0)
            elseif hpPercent > 0.25 then
                healthFill.BackgroundColor3 = Color3.fromRGB(255,170,0)
            else
                healthFill.BackgroundColor3 = Color3.fromRGB(255,0,0)
            end
        end
    end)
end

-- ===== TOGGLE =====
VisualTab:CreateToggle({
    Name = "Team ESP PRO (Fixed)",
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

-- ===== RESPAWN SUPPORT =====
for _,player in pairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if espEnabled then
            createESP(player)
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if espEnabled then
            createESP(player)
        end
    end)
end)

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
