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
-- TEAM CHECK (SHARED)
-- =====================================================

local function IsEnemy(player)
    if not player or player == LocalPlayer then
        return false
    end

    if LocalPlayer.Team and player.Team then
        return player.Team ~= LocalPlayer.Team
    end

    if LocalPlayer.TeamColor and player.TeamColor then
        return player.TeamColor ~= LocalPlayer.TeamColor
    end

    return true
end

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
-- ESP STABLE CORE V5 (NO MEMORY LEAK)
-- =====================================================

local Camera = workspace.CurrentCamera

local ESPEnabled = false
local ESPCache = {}
local ESPConnection = nil

-- ใช้ IsEnemy ตัวบนของไฟล์เท่านั้น (ห้ามมีซ้ำ)

-- =========================
-- CREATE DRAW OBJECT
-- =========================
local function CreateDrawings(player)
    if ESPCache[player] then return end

    local box = Drawing.new("Square")
    box.Thickness = 1.5
    box.Filled = false
    box.Visible = false

    local name = Drawing.new("Text")
    name.Size = 13
    name.Center = true
    name.Outline = true
    name.Visible = false

    local health = Drawing.new("Square")
    health.Filled = true
    health.Thickness = 0
    health.Visible = false

    ESPCache[player] = {
        Box = box,
        Name = name,
        Health = health
    }
end

-- =========================
-- REMOVE DRAW OBJECT
-- =========================
local function RemoveDrawings(player)
    if ESPCache[player] then
        for _,v in pairs(ESPCache[player]) do
            v:Remove()
        end
        ESPCache[player] = nil
    end
end

-- =========================
-- UPDATE LOOP (1 CONNECTION ONLY)
-- =========================
local function StartESP()
    if ESPConnection then return end

    ESPConnection = RunService.RenderStepped:Connect(function()

        for _,player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then

                if not ESPCache[player] then
                    CreateDrawings(player)
                end

                local drawings = ESPCache[player]
                local box = drawings.Box
                local name = drawings.Name
                local health = drawings.Health

                if not ESPEnabled
                or not player.Character
                or not player.Character:FindFirstChild("HumanoidRootPart")
                or not player.Character:FindFirstChild("Humanoid")
                or player.Character.Humanoid.Health <= 0
                or not IsEnemy(player) then

                    box.Visible = false
                    name.Visible = false
                    health.Visible = false
                    continue
                end

                local root = player.Character.HumanoidRootPart
                local hum = player.Character.Humanoid

                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if not onScreen then
                    box.Visible = false
                    name.Visible = false
                    health.Visible = false
                    continue
                end

                local scale = 1 / (pos.Z * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 100
                local width = 28 * scale
                local height = 44 * scale

                local color = Color3.fromRGB(255,0,0)

                -- BOX
                box.Size = Vector2.new(width, height)
                box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
                box.Color = color
                box.Visible = true

                -- NAME
                name.Text = player.Name
                name.Position = Vector2.new(pos.X, pos.Y - height/2 - 13)
                name.Color = color
                name.Visible = true

                -- HEALTH BAR (VERTICAL)
                local hpPercent = hum.Health / hum.MaxHealth
                local barHeight = height * hpPercent

                health.Size = Vector2.new(4, barHeight)
                health.Position = Vector2.new(
                    pos.X - width/2 - 6,
                    pos.Y + height/2 - barHeight
                )
                health.Color = Color3.fromRGB(0,255,0)
                health.Visible = true
            end
        end
    end)
end

-- =========================
-- CLEAN WHEN PLAYER LEAVE
-- =========================
Players.PlayerRemoving:Connect(function(player)
    RemoveDrawings(player)
end)

-- =========================
-- START LOOP
-- =========================
StartESP()

-- =========================
-- TOGGLE
-- =========================
PlayerTab:CreateToggle({
    Name = "ESP Enemy Only",
    CurrentValue = false,
    Callback = function(v)
        ESPEnabled = v
    end
})

-- =====================================================
-- HITBOX EXPANDER V4 (STABLE LOOP FIX)
-- =====================================================

local HitboxEnabled = false
local HitboxVisible = true
local HitboxSize = 6
local HitboxObjects = {}

local function CreateHitbox(player)
    if not player.Character then return end
    if not IsEnemy(player) then return end

    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if not HitboxObjects[player] then
        local box = Instance.new("BoxHandleAdornment")
        box.Adornee = root
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Parent = root
        HitboxObjects[player] = box
    end

    local box = HitboxObjects[player]
    box.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
    box.Color3 = Color3.fromRGB(255,0,0)
    box.Transparency = HitboxVisible and 0.4 or 1
end

local function RemoveHitbox(player)
    if HitboxObjects[player] then
        HitboxObjects[player]:Destroy()
        HitboxObjects[player] = nil
    end
end

-- Loop อัปเดตทุก 1 วิ ลดโหลด
task.spawn(function()
    while true do
        task.wait(1)

        for _,player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if HitboxEnabled and IsEnemy(player) then
                    CreateHitbox(player)
                else
                    RemoveHitbox(player)
                end
            end
        end
    end
end)

PlayerTab:CreateToggle({
    Name = "Hitbox Expander (Enemy)",
    CurrentValue = false,
    Callback = function(v)
        HitboxEnabled = v
    end
})

PlayerTab:CreateToggle({
    Name = "Show Hitbox",
    CurrentValue = true,
    Callback = function(v)
        HitboxVisible = v
    end
})

PlayerTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {4, 12},
    Increment = 1,
    CurrentValue = 6,
    Callback = function(v)
        HitboxSize = v
    end
})

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
