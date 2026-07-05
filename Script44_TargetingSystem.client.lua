--!strict
-- Скрипт 44: Система таргетинга ракет + Интро GUI + Визуал
-- Размещение: StarterPlayerScripts (LocalScript)

-- ====================================================================
-- СЕРВИСЫ
-- ====================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local lp = player
local mouse = lp:GetMouse()
local RS = ReplicatedStorage
local WS = workspace

-- ====================================================================
-- REMOTE EVENTS
-- ====================================================================
local rvEv = {}

local function findRemotes()
    rvEv = {}
    -- Поиск в rvEv папке
    local rvFolder = RS:FindFirstChild("rvEv")
    if rvFolder then
        for _, name in ipairs({"RocketReloadedFX", "FireRocketReplicated", "RocketHit", "KillFeed"}) do
            local ev = rvFolder:FindFirstChild(name)
            if ev then rvEv[name] = ev end
        end
    end
    -- Поиск в RocketSystem.Events
    local rvSys = RS:FindFirstChild("RocketSystem") and RS.RocketSystem:FindFirstChild("Events")
    if rvSys then
        for _, name in ipairs({"RocketReloadedFX", "FireRocketReplicated", "RocketHit", "KillFeed"}) do
            local ev = rvSys:FindFirstChild(name)
            if ev and not rvEv[name] then rvEv[name] = ev end
        end
    end
    -- Поиск KillFeed по всему ReplicatedStorage
    if not rvEv.KillFeed then
        for _, v in ipairs(RS:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name == "KillFeed" then
                rvEv.KillFeed = v
                break
            end
        end
    end
    -- Поиск по всему ReplicatedStorage рекурсивно
    if not rvEv.RocketHit then
        for _, v in ipairs(RS:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                if v.Name == "RocketHit" and not rvEv.RocketHit then rvEv.RocketHit = v end
                if v.Name == "FireRocketReplicated" and not rvEv.FireRocketReplicated then rvEv.FireRocketReplicated = v end
                if v.Name == "RocketReloadedFX" and not rvEv.RocketReloadedFX then rvEv.RocketReloadedFX = v end
            end
        end
    end
end

findRemotes()

local ROCKET_MODEL = nil
local rocketFolder = RS:FindFirstChild("RocketSystem") and RS.RocketSystem:FindFirstChild("Rockets")
if rocketFolder then
    ROCKET_MODEL = rocketFolder:FindFirstChild("RPG Rocket")
end

-- ====================================================================
-- ПОИСК ТУЛЗЫ
-- ====================================================================
local cachedTool = nil

local function getTool()
    if cachedTool and cachedTool.Parent then
        return cachedTool
    end
    cachedTool = nil

    local function isRPG(t)
        if not t:IsA("Tool") then return false end
        if t.Name:lower():find("rpg") then return true end
        if t:FindFirstChild("RocketSettings") then return true end
        return false
    end

    local c = lp.Character
    if c then
        for _, t in ipairs(c:GetChildren()) do
            if isRPG(t) then
                cachedTool = t
                return t
            end
        end
    end

    local bp = lp:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if isRPG(t) then
                cachedTool = t
                return t
            end
        end
    end

    return nil
end

-- Автопоиск RPG при подборе
lp.CharacterAdded:Connect(function()
    cachedTool = nil
    task.wait(1)
    getTool()
end)

-- Также ищем в Backpack при добавлении
local bp = lp:FindFirstChild("Backpack")
if bp then
    bp.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and not cachedTool then
            task.wait(0.5)
            getTool()
        end
    end)
end

lp.CharacterAdded:Connect(function()
    cachedTool = nil
    task.wait(1)
    getTool()
end)

-- ====================================================================
-- НАСТРОЙКИ
-- ====================================================================
local S = {
    Enabled = false,
    RocketCount = 3,
    Spread = 2,
    FireRate = 0.03,
    TargetSpam = false,
    TargetSpamMult = 3,
    TargetSpamRate = 0.03,
    KillDistance = "0",
    -- Визуал
    SkyEnabled = false,
    SkyPreset = 1,
    GlowEnabled = false,
    GlowColor = Color3.fromRGB(130, 50, 255),
    BloomEnabled = false,
    CCEnabled = false,
    -- Combat
    AutoFire = false,
    AutoFireKey = Enum.KeyCode.T,
    BurstMode = false,
    BurstKey = Enum.KeyCode.Q,
    ClusterEnabled = false,
    ClusterKey = Enum.KeyCode.R,
    ClusterCount = 8,
    ClusterRadius = 30,
    HomingEnabled = false,
    HomingKey = Enum.KeyCode.G,
    HomingSpeed = 1.5,
    SlowMoEnabled = false,
    SlowMoKey = Enum.KeyCode.E,
    SlowMoCount = 5,
    SlowMoSpread = 10,
    SlowMoMult = 0.3,
    RocketJumpEnabled = false,
    RocketJumpKey = Enum.KeyCode.V,
    RocketJumpPower = 200,
    CarDestroyEnabled = false,
    CarDestroyKey = Enum.KeyCode.B,
    CarDestroyCount = 10,
    CarDestroySpread = 50,
    CarDestroyRange = 200,
    BringAllEnabled = false,
    BringAllKey = Enum.KeyCode.Z,
    MegaEnabled = false,
    MegaKey = Enum.KeyCode.N,
    MegaCount = 5,
    MegaSpread = 5,
    AirStrikeEnabled = false,
    AirStrikeKey = Enum.KeyCode.F5,
    AirStrikeHeight = 200,
    AirStrikeCount = 10,
    AirStrikeSpeed = 1.0,
    -- Misc
    SpeedBoost = false,
    WalkSpeed = 50,
    NoClip = false,
    FlyEnabled = false,
    FlyKey = Enum.KeyCode.X,
    FlySpeed = 150,
    -- Settings
    GUIAccent = Color3.fromRGB(60, 130, 246),
    GUIBgTransparency = 0.5,
    GUIMatte = false,
    GUIFontSize = 11,
}

-- ====================================================================
-- СОСТОЯНИЕ
-- ====================================================================
local rCnt = 0
local alive = true
local selectedTargets = {}
local targetHighlights = {}
local targetHeader = nil
local targetCooldowns = {} -- cooldown для анти-респавна

-- Фоновый поиск remote events (после объявления alive)
task.spawn(function()
    while alive do
        if not rvEv.RocketHit or not rvEv.FireRocketReplicated or not rvEv.RocketReloadedFX then
            findRemotes()
        end
        task.wait(1)
    end
end)

-- ====================================================================
-- ВИЗУАЛ (только локальный — через GUI)
-- ====================================================================
local visualGui = Instance.new("ScreenGui")
visualGui.Name = "RPGVisual"
visualGui.ResetOnSpawn = false
visualGui.DisplayOrder = 998
visualGui.IgnoreGuiInset = true
visualGui.Enabled = false
visualGui.Parent = game:GetService("CoreGui")

-- Полноэкранный оверлей
local visualOverlay = Instance.new("Frame", visualGui)
visualOverlay.Size = UDim2.new(1, 0, 1, 0)
visualOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
visualOverlay.BackgroundTransparency = 1
visualOverlay.BorderSizePixel = 0
visualOverlay.ZIndex = 0

-- Виньетка (тёмные края)
local vignette = Instance.new("ImageLabel", visualGui)
vignette.Size = UDim2.new(1, 0, 1, 0)
vignette.BackgroundTransparency = 1
vignette.ImageTransparency = 0.4
vignette.ZIndex = 0
vignette.Image = "rbxassetid://1134855083"
vignette.ImageColor3 = Color3.fromRGB(0, 0, 0)

-- Частицы на экране
local visualParticles = {}
for i = 1, 30 do
    local p = Instance.new("Frame", visualGui)
    local s = 1 + math.random() * 3
    p.Size = UDim2.new(0, s, 0, s)
    p.Position = UDim2.new(math.random(), 0, math.random(), 0)
    p.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    p.BackgroundTransparency = 0.6
    p.BorderSizePixel = 0
    p.ZIndex = 0
    Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
    table.insert(visualParticles, {
        f = p,
        dx = (math.random() - 0.5) * 0.3,
        dy = (math.random() - 0.5) * 0.3,
        px = math.random(),
        py = math.random(),
    })
end

-- Пресеты: цвет оверлея + цвет частиц + интенсивность
local VISUAL_PRESETS = {
    [1] = {name = "Purple Haze", overlay = Color3.fromRGB(60, 15, 120), particle = Color3.fromRGB(200, 100, 255), intensity = 0.65, vignetteColor = Color3.fromRGB(40, 8, 80)},
    [2] = {name = "Crimson Night", overlay = Color3.fromRGB(120, 10, 15), particle = Color3.fromRGB(255, 60, 60), intensity = 0.6, vignetteColor = Color3.fromRGB(80, 0, 0)},
    [3] = {name = "Ocean Deep", overlay = Color3.fromRGB(8, 30, 90), particle = Color3.fromRGB(60, 180, 255), intensity = 0.65, vignetteColor = Color3.fromRGB(0, 15, 70)},
    [4] = {name = "Toxic Green", overlay = Color3.fromRGB(15, 60, 15), particle = Color3.fromRGB(100, 255, 100), intensity = 0.65, vignetteColor = Color3.fromRGB(8, 45, 8)},
    [5] = {name = "Golden Hour", overlay = Color3.fromRGB(80, 50, 8), particle = Color3.fromRGB(255, 220, 60), intensity = 0.6, vignetteColor = Color3.fromRGB(60, 35, 0)},
    [6] = {name = "Neon Pink", overlay = Color3.fromRGB(90, 8, 45), particle = Color3.fromRGB(255, 60, 180), intensity = 0.62, vignetteColor = Color3.fromRGB(70, 0, 35)},
}

local currentVisualPreset = 0

local function applyLocalVisual(presetNum)
    local preset = VISUAL_PRESETS[presetNum]
    if not preset then return end
    currentVisualPreset = presetNum
    visualGui.Enabled = true

    -- Плавный переход
    TweenService:Create(visualOverlay, TweenInfo.new(1), {
        BackgroundColor3 = preset.overlay,
        BackgroundTransparency = preset.intensity,
    }):Play()

    vignette.ImageColor3 = preset.vignetteColor

    for _, p in ipairs(visualParticles) do
        p.f.BackgroundColor3 = preset.particle
    end
end

local function removeLocalVisual()
    currentVisualPreset = 0
    TweenService:Create(visualOverlay, TweenInfo.new(0.5), {
        BackgroundTransparency = 1,
    }):Play()
    for _, p in ipairs(visualParticles) do
        TweenService:Create(p.f, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    end
    task.delay(0.6, function()
        visualGui.Enabled = false
    end)
end

-- ====================================================================
-- ФУНКЦИИ
-- ====================================================================

local function instantExplosion(targetPos, hitPart)
    rCnt = rCnt + 1
    local label = lp.Name .. "R" .. rCnt
    local tool = getTool()
    if not tool then return end
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local origin = myRoot and myRoot.Position or Vector3.zero

    for i = 1, S.RocketCount do
        local sx = (math.random() - 0.5) * S.Spread
        local sy = (math.random() - 0.5) * S.Spread
        local sz = (math.random() - 0.5) * S.Spread
        local finalPos = targetPos + Vector3.new(sx * 5, sy * 2, sz * 5)
        local dir = (finalPos - origin).Unit

        if rvEv.RocketReloadedFX then
            pcall(function()
                rvEv.RocketReloadedFX:FireServer(tool, false)
            end)
        end

        if rvEv.FireRocketReplicated then
            pcall(function()
                rvEv.FireRocketReplicated:FireServer({
                    Direction = dir,
                    Settings = {},
                    Origin = origin,
                    PlrFired = lp,
                    Vehicle = tool,
                    RocketModel = ROCKET_MODEL or tool,
                    Weapon = tool,
                })
            end)
        end

        if rvEv.RocketHit then
            pcall(function()
                rvEv.RocketHit:FireServer({
                    Normal = Vector3.new(0, 1, 0),
                    HitPart = hitPart or WS.Terrain,
                    Position = finalPos,
                    Label = label,
                    Vehicle = tool,
                    Player = lp,
                    Weapon = tool,
                })
            end)
        end
    end
end

local function teleportToHumanoid(targetPlayer)
    local targetChar = targetPlayer.Character
    if not targetChar then return end
    local h = targetChar:FindFirstChildOfClass("Humanoid")
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not h or not hrp then return end

    -- Если цель мертва — ждём 2 сек
    if h.Health <= 0 then return end

    -- Анти-респавн: cooldown 2 сек после смерти
    local now = tick()
    local pName = targetPlayer.Name
    if targetCooldowns[pName] and (now - targetCooldowns[pName]) < 2 then
        return
    end

    -- Помечаем момент смерти
    h.Died:Connect(function()
        targetCooldowns[pName] = tick()
    end)

    local tool = getTool()
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local dir = myRoot and (hrp.Position - myRoot.Position).Unit or Vector3.new(0, -1, 0)

    -- Фейковая дистанция: смещаем точку выстрела на KillDistance
    local killDist = tonumber(S.KillDistance) or 0
    local origin = myRoot and (myRoot.Position + dir * killDist) or Vector3.zero

    for i = 1, S.TargetSpamMult do
        rCnt = rCnt + 1
        local label = lp.Name .. "R" .. rCnt

        if rvEv.RocketReloadedFX then
            pcall(function()
                rvEv.RocketReloadedFX:FireServer(tool, false)
            end)
        end

        if rvEv.FireRocketReplicated then
            pcall(function()
                rvEv.FireRocketReplicated:FireServer({
                    Direction = dir,
                    Settings = {},
                    Origin = origin,
                    PlrFired = lp,
                    Vehicle = tool,
                    RocketModel = ROCKET_MODEL or tool,
                    Weapon = tool,
                })
            end)
        end

        if rvEv.RocketHit then
            pcall(function()
                rvEv.RocketHit:FireServer({
                    Normal = Vector3.new(0, 1, 0),
                    HitPart = h,
                    Position = hrp.Position,
                    Label = label,
                    Vehicle = tool,
                    Player = lp,
                    Weapon = tool,
                })
            end)
        end

        -- KillFeed: показываем всем расстояние убийства
        if rvEv.KillFeed then
            -- Пробуем разные форматы
            pcall(function()
                rvEv.KillFeed:FireServer({
                    Killer = lp,
                    Victim = targetPlayer,
                    Distance = S.KillDistance,
                    Studs = S.KillDistance,
                    Weapon = "RPG",
                })
            end)
            pcall(function()
                rvEv.KillFeed:FireServer(lp, targetPlayer, "RPG", S.KillDistance)
            end)
            pcall(function()
                rvEv.KillFeed:FireServer(lp.Name, targetPlayer.Name, S.KillDistance)
            end)
        end
    end
end

local function toggleTarget(p)
    if not p then return end

    -- Проверяем, есть ли уже Player в списке
    for i, tp in ipairs(selectedTargets) do
        if tp == p then
            -- Убираем из списка
            table.remove(selectedTargets, i)
            if targetHighlights[i] then
                targetHighlights[i]:Destroy()
            end
            table.remove(targetHighlights, i)
            if targetHeader then
                targetHeader.Text = #selectedTargets > 0 and "  Targets: " .. #selectedTargets or "  Selected: None"
            end
            return
        end
    end

    -- Добавляем Player
    if not p.Character then return end
    table.insert(selectedTargets, p)
    local hl = Instance.new("Highlight")
    hl.Adornee = p.Character
    hl.FillColor = Color3.fromRGB(255, 50, 50)
    hl.OutlineColor = Color3.fromRGB(255, 200, 50)
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0
    hl.Parent = p.Character
    table.insert(targetHighlights, hl)

    if targetHeader then
        targetHeader.Text = "  Targets: " .. #selectedTargets
    end
end

local function clearAllTargets()
    for _, hl in ipairs(targetHighlights) do
        if hl then hl:Destroy() end
    end
    selectedTargets = {}
    targetHighlights = {}
    targetCooldowns = {}
    if targetHeader then
        targetHeader.Text = "  Selected: None"
    end
end

-- ====================================================================
-- UI HELPER FUNCTIONS
-- ====================================================================

local function corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius)
end

local function makeStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or Color3.fromRGB(160, 60, 255)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.5
    return s
end

local function section(parent, y, text)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, -20, 0, 18)
    l.Position = UDim2.new(0, 10, 0, y)
    l.BackgroundTransparency = 1
    l.Text = "-- " .. text .. " --"
    l.TextColor3 = Color3.fromRGB(160, 100, 255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
end

local function makeToggle(parent, x, y, w, label, get, set)
    local bg = Instance.new("Frame", parent)
    bg.Size = UDim2.new(0, w, 0, 22)
    bg.Position = UDim2.new(0, x, 0, y)
    bg.BackgroundColor3 = Color3.fromRGB(20, 10, 35)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 0
    corner(bg, 4)

    local lbl = Instance.new("TextLabel", bg)
    lbl.Size = UDim2.new(0, w - 50, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(210, 200, 240)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", bg)
    btn.Size = UDim2.new(0, 36, 0, 16)
    btn.Position = UDim2.new(1, -40, 0, 3)
    btn.BackgroundColor3 = get() and Color3.fromRGB(50, 200, 80) or Color3.fromRGB(200, 50, 50)
    btn.BorderSizePixel = 0
    btn.Text = get() and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    corner(btn, 3)

    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, tweenInfo, {Size = UDim2.new(0, 38, 0, 17)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, tweenInfo, {Size = UDim2.new(0, 36, 0, 16)}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        set(not get())
        local newColor = get() and Color3.fromRGB(50, 200, 80) or Color3.fromRGB(200, 50, 50)
        TweenService:Create(btn, tweenInfo, {BackgroundColor3 = newColor}):Play()
        btn.Text = get() and "ON" or "OFF"
    end)
end

local function makeSlider(parent, x, y, w, label, get, set, minV, maxV, step, fmt)
    step = step or 1
    fmt = fmt or "%.0f"
    local h = 26

    local bg = Instance.new("Frame", parent)
    bg.Size = UDim2.new(0, w, 0, h)
    bg.Position = UDim2.new(0, x, 0, y)
    bg.BackgroundColor3 = Color3.fromRGB(20, 10, 35)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 0
    corner(bg, 4)

    local lbl = Instance.new("TextLabel", bg)
    lbl.Size = UDim2.new(0, w - 90, 0, 14)
    lbl.Position = UDim2.new(0, 6, 0, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(200, 200, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valBtn = Instance.new("TextButton", bg)
    valBtn.Size = UDim2.new(0, 60, 0, 14)
    valBtn.Position = UDim2.new(1, -66, 0, 1)
    valBtn.BackgroundColor3 = Color3.fromRGB(35, 22, 55)
    valBtn.BorderSizePixel = 0
    valBtn.Text = string.format(fmt, get() or 0)
    valBtn.TextColor3 = Color3.fromRGB(255, 210, 100)
    valBtn.Font = Enum.Font.GothamBold
    valBtn.TextSize = 9
    corner(valBtn, 3)

    local inputBox = Instance.new("TextBox", bg)
    inputBox.Size = UDim2.new(0, 60, 0, 14)
    inputBox.Position = UDim2.new(1, -66, 0, 1)
    inputBox.BackgroundColor3 = Color3.fromRGB(35, 22, 55)
    inputBox.BorderSizePixel = 0
    inputBox.Text = string.format(fmt, get() or 0)
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 200)
    inputBox.Font = Enum.Font.GothamBold
    inputBox.TextSize = 9
    inputBox.ClearTextOnFocus = true
    inputBox.ZIndex = 20
    inputBox.Visible = false
    corner(inputBox, 3)

    local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    valBtn.MouseEnter:Connect(function()
        TweenService:Create(valBtn, ti, {BackgroundColor3 = Color3.fromRGB(50, 30, 80)}):Play()
    end)
    valBtn.MouseLeave:Connect(function()
        TweenService:Create(valBtn, ti, {BackgroundColor3 = Color3.fromRGB(35, 22, 55)}):Play()
    end)

    valBtn.MouseButton1Click:Connect(function()
        valBtn.Visible = false
        inputBox.Visible = true
        inputBox:CaptureFocus()
    end)

    inputBox.FocusLost:Connect(function()
        local num = tonumber(inputBox.Text)
        if num then
            num = math.clamp(num, minV, maxV)
            num = math.floor(num / step + 0.5) * step
            set(num)
        end
        valBtn.Text = string.format(fmt, get() or 0)
        inputBox.Text = string.format(fmt, get() or 0)
        inputBox.Visible = false
        valBtn.Visible = true
    end)

    local track = Instance.new("Frame", bg)
    track.Size = UDim2.new(0, w - 70, 0, 4)
    track.Position = UDim2.new(0, 6, 0, 18)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    track.BorderSizePixel = 0
    corner(track, 2)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(math.clamp((get() or 0) - minV / (maxV - minV), 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(130, 50, 255)
    fill.BorderSizePixel = 0
    corner(fill, 2)

    local trackBtn = Instance.new("TextButton", track)
    trackBtn.Size = UDim2.new(1, 0, 1, 0)
    trackBtn.BackgroundTransparency = 1
    trackBtn.Text = ""

    local dragging = false
    trackBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local mPos = UserInputService:GetMouseLocation()
            local absX = track.AbsolutePosition.X
            local absW = track.AbsoluteSize.X
            if absW <= 0 then return end
            local pct = math.clamp((mPos.X - absX) / absW, 0, 1)
            local val = minV + pct * (maxV - minV)
            val = math.floor(val / step + 0.5) * step
            val = math.clamp(val, minV, maxV)
            set(val)
            valBtn.Text = string.format(fmt, val)
            fill.Size = UDim2.new(math.clamp((val - minV) / (maxV - minV), 0, 1), 0, 1, 0)
        end
    end)
end

local function makeButton(parent, x, y, w, h, txt, cb, col)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0, w, 0, h)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = col or Color3.fromRGB(130, 50, 255)
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(240, 230, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    corner(b, 4)

    local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local origSize = UDim2.new(0, w, 0, h)
    local hoverSize = UDim2.new(0, w + 4, 0, h + 2)

    b.MouseEnter:Connect(function()
        TweenService:Create(b, ti, {Size = hoverSize, BackgroundColor3 = Color3.fromRGB(
            math.min(b.BackgroundColor3.R * 255 + 20, 255),
            math.min(b.BackgroundColor3.G * 255 + 20, 255),
            math.min(b.BackgroundColor3.B * 255 + 20, 255)
        )}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, ti, {Size = origSize, BackgroundColor3 = col or Color3.fromRGB(130, 50, 255)}):Play()
    end)

    if cb then
        b.MouseButton1Click:Connect(cb)
    end
end

-- ====================================================================
-- ИНТРО
-- ====================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "RPGSys"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
gui.Parent = game:GetService("CoreGui")
gui.Enabled = false

local introGui = Instance.new("ScreenGui")
introGui.Name = "RPGIntro"
introGui.DisplayOrder = 1000
introGui.ResetOnSpawn = false
introGui.IgnoreGuiInset = true
introGui.Parent = game:GetService("CoreGui")

local skipIntro = false
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F2 then
        skipIntro = true
    end
end)

-- Фон интро
local overlay = Instance.new("Frame", introGui)
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0

-- 8 колец
local rings = {}
for i = 1, 8 do
    local r = Instance.new("Frame", introGui)
    local w = 90 + i * 100
    local h = 8 + i * 12
    r.Size = UDim2.new(0, w, 0, h)
    r.Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2)
    r.BackgroundTransparency = 1
    r.BorderSizePixel = 0
    local st = Instance.new("UIStroke", r)
    st.Color = Color3.fromRGB(160, 60, 255)
    st.Thickness = 0.8 + i * 0.35
    st.Transparency = 0.18 + i * 0.07
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, h / 2)
    table.insert(rings, {
        frame = r,
        spd = (0.04 - i * 0.005) * (i % 2 == 0 and 1 or -1),
        ang = 0,
    })
end

-- 80 частиц
local parts = {}
for i = 1, 80 do
    local d = Instance.new("Frame", introGui)
    local s = 1 + math.random() * 3
    d.Size = UDim2.new(0, s, 0, s)
    d.Position = UDim2.new(math.random(), 0, math.random(), 0)
    d.BackgroundColor3 = Color3.fromHSV(0.7 + math.random() * 0.15, 0.6, 0.9)
    d.BorderSizePixel = 0
    Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
    d.BackgroundTransparency = 0.2 + math.random() * 0.4
    table.insert(parts, {
        f = d,
        dx = (math.random() - 0.5) * 0.004,
        dy = (math.random() - 0.5) * 0.004,
        px = d.Position.X.Scale,
        py = d.Position.Y.Scale,
        ph = math.random() * 6.28,
    })
end

-- 20 ромбов
local diamonds = {}
for i = 1, 20 do
    local d = Instance.new("Frame", introGui)
    local s = 4 + math.random() * 6
    d.Size = UDim2.new(0, s, 0, s)
    d.Position = UDim2.new(math.random(), 0, math.random(), 0)
    d.BorderSizePixel = 0
    d.Rotation = math.random() * 360
    d.BackgroundColor3 = Color3.fromHSV(0.7 + math.random() * 0.2, 0.5, 0.8)
    table.insert(diamonds, {
        f = d,
        dx = (math.random() - 0.5) * 0.0025,
        dy = (math.random() - 0.5) * 0.0025,
        px = math.random(),
        py = math.random(),
        rs = (math.random() - 0.5) * 0.15,
        ang = math.random() * 360,
    })
end

-- 12 крестов
local crosses = {}
for i = 1, 12 do
    local c = Instance.new("Frame", introGui)
    local sz = 10 + math.random() * 8
    c.Size = UDim2.new(0, sz, 0, sz)
    c.Position = UDim2.new(math.random(), 0, math.random(), 0)
    c.BackgroundTransparency = 1
    c.BorderSizePixel = 0
    local v = Instance.new("Frame", c)
    v.Size = UDim2.new(0, 2, 0, sz)
    v.Position = UDim2.new(0.5, -1, 0, 0)
    v.BackgroundColor3 = Color3.fromHSV(0.75 + math.random() * 0.15, 0.5, 0.8)
    v.BorderSizePixel = 0
    local h = Instance.new("Frame", c)
    h.Size = UDim2.new(0, sz, 0, 2)
    h.Position = UDim2.new(0, 0, 0.5, -1)
    h.BackgroundColor3 = Color3.fromHSV(0.75 + math.random() * 0.15, 0.5, 0.8)
    h.BorderSizePixel = 0
    table.insert(crosses, {
        f = c,
        dx = (math.random() - 0.5) * 0.003,
        dy = (math.random() - 0.5) * 0.003,
        px = math.random(),
        py = math.random(),
        rs = (math.random() - 0.5) * 0.12,
        ang = math.random() * 360,
    })
end

-- 10 сфер
local orbs = {}
for i = 1, 10 do
    local o = Instance.new("Frame", introGui)
    local sz = 18 + math.random() * 22
    o.Size = UDim2.new(0, sz, 0, sz)
    o.Position = UDim2.new(math.random(), 0, math.random(), 0)
    o.BackgroundColor3 = Color3.fromHSV(0.75 + math.random() * 0.1, 0.35, 0.6 + math.random() * 0.2)
    o.BackgroundTransparency = 0.65
    o.BorderSizePixel = 0
    Instance.new("UICorner", o).CornerRadius = UDim.new(1, 0)
    local g = Instance.new("UIStroke", o)
    g.Color = Color3.fromHSV(0.75 + math.random() * 0.1, 0.4, 0.7)
    g.Thickness = 2.5
    g.Transparency = 0.75
    table.insert(orbs, {
        f = o,
        dx = (math.random() - 0.5) * 0.0015,
        dy = (math.random() - 0.5) * 0.0015,
        px = math.random(),
        py = math.random(),
        ph = math.random() * 6.28,
    })
end

-- Панель интро (стекло)
local panel = Instance.new("Frame", introGui)
panel.Size = UDim2.new(0, 460, 0, 100)
panel.Position = UDim2.new(0.5, -230, 0.5, -115)
panel.BackgroundTransparency = 1
panel.BackgroundColor3 = Color3.fromRGB(12, 4, 28)
panel.BorderSizePixel = 0
corner(panel, 16)

local pnlGlow = Instance.new("UIStroke", panel)
pnlGlow.Color = Color3.fromRGB(180, 70, 255)
pnlGlow.Thickness = 2
pnlGlow.Transparency = 0.55

local pnlInner = Instance.new("Frame", panel)
pnlInner.Size = UDim2.new(1, -8, 1, -8)
pnlInner.Position = UDim2.new(0, 4, 0, 4)
pnlInner.BackgroundColor3 = Color3.fromRGB(80, 20, 160)
pnlInner.BackgroundTransparency = 0.9
pnlInner.BorderSizePixel = 0
corner(pnlInner, 13)

local pnlGrad = Instance.new("UIGradient", panel)
pnlGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 12, 90)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(18, 6, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 12, 90)),
})
pnlGrad.Transparency = NumberSequence.new(0.25)

-- Вращающееся кольцо вокруг панели
local spinRing = Instance.new("Frame", introGui)
spinRing.Size = UDim2.new(0, 500, 0, 170)
spinRing.Position = UDim2.new(0.5, -250, 0.5, -85)
spinRing.BackgroundTransparency = 1
spinRing.BorderSizePixel = 0
spinRing.ZIndex = 0

local spinStroke = Instance.new("UIStroke", spinRing)
spinStroke.Color = Color3.fromRGB(160, 60, 255)
spinStroke.Thickness = 1.5
spinStroke.Transparency = 0.6
Instance.new("UICorner", spinRing).CornerRadius = UDim.new(0, 16)

-- Светящиеся линии по кругу
local energyLines = {}
for i = 1, 4 do
    local line = Instance.new("Frame", introGui)
    line.Size = UDim2.new(0, 2, 0, 40)
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Position = UDim2.new(0.5, 0, 0.5, 0)
    line.BackgroundColor3 = Color3.fromHSV(0.75 + i * 0.05, 0.5, 0.9)
    line.BackgroundTransparency = 0.5
    line.BorderSizePixel = 0
    line.Rotation = i * 90
    line.ZIndex = 0
    Instance.new("UICorner", line).CornerRadius = UDim.new(1, 0)
    table.insert(energyLines, {
        frame = line,
        baseAngle = i * 90,
    })
end

-- Заголовок
local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1, -24, 0, 50)
title.Position = UDim2.new(0, 12, 0, 6)
title.BackgroundTransparency = 1
title.Text = "GOD OF THE RPG"
title.TextColor3 = Color3.fromRGB(240, 160, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 38
title.TextTransparency = 1

local sub = Instance.new("TextLabel", panel)
sub.Size = UDim2.new(1, -24, 0, 18)
sub.Position = UDim2.new(0, 12, 0, 56)
sub.BackgroundTransparency = 1
sub.Text = "War Tycoon"
sub.TextColor3 = Color3.fromRGB(200, 120, 255)
sub.Font = Enum.Font.Gotham
sub.TextSize = 14
sub.TextTransparency = 1

local scorpio = Instance.new("TextLabel", panel)
scorpio.Size = UDim2.new(1, -24, 0, 16)
scorpio.Position = UDim2.new(0, 12, 0, 74)
scorpio.BackgroundTransparency = 1
scorpio.Text = "By Scorpio & nazarkus1337"
scorpio.TextColor3 = Color3.fromRGB(150, 90, 210)
scorpio.Font = Enum.Font.Gotham
scorpio.TextSize = 11
scorpio.TextTransparency = 1

local dots = Instance.new("TextLabel", introGui)
dots.Size = UDim2.new(0, 60, 0, 16)
dots.Position = UDim2.new(0.5, -30, 0.5, 65)
dots.BackgroundTransparency = 1
dots.Text = ""
dots.TextColor3 = Color3.fromRGB(160, 80, 255)
dots.Font = Enum.Font.GothamBold
dots.TextSize = 18

-- ====================================================================
-- ФУНКЦИЯ АНИМАЦИИ ИНТРО
-- ====================================================================
local function animIntro(frame)
    for _, o in ipairs(parts) do
        o.px = (o.px + o.dx) % 1
        o.py = (o.py + o.dy) % 1
        o.f.Position = UDim2.new(o.px, 0, o.py, 0)
        o.f.BackgroundTransparency = 0.2 + math.sin(frame * 0.02 + o.ph) * 0.15
    end

    for i2, r in ipairs(rings) do
        r.ang = (r.ang + r.spd) % 360
        r.frame.Rotation = r.ang
        local st = r.frame:FindFirstChildOfClass("UIStroke")
        if st then
            local hue = 0.75 + math.sin(frame * 0.012 + i2 * 0.4) * 0.05
            st.Color = Color3.fromHSV(hue, 0.7, 0.8 + math.sin(frame * 0.02 + i2) * 0.1)
        end
    end

    for _, d in ipairs(diamonds) do
        d.px = (d.px + d.dx) % 1
        d.py = (d.py + d.dy) % 1
        d.ang = (d.ang + d.rs) % 360
        d.f.Position = UDim2.new(d.px, 0, d.py, 0)
        d.f.Rotation = d.ang
    end

    for _, c in ipairs(crosses) do
        c.px = (c.px + c.dx) % 1
        c.py = (c.py + c.dy) % 1
        c.ang = (c.ang + c.rs) % 360
        c.f.Position = UDim2.new(c.px, 0, c.py, 0)
        c.f.Rotation = c.ang
    end

    for _, o in ipairs(orbs) do
        o.px = (o.px + o.dx) % 1
        o.py = (o.py + o.dy) % 1
        o.f.Position = UDim2.new(o.px, 0, o.py, 0)
        o.f.BackgroundTransparency = 0.5 + math.sin(frame * 0.008 + o.ph) * 0.2
    end

    if spinRing then
        spinRing.Rotation = (spinRing.Rotation + 0.5) % 360
    end

    for _, el in ipairs(energyLines) do
        el.frame.Rotation = el.baseAngle + frame * 0.8
    end
end

local function fadeAllElements()
    for _, o in ipairs(parts) do
        TweenService:Create(o.f, TweenInfo.new(2, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0),
        }):Play()
    end

    for _, r in ipairs(rings) do
        local st = r.frame:FindFirstChildOfClass("UIStroke")
        if st then
            TweenService:Create(st, TweenInfo.new(2), {Transparency = 1}):Play()
        end
    end

    for _, d in ipairs(diamonds) do
        TweenService:Create(d.f, TweenInfo.new(2), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0),
        }):Play()
    end

    for _, c in ipairs(crosses) do
        for _, child in ipairs(c.f:GetChildren()) do
            if child:IsA("Frame") then
                TweenService:Create(child, TweenInfo.new(2), {BackgroundTransparency = 1}):Play()
            end
        end
    end

    for _, o in ipairs(orbs) do
        TweenService:Create(o.f, TweenInfo.new(2), {BackgroundTransparency = 1}):Play()
        local st = o.f:FindFirstChildOfClass("UIStroke")
        if st then
            TweenService:Create(st, TweenInfo.new(2), {Transparency = 1}):Play()
        end
    end

    TweenService:Create(panel, TweenInfo.new(2), {BackgroundTransparency = 1}):Play()
    TweenService:Create(pnlInner, TweenInfo.new(2), {BackgroundTransparency = 1}):Play()
    if spinStroke then
        TweenService:Create(spinStroke, TweenInfo.new(2), {Transparency = 1}):Play()
    end
    for _, el in ipairs(energyLines) do
        TweenService:Create(el.frame, TweenInfo.new(2), {BackgroundTransparency = 1}):Play()
    end
end

-- ====================================================================
-- ФАЗЫ ИНТРО
-- ====================================================================

-- ФАЗА 1: появление (9 сек)
for i = 0, 270 do
    if skipIntro then break end
    task.wait()
    overlay.BackgroundTransparency = 1 - i / 270
    animIntro(i)

    if i < 135 then
        local tp = i / 135
        title.TextTransparency = 1 - tp
        sub.TextTransparency = 1 - tp
        scorpio.TextTransparency = 1 - tp
        panel.BackgroundTransparency = 1 - tp * 0.75
    end

    if i == 67 then dots.Text = "." end
    if i == 135 then dots.Text = ".." end
    if i == 200 then dots.Text = "..." end
end

if skipIntro then
    introGui:Destroy()
end

if not skipIntro then
    -- ФАЗА 2: текст пропадает, фон остаётся чёрным (6 сек)
    overlay.BackgroundTransparency = 0
    panel.BackgroundTransparency = 0.25
    title.TextTransparency = 0
    sub.TextTransparency = 0
    scorpio.TextTransparency = 0

    for i = 0, 180 do
        task.wait()
        animIntro(i)
        if i < 90 then
            local tp = i / 90
            title.TextTransparency = tp
            sub.TextTransparency = tp
            scorpio.TextTransparency = tp
        end
    end

    title.TextTransparency = 1
    sub.TextTransparency = 1
    scorpio.TextTransparency = 1
    overlay.BackgroundTransparency = 0
    dots.Text = ""

    -- ФАЗА 3: вопрос READY? на чёрном фоне
    panel.Size = UDim2.new(0, 460, 0, 140)
    panel.Position = UDim2.new(0.5, -230, 0.5, -120)

    local ready = Instance.new("TextLabel", panel)
    ready.Size = UDim2.new(1, -24, 0, 50)
    ready.Position = UDim2.new(0, 12, 0, 12)
    ready.BackgroundTransparency = 1
    ready.Text = "READY?"
    ready.TextColor3 = Color3.fromRGB(200, 120, 255)
    ready.Font = Enum.Font.GothamBold
    ready.TextSize = 42
    ready.TextTransparency = 1

    local yes = Instance.new("TextButton", panel)
    yes.Size = UDim2.new(0, 140, 0, 42)
    yes.Position = UDim2.new(0.5, -150, 0, 80)
    yes.BackgroundColor3 = Color3.fromRGB(30, 120, 40)
    yes.BackgroundTransparency = 1
    yes.Text = "YES"
    yes.TextColor3 = Color3.fromRGB(100, 255, 120)
    yes.TextTransparency = 1
    yes.Font = Enum.Font.GothamBold
    yes.TextSize = 18
    yes.BorderSizePixel = 0
    corner(yes, 8)
    Instance.new("UIStroke", yes).Color = Color3.fromRGB(60, 200, 80)

    local no = Instance.new("TextButton", panel)
    no.Size = UDim2.new(0, 140, 0, 42)
    no.Position = UDim2.new(0.5, 10, 0, 80)
    no.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
    no.BackgroundTransparency = 1
    no.Text = "NO"
    no.TextColor3 = Color3.fromRGB(255, 80, 80)
    no.TextTransparency = 1
    no.Font = Enum.Font.GothamBold
    no.TextSize = 18
    no.BorderSizePixel = 0
    corner(no, 8)
    Instance.new("UIStroke", no).Color = Color3.fromRGB(200, 60, 60)

    -- Появление вопроса (2 сек)
    for i = 0, 60 do
        task.wait()
        local p = i / 60
        ready.TextTransparency = 1 - p
        yes.BackgroundTransparency = 1 - p * 0.8
        yes.TextTransparency = 1 - p
        no.BackgroundTransparency = 1 - p * 0.8
        no.TextTransparency = 1 - p
        animIntro(i)
    end

    ready.TextTransparency = 0
    yes.BackgroundTransparency = 0.2
    yes.TextTransparency = 0
    no.BackgroundTransparency = 0.2
    no.TextTransparency = 0

    -- ФАЗА 4: ожидание (10 минут)
    local chosen = nil
    yes.MouseButton1Click:Connect(function() chosen = true end)
    no.MouseButton1Click:Connect(function() chosen = false end)

    local startTime = tick()
    for wt = 0, 36000 do
        if chosen then break end
        if (tick() - startTime) >= 600 then
            chosen = true
            break
        end
        task.wait()
        ready.TextColor3 = Color3.fromHSV(0.75 + math.sin(wt * 0.2) * 0.04, 0.6, 0.9)
        yes.BackgroundTransparency = 0.2 + math.sin(wt * 0.3) * 0.08
        no.BackgroundTransparency = 0.2 + math.sin(wt * 0.3) * 0.08
        animIntro(wt)
    end

    ready:Destroy()
    yes:Destroy()
    no:Destroy()

    if chosen == false then
        introGui:Destroy()
        gui:Destroy()
        alive = false
        return
    end

    -- ФАЗА 5: частицы исчезают → GUI появляется плавно
    fadeAllElements()
    task.wait(2.5)

    -- Плавное появление GUI через overlay
    gui.Enabled = true
    local guiOverlay = Instance.new("Frame", gui)
    guiOverlay.Size = UDim2.new(1, 0, 1, 0)
    guiOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    guiOverlay.BackgroundTransparency = 0
    guiOverlay.BorderSizePixel = 0
    guiOverlay.ZIndex = 9999

    for i = 0, 60 do
        task.wait()
        guiOverlay.BackgroundTransparency = i / 60
        overlay.BackgroundTransparency = 0.5 + i / 120
    end

    guiOverlay:Destroy()
    overlay.BackgroundTransparency = 1
    introGui:Destroy()
end
gui.Enabled = true

-- ====================================================================
-- ГЛАВНОЕ GUI (Wind UI Horizontal)
-- ====================================================================

local accent = Color3.fromRGB(60, 130, 246)
local bgDark = Color3.fromRGB(16, 20, 38)
local bgSide = Color3.fromRGB(20, 24, 45)
local bgCard = Color3.fromRGB(24, 30, 55)
local bgHover = Color3.fromRGB(32, 40, 68)
local glassTransparency = 0.55
local textMain = Color3.fromRGB(230, 225, 250)
local textSub = Color3.fromRGB(130, 120, 165)
local textDim = Color3.fromRGB(80, 72, 110)
local SIDE = 76
local PW = 420
local PH = 420

-- Утилита: Wind UI Toggle
local function windToggle(parent, y, label, get, set)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -16, 0, 30)
    row.Position = UDim2.new(0, 8, 0, y)
    row.BackgroundColor3 = bgCard
    row.BackgroundTransparency = glassTransparency
    row.BorderSizePixel = 0
    corner(row, 6)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -52, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = textMain
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(0, 36, 0, 18)
    track.Position = UDim2.new(1, -44, 0.5, -9)
    track.BackgroundColor3 = get() and accent or Color3.fromRGB(35, 42, 65)
    track.BackgroundTransparency = 0.3
    track.BorderSizePixel = 0
    corner(track, 9)

    local circle = Instance.new("Frame", track)
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = get() and UDim2.new(1, -16, 0, 2) or UDim2.new(0, 2, 0, 2)
    circle.BackgroundColor3 = Color3.new(1, 1, 1)
    circle.BorderSizePixel = 0
    corner(circle, 7)

    local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    row.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            set(not get())
            TweenService:Create(track, ti, {BackgroundColor3 = get() and accent or Color3.fromRGB(45, 40, 65)}):Play()
            TweenService:Create(circle, ti, {Position = get() and UDim2.new(1, -16, 0, 2) or UDim2.new(0, 2, 0, 2)}):Play()
        end
    end)
    return row
end

-- Утилита: Wind UI Slider
local function windSlider(parent, y, label, get, set, minV, maxV, step, fmt)
    step = step or 1
    fmt = fmt or "%.0f"

    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -16, 0, 38)
    row.Position = UDim2.new(0, 8, 0, y)
    row.BackgroundColor3 = bgCard
    row.BackgroundTransparency = glassTransparency
    row.BorderSizePixel = 0
    corner(row, 6)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.5, 0, 0, 16)
    lbl.Position = UDim2.new(0, 10, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = textSub
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valBtn = Instance.new("TextButton", row)
    valBtn.Size = UDim2.new(0, 52, 0, 16)
    valBtn.Position = UDim2.new(1, -62, 0, 6)
    valBtn.BackgroundColor3 = bgHover
    valBtn.BorderSizePixel = 0
    valBtn.Text = string.format(fmt, get() or 0)
    valBtn.TextColor3 = accent
    valBtn.Font = Enum.Font.GothamBold
    valBtn.TextSize = 10
    corner(valBtn, 3)

    local inputBox = Instance.new("TextBox", row)
    inputBox.Size = UDim2.new(0, 52, 0, 16)
    inputBox.Position = UDim2.new(1, -62, 0, 6)
    inputBox.BackgroundColor3 = bgHover
    inputBox.BorderSizePixel = 0
    inputBox.Text = string.format(fmt, get() or 0)
    inputBox.TextColor3 = Color3.new(1, 1, 1)
    inputBox.Font = Enum.Font.GothamBold
    inputBox.TextSize = 10
    inputBox.ClearTextOnFocus = true
    inputBox.Visible = false
    inputBox.ZIndex = 20
    corner(inputBox, 3)

    valBtn.MouseButton1Click:Connect(function()
        valBtn.Visible = false
        inputBox.Visible = true
        inputBox:CaptureFocus()
    end)
    inputBox.FocusLost:Connect(function()
        local num = tonumber(inputBox.Text)
        if num then
            num = math.clamp(num, minV, maxV)
            num = math.floor(num / step + 0.5) * step
            set(num)
        end
        valBtn.Text = string.format(fmt, get() or 0)
        inputBox.Text = string.format(fmt, get() or 0)
        inputBox.Visible = false
        valBtn.Visible = true
    end)

    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(1, -20, 0, 4)
    track.Position = UDim2.new(0, 10, 0, 28)
    track.BackgroundColor3 = Color3.fromRGB(30, 38, 60)
    track.BorderSizePixel = 0
    corner(track, 2)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(math.clamp((get() or 0) - minV / (maxV - minV), 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = accent
    fill.BorderSizePixel = 0
    corner(fill, 2)

    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(math.clamp((get() or 0) - minV / (maxV - minV), 0, 1), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 5
    corner(knob, 5)

    local dragging = false
    local trackBtn = Instance.new("TextButton", track)
    trackBtn.Size = UDim2.new(1, 0, 1, 0)
    trackBtn.BackgroundTransparency = 1
    trackBtn.Text = ""
    trackBtn.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local mPos = UserInputService:GetMouseLocation()
            local absX = track.AbsolutePosition.X
            local absW = track.AbsoluteSize.X
            if absW <= 0 then return end
            local pct = math.clamp((mPos.X - absX) / absW, 0, 1)
            local val = minV + pct * (maxV - minV)
            val = math.floor(val / step + 0.5) * step
            val = math.clamp(val, minV, maxV)
            set(val)
            valBtn.Text = string.format(fmt, val)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, 0, 0.5, 0)
        end
    end)
    return row
end

-- Утилита: Wind UI Section
local function windSection(parent, y, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, -16, 0, 16)
    lbl.Position = UDim2.new(0, 8, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(text)
    lbl.TextColor3 = textDim
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    return y + 18
end

-- Утилита: Wind UI Button
local function windButton(parent, x, y, w, h, text, cb, col)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0, w, 0, h)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = col or bgHover
    b.BackgroundTransparency = 0.4
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = textMain
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    corner(b, 5)
    local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    b.MouseEnter:Connect(function() TweenService:Create(b, ti, {BackgroundColor3 = accent}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, ti, {BackgroundColor3 = col or bgHover}):Play() end)
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

-- ===== ОСНОВНАЯ ПАНЕЛЬ (горизонтальная) =====
local bg = Instance.new("Frame", gui)
bg.Name = "Main"
bg.Size = UDim2.new(0, SIDE + PW + 4, 0, PH + 80)
bg.Position = UDim2.new(0.5, -(SIDE + PW + 4) / 2, 0.5, -(PH + 80) / 2)
bg.BackgroundColor3 = bgDark
bg.BackgroundTransparency = 0.5
bg.BorderSizePixel = 0
bg.Active = true
bg.Draggable = true
bg.ClipsDescendants = true
corner(bg, 12)
makeStroke(bg, accent, 1, 0.8)

-- Accent-линия сверху панели
local topLine = Instance.new("Frame", bg)
topLine.Size = UDim2.new(1, 0, 0, 2)
topLine.Position = UDim2.new(0, 0, 0, 0)
topLine.BackgroundColor3 = accent
topLine.BackgroundTransparency = 0.3
topLine.BorderSizePixel = 0
corner(topLine, 1)

-- Вращающиеся фигуры на фоне
local bgShapes = {}
local shapeColors = {
    Color3.fromRGB(60, 130, 246),
    Color3.fromRGB(80, 100, 200),
    Color3.fromRGB(40, 80, 180),
    Color3.fromRGB(100, 140, 255),
    Color3.fromRGB(50, 90, 190),
}
for i = 1, 5 do
    local shape = Instance.new("Frame", bg)
    local size = 20 + math.random() * 40
    shape.Size = UDim2.new(0, size, 0, size)
    shape.Position = UDim2.new(math.random() * 0.8 + 0.1, 0, math.random() * 0.8 + 0.1, 0)
    shape.BackgroundColor3 = shapeColors[i]
    shape.BackgroundTransparency = 0.88
    shape.BorderSizePixel = 0
    shape.ZIndex = -1
    shape.Rotation = math.random() * 360
    corner(shape, size / 2)
    local st = Instance.new("UIStroke", shape)
    st.Color = shapeColors[i]
    st.Thickness = 1
    st.Transparency = 0.8
    table.insert(bgShapes, {
        f = shape,
        spd = (0.15 + math.random() * 0.3) * (i % 2 == 0 and 1 or -1),
        ang = math.random() * 360,
    })
end

-- ===== САЙДБАР =====
local sidebar = Instance.new("Frame", bg)
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, SIDE, 1, 0)
sidebar.BackgroundColor3 = bgSide
sidebar.BackgroundTransparency = 0.55
sidebar.BorderSizePixel = 0
corner(sidebar, 12)

-- Accent-линия сверху сайдбара
local accentLine = Instance.new("Frame", sidebar)
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.Position = UDim2.new(0, 0, 0, 0)
accentLine.BackgroundColor3 = accent
accentLine.BorderSizePixel = 0
corner(accentLine, 1)

-- Разделитель сайдбар ↔ контент
local sideDiv = Instance.new("Frame", bg)
sideDiv.Size = UDim2.new(0, 1, 1, -4)
sideDiv.Position = UDim2.new(0, SIDE + 1, 0, 2)
sideDiv.BackgroundColor3 = accent
sideDiv.BackgroundTransparency = 0.9
sideDiv.BorderSizePixel = 0

-- Заголовок в сайдбаре
local logo = Instance.new("TextLabel", sidebar)
logo.Size = UDim2.new(1, 0, 0, 18)
logo.Position = UDim2.new(0, 0, 0, 6)
logo.BackgroundTransparency = 1
logo.Text = "GOD OF THE RPG"
logo.TextColor3 = accent
logo.Font = Enum.Font.GothamBlack
logo.TextSize = 9
logo.TextWrapped = true
logo.TextXAlignment = Enum.TextXAlignment.Center

-- Кнопки горизонтально над логотипом
local btnY = 26
local btnW = math.floor((SIDE - 12) / 3)

-- Шестерёнка
local gearBtn = Instance.new("TextButton", sidebar)
gearBtn.Size = UDim2.new(0, btnW, 0, 14)
gearBtn.Position = UDim2.new(0, 4, 0, btnY)
gearBtn.BackgroundColor3 = bgHover
gearBtn.BackgroundTransparency = 0.5
gearBtn.BorderSizePixel = 0
gearBtn.Text = "*"
gearBtn.TextColor3 = textSub
gearBtn.Font = Enum.Font.GothamBold
gearBtn.TextSize = 10
corner(gearBtn, 3)
local gearTi = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
gearBtn.MouseEnter:Connect(function() TweenService:Create(gearBtn, gearTi, {BackgroundTransparency = 0.2, TextColor3 = accent}):Play() end)
gearBtn.MouseLeave:Connect(function() TweenService:Create(gearBtn, gearTi, {BackgroundTransparency = 0.5, TextColor3 = textSub}):Play() end)

-- Свернуть
local minBtn = Instance.new("TextButton", sidebar)
minBtn.Size = UDim2.new(0, btnW, 0, 14)
minBtn.Position = UDim2.new(0, 4 + btnW + 2, 0, btnY)
minBtn.BackgroundColor3 = bgHover
minBtn.BackgroundTransparency = 0.5
minBtn.BorderSizePixel = 0
minBtn.Text = "-"
minBtn.TextColor3 = textSub
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 10
corner(minBtn, 3)
minBtn.MouseEnter:Connect(function() TweenService:Create(minBtn, gearTi, {BackgroundTransparency = 0.2, TextColor3 = accent}):Play() end)
minBtn.MouseLeave:Connect(function() TweenService:Create(minBtn, gearTi, {BackgroundTransparency = 0.5, TextColor3 = textSub}):Play() end)
minBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

-- Закрыть
local closeBtn = Instance.new("TextButton", sidebar)
closeBtn.Size = UDim2.new(0, btnW, 0, 14)
closeBtn.Position = UDim2.new(0, 4 + (btnW + 2) * 2, 0, btnY)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
closeBtn.BackgroundTransparency = 0.5
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(200, 100, 100)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 9
corner(closeBtn, 3)
closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn, gearTi, {BackgroundTransparency = 0.1, TextColor3 = Color3.fromRGB(255, 80, 80)}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn, gearTi, {BackgroundTransparency = 0.5, TextColor3 = Color3.fromRGB(200, 100, 100)}):Play() end)
closeBtn.MouseButton1Click:Connect(function()
    alive = false
    hHeld = false
    flyHeld = false
    removeLocalVisual()
    if glowAtmo then glowAtmo:Destroy(); glowAtmo = nil end
    if bloomObj then bloomObj:Destroy(); bloomObj = nil end
    if ccObj then ccObj:Destroy(); ccObj = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    visualGui:Destroy()
    gui:Destroy()
end)

-- Шестерёнка → открывает Settings
gearBtn.MouseButton1Click:Connect(function()
    for idx, tb in ipairs(tabBtns) do
        TweenService:Create(tb, gearTi, {BackgroundTransparency = 1, TextColor3 = textSub, BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
    end
    -- Находим кнопку Settings
    for idx, name in ipairs(tabNames) do
        if name == "settings" and tabBtns[idx] then
            TweenService:Create(tabBtns[idx], gearTi, {BackgroundTransparency = 0.15, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = accent}):Play()
            break
        end
    end
    for _, p in ipairs(tabPages) do p.Visible = false end
    for idx, name in ipairs(tabNames) do
        if name == "settings" and tabPages[idx] then
            tabPages[idx].Visible = true
            break
        end
    end
end)

-- Табы в сайдбаре
local tabNames = {"combat", "visual", "misc", "settings", "info"}
local tabLabels = {combat = "Combat", visual = "Visual", misc = "Misc", settings = "Settings", info = "Info"}
local tabBtns = {}
local tabPages = {}
local contentArea = Instance.new("Frame", bg)
contentArea.Name = "Content"
contentArea.Size = UDim2.new(1, -SIDE - 4, 1, 0)
contentArea.Position = UDim2.new(0, SIDE + 4, 0, 0)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0

for i, name in ipairs(tabNames) do
    local by = 48 + (i - 1) * 38

    -- Активный индикатор (полоска слева)
    local indicator = Instance.new("Frame", sidebar)
    indicator.Size = UDim2.new(0, 2, 0, 16)
    indicator.Position = UDim2.new(0, 2, 0, by + 8)
    indicator.BackgroundColor3 = accent
    indicator.BorderSizePixel = 0
    corner(indicator, 1)
    indicator.BackgroundTransparency = (i == 1) and 0 or 1
    indicator.ZIndex = 5

    local b = Instance.new("TextButton", sidebar)
    b.Size = UDim2.new(1, -8, 0, 32)
    b.Position = UDim2.new(0, 4, 0, by)
    b.BackgroundColor3 = (i == 1) and accent or Color3.fromRGB(0, 0, 0)
    b.BackgroundTransparency = (i == 1) and 0.15 or 1
    b.BorderSizePixel = 0
    b.Text = tabLabels[name]
    b.TextColor3 = (i == 1) and Color3.new(1, 1, 1) or textSub
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    corner(b, 8)

    local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    b.MouseEnter:Connect(function()
        if not tabPages[i].Visible then
            TweenService:Create(b, ti, {BackgroundTransparency = 0.85, BackgroundColor3 = accent}):Play()
        end
    end)
    b.MouseLeave:Connect(function()
        if not tabPages[i].Visible then
            TweenService:Create(b, ti, {BackgroundTransparency = 1, BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
        end
    end)
    b.MouseButton1Click:Connect(function()
        for idx, tb in ipairs(tabBtns) do
            TweenService:Create(tb, ti, {BackgroundTransparency = 1, TextColor3 = textSub, BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
        end
        TweenService:Create(b, ti, {BackgroundTransparency = 0.15, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = accent}):Play()
        for _, p in ipairs(tabPages) do p.Visible = false end
        tabPages[i].Visible = true
    end)

    table.insert(tabBtns, b)

    local page = Instance.new("ScrollingFrame", contentArea)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = (i == 1)
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 4)
    Instance.new("UIPadding", page).PaddingTop = UDim.new(0, 6)
    Instance.new("UIPadding", page).PaddingLeft = UDim.new(0, 4)
    tabPages[i] = page
end

-- ===== ВКЛАДКА COMBAT (подвкладки на каждую функцию) =====
local combat = tabPages[1]
local combatTi = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- Панель подвкладок (скроллируемая)
local subBar = Instance.new("ScrollingFrame", combat)
subBar.Size = UDim2.new(1, 0, 0, 28)
subBar.Position = UDim2.new(0, 0, 0, 0)
subBar.BackgroundColor3 = bgCard
subBar.BackgroundTransparency = glassTransparency
subBar.BorderSizePixel = 0

local subNames = {"Fire", "Slow-Mo", "Cluster", "Homing", "Mega", "RocketJump", "CarDestroy", "BringAll", "Target"}

subBar.ScrollBarThickness = 0
subBar.CanvasSize = UDim2.new(0, #subNames * 68, 0, 0)
subBar.ScrollingDirection = Enum.ScrollingDirection.X
subBar.AutomaticCanvasSize = Enum.AutomaticSize.X
corner(subBar, 6)

local subBtns = {}
local subPages = {}

for i, name in ipairs(subNames) do
    local sw = 68
    local sb = Instance.new("TextButton", subBar)
    sb.Size = UDim2.new(0, sw - 2, 0, 22)
    sb.Position = UDim2.new(0, (i-1)*sw + 2, 0, 3)
    sb.Text = name
    sb.TextColor3 = textSub
    sb.BackgroundColor3 = (i==1) and accent or Color3.fromRGB(0, 0, 0)
    sb.BackgroundTransparency = (i==1) and 0.15 or 1
    sb.BorderSizePixel = 0
    sb.Font = Enum.Font.GothamBold
    sb.TextSize = 9
    corner(sb, 4)

    local sp = Instance.new("ScrollingFrame", combat)
    sp.Size = UDim2.new(1, -8, 1, -36)
    sp.Position = UDim2.new(0, 4, 0, 32)
    sp.BackgroundTransparency = 1
    sp.BorderSizePixel = 0
    sp.ScrollBarThickness = 2
    sp.ScrollBarImageColor3 = accent
    sp.CanvasSize = UDim2.new(0, 0, 0, 0)
    sp.Visible = (i == 1)
    Instance.new("UIListLayout", sp).Padding = UDim.new(0, 4)
    Instance.new("UIPadding", sp).PaddingTop = UDim.new(0, 4)
    Instance.new("UIPadding", sp).PaddingLeft = UDim.new(0, 4)

    sb.MouseButton1Click:Connect(function()
        for _, b in ipairs(subBtns) do
            TweenService:Create(b, combatTi, {BackgroundTransparency = 1, TextColor3 = textSub, BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
        end
        TweenService:Create(sb, combatTi, {BackgroundTransparency = 0.15, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = accent}):Play()
        for _, p in ipairs(subPages) do p.Visible = false end
        sp.Visible = true
    end)

    table.insert(subBtns, sb)
    table.insert(subPages, sp)
end

-- === Fire ===
local pFire = subPages[1]
local py1 = 4
py1 = windSection(pFire, py1, "Fire")
py1 = windToggle(pFire, py1, "Enabled", function() return S.Enabled end, function(v) S.Enabled = v end) and py1 + 34
py1 = windSlider(pFire, py1, "Rocket Count", function() return S.RocketCount end, function(v) S.RocketCount = v end, 1, 1e14, 1) and py1 + 42
py1 = windSlider(pFire, py1, "Spread", function() return S.Spread end, function(v) S.Spread = v end, 0, 1e9, 0.1) and py1 + 42
py1 = windSlider(pFire, py1, "Fire Rate", function() return S.FireRate end, function(v) S.FireRate = v end, -1, 99999, 0.01, "%.2f") and py1 + 42
py1 = windSection(pFire, py1, "Keybind")
local kbCard1 = Instance.new("Frame", pFire)
kbCard1.Size = UDim2.new(1, -8, 0, 24)
kbCard1.Position = UDim2.new(0, 4, 0, py1)
kbCard1.BackgroundColor3 = bgCard
kbCard1.BackgroundTransparency = glassTransparency
kbCard1.BorderSizePixel = 0
corner(kbCard1, 4)
local kbTxt1 = Instance.new("TextLabel", kbCard1)
kbTxt1.Size = UDim2.new(1, -8, 1, 0)
kbTxt1.Position = UDim2.new(0, 8, 0, 0)
kbTxt1.BackgroundTransparency = 1
kbTxt1.Text = "Hold H to fire"
kbTxt1.TextColor3 = textSub
kbTxt1.Font = Enum.Font.Gotham
kbTxt1.TextSize = 10
kbTxt1.TextXAlignment = Enum.TextXAlignment.Left
pFire.CanvasSize = UDim2.new(0, 0, 0, py1 + 30)

-- === Slow-Mo ===
local pSlow = subPages[2]
local py2 = 4
py2 = windSection(pSlow, py2, "Slow-Mo Rockets")
py2 = windToggle(pSlow, py2, "Enabled", function() return S.SlowMoEnabled end, function(v) S.SlowMoEnabled = v end) and py2 + 34
py2 = windSlider(pSlow, py2, "Speed", function() return S.SlowMoMult end, function(v) S.SlowMoMult = v end, 0.1, 1, 0.01, "%.2f") and py2 + 42
py2 = windSlider(pSlow, py2, "Count", function() return S.SlowMoCount end, function(v) S.SlowMoCount = v end, 1, 50, 1) and py2 + 42
py2 = windSlider(pSlow, py2, "Spread", function() return S.SlowMoSpread end, function(v) S.SlowMoSpread = v end, 0, 100, 1) and py2 + 42
py2 = windSection(pSlow, py2, "Info")
local infoSlow = Instance.new("TextLabel", pSlow)
infoSlow.Size = UDim2.new(1, -8, 0, 20)
infoSlow.Position = UDim2.new(0, 4, 0, py2)
infoSlow.BackgroundTransparency = 1
infoSlow.Text = "Press keybind to fire slow rockets"
infoSlow.TextColor3 = textDim
infoSlow.Font = Enum.Font.Gotham
infoSlow.TextSize = 9
infoSlow.TextXAlignment = Enum.TextXAlignment.Left
pSlow.CanvasSize = UDim2.new(0, 0, 0, py2 + 30)

-- === Cluster ===
local pClust = subPages[3]
local py3 = 4
py3 = windSection(pClust, py3, "Cluster Rockets")
py3 = windToggle(pClust, py3, "Enabled", function() return S.ClusterEnabled end, function(v) S.ClusterEnabled = v end) and py3 + 34
py3 = windSlider(pClust, py3, "Count", function() return S.ClusterCount end, function(v) S.ClusterCount = v end, 2, 20, 1) and py3 + 42
py3 = windSlider(pClust, py3, "Radius", function() return S.ClusterRadius end, function(v) S.ClusterRadius = v end, 5, 100, 1) and py3 + 42
py3 = windSection(pClust, py3, "Info")
local infoClust = Instance.new("TextLabel", pClust)
infoClust.Size = UDim2.new(1, -8, 0, 20)
infoClust.Position = UDim2.new(0, 4, 0, py3)
infoClust.BackgroundTransparency = 1
infoClust.Text = "Press keybind — rockets split on impact"
infoClust.TextColor3 = textDim
infoClust.Font = Enum.Font.Gotham
infoClust.TextSize = 9
infoClust.TextXAlignment = Enum.TextXAlignment.Left
pClust.CanvasSize = UDim2.new(0, 0, 0, py3 + 30)

-- === Homing ===
local pHom = subPages[4]
local py4 = 4
py4 = windSection(pHom, py4, "Homing Rockets")
py4 = windToggle(pHom, py4, "Enabled", function() return S.HomingEnabled end, function(v) S.HomingEnabled = v end) and py4 + 34
py4 = windSlider(pHom, py4, "Speed", function() return S.HomingSpeed end, function(v) S.HomingSpeed = v end, 0.5, 3, 0.1, "%.1f") and py4 + 42
py4 = windSection(pHom, py4, "Info")
local infoHom = Instance.new("TextLabel", pHom)
infoHom.Size = UDim2.new(1, -8, 0, 20)
infoHom.Position = UDim2.new(0, 4, 0, py4)
infoHom.BackgroundTransparency = 1
infoHom.Text = "Rockets follow selected target"
infoHom.TextColor3 = textDim
infoHom.Font = Enum.Font.Gotham
infoHom.TextSize = 9
infoHom.TextXAlignment = Enum.TextXAlignment.Left
pHom.CanvasSize = UDim2.new(0, 0, 0, py4 + 30)

-- === Mega ===
local pMega = subPages[5]
local py5 = 4
py5 = windSection(pMega, py5, "Mega Rocket")
py5 = windToggle(pMega, py5, "Enabled", function() return S.MegaEnabled end, function(v) S.MegaEnabled = v end) and py5 + 34
py5 = windSlider(pMega, py5, "Count", function() return S.MegaCount end, function(v) S.MegaCount = v end, 3, 15, 1) and py5 + 42
py5 = windSlider(pMega, py5, "Spread", function() return S.MegaSpread end, function(v) S.MegaSpread = v end, 0, 10, 0.5, "%.1f") and py5 + 42
py5 = windSection(pMega, py5, "Info")
local infoMega = Instance.new("TextLabel", pMega)
infoMega.Size = UDim2.new(1, -8, 0, 20)
infoMega.Position = UDim2.new(0, 4, 0, py5)
infoMega.BackgroundTransparency = 1
infoMega.Text = "Multiple rockets to one point"
infoMega.TextColor3 = textDim
infoMega.Font = Enum.Font.Gotham
infoMega.TextSize = 9
infoMega.TextXAlignment = Enum.TextXAlignment.Left
pMega.CanvasSize = UDim2.new(0, 0, 0, py5 + 30)

-- === Rocket Jump ===
local pJump = subPages[6]
local py6 = 4
py6 = windSection(pJump, py6, "Rocket Jump")
py6 = windToggle(pJump, py6, "Enabled", function() return S.RocketJumpEnabled end, function(v) S.RocketJumpEnabled = v end) and py6 + 34
py6 = windSlider(pJump, py6, "Power", function() return S.RocketJumpPower end, function(v) S.RocketJumpPower = v end, 50, 500, 10) and py6 + 42
py6 = windSection(pJump, py6, "Info")
local infoJump = Instance.new("TextLabel", pJump)
infoJump.Size = UDim2.new(1, -8, 0, 20)
infoJump.Position = UDim2.new(0, 4, 0, py6)
infoJump.BackgroundTransparency = 1
infoJump.Text = "Press keybind to launch up"
infoJump.TextColor3 = textDim
infoJump.Font = Enum.Font.Gotham
infoJump.TextSize = 9
infoJump.TextXAlignment = Enum.TextXAlignment.Left
pJump.CanvasSize = UDim2.new(0, 0, 0, py6 + 30)

-- === Car Destroy ===
local pCar = subPages[7]
local py7 = 4
py7 = windSection(pCar, py7, "Car Destroy")
py7 = windToggle(pCar, py7, "Enabled", function() return S.CarDestroyEnabled end, function(v) S.CarDestroyEnabled = v end) and py7 + 34
py7 = windSlider(pCar, py7, "Rockets", function() return S.CarDestroyCount end, function(v) S.CarDestroyCount = v end, 1, 50, 1) and py7 + 42
py7 = windSlider(pCar, py7, "Range", function() return S.CarDestroyRange end, function(v) S.CarDestroyRange = v end, 50, 500, 10) and py7 + 42
py7 = windSection(pCar, py7, "Info")
local infoCar = Instance.new("TextLabel", pCar)
infoCar.Size = UDim2.new(1, -8, 0, 20)
infoCar.Position = UDim2.new(0, 4, 0, py7)
infoCar.BackgroundTransparency = 1
infoCar.Text = "Press keybind — destroy nearby vehicles"
infoCar.TextColor3 = textDim
infoCar.Font = Enum.Font.Gotham
infoCar.TextSize = 9
infoCar.TextXAlignment = Enum.TextXAlignment.Left
pCar.CanvasSize = UDim2.new(0, 0, 0, py7 + 30)

-- === Bring All ===
local pBring = subPages[8]
local py8 = 4
py8 = windSection(pBring, py8, "Bring All")
py8 = windToggle(pBring, py8, "Enabled", function() return S.BringAllEnabled end, function(v) S.BringAllEnabled = v end) and py8 + 34
py8 = windSection(pBring, py8, "Info")
local infoBring = Instance.new("TextLabel", pBring)
infoBring.Size = UDim2.new(1, -8, 0, 20)
infoBring.Position = UDim2.new(0, 4, 0, py8)
infoBring.BackgroundTransparency = 1
infoBring.Text = "Press keybind — all players to you"
infoBring.TextColor3 = textDim
infoBring.Font = Enum.Font.Gotham
infoBring.TextSize = 9
infoBring.TextXAlignment = Enum.TextXAlignment.Left
pBring.CanvasSize = UDim2.new(0, 0, 0, py8 + 30)

-- === Target ===
local pTgt = subPages[9]
local py9 = 4

targetHeader = Instance.new("TextLabel", pTgt)
targetHeader.Size = UDim2.new(1, -8, 0, 26)
targetHeader.Position = UDim2.new(0, 4, 0, py9)
targetHeader.BackgroundColor3 = bgCard
targetHeader.BackgroundTransparency = glassTransparency
targetHeader.BorderSizePixel = 0
targetHeader.Text = "  Selected: None"
targetHeader.TextColor3 = textMain
targetHeader.Font = Enum.Font.GothamBold
targetHeader.TextSize = 11
targetHeader.TextXAlignment = Enum.TextXAlignment.Left
corner(targetHeader, 6)
py9 = py9 + 30

local btnRow = Instance.new("Frame", pTgt)
btnRow.Size = UDim2.new(1, -8, 0, 26)
btnRow.Position = UDim2.new(0, 4, 0, py9)
btnRow.BackgroundTransparency = 1
btnRow.BorderSizePixel = 0
local bw = math.floor((PW - 24) / 3)
windButton(btnRow, 0, 0, bw, 24, "Refresh", function() refreshList() end)
windButton(btnRow, bw + 4, 0, bw, 24, "Select All", function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local found = false
            for _, t in ipairs(selectedTargets) do if t == p then found = true; break end end
            if not found then toggleTarget(p) end
        end
    end
    refreshList()
end)
windButton(btnRow, (bw + 4) * 2, 0, bw, 24, "Clear", function() clearAllTargets() end)
py9 = py9 + 30

py9 = windSection(pTgt, py9, "Target Spam")
py9 = windToggle(pTgt, py9, "Target Spam", function() return S.TargetSpam end, function(v) S.TargetSpam = v end) and py9 + 34
py9 = windSlider(pTgt, py9, "Rockets / tick", function() return S.TargetSpamMult end, function(v) S.TargetSpamMult = v end, 1, 1e14, 1) and py9 + 42
py9 = windSlider(pTgt, py9, "Tick Rate", function() return S.TargetSpamRate end, function(v) S.TargetSpamRate = v end, 0.01, 5, 0.01, "%.2f") and py9 + 42
py9 = windToggle(pTgt, py9, "Target Cycle", function() return S.TargetCycle end, function(v) S.TargetCycle = v end) and py9 + 34
py9 = windSlider(pTgt, py9, "Cycle Interval", function() return S.TargetCycleInterval end, function(v) S.TargetCycleInterval = v end, 0.1, 5, 0.1, "%.1f") and py9 + 42

py9 = windSection(pTgt, py9, "Kill Distance")
local killRow = Instance.new("Frame", pTgt)
killRow.Size = UDim2.new(1, -8, 0, 30)
killRow.Position = UDim2.new(0, 4, 0, py9)
killRow.BackgroundColor3 = bgCard
killRow.BackgroundTransparency = glassTransparency
killRow.BorderSizePixel = 0
corner(killRow, 6)
local killLbl = Instance.new("TextLabel", killRow)
killLbl.Size = UDim2.new(0.5, 0, 1, 0)
killLbl.Position = UDim2.new(0, 10, 0, 0)
killLbl.BackgroundTransparency = 1
killLbl.Text = "Kill Distance"
killLbl.TextColor3 = textSub
killLbl.Font = Enum.Font.GothamMedium
killLbl.TextSize = 11
killLbl.TextXAlignment = Enum.TextXAlignment.Left
local killInput = Instance.new("TextBox", killRow)
killInput.Size = UDim2.new(0, 100, 0, 20)
killInput.Position = UDim2.new(1, -110, 0.5, -10)
killInput.BackgroundColor3 = bgHover
killInput.BackgroundTransparency = 0.3
killInput.BorderSizePixel = 0
killInput.Text = tostring(S.KillDistance)
killInput.TextColor3 = accent
killInput.Font = Enum.Font.GothamBold
killInput.TextSize = 11
killInput.ClearTextOnFocus = true
corner(killInput, 4)
killInput.FocusLost:Connect(function()
    if killInput.Text ~= "" then S.KillDistance = killInput.Text end
    killInput.Text = tostring(S.KillDistance)
end)
py9 = py9 + 34

py9 = windSection(pTgt, py9, "Players")
local targetList = Instance.new("ScrollingFrame", pTgt)
targetList.Size = UDim2.new(1, -8, 0, 120)
targetList.Position = UDim2.new(0, 4, 0, py9)
targetList.BackgroundColor3 = bgCard
targetList.BackgroundTransparency = glassTransparency
targetList.BorderSizePixel = 0
targetList.ScrollBarThickness = 2
targetList.ScrollBarImageColor3 = accent
corner(targetList, 6)
Instance.new("UIListLayout", targetList).Padding = UDim.new(0, 3)
Instance.new("UIPadding", targetList).PaddingTop = UDim.new(0, 3)

local playerButtons = {}
local function refreshList()
    for _, b in ipairs(playerButtons) do b:Destroy() end
    playerButtons = {}
    local sorted = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then table.insert(sorted, p) end
    end
    table.sort(sorted, function(a, b) return a.Name < b.Name end)
    for _, p in ipairs(sorted) do
        local b = Instance.new("TextButton", targetList)
        b.Size = UDim2.new(1, -6, 0, 22)
        b.Position = UDim2.new(0, 3, 0, 0)
        b.BorderSizePixel = 0
        local isTarget = false
        for _, t in ipairs(selectedTargets) do if t == p then isTarget = true; break end end
        b.BackgroundColor3 = isTarget and accent or bgHover
        b.BackgroundTransparency = isTarget and 0.15 or 0.4
        b.TextColor3 = textMain
        b.Font = Enum.Font.Gotham
        b.TextSize = 10
        b.TextXAlignment = Enum.TextXAlignment.Left
        corner(b, 4)
        b.Text = "  " .. p.Name .. " [" .. S.KillDistance .. " studs]"
        b.MouseButton1Click:Connect(function() toggleTarget(p); refreshList() end)
        table.insert(playerButtons, b)
    end
    local layout = targetList:FindFirstChildOfClass("UIListLayout")
    if layout then targetList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8) end
end
refreshList()
Players.PlayerAdded:Connect(function() task.wait(1); refreshList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); refreshList() end)

-- ===== ВКЛАДКА VISUAL =====
local visual = tabPages[2]
local vy = 0

local note = Instance.new("TextLabel", visual)
note.Size = UDim2.new(1, -16, 0, 16)
note.Position = UDim2.new(0, 8, 0, vy)
note.BackgroundTransparency = 1
note.Text = "Visible only to you"
note.TextColor3 = Color3.fromRGB(255, 200, 80)
note.Font = Enum.Font.GothamBold
note.TextSize = 9
note.TextXAlignment = Enum.TextXAlignment.Left
vy = vy + 20

vy = windSection(visual, vy, "Presets")
vy = windToggle(visual, vy, "Visual Effects", function() return S.SkyEnabled end, function(v)
    S.SkyEnabled = v
    if v then applyLocalVisual(S.SkyPreset) else removeLocalVisual() end
end) and vy + 34

local presetBtns = {}
for idx, preset in ipairs(VISUAL_PRESETS) do
    local row = math.floor((idx - 1) / 2)
    local col = (idx - 1) % 2
    local bx = 8 + col * ((PW - 24) / 2)
    local by = vy + row * 28

    local btn = Instance.new("TextButton", visual)
    btn.Size = UDim2.new(0, (PW - 24) / 2, 0, 24)
    btn.Position = UDim2.new(0, bx, 0, by)
    btn.BackgroundColor3 = (S.SkyPreset == idx) and accent or bgHover
    btn.BackgroundTransparency = (S.SkyPreset == idx) and 0.1 or 0.3
    btn.BorderSizePixel = 0
    btn.Text = preset.name
    btn.TextColor3 = textMain
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    corner(btn, 5)

    local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    btn.MouseButton1Click:Connect(function()
        S.SkyPreset = idx
        S.SkyEnabled = true
        applyLocalVisual(idx)
        for bi, pb in ipairs(presetBtns) do
            TweenService:Create(pb, ti, {
                BackgroundColor3 = (bi == idx) and accent or bgHover,
                BackgroundTransparency = (bi == idx) and 0.1 or 0.3,
            }):Play()
        end
    end)
    table.insert(presetBtns, btn)
end

local presetRows = math.ceil(#VISUAL_PRESETS / 2)
vy = vy + presetRows * 28 + 6

vy = windSection(visual, vy, "Atmosphere")
local glowAtmo = nil
vy = windToggle(visual, vy, "Glow", function() return S.GlowEnabled end, function(v)
    S.GlowEnabled = v
    if v then
        if not glowAtmo then
            glowAtmo = Instance.new("Atmosphere")
            glowAtmo.Name = "RPG_Glow"
            glowAtmo.Density = 0.2
            glowAtmo.Offset = 0.2
            glowAtmo.Color = S.GlowColor
            glowAtmo.Decay = Color3.fromRGB(120, 60, 200)
            glowAtmo.Glare = 0.3
            glowAtmo.Haze = 1.5
            glowAtmo.Parent = Lighting
        end
    else
        if glowAtmo then glowAtmo:Destroy(); glowAtmo = nil end
    end
end) and vy + 34

vy = windSection(visual, vy, "Glow Color")
local glowColors = {
    {name = "Purple", color = Color3.fromRGB(130, 50, 255)},
    {name = "Red", color = Color3.fromRGB(200, 30, 30)},
    {name = "Blue", color = Color3.fromRGB(30, 100, 255)},
    {name = "Green", color = Color3.fromRGB(30, 200, 80)},
    {name = "Pink", color = Color3.fromRGB(255, 50, 150)},
    {name = "Orange", color = Color3.fromRGB(255, 120, 30)},
}
local glowBtns = {}
for idx, cp in ipairs(glowColors) do
    local row = math.floor((idx - 1) / 3)
    local col = (idx - 1) % 3
    local bx = 8 + col * ((PW - 28) / 3)
    local by = vy + row * 24

    local btn = Instance.new("TextButton", visual)
    btn.Size = UDim2.new(0, (PW - 28) / 3, 0, 20)
    btn.Position = UDim2.new(0, bx, 0, by)
    btn.BackgroundColor3 = cp.color
    btn.BackgroundTransparency = (S.GlowColor == cp.color) and 0.1 or 0.55
    btn.BorderSizePixel = 0
    btn.Text = cp.name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    corner(btn, 4)

    local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    btn.MouseButton1Click:Connect(function()
        S.GlowColor = cp.color
        if glowAtmo then glowAtmo.Color = cp.color end
        for bi, gb in ipairs(glowBtns) do
            TweenService:Create(gb, ti, {BackgroundTransparency = (bi == idx) and 0.1 or 0.55}):Play()
        end
    end)
    table.insert(glowBtns, btn)
end
local glowRows = math.ceil(#glowColors / 3)
vy = vy + glowRows * 24 + 6

vy = windSection(visual, vy, "Lighting")
vy = windSlider(visual, vy, "Brightness", function() return Lighting.Brightness end, function(v) Lighting.Brightness = v end, 0, 10, 0.1, "%.1f") and vy + 42
vy = windSlider(visual, vy, "Clock Time", function() return Lighting.ClockTime end, function(v) Lighting.ClockTime = v end, 0, 24, 0.1, "%.1f") and vy + 42

-- Новые опции
vy = windSection(visual, vy, "Effects")

-- Bloom
local bloomObj = nil
vy = windToggle(visual, vy, "Bloom", function() return S.BloomEnabled end, function(v)
    S.BloomEnabled = v
    if v then
        if not bloomObj then
            bloomObj = Instance.new("BloomEffect")
            bloomObj.Name = "RPG_Bloom"
            bloomObj.Intensity = 0.5
            bloomObj.Size = 24
            bloomObj.Threshold = 0.8
            bloomObj.Parent = Lighting
        end
    else
        if bloomObj then bloomObj:Destroy(); bloomObj = nil end
    end
end) and vy + 34

-- Color Correction
local ccObj = nil
vy = windToggle(visual, vy, "Color Shift", function() return S.CCEnabled end, function(v)
    S.CCEnabled = v
    if v then
        if not ccObj then
            ccObj = Instance.new("ColorCorrectionEffect")
            ccObj.Name = "RPG_CC"
            ccObj.Brightness = 0.05
            ccObj.Contrast = 0.15
            ccObj.Saturation = 0.3
            ccObj.TintColor = Color3.fromRGB(230, 220, 255)
            ccObj.Parent = Lighting
        end
    else
        if ccObj then ccObj:Destroy(); ccObj = nil end
    end
end) and vy + 34

visual.CanvasSize = UDim2.new(0, 0, 0, vy + 10)

-- ===== ВКЛАДКА MISC =====
local misc = tabPages[3]
local my = 0

flyBV = nil
flyBG = nil
flyHeld = false
local noclipConn = nil

my = windSection(misc, my, "Movement")
my = windToggle(misc, my, "Speed Boost", function() return S.SpeedBoost end, function(v)
    S.SpeedBoost = v
    if v and lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
        lp.Character.Humanoid.WalkSpeed = S.WalkSpeed
    elseif lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
        lp.Character.Humanoid.WalkSpeed = 16
    end
end) and my + 34
my = windSlider(misc, my, "Walk Speed", function() return S.WalkSpeed end, function(v)
    S.WalkSpeed = v
    if S.SpeedBoost and lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
        lp.Character.Humanoid.WalkSpeed = v
    end
end, 16, 500, 1) and my + 42

my = windToggle(misc, my, "NoClip", function() return S.NoClip end, function(v) S.NoClip = v end) and my + 34
my = windToggle(misc, my, "Fly", function() return S.FlyEnabled end, function(v)
    S.FlyEnabled = v
    if not v then
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
        -- Восстанавливаем состояния
        if lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
            local hum = lp.Character:FindFirstChildOfClass("Humanoid")
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end
    end
end) and my + 34
my = windSlider(misc, my, "Fly Speed", function() return S.FlySpeed end, function(v) S.FlySpeed = v end, 10, 500, 10) and my + 42

misc.CanvasSize = UDim2.new(0, 0, 0, my + 10)

-- ===== ВКЛАДКА SETTINGS =====
local settings = tabPages[4]
local sy = 0

sy = windSection(settings, sy, "Keybinds")
local keybindList = {
    {"Fire", "H"},
    {"Auto Fire", "T"},
    {"Burst", "Q"},
    {"Slow-Mo", "E"},
    {"Cluster", "R"},
    {"Homing", "G"},
    {"Mega Rocket", "N"},
    {"Rocket Jump", "V"},
    {"Car Destroy", "B"},
    {"Bring All", "Z"},
    {"Target Cycle", "C"},
    {"Fly", "X"},
    {"Toggle GUI", "F1"},
}
for _, data in ipairs(keybindList) do
    local card = Instance.new("Frame", settings)
    card.Size = UDim2.new(1, -16, 0, 22)
    card.Position = UDim2.new(0, 8, 0, sy)
    card.BackgroundColor3 = bgCard
    card.BackgroundTransparency = glassTransparency
    card.BorderSizePixel = 0
    corner(card, 4)
    local k = Instance.new("TextLabel", card)
    k.Size = UDim2.new(0.6, 0, 1, 0)
    k.Position = UDim2.new(0, 8, 0, 0)
    k.BackgroundTransparency = 1
    k.Text = data[1]
    k.TextColor3 = textMain
    k.Font = Enum.Font.Gotham
    k.TextSize = 10
    k.TextXAlignment = Enum.TextXAlignment.Left
    local v = Instance.new("TextLabel", card)
    v.Size = UDim2.new(0, 30, 1, 0)
    v.Position = UDim2.new(1, -38, 0, 0)
    v.BackgroundTransparency = 1
    v.Text = data[2]
    v.TextColor3 = accent
    v.Font = Enum.Font.GothamBold
    v.TextSize = 10
    sy = sy + 25
end

sy = windSection(settings, sy, "GUI Style")
sy = windToggle(settings, sy, "Matte Background", function() return S.GUIMatte end, function(v)
    S.GUIMatte = v
    if v then
        bg.BackgroundTransparency = 0.05
    else
        bg.BackgroundTransparency = 0.5
    end
end) and sy + 34
sy = windSlider(settings, sy, "Transparency", function() return S.GUIBgTransparency end, function(v)
    S.GUIBgTransparency = v
    if not S.GUIMatte then bg.BackgroundTransparency = v end
end, 0.05, 0.9, 0.05, "%.2f") and sy + 42
sy = windSlider(settings, sy, "Font Size", function() return S.GUIFontSize end, function(v) S.GUIFontSize = v end, 8, 16, 1) and sy + 42

settings.CanvasSize = UDim2.new(0, 0, 0, sy + 10)

-- ===== ВКЛАДКА INFO =====
local info = tabPages[5]
local iy = 0

iy = windSection(info, iy, "Controls")
for _, data in ipairs({
    {"H", "Fire rockets"},
    {"F1", "Toggle GUI"},
    {"F2", "Skip intro"},
    {"F3", "Unload script"},
}) do
    local card = Instance.new("Frame", info)
    card.Size = UDim2.new(1, -16, 0, 24)
    card.Position = UDim2.new(0, 8, 0, iy)
    card.BackgroundColor3 = bgCard
    card.BackgroundTransparency = glassTransparency
    card.BorderSizePixel = 0
    corner(card, 4)
    local k = Instance.new("TextLabel", card)
    k.Size = UDim2.new(0, 32, 1, 0)
    k.Position = UDim2.new(0, 8, 0, 0)
    k.BackgroundTransparency = 1
    k.Text = data[1]
    k.TextColor3 = accent
    k.Font = Enum.Font.GothamBold
    k.TextSize = 11
    k.TextXAlignment = Enum.TextXAlignment.Left
    local d = Instance.new("TextLabel", card)
    d.Size = UDim2.new(1, -48, 1, 0)
    d.Position = UDim2.new(0, 38, 0, 0)
    d.BackgroundTransparency = 1
    d.Text = data[2]
    d.TextColor3 = textSub
    d.Font = Enum.Font.Gotham
    d.TextSize = 10
    d.TextXAlignment = Enum.TextXAlignment.Left
    iy = iy + 27
end

iy = iy + 6
iy = windSection(info, iy, "About")
local aboutCard = Instance.new("Frame", info)
aboutCard.Size = UDim2.new(1, -16, 0, 24)
aboutCard.Position = UDim2.new(0, 8, 0, iy)
aboutCard.BackgroundColor3 = bgCard
aboutCard.BackgroundTransparency = glassTransparency
aboutCard.BorderSizePixel = 0
corner(aboutCard, 4)
local aboutTxt = Instance.new("TextLabel", aboutCard)
aboutTxt.Size = UDim2.new(1, -12, 1, 0)
aboutTxt.Position = UDim2.new(0, 8, 0, 0)
aboutTxt.BackgroundTransparency = 1
aboutTxt.Text = "GOD OF THE RPG v2.0  |  Scorpio & nazarkus1337"
aboutTxt.TextColor3 = textSub
aboutTxt.Font = Enum.Font.Gotham
aboutTxt.TextSize = 10
aboutTxt.TextXAlignment = Enum.TextXAlignment.Left

info.CanvasSize = UDim2.new(0, 0, 0, iy + 34)

-- ====================================================================
-- ВВОД
-- ====================================================================
local hHeld = false
local hTimer = 0
local targetSpamTimer = 0

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == Enum.KeyCode.F1 then
        gui.Enabled = not gui.Enabled
    end

    if input.KeyCode == Enum.KeyCode.F3 then
        alive = false
        hHeld = false
        flyHeld = false
        removeLocalVisual()
        if glowAtmo then glowAtmo:Destroy(); glowAtmo = nil end
        if bloomObj then bloomObj:Destroy(); bloomObj = nil end
        if ccObj then ccObj:Destroy(); ccObj = nil end
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
        visualGui:Destroy()
        gui:Destroy()
    end

    if input.KeyCode == Enum.KeyCode.H and S.Enabled then
        hHeld = true
    end

    -- Rocket Jump
    if input.KeyCode == S.RocketJumpKey and S.RocketJumpEnabled then
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp:ApplyImpulse(Vector3.new(0, S.RocketJumpPower, 0))
        end
    end

    -- Car Destroy
    if input.KeyCode == S.CarDestroyKey and S.CarDestroyEnabled then
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Vehicle") or (obj:IsA("Model") and obj:FindFirstChildOfClass("VehicleSeat")) then
                    localvp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                    if vp then
                        local dist = (vp.Position - hrp.Position).Magnitude
                        if dist <= S.CarDestroyRange then
                            for i = 1, S.CarDestroyCount do
                                pcall(function()
                                    if rvEv.RocketHit then
                                        rvEv.RocketHit:FireServer({
                                            Normal = Vector3.new(0, 1, 0),
                                            HitPart = vp,
                                            Position = vp.Position + Vector3.new((math.random()-0.5)*S.CarDestroySpread, 0, (math.random()-0.5)*S.CarDestroySpread),
                                            Label = lp.Name .. "CD" .. i,
                                            Vehicle = getTool(),
                                            Player = lp,
                                            Weapon = getTool(),
                                        })
                                    end
                                end)
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    -- Bring All
    if input.KeyCode == S.BringAllKey and S.BringAllEnabled then
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    pcall(function()
                        if rvEv.RocketHit then
                            rvEv.RocketHit:FireServer({
                                Normal = Vector3.new(0, 1, 0),
                                HitPart = p.Character.HumanoidRootPart,
                                Position = p.Character.HumanoidRootPart.Position,
                                Label = lp.Name .. "BA",
                                Vehicle = getTool(),
                                Player = lp,
                                Weapon = getTool(),
                            })
                        end
                    end)
                end
            end
        end
    end

    -- Cluster
    if input.KeyCode == S.ClusterKey and S.ClusterEnabled then
        local hit = mouse.Hit
        if hit then
            for i = 1, S.ClusterCount do
                local angle = math.random() * math.pi * 2
                local dist = math.random() * S.ClusterRadius
                local offset = Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
                pcall(function()
                    if rvEv.RocketHit then
                        rvEv.RocketHit:FireServer({
                            Normal = Vector3.new(0, 1, 0),
                            HitPart = mouse.Target or WS.Terrain,
                            Position = hit.Position + offset,
                            Label = lp.Name .. "CL" .. i,
                            Vehicle = getTool(),
                            Player = lp,
                            Weapon = getTool(),
                        })
                    end
                end)
            end
        end
    end

    -- Slow-Mo
    if input.KeyCode == S.SlowMoKey and S.SlowMoEnabled then
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        local tool = getTool()
        if hrp and tool then
            local dir = workspace.CurrentCamera.CFrame.LookVector
            local origin = hrp.Position
            task.spawn(function()
                for i = 1, S.SlowMoCount do
                    local sx = (math.random() - 0.5) * S.SlowMoSpread
                    local sz = (math.random() - 0.5) * S.SlowMoSpread
                    local finalPos = origin + dir * 100 + Vector3.new(sx, 0, sz)
                    local fd = (finalPos - origin).Unit

                    -- 1. Запускаем ракету (создаёт визуально)
                    pcall(function()
                        if rvEv.RocketReloadedFX then rvEv.RocketReloadedFX:FireServer(tool, false) end
                        if rvEv.FireRocketReplicated then
                            rvEv.FireRocketReplicated:FireServer({
                                Direction = fd,
                                Settings = {},
                                Origin = origin,
                                PlrFired = lp,
                                Vehicle = tool,
                                RocketModel = ROCKET_MODEL or tool,
                                Weapon = tool,
                            })
                        end
                    end)

                    -- 2. Ждём пока ракета долетит
                    task.wait(1.5)

                    -- 3. Взрыв в точке назначения
                    pcall(function()
                        if rvEv.RocketHit then
                            rvEv.RocketHit:FireServer({
                                Normal = Vector3.new(0, 1, 0),
                                HitPart = WS.Terrain,
                                Position = finalPos,
                                Label = lp.Name .. "SM" .. i,
                                Vehicle = tool,
                                Player = lp,
                                Weapon = tool,
                            })
                        end
                    end)

                    task.wait(0.3)
                end
            end)
        end
    end

    -- Mega Rocket
    if input.KeyCode == S.MegaKey and S.MegaEnabled then
        local hit = mouse.Hit
        if hit then
            for i = 1, S.MegaCount do
                local sx = (math.random() - 0.5) * S.MegaSpread
                local sz = (math.random() - 0.5) * S.MegaSpread
                pcall(function()
                    if rvEv.RocketHit then
                        rvEv.RocketHit:FireServer({
                            Normal = Vector3.new(0, 1, 0),
                            HitPart = mouse.Target or WS.Terrain,
                            Position = hit.Position + Vector3.new(sx, 0, sz),
                            Label = lp.Name .. "MR" .. i,
                            Vehicle = getTool(),
                            Player = lp,
                            Weapon = getTool(),
                        })
                    end
                end)
            end
        end
    end

    -- Auto Fire toggle
    if input.KeyCode == S.AutoFireKey then
        S.AutoFire = not S.AutoFire
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.H then
        hHeld = false
        hTimer = 0
    end
end)

-- ====================================================================
-- ХУКИ
-- ====================================================================
pcall(function()
    local oldReq = require
    require = function(mod)
        local t = oldReq(mod)
        if mod:IsA("ModuleScript") and mod.Name == "RocketSettings" then
            t.velocity = 999999999
            t.ExplosionDamage = 999999999
            t.VehicleDamage = 999999999
            t.BoatDamage = 999999999
            t.TankDamage = 999999999
            t.HelicopterDamage = 999999999
            t.PlaneDamage = 999999999
            t.GunshipDamage = 999999999
            t.ShieldDamage = 999999999
            t.ExpRadius = 500
            t.Distance = 999999999
            t.Acceleration = 999999999
            t.FireRate = 0
            t.RocketAmount = 50
            t.gravity = Vector3.new(0, 0, 0)
        end
        return t
    end
end)

pcall(function()
    local FireRocketFunc = RS:FindFirstChild("FireRocket")
    if FireRocketFunc and FireRocketFunc:IsA("RemoteFunction") then
        local mt = getrawmetatable(game)
        if mt then
            setreadonly(mt, false)
            local oldNC = mt.__namecall
            mt.__namecall = function(self, ...)
                local method = getnamecallmethod()
                if self == FireRocketFunc and method == "InvokeServer" then
                    local args = {...}
                    task.spawn(function()
                        for _ = 2, S.RocketCount do
                            oldNC(self, unpack(args))
                        end
                    end)
                    return oldNC(self, ...)
                end
                return oldNC(self, ...)
            end
            setreadonly(mt, true)
        end
    end
end)

-- ====================================================================
-- HEARTBEAT
-- ====================================================================
RunService.Heartbeat:Connect(function(dt)
    if not alive then return end

    -- Очистка старых cooldown'ов
    local now = tick()
    for k, v in pairs(targetCooldowns) do
        if (now - v) > 2 then targetCooldowns[k] = nil end
    end

    if hHeld and S.Enabled then
        hTimer = hTimer + dt
        if hTimer >= S.FireRate then
            hTimer = 0
            local hit = mouse.Hit
            if hit then
                instantExplosion(hit.Position, mouse.Target)
            end
        end
    end

    -- Auto Fire
    if S.AutoFire and S.Enabled then
        hTimer = hTimer + dt
        if hTimer >= S.FireRate then
            hTimer = 0
            local hit = mouse.Hit
            if hit then
                instantExplosion(hit.Position, mouse.Target)
            end
        end
    end

    if S.TargetSpam and #selectedTargets > 0 then
        targetSpamTimer = targetSpamTimer + dt
        if targetSpamTimer >= S.TargetSpamRate then
            targetSpamTimer = 0
            for _, targetPlayer in ipairs(selectedTargets) do
                if targetPlayer and targetPlayer.Character then
                    teleportToHumanoid(targetPlayer)
                end
            end
        end
    end

    -- Вращение фигур на фоне GUI
    for _, sh in ipairs(bgShapes) do
        sh.ang = (sh.ang + sh.spd * dt * 60) % 360
        sh.f.Rotation = sh.ang
    end

    -- NoClip
    if S.NoClip and lp.Character then
        for _, part in ipairs(lp.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    -- Fly
    if S.FlyEnabled and lp.Character then
        local hrp = lp.Character:FindFirstChild("HumanoidRootPart")
        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            -- Отключаем коллизии при полёте
            for _, part in ipairs(lp.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end

            -- Отключаем урон от падения
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

            local cam = workspace.CurrentCamera
            local look = cam.CFrame.LookVector
            local right = cam.CFrame.RightVector
            local up = Vector3.new(0, 1, 0)
            local vel = Vector3.zero

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + look end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - look end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + right end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - right end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + up end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - up end

            if vel.Magnitude > 0 then
                vel = vel.Unit * S.FlySpeed
            end

            if not flyBV then
                flyBV = Instance.new("BodyVelocity", hrp)
                flyBV.MaxForce = Vector3.new(1, 1, 1) * 1e9
            end
            flyBV.Velocity = vel

            if not flyBG then
                flyBG = Instance.new("BodyGyro", hrp)
                flyBG.MaxTorque = Vector3.new(1, 1, 1) * 1e9
                flyBG.P = 1e4
            end
            flyBG.CFrame = cam.CFrame
        end
    end

    -- Speed Boost
    if S.SpeedBoost and lp.Character then
        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= S.WalkSpeed then
            hum.WalkSpeed = S.WalkSpeed
        end
    end

    if visualGui.Enabled then
        for _, p in ipairs(visualParticles) do
            p.px = (p.px + p.dx * dt) % 1
            p.py = (p.py + p.dy * dt) % 1
            p.f.Position = UDim2.new(p.px, 0, p.py, 0)
        end
    end
end)

task.spawn(function()
    while alive do
        task.wait(1)
        refreshList()
    end
end)

-- ====================================================================
-- КОНСОЛЬ
-- ====================================================================
print("")
print("============================================")
print("")
print("       G O D   O F   T H E   R P G")
print("")
print("============================================")
print("")
print("       BY SCORPIO & NAZARKUS1337")
print("       WAR TYCOON RPG SYSTEM")
print("")
print("============================================")
print("")
