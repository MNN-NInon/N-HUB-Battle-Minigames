-- =====================================================
-- N-HUB | Universal V3 PRO
-- Stable • Black UI • Full Feature + Auto Save Config
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

-- =====================================================
-- AUTO SAVE CONFIG SYSTEM (Proxy Metatable)
-- พอค่าไหนใน Config เปลี่ยน → SaveConfig ทันทีอัตโนมัติ
-- ไม่ต้องเขียน SaveConfig ในทุก callback อีกต่อไป
-- =====================================================

local ConfigFolder = "NHub"
local ConfigFile   = "UniversalV3PRO.json"
local ConfigPath   = ConfigFolder .. "/" .. ConfigFile
local HttpService  = game:GetService("HttpService")

-- ค่า default จริงๆ เก็บใน _raw
local _raw = {
	WalkSpeed       = 16,
	JumpPower       = 50,
	InfiniteJump    = false,
	Noclip          = false,
	ESPEnabled      = true,
	ClickTP         = false,
	HitboxSize      = 5,
	HitboxEnabled   = false,
	BlinkEnabled    = false,
	BlinkRange      = 20,
	AutoAttack      = false,
	AutoAttackRate  = 0.1,
	AutoAttackRange = 15,
	FastAttack      = false,
	FastAttackDelay = 5,
	PosSpoof        = false,
	SpoofRange      = 3,
	AutoSkill       = false,
	SkillDelay      = 10,
	KillAura        = false,
	KillAuraRange   = 20,
	KillAuraRate    = 3,
}

local function EnsureFolder()
	if not isfolder(ConfigFolder) then
		makefolder(ConfigFolder)
	end
end

local isSaving = false
local function SaveConfig()
	if isSaving then return end
	isSaving = true
	task.defer(function()
		local ok, err = pcall(function()
			EnsureFolder()
			writefile(ConfigPath, HttpService:JSONEncode(_raw))
		end)
		if not ok then warn("[N-HUB] SaveConfig failed: "..tostring(err)) end
		isSaving = false
	end)
end

-- โหลดก่อน Proxy ถูกสร้าง → _raw มีค่าถูกต้องก่อน UI อ่าน
local function LoadConfig()
	local ok, err = pcall(function()
		EnsureFolder()
		if isfile(ConfigPath) then
			local data = readfile(ConfigPath)
			print("[N-HUB] Raw file: "..tostring(data):sub(1,100))
			local decoded = HttpService:JSONDecode(data)
			for k, v in pairs(decoded) do
				_raw[k] = v
			end
			print("[N-HUB] Config loaded ✅ WalkSpeed="..tostring(_raw.WalkSpeed))
		else
			print("[N-HUB] No config file found at: "..ConfigPath)
		end
	end)
	if not ok then warn("[N-HUB] LoadConfig failed: "..tostring(err)) end
end

-- โหลดก่อนสร้าง Proxy และ UI ทั้งหมด
LoadConfig()

-- Proxy: ทุกครั้งที่ Config.xxx = yyy → SaveConfig อัตโนมัติ
local Config = setmetatable({}, {
	__index = function(_, k)
		return _raw[k]
	end,
	__newindex = function(_, k, v)
		_raw[k] = v
		SaveConfig()  -- auto save ทันที ไม่เช็ค ~= เพื่อไม่พลาด
	end,
})

-- Auto save ทุก 60 วินาที (สำรอง)
task.spawn(function()
	while task.wait(60) do
		SaveConfig()
	end
end)

-- =====================================================
-- Character reference updater
-- =====================================================

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
end)

-- (ApplyConfig อยู่ด้านล่างหลัง declare ตัวแปรทั้งหมดแล้ว)

-- =====================================================
-- PLAYER TAB
-- =====================================================

local PlayerTab = Window:CreateTab("Player", 4483362458)

-- =====================================================
-- WALK SPEED (LOCK SYSTEM FIX)
-- =====================================================

local speedValue = Config.WalkSpeed
local speedEnabled = speedValue ~= 16
local speedConnection

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

PlayerTab:CreateSlider({
	Name = "WalkSpeed",
	Range = {16, 200},
	Increment = 1,
	CurrentValue = Config.WalkSpeed,  -- โหลดค่าเดิม
	Callback = function(v)
		speedValue = v
		speedEnabled = true
		Config.WalkSpeed = v

		if Character then
			local hum = Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = v
				hookWalkSpeed(hum)
			end
		end
	end
})

-- =====================================================
-- JUMP POWER
-- =====================================================

PlayerTab:CreateSlider({
	Name = "JumpPower",
	Range = {50, 500},
	Increment = 5,
	CurrentValue = Config.JumpPower,
	Callback = function(v)
		Config.JumpPower = v
		local hum = Character and Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.JumpPower = v
			hum.JumpHeight = v / 10  -- รองรับเกมที่ใช้ JumpHeight แทน
			hum.UseJumpPower = true   -- บังคับให้ใช้ JumpPower
		end
	end
})

-- =====================================================
-- INFINITE JUMP
-- =====================================================

local infJump = Config.InfiniteJump

PlayerTab:CreateToggle({
	Name = "Infinite Jump",
	CurrentValue = Config.InfiniteJump,
	Callback = function(v)
		infJump = v
		Config.InfiniteJump = v
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
-- =====================================================
-- NOCLIP
-- =====================================================

local noclip = Config.Noclip

PlayerTab:CreateToggle({
	Name = "Noclip",
	CurrentValue = Config.Noclip,  -- โหลดค่าเดิม
	Callback = function(v)
		noclip = v
		Config.Noclip = v
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

local ESPEnabled = Config.ESPEnabled
local ESPObjects = {}

local TEAM_COLOR  = Color3.fromRGB(0,170,255)
local ENEMY_COLOR = Color3.fromRGB(255,60,60)

local function IsEnemy(player)
	if not player or player == LocalPlayer then return false end
	if LocalPlayer.Team and player.Team then
		return player.Team ~= LocalPlayer.Team
	end
	if LocalPlayer.TeamColor and player.TeamColor then
		return player.TeamColor ~= LocalPlayer.TeamColor
	end
	return true
end

local function CreateESP(player)
	if ESPObjects[player] then return end
	ESPObjects[player] = {}

	local function SetupCharacter(char)
		local hum  = char:WaitForChild("Humanoid")
		local root = char:WaitForChild("HumanoidRootPart")

		local box    = Drawing.new("Square")
		box.Thickness = 1
		box.Filled    = false
		box.Visible   = false

		local name = Drawing.new("Text")
		name.Size   = 13
		name.Center = true
		name.Outline = true
		name.Visible = false

		local hpBack = Drawing.new("Square")
		hpBack.Filled  = true
		hpBack.Color   = Color3.new(0,0,0)
		hpBack.Visible = false

		local hpBar = Drawing.new("Square")
		hpBar.Filled  = true
		hpBar.Visible = false

		ESPObjects[player] = { box=box, name=name, hpBack=hpBack, hpBar=hpBar }

		RunService.RenderStepped:Connect(function()
			if not ESPEnabled then
				box.Visible=false; name.Visible=false
				hpBack.Visible=false; hpBar.Visible=false
				return
			end
			if not char or not char.Parent then
				box.Visible=false; name.Visible=false
				hpBack.Visible=false; hpBar.Visible=false
				return
			end

			local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(root.Position)
			if onScreen then
				local dist  = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)
				local color = IsEnemy(player) and ENEMY_COLOR or TEAM_COLOR
				local scale = math.clamp(1200 / pos.Z, 0.8, 1.6)
				local width = 28 * scale
				local height = 48 * scale

				box.Size     = Vector2.new(width, height)
				box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
				box.Color    = color
				box.Visible  = true

				name.Text     = player.Name.." ["..dist.."m]"
				name.Position = Vector2.new(pos.X, pos.Y - height/2 - 14)
				name.Color    = color
				name.Visible  = true

				local hpPercent = hum.Health / hum.MaxHealth
				hpBack.Size     = Vector2.new(4, height)
				hpBack.Position = Vector2.new(pos.X - width/2 - 8, pos.Y - height/2)
				hpBack.Visible  = true

				hpBar.Size     = Vector2.new(4, height * hpPercent)
				hpBar.Position = Vector2.new(pos.X - width/2 - 8, pos.Y - height/2 + (height - height * hpPercent))
				hpBar.Color    = Color3.fromRGB(0,255,0)
				hpBar.Visible  = true
			else
				box.Visible=false; name.Visible=false
				hpBack.Visible=false; hpBar.Visible=false
			end
		end)
	end

	if player.Character then SetupCharacter(player.Character) end
	player.CharacterAdded:Connect(function(char) SetupCharacter(char) end)
end

for _,plr in pairs(Players:GetPlayers()) do
	if plr ~= LocalPlayer then CreateESP(plr) end
end

Players.PlayerAdded:Connect(function(plr)
	if plr ~= LocalPlayer then CreateESP(plr) end
end)

-- =====================================================
-- ESP TAB
-- =====================================================

local ESPTab = Window:CreateTab("ESP", 4483362458)

ESPTab:CreateToggle({
	Name = "ESP",
	CurrentValue = Config.ESPEnabled,
	Callback = function(v)
		ESPEnabled = v
		Config.ESPEnabled = v
		-- ซ่อน/แสดง drawing ทันที
		if not v then
			for _, obj in pairs(ESPObjects) do
				if obj.box   then obj.box.Visible   = false end
				if obj.name  then obj.name.Visible  = false end
				if obj.hpBack then obj.hpBack.Visible = false end
				if obj.hpBar  then obj.hpBar.Visible  = false end
			end
		end
		Rayfield:Notify({
			Title = "ESP",
			Content = v and "เปิดแล้ว 🟢" or "ปิดแล้ว 🔴",
			Duration = 2
		})
	end
})

-- =====================================================
-- COMBAT TAB
-- =====================================================

local CombatTab = Window:CreateTab("Combat", 4483362458)

-- =====================================================
-- HITBOX EXPANDER
-- วิธีทำงาน: ขยาย HitboxSize ของ HumanoidRootPart
-- ศัตรูทุกคนในเกม จะโดนตีได้ในระยะไกลขึ้น
-- =====================================================

local hitboxEnabled = Config.HitboxEnabled
local hitboxSize    = Config.HitboxSize
local hitboxOriginals = {}  -- เก็บขนาดเดิมไว้คืนค่า

local function ApplyHitbox()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				-- เก็บค่าเดิมครั้งแรก
				if not hitboxOriginals[plr] then
					hitboxOriginals[plr] = hrp.Size
				end
				hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
			end
		end
	end
end

local function RemoveHitbox()
	for plr, origSize in pairs(hitboxOriginals) do
		if plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.Size = origSize
			end
		end
	end
	hitboxOriginals = {}
end

-- Loop ใส่ hitbox ตลอด (รองรับ respawn ด้วย)
RunService.Heartbeat:Connect(function()
	if hitboxEnabled then
		ApplyHitbox()
	end
end)

CombatTab:CreateToggle({
	Name = "Hitbox Expander",
	CurrentValue = Config.HitboxEnabled,
	Callback = function(v)
		hitboxEnabled = v
		Config.HitboxEnabled = v
		if not v then
			RemoveHitbox()
		end
		Rayfield:Notify({
			Title = "Hitbox Expander",
			Content = v and ("เปิดแล้ว 🟢 ขนาด: "..hitboxSize) or "ปิดแล้ว 🔴 คืนค่าเดิม",
			Duration = 3
		})
	end
})

CombatTab:CreateSlider({
	Name = "Hitbox Size",
	Range = {5, 50},
	Increment = 1,
	CurrentValue = Config.HitboxSize,
	Callback = function(v)
		hitboxSize = v
		Config.HitboxSize = v
	end
})

-- =====================================================
-- AUTO SKILL Q
-- ใช้หลาย method รองรับ XENO และ executor อื่นๆ
-- เช็คว่าพิมพ์แชทอยู่ไหมก่อนกด
-- =====================================================

local autoSkill  = false
local skillDelay = 1.0
local skillConn  = nil

local function IsChatFocused()
	return UIS:GetFocusedTextBox() ~= nil
end

local function PressQ()
	-- วิธีที่ 1: XENO / executor ที่รองรับ sendinput
	pcall(function()
		sendinput({type = "keyboard", keyCode = Enum.KeyCode.Q, inputType = Enum.UserInputType.Keyboard, inputState = Enum.UserInputState.Begin})
		task.wait(0.05)
		sendinput({type = "keyboard", keyCode = Enum.KeyCode.Q, inputType = Enum.UserInputType.Keyboard, inputState = Enum.UserInputState.End})
	end)

	-- วิธีที่ 2: VirtualInputManager (fallback)
	pcall(function()
		game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Q, false, game)
		task.wait(0.05)
		game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Q, false, game)
	end)

	-- วิธีที่ 3: keypress/keyrelease (fallback)
	pcall(function()
		keypress(0x51)
		task.wait(0.05)
		keyrelease(0x51)
	end)
end

local function StartAutoSkill()
	if skillConn then task.cancel(skillConn) end
	skillConn = task.spawn(function()
		while autoSkill do
			if Character and not IsChatFocused() then
				local hum = Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					PressQ()
				end
			end
			task.wait(skillDelay)
		end
	end)
end

local function StopAutoSkill()
	autoSkill = false
end

CombatTab:CreateToggle({
	Name = "Auto Skill  [Q อัตโนมัติ]",
	CurrentValue = Config.AutoSkill or false,
	Callback = function(v)
		autoSkill = v
		Config.AutoSkill = v
		if v then
			StartAutoSkill()
			Rayfield:Notify({
				Title = "Auto Skill ⚡",
				Content = "เปิดแล้ว 🟢  กด Q ทุก "..skillDelay.."s",
				Duration = 3
			})
		else
			StopAutoSkill()
			Rayfield:Notify({
				Title = "Auto Skill",
				Content = "ปิดแล้ว 🔴",
				Duration = 2
			})
		end
	end
})

CombatTab:CreateSlider({
	Name = "Skill Cooldown (วินาที)",
	Range = {1, 30},
	Increment = 1,
	CurrentValue = Config.SkillDelay or 10,
	Callback = function(v)
		skillDelay = v
		Config.SkillDelay = v
	end
})

-- =====================================================
-- BLINK TP (ระยะประชิด Combat)
-- กด Q = กระโดดไปหาศัตรูที่ใกล้ที่สุดทันที
-- กด E = กระโดดไปหลังศัตรู (backstab position)
-- =====================================================

local blinkEnabled = Config.BlinkEnabled
local blinkRange   = Config.BlinkRange

-- หาศัตรูที่ใกล้ที่สุด
local function GetNearestEnemy()
	local nearest = nil
	local minDist = math.huge

	if not Character then return nil end
	local myRoot = Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
			local root = plr.Character:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				local dist = (myRoot.Position - root.Position).Magnitude
				if dist < minDist then
					minDist = dist
					nearest = plr
				end
			end
		end
	end
	return nearest
end

CombatTab:CreateToggle({
	Name = "Blink TP  [Z = หน้า | X = หลัง]",
	CurrentValue = Config.BlinkEnabled,
	Callback = function(v)
		blinkEnabled = v
		Config.BlinkEnabled = v
		Rayfield:Notify({
			Title = "Blink TP",
			Content = v and "เปิดแล้ว 🟢  Z=หน้า  X=หลัง" or "ปิดแล้ว 🔴",
			Duration = 3
		})
	end
})

CombatTab:CreateSlider({
	Name = "Blink Range (offset)",
	Range = {3, 30},
	Increment = 1,
	CurrentValue = Config.BlinkRange,
	Callback = function(v)
		blinkRange = v
		Config.BlinkRange = v
	end
})

-- Input handler สำหรับ Blink
UIS.InputBegan:Connect(function(input, gp)
	if gp or not blinkEnabled then return end
	if not Character then return end
	local myRoot = Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end

	local enemy = GetNearestEnemy()
	if not enemy or not enemy.Character then return end
	local eRoot = enemy.Character:FindFirstChild("HumanoidRootPart")
	if not eRoot then return end

	-- Z = เทเลพอร์ตไปด้านหน้าศัตรู (เข้าหา)
	if input.KeyCode == Enum.KeyCode.Z then
		local dir = (eRoot.CFrame.LookVector)
		local targetPos = eRoot.Position + dir * blinkRange + Vector3.new(0, 0, 0)
		myRoot.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.pi, 0)
		Rayfield:Notify({
			Title = "Blink TP",
			Content = "⚔️ เข้าหา "..enemy.Name,
			Duration = 1
		})

	-- X = เทเลพอร์ตไปด้านหลังศัตรู (backstab)
	elseif input.KeyCode == Enum.KeyCode.X then
		local dir = (-eRoot.CFrame.LookVector)
		local targetPos = eRoot.Position + dir * blinkRange
		myRoot.CFrame = CFrame.new(targetPos) * CFrame.fromEulerAnglesXYZ(0, math.atan2(dir.X, dir.Z), 0)
		Rayfield:Notify({
			Title = "Blink TP",
			Content = "🗡️ Backstab "..enemy.Name,
			Duration = 1
		})
	end
end)

-- =====================================================
-- AUTO ATTACK
-- จำลองคลิกซ้ายวนซ้ำ + หมุนหน้าไปหาศัตรูที่ใกล้ที่สุด
-- =====================================================

local autoAttack      = Config.AutoAttack
local autoAttackRate  = Config.AutoAttackRate
local autoAttackRange = Config.AutoAttackRange
local autoAttackConn  = nil
local lastAttackTime  = 0

local function StartAutoAttack()
	if autoAttackConn then autoAttackConn:Disconnect() end

	autoAttackConn = RunService.Heartbeat:Connect(function()
		if not autoAttack then return end
		if not Character then return end
		if IsChatFocused() then return end

		local myRoot = Character:FindFirstChild("HumanoidRootPart")
		local myHum  = Character:FindFirstChildOfClass("Humanoid")
		if not myRoot or not myHum or myHum.Health <= 0 then return end

		-- throttle ตาม attack rate
		local now = tick()
		if (now - lastAttackTime) < autoAttackRate then return end

		-- เก็บทุกคนในระยะ
		local targets = {}
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
				local root = plr.Character:FindFirstChild("HumanoidRootPart")
				if hum and root and hum.Health > 0 then
					local dist = (myRoot.Position - root.Position).Magnitude
					if dist <= autoAttackRange then
						table.insert(targets, root)
					end
				end
			end
		end

		if #targets > 0 then
			lastAttackTime = now

			local screenCenter = Vector2.new(
				workspace.CurrentCamera.ViewportSize.X / 2,
				workspace.CurrentCamera.ViewportSize.Y / 2
			)

			-- วนตีทีละคนในระยะ
			for _, targetRoot in pairs(targets) do
				-- หมุนหน้าไปหาเป้าแต่ละคน
				myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(
					targetRoot.Position.X,
					myRoot.Position.Y,
					targetRoot.Position.Z
				))

				VirtualUser:Button1Down(screenCenter, workspace.CurrentCamera.CFrame)
				task.wait(0.03)
				VirtualUser:Button1Up(screenCenter, workspace.CurrentCamera.CFrame)
				task.wait(0.03)
			end
		end
	end)
end

local function StopAutoAttack()
	if autoAttackConn then
		autoAttackConn:Disconnect()
		autoAttackConn = nil
	end
end

CombatTab:CreateToggle({
	Name = "Auto Attack  [ตีศัตรูใกล้สุดอัตโนมัติ]",
	CurrentValue = Config.AutoAttack,
	Callback = function(v)
		autoAttack = v
		Config.AutoAttack = v
		if v then
			StartAutoAttack()
			Rayfield:Notify({
				Title = "Auto Attack 🗡️",
				Content = "เปิดแล้ว 🟢  rate: "..autoAttackRate.."s  range: "..autoAttackRange.."st",
				Duration = 3
			})
		else
			StopAutoAttack()
			Rayfield:Notify({
				Title = "Auto Attack",
				Content = "ปิดแล้ว 🔴",
				Duration = 2
			})
		end
	end
})

-- ระยะโจมตี
CombatTab:CreateSlider({
	Name = "Attack Range (studs)",
	Range = {5, 60},
	Increment = 1,
	CurrentValue = Config.AutoAttackRange,
	Callback = function(v)
		autoAttackRange = v
		Config.AutoAttackRange = v
	end
})

-- =====================================================
-- FAST ATTACK (Click Spam + Tool Activation)
-- วิธีที่ 1: ส่ง MouseButton1 ถี่กว่า client ปกติ (bypass client cooldown)
-- วิธีที่ 2: fire Tool.Activated ตรงๆ ข้าม animation cooldown เลย
-- ทั้งสองวิธีทำงานพร้อมกัน ได้ผลกับเกมส่วนใหญ่
-- =====================================================

local fastAttackEnabled = false
local fastAttackDelay   = 0.05   -- วินาที/ครั้ง (default เร็วมาก)
local fastAttackConn    = nil

-- หา Tool (อาวุธ) ที่ถือออยู่ตอนนี้
local function GetEquippedTool()
	if not Character then return nil end
	for _, obj in pairs(Character:GetChildren()) do
		if obj:IsA("Tool") then
			return obj
		end
	end
	return nil
end

local function StartFastAttack()
	-- หยุด thread เก่าก่อน
	if fastAttackConn then
		task.cancel(fastAttackConn)
		fastAttackConn = nil
	end

	fastAttackConn = task.spawn(function()
		while fastAttackEnabled do
			pcall(function()
				if Character and not IsChatFocused() then
					local myHum = Character:FindFirstChildOfClass("Humanoid")
					if myHum and myHum.Health > 0 then
						local tool = GetEquippedTool()
						if tool then
							tool.Activated:Fire()
							for _, obj in pairs(tool:GetDescendants()) do
								if obj:IsA("RemoteEvent") and
									(obj.Name:lower():find("attack") or
									 obj.Name:lower():find("hit") or
									 obj.Name:lower():find("swing") or
									 obj.Name:lower():find("slash")) then
									obj:FireServer()
								end
							end
						end
					end
				end
			end)
			task.wait(fastAttackDelay)
		end
	end)
end

local function StopFastAttack()
	fastAttackEnabled = false
	if fastAttackConn then
		task.cancel(fastAttackConn)
		fastAttackConn = nil
	end
end

CombatTab:CreateToggle({
	Name = "Fast Attack  [Click Spam + Tool Fire]",
	CurrentValue = Config.FastAttack or false,
	Callback = function(v)
		fastAttackEnabled = v
		Config.FastAttack = v
		if v then
			StartFastAttack()
			Rayfield:Notify({
				Title = "Fast Attack ⚡",
				Content = "เปิดแล้ว 🟢  ส่ง input ทุก "..fastAttackDelay.."s",
				Duration = 3
			})
		else
			StopFastAttack()
			Rayfield:Notify({
				Title = "Fast Attack",
				Content = "ปิดแล้ว 🔴",
				Duration = 2
			})
		end
	end
})

-- ปรับความเร็ว: slider 1-10 → 0.01s - 0.10s
CombatTab:CreateSlider({
	Name = "Fast Attack Delay  (ต่ำ = เร็วสุด)",
	Range = {1, 10},
	Increment = 1,
	CurrentValue = Config.FastAttackDelay or 5,
	Callback = function(v)
		fastAttackDelay = v / 100
		Config.FastAttackDelay = v
	end
})

-- =====================================================
-- POSITION SPOOF (Fake Reach)
-- ตอนคลิกตี → ย้ายตัวเองเข้าหาศัตรูชั่วคราว 1 frame
-- server เห็นว่าอยู่ในระยะ → damage ผ่าน
-- client กลับมาที่เดิมทันที → ไม่เห็นขยับ
-- =====================================================

local posSpoof       = false
local spoofRange     = 3   -- offset ห่างจากศัตรู (studs)
local isSpoofing     = false

-- จับ input คลิกซ้าย
UIS.InputBegan:Connect(function(input, gp)
	if gp or not posSpoof then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if isSpoofing then return end

	if not Character then return end
	local myRoot = Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end

	-- หาศัตรูที่ใกล้ที่สุด
	local nearest, minDist = nil, math.huge
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
			local root = plr.Character:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				local d = (myRoot.Position - root.Position).Magnitude
				if d < minDist then
					minDist = d
					nearest = root
				end
			end
		end
	end

	if not nearest then return end

	isSpoofing = true
	local originalCF = myRoot.CFrame  -- เก็บ position เดิม

	-- คำนวณ position ที่อยู่ใกล้ศัตรู
	local dir = (nearest.Position - myRoot.Position).Unit
	local spoofCF = CFrame.new(nearest.Position - dir * spoofRange)

	-- ย้ายไปหาศัตรู 1 frame
	myRoot.CFrame = spoofCF

	-- รอ 1 frame ให้ server รับ position แล้วดึงกลับทันที
	task.wait()
	myRoot.CFrame = originalCF
	isSpoofing = false
end)

CombatTab:CreateToggle({
	Name = "Position Spoof  [Fake Reach]",
	CurrentValue = Config.PosSpoof or false,
	Callback = function(v)
		posSpoof = v
		Config.PosSpoof = v
		Rayfield:Notify({
			Title = "Position Spoof",
			Content = v and "เปิดแล้ว 🟢  คลิกตีแล้ว spoof อัตโนมัติ" or "ปิดแล้ว 🔴",
			Duration = 3
		})
	end
})

CombatTab:CreateSlider({
	Name = "Spoof Offset (studs จากศัตรู)",
	Range = {1, 10},
	Increment = 1,
	CurrentValue = Config.SpoofRange or 3,
	Callback = function(v)
		spoofRange = v
		Config.SpoofRange = v
	end
})

-- =====================================================
-- TELEPORT TAB
-- =====================================================

local TeleportTab = Window:CreateTab("Teleport", 4483362458)
local clickTP = Config.ClickTP

TeleportTab:CreateToggle({
	Name = "CTRL + Click TP",
	CurrentValue = Config.ClickTP,  -- โหลดค่าเดิม
	Callback = function(v)
		clickTP = v
		Config.ClickTP = v
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
			VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
			task.wait(1)
			VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
		end)
	end
})

-- ปุ่ม Save Config ด้วยตัวเอง
UtilityTab:CreateButton({
	Name = "💾 Save Config",
	Callback = function()
		Rayfield:Notify({
			Title = "Config Saved",
			Content = "บันทึก config เรียบร้อย ✅",
			Duration = 3
		})
	end
})

-- ปุ่ม Reset Config
UtilityTab:CreateButton({
	Name = "🔄 Reset Config",
	Callback = function()
		Config = {
			WalkSpeed       = 16,
			JumpPower       = 50,
			InfiniteJump    = false,
			Noclip          = false,
			ESPEnabled      = true,
			ClickTP         = false,
			HitboxSize      = 5,
			HitboxEnabled   = false,
			BlinkEnabled    = false,
			BlinkRange      = 20,
			AutoAttack      = false,
			AutoAttackRate  = 0.1,
			AutoAttackRange = 15,
			FastAttack      = false,
			FastAttackDelay = 5,
			PosSpoof        = false,
			SpoofRange      = 3,
			AutoSkill       = false,
			SkillDelay      = 10,
		}
		Rayfield:Notify({
			Title = "Config Reset",
			Content = "รีเซ็ต config เป็นค่าเริ่มต้นแล้ว 🔄",
			Duration = 3
		})
	end
})

UtilityTab:CreateButton({
	Name = "Destroy UI",
	Callback = function()
		Rayfield:Destroy()
	end
})

-- =====================================================
-- APPLY CONFIG — ใช้ค่าที่บันทึกไว้กับ character จริงๆ
-- อยู่ท้ายสุดเพื่อให้ตัวแปรทุกตัว declare แล้ว
-- =====================================================

local function ApplyConfig(char)
	if not char then return end
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end

	-- WalkSpeed
	speedValue   = Config.WalkSpeed
	speedEnabled = Config.WalkSpeed ~= 16
	hum.WalkSpeed = Config.WalkSpeed
	if speedEnabled then hookWalkSpeed(hum) end

	-- JumpPower
	hum.UseJumpPower = true
	hum.JumpPower    = Config.JumpPower
	hum.JumpHeight   = Config.JumpPower / 10

	-- Infinite Jump
	infJump = Config.InfiniteJump

	-- Noclip
	noclip = Config.Noclip

	-- Hitbox Expander
	hitboxEnabled = Config.HitboxEnabled
	hitboxSize    = Config.HitboxSize

	-- Blink TP
	blinkEnabled = Config.BlinkEnabled
	blinkRange   = Config.BlinkRange

	-- Auto Attack
	autoAttack      = Config.AutoAttack
	autoAttackRange = Config.AutoAttackRange
	autoAttackRate  = Config.AutoAttackRate
	if autoAttack then StartAutoAttack() end

	-- Fast Attack
	fastAttackEnabled = Config.FastAttack or false
	fastAttackDelay   = (Config.FastAttackDelay or 5) / 100
	if fastAttackEnabled then StartFastAttack() end

	-- Position Spoof
	posSpoof   = Config.PosSpoof or false
	spoofRange = Config.SpoofRange or 3

	-- Auto Skill
	autoSkill  = Config.AutoSkill or false
	skillDelay = Config.SkillDelay or 10
	if autoSkill then StartAutoSkill() end

	-- Kill Aura
	killAura      = Config.KillAura or false
	killAuraRange = Config.KillAuraRange or 20
	killAuraRate  = (Config.KillAuraRate or 3) / 20
	if killAura then StartKillAura() end
end

-- Apply ตอนเริ่ม
task.spawn(function()
	task.wait(1.5)
	ApplyConfig(Character)
end)

-- Apply ทุกครั้งที่ respawn
LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
	task.wait(1.5)
	ApplyConfig(char)
end)

-- =====================================================
-- NOTIFY
-- =====================================================

Rayfield:Notify({
	Title = "N-HUB V3 PRO Loaded",
	Content = "Combat Edition Ready 😈 | Q=Blink หน้า  E=Backstab",
	Duration = 5
})
