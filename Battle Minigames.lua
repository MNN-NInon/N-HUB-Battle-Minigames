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
-- ESP V3 PRO FIX
-- Team Check Real + Vertical Health Bar
-- =====================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ESPEnabled = true
local ESPObjects = {}

-- สีทีม
local TEAM_COLOR = Color3.fromRGB(0,170,255)   -- ฟ้า
local ENEMY_COLOR = Color3.fromRGB(255,60,60)  -- แดง

-- เช็คว่าเป็นศัตรูจริงไหม
local function IsEnemy(player)
    if not player or player == LocalPlayer then
        return false
    end

    -- ถ้ามี Team system
    if LocalPlayer.Team and player.Team then
        return player.Team ~= LocalPlayer.Team
    end

    -- ถ้าใช้ TeamColor แทน
    if LocalPlayer.TeamColor and player.TeamColor then
        return player.TeamColor ~= LocalPlayer.TeamColor
    end

    return true
end

local function CreateESP(player)
    if ESPObjects[player] then return end

    ESPObjects[player] = {}

    local function SetupCharacter(char)
        local hum = char:WaitForChild("Humanoid")
        local root = char:WaitForChild("HumanoidRootPart")

        -- BOX
        local box = Drawing.new("Square")
        box.Thickness = 1
        box.Filled = false
        box.Visible = false

        -- NAME + DISTANCE
        local name = Drawing.new("Text")
        name.Size = 13
        name.Center = true
        name.Outline = true
        name.Visible = false

        -- VERTICAL HEALTH BAR BACK
        local hpBack = Drawing.new("Square")
        hpBack.Filled = true
        hpBack.Color = Color3.new(0,0,0)
        hpBack.Visible = false

        -- VERTICAL HEALTH BAR
        local hpBar = Drawing.new("Square")
        hpBar.Filled = true
        hpBar.Visible = false

        ESPObjects[player] = {
            box = box,
            name = name,
            hpBack = hpBack,
            hpBar = hpBar
        }

        RunService.RenderStepped:Connect(function()
            if not ESPEnabled then
                box.Visible = false
                name.Visible = false
                hpBack.Visible = false
                hpBar.Visible = false
                return
            end

            if not char or not char.Parent then
                box.Visible = false
                name.Visible = false
                hpBack.Visible = false
                hpBar.Visible = false
                return
            end

            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(root.Position)
            if onScreen then

                local distance = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)

                local color = IsEnemy(player) and ENEMY_COLOR or TEAM_COLOR

               -- SCALE FIX (ไม่บวม)
             local scale = math.clamp(1200 / pos.Z, 0.8, 1.6)
             local width = 28 * scale
             local height = 48 * scale
               
                -- BOX
                box.Size = Vector2.new(width, height)
                box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
                box.Color = color
                box.Visible = true

                -- NAME
                name.Text = player.Name.." ["..distance.."m]"
                name.Position = Vector2.new(pos.X, pos.Y - height/2 - 14)
                name.Color = color
                name.Visible = true

                -- HEALTH %
                local hpPercent = hum.Health / hum.MaxHealth

                -- BACKGROUND
                hpBack.Size = Vector2.new(4, height)
                hpBack.Position = Vector2.new(pos.X - width/2 - 8, pos.Y - height/2)
                hpBack.Visible = true

                -- HP BAR (แนวตั้ง)
                hpBar.Size = Vector2.new(4, height * hpPercent)
                hpBar.Position = Vector2.new(
                    pos.X - width/2 - 8,
                    pos.Y - height/2 + (height - (height * hpPercent))
                )
                hpBar.Color = Color3.fromRGB(0,255,0)
                hpBar.Visible = true

            else
                box.Visible = false
                name.Visible = false
                hpBack.Visible = false
                hpBar.Visible = false
            end
        end)
    end

    if player.Character then
        SetupCharacter(player.Character)
    end

    player.CharacterAdded:Connect(function(char)
        SetupCharacter(char)
    end)
end

-- สร้าง ESP ให้ทุกคน
for _,plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        CreateESP(plr)
    end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then
        CreateESP(plr)
    end
end)

-- =====================================================
-- ESP TOGGLE
-- =====================================================

PlayerTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = true,
    Callback = function(v)
        ESPEnabled = v

        if not v then
            -- ซ่อนทั้งหมดทันที
            for _,esp in pairs(ESPObjects) do
                if esp.box then esp.box.Visible = false end
                if esp.name then esp.name.Visible = false end
                if esp.hpBack then esp.hpBack.Visible = false end
                if esp.hpBar then esp.hpBar.Visible = false end
            end
        end
    end
})

-- =====================================================
-- HITBOX EXPANDER V2 (ENEMY ONLY + SHOW/HIDE)
-- Stable + Respawn Safe
-- =====================================================

local HitboxEnabled = false
local HitboxVisible = true
local HitboxSize = 6

local OriginalData = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- เช็คศัตรู
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

-- ขยาย Hitbox
local function ApplyHitbox(player)
    if not player.Character then return end
    if not IsEnemy(player) then return end

    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- เก็บค่าเดิมครั้งแรก
    if not OriginalData[player] then
        OriginalData[player] = {
            Size = root.Size,
            Transparency = root.Transparency,
            Material = root.Material
        }
    end

    root.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
    root.CanCollide = false

    if HitboxVisible then
        root.Transparency = 0.4
        root.Material = Enum.Material.Neon
        root.Color = Color3.fromRGB(255,0,0)
    else
        root.Transparency = 1
        root.Material = Enum.Material.Plastic
    end
end

-- คืนค่าเดิม
local function ResetHitbox(player)
    if not player.Character then return end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if OriginalData[player] then
        root.Size = OriginalData[player].Size
        root.Transparency = OriginalData[player].Transparency
        root.Material = OriginalData[player].Material
    end
end

-- Loop คุมเสถียร
RunService.Heartbeat:Connect(function()
    if HitboxEnabled then
        for _,player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                ApplyHitbox(player)
            end
        end
    end
end)

-- Toggle เปิด/ปิดขยาย
PlayerTab:CreateToggle({
    Name = "Hitbox Expander (Enemy)",
    CurrentValue = false,
    Callback = function(v)
        HitboxEnabled = v

        if not v then
            for _,player in pairs(Players:GetPlayers()) do
                ResetHitbox(player)
            end
        end
    end
})

-- Toggle มองเห็น
PlayerTab:CreateToggle({
    Name = "Show Hitbox",
    CurrentValue = true,
    Callback = function(v)
        HitboxVisible = v
    end
})

-- Slider ขนาด
PlayerTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {4, 12},
    Increment = 1,
    CurrentValue = 6,
    Callback = function(v)
        HitboxSize = v
    end
})

-- รองรับเกิดใหม่
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if HitboxEnabled then
            ApplyHitbox(player)
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
