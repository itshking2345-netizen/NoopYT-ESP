-- ============================================================
-- NoopYT Universal v9 — Pro Edition
-- ESP + Aimbot + Predictive + Silent Aim + Pro GUI + Save Settings
-- متوافق مع: Arceus X Neo / Delta / Fluxus / Solara (أندرويد + كمبيوتر)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ==================== الإعدادات ====================
local CONFIG = {
    -- ESP
    ESPEnabled = true,
    ShowNames = true,
    ShowDistance = true,
    ShowHighlight = true,
    ShowTracers = true,
    ShowBox = false,
    TeamCheck = false,

    -- Aimbot
    AimbotEnabled = false,
    AimbotMode = "Silent",
    AutoFire = false,
    FireDelay = 0.15,
    AimbotFOV = 200,
    AimbotSmoothing = 0.15,
    AimbotPart = "Head",
    AimbotVisibleOnly = false,
    SelectedTarget = nil,
    ShowFOVCircle = true,
    LockOnTarget = false,

    -- Predictive
    PredictiveEnabled = true,
    PredictionStrength = 0.5,
    PredictionTime = 0.15,

    -- Colors
    HighlightFill = Color3.fromRGB(255, 60, 60),
    HighlightOutline = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 60, 60),
    BoxColor = Color3.fromRGB(255, 255, 255),
    FOVColor = Color3.fromRGB(255, 60, 60),
    FillTransparency = 0.7,
    OutlineTransparency = 0.2,
    RefreshRate = 0.5,

    -- UI
    UIPosition = UDim2.new(0.5, -170, 0.5, -240),
    ButtonPosition = UDim2.new(1, -80, 0.5, -30),
    PanelVisible = false,
}

local THEME = {
    Bg = Color3.fromRGB(15, 15, 20),
    Panel = Color3.fromRGB(22, 22, 30),
    Card = Color3.fromRGB(32, 32, 42),
    CardHover = Color3.fromRGB(42, 42, 55),
    Accent = Color3.fromRGB(255, 60, 60),
    Accent2 = Color3.fromRGB(120, 60, 255),
    Text = Color3.fromRGB(240, 240, 245),
    TextDim = Color3.fromRGB(140, 140, 160),
    Success = Color3.fromRGB(60, 220, 130),
    Danger = Color3.fromRGB(255, 70, 70),
    Divider = Color3.fromRGB(45, 45, 58),
    Gold = Color3.fromRGB(255, 200, 60),
}

-- ==================== حفظ الإعدادات ====================
local SETTINGS_FILE = "NoopYT_v9_settings.json"
local function saveSettings()
    local data = {}
    for k, v in pairs(CONFIG) do
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
            data[k] = v
        end
    end
    pcall(function()
        if writefile then
            writefile(SETTINGS_FILE, HttpService:JSONEncode(data))
        end
    end)
end

local function loadSettings()
    pcall(function()
        if isfile and isfile(SETTINGS_FILE) and readfile then
            local raw = readfile(SETTINGS_FILE)
            local data = HttpService:JSONDecode(raw)
            for k, v in pairs(data) do
                if CONFIG[k] ~= nil then
                    CONFIG[k] = v
                end
            end
        end
    end)
end

loadSettings()

-- ==================== التخزين ====================
local ESPData = {}
local Tracers = {}
local Boxes = {}
local FOVCircle = nil
local LockedTarget = nil
local LastFireTime = 0
local LastPositions = {}

-- ==================== أدوات ====================
local function safeDestroy(obj)
    if obj and typeof(obj) == "Instance" and obj.Parent then
        pcall(function() obj:Destroy() end)
    end
end

local function isValidPlayer(player)
    return player and player ~= LocalPlayer and player.Parent
end

local function isValidCharacter(player)
    if not isValidPlayer(player) then return false end
    local char = player.Character
    if not char or not char.Parent then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return false end
    if not char:FindFirstChild("HumanoidRootPart") then return false end
    return true
end

local function isSameTeam(player)
    if not CONFIG.TeamCheck then return false end
    return player.Team == LocalPlayer.Team
end

local function getCharacterPart(player, partName)
    if not player or not player.Character then return nil end
    return player.Character:FindFirstChild(partName)
        or player.Character:FindFirstChild("HumanoidRootPart")
end

-- ==================== ESP ====================
local function cleanupESP(player)
    local data = ESPData[player]
    if data then
        safeDestroy(data.Highlight)
        safeDestroy(data.Billboard)
        ESPData[player] = nil
    end
    local t = Tracers[player]
    if t then pcall(function() t:Remove() end); Tracers[player] = nil end
    local b = Boxes[player]
    if b then pcall(function() b:Remove() end); Boxes[player] = nil end
end

local function createESP(player)
    if not isValidPlayer(player) then return end
    if isSameTeam(player) then return end
    if ESPData[player] then return end
    if not isValidCharacter(player) then return end

    local char = player.Character
    local ok = pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.Name = "NoopYT_HL"
        highlight.FillColor = CONFIG.HighlightFill
        highlight.OutlineColor = CONFIG.HighlightOutline
        highlight.FillTransparency = CONFIG.FillTransparency
        highlight.OutlineTransparency = CONFIG.OutlineTransparency
        highlight.Adornee = char
        highlight.Parent = char

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "NoopYT_BB"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = char
        billboard.Parent = char

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextScaled = true
        nameLabel.Visible = CONFIG.ShowNames
        nameLabel.Parent = billboard

        local distLabel = Instance.new("TextLabel")
        distLabel.Name = "Dist"
        distLabel.Size = UDim2.new(1, 0, 0.4, 0)
        distLabel.Position = UDim2.new(0, 0, 0.6, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.TextColor3 = THEME.Accent
        distLabel.TextStrokeTransparency = 0
        distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        distLabel.Font = Enum.Font.GothamBold
        distLabel.TextScaled = true
        distLabel.Visible = CONFIG.ShowDistance
        distLabel.Parent = billboard

        if Drawing then
            local tracer = Drawing.new("Line")
            tracer.Visible = false
            tracer.Thickness = 1.5
            tracer.Color = CONFIG.TracerColor
            tracer.Transparency = 1
            Tracers[player] = tracer

            local box = Drawing.new("Square")
            box.Visible = false
            box.Thickness = 1
            box.Color = CONFIG.BoxColor
            box.Filled = false
            box.Transparency = 1
            Boxes[player] = box
        end

        ESPData[player] = {
            Highlight = highlight,
            Billboard = billboard,
            NameLabel = nameLabel,
            DistLabel = distLabel,
        }
    end)
    if not ok then cleanupESP(player) end
end

local function fullRefresh()
    if not CONFIG.ESPEnabled then return end
    for player, _ in pairs(ESPData) do
        if not isValidPlayer(player) then cleanupESP(player)
        elseif not isValidCharacter(player) then
            local d = ESPData[player]
            if d.Billboard then d.Billboard.Enabled = false end
        end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidPlayer(player) and isValidCharacter(player) and not isSameTeam(player) then
            if not ESPData[player] then
                createESP(player)
            else
                local d = ESPData[player]
                if d.Highlight and not d.Highlight.Parent then
                    cleanupESP(player)
                    createESP(player)
                elseif d.Billboard then
                    d.Billboard.Enabled = true
                end
            end
        end
    end
end

-- ==================== أحداث اللاعبين ====================
local function watchCharacter(player)
    if not isValidPlayer(player) then return end
    task.spawn(function()
        local char = player.Character or player.CharacterAdded:Wait()
        if not char then return end
        local h = char:WaitForChild("Humanoid", 10)
        char:WaitForChild("HumanoidRootPart", 10)
        if h and h.Health > 0 then
            cleanupESP(player)
            createESP(player)
        end
        if h then
            h.Died:Connect(function()
                cleanupESP(player)
                if LockedTarget == player then LockedTarget = nil end
                LastPositions[player] = nil
            end)
        end
    end)
end

local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    watchCharacter(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.3)
        watchCharacter(player)
    end)
    player.CharacterRemoving:Connect(function()
        cleanupESP(player)
    end)
end

local function onPlayerRemoving(player)
    cleanupESP(player)
    if LockedTarget == player then LockedTarget = nil end
    LastPositions[player] = nil
end

for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ==================== Predictive ====================
local function getPlayerVelocity(player)
    local part = getCharacterPart(player, "HumanoidRootPart")
    if not part then return Vector3.zero end
    local now = tick()
    local last = LastPositions[player]
    if not last then
        LastPositions[player] = {pos = part.Position, time = now}
        return Vector3.zero
    end
    local dt = now - last.time
    if dt < 0.02 then return last.vel or Vector3.zero end
    local vel = (part.Position - last.pos) / dt
    LastPositions[player] = {pos = part.Position, time = now, vel = vel}
    return vel
end

local function getPredictedPosition(player, part)
    if not CONFIG.PredictiveEnabled then return part.Position end
    if CONFIG.PredictionStrength <= 0 then return part.Position end
    local vel = getPlayerVelocity(player)
    if vel.Magnitude < 1 then return part.Position end
    local dist = (Camera.CFrame.Position - part.Position).Magnitude
    local bulletSpeed = 500
    local travelTime = dist / bulletSpeed
    local totalTime = travelTime + CONFIG.PredictionTime
    return part.Position + vel * totalTime * CONFIG.PredictionStrength
end

-- ==================== Aimbot ====================
local function isVisible(part)
    if not CONFIG.AimbotVisibleOnly then return true end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = workspace:Raycast(origin, dir, params)
    if result then return result.Instance:IsDescendantOf(part.Parent) end
    return true
end

local function getBestTarget()
    if not Camera then return nil end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest, shortest = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if isSameTeam(player) then continue end
        if CONFIG.SelectedTarget and CONFIG.SelectedTarget ~= "" then
            if player.Name ~= CONFIG.SelectedTarget then continue end
        end
        local char = player.Character
        if not char then continue end
        local h = char:FindFirstChildOfClass("Humanoid")
        if not h or h.Health <= 0 then continue end
        local part = char:FindFirstChild(CONFIG.AimbotPart)
                or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        local checkPos = getPredictedPosition(player, part)
        local sp, onScreen = Camera:WorldToViewportPoint(checkPos)
        if not onScreen then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d > CONFIG.AimbotFOV then continue end
        if d >= shortest then continue end
        if not isVisible(part) then continue end
        shortest = d
        closest = {player = player, part = part}
    end
    return closest
end

local function silentAim(target)
    if not target or not target.part then return end
    pcall(function()
        if hookmetamethod and getrawmetatable and Mouse then
            local mt = getrawmetatable(Mouse)
            if mt and not mt.__noopYT_hooked then
                local old = mt.__index
                mt.__index = newcclosure(function(self, key)
                    if key == "Hit" and LockedTarget and isValidCharacter(LockedTarget) then
                        local p = getCharacterPart(LockedTarget, CONFIG.AimbotPart)
                        if p then return getPredictedPosition(LockedTarget, p) end
                    end
                    if key == "Target" and LockedTarget then
                        local p = getCharacterPart(LockedTarget, CONFIG.AimbotPart)
                        if p then return p end
                    end
                    return old(self, key)
                end)
                mt.__noopYT_hooked = true
            end
        end
    end)
end

local function updateLockedTarget()
    if not CONFIG.AimbotEnabled then LockedTarget = nil return end
    if CONFIG.SelectedTarget and CONFIG.SelectedTarget ~= "" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name == CONFIG.SelectedTarget and isValidCharacter(player) then
                LockedTarget = player
                return
            end
        end
        LockedTarget = nil
        return
    end
    if CONFIG.LockOnTarget then
        local target = getBestTarget()
        LockedTarget = target and target.player or nil
    else
        LockedTarget = nil
    end
end

local function tryAutoFire()
    if not CONFIG.AutoFire or not LockedTarget then return end
    local now = tick()
    if now - LastFireTime < CONFIG.FireDelay then return end
    LastFireTime = now
    if mouse1click then pcall(mouse1click) return end
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end

local function performAimbot()
    if not CONFIG.AimbotEnabled then return end
    if not LockedTarget or not isValidCharacter(LockedTarget) then return end
    local targetPart = getCharacterPart(LockedTarget, CONFIG.AimbotPart)
    if not targetPart then return end
    local aimPos = getPredictedPosition(LockedTarget, targetPart)
    if CONFIG.AimbotMode == "Silent" then
        silentAim({player = LockedTarget, part = targetPart})
    else
        local desired = CFrame.new(Camera.CFrame.Position, aimPos)
        local smooth = math.clamp(CONFIG.AimbotSmoothing, 0, 0.95)
        if smooth <= 0 then
            Camera.CFrame = desired
        else
            Camera.CFrame = Camera.CFrame:Lerp(desired, 1 - smooth)
        end
    end
end

-- ==================== Visuals ====================
local function updateVisuals()
    if not Camera then return end
    local size = Camera.ViewportSize
    local startPt = Vector2.new(size.X / 2, size.Y)
    for player, tracer in pairs(Tracers) do
        if not tracer then continue end
        if not CONFIG.ESPEnabled or not CONFIG.ShowTracers then
            tracer.Visible = false
        else
            local part = getCharacterPart(player, "HumanoidRootPart")
            if part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    tracer.From = startPt
                    tracer.To = Vector2.new(sp.X, sp.Y)
                    if LockedTarget == player then
                        tracer.Color = THEME.Accent2
                        tracer.Thickness = 3
                    else
                        tracer.Color = CONFIG.TracerColor
                        tracer.Thickness = 1.5
                    end
                    tracer.Visible = true
                else
                    tracer.Visible = false
                end
            else
                tracer.Visible = false
            end
        end
    end
    for player, box in pairs(Boxes) do
        if not box then continue end
        if not CONFIG.ESPEnabled or not CONFIG.ShowBox then
            box.Visible = false
        else
            local part = getCharacterPart(player, "HumanoidRootPart")
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Camera.CFrame.Position - part.Position).Magnitude
                    local h = math.clamp(2000 / dist, 20, 400)
                    local w = h * 0.6
                    box.Size = Vector2.new(w, h)
                    box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                    if LockedTarget == player then
                        box.Color = THEME.Accent2
                        box.Thickness = 2
                    else
                        box.Color = CONFIG.BoxColor
                        box.Thickness = 1
                    end
                    box.Visible = true
                else
                    box.Visible = false
                end
            else
                box.Visible = false
            end
        end
    end
end

local distAccum = 0
local function updateDistances(dt)
    distAccum = distAccum + dt
    if distAccum < 0.1 then return end
    distAccum = 0
    local lc = LocalPlayer.Character
    local lr = lc and lc:FindFirstChild("HumanoidRootPart")
    if not lr then return end
    for player, data in pairs(ESPData) do
        if data.DistLabel and data.DistLabel.Parent then
            local part = getCharacterPart(player, "HumanoidRootPart")
            if part then
                local d = (lr.Position - part.Position).Magnitude
                data.DistLabel.Text = string.format("%d", math.floor(d))
                data.DistLabel.Visible = CONFIG.ShowDistance
            end
        end
    end
end

local function updateFOVCircle()
    if not FOVCircle then return end
    if not CONFIG.ShowFOVCircle or not CONFIG.AimbotEnabled then
        FOVCircle.Visible = false
        return
    end
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = CONFIG.AimbotFOV
    FOVCircle.Color = CONFIG.FOVColor
    FOVCircle.Visible = true
end

-- ==================== الحلقة الرئيسية ====================
local refreshAccum = 0
RunService.RenderStepped:Connect(function(dt)
    if not Camera then Camera = workspace.CurrentCamera end
    if not Camera then return end
    refreshAccum = refreshAccum + dt
    if refreshAccum >= CONFIG.RefreshRate then
        refreshAccum = 0
        pcall(fullRefresh)
    end
    updateDistances(dt)
    pcall(updateVisuals)
    pcall(updateLockedTarget)
    pcall(performAimbot)
    pcall(tryAutoFire)
    updateFOVCircle()
end)

-- ==================== Keybinds ====================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightAlt then
        CONFIG.AimbotEnabled = not CONFIG.AimbotEnabled
        saveSettings()
    elseif input.KeyCode == Enum.KeyCode.RightControl then
        CONFIG.AutoFire = not CONFIG.AutoFire
        saveSettings()
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        CONFIG.LockOnTarget = not CONFIG.LockOnTarget
        saveSettings()
    elseif input.KeyCode == Enum.KeyCode.P then
        CONFIG.PredictiveEnabled = not CONFIG.PredictiveEnabled
        saveSettings()
    end
end)

-- ============================================================
-- ==================== PRO GUI ===============================
-- ============================================================

local function createGUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "NoopYT_v9"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999

    local parent = LocalPlayer:WaitForChild("PlayerGui")
    if gethui then parent = gethui()
    elseif syn and syn.protect_gui then
        parent = game:GetService("CoreGui")
        syn.protect_gui(sg)
    end
    sg.Parent = parent

    -- ============ الزر العائم ============
    local panelRef = nil
    local togglePanel = function()
        if panelRef then
            panelRef.Visible = not panelRef.Visible
        end
    end

    local btn = Instance.new("TextButton")
    btn.Name = "NoopYT_Toggle"
    btn.Size = UDim2.new(0, 60, 0, 60)
    btn.Position = CONFIG.ButtonPosition
    btn.BackgroundColor3 = THEME.Panel
    btn.BorderSizePixel = 0
    btn.Text = "N"
    btn.TextColor3 = THEME.Accent
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.ZIndex = 10
    btn.Parent = sg
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local bStroke = Instance.new("UIStroke", btn)
    bStroke.Color = THEME.Accent
    bStroke.Thickness = 2

    -- نظام سحب/ضغط ذكي
    local touchState = {
        startTime = 0, startPos = nil, moved = 0,
        dragging = false, btnStartPos = nil,
    }
    local TAP_TIME_MAX = 0.4
    local TAP_MOVE_MAX = 12

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            touchState.startTime = tick()
            touchState.startPos = Vector2.new(input.Position.X, input.Position.Y)
            touchState.moved = 0
            touchState.dragging = false
            touchState.btnStartPos = btn.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not touchState.startPos then return end
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement then
            local cp = Vector2.new(input.Position.X, input.Position.Y)
            local delta = cp - touchState.startPos
            touchState.moved = math.max(touchState.moved, delta.Magnitude)
            if touchState.moved > TAP_MOVE_MAX then
                touchState.dragging = true
                if touchState.btnStartPos then
                    btn.Position = UDim2.new(
                        touchState.btnStartPos.X.Scale,
                        touchState.btnStartPos.X.Offset + delta.X,
                        touchState.btnStartPos.Y.Scale,
                        touchState.btnStartPos.Y.Offset + delta.Y
                    )
                end
            end
        end
    end)

    local function endTouch(input)
        if not touchState.startPos then return end
        if input.UserInputType ~= Enum.UserInputType.Touch
        and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        local duration = tick() - touchState.startTime
        local wasTap = (not touchState.dragging)
                    and (duration < TAP_TIME_MAX)
                    and (touchState.moved < TAP_MOVE_MAX)
        if wasTap then togglePanel() end

        touchState.startPos = nil
        touchState.startTime = 0
        touchState.moved = 0
        touchState.dragging = false
        touchState.btnStartPos = nil
    end

    btn.InputEnded:Connect(endTouch)
    UserInputService.InputEnded:Connect(endTouch)

    -- ============ اللوحة ============
    local panel = Instance.new("Frame")
    panel.Name = "NoopYT_Panel"
    panel.Size = UDim2.new(0, 360, 0, 500)
    panel.Position = CONFIG.UIPosition
    panel.BackgroundColor3 = THEME.Bg
    panel.BorderSizePixel = 0
    panel.Visible = CONFIG.PanelVisible
    panel.Active = true
    panel.ZIndex = 20
    panel.Parent = sg
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
    local pStroke = Instance.new("UIStroke", panel)
    pStroke.Color = THEME.Accent
    pStroke.Thickness = 1.5
    pStroke.Transparency = 0.3

    panelRef = panel

    -- ============ العنوان ============
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = THEME.Panel
    header.BorderSizePixel = 0
    header.ZIndex = 21
    header.Parent = panel
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

    local panelDragging = false
    local panelDragStart, panelStartPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            panelDragging = true
            panelDragStart = Vector2.new(input.Position.X, input.Position.Y)
            panelStartPos = panel.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not panelDragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - panelDragStart
            panel.Position = UDim2.new(
                panelStartPos.X.Scale, panelStartPos.X.Offset + delta.X,
                panelStartPos.Y.Scale, panelStartPos.Y.Offset + delta.Y
            )
            CONFIG.UIPosition = panel.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            panelDragging = false
            saveSettings()
        end
    end)

    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0, 32, 0, 32)
    logo.Position = UDim2.new(0, 12, 0.5, -16)
    logo.BackgroundColor3 = THEME.Accent
    logo.BorderSizePixel = 0
    logo.ZIndex = 22
    logo.Parent = header
    Instance.new("UICorner", logo).CornerRadius = UDim.new(1, 0)
    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.new(1, 0, 1, 0)
    logoText.BackgroundTransparency = 1
    logoText.Text = "N"
    logoText.TextColor3 = Color3.new(1, 1, 1)
    logoText.Font = Enum.Font.GothamBold
    logoText.TextScaled = true
    logoText.ZIndex = 23
    logoText.Parent = logo

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -140, 1, 0)
    title.Position = UDim2.new(0, 52, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "NoopYT"
    title.TextColor3 = THEME.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 22
    title.Parent = header

    local subTitle = Instance.new("TextLabel")
    subTitle.Size = UDim2.new(1, -140, 0, 14)
    subTitle.Position = UDim2.new(0, 52, 0, 30)
    subTitle.BackgroundTransparency = 1
    subTitle.Text = "v9 Pro Edition"
    subTitle.TextColor3 = THEME.Gold
    subTitle.Font = Enum.Font.Gotham
    subTitle.TextSize = 11
    subTitle.TextXAlignment = Enum.TextXAlignment.Left
    subTitle.ZIndex = 22
    subTitle.Parent = header

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 26, 0, 26)
    minBtn.Position = UDim2.new(1, -66, 0.5, -13)
    minBtn.BackgroundColor3 = THEME.Card
    minBtn.Text = "—"
    minBtn.TextColor3 = THEME.Text
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 14
    minBtn.BorderSizePixel = 0
    minBtn.ZIndex = 22
    minBtn.Parent = header
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)
    minBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
        saveSettings()
    end)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -34, 0.5, -13)
    closeBtn.BackgroundColor3 = THEME.Danger
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 22
    closeBtn.Parent = header
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
        saveSettings()
    end)

    -- ============ التبويبات ============
    local tabs = Instance.new("Frame")
    tabs.Size = UDim2.new(1, -20, 0, 38)
    tabs.Position = UDim2.new(0, 10, 0, 58)
    tabs.BackgroundColor3 = THEME.Panel
    tabs.BorderSizePixel = 0
    tabs.ZIndex = 21
    tabs.Parent = panel
    Instance.new("UICorner", tabs).CornerRadius = UDim.new(0, 8)
    local tabLayout = Instance.new("UIListLayout", tabs)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -168)
    content.Position = UDim2.new(0, 10, 0, 104)
    content.BackgroundTransparency = 1
    content.ZIndex = 21
    content.ClipsDescendants = true
    content.Parent = panel

    local pages = {}
    local function makePage(name)
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = THEME.Accent
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.ZIndex = 22        page.Parent = content
        local ll = Instance.new("UIListLayout", page)
        ll.Padding = UDim.new(0, 8)
        ll.SortOrder = Enum.SortOrder.LayoutOrder
        pages[name] = page
        return page
    end

    local pageESP = makePage("ESP")
    local pageAim = makePage("Aimbot")
    local pagePlayers = makePage("Players")
    local pageSettings = makePage("Settings")

    local tabButtons = {}
    local tabNames = {"ESP", "Aimbot", "Players", "Settings"}
    local tabIcons = {"👁", "🎯", "👥", "⚙"}

    local function selectTab(name)
        for n, p in pairs(pages) do p.Visible = (n == name) end
        for n, b in pairs(tabButtons) do
            if n == name then
                b.BackgroundColor3 = THEME.Accent
                b.TextColor3 = Color3.new(1, 1, 1)
            else
                b.BackgroundColor3 = THEME.Card
                b.TextColor3 = THEME.TextDim
            end
        end
    end

    for i, name in ipairs(tabNames) do
        local tb = Instance.new("TextButton")
        tb.Size = UDim2.new(0, 76, 0, 30)
        tb.BackgroundColor3 = THEME.Card
        tb.BorderSizePixel = 0
        tb.Text = tabIcons[i] .. " " .. name
        tb.TextColor3 = THEME.TextDim
        tb.Font = Enum.Font.GothamBold
        tb.TextSize = 11
        tb.LayoutOrder = i
        tb.ZIndex = 23
        tb.Parent = tabs
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
        tabButtons[name] = tb
        tb.MouseButton1Click:Connect(function() selectTab(name) end)
    end

    -- ============ المكونات ============
    local function makeToggle(parent, text, key, order, callback)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -8, 0, 40)
        card.BackgroundColor3 = THEME.Card
        card.BorderSizePixel = 0
        card.LayoutOrder = order
        card.ZIndex = 23
        card.Parent = parent
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -70, 1, 0)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = THEME.Text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 24
        lbl.Parent = card

        local switch = Instance.new("TextButton")
        switch.Size = UDim2.new(0, 46, 0, 24)
        switch.Position = UDim2.new(1, -58, 0.5, -12)
        switch.BackgroundColor3 = CONFIG[key] and THEME.Success or THEME.Danger
        switch.Text = ""
        switch.BorderSizePixel = 0
        switch.ZIndex = 24
        switch.Parent = card
        Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = CONFIG[key] and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.ZIndex = 25
        knob.Parent = switch
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local function refresh()
            local on = CONFIG[key]
            switch.BackgroundColor3 = on and THEME.Success or THEME.Danger
            TweenService:Create(knob, TweenInfo.new(0.15),
                {Position = on and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)}):Play()
            if callback then callback() end
            saveSettings()
        end

        switch.MouseButton1Click:Connect(function()
            CONFIG[key] = not CONFIG[key]
            refresh()
        end)
        card.MouseButton1Click:Connect(function()
            CONFIG[key] = not CONFIG[key]
            refresh()
        end)
        card.MouseEnter:Connect(function()
            TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = THEME.CardHover}):Play()
        end)
        card.MouseLeave:Connect(function()
            TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Card}):Play()
        end)
    end

    local function makeSlider(parent, text, key, minV, maxV, step, order)
        local fr = Instance.new("Frame")
        fr.Size = UDim2.new(1, -8, 0, 60)
        fr.BackgroundColor3 = THEME.Card
        fr.BorderSizePixel = 0
        fr.LayoutOrder = order
        fr.ZIndex = 23
        fr.Parent = parent
        Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 0, 20)
        lbl.Position = UDim2.new(0, 14, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = THEME.Text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 24
        lbl.Parent = fr

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0, 50, 0, 20)
        valLbl.Position = UDim2.new(1, -56, 0, 4)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = tostring(CONFIG[key])
        valLbl.TextColor3 = THEME.Accent
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 13
        valLbl.ZIndex = 24
        valLbl.Parent = fr

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -24, 0, 10)
        bar.Position = UDim2.new(0, 12, 0, 38)
        bar.BackgroundColor3 = THEME.Bg
        bar.BorderSizePixel = 0
        bar.ZIndex = 24
        bar.Parent = fr
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((CONFIG[key] - minV) / (maxV - minV), 0, 1, 0)
        fill.BackgroundColor3 = THEME.Accent
        fill.BorderSizePixel = 0
        fill.ZIndex = 25
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("TextButton")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = UDim2.new((CONFIG[key] - minV) / (maxV - minV), -9, 0.5, -9)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.Text = ""
        knob.BorderSizePixel = 0
        knob.ZIndex = 26
        knob.Parent = bar
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local dragging = false
        local function update(x)
            local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local v = minV + rel * (maxV - minV)
            v = math.floor(v / step + 0.5) * step
            CONFIG[key] = v
            valLbl.Text = tostring(v)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -9, 0.5, -9)
        end

        knob.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                update(i.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
                update(i.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                saveSettings()
            end
        end)
    end

    local function makeLabel(parent, text, order)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -8, 0, 26)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = THEME.TextDim
        l.Font = Enum.Font.GothamBold
        l.TextSize = 12
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.LayoutOrder = order
        l.ZIndex = 23
        l.Parent = parent
    end

    local function makeButton(parent, text, color, order, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -8, 0, 34)
        b.BackgroundColor3 = color or THEME.Card
        b.BorderSizePixel = 0
        b.Text = text
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.LayoutOrder = order
        b.ZIndex = 23
        b.Parent = parent
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        if callback then
            b.MouseButton1Click:Connect(function()
                callback()
                saveSettings()
            end)
        end
    end

    -- ============ تبويب ESP ============
    makeLabel(pageESP, "  👁 ESP", 1)
    makeToggle(pageESP, "تفعيل ESP", "ESPEnabled", 2)
    makeToggle(pageESP, "الإطار", "ShowHighlight", 3)
    makeToggle(pageESP, "الأسماء", "ShowNames", 4, function()
        for _, d in pairs(ESPData) do
            if d.NameLabel then d.NameLabel.Visible = CONFIG.ShowNames end
        end
    end)
    makeToggle(pageESP, "المسافات", "ShowDistance", 5)
    makeToggle(pageESP, "الخطوط", "ShowTracers", 6)
    makeToggle(pageESP, "الصندوق", "ShowBox", 7)
    makeToggle(pageESP, "فحص الفريق", "TeamCheck", 8)

    -- ============ تبويب Aimbot ============
    makeLabel(pageAim, "  🎯 Aimbot", 1)
    makeToggle(pageAim, "تفعيل Aimbot", "AimbotEnabled", 2)
    makeToggle(pageAim, "قفل الهدف تلقائياً", "LockOnTarget", 3)
    makeToggle(pageAim, "إطلاق تلقائي", "AutoFire", 4)
    makeToggle(pageAim, "دائرة FOV", "ShowFOVCircle", 5)
    makeToggle(pageAim, "المرئيون فقط", "AimbotVisibleOnly", 6)
    makeSlider(pageAim, "نطاق FOV", "AimbotFOV", 30, 600, 10, 7)
    makeSlider(pageAim, "نعومة", "AimbotSmoothing", 0, 0.9, 0.05, 8)
    makeSlider(pageAim, "تأخير الإطلاق", "FireDelay", 0.05, 0.5, 0.05, 9)

    makeLabel(pageAim, "  🚀 توقع الحركة", 10)
    makeToggle(pageAim, "تفعيل توقع الحركة", "PredictiveEnabled", 11)
    makeSlider(pageAim, "قوة التوقع", "PredictionStrength", 0, 1.5, 0.05, 12)
    makeSlider(pageAim, "زمن التوقع (ث)", "PredictionTime", 0, 0.5, 0.05, 13)

    makeLabel(pageAim, "  🎯 نمط التصويب", 14)
    local modeFr = Instance.new("Frame")
    modeFr.Size = UDim2.new(1, -8, 0, 44)
    modeFr.BackgroundColor3 = THEME.Card
    modeFr.BorderSizePixel = 0
    modeFr.LayoutOrder = 15
    modeFr.ZIndex = 23
    modeFr.Parent = pageAim
    Instance.new("UICorner", modeFr).CornerRadius = UDim.new(0, 8)

    local modeBtns = {}
    local modes = {
        {id = "Silent", label = "صامت"},
        {id = "Camera", label = "كاميرا"},
    }
    for i, m in ipairs(modes) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.48, 0, 0, 30)
        b.Position = UDim2.new(0.01 + (i-1)*0.5, 0, 0.5, -15)
        b.BackgroundColor3 = CONFIG.AimbotMode == m.id and THEME.Accent or THEME.Bg
        b.Text = m.label
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.BorderSizePixel = 0
        b.ZIndex = 24
        b.Parent = modeFr
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        modeBtns[m.id] = b
        b.MouseButton1Click:Connect(function()
            CONFIG.AimbotMode = m.id
            for k, btn2 in pairs(modeBtns) do
                btn2.BackgroundColor3 = k == m.id and THEME.Accent or THEME.Bg
            end
            saveSettings()
        end)
    end

    makeLabel(pageAim, "  🎯 الجزء المستهدف", 16)
    local partFr = Instance.new("Frame")
    partFr.Size = UDim2.new(1, -8, 0, 44)
    partFr.BackgroundColor3 = THEME.Card
    partFr.BorderSizePixel = 0
    partFr.LayoutOrder = 17
    partFr.ZIndex = 23
    partFr.Parent = pageAim
    Instance.new("UICorner", partFr).CornerRadius = UDim.new(0, 8)

    local parts = {
        {id = "Head", label = "رأس"},
        {id = "HumanoidRootPart", label = "جسم"},
        {id = "UpperTorso", label = "صدر"},
        {id = "LowerTorso", label = "بطن"},
    }
    local partBtns = {}
    for i, p in ipairs(parts) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.24, 0, 0, 30)
        b.Position = UDim2.new(0.01 + (i-1)*0.245, 0, 0.5, -15)
        b.BackgroundColor3 = CONFIG.AimbotPart == p.id and THEME.Accent or THEME.Bg
        b.Text = p.label
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.BorderSizePixel = 0
        b.ZIndex = 24
        b.Parent = partFr
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        partBtns[p.id] = b
        b.MouseButton1Click:Connect(function()
            CONFIG.AimbotPart = p.id
            for k, btn2 in pairs(partBtns) do
                btn2.BackgroundColor3 = k == p.id and THEME.Accent or THEME.Bg
            end
            saveSettings()
        end)
    end

    -- ============ تبويب Players ============
    makeLabel(pagePlayers, "  👥 قائمة اللاعبين", 1)

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -8, 0, 34)
    searchBox.BackgroundColor3 = THEME.Card
    searchBox.BorderSizePixel = 0
    searchBox.Text = ""
    searchBox.PlaceholderText = "ابحث بالاسم..."
    searchBox.PlaceholderColor3 = THEME.TextDim
    searchBox.TextColor3 = THEME.Text
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 13
    searchBox.ClearTextOnFocus = false
    searchBox.LayoutOrder = 2
    searchBox.ZIndex = 23
    searchBox.Parent = pagePlayers
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 8)

    local targetInfo = Instance.new("TextLabel")
    targetInfo.Size = UDim2.new(1, -8, 0, 32)
    targetInfo.BackgroundColor3 = THEME.Card
    targetInfo.BorderSizePixel = 0
    targetInfo.Text = "🎯 الهدف: لا يوجد"
    targetInfo.TextColor3 = THEME.Accent
    targetInfo.Font = Enum.Font.GothamBold
    targetInfo.TextSize = 13
    targetInfo.LayoutOrder = 3
    targetInfo.ZIndex = 23
    targetInfo.Parent = pagePlayers
    Instance.new("UICorner", targetInfo).CornerRadius = UDim.new(0, 8)

    makeButton(pagePlayers, "إلغاء الهدف المحدد", THEME.Danger, 4, function()
        CONFIG.SelectedTarget = nil
        LockedTarget = nil
        targetInfo.Text = "🎯 الهدف: لا يوجد"
    end)

    local playersListFrame = Instance.new("Frame")
    playersListFrame.Size = UDim2.new(1, -8, 0, 10)
    playersListFrame.AutomaticSize = Enum.AutomaticSize.Y
    playersListFrame.BackgroundTransparency = 1
    playersListFrame.LayoutOrder = 5
    playersListFrame.ZIndex = 23
    playersListFrame.Parent = pagePlayers
    local pll = Instance.new("UIListLayout", playersListFrame)
    pll.Padding = UDim.new(0, 5)
    pll.SortOrder = Enum.SortOrder.LayoutOrder

    local function refreshPlayerList()
        for _, c in ipairs(playersListFrame:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local lc = LocalPlayer.Character
        local lr = lc and lc:FindFirstChild("HumanoidRootPart")
        local search = string.lower(searchBox.Text or "")

        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local dist = 0
                if lr and p.Character then
                    local rr = p.Character:FindFirstChild("HumanoidRootPart")
                    if rr then dist = math.floor((lr.Position - rr.Position).Magnitude) end
                end
                table.insert(list, {player = p, dist = dist})
            end
        end
        table.sort(list, function(a, b) return a.dist < b.dist end)

        for i, entry in ipairs(list) do
            local p = entry.player
            if search ~= "" and not string.find(string.lower(p.Name), search, 1, true) then
                continue
            end

            local isSelected = (CONFIG.SelectedTarget == p.Name)
            local isLocked = (LockedTarget == p)

            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, 0, 0, 44)
            row.BackgroundColor3 = isLocked and THEME.Accent2
                    or (isSelected and THEME.Accent or THEME.Card)
            row.BorderSizePixel = 0
            row.Text = ""
            row.LayoutOrder = i
            row.ZIndex = 24
            row.Parent = playersListFrame
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -70, 1, 0)
            nameLbl.Position = UDim2.new(0, 14, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = (isLocked and "🎯 " or "") .. p.Name
            nameLbl.TextColor3 = Color3.new(1, 1, 1)
            nameLbl.Font = Enum.Font.Gotham
            nameLbl.TextSize = 13
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.ZIndex = 25
            nameLbl.Parent = row

            local distLbl = Instance.new("TextLabel")
            distLbl.Size = UDim2.new(0, 55, 1, 0)
            distLbl.Position = UDim2.new(1, -60, 0, 0)
            distLbl.BackgroundTransparency = 1
            distLbl.Text = entry.dist .. "m"
            distLbl.TextColor3 = Color3.new(1, 1, 1)
            distLbl.Font = Enum.Font.GothamBold
            distLbl.TextSize = 12
            distLbl.ZIndex = 25
            distLbl.Parent = row

            row.MouseButton1Click:Connect(function()
                if CONFIG.SelectedTarget == p.Name then
                    CONFIG.SelectedTarget = nil
                    LockedTarget = nil
                    targetInfo.Text = "🎯 الهدف: لا يوجد"
                else
                    CONFIG.SelectedTarget = p.Name
                    if CONFIG.AimbotEnabled then LockedTarget = p end
                    targetInfo.Text = "🎯 الهدف: " .. p.Name
                end
                refreshPlayerList()
                saveSettings()
            end)
        end
    end

    task.spawn(function()
        while sg.Parent do
            task.wait(1.2)
            if pagePlayers.Visible then
                pcall(refreshPlayerList)
                if LockedTarget and isValidCharacter(LockedTarget) then
                    targetInfo.Text = "🎯 الهدف: " .. LockedTarget.Name .. " ✓"
                    targetInfo.TextColor3 = THEME.Success
                elseif CONFIG.SelectedTarget then
                    targetInfo.Text = "🎯 الهدف: " .. CONFIG.SelectedTarget .. " (خارج المدى)"
                    targetInfo.TextColor3 = THEME.Danger
                else
                    targetInfo.Text = "🎯 الهدف: لا يوجد"
                    targetInfo.TextColor3 = THEME.Accent
                end
            end
        end
    end)

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        refreshPlayerList()
    end)

    -- ============ تبويب Settings ============
    makeLabel(pageSettings, "  ⚙ مفاتيح الاختصار", 1)
    local keysCard = Instance.new("Frame")
    keysCard.Size = UDim2.new(1, -8, 0, 150)
    keysCard.BackgroundColor3 = THEME.Card
    keysCard.BorderSizePixel = 0
    keysCard.LayoutOrder = 2
    keysCard.ZIndex = 23
    keysCard.Parent = pageSettings
    Instance.new("UICorner", keysCard).CornerRadius = UDim.new(0, 8)

    local keysText = Instance.new("TextLabel")
    keysText.Size = UDim2.new(1, -20, 1, 0)
    keysText.Position = UDim2.new(0, 14, 0, 0)
    keysText.BackgroundTransparency = 1
    keysText.Text = "RightAlt → Aimbot\nRightCtrl → AutoFire\nRightShift → LockOn\nP → Predictive\n\n(للكمبيوتر فقط)"
    keysText.TextColor3 = THEME.Text
    keysText.Font = Enum.Font.Gotham
    keysText.TextSize = 13
    keysText.TextXAlignment = Enum.TextXAlignment.Left
    keysText.TextYAlignment = Enum.TextYAlignment.Top
    keysText.ZIndex = 24
    keysText.Parent = keysCard

    makeLabel(pageSettings, "  ⚙ إدارة الإعدادات", 3)
    makeButton(pageSettings, "💾 حفظ الإعدادات", THEME.Success, 4, function()
        saveSettings()
        print("[NoopYT] ✅ تم حفظ الإعدادات")
    end)
    makeButton(pageSettings, "🔄 إعادة تعيين", THEME.Accent2, 5, function()
        CONFIG.ESPEnabled = true
        CONFIG.ShowNames = true
        CONFIG.ShowDistance = true
        CONFIG.ShowHighlight = true
        CONFIG.ShowTracers = true
        CONFIG.ShowBox = false
        CONFIG.TeamCheck = false
        CONFIG.AimbotEnabled = false
        CONFIG.AutoFire = false
        CONFIG.AimbotFOV = 200
        CONFIG.AimbotSmoothing = 0.15
        CONFIG.AimbotPart = "Head"
        CONFIG.AimbotMode = "Silent"
        CONFIG.PredictiveEnabled = true
        CONFIG.PredictionStrength = 0.5
        CONFIG.PredictionTime = 0.15
        print("[NoopYT] 🔄 تم إعادة التعيين (أعد التشغيل للتطبيق)")
    end)

    makeLabel(pageSettings, "  ⚙ معلومات", 6)
    local infoCard = Instance.new("Frame")
    infoCard.Size = UDim2.new(1, -8, 0, 100)
    infoCard.BackgroundColor3 = THEME.Card
    infoCard.BorderSizePixel = 0
    infoCard.LayoutOrder = 7
    infoCard.ZIndex = 23
    infoCard.Parent = pageSettings
    Instance.new("UICorner", infoCard).CornerRadius = UDim.new(0, 8)

    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, -20, 1, 0)
    infoText.Position = UDim2.new(0, 14, 0, 0)
    infoText.BackgroundTransparency = 1
    infoText.Text = "NoopYT v9 Pro Edition\n\n• ESP احترافي\n• Aimbot + Predictive\n• Silent Aim\n• حفظ الإعدادات"
    infoText.TextColor3 = THEME.Text
    infoText.Font = Enum.Font.Gotham
    infoText.TextSize = 13
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.TextYAlignment = Enum.TextYAlignment.Top
    infoText.ZIndex = 24
    infoText.Parent = infoCard

    -- فتح تبويب ESP افتراضياً
    selectTab("ESP")

    return sg
end

-- ==================== FOV Circle ====================
if Drawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1
    FOVCircle.NumSides = 64
    FOVCircle.Radius = CONFIG.AimbotFOV
    FOVCircle.Filled = false
    FOVCircle.Color = CONFIG.FOVColor
    FOVCircle.Transparency = 1
    FOVCircle.Visible = false
end

-- ==================== تشغيل ====================
pcall(createGUI)

-- حفظ الإعدادات تلقائياً كل 30 ثانية
task.spawn(function()
    while true do
        task.wait(30)
        pcall(saveSettings)
    end
end)

print("[NoopYT v9] ✅ Pro Edition Loaded")
print("[NoopYT v9] ESP + Aimbot + Predictive + Save Settings")
print("[NoopYT v9] RightAlt=Aimbot | P=Predictive")
