-- ============================================================
-- NoopYT Universal v5 — Pro Edition
-- ESP + Aimbot (Auto) + Player List + Pro UI
-- متوافق مع: Arceus X Neo / Delta / Fluxus
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==================== الإعدادات ====================
local CONFIG = {
    ESPEnabled = true,
    ShowNames = true,
    ShowDistance = true,
    ShowHighlight = true,
    ShowTracers = true,
    ShowBox = false,
    TeamCheck = false,

    AimbotEnabled = false,
    AimbotAuto = true,        -- تصويب تلقائي (بدون ضغط زر)
    AimbotFOV = 150,
    AimbotSmoothing = 0.25,
    AimbotPart = "Head",
    AimbotVisibleOnly = false,
    SelectedTarget = nil,      -- اسم لاعب محدد (nil = أقرب هدف)
    ShowFOVCircle = true,

    HighlightFill = Color3.fromRGB(255, 60, 60),
    HighlightOutline = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 60, 60),
    BoxColor = Color3.fromRGB(255, 255, 255),
    FOVColor = Color3.fromRGB(255, 60, 60),
    FillTransparency = 0.7,
    OutlineTransparency = 0.2,
    RefreshRate = 0.5,
}

-- ==================== الألوان الاحترافية ====================
local THEME = {
    Bg = Color3.fromRGB(18, 18, 24),
    Panel = Color3.fromRGB(26, 26, 34),
    Card = Color3.fromRGB(34, 34, 44),
    CardHover = Color3.fromRGB(44, 44, 56),
    Accent = Color3.fromRGB(255, 60, 60),
    Accent2 = Color3.fromRGB(120, 60, 255),
    Text = Color3.fromRGB(240, 240, 245),
    TextDim = Color3.fromRGB(150, 150, 165),
    Success = Color3.fromRGB(60, 220, 130),
    Danger = Color3.fromRGB(255, 70, 70),
    Divider = Color3.fromRGB(45, 45, 58),
}

-- ==================== التخزين ====================
local ESPData = {}
local Tracers = {}
local Boxes = {}
local FOVCircle = nil
local AimbotActive = false
local PlayerListCache = {}

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

-- ==================== تنظيف ====================
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

-- ==================== إنشاء ESP ====================
local function createESP(player)
    if not isValidPlayer(player) then return end
    if isSameTeam(player) then return end
    if ESPData[player] then return end
    if not isValidCharacter(player) then return end

    local char = player.Character
    local ok, err = pcall(function()
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

    if not ok then
        cleanupESP(player)
    end
end

-- ==================== الفحص الشامل ====================
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

-- ==================== مراقبة اللاعبين ====================
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
            h.Died:Connect(function() cleanupESP(player) end)
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
end

for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ==================== التحديثات ====================
local function updateVisuals()
    if not Camera then return end
    local size = Camera.ViewportSize
    local startPt = Vector2.new(size.X / 2, size.Y)

    for player, tracer in pairs(Tracers) do
        if not tracer then continue end
        if not CONFIG.ESPEnabled or not CONFIG.ShowTracers then
            tracer.Visible = false
        else
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local sp, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    tracer.From = startPt
                    tracer.To = Vector2.new(sp.X, sp.Y)
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
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local dist = (Camera.CFrame.Position - root.Position).Magnitude
                    local h = math.clamp(2000 / dist, 20, 400)
                    local w = h * 0.6
                    box.Size = Vector2.new(w, h)
                    box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
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
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local d = (lr.Position - root.Position).Magnitude
                data.DistLabel.Text = string.format("%d", math.floor(d))
                data.DistLabel.Visible = CONFIG.ShowDistance
            end
        end
    end
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

        -- إذا محدد لاعب معين، تجاوز الباقي
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

        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
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

local function performAimbot()
    if not CONFIG.AimbotEnabled then return end
    -- التصويب التلقائي: يعمل دائماً. اليدوي: عند AimbotActive فقط
    if not CONFIG.AimbotAuto and not AimbotActive then return end

    local target = getBestTarget()
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

    refreshAccum = refreshAccum + dt
    if refreshAccum >= CONFIG.RefreshRate then
        refreshAccum = 0
        pcall(fullRefresh)
    end

    updateDistances(dt)
    pcall(updateVisuals)
    pcall(performAimbot)
    updateFOVCircle()
end)

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.MouseButton2 then AimbotActive = true end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then AimbotActive = false end
end)

-- ============================================================
-- ==================== PRO GUI ===============================
-- ============================================================

local function createGUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "NoopYT_v5"
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

    -- ============ الزر العائم ============
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 56, 0, 56)
    btn.Position = UDim2.new(0, 20, 0.5, -28)
    btn.BackgroundColor3 = THEME.Panel
    btn.BorderSizePixel = 0
    btn.Text = "N"
    btn.TextColor3 = THEME.Accent
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Active = true
    btn.Draggable = true
    btn.Parent = sg
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local bStroke = Instance.new("UIStroke", btn)
    bStroke.Color = THEME.Accent
    bStroke.Thickness = 2

    -- ============ اللوحة ============
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 320, 0, 480)
    panel.Position = UDim2.new(0.5, -160, 0.5, -240)
    panel.BackgroundColor3 = THEME.Bg
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Active = true
    panel.Draggable = true
    panel.Parent = sg
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
    local pStroke = Instance.new("UIStroke", panel)
    pStroke.Color = THEME.Accent
    pStroke.Thickness = 1.5
    pStroke.Transparency = 0.3

    -- ============ شريط العنوان ============
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 48)
    header.BackgroundColor3 = THEME.Panel
    header.BorderSizePixel = 0
    header.Parent = panel
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

    -- شعار
    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0, 30, 0, 30)
    logo.Position = UDim2.new(0, 12, 0.5, -15)
    logo.BackgroundColor3 = THEME.Accent
    logo.BorderSizePixel = 0
    logo.Parent = header
    Instance.new("UICorner", logo).CornerRadius = UDim.new(1, 0)

    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.new(1, 0, 1, 0)
    logoText.BackgroundTransparency = 1
    logoText.Text = "N"
    logoText.TextColor3 = Color3.new(1, 1, 1)
    logoText.Font = Enum.Font.GothamBold
    logoText.TextScaled = true
    logoText.Parent = logo

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Position = UDim2.new(0, 50, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "NoopYT"
    title.TextColor3 = THEME.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local subTitle = Instance.new("TextLabel")
    subTitle.Size = UDim2.new(1, -120, 0, 14)
    subTitle.Position = UDim2.new(0, 50, 0, 28)
    subTitle.BackgroundTransparency = 1
    subTitle.Text = "v5 Pro Edition"
    subTitle.TextColor3 = THEME.TextDim
    subTitle.Font = Enum.Font.Gotham
    subTitle.TextSize = 11
    subTitle.TextXAlignment = Enum.TextXAlignment.Left
    subTitle.Parent = header

    -- زر التصغير
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 26, 0, 26)
    minBtn.Position = UDim2.new(1, -66, 0.5, -13)
    minBtn.BackgroundColor3 = THEME.Card
    minBtn.Text = "—"
    minBtn.TextColor3 = THEME.Text
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 14
    minBtn.BorderSizePixel = 0
    minBtn.Parent = header
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

    -- زر الإغلاق
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -34, 0.5, -13)
    closeBtn.BackgroundColor3 = THEME.Danger
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

    -- ============ شريط التبويبات ============
    local tabs = Instance.new("Frame")
    tabs.Size = UDim2.new(1, -20, 0, 36)
    tabs.Position = UDim2.new(0, 10, 0, 56)
    tabs.BackgroundColor3 = THEME.Panel
    tabs.BorderSizePixel = 0
    tabs.Parent = panel
    Instance.new("UICorner", tabs).CornerRadius = UDim.new(0, 8)

    local tabLayout = Instance.new("UIListLayout", tabs)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ============ محتوى التبويبات ============
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -160)
    content.Position = UDim2.new(0, 10, 0, 100)
    content.BackgroundTransparency = 1
    content.Parent = panel

    local pages = {}

    local function makePage(name)
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = THEME.Accent
        page.CanvasSize = UDim2.new(0, 0, 0, 800)
        page.Visible = false
        page.Parent = content

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

    -- أزرار التبويبات
    local tabButtons = {}
    local tabNames = {"ESP", "Aimbot", "Players", "Settings"}
    local tabIcons = {"👁", "🎯", "👥", "⚙"}

    local function selectTab(name)
        for n, p in pairs(pages) do
            p.Visible = (n == name)
        end
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
        tb.Size = UDim2.new(0, 70, 0, 28)
        tb.BackgroundColor3 = THEME.Card
        tb.BorderSizePixel = 0
        tb.Text = tabIcons[i] .. " " .. name
        tb.TextColor3 = THEME.TextDim
        tb.Font = Enum.Font.GothamBold
        tb.TextSize = 11
        tb.LayoutOrder = i
        tb.Parent = tabs
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
        tabButtons[name] = tb

        tb.MouseButton1Click:Connect(function()
            selectTab(name)
        end)
    end

    -- ============ مكونات ============
    local function makeToggle(parent, text, key, order, callback)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -8, 0, 38)
        card.BackgroundColor3 = THEME.Card
        card.BorderSizePixel = 0
        card.LayoutOrder = order
        card.Parent = parent
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -70, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = THEME.Text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = card

        -- المفتاح (Toggle)
        local switch = Instance.new("TextButton")
        switch.Size = UDim2.new(0, 44, 0, 22)
        switch.Position = UDim2.new(1, -56, 0.5, -11)
        switch.BackgroundColor3 = CONFIG[key] and THEME.Success or THEME.Danger
        switch.Text = ""
        switch.BorderSizePixel = 0
        switch.Parent = card
        Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = CONFIG[key] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.Parent = switch
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local function refresh()
            local on = CONFIG[key]
            switch.BackgroundColor3 = on and THEME.Success or THEME.Danger
            TweenService:Create(knob, TweenInfo.new(0.15),
                {Position = on and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}):Play()
            if callback then callback() end
        end

        switch.MouseButton1Click:Connect(function()
            CONFIG[key] = not CONFIG[key]
            refresh()
        end)
        card.MouseButton1Click:Connect(function()
            CONFIG[key] = not CONFIG[key]
            refresh()
        end)

        -- hover
        card.MouseEnter:Connect(function()
            TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = THEME.CardHover}):Play()
        end)
        card.MouseLeave:Connect(function()
            TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Card}):Play()
        end)
    end

    local function makeSlider(parent, text, key, minV, maxV, step, order)
        local fr = Instance.new("Frame")
        fr.Size = UDim2.new(1, -8, 0, 58)
        fr.BackgroundColor3 = THEME.Card
        fr.BorderSizePixel = 0
        fr.LayoutOrder = order
        fr.Parent = parent
        Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 0, 20)
        lbl.Position = UDim2.new(0, 12, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = THEME.Text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = fr

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0, 50, 0, 20)
        valLbl.Position = UDim2.new(1, -56, 0, 4)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = tostring(CONFIG[key])
        valLbl.TextColor3 = THEME.Accent
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 13
        valLbl.Parent = fr

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -24, 0, 8)
        bar.Position = UDim2.new(0, 12, 0, 38)
        bar.BackgroundColor3 = THEME.Bg
        bar.BorderSizePixel = 0
        bar.Parent = fr
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((CONFIG[key] - minV) / (maxV - minV), 0, 1, 0)
        fill.BackgroundColor3 = THEME.Accent
        fill.BorderSizePixel = 0
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("TextButton")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new((CONFIG[key] - minV) / (maxV - minV), -8, 0.5, -8)
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
            valLbl.Text = tostring(v)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -8, 0.5, -8)
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

    local function makeDivider(parent, order)
        local d = Instance.new("Frame")
        d.Size = UDim2.new(1, -8, 0, 1)
        d.BackgroundColor3 = THE
