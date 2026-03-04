-- =====================================================
-- N-HUB | Rayfield (Sirius CDN)
-- Universal Version
-- =====================================================

-- LOAD RAYFIELD (Stable CDN)
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- CREATE WINDOW
local Window = Rayfield:CreateWindow({
   Name = "N-HUB | Universal",
   LoadingTitle = "N-HUB",
   LoadingSubtitle = "Rayfield Edition",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "NHub",
      FileName = "Universal"
   },
   KeySystem = false
})

-- SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

-- =====================================================
-- PLAYER TAB
-- =====================================================

local PlayerTab = Window:CreateTab("Player", 4483362458)

-- WalkSpeed
PlayerTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 200},
   Increment = 1,
   CurrentValue = 16,
   Callback = function(Value)
      local char = LocalPlayer.Character
      if char and char:FindFirstChild("Humanoid") then
         char.Humanoid.WalkSpeed = Value
      end
   end,
})

-- God Mode
PlayerTab:CreateToggle({
   Name = "God Mode",
   CurrentValue = false,
   Callback = function(Value)
      local char = LocalPlayer.Character
      if not char then return end
      local hum = char:FindFirstChildOfClass("Humanoid")
      if not hum then return end

      if Value then
         hum.MaxHealth = math.huge
         hum.Health = math.huge

         hum:GetPropertyChangedSignal("Health"):Connect(function()
            if hum.Health < hum.MaxHealth then
               hum.Health = hum.MaxHealth
            end
         end)
      else
         hum.MaxHealth = 100
         hum.Health = 100
      end
   end,
})

-- JumpPower
PlayerTab:CreateSlider({
   Name = "JumpPower",
   Range = {50, 200},
   Increment = 1,
   CurrentValue = 50,
   Callback = function(Value)
      local char = LocalPlayer.Character
      if char and char:FindFirstChild("Humanoid") then
         char.Humanoid.JumpPower = Value
      end
   end,
})

-- Fly Speed Slider
PlayerTab:CreateSlider({
   Name = "Fly Speed",
   Range = {20, 200},
   Increment = 5,
   CurrentValue = 60,
   Callback = function(Value)
      flySpeed = Value
   end,
})

-- Fly Toggle
PlayerTab:CreateToggle({
   Name = "Fly Mode",
   CurrentValue = false,
   Callback = function(Value)
      flying = Value

      local char = LocalPlayer.Character
      if not char then return end
      local hrp = char:FindFirstChild("HumanoidRootPart")
      if not hrp then return end

      if Value then
         bodyVelocity = Instance.new("BodyVelocity")
         bodyVelocity.MaxForce = Vector3.new(1e9,1e9,1e9)
         bodyVelocity.Velocity = Vector3.zero
         bodyVelocity.Parent = hrp

         bodyGyro = Instance.new("BodyGyro")
         bodyGyro.MaxTorque = Vector3.new(1e9,1e9,1e9)
         bodyGyro.CFrame = hrp.CFrame
         bodyGyro.Parent = hrp

         RunService.RenderStepped:Connect(function()
            if flying and bodyVelocity then
               local cam = workspace.CurrentCamera
               bodyGyro.CFrame = cam.CFrame

               local moveDir = Vector3.zero
               if UIS:IsKeyDown(Enum.KeyCode.W) then
                  moveDir += cam.CFrame.LookVector
               end
               if UIS:IsKeyDown(Enum.KeyCode.S) then
                  moveDir -= cam.CFrame.LookVector
               end
               if UIS:IsKeyDown(Enum.KeyCode.A) then
                  moveDir -= cam.CFrame.RightVector
               end
               if UIS:IsKeyDown(Enum.KeyCode.D) then
                  moveDir += cam.CFrame.RightVector
               end

               bodyVelocity.Velocity = moveDir * flySpeed
            end
         end)

      else
         if bodyVelocity then bodyVelocity:Destroy() end
         if bodyGyro then bodyGyro:Destroy() end
      end
   end,
})

-- Infinite Jump
local infJump = false
PlayerTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Callback = function(Value)
      infJump = Value
   end,
})

UIS.JumpRequest:Connect(function()
   if infJump then
      local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
      if hum then
         hum:ChangeState("Jumping")
      end
   end
end)

-- =====================================================
-- VISUAL TAB
-- =====================================================

local VisualTab = Window:CreateTab("Visual", 4483362458)

VisualTab:CreateToggle({
   Name = "Player ESP",
   CurrentValue = false,
   Callback = function(Value)
      for _,player in pairs(Players:GetPlayers()) do
         if player ~= LocalPlayer and player.Character then
            if Value then
               if not player.Character:FindFirstChild("NHubESP") then
                  local h = Instance.new("Highlight")
                  h.Name = "NHubESP"
                  h.FillColor = Color3.fromRGB(255,0,0)
                  h.Parent = player.Character
               end
            else
               if player.Character:FindFirstChild("NHubESP") then
                  player.Character.NHubESP:Destroy()
               end
            end
         end
      end
   end,
})

-- =====================================================
-- TELEPORT TAB
-- =====================================================

local TeleportTab = Window:CreateTab("Teleport", 4483362458)

local clickTP = false

TeleportTab:CreateToggle({
   Name = "CTRL + Click TP",
   CurrentValue = false,
   Callback = function(Value)
      clickTP = Value
   end,
})

UIS.InputBegan:Connect(function(input, gp)
   if clickTP and not gp then
      if input.UserInputType == Enum.UserInputType.MouseButton1
      and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
         local mouse = LocalPlayer:GetMouse()
         if mouse.Hit then
            LocalPlayer.Character:MoveTo(mouse.Hit.Position)
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
   end,
})

UtilityTab:CreateButton({
   Name = "Destroy UI",
   Callback = function()
      Rayfield:Destroy()
   end,
})

Rayfield:Notify({
   Title = "N-HUB Loaded",
   Content = "Universal Ready",
   Duration = 4
})
