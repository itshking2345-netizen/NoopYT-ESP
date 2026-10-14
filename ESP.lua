-- ============================================================
-- NoopYT Universal ESP + Aimbot v3
-- متوافق مع: Arceus X Neo / Delta / Fluxus (أندرويد)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==================== الإعدادات ====================
local CONFIG = {
    -- ESP
    Enabled = true,
    ShowNames = true,
    ShowDistance = true,
    ShowHighlight = true,
    ShowTracers = true,
    HighlightFill = Color3.fromRGB(255, 50, 50),
    HighlightOutline = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 50, 50),
    FillTransparency = 0.7,
    OutlineTransparency = 0.2,
    UpdateRate = 0.05,

    -- Aimbot
    AimbotEnabled = false,       -- الافتراضي مغلق
    AimbotKey = Enum.UserInputType.MouseButton2, -- يمين الفأرة (كمبيوتر)
    AimbotFOV = 150,             -- نطاق الرؤية بالبكسل
    AimbotSmoothing = 0.25,      -- 0=سريع جداً, 1=بطيء جداً
    AimbotPart = "Head",         -- Head / HumanoidRootPart / UpperTorso
    AimbotVisibleOnly = false,   -- استهدف فقط المرئيين
    ShowFOVCircle = true,
    FOVColor = Color3.fromRGB(255, 80, 80),
}

-- ==================== التخزين ====================
local ESPData = {}
local Tracers = {}
local Connections = {}
local FOVCircle = nil
local AimbotActive = false
local CurrentTarget = nil

-- ==================== تنظيف ====================
local function cleanupESP(player)
    local data = ESPData[player]
    if not data then return end
    if data.Highlight and data.Highlight.Parent then
        data.Highlight:Destroy()
    end
    if data.Billboard and data.Billboard.Parent then
        data.Billboard:Destroy()
    end
    ESPData[player] = nil
end

-- ==================== إنشاء ESP ====================
local function createESP(player)
    if player == LocalPlayer then return end
    if ESPData[player] then return end

    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "NoopYT_ESP_Highlight"
    highlight.FillColor = CONFIG.HighlightFill
    highlight.OutlineColor = CONFIG.HighlightOutline
    highlight.FillTransparency = CONFIG.FillTransparency
    highlight.OutlineTransparency = CONFIG.OutlineTransparency
    highlight.Adornee = character
    highlight.Parent = character

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NoopYT_ESP_Billboard"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = character
    billboard.Parent = character

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

    ESPData[player] = {
        Highlight = highlight,
        Billboard = billboard,
        NameLabel = nameLabel,
        DistLabel = distLabel,
    }
end

-- ==================== إنشاء Tracer ====================
local function createTracer(player)
    if Tracers[player] then return end
    if not Drawing then return end
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Thickness = 1.5
    tracer.Color = CONFIG.TracerColor
    tracer.Transparency = 1
    Tracers[player] = tracer
end

-- ==================== إنشاء دائرة FOV ====================
local function createFOVCircle()
    if not Drawing then return end
    if FOVCircle then FOVCircle:Remove() end
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1
    FOVCircle.NumSides = 64
    FOVCircle.Radius = CONFIG.AimbotFOV
    FOVCircle.Filled = false
    FOVCircle.Color = CONFIG.FOVColor
    FOVCircle.Transparency = 1
    FOVCircle.Visible = false
end

-- ==================== تحديث Tracers ====================
local function updateTracers()
    if not CONFIG.ShowTracers then
        for _, tracer in pairs(Tracers) do
            if tracer then tracer.Visible = false end
        end
        return
    end

    if not Camera then return end
    local screenSize = Camera.ViewportSize
    local startPoint = Vector2.new(screenSize.X / 2, screenSize.Y)

    for player, tracer in pairs(Tracers) do
        if not tracer then continue end
        local char = player.Character
        if not char then tracer.Visible = false continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then
            tracer.Visible = false continue
        end
        local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then tracer.Visible = false continue end
        tracer.From = startPoint
        tracer.To = Vector2.new(screenPos.X, screenPos.Y)
        tracer.Visible = true
    end
end

-- ==================== تحديث المسافات ====================
local accumulator = 0
local function updateDistances(dt)
    accumulator = accumulator + dt
    if accumulator < CONFIG.UpdateRate then return end
    accumulator = 0

    local localChar = LocalPlayer.Character
    if not localChar then return end
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    for player, data in pairs(ESPData) do
        if not data.Billboard or not data.Billboard.Parent then continue end
        if not CONFIG.ShowDistance then
            if data.DistLabel then data.DistLabel.Visible = false end
            continue
        end
        local char = player.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local distance = (localRoot.Position - root.Position).Magnitude
        if data.DistLabel then
            data.DistLabel.Text = string.format("[%d studs]", math.floor(distance))
            data.DistLabel.Visible = true
        end
    end
end

-- ============================================================
-- ==================== AIMBOT =================================
-- ============================================================

-- فحص الرؤية
local function isVisible(part)
    if not CONFIG.AimbotVisibleOnly then return true end
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (part.Position - rayOrigin)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
    if result then
        return result.Instance:IsDescendantOf(part.Parent)
    end
    return true
end

-- إيجاد أفضل هدف
local function getBestTarget()
    if not Camera then return nil end
    local closest = nil
    local shortestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        local targetPart = char:FindFirstChild(CONFIG.AimbotPart)
        if not targetPart then
            targetPart = char:FindFirstChild("HumanoidRootPart")
        end
        if not targetPart then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end

        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
        if dist > CONFIG.AimbotFOV then continue end
        if dist >= shortestDist then continue end

        if not isVisible(targetPart) then continue end

        shortestDist = dist
        closest = {player = player, part = targetPart}
    end
    return closest
end

-- تنفيذ التصويب
local function performAimbot()
    if not CONFIG.AimbotEnabled then
        CurrentTarget = nil
        return
    end

    local target = getBestTarget()
    CurrentTarget = target
    if not target then return end

    local targetPos = target.part.Position
    local camPos = Camera.CFrame.Position
    local desiredCFrame = CFrame.new(camPos, targetPos)

    -- Smoothing
    local smooth = math.clamp(CONFIG.AimbotSmoothing, 0, 1)
    if smooth <= 0 then
        Camera.CFrame = desiredCFrame
    else
        Camera.CFrame = Camera.CFrame:Lerp(desiredCFrame, 1 - smooth)
    end
end

-- تحديث دائرة FOV
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

-- أحداث تشغيل Aimbot
local function setupAimbotInput()
    -- كمبيوتر: زر الفأرة الأيمن
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == CONFIG.AimbotKey then
            AimbotActive = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == CONFIG.AimbotKey then
            AimbotActive = false
        end
    end)

    -- للمس (أندرويد): استخدام اللمس في الجهة اليمنى من الشاشة
    -- يمكن أيضاً التفعيل الدائم عبر الزر
end

-- ==================== أحداث اللاعبين ====================
local function onCharacterAdded(player, character)
    task.wait(0.5)
    if not CONFIG.Enabled then return end
    if player == LocalPlayer then return end
    cleanupESP(player)
    createTracer(player)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid and humanoid.Health > 0 then
        createESP(player)
    end
end

local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end)
    player.CharacterRemoving:Connect(function()
        cleanupESP(player)
    end)
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
end

local function onPlayerRemoving(player)
    cleanupESP(player)
    local tracer = Tracers[player]
    if tracer then
        tracer:Remove()
        Tracers[player] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ==================== الحلقة الرئيسية ====================
Connections.heartbeat = RunService.RenderStepped:Connect(function(dt)
    if not Camera then Camera = workspace.CurrentCamera end

    if not CONFIG.Enabled then
        for player, _ in pairs(ESPData) do
            cleanupESP(player)
        end
        for _, tracer in pairs(Tracers) do
            if tracer then tracer.Visible = false end
        end
    else
        -- ضمان ESP
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if not ESPData[player] then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        createESP(player)
                    end
                end
                if not Tracers[player] then
                    createTracer(player)
                end
            end
        end

        for _, data in pairs(ESPData) do
            if data.Highlight then data.Highlight.Enabled = CONFIG.ShowHighlight end
            if data.NameLabel then data.NameLabel.Visible = CONFIG.ShowNames end
        end

        updateDistances(dt)
        updateTracers()
    end

    -- Aimbot يعمل دائماً إذا كان مفعل
    if CONFIG.AimbotEnabled and AimbotActive then
        performAimbot()
    elseif CONFIG.AimbotEnabled and not AimbotActive then
        -- ملاحظة: يمكن جعل Aimbot يعمل دائماً بمجرد تفعيله
        -- حالياً يعمل فقط عند الضغط على الزر
    end

    updateFOVCircle()
end)

-- ============================================================
-- ==================== GUI ===================================
-- ============================================================

local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NoopYT_ESP_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local parent
    if gethui then
        parent = gethui()
    elseif syn and syn.protect_gui then
        parent = game:GetService("CoreGui")
        syn.protect_gui(screenGui)
    else
        parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    screenGui.Parent = parent

    -- الزر العائم
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.new(0, 60, 0, 60)
    toggleBtn.Position = UDim2.new(0, 20, 0.5, -30)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "ESP"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Active = true
    toggleBtn.Draggable = true
    toggleBtn.Parent = screenGui

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(1, 0)
    btnCorner.Parent = toggleBtn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(255, 80, 80)
    btnStroke.Thickness = 2
    btnStroke.Parent = toggleBtn

    -- اللوحة
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 250, 0, 480)
    panel.Position = UDim2.new(0, 100, 0.5, -240)
    panel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Active = true
    panel.Draggable = true
    panel.Parent = screenGui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Color3.fromRGB(255, 80, 80)
    panelStroke.Thickness = 1.5
    panelStroke.Parent = panel

    -- العنوان
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    title.BorderSizePixel = 0
    title.Text = "NoopYT ESP + Aimbot"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = panel

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = title

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = title

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeBtn

    -- قائمة التمرير
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -55)
    scroll.Position = UDim2.new(0, 10, 0, 45)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 700)
    scroll.Parent = panel

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scroll

    -- دالة زر Toggle
    local function makeToggle(text, key, order, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 38)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
        btn.BorderSizePixel = 0
        btn.Text = text .. ": " .. (CONFIG[key] and "ON" or "OFF")
        btn.TextColor3 = CONFIG[key] and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.LayoutOrder = order
        btn.Parent = scroll

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = btn

        btn.MouseButton1Click:Connect(function()
            CONFIG[key] = not CONFIG[key]
            btn.Text = text .. ": " .. (CONFIG[key] and "ON" or "OFF")
            btn.TextColor3 = CONFIG[key] and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
            if callback then callback() end
        end)
    end

    -- دالة زر Slider (للتعديل السلس)
    local function makeSlider(text, key, minVal, maxVal, step, order)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -8, 0, 60)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        frame.BorderSizePixel = 0
        frame.LayoutOrder = order
        frame.Parent = scroll

        local fCorner = Instance.new("UICorner")
        fCorner.CornerRadius = UDim.new(0, 8)
        fCorner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 25)
        label.Position = UDim2.new(0, 5, 0, 3)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. tostring(CONFIG[key])
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -20, 0, 12)
        bar.Position = UDim2.new(0, 10, 0, 35)
        bar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        bar.BorderSizePixel = 0
        bar.Parent = frame

        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(1, 0)
        barCorner.Parent = bar

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((CONFIG[key] - minVal) / (maxVal - minVal), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        fill.BorderSizePixel = 0
        fill.Parent = bar

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill

        local knob = Instance.new("TextButton")
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = UDim2.new((CONFIG[key] - minVal) / (maxVal - minVal), -10, 0.5, -10)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.Text = ""
        knob.Parent = bar

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local dragging = false

        local function updateFromX(x)
            local relX = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = minVal + relX * (maxVal - minVal)
            val = math.floor(val / step + 0.5) * step
            CONFIG[key] = val
            label.Text = text .. ": " .. tostring(val)
            fill.Size = UDim2.new(relX, 0, 1, 0)
            knob.Position = UDim2.new(relX, -10, 0.5, -10)
        end

        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
               or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromX(input.Position.X)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
               or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
               or input.UserInputType == Enum.UserInputType.Touch then
                updateFromX(input.Position.X)
            end
        end)
    end

    -- ============ الأزرار ============
    makeToggle("ESP كامل", "Enabled", 1)
    makeToggle("الإطار الملون", "ShowHighlight", 2)
    makeToggle("الأسماء", "ShowNames", 3)
    makeToggle("المسافات", "ShowDistance", 4)
    makeToggle("الخطوط", "ShowTracers", 5)

    local sep1 = Instance.new("Frame")
    sep1.Size = UDim2.new(1, -8, 0, 2)
    sep1.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    sep1.BorderSizePixel = 0
    sep1.LayoutOrder = 6
    sep1.Parent = scroll

    makeToggle("Aimbot", "AimbotEnabled", 7, function()
        if FOVCircle then
            FOVCircle.Visible = CONFIG.AimbotEnabled and CONFIG.ShowFOVCircle
        end
    end)
    makeToggle("دائرة FOV", "ShowFOVCircle", 8)
    makeToggle("المرئيون فقط", "AimbotVisibleOnly", 9)
    makeSlider("FOV", "AimbotFOV", 30, 500, 10, 10)
    makeSlider("نعومة الحركة", "AimbotSmoothing", 0, 0.9, 0.05, 11)

    -- اختيار الجزء المستهدف
    local partFrame = Instance.new("Frame")
    partFrame.Size = UDim2.new(1, -8, 0, 80)
    partFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    partFrame.BorderSizePixel = 0
    partFrame.LayoutOrder = 12
    partFrame.Parent = scroll

    local pfCorner = Instance.new("UICorner")
    pfCorner.CornerRadius = UDim.new(0, 8)
    pfCorner.Parent = partFrame

    local partLabel = Instance.new("TextLabel")
    partLabel.Size = UDim2.new(1, -10, 0, 25)
    partLabel.Position = UDim2.new(0, 5, 0, 3)
    partLabel.BackgroundTransparency = 1
    partLabel.Text = "الجزء المستهدف: " .. CONFIG.AimbotPart
    partLabel.TextColor3 = Color3.new(1, 1, 1)
    partLabel.Font = Enum.Font.Gotham
    partLabel.TextSize = 13
    partLabel.TextXAlignment = Enum.TextXAlignment.Left
    partLabel.Parent = partFrame

    local parts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
    local partBtns = {}
    for i, p in ipairs(parts) do
        local pBtn = Instance.new("TextButton")
        pBtn.Size = UDim2.new(0.24, 0, 0, 35)
        pBtn.Position = UDim2.new(0.01 + (i-1) * 0.245, 0, 0, 35)
        pBtn.BackgroundColor3 = CONFIG.AimbotPart == p and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(50, 50, 60)
        pBtn.BorderSizePixel = 0
        pBtn.Text = p:gsub("UpperTorso", "صدر").gsub("LowerTorso", "بطن"):gsub("HumanoidRootPart", "جسم"):gsub("Head", "رأس")
        pBtn.TextColor3 = Color3.new(1, 1, 1)
        pBtn.Font = Enum.Font.Gotham
        pBtn.TextSize = 11
        pBtn.Parent = partFrame

        local pbCorner = Instance.new("UICorner")
        pbCorner.CornerRadius = UDim.new(0, 6)
        pbCorner.Parent = pBtn

        partBtns[p] = pBtn

        pBtn.MouseButton1Click:Connect(function()
            CONFIG.AimbotPart = p
            for key, btn in pairs(partBtns) do
                btn.BackgroundColor3 = key == p and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(50, 50, 60)
            end
            partLabel.Text = "الجزء المستهدف: " .. p
        end)
    end

    -- ربط الأزرار الرئيسية
    toggleBtn.MouseButton1Click:Connect(function()
        panel.Visible = not panel.Visible
    end)

    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
    end)

    return screenGui
end

-- ==================== التشغيل ====================
createFOVCircle()
setupAimbotInput()

local ok, err = pcall(createGUI)
if not ok then
    warn("[NoopYT ESP] فشل إنشاء GUI: " .. tostring(err))
end

print("[NoopYT ESP v3] تم التحميل بنجاح")
print("[NoopYT ESP v3] ESP + Aimbot + GUI")
