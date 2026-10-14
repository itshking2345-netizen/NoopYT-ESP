-- ============================================================
-- NoopYT Universal ESP + Aimbot v4
-- قائمة كاملة + إصلاح ظهور اللاعبين + تحكم سلس
-- متوافق مع: Arceus X Neo / Delta / Fluxus
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

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
    MaxDistance = 2000,
    HighlightFill = Color3.fromRGB(255, 50, 50),
    HighlightOutline = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 50, 50),
    BoxColor = Color3.fromRGB(255, 255, 255),
    FillTransparency = 0.7,
    OutlineTransparency = 0.2,
    RefreshRate = 0.5,   -- معدل الفحص الشامل (ثانية)

    -- Aimbot
    AimbotEnabled = false,
    AimbotFOV = 150,
    AimbotSmoothing = 0.25,
    AimbotPart = "Head",
    AimbotVisibleOnly = false,
    ShowFOVCircle = true,
    FOVColor = Color3.fromRGB(255, 80, 80),
}

-- ==================== التخزين ====================
local ESPData = {}
local Tracers = {}
local Boxes = {}
local FOVCircle = nil
local AimbotActive = false
local CurrentTarget = nil

-- ==================== أدوات مساعدة ====================
local function safeDestroy(obj)
    if obj and typeof(obj) == "Instance" and obj.Parent then
        pcall(function() obj:Destroy() end)
    end
end

local function isValidPlayer(player)
    if not player or player == LocalPlayer then return false end
    if not player.Parent then return false end
    return true
end

local function isValidCharacter(player)
    if not isValidPlayer(player) then return false end
    local char = player.Character
    if not char or not char.Parent then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    return true
end

local function isSameTeam(player)
    if not CONFIG.TeamCheck then return false end
    return player.Team == LocalPlayer.Team
end

-- ==================== تنظيف ====================
local function cleanupESP(player)
    local data = ESPData[player]
    if data then
        safeDestroy(data.Highlight)
        safeDestroy(data.Billboard)
        safeDestroy(data.Box)
        ESPData[player] = nil
    end
    local tracer = Tracers[player]
    if tracer then
        pcall(function() tracer:Remove() end)
        Tracers[player] = nil
    end
    local box = Boxes[player]
    if box then
        pcall(function() box:Remove() end)
        Boxes[player] = nil
    end
end

-- ==================== إنشاء ESP لشخص واحد ====================
local function createESP(player)
    if not isValidPlayer(player) then return end
    if isSameTeam(player) then return end
    if ESPData[player] then return end
    if not isValidCharacter(player) then return end

    local char = player.Character
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")

    if not humanoid or not rootPart then return end

    local ok, err = pcall(function()
        -- Highlight
        local highlight = Instance.new("Highlight")
        highlight.Name = "NoopYT_Highlight"
        highlight.FillColor = CONFIG.HighlightFill
        highlight.OutlineColor = CONFIG.HighlightOutline
        highlight.FillTransparency = CONFIG.FillTransparency
        highlight.OutlineTransparency = CONFIG.OutlineTransparency
        highlight.Adornee = char
        highlight.Parent = char

        -- Billboard
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "NoopYT_Billboard"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = char
        billboard.Parent = char

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
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
        distLabel.Name = "DistLabel"
        distLabel.Size = UDim2.new(1, 0, 0.4, 0)
        distLabel.Position = UDim2.new(0, 0, 0.6, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        distLabel.TextStrokeTransparency = 0
        distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        distLabel.Font = Enum.Font.Gotham
        distLabel.TextScaled = true
        distLabel.Visible = CONFIG.ShowDistance
        distLabel.Parent = billboard

        -- Tracer
        if Drawing then
            local tracer = Drawing.new("Line")
            tracer.Visible = false
            tracer.Thickness = 1.5
            tracer.Color = CONFIG.TracerColor
            tracer.Transparency = 1
            Tracers[player] = tracer
        end

        -- Box (اختياري)
        if Drawing then
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

    if not ok then
        warn("[NoopYT] فشل ESP لـ " .. player.Name .. ": " .. tostring(err))
        cleanupESP(player)
    end
end

-- ==================== الفحص الشامل (الإصلاح الرئيسي) ====================
local function fullRefresh()
    if not CONFIG.ESPEnabled then return end

    -- 1. إزالة ESP للاعبين الذين خرجوا أو ماتوا
    for player, _ in pairs(ESPData) do
        if not isValidPlayer(player) then
            cleanupESP(player)
        elseif not isValidCharacter(player) then
            -- احتفظ بالـ Highlight لكن أخفِ الـ Billboard
            local data = ESPData[player]
            if data.Billboard then data.Billboard.Enabled = false end
        end
    end

    -- 2. إنشاء ESP لكل لاعب صالح
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidPlayer(player) and isValidCharacter(player) and not isSameTeam(player) then
            if not ESPData[player] then
                createESP(player)
            else
                -- تأكد أن ESP سليم (لم يُحذف)
                local data = ESPData[player]
                if data.Highlight and not data.Highlight.Parent then
                    cleanupESP(player)
                    createESP(player)
                end
                if data.Billboard then data.Billboard.Enabled = true end
            end
        end
    end
end

-- ==================== مراقبة اللاعبين ====================
local function watchCharacter(player)
    if not isValidPlayer(player) then return end

    task.spawn(function()
        -- انتظر حتى يظهر الكارakter
        local char = player.Character or player.CharacterAdded:Wait()
        if not char then return end

        -- انتظر Humanoid و HumanoidRootPart
        local humanoid = char:WaitForChild("Humanoid", 10)
        local root = char:WaitForChild("HumanoidRootPart", 10)

        if humanoid and root and humanoid.Health > 0 then
            cleanupESP(player)  -- نظّف القديم
            createESP(player)
        end

        -- راقب الموت
        if humanoid then
            humanoid.Died:Connect(function()
                cleanupESP(player)
            end)
        end
    end)
end

local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    watchCharacter(player)

    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        watchCharacter(player)
    end)

    player.CharacterRemoving:Connect(function()
        cleanupESP(player)
    end)
end

local function onPlayerRemoving(player)
    cleanupESP(player)
end

-- تهيئة اللاعبين الموجودين
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- راقب التغييرات في Character
task.spawn(function()
    while CONFIG.ESPEnabled do
        task.wait(0.5)
        for _, player in ipairs(Players:GetPlayers()) do
            if isValidPlayer(player) then
                if player.Character and not player.Character:FindFirstChild("HumanoidRootPart") then
                    -- الشخصية موجودة لكن لم تُحمّل بالكامل
                    watchCharacter(player)
                end
            end
        end
    end
end)

-- ==================== Tracers و Boxes ====================
local function updateVisuals()
    if not Camera then return end
    local screenSize = Camera.ViewportSize
    local startPoint = Vector2.new(screenSize.X / 2, screenSize.Y)

    for player, tracer in pairs(Tracers) do
        if not tracer then continue end
        if not CONFIG.ESPEnabled or not CONFIG.ShowTracers then
            tracer.Visible = false
        else
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local sp, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        tracer.From = startPoint
                        tracer.To = Vector2.new(sp.X, sp.Y)
                        tracer.Visible = true
                    else
                        tracer.Visible = false
                    end
                else
                    tracer.Visible = false
                end
            else
                tracer.Visible = false
            end
        end
    end

    -- Boxes
    for player, box in pairs(Boxes) do
        if not box then continue end
        if not CONFIG.ESPEnabled or not CONFIG.ShowBox then
            box.Visible = false
        else
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local dist = (Camera.CFrame.Position - root.Position).Magnitude
                        local height = math.clamp(2000 / dist, 20, 400)
                        local width = height * 0.6
                        box.Size = Vector2.new(width, height)
                        box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
                        box.Visible = true
                    else
                        box.Visible = false
                    end
                else
                    box.Visible = false
                end
            else
                box.Visible = false
            end
        end
    end
end

-- ==================== تحديث المسافات ====================
local distAccum = 0
local function updateDistances(dt)
    distAccum = distAccum + dt
    if distAccum < 0.1 then return end
    distAccum = 0

    local localChar = LocalPlayer.Character
    if not localChar then return end
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    for player, data in pairs(ESPData) do
        if data.DistLabel and data.DistLabel.Parent then
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local distance = (localRoot.Position - root.Position).Magnitude
                    data.DistLabel.Text = string.format("[%d]", math.floor(distance))
                    data.DistLabel.Visible = CONFIG.ShowDistance
                end
            end
        end
    end
end

-- ==================== AIMBOT ====================
local function isVisible(part)
    if not CONFIG.AimbotVisibleOnly then return true end
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = workspace:Raycast(origin, dir, params)
    if result then
        return result.Instance:IsDescendantOf(part.Parent)
    end
    return true
end

local function getBestTarget()
    if not Camera then return nil end
    local closest = nil
    local shortestDist = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if isSameTeam(player) then continue end
        local char = player.Character
        if not char then continue end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        local targetPart = char:FindFirstChild(CONFIG.AimbotPart)
                    or char:FindFirstChild("HumanoidRootPart")
        if not targetPart then continue end

        local sp, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if dist > CONFIG.AimbotFOV then continue end
        if dist >= shortestDist then continue end
        if not isVisible(targetPart) then continue end

        shortestDist = dist
        closest = {player = player, part = targetPart}
    end
    return closest
end

local function performAimbot()
    if not CONFIG.AimbotEnabled then CurrentTarget = nil return end
    local target = getBestTarget()
    CurrentTarget = target
    if not target then return end

    local desired = CFrame.new(Camera.CFrame.Position, target.part.Position)
    local smooth = math.clamp(CONFIG.AimbotSmoothing, 0, 0.95)
    if smooth <= 0 then
        Camera.CFrame = desired
    else
        Camera.CFrame = Camera.CFrame:Lerp(desired, 1 - smooth)
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

    -- الفحص الشامل الدوري (الإصلاح الرئيسي)
    refreshAccum = refreshAccum + dt
    if refreshAccum >= CONFIG.RefreshRate then
        refreshAccum = 0
        pcall(fullRefresh)
    end

    -- تحديث الرؤية
    updateDistances(dt)
    pcall(updateVisuals)

    -- Aimbot
    if CONFIG.AimbotEnabled and AimbotActive then
        pcall(performAimbot)
    end

    updateFOVCircle()
end)

-- ==================== مفاتيح Aimbot ====================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimbotActive = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimbotActive = false
    end
end)

-- ============================================================
-- ==================== GUI ===================================
-- ============================================================

local function createGUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "NoopYT_v4"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true

    local parent = LocalPlayer:WaitForChild("PlayerGui")
    if gethui then parent = gethui()
    elseif syn and syn.protect_gui then
        parent = game:GetService("CoreGui")
        syn.protect_gui(sg)
    end
    sg.Parent = parent

    -- زر عائم
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 60)
    btn.Position = UDim2.new(0, 20, 0.5, -30)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    btn.BorderSizePixel = 0
    btn.Text = "ESP"
    btn.TextColor3 = Color3.fromRGB(255, 80, 80)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Active = true
    btn.Draggable = true
    btn.Parent = sg
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local bs = Instance.new("UIStroke", btn)
    bs.Color = Color3.fromRGB(255, 80, 80)
    bs.Thickness = 2

    -- اللوحة
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 260, 0, 520)
    panel.Position = UDim2.new(0, 90, 0.5, -260)
    panel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Active = true
    panel.Draggable = true
    panel.Parent = sg
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    local ps = Instance.new("UIStroke", panel)
    ps.Color = Color3.fromRGB(255, 80, 80)
    ps.Thickness = 1.5

    -- العنوان
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    title.BorderSizePixel = 0
    title.Text = "NoopYT v4"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = panel
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    -- زر إغلاق
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -35, 0, 5)
    close.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    close.Text = "X"
    close.TextColor3 = Color3.new(1, 1, 1)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    close.BorderSizePixel = 0
    close.Parent = title
    Instance.new("UICorner", close).CornerRadius = UDim.new(1, 0)

    -- تبويبات
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, -10, 0, 32)
    tabFrame.Position = UDim2.new(0, 5, 0, 45)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = panel

    local tabLayout = Instance.new("UIListLayout", tabFrame)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- محتوى
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -10, 1, -90)
    content.Position = UDim2.new(0, 5, 0, 82)
    content.BackgroundTransparency = 1
    content.Parent = panel

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 600)
    scroll.Parent = content

    local listLayout = Instance.new("UIListLayout", scroll)
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- دوال مساعدة
    local function makeToggle(parent, text, key, order, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -8, 0, 36)
        b.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        b.BorderSizePixel = 0
        b.Text = text .. ": " .. (CONFIG[key] and "ON" or "OFF")
        b.TextColor3 = CONFIG[key] and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
        b.Font = Enum.Font.Gotham
        b.TextSize = 14
        b.LayoutOrder = order
        b.Parent = parent
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

        b.MouseButton1Click:Connect(function()
            CONFIG[key] = not CONFIG[key]
            b.Text = text .. ": " .. (CONFIG[key] and "ON" or "OFF")
            b.TextColor3 = CONFIG[key] and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
            if callback then callback() end
        end)
    end

    local function makeSlider(parent, text, key, minV, maxV, step, order)
        local fr = Instance.new("Frame")
        fr.Size = UDim2.new(1, -8, 0, 56)
        fr.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
        fr.BorderSizePixel = 0
        fr.LayoutOrder = order
        fr.Parent = parent
        Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 22)
        lbl.Position = UDim2.new(0, 5, 0, 3)
        lbl.BackgroundTransparency = 1
        lbl.Text = text .. ": " .. tostring(CONFIG[key])
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = fr

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -20, 0, 10)
        bar.Position = UDim2.new(0, 10, 0, 35)
        bar.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
        bar.BorderSizePixel = 0
        bar.Parent = fr
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((CONFIG[key] - minV) / (maxV - minV), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        fill.BorderSizePixel = 0
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("TextButton")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = UDim2.new((CONFIG[key] - minV) / (maxV - minV), -9, 0.5, -9)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.Text = ""
        knob.BorderSizePixel = 0
        knob.Parent = bar
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local dragging = false
        local function update(x)
            local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local v = minV + rel * (maxV - minV)
            v = math.floor(v / step + 0.5) * step
            CONFIG[key] = v
            lbl.Text = text .. ": " .. tostring(v)
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
            end
        end)
    end

    -- ============ تبويب ESP ============
    local espScroll = scroll

    makeToggle(espScroll, "ESP رئيسي", "ESPEnabled", 1)
    makeToggle(espScroll, "الإطار", "ShowHighlight", 2)
    makeToggle(espScroll, "الأسماء", "ShowNames", 3, function()
        for _, d in pairs(ESPData) do
            if d.NameLabel then d.NameLabel.Visible = CONFIG.ShowNames end
        end
    end)
    makeToggle(espScroll, "المسافات", "ShowDistance", 4)
    makeToggle(espScroll, "الخطوط", "ShowTracers", 5)
    makeToggle(espScroll, "الصندوق", "ShowBox", 6)

    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, -8, 0, 2)
    sep.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    sep.BorderSizePixel = 0
    sep.LayoutOrder = 7
    sep.Parent = espScroll

    makeToggle(espScroll, "Aimbot", "AimbotEnabled", 8)
    makeToggle(espScroll, "دائرة FOV", "ShowFOVCircle", 9)
    makeToggle(espScroll, "المرئيون فقط", "AimbotVisibleOnly", 10)
    makeSlider(espScroll, "FOV", "AimbotFOV", 30, 500, 10, 11)
    makeSlider(espScroll, "نعومة", "AimbotSmoothing", 0, 0.9, 0.05, 12)

    -- اختيار الجزء
    local partFr = Instance.new("Frame")
    partFr.Size = UDim2.new(1, -8, 0, 70)
    partFr.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    partFr.BorderSizePixel = 0
    partFr.LayoutOrder = 13
    partFr.Parent = espScroll
    Instance.new("UICorner", partFr).CornerRadius = UDim.new(0, 8)

    local partLbl = Instance.new("TextLabel")
    partLbl.Size = UDim2.new(1, -10, 0, 20)
    partLbl.Position = UDim2.new(0, 5, 0, 3)
    partLbl.BackgroundTransparency = 1
    partLbl.Text = "الجزء المستهدف: " .. CONFIG.AimbotPart
    partLbl.TextColor3 = Color3.new(1, 1, 1)
    partLbl.Font = Enum.Font.Gotham
    partLbl.TextSize = 13
    partLbl.TextXAlignment = Enum.TextXAlignment.Left
    partLbl.Parent = partFr

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
        b.Position = UDim2.new(0.01 + (i-1)*0.245, 0, 0, 30)
        b.BackgroundColor3 = CONFIG.AimbotPart == p.id and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(50, 50, 60)
        b.Text = p.label
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.Gotham
        b.TextSize = 12
        b.BorderSizePixel = 0
        b.Parent = partFr
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        partBtns[p.id] = b

        b.MouseButton1Click:Connect(function()
            CONFIG.AimbotPart = p.id
            for k, btn in pairs(partBtns) do
                btn.BackgroundColor3 = k == p.id and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(50, 50, 60)
            end
            partLbl.Text = "الجزء المستهدف: " .. p.id
        end)
    end

    -- أزرار رئيسية
    btn.MouseButton1Click:Connect(function()
        panel.Visible = not panel.Visible
    end)
    close.MouseButton1Click:Connect(function()
        panel.Visible = false
    end)

    return sg
end

-- ==================== إنشاء FOV ====================
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

-- ==================== التشغيل ====================
pcall(createGUI)

print("[NoopYT v4] ✅ تم التحميل")
print("[NoopYT v4] ESP + Aimbot + قائمة كاملة + إصلاح الظهور")
