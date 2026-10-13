-- ============================================================
-- NoopYT Universal ESP
-- متوافق مع: Arceus X Neo / Delta / Fluxus (أندرويد)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ==================== الإعدادات ====================
local CONFIG = {
    Enabled = true,
    ShowNames = true,
    ShowDistance = true,
    HighlightFill = Color3.fromRGB(255, 50, 50),
    HighlightOutline = Color3.fromRGB(255, 255, 255),
    FillTransparency = 0.7,
    OutlineTransparency = 0.2,
    UpdateRate = 0.1,
}

-- ==================== التخزين ====================
local ESPData = {}

-- ==================== دوال مساعدة ====================
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

local function createESP(player)
    if player == LocalPlayer then return end
    if ESPData[player] then return end

    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- 1. Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "NoopYT_ESP_Highlight"
    highlight.FillColor = CONFIG.HighlightFill
    highlight.OutlineColor = CONFIG.HighlightOutline
    highlight.FillTransparency = CONFIG.FillTransparency
    highlight.OutlineTransparency = CONFIG.OutlineTransparency
    highlight.Adornee = character
    highlight.Parent = character

    -- 2. BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NoopYT_ESP_Billboard"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = character
    billboard.Parent = character

    -- اسم اللاعب
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

    -- المسافة
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0.4, 0)
    distLabel.Position = UDim2.new(0, 0, 0.6, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
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

-- ==================== أحداث اللاعبين ====================
local function onCharacterAdded(player, character)
    task.wait(0.5)
    if not CONFIG.Enabled then return end
    if player == LocalPlayer then return end
    cleanupESP(player)
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
end

-- تهيئة اللاعبين الموجودين
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ==================== الحلقة الرئيسية ====================
RunService.Heartbeat:Connect(function(dt)
    if not CONFIG.Enabled then
        for player, _ in pairs(ESPData) do
            cleanupESP(player)
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if not ESPData[player] then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    createESP(player)
                end
            end
        end
    end

    updateDistances(dt)
end)

print("[NoopYT ESP] تم التحميل بنجاح")
print("[NoopYT ESP] الميزات: أسماء + مسافات + إطار ملون")
