-- =====================================================
-- N-HUB | Universal V3 PRO
-- Stable • Black UI • Full Feature + Auto Save Config
-- =====================================================

-- CLEANUP SYSTEM: track ทุก connection อัตโนมัติ
if _G.NHubCleanup then pcall(_G.NHubCleanup) end

local _connections = {}
local _threads     = {}

-- ใช้ Connect() นี้แทน :Connect() ทุกที่ → track อัตโนมัติ
local function Connect(signal, fn)
	local conn = signal:Connect(fn)
	table.insert(_connections, conn)
	return conn
end

-- ใช้ Spawn() นี้แทน task.spawn() → track อัตโนมัติ
local function Spawn(fn)
	local t = task.spawn(fn)
	table.insert(_threads, t)
	return t
end

_G.NHubCleanup = function()
	for _, conn in pairs(_connections) do pcall(function() conn:Disconnect() end) end
	for _, t    in pairs(_threads)     do pcall(function() task.cancel(t) end) end
	_connections = {}
	_threads     = {}
	_G.NHubCleanup = nil
end

local Rayfield
Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Services
local Players        = game:GetService("Players")
local LocalPlayer    = Players.LocalPlayer
local UIS            = game:GetService("UserInputService")
local TeleportService= game:GetService("TeleportService")
local RunService     = game:GetService("RunService")
local VirtualUser    = game:GetService("VirtualUser")
local HttpService    = game:GetService("HttpService")

-- =====================================================
-- LANGUAGE SYSTEM
-- =====================================================

local Lang = "EN"  -- default EN

local L = {
	EN = {
		-- Window
		subtitle       = "Free",
		-- Tabs
		tab_player     = "Player",
		tab_esp        = "ESP",
		tab_combat     = "Combat",
		tab_teleport   = "Teleport",
		tab_utility    = "Utility",
		-- Player
		walkspeed      = "Walk Speed",
		jumppower      = "Jump Power",
		infjump        = "Infinite Jump",
		noclip         = "Noclip",
		-- ESP
		esp            = "ESP",
		esp_enemy      = "Enemy ESP (Red)",
		esp_team       = "Team ESP (Blue)",
		hitbox         = "Hitbox Expander",
		hitbox_size    = "Hitbox Size",
		autoskill      = "Auto Skill  [Q Auto]",
		skill_cd       = "Skill Cooldown (sec)",
		blink          = "Blink TP  [Z = Front | X = Back]",
		blink_range    = "Blink Range (offset)",
		autoattack     = "Auto Attack  [Auto hit nearest]",
		attack_range   = "Attack Range (studs)",
		fastattack     = "Fast Attack  [Click Spam + Tool Fire]",
		fastattack_del = "Fast Attack Delay  (low = fastest)",
		posspoof       = "Position Spoof  [Fake Reach]",
		spoof_offset   = "Spoof Offset (studs from enemy)",
		-- Teleport
		clicktp        = "CTRL + Click TP",
		-- Utility
		rejoin         = "Rejoin Server",
		antiafk        = "Anti AFK",
		saveconfig     = "💾 Save Config",
		resetconfig    = "🔄 Reset Config",
		destroyui      = "Destroy UI",
		language       = "🌐 Language: EN → ไทย",
		-- Notify
		on             = "ON 🟢",
		off            = "OFF 🔴",
		loaded         = "Made by AI 😈",
		config_saved   = "Config saved ✅",
		config_reset   = "Config reset 🔄",
	},
	TH = {
		-- Window
		subtitle       = "แจกฟรี",
		-- Tabs
		tab_player     = "ผู้เล่น",
		tab_esp        = "ESP",
		tab_combat     = "ต่อสู้",
		tab_teleport   = "เทเลพอร์ต",
		tab_utility    = "เครื่องมือ",
		-- Player
		walkspeed      = "วิ่งไว",
		jumppower      = "ความสูงกระโดด",
		infjump        = "กระโดดไม่จำกัด",
		noclip         = "ทะลุกำแพง",
		-- ESP
		esp            = "ESP (มองทะลุ)",
		esp_enemy      = "ESP ศัตรู (แดง)",
		esp_team       = "ESP ทีมเรา (น้ำเงิน)",
		-- Combat
		hitbox         = "ขยาย Hitbox",
		hitbox_size    = "ขนาด Hitbox",
		autoskill      = "สกิลอัตโนมัติ  [กด Q อัตโนมัติ]",
		skill_cd       = "คูลดาวน์สกิล (วินาที)",
		blink          = "วาปหาศัตรู  [Z = หน้า | X = หลัง]",
		blink_range    = "ระยะวาป",
		autoattack     = "โจมตีอัตโนมัติ",
		attack_range   = "ระยะโจมตี (studs)",
		fastattack     = "โจมตีเร็ว  [สแปมคลิก + ยิง Tool]",
		fastattack_del = "หน่วงโจมตีเร็ว  (ต่ำ = เร็วสุด)",
		posspoof       = "วาปไปตีจากระยะไกล  [คลิกโจมตี]",
		spoof_offset   = "ระยะวาปไปตี (studs จากศัตรู)",
		-- Teleport
		clicktp        = "CTRL + คลิก เพื่อวาป",
		-- Utility
		rejoin         = "เข้าเซิร์ฟใหม่",
		antiafk        = "กัน AFK",
		saveconfig     = "💾 บันทึกตั้งค่า",
		resetconfig    = "🔄 รีเซ็ตตั้งค่า",
		destroyui      = "ปิด UI",
		language       = "🌐 ภาษา: ไทย → EN",
		-- Notify
		on             = "เปิดแล้ว 🟢",
		off            = "ปิดแล้ว 🔴",
		loaded         = "ใช้ AI ทำทั้งหมด 😈",
		config_saved   = "บันทึก config เรียบร้อย ✅",
		config_reset   = "รีเซ็ต config เป็นค่าเริ่มต้นแล้ว 🔄",
	},
}

local function T(key)
	return L[Lang][key] or key
end

-- =====================================================
-- CONFIG SYSTEM
-- =====================================================

local ConfigFolder = "NHub"
local ConfigPath   = ConfigFolder .. "/UniversalV3PRO.json"

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
	Language        = "EN",
}

local function EnsureFolder()
	if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
end

local isSaving = false
local function SaveConfig()
	if isSaving then return end
	isSaving = true
	task.defer(function()
		pcall(function()
			EnsureFolder()
			writefile(ConfigPath, HttpService:JSONEncode(_raw))
		end)
		isSaving = false
	end)
end

local function LoadConfig()
	pcall(function()
		EnsureFolder()
		if isfile(ConfigPath) then
			local decoded = HttpService:JSONDecode(readfile(ConfigPath))
			for k, v in pairs(decoded) do _raw[k] = v end
			print("[N-HUB] Config loaded ✅")
		end
	end)
end

LoadConfig()
Lang = _raw.Language or "EN"

local Config = setmetatable({}, {
	__index    = function(_, k) return _raw[k] end,
	__newindex = function(_, k, v) _raw[k] = v; SaveConfig() end,
})

Spawn(function()
	while task.wait(60) do SaveConfig() end
end)

-- =====================================================
-- CHARACTER
-- =====================================================

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
Connect(LocalPlayer.CharacterAdded, function(char) Character = char end)

-- =====================================================
-- GAME STATE (ตัวแปรทั้งหมดอยู่นอก BuildUI)
-- =====================================================

local speedValue      = Config.WalkSpeed
local speedEnabled    = speedValue ~= 16
local speedConnection = nil
local infJump         = Config.InfiniteJump
local noclip          = Config.Noclip
local ESPEnabled = Config.ESPEnabled
local ESPObjects = {}
local hitboxEnabled   = Config.HitboxEnabled
local hitboxSize      = Config.HitboxSize
local hitboxOriginals = {}
local autoSkill       = Config.AutoSkill or false
local skillDelay      = Config.SkillDelay or 10
local skillConn       = nil
local blinkEnabled    = Config.BlinkEnabled
local blinkRange      = Config.BlinkRange
local autoAttack      = Config.AutoAttack
local autoAttackRate  = Config.AutoAttackRate
local autoAttackRange = Config.AutoAttackRange
local autoAttackConn  = nil
local lastAttackTime  = 0
local fastAttackEnabled = false
local fastAttackDelay   = (Config.FastAttackDelay or 5) / 100
local fastAttackConn    = nil
local posSpoof        = Config.PosSpoof or false
local spoofRange      = Config.SpoofRange or 3
local isSpoofing      = false
local clickTP         = Config.ClickTP

-- =====================================================
-- LOGIC FUNCTIONS
-- =====================================================

local function IsChatFocused()
	return UIS:GetFocusedTextBox() ~= nil
end

local function hookWalkSpeed(hum)
	if speedConnection then speedConnection:Disconnect(); speedConnection = nil end
	speedConnection = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if speedEnabled and hum.WalkSpeed ~= speedValue then
			hum.WalkSpeed = speedValue
		end
	end)
end

-- ESP
local TEAM_COLOR  = Color3.fromRGB(0,170,255)
local ENEMY_COLOR = Color3.fromRGB(255,60,60)

local function IsEnemy(player)
	if not player or player == LocalPlayer then return false end
	-- ถ้าเกมมี Team system จริงๆ
	if LocalPlayer.Team ~= nil and player.Team ~= nil then
		return player.Team ~= LocalPlayer.Team
	end
	if LocalPlayer.TeamColor ~= nil and player.TeamColor ~= nil then
		-- Neutral (grey) = ยังไม่มีทีม = ถือว่าทุกคนเป็นศัตรู
		local neutral = BrickColor.new("Medium stone grey")
		if LocalPlayer.TeamColor == neutral then return true end
		return player.TeamColor ~= LocalPlayer.TeamColor
	end
	return true  -- ไม่มี team system → ทุกคนเป็นศัตรู
end

local function CreateESP(player)
	if ESPObjects[player] then return end
	local function SetupCharacter(char)
		local hum  = char:WaitForChild("Humanoid")
		local root = char:WaitForChild("HumanoidRootPart")
		local box    = Drawing.new("Square"); box.Thickness=1; box.Filled=false; box.Visible=false
		local name   = Drawing.new("Text");   name.Size=13; name.Center=true; name.Outline=true; name.Visible=false
		local hpBack = Drawing.new("Square"); hpBack.Filled=true; hpBack.Color=Color3.new(0,0,0); hpBack.Visible=false
		local hpBar  = Drawing.new("Square"); hpBar.Filled=true; hpBar.Visible=false
		ESPObjects[player] = {box=box, name=name, hpBack=hpBack, hpBar=hpBar}
		RunService.RenderStepped:Connect(function()
			if not ESPEnabled or not char or not char.Parent then
				box.Visible=false; name.Visible=false; hpBack.Visible=false; hpBar.Visible=false; return
			end
			local myChar = LocalPlayer.Character
			if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
			local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(root.Position)
			if onScreen then
				local dist   = math.floor((myChar.HumanoidRootPart.Position - root.Position).Magnitude)
				local color  = IsEnemy(player) and ENEMY_COLOR or TEAM_COLOR
				local scale  = math.clamp(1200/pos.Z, 0.8, 1.6)
				local w, h   = 28*scale, 48*scale
				box.Size=Vector2.new(w,h); box.Position=Vector2.new(pos.X-w/2,pos.Y-h/2); box.Color=color; box.Visible=true
				name.Text=player.Name.." ["..dist.."m]"; name.Position=Vector2.new(pos.X,pos.Y-h/2-14); name.Color=color; name.Visible=true
				local hp = hum.Health/hum.MaxHealth
				hpBack.Size=Vector2.new(4,h); hpBack.Position=Vector2.new(pos.X-w/2-8,pos.Y-h/2); hpBack.Visible=true
				hpBar.Size=Vector2.new(4,h*hp); hpBar.Position=Vector2.new(pos.X-w/2-8,pos.Y-h/2+(h-h*hp)); hpBar.Color=Color3.fromRGB(0,255,0); hpBar.Visible=true
			else
				box.Visible=false; name.Visible=false; hpBack.Visible=false; hpBar.Visible=false
			end
		end)
	end
	ESPObjects[player] = {}
	if player.Character then SetupCharacter(player.Character) end
	player.CharacterAdded:Connect(SetupCharacter)
end

for _, plr in pairs(Players:GetPlayers()) do
	if plr ~= LocalPlayer then CreateESP(plr) end
end
Connect(Players.PlayerAdded, function(plr)
	if plr ~= LocalPlayer then CreateESP(plr) end
end)

-- Hitbox
local function ApplyHitbox()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				if not hitboxOriginals[plr] then
					hitboxOriginals[plr] = {size=hrp.Size, canCollide=hrp.CanCollide}
				end
				hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
				hrp.CanCollide = false
			end
		end
	end
end

local function RemoveHitbox()
	for plr, orig in pairs(hitboxOriginals) do
		if plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.Size=orig.size; hrp.CanCollide=orig.canCollide end
		end
	end
	hitboxOriginals = {}
end

local _hitboxConn = Connect(RunService.Heartbeat, function()
	if hitboxEnabled then ApplyHitbox() end
end)


-- Auto Skill
local function PressQ()
	pcall(function()
		sendinput({type="keyboard",keyCode=Enum.KeyCode.Q,inputType=Enum.UserInputType.Keyboard,inputState=Enum.UserInputState.Begin})
		task.wait(0.05)
		sendinput({type="keyboard",keyCode=Enum.KeyCode.Q,inputType=Enum.UserInputType.Keyboard,inputState=Enum.UserInputState.End})
	end)
	pcall(function()
		game:GetService("VirtualInputManager"):SendKeyEvent(true,Enum.KeyCode.Q,false,game)
		task.wait(0.05)
		game:GetService("VirtualInputManager"):SendKeyEvent(false,Enum.KeyCode.Q,false,game)
	end)
	pcall(function() keypress(0x51); task.wait(0.05); keyrelease(0x51) end)
end

local function StartAutoSkill()
	if skillConn then task.cancel(skillConn) end
	skillConn = Spawn(function()
		while autoSkill do
			if Character and not IsChatFocused() then
				local hum = Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then PressQ() end
			end
			task.wait(skillDelay)
		end
	end)
end

local function StopAutoSkill() autoSkill = false end

-- Blink
local function GetNearestEnemy()
	local nearest, minDist = nil, math.huge
	if not Character then return nil end
	local myRoot = Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
			local root = plr.Character:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				local dist = (myRoot.Position - root.Position).Magnitude
				if dist < minDist then minDist=dist; nearest=plr end
			end
		end
	end
	return nearest
end

Connect(UIS.InputBegan, function(input, gp)
	if gp or not blinkEnabled or not Character then return end
	local myRoot = Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	local enemy = GetNearestEnemy()
	if not enemy or not enemy.Character then return end
	local eRoot = enemy.Character:FindFirstChild("HumanoidRootPart")
	if not eRoot then return end
	if input.KeyCode == Enum.KeyCode.Z then
		local dir = eRoot.CFrame.LookVector
		myRoot.CFrame = CFrame.new(eRoot.Position + dir * blinkRange) * CFrame.Angles(0, math.pi, 0)
		Rayfield:Notify({Title="Blink TP", Content="⚔️ → "..enemy.Name, Duration=1})
	elseif input.KeyCode == Enum.KeyCode.X then
		local dir = -eRoot.CFrame.LookVector
		myRoot.CFrame = CFrame.new(eRoot.Position + dir * blinkRange) * CFrame.fromEulerAnglesXYZ(0, math.atan2(dir.X, dir.Z), 0)
		Rayfield:Notify({Title="Blink TP", Content="🗡️ Backstab "..enemy.Name, Duration=1})
	end
end)

-- Auto Attack
local function StartAutoAttack()
	if autoAttackConn then autoAttackConn:Disconnect() end
	autoAttackConn = Connect(RunService.Heartbeat, function()
		if not autoAttack or not Character or IsChatFocused() then return end
		local myRoot = Character:FindFirstChild("HumanoidRootPart")
		local myHum  = Character:FindFirstChildOfClass("Humanoid")
		if not myRoot or not myHum or myHum.Health <= 0 then return end
		local now = tick()
		if (now - lastAttackTime) < autoAttackRate then return end
		local targets = {}
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
				local root = plr.Character:FindFirstChild("HumanoidRootPart")
				if hum and root and hum.Health > 0 then
					if (myRoot.Position - root.Position).Magnitude <= autoAttackRange then
						table.insert(targets, root)
					end
				end
			end
		end
		if #targets > 0 then
			lastAttackTime = now
			local sc = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2)
			for _, tRoot in pairs(targets) do
				myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z))
				VirtualUser:Button1Down(sc, workspace.CurrentCamera.CFrame)
				task.wait(0.03)
				VirtualUser:Button1Up(sc, workspace.CurrentCamera.CFrame)
				task.wait(0.03)
			end
		end
	end)
end

local function StopAutoAttack()
	if autoAttackConn then autoAttackConn:Disconnect(); autoAttackConn=nil end
end

-- Fast Attack
local function GetEquippedTool()
	if not Character then return nil end
	for _, obj in pairs(Character:GetChildren()) do
		if obj:IsA("Tool") then return obj end
	end
	return nil
end

local function StartFastAttack()
	if fastAttackConn then task.cancel(fastAttackConn); fastAttackConn=nil end
	fastAttackConn = Spawn(function()
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
									(obj.Name:lower():find("attack") or obj.Name:lower():find("hit") or
									 obj.Name:lower():find("swing") or obj.Name:lower():find("slash")) then
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
	if fastAttackConn then task.cancel(fastAttackConn); fastAttackConn=nil end
end

Connect(UIS.InputBegan, function(input, gp)
	if gp or not posSpoof or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if isSpoofing or not Character then return end
	local myRoot = Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	local nearest, minDist = nil, math.huge
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
			local root = plr.Character:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				local d = (myRoot.Position - root.Position).Magnitude
				if d < minDist then minDist=d; nearest=root end
			end
		end
	end
	if not nearest then return end
	isSpoofing = true
	local originalCF = myRoot.CFrame
	local dir = (nearest.Position - myRoot.Position).Unit
	myRoot.CFrame = CFrame.new(nearest.Position - dir * spoofRange)
	task.wait()
	myRoot.CFrame = originalCF
	isSpoofing = false
end)

Connect(UIS.InputBegan, function(input, gp)
	if not clickTP or gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
		local mouse = LocalPlayer:GetMouse()
		if mouse.Hit and Character then Character:MoveTo(mouse.Hit.Position) end
	end
end)

Connect(RunService.Stepped, function()
	if noclip and Character then
		for _, p in pairs(Character:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end
end)

Connect(UIS.JumpRequest, function()
	if infJump then
		local hum = Character and Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- ApplyConfig
local function ApplyConfig(char)
	if not char then return end
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end
	speedValue=Config.WalkSpeed; speedEnabled=Config.WalkSpeed~=16
	hum.WalkSpeed=Config.WalkSpeed
	if speedEnabled then hookWalkSpeed(hum) end
	hum.UseJumpPower=true; hum.JumpPower=Config.JumpPower; hum.JumpHeight=Config.JumpPower/10
	infJump=Config.InfiniteJump; noclip=Config.Noclip
	hitboxEnabled=Config.HitboxEnabled; hitboxSize=Config.HitboxSize
	blinkEnabled=Config.BlinkEnabled; blinkRange=Config.BlinkRange
	autoAttack=Config.AutoAttack; autoAttackRange=Config.AutoAttackRange; autoAttackRate=Config.AutoAttackRate
	if autoAttack then StartAutoAttack() end
	fastAttackEnabled=Config.FastAttack or false; fastAttackDelay=(Config.FastAttackDelay or 5)/100
	if fastAttackEnabled then StartFastAttack() end
	posSpoof=Config.PosSpoof or false; spoofRange=Config.SpoofRange or 3
	autoSkill=Config.AutoSkill or false; skillDelay=Config.SkillDelay or 10
	if autoSkill then StartAutoSkill() end
end

Spawn(function() task.wait(1.5); ApplyConfig(Character) end)
Connect(LocalPlayer.CharacterAdded, function(char)
	Character = char; task.wait(1.5); ApplyConfig(char)
end)

-- =====================================================
-- BUILD UI FUNCTION (สร้างใหม่ได้เมื่อเปลี่ยนภาษา)
-- =====================================================

local Window
local function BuildUI()
	Window = Rayfield:CreateWindow({
		Name          = "N-HUB | Battle Minigames",
		LoadingTitle  = "N-HUB",
		LoadingSubtitle = T("subtitle"),
		ConfigurationSaving = { Enabled=false },
		KeySystem     = false,
	})
	pcall(function() Rayfield:SetTheme("Dark") end)

	-- PLAYER TAB
	local PlayerTab = Window:CreateTab(T("tab_player"), 4483362458)

	PlayerTab:CreateSlider({
		Name=T("walkspeed"), Range={16,200}, Increment=1, CurrentValue=Config.WalkSpeed,
		Callback=function(v)
			speedValue=v; speedEnabled=true; Config.WalkSpeed=v
			if Character then
				local hum=Character:FindFirstChildOfClass("Humanoid")
				if hum then hum.WalkSpeed=v; hookWalkSpeed(hum) end
			end
		end
	})

	PlayerTab:CreateSlider({
		Name=T("jumppower"), Range={50,500}, Increment=5, CurrentValue=Config.JumpPower,
		Callback=function(v)
			Config.JumpPower=v
			local hum=Character and Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.JumpPower=v; hum.JumpHeight=v/10; hum.UseJumpPower=true end
		end
	})

	PlayerTab:CreateToggle({
		Name=T("infjump"), CurrentValue=Config.InfiniteJump,
		Callback=function(v) infJump=v; Config.InfiniteJump=v end
	})

	PlayerTab:CreateToggle({
		Name=T("noclip"), CurrentValue=Config.Noclip,
		Callback=function(v) noclip=v; Config.Noclip=v end
	})

	-- ESP TAB
	local ESPTab = Window:CreateTab(T("tab_esp"), 4483362458)

	ESPTab:CreateToggle({
		Name=T("esp"), CurrentValue=Config.ESPEnabled,
		Callback=function(v)
			ESPEnabled=v; Config.ESPEnabled=v
			if not v then
				for _, obj in pairs(ESPObjects) do
					if obj.box    then obj.box.Visible=false end
					if obj.name   then obj.name.Visible=false end
					if obj.hpBack then obj.hpBack.Visible=false end
					if obj.hpBar  then obj.hpBar.Visible=false end
				end
			end
			Rayfield:Notify({Title="ESP", Content=v and T("on") or T("off"), Duration=2})
		end
	})

	-- COMBAT TAB
	local CombatTab = Window:CreateTab(T("tab_combat"), 4483362458)

	CombatTab:CreateToggle({
		Name=T("hitbox"), CurrentValue=Config.HitboxEnabled,
		Callback=function(v)
			hitboxEnabled=v; Config.HitboxEnabled=v
			if not v then RemoveHitbox() end
			Rayfield:Notify({Title="Hitbox", Content=v and T("on") or T("off"), Duration=2})
		end
	})

	CombatTab:CreateSlider({
		Name=T("hitbox_size"), Range={5,200}, Increment=1, CurrentValue=Config.HitboxSize,
		Callback=function(v) hitboxSize=v; Config.HitboxSize=v end
	})

	CombatTab:CreateToggle({
		Name=T("autoskill"), CurrentValue=Config.AutoSkill or false,
		Callback=function(v)
			autoSkill=v; Config.AutoSkill=v
			if v then StartAutoSkill(); Rayfield:Notify({Title="Auto Skill ⚡", Content=T("on"), Duration=3})
			else StopAutoSkill(); Rayfield:Notify({Title="Auto Skill", Content=T("off"), Duration=2}) end
		end
	})

	CombatTab:CreateSlider({
		Name=T("skill_cd"), Range={1,30}, Increment=1, CurrentValue=Config.SkillDelay or 10,
		Callback=function(v) skillDelay=v; Config.SkillDelay=v end
	})

	CombatTab:CreateToggle({
		Name=T("blink"), CurrentValue=Config.BlinkEnabled,
		Callback=function(v)
			blinkEnabled=v; Config.BlinkEnabled=v
			Rayfield:Notify({Title="Blink TP", Content=v and T("on") or T("off"), Duration=2})
		end
	})

	CombatTab:CreateSlider({
		Name=T("blink_range"), Range={3,30}, Increment=1, CurrentValue=Config.BlinkRange,
		Callback=function(v) blinkRange=v; Config.BlinkRange=v end
	})

	CombatTab:CreateToggle({
		Name=T("autoattack"), CurrentValue=Config.AutoAttack,
		Callback=function(v)
			autoAttack=v; Config.AutoAttack=v
			if v then StartAutoAttack(); Rayfield:Notify({Title="Auto Attack 🗡️", Content=T("on"), Duration=3})
			else StopAutoAttack(); Rayfield:Notify({Title="Auto Attack", Content=T("off"), Duration=2}) end
		end
	})

	CombatTab:CreateSlider({
		Name=T("attack_range"), Range={5,60}, Increment=1, CurrentValue=Config.AutoAttackRange,
		Callback=function(v) autoAttackRange=v; Config.AutoAttackRange=v end
	})

	CombatTab:CreateToggle({
		Name=T("fastattack"), CurrentValue=Config.FastAttack or false,
		Callback=function(v)
			fastAttackEnabled=v; Config.FastAttack=v
			if v then StartFastAttack(); Rayfield:Notify({Title="Fast Attack ⚡", Content=T("on"), Duration=3})
			else StopFastAttack(); Rayfield:Notify({Title="Fast Attack", Content=T("off"), Duration=2}) end
		end
	})

	CombatTab:CreateSlider({
		Name=T("fastattack_del"), Range={1,10}, Increment=1, CurrentValue=Config.FastAttackDelay or 5,
		Callback=function(v) fastAttackDelay=v/100; Config.FastAttackDelay=v end
	})

	CombatTab:CreateToggle({
		Name=T("posspoof"), CurrentValue=Config.PosSpoof or false,
		Callback=function(v)
			posSpoof=v; Config.PosSpoof=v
			Rayfield:Notify({Title="Position Spoof", Content=v and T("on") or T("off"), Duration=2})
		end
	})

	CombatTab:CreateSlider({
		Name=T("spoof_offset"), Range={1,10}, Increment=1, CurrentValue=Config.SpoofRange or 3,
		Callback=function(v) spoofRange=v; Config.SpoofRange=v end
	})

	-- TELEPORT TAB
	local TeleportTab = Window:CreateTab(T("tab_teleport"), 4483362458)

	TeleportTab:CreateToggle({
		Name=T("clicktp"), CurrentValue=Config.ClickTP,
		Callback=function(v) clickTP=v; Config.ClickTP=v end
	})

	-- UTILITY TAB
	local UtilityTab = Window:CreateTab(T("tab_utility"), 4483362458)

	UtilityTab:CreateButton({
		Name=T("rejoin"),
		Callback=function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end
	})

	UtilityTab:CreateButton({
		Name=T("antiafk"),
		Callback=function()
			LocalPlayer.Idled:Connect(function()
				VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
				task.wait(1)
				VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
			end)
		end
	})

	UtilityTab:CreateButton({
		Name=T("saveconfig"),
		Callback=function()
			SaveConfig()
			Rayfield:Notify({Title="Config", Content=T("config_saved"), Duration=3})
		end
	})

	UtilityTab:CreateButton({
		Name=T("resetconfig"),
		Callback=function()
			local defaults = {
				WalkSpeed=16,JumpPower=50,InfiniteJump=false,Noclip=false,
				ESPEnabled=true,ClickTP=false,HitboxSize=5,HitboxEnabled=false,
				BlinkEnabled=false,BlinkRange=20,AutoAttack=false,AutoAttackRate=0.1,
				AutoAttackRange=15,FastAttack=false,FastAttackDelay=5,
				PosSpoof=false,SpoofRange=3,AutoSkill=false,SkillDelay=10,
				Language=Lang,
			}
			for k,v in pairs(defaults) do _raw[k]=v end
			SaveConfig()
			Rayfield:Notify({Title="Reset", Content=T("config_reset"), Duration=3})
		end
	})

	-- ปุ่มเปลี่ยนภาษา
	UtilityTab:CreateButton({
		Name=T("language"),
		Callback=function()
			Lang = Lang == "EN" and "TH" or "EN"
			_raw.Language = Lang
			SaveConfig()
			Rayfield:Destroy()
			task.wait(0.5)
			-- โหลด Rayfield ใหม่หลัง destroy
			Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
			task.wait(0.3)
			BuildUI()
		end
	})

	UtilityTab:CreateButton({
		Name=T("destroyui"),
		Callback=function() SaveConfig(); Rayfield:Destroy() end
	})

	-- Notify โหลดสำเร็จ
	Rayfield:Notify({Title="N-HUB V3 PRO", Content=T("loaded"), Duration=5})
end

BuildUI()
