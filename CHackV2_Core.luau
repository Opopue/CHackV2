local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local CONFIG_PATH = "CHack_config.json"
local PANEL_WIDTH = 520
local CONTENT_HEIGHT = 340
local FPS_UPDATE_INTERVAL = 0.5

local state = {
    esp = false, boxfilled = false, nametags = false, health = false, range = false, skeleton = false,
    fly = false, speed = false, noclip = false,
    god = false, infjump = false, antiafk = false,
    fps = false, freecam = false, invisible = false,
    fov = false, thirdperson = false,
    aimbot = false, silentaim = false, norecoil = false,
    watermark = true,
}

local keys = {
    esp = Enum.KeyCode.Unknown, boxfilled = Enum.KeyCode.Unknown,
    nametags = Enum.KeyCode.Unknown, health = Enum.KeyCode.Unknown,
    range = Enum.KeyCode.Unknown, skeleton = Enum.KeyCode.Unknown,
    fly = Enum.KeyCode.Unknown, speed = Enum.KeyCode.Unknown, noclip = Enum.KeyCode.Unknown,
    god = Enum.KeyCode.Unknown, infjump = Enum.KeyCode.Unknown, antiafk = Enum.KeyCode.Unknown,
    fps = Enum.KeyCode.Unknown, freecam = Enum.KeyCode.Unknown, invisible = Enum.KeyCode.Unknown,
    fov = Enum.KeyCode.Unknown, thirdperson = Enum.KeyCode.Unknown,
    aimbot = Enum.KeyCode.Unknown, silentaim = Enum.KeyCode.Unknown, norecoil = Enum.KeyCode.Unknown,
    watermark = Enum.KeyCode.Unknown,
}

local flySpeed = 50
local speedValue = 50
local espTextSize = 14
local fovValue = 90
local thirdPersonDist = 24
local aimSmoothness = 0.25
local aimTargetHead = true
local aimbotSnap = true

local espBoxColor = Color3.fromRGB(168, 85, 247)
local espSkelColor = Color3.fromRGB(168, 85, 247)

local theme = {
    accent = Color3.fromRGB(192, 132, 252),
    background = Color3.fromRGB(13, 13, 20),
    panel = Color3.fromRGB(26, 15, 46),
    button = Color3.fromRGB(26, 15, 46),
    input = Color3.fromRGB(18, 9, 31),
    text = Color3.fromRGB(192, 132, 252),
    subtext = Color3.fromRGB(124, 95, 160),
    stroke = Color3.fromRGB(108, 63, 197),
    strokeDim = Color3.fromRGB(59, 31, 110),
    action = Color3.fromRGB(40, 10, 80),
    hint = Color3.fromRGB(90, 58, 122),
    tabInactive = Color3.fromRGB(20, 10, 35),
    tabActive = Color3.fromRGB(40, 10, 80),
}

local themedElements = { buttons = {}, inputs = {}, strokes = {}, labels = {}, tabs = {} }

local espTable = {}
local bodyVel, bodyGyro
local bindingKey = nil
local lastTime = tick()
local freecamPart = nil
local freecamYaw, freecamPitch = 0, 0
local freecamSpeed = 0.5
local antiafkConn = nil
local silentAimHooked = false
local noRecoilLastCF = nil
local defaultFov = 70
local defaultCamMin, defaultCamMax = 0.5, 400

local displayedFps = "0"
local fpsSum, fpsCount = 0, 0
local lastFpsRefresh = tick()

local R15_BONES = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
}
local R6_BONES = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local gui = Instance.new("ScreenGui")
gui.Name = "CHack"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local fpsLabel = Drawing.new("Text")
fpsLabel.Visible = false
fpsLabel.Color = theme.accent
fpsLabel.Size = 16
fpsLabel.Outline = true
fpsLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
fpsLabel.Position = Vector2.new(1000, 10)

local watermarkLabel = Drawing.new("Text")
watermarkLabel.Visible = true
watermarkLabel.Color = theme.accent
watermarkLabel.Size = 14
watermarkLabel.Outline = true
watermarkLabel.OutlineColor = Color3.fromRGB(0, 0, 0)

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, PANEL_WIDTH, 0, 0)
panel.Position = UDim2.new(0.5, -PANEL_WIDTH / 2, 0.5, -240)
panel.BackgroundColor3 = theme.background
panel.BorderSizePixel = 0
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = theme.stroke
panelStroke.Thickness = 1
table.insert(themedElements.strokes, panelStroke)

local dragging, dragStart, startPos
panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)
panel.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

Instance.new("UIListLayout", panel).Padding = UDim.new(0, 0)

local header = Instance.new("Frame", panel)
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = theme.panel
header.BorderSizePixel = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)
table.insert(themedElements.buttons, header)

local logo = Instance.new("TextLabel", header)
logo.Size = UDim2.new(1, 0, 1, 0)
logo.Position = UDim2.new(0, 14, 0, 0)
logo.BackgroundTransparency = 1
logo.TextColor3 = theme.accent
logo.Text = "CHack"
logo.Font = Enum.Font.GothamBold
logo.TextSize = 14
logo.TextXAlignment = Enum.TextXAlignment.Left
table.insert(themedElements.labels, logo)

local tabBar = Instance.new("Frame", panel)
tabBar.Size = UDim2.new(1, 0, 0, 30)
tabBar.BackgroundTransparency = 1
local tabBarLayout = Instance.new("UIListLayout", tabBar)
tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
tabBarLayout.Padding = UDim.new(0, 4)
local tabPad = Instance.new("UIPadding", tabBar)
tabPad.PaddingLeft = UDim.new(0, 8)
tabPad.PaddingRight = UDim.new(0, 8)

local contentArea = Instance.new("Frame", panel)
contentArea.Size = UDim2.new(1, 0, 0, CONTENT_HEIGHT)
contentArea.BackgroundTransparency = 1
contentArea.ClipsDescendants = true

local hint = Instance.new("TextLabel", panel)
hint.Size = UDim2.new(1, 0, 0, 22)
hint.BackgroundTransparency = 1
hint.Text = "RShift Oeffnen | Taste druecken zum Belegen"
hint.Font = Enum.Font.Gotham
hint.TextSize = 9
hint.TextColor3 = theme.hint
table.insert(themedElements.labels, hint)

local pages = {}
local tabButtons = {}
local activeTab = "Visuals"
local TAB_NAMES = {"Visuals", "Combat", "Movement", "Camera", "Misc", "Utility"}

local function colorToString(c)
    return string.format("%d,%d,%d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function parseColor(str, fallback)
    if not str then return fallback end
    local r, g, b = str:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
    if r then
        return Color3.fromRGB(math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255))
    end
    return fallback
end

local function applyTheme()
    panel.BackgroundColor3 = theme.background
    header.BackgroundColor3 = theme.panel
    panelStroke.Color = theme.stroke
    logo.TextColor3 = theme.accent
    hint.TextColor3 = theme.hint
    fpsLabel.Color = theme.accent
    watermarkLabel.Color = theme.accent
    for _, btn in ipairs(themedElements.buttons) do
        if btn:IsA("TextButton") then
            if btn:GetAttribute("IsTab") then
                btn.BackgroundColor3 = btn:GetAttribute("TabName") == activeTab and theme.tabActive or theme.tabInactive
            elseif btn:GetAttribute("IsAction") then
                btn.BackgroundColor3 = theme.action
                btn.TextColor3 = theme.text
            else
                btn.BackgroundColor3 = theme.button
            end
        elseif btn:IsA("Frame") then
            btn.BackgroundColor3 = theme.panel
        end
    end
    for _, box in ipairs(themedElements.inputs) do
        box.BackgroundColor3 = theme.input
        box.TextColor3 = theme.text
    end
    for _, stroke in ipairs(themedElements.strokes) do
        if stroke.Parent and stroke.Parent:GetAttribute("IsTab") then
            stroke.Color = stroke.Parent:GetAttribute("TabName") == activeTab and theme.accent or theme.strokeDim
        else
            stroke.Color = theme.strokeDim
        end
    end
    for _, lbl in ipairs(themedElements.labels) do
        if lbl:GetAttribute("IsSection") then
            lbl.TextColor3 = theme.subtext
        else
            lbl.TextColor3 = theme.text
        end
    end
end

local function switchTab(name)
    activeTab = name
    for tabName, page in pairs(pages) do
        page.Visible = tabName == name
    end
    for tabName, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = tabName == name and theme.tabActive or theme.tabInactive
        local st = btn:FindFirstChildOfClass("UIStroke")
        if st then st.Color = tabName == name and theme.accent or theme.strokeDim end
    end
end

local function createPage(name)
    local page = Instance.new("ScrollingFrame", contentArea)
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 4)
    local pad = Instance.new("UIPadding", page)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 6)
    pages[name] = page
    return page
end

for _, name in ipairs(TAB_NAMES) do
    createPage(name)
    local tabBtn = Instance.new("TextButton", tabBar)
    tabBtn.Size = UDim2.new(0, 78, 1, 0)
    tabBtn.BackgroundColor3 = theme.tabInactive
    tabBtn.BorderSizePixel = 0
    tabBtn.AutoButtonColor = false
    tabBtn.Text = name
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 9
    tabBtn.TextColor3 = theme.text
    tabBtn:SetAttribute("IsTab", true)
    tabBtn:SetAttribute("TabName", name)
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)
    local tabStroke = Instance.new("UIStroke", tabBtn)
    tabStroke.Color = theme.strokeDim
    tabStroke.Thickness = 1
    table.insert(themedElements.strokes, tabStroke)
    table.insert(themedElements.buttons, tabBtn)
    tabButtons[name] = tabBtn
    tabBtn.MouseButton1Click:Connect(function() switchTab(name) end)
end
switchTab("Visuals")

local function makeSection(name, parent)
    local title = Instance.new("TextLabel", parent)
    title.Size = UDim2.new(1, 0, 0, 16)
    title.BackgroundTransparency = 1
    title.TextColor3 = theme.subtext
    title.Text = name
    title.Font = Enum.Font.GothamBold
    title.TextSize = 10
    title.TextXAlignment = Enum.TextXAlignment.Left
    title:SetAttribute("IsSection", true)
    table.insert(themedElements.labels, title)
end

local function setOn(badge, stroke, on)
    if on then
        badge.Text = "ON"
        badge.BackgroundColor3 = Color3.fromRGB(26, 61, 26)
        badge.TextColor3 = Color3.fromRGB(74, 222, 128)
        stroke.Color = Color3.fromRGB(74, 222, 128)
    else
        badge.Text = "OFF"
        badge.BackgroundColor3 = Color3.fromRGB(45, 16, 96)
        badge.TextColor3 = Color3.fromRGB(168, 85, 247)
        stroke.Color = theme.strokeDim
    end
end

local function makeBtn(text, parent, stateKey)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    local rowL = Instance.new("UIListLayout", row)
    rowL.FillDirection = Enum.FillDirection.Horizontal
    rowL.Padding = UDim.new(0, 4)
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1, -70, 1, 0)
    btn.BackgroundColor3 = theme.button
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = theme.strokeDim
    stroke.Thickness = 1
    table.insert(themedElements.strokes, stroke)
    table.insert(themedElements.buttons, btn)
    local label = Instance.new("TextLabel", btn)
    label.Size = UDim2.new(1, -44, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextColor3 = theme.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    table.insert(themedElements.labels, label)
    local badge = Instance.new("TextLabel", btn)
    badge.Size = UDim2.new(0, 32, 0, 16)
    badge.Position = UDim2.new(1, -36, 0.5, -8)
    badge.BackgroundColor3 = Color3.fromRGB(45, 16, 96)
    badge.Text = "OFF"
    badge.Font = Enum.Font.GothamBold
    badge.TextSize = 9
    badge.TextColor3 = Color3.fromRGB(168, 85, 247)
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)
    local keyBtn = Instance.new("TextButton", row)
    keyBtn.Size = UDim2.new(0, 62, 1, 0)
    keyBtn.BackgroundColor3 = theme.tabInactive
    keyBtn.BorderSizePixel = 0
    keyBtn.AutoButtonColor = false
    keyBtn.Text = "---"
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 10
    keyBtn.TextColor3 = Color3.fromRGB(150, 100, 220)
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 7)
    local keyStroke = Instance.new("UIStroke", keyBtn)
    keyStroke.Color = theme.strokeDim
    keyStroke.Thickness = 1
    table.insert(themedElements.strokes, keyStroke)
    table.insert(themedElements.buttons, keyBtn)
    keyBtn.MouseButton1Click:Connect(function()
        bindingKey = stateKey
        keyBtn.Text = "..."
        keyBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
    end)
    return btn, badge, stroke, keyBtn
end

local function makeInput(placeholder, parent, defaultText)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(1, 0, 0, 26)
    box.BackgroundColor3 = theme.input
    box.BorderSizePixel = 0
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = theme.hint
    box.Text = defaultText or ""
    box.Font = Enum.Font.Gotham
    box.TextSize = 11
    box.TextColor3 = theme.text
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)
    local st = Instance.new("UIStroke", box)
    st.Color = theme.strokeDim
    table.insert(themedElements.strokes, st)
    table.insert(themedElements.inputs, box)
    return box
end

local function makeActionBtn(text, parent, callback, widthScale)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(widthScale or 0.5, -2, 0, 26)
    btn.BackgroundColor3 = theme.action
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = theme.text
    btn:SetAttribute("IsAction", true)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local st = Instance.new("UIStroke", btn)
    st.Color = theme.stroke
    table.insert(themedElements.strokes, st)
    table.insert(themedElements.buttons, btn)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function makeFullBtn(text, parent, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.BackgroundColor3 = theme.action
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = theme.text
    btn:SetAttribute("IsAction", true)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local st = Instance.new("UIStroke", btn)
    st.Color = theme.stroke
    table.insert(themedElements.strokes, st)
    table.insert(themedElements.buttons, btn)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- VISUALS
local pgVisuals = pages.Visuals
makeSection("ESP", pgVisuals)
local btnESP, badgeESP, strokeESP, keyESP = makeBtn("Box ESP", pgVisuals, "esp")
local btnFill, badgeFill, strokeFill, keyFill = makeBtn("Filled Box", pgVisuals, "boxfilled")
local btnNames, badgeNames, strokeNames, keyNames = makeBtn("Nametags", pgVisuals, "nametags")
local btnHealth, badgeHealth, strokeHealth, keyHealth = makeBtn("Healthbar", pgVisuals, "health")
local btnRange, badgeRange, strokeRange, keyRange = makeBtn("Distance", pgVisuals, "range")
local btnSkel, badgeSkel, strokeSkel, keySkel = makeBtn("Skeleton ESP", pgVisuals, "skeleton")
local espTextBox = makeInput("ESP Text Size (8-24)", pgVisuals, tostring(espTextSize))
local boxColorBox = makeInput("Box Farbe R,G,B", pgVisuals, colorToString(espBoxColor))
local skelColorBox = makeInput("Skeleton Farbe R,G,B", pgVisuals, colorToString(espSkelColor))
makeSection("Overlay", pgVisuals)
local btnFPS, badgeFPS, strokeFPS, keyFPSBtn = makeBtn("FPS Counter", pgVisuals, "fps")
local btnWM, badgeWM, strokeWM, keyWM = makeBtn("Watermark", pgVisuals, "watermark")

-- COMBAT
local pgCombat = pages.Combat
makeSection("Aim", pgCombat)
local btnAim, badgeAim, strokeAim, keyAim = makeBtn("Aimbot", pgCombat, "aimbot")
local btnSilent, badgeSilent, strokeSilent, keySilent = makeBtn("Silent Aim", pgCombat, "silentaim")
local btnRecoil, badgeRecoil, strokeRecoil, keyRecoil = makeBtn("No Recoil", pgCombat, "norecoil")
local combatRow = Instance.new("Frame", pgCombat)
combatRow.Size = UDim2.new(1, 0, 0, 26)
combatRow.BackgroundTransparency = 1
local combatRowLayout = Instance.new("UIListLayout", combatRow)
combatRowLayout.FillDirection = Enum.FillDirection.Horizontal
combatRowLayout.Padding = UDim.new(0, 4)
local aimModeBtn = makeActionBtn("Mode: Snap", combatRow, function() end)
local aimTargetBtn = makeActionBtn("Ziel: Kopf", combatRow, function() end)
local aimSmoothBox = makeInput("Smooth (0.05-0.9)", pgCombat, tostring(aimSmoothness))

-- MOVEMENT
local pgMove = pages.Movement
makeSection("Bewegung", pgMove)
local btnFly, badgeFly, strokeFly, keyFly = makeBtn("Fly", pgMove, "fly")
local flySpeedBox = makeInput("Fly Speed", pgMove, tostring(flySpeed))
local btnSpeed, badgeSpeed, strokeSpeed, keySpeed = makeBtn("Speed Boost", pgMove, "speed")
local speedBox = makeInput("Walk Speed (16-500)", pgMove, tostring(speedValue))
local btnNoclip, badgeNoclip, strokeNoclip, keyNoclip = makeBtn("No Clip", pgMove, "noclip")

-- CAMERA
local pgCamera = pages.Camera
makeSection("Kamera", pgCamera)
local btnFreecam, badgeFreecam, strokeFreecam, keyFreecam = makeBtn("Freecam", pgCamera, "freecam")
local btnFOV, badgeFOV, strokeFOV, keyFOV = makeBtn("FOV Changer", pgCamera, "fov")
local fovBox = makeInput("FOV Wert (70-120)", pgCamera, tostring(fovValue))
local btnTPDist, badgeTPDist, strokeTPDist, keyTPDist = makeBtn("Third Person", pgCamera, "thirdperson")
local tpDistBox = makeInput("Kamera Distanz (5-100)", pgCamera, tostring(thirdPersonDist))

-- MISC
local pgMisc = pages.Misc
makeSection("Spieler", pgMisc)
local btnGod, badgeGod, strokeGod, keyGod = makeBtn("God Mode", pgMisc, "god")
local btnJump, badgeJump, strokeJump, keyJump = makeBtn("Infinite Jump", pgMisc, "infjump")
local btnInvis, badgeInvis, strokeInvis, keyInvis = makeBtn("Invisible", pgMisc, "invisible")
local btnAFK, badgeAFK, strokeAFK, keyAFK = makeBtn("Anti-AFK", pgMisc, "antiafk")
makeSection("Teleport", pgMisc)
local tpNameBox = makeInput("Spielername", pgMisc, "")
local tpBtn = makeFullBtn("Teleport zu Spieler", pgMisc, function() end)
local coordBox = makeInput("X,Y,Z (z.B. 0,50,0)", pgMisc, "")
local tpCoordsBtn = makeFullBtn("Teleport zu Koordinaten", pgMisc, function() end)

-- UTILITY
local pgUtil = pages.Utility
makeSection("Config", pgUtil)
local cfgRow = Instance.new("Frame", pgUtil)
cfgRow.Size = UDim2.new(1, 0, 0, 26)
cfgRow.BackgroundTransparency = 1
local cfgRowLayout = Instance.new("UIListLayout", cfgRow)
cfgRowLayout.FillDirection = Enum.FillDirection.Horizontal
cfgRowLayout.Padding = UDim.new(0, 4)
local saveBtn = makeActionBtn("Save Config", cfgRow, function() end)
local loadBtn = makeActionBtn("Load Config", cfgRow, function() end)
makeSection("UI Theme", pgUtil)
local accentColorBox = makeInput("Accent R,G,B", pgUtil, colorToString(theme.accent))
local bgColorBox = makeInput("Background R,G,B", pgUtil, colorToString(theme.background))
local panelColorBox = makeInput("Panel R,G,B", pgUtil, colorToString(theme.panel))
local textColorBox = makeInput("Text R,G,B", pgUtil, colorToString(theme.text))
local strokeColorBox = makeInput("Stroke R,G,B", pgUtil, colorToString(theme.stroke))
local applyThemeBtn = makeFullBtn("Theme anwenden", pgUtil, function() end)

local badges = {
    esp = badgeESP, boxfilled = badgeFill, nametags = badgeNames, health = badgeHealth,
    range = badgeRange, skeleton = badgeSkel, fly = badgeFly, speed = badgeSpeed,
    noclip = badgeNoclip, god = badgeGod, infjump = badgeJump, antiafk = badgeAFK,
    fps = badgeFPS, freecam = badgeFreecam, invisible = badgeInvis, fov = badgeFOV,
    thirdperson = badgeTPDist, aimbot = badgeAim, silentaim = badgeSilent,
    norecoil = badgeRecoil, watermark = badgeWM,
}
local strokes = {
    esp = strokeESP, boxfilled = strokeFill, nametags = strokeNames, health = strokeHealth,
    range = strokeRange, skeleton = strokeSkel, fly = strokeFly, speed = strokeSpeed,
    noclip = strokeNoclip, god = strokeGod, infjump = strokeJump, antiafk = strokeAFK,
    fps = strokeFPS, freecam = strokeFreecam, invisible = strokeInvis, fov = strokeFOV,
    thirdperson = strokeTPDist, aimbot = strokeAim, silentaim = strokeSilent,
    norecoil = strokeRecoil, watermark = strokeWM,
}
local keyBtns = {
    esp = keyESP, boxfilled = keyFill, nametags = keyNames, health = keyHealth,
    range = keyRange, skeleton = keySkel, fly = keyFly, speed = keySpeed,
    noclip = keyNoclip, god = keyGod, infjump = keyJump, antiafk = keyAFK,
    fps = keyFPSBtn, freecam = keyFreecam, invisible = keyInvis, fov = keyFOV,
    thirdperson = keyTPDist, aimbot = keyAim, silentaim = keySilent,
    norecoil = keyRecoil, watermark = keyWM,
}


-- Globale Exports fuer Logic
_G.CH = {
    state = state, keys = keys, badges = badges, strokes = strokes, keyBtns = keyBtns,
    espTable = espTable, theme = theme, themedElements = themedElements,
    pages = pages, tabButtons = tabButtons,
    panel = panel, Camera = Camera, Players = Players, LocalPlayer = LocalPlayer,
    UIS = UIS, RunService = RunService, HttpService = HttpService,
    fpsLabel = fpsLabel, watermarkLabel = watermarkLabel,
    flySpeed = flySpeed, speedValue = speedValue, espTextSize = espTextSize,
    fovValue = fovValue, thirdPersonDist = thirdPersonDist,
    aimSmoothness = aimSmoothness, aimTargetHead = aimTargetHead, aimbotSnap = aimbotSnap,
    espBoxColor = espBoxColor, espSkelColor = espSkelColor,
    bodyVel = bodyVel, bodyGyro = bodyGyro, freecamPart = freecamPart,
    freecamYaw = freecamYaw, freecamPitch = freecamPitch, freecamSpeed = freecamSpeed,
    bindingKey = bindingKey, lastTime = lastTime, activeTab = activeTab,
    displayedFps = displayedFps, fpsSum = fpsSum, fpsCount = fpsCount,
    lastFpsRefresh = lastFpsRefresh, antiafkConn = antiafkConn,
    silentAimHooked = silentAimHooked, noRecoilLastCF = noRecoilLastCF,
    defaultFov = defaultFov, defaultCamMin = defaultCamMin, defaultCamMax = defaultCamMax,
    FPS_UPDATE_INTERVAL = FPS_UPDATE_INTERVAL, CONFIG_PATH = CONFIG_PATH,
    R15_BONES = R15_BONES, R6_BONES = R6_BONES,
    setOn = setOn, applyTheme = applyTheme, switchTab = switchTab,
    colorToString = colorToString, parseColor = parseColor,
    -- UI Inputs
    flySpeedBox = flySpeedBox, speedBox = speedBox, espTextBox = espTextBox,
    boxColorBox = boxColorBox, skelColorBox = skelColorBox,
    fovBox = fovBox, tpDistBox = tpDistBox, aimSmoothBox = aimSmoothBox,
    tpNameBox = tpNameBox, coordBox = coordBox,
    accentColorBox = accentColorBox, bgColorBox = bgColorBox,
    panelColorBox = panelColorBox, textColorBox = textColorBox, strokeColorBox = strokeColorBox,
    aimModeBtn = aimModeBtn, aimTargetBtn = aimTargetBtn,
    saveBtn = saveBtn, loadBtn = loadBtn, applyThemeBtn = applyThemeBtn,
}
