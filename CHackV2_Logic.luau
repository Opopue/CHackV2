local ch = _G.CH
local state = ch.state
local keys = ch.keys
local badges = ch.badges
local strokes = ch.strokes
local keyBtns = ch.keyBtns
local espTable = ch.espTable
local theme = ch.theme
local themedElements = ch.themedElements
local panel = ch.panel
local Camera = ch.Camera
local Players = ch.Players
local LocalPlayer = ch.LocalPlayer
local UIS = ch.UIS
local RunService = ch.RunService
local HttpService = ch.HttpService
local fpsLabel = ch.fpsLabel
local watermarkLabel = ch.watermarkLabel
local flySpeedBox = ch.flySpeedBox
local speedBox = ch.speedBox
local espTextBox = ch.espTextBox
local boxColorBox = ch.boxColorBox
local skelColorBox = ch.skelColorBox
local fovBox = ch.fovBox
local tpDistBox = ch.tpDistBox
local aimSmoothBox = ch.aimSmoothBox
local tpNameBox = ch.tpNameBox
local coordBox = ch.coordBox
local accentColorBox = ch.accentColorBox
local bgColorBox = ch.bgColorBox
local panelColorBox = ch.panelColorBox
local textColorBox = ch.textColorBox
local strokeColorBox = ch.strokeColorBox
local aimModeBtn = ch.aimModeBtn
local aimTargetBtn = ch.aimTargetBtn
local saveBtn = ch.saveBtn
local loadBtn = ch.loadBtn
local applyThemeBtn = ch.applyThemeBtn
local setOn = ch.setOn
local applyTheme = ch.applyTheme
local colorToString = ch.colorToString
local parseColor = ch.parseColor
local flySpeed = ch.flySpeed
local speedValue = ch.speedValue
local espTextSize = ch.espTextSize
local fovValue = ch.fovValue
local thirdPersonDist = ch.thirdPersonDist
local aimSmoothness = ch.aimSmoothness
local aimTargetHead = ch.aimTargetHead
local aimbotSnap = ch.aimbotSnap
local espBoxColor = ch.espBoxColor
local espSkelColor = ch.espSkelColor
local bodyVel = ch.bodyVel
local bodyGyro = ch.bodyGyro
local freecamPart = ch.freecamPart
local freecamYaw = ch.freecamYaw
local freecamPitch = ch.freecamPitch
local freecamSpeed = ch.freecamSpeed
local bindingKey = ch.bindingKey
local lastTime = ch.lastTime
local displayedFps = ch.displayedFps
local fpsSum = ch.fpsSum
local fpsCount = ch.fpsCount
local lastFpsRefresh = ch.lastFpsRefresh
local antiafkConn = ch.antiafkConn
local silentAimHooked = ch.silentAimHooked
local noRecoilLastCF = ch.noRecoilLastCF
local defaultFov = ch.defaultFov
local defaultCamMin = ch.defaultCamMin
local defaultCamMax = ch.defaultCamMax
local FPS_UPDATE_INTERVAL = ch.FPS_UPDATE_INTERVAL
local CONFIG_PATH = ch.CONFIG_PATH
local R15_BONES = ch.R15_BONES
local R6_BONES = ch.R6_BONES
local silentAimTarget = nil

local function getBoneList(char)
    if char:FindFirstChild("UpperTorso") then return R15_BONES end
    return R6_BONES
end

local function getCharacterBounds(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not head then return nil end

    local topY = head.Position.Y + head.Size.Y * 0.5
    local foot = char:FindFirstChild("LeftFoot") or char:FindFirstChild("RightFoot")
        or char:FindFirstChild("Left Leg") or char:FindFirstChild("Right Leg")
    local bottomY
    if foot then
        bottomY = foot.Position.Y - foot.Size.Y * 0.5
    else
        local hip = hum and hum.HipHeight or 2
        bottomY = hrp.Position.Y - hrp.Size.Y * 0.5 - hip
    end

    local leftPart = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")
        or char:FindFirstChild("LeftUpperArm")
    local rightPart = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
        or char:FindFirstChild("RightUpperArm")
    local halfWidth = 1.2
    if leftPart and rightPart then
        halfWidth = math.max(halfWidth, (leftPart.Position - rightPart.Position).Magnitude * 0.5 + 0.3)
    end

    local topWorld = Vector3.new(hrp.Position.X, topY, hrp.Position.Z)
    local botWorld = Vector3.new(hrp.Position.X, bottomY, hrp.Position.Z)
    local leftWorld = hrp.Position - hrp.CFrame.RightVector * halfWidth
    local rightWorld = hrp.Position + hrp.CFrame.RightVector * halfWidth

    local topS, topVis = Camera:WorldToViewportPoint(topWorld)
    local botS, botVis = Camera:WorldToViewportPoint(botWorld)
    local leftS = Camera:WorldToViewportPoint(leftWorld)
    local rightS = Camera:WorldToViewportPoint(rightWorld)

    if not topVis and not botVis then return nil end

    local minX = math.min(topS.X, botS.X, leftS.X, rightS.X)
    local maxX = math.max(topS.X, botS.X, leftS.X, rightS.X)
    local minY = math.min(topS.Y, botS.Y)
    local maxY = math.max(topS.Y, botS.Y)

    return {
        x = minX, y = minY,
        w = math.max(maxX - minX, 4),
        h = math.max(maxY - minY, 8),
        cx = (minX + maxX) * 0.5,
        valid = true,
    }
end

local function createEntry(p)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = espBoxColor
    box.Thickness = 2
    box.Filled = false
    local boxFill = Drawing.new("Square")
    boxFill.Visible = false
    boxFill.Color = espBoxColor
    boxFill.Filled = true
    boxFill.Transparency = 0.65
    local tag = Drawing.new("Text")
    tag.Visible = false
    tag.Color = Color3.fromRGB(255, 255, 255)
    tag.Size = espTextSize
    tag.Center = true
    tag.Outline = true
    tag.OutlineColor = Color3.fromRGB(0, 0, 0)
    tag.Text = p.Name
    local skeletonLines = {}
    for i = 1, 15 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = espSkelColor
        line.Thickness = 1.5
        skeletonLines[i] = line
    end
    espTable[p] = { box = box, boxFill = boxFill, tag = tag, skeletonLines = skeletonLines }
end

local function removeEntry(p)
    local data = espTable[p]
    if not data then return end
    data.box:Remove()
    data.boxFill:Remove()
    data.tag:Remove()
    if data.hpBg then data.hpBg:Remove() end
    if data.hpBar then data.hpBar:Remove() end
    if data.distLabel then data.distLabel:Remove() end
    for _, line in ipairs(data.skeletonLines) do line:Remove() end
    espTable[p] = nil
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then createEntry(p) end
end
Players.PlayerAdded:Connect(createEntry)
Players.PlayerRemoving:Connect(removeEntry)

local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    char.Humanoid.PlatformStand = true
    bodyVel = Instance.new("BodyVelocity", root)
    bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVel.Velocity = Vector3.zero
    bodyGyro = Instance.new("BodyGyro", root)
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro.CFrame = root.CFrame
end

local function stopFly()
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then char.Humanoid.PlatformStand = false end
    if bodyVel then bodyVel:Destroy() bodyVel = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
end

local function startFreecam()
    freecamPart = Instance.new("Part", workspace)
    freecamPart.Anchored = true
    freecamPart.CanCollide = false
    freecamPart.Transparency = 1
    freecamPart.Size = Vector3.new(1, 1, 1)
    freecamPart.CFrame = Camera.CFrame
    freecamYaw, freecamPitch = 0, 0
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.Anchored = true end
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = freecamPart.CFrame
    UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
end

local function stopFreecam()
    Camera.CameraType = Enum.CameraType.Custom
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.Anchored = false end
    if freecamPart then freecamPart:Destroy() freecamPart = nil end
    UIS.MouseBehavior = Enum.MouseBehavior.Default
end

local function setInvisible(on)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.LocalTransparencyModifier = on and 1 or 0
        end
    end
end

local function applyFOV()
    Camera.FieldOfView = state.fov and fovValue or defaultFov
end

local function applyThirdPerson()
    if state.thirdperson then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMinZoomDistance = math.max(5, thirdPersonDist * 0.5)
        LocalPlayer.CameraMaxZoomDistance = thirdPersonDist
    else
        LocalPlayer.CameraMinZoomDistance = defaultCamMin
        LocalPlayer.CameraMaxZoomDistance = defaultCamMax
    end
end

local function getAimPart(char)
    if not char then return nil end
    if aimTargetHead then
        return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function getNearestTarget()
    local bestPart, bestScore = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local part = getAimPart(char)
            if hum and hum.Health > 0 and part then
                local dir = (part.Position - Camera.CFrame.Position).Unit
                local angle = math.acos(math.clamp(Camera.CFrame.LookVector:Dot(dir), -1, 1))
                local dist = (part.Position - Camera.CFrame.Position).Magnitude
                local score = angle + dist * 0.001
                if score < bestScore then bestScore = score bestPart = part end
            end
        end
    end
    return bestPart
end

local silentAimTarget = nil

local function setupSilentAim()
    if silentAimHooked then return end
    pcall(function()
        if not getrawmetatable then return end
        local Mouse = LocalPlayer:GetMouse()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local oldIndex = mt.__index
        local function hookIndex(self, key)
            if state.silentaim and silentAimTarget and checkcaller and not checkcaller() then
                if self == Mouse and (key == "Hit" or key == "Target") then
                    return CFrame.new(silentAimTarget.Position)
                end
            end
            return oldIndex(self, key)
        end
        mt.__index = newcclosure and newcclosure(hookIndex) or hookIndex
        setreadonly(mt, true)
        silentAimHooked = true
    end)
end

local function updateAimbot()
    if not state.aimbot or state.freecam then return end
    local target = getNearestTarget()
    if not target then return end
    local goal = CFrame.new(Camera.CFrame.Position, target.Position)
    Camera.CFrame = aimbotSnap and goal or Camera.CFrame:Lerp(goal, aimSmoothness)
end

local function updateSilentAim()
    silentAimTarget = state.silentaim and getNearestTarget() or nil
    if state.silentaim then setupSilentAim() end
end

local function updateNoRecoil()
    if not state.norecoil or state.freecam then
        noRecoilLastCF = Camera.CFrame
        return
    end
    if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        if noRecoilLastCF then
            local pos = Camera.CFrame.Position
            Camera.CFrame = CFrame.new(pos, noRecoilLastCF.LookVector + pos)
        end
    else
        noRecoilLastCF = Camera.CFrame
    end
end

local function refreshFpsDisplay(delta)
    if delta > 0 then
        fpsSum += 1 / delta
        fpsCount += 1
    end
    local now = tick()
    if now - lastFpsRefresh >= FPS_UPDATE_INTERVAL then
        if fpsCount > 0 then
            displayedFps = tostring(math.floor(fpsSum / fpsCount))
        end
        fpsSum, fpsCount = 0, 0
        lastFpsRefresh = now
    end
end

local function updateWatermark()
    if not state.watermark then
        watermarkLabel.Visible = false
        return
    end
    watermarkLabel.Visible = true
    watermarkLabel.Text = "CHack loaded | " .. displayedFps .. " FPS"
    local tw = watermarkLabel.TextBounds and watermarkLabel.TextBounds.X or (#watermarkLabel.Text * 7)
    local vps = Camera.ViewportSize
    watermarkLabel.Position = Vector2.new(vps.X - tw - 10, vps.Y - 24)
end

local function keyToString(keyCode)
    return keyCode == Enum.KeyCode.Unknown and "Unknown" or keyCode.Name
end

local function stringToKey(name)
    if not name or name == "Unknown" then return Enum.KeyCode.Unknown end
    return Enum.KeyCode[name] or Enum.KeyCode.Unknown
end

local function applyThemeFromInputs()
    theme.accent = parseColor(accentColorBox.Text, theme.accent)
    theme.background = parseColor(bgColorBox.Text, theme.background)
    theme.panel = parseColor(panelColorBox.Text, theme.panel)
    theme.text = parseColor(textColorBox.Text, theme.text)
    theme.stroke = parseColor(strokeColorBox.Text, theme.stroke)
    theme.button = theme.panel
    theme.input = Color3.new(theme.background.R * 0.85, theme.background.G * 0.85, theme.background.B * 0.85)
    theme.tabInactive = theme.input
    theme.tabActive = theme.action
    applyTheme()
end

local function saveConfig()
    if not writefile then warn("[CHack] writefile nicht verfuegbar") return end
    local keyData = {}
    for name, keyCode in pairs(keys) do keyData[name] = keyToString(keyCode) end
    local data = {
        state = state, keys = keyData,
        flySpeed = flySpeed, speedValue = speedValue, espTextSize = espTextSize,
        fovValue = fovValue, thirdPersonDist = thirdPersonDist,
        aimSmoothness = aimSmoothness, aimTargetHead = aimTargetHead, aimbotSnap = aimbotSnap,
        espBoxColor = colorToString(espBoxColor), espSkelColor = colorToString(espSkelColor),
        theme = {
            accent = colorToString(theme.accent), background = colorToString(theme.background),
            panel = colorToString(theme.panel), text = colorToString(theme.text),
            stroke = colorToString(theme.stroke),
        },
    }
    local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
    if ok then writefile(CONFIG_PATH, json) print("[CHack] Config gespeichert") end
end

local toggle

local function loadConfig()
    if not readfile or not isfile or not isfile(CONFIG_PATH) then
        warn("[CHack] Keine Config gefunden") return
    end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_PATH)) end)
    if not ok or not data then return end
    if data.flySpeed then flySpeed = data.flySpeed flySpeedBox.Text = tostring(flySpeed) end
    if data.speedValue then speedValue = data.speedValue speedBox.Text = tostring(speedValue) end
    if data.espTextSize then espTextSize = math.clamp(data.espTextSize, 8, 24) espTextBox.Text = tostring(espTextSize) end
    if data.fovValue then fovValue = data.fovValue fovBox.Text = tostring(fovValue) end
    if data.thirdPersonDist then thirdPersonDist = data.thirdPersonDist tpDistBox.Text = tostring(thirdPersonDist) end
    if data.aimSmoothness then aimSmoothness = data.aimSmoothness aimSmoothBox.Text = tostring(aimSmoothness) end
    if data.aimTargetHead ~= nil then
        aimTargetHead = data.aimTargetHead
        aimTargetBtn.Text = aimTargetHead and "Ziel: Kopf" or "Ziel: Koerper"
    end
    if data.aimbotSnap ~= nil then
        aimbotSnap = data.aimbotSnap
        aimModeBtn.Text = aimbotSnap and "Mode: Snap" or "Mode: Smooth"
    end
    if data.espBoxColor then espBoxColor = parseColor(data.espBoxColor, espBoxColor) boxColorBox.Text = data.espBoxColor end
    if data.espSkelColor then espSkelColor = parseColor(data.espSkelColor, espSkelColor) skelColorBox.Text = data.espSkelColor end
    if data.theme then
        theme.accent = parseColor(data.theme.accent, theme.accent)
        theme.background = parseColor(data.theme.background, theme.background)
        theme.panel = parseColor(data.theme.panel, theme.panel)
        theme.text = parseColor(data.theme.text, theme.text)
        theme.stroke = parseColor(data.theme.stroke, theme.stroke)
        accentColorBox.Text = colorToString(theme.accent)
        bgColorBox.Text = colorToString(theme.background)
        panelColorBox.Text = colorToString(theme.panel)
        textColorBox.Text = colorToString(theme.text)
        strokeColorBox.Text = colorToString(theme.stroke)
        applyTheme()
    end
    if data.keys then
        for name, keyName in pairs(data.keys) do
            if keys[name] then
                keys[name] = stringToKey(keyName)
                if keyBtns[name] then keyBtns[name].Text = keyName == "Unknown" and "---" or keyName end
            end
        end
    end
    if data.state then
        for name, value in pairs(data.state) do
            if state[name] ~= nil and type(value) == "boolean" and state[name] ~= value then
                toggle(name)
            end
        end
    end
    print("[CHack] Config geladen")
end

saveBtn.MouseButton1Click:Connect(saveConfig)
loadBtn.MouseButton1Click:Connect(loadConfig)

applyThemeBtn.MouseButton1Click:Connect(applyThemeFromInputs)

aimModeBtn.MouseButton1Click:Connect(function()
    aimbotSnap = not aimbotSnap
    aimModeBtn.Text = aimbotSnap and "Mode: Snap" or "Mode: Smooth"
end)

aimTargetBtn.MouseButton1Click:Connect(function()
    aimTargetHead = not aimTargetHead
    aimTargetBtn.Text = aimTargetHead and "Ziel: Kopf" or "Ziel: Koerper"
end)

toggle = function(key)
    state[key] = not state[key]
    if badges[key] and strokes[key] then setOn(badges[key], strokes[key], state[key]) end
    if key == "fly" then
        if state.fly then startFly() else stopFly() end
    elseif key == "freecam" then
        if state.freecam then startFreecam() else stopFreecam() end
    elseif key == "invisible" then setInvisible(state.invisible)
    elseif key == "fps" then fpsLabel.Visible = state.fps
    elseif key == "watermark" then watermarkLabel.Visible = state.watermark
    elseif key == "fov" then applyFOV()
    elseif key == "thirdperson" then applyThirdPerson()
    elseif key == "god" then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.MaxHealth = state.god and math.huge or 100
                hum.Health = hum.MaxHealth
            end
        end
    elseif key == "antiafk" then
        if state.antiafk then
            if antiafkConn then antiafkConn:Disconnect() end
            local vrs = game:GetService("VirtualUser")
            antiafkConn = LocalPlayer.Idled:Connect(function()
                vrs:Button2Down(Vector2.new(0, 0), Camera.CFrame)
                task.wait(0.1)
                vrs:Button2Up(Vector2.new(0, 0), Camera.CFrame)
            end)
        elseif antiafkConn then
            antiafkConn:Disconnect()
            antiafkConn = nil
        end
    end
end

btnESP.MouseButton1Click:Connect(function() toggle("esp") end)
btnFill.MouseButton1Click:Connect(function() toggle("boxfilled") end)
btnNames.MouseButton1Click:Connect(function() toggle("nametags") end)
btnHealth.MouseButton1Click:Connect(function() toggle("health") end)
btnRange.MouseButton1Click:Connect(function() toggle("range") end)
btnSkel.MouseButton1Click:Connect(function() toggle("skeleton") end)
btnFPS.MouseButton1Click:Connect(function() toggle("fps") end)
btnWM.MouseButton1Click:Connect(function() toggle("watermark") end)
btnFly.MouseButton1Click:Connect(function() toggle("fly") end)
btnSpeed.MouseButton1Click:Connect(function() toggle("speed") end)
btnNoclip.MouseButton1Click:Connect(function() toggle("noclip") end)
btnGod.MouseButton1Click:Connect(function() toggle("god") end)
btnJump.MouseButton1Click:Connect(function() toggle("infjump") end)
btnInvis.MouseButton1Click:Connect(function() toggle("invisible") end)
btnAFK.MouseButton1Click:Connect(function() toggle("antiafk") end)
btnFreecam.MouseButton1Click:Connect(function() toggle("freecam") end)
btnFOV.MouseButton1Click:Connect(function() toggle("fov") end)
btnTPDist.MouseButton1Click:Connect(function() toggle("thirdperson") end)
btnAim.MouseButton1Click:Connect(function() toggle("aimbot") end)
btnSilent.MouseButton1Click:Connect(function() toggle("silentaim") end)
btnRecoil.MouseButton1Click:Connect(function() toggle("norecoil") end)

flySpeedBox.FocusLost:Connect(function() flySpeed = tonumber(flySpeedBox.Text) or flySpeed; ch.flySpeed = flySpeed end)
speedBox.FocusLost:Connect(function()
    speedValue = math.clamp(tonumber(speedBox.Text) or speedValue, 16, 500)
    speedBox.Text = tostring(speedValue)
end)
espTextBox.FocusLost:Connect(function()
    espTextSize = math.clamp(tonumber(espTextBox.Text) or espTextSize, 8, 24)
    espTextBox.Text = tostring(espTextSize)
end)
boxColorBox.FocusLost:Connect(function()
    espBoxColor = parseColor(boxColorBox.Text, espBoxColor)
    boxColorBox.Text = colorToString(espBoxColor)
end)
skelColorBox.FocusLost:Connect(function()
    espSkelColor = parseColor(skelColorBox.Text, espSkelColor)
    skelColorBox.Text = colorToString(espSkelColor)
end)
fovBox.FocusLost:Connect(function()
    fovValue = math.clamp(tonumber(fovBox.Text) or fovValue, 70, 120)
    fovBox.Text = tostring(fovValue)
    applyFOV()
end)
tpDistBox.FocusLost:Connect(function()
    thirdPersonDist = math.clamp(tonumber(tpDistBox.Text) or thirdPersonDist, 5, 100)
    tpDistBox.Text = tostring(thirdPersonDist)
    applyThirdPerson()
end)
aimSmoothBox.FocusLost:Connect(function()
    aimSmoothness = math.clamp(tonumber(aimSmoothBox.Text) or aimSmoothness, 0.05, 0.9)
    aimSmoothBox.Text = tostring(aimSmoothness)
end)

tpBtn.MouseButton1Click:Connect(function()
    local name = tpNameBox.Text:lower()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower() == name or p.DisplayName:lower() == name then
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(3, 0, 0)
                end
            end
        end
    end
end)

tpCoordsBtn.MouseButton1Click:Connect(function()
    local txt = coordBox.Text
    local x, y, z = txt:match("(-?%d+%.?%d*),(-?%d+%.?%d*),(-?%d+%.?%d*)")
    if x and y and z then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(tonumber(x), tonumber(y), tonumber(z))
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if state.infjump and LocalPlayer.Character then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

UIS.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.RightShift then
        panel.Visible = not panel.Visible
        return
    end
    if bindingKey then
        keys[bindingKey] = input.KeyCode
        local kb = keyBtns[bindingKey]
        if kb then
            kb.Text = input.KeyCode.Name
            kb.TextColor3 = Color3.fromRGB(150, 100, 220)
        end
        bindingKey = nil
        return
    end
    if gp then return end
    for key, keyCode in pairs(keys) do
        if input.KeyCode == keyCode and keyCode ~= Enum.KeyCode.Unknown then toggle(key) end
    end
end)

UIS.InputChanged:Connect(function(input)
    if state.freecam and freecamPart and input.UserInputType == Enum.UserInputType.MouseMovement then
        freecamYaw -= input.Delta.X * 0.3
        freecamPitch = math.clamp(freecamPitch - input.Delta.Y * 0.3, -80, 80)
        freecamPart.CFrame = CFrame.new(freecamPart.CFrame.Position)
            * CFrame.Angles(0, math.rad(freecamYaw), 0)
            * CFrame.Angles(math.rad(freecamPitch), 0, 0)
        Camera.CFrame = freecamPart.CFrame
    elseif dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

RunService.RenderStepped:Connect(function()
    local now = tick()
    local delta = now - lastTime
    lastTime = now
    refreshFpsDisplay(delta)

    if state.fps then fpsLabel.Text = "FPS: " .. displayedFps end
    updateWatermark()

    for player, data in pairs(espTable) do
        local box, boxFill, tag = data.box, data.boxFill, data.tag
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local bounds = getCharacterBounds(char)
                if bounds and bounds.valid then
                    box.Color = espBoxColor
                    boxFill.Color = espBoxColor
                    box.Size = Vector2.new(bounds.w, bounds.h)
                    box.Position = Vector2.new(bounds.x, bounds.y)
                    box.Visible = state.esp
                    boxFill.Size = Vector2.new(bounds.w, bounds.h)
                    boxFill.Position = Vector2.new(bounds.x, bounds.y)
                    boxFill.Visible = state.boxfilled
                    tag.Size = espTextSize
                    tag.Position = Vector2.new(bounds.cx, bounds.y - espTextSize - 4)
                    tag.Text = player.Name
                    tag.Visible = state.nametags
                    if state.health then
                        local hpRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        if not data.hpBg then
                            data.hpBg = Drawing.new("Square")
                            data.hpBg.Filled = true
                            data.hpBg.Color = Color3.fromRGB(0, 0, 0)
                            data.hpBg.Transparency = 0.5
                            data.hpBar = Drawing.new("Square")
                            data.hpBar.Filled = true
                        end
                        local barH = bounds.h * hpRatio
                        local barX = bounds.x + bounds.w + 3
                        data.hpBg.Size = Vector2.new(4, bounds.h)
                        data.hpBg.Position = Vector2.new(barX, bounds.y)
                        data.hpBg.Visible = true
                        data.hpBar.Size = Vector2.new(4, barH)
                        data.hpBar.Position = Vector2.new(barX, bounds.y + bounds.h - barH)
                        data.hpBar.Color = Color3.fromRGB(math.floor(255 * (1 - hpRatio)), math.floor(255 * hpRatio), 0)
                        data.hpBar.Visible = true
                    else
                        if data.hpBg then data.hpBg.Visible = false end
                        if data.hpBar then data.hpBar.Visible = false end
                    end
                    if state.range then
                        if not data.distLabel then
                            data.distLabel = Drawing.new("Text")
                            data.distLabel.Center = false
                            data.distLabel.Outline = true
                            data.distLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
                            data.distLabel.Color = Color3.fromRGB(220, 220, 220)
                        end
                        data.distLabel.Size = espTextSize
                        local lchar = LocalPlayer.Character
                        local dist = 0
                        if lchar and lchar:FindFirstChild("HumanoidRootPart") then
                            dist = math.floor((char.HumanoidRootPart.Position - lchar.HumanoidRootPart.Position).Magnitude)
                        end
                        data.distLabel.Text = dist .. " studs"
                        data.distLabel.Position = Vector2.new(bounds.x, bounds.y + bounds.h + 3)
                        data.distLabel.Visible = true
                    elseif data.distLabel then
                        data.distLabel.Visible = false
                    end
                    if state.skeleton then
                        local bones = getBoneList(char)
                        local lineIndex = 1
                        for _, pair in ipairs(bones) do
                            local a = char:FindFirstChild(pair[1])
                            local b = char:FindFirstChild(pair[2])
                            local line = data.skeletonLines[lineIndex]
                            if a and b and line then
                                line.Color = espSkelColor
                                local aPos, aVis = Camera:WorldToViewportPoint(a.Position)
                                local bPos, bVis = Camera:WorldToViewportPoint(b.Position)
                                if aVis and bVis then
                                    line.From = Vector2.new(aPos.X, aPos.Y)
                                    line.To = Vector2.new(bPos.X, bPos.Y)
                                    line.Visible = true
                                else
                                    line.Visible = false
                                end
                            elseif line then
                                line.Visible = false
                            end
                            lineIndex += 1
                        end
                        for i = lineIndex, #data.skeletonLines do
                            data.skeletonLines[i].Visible = false
                        end
                    else
                        for _, line in ipairs(data.skeletonLines) do line.Visible = false end
                    end
                else
                    box.Visible = false
                    boxFill.Visible = false
                    tag.Visible = false
                    if data.hpBg then data.hpBg.Visible = false end
                    if data.hpBar then data.hpBar.Visible = false end
                    if data.distLabel then data.distLabel.Visible = false end
                    for _, line in ipairs(data.skeletonLines) do line.Visible = false end
                end
            else
                box.Visible = false
                boxFill.Visible = false
                tag.Visible = false
                if data.hpBg then data.hpBg.Visible = false end
                if data.hpBar then data.hpBar.Visible = false end
                if data.distLabel then data.distLabel.Visible = false end
                for _, line in ipairs(data.skeletonLines) do line.Visible = false end
            end
        end
    end

    if state.fly and bodyVel and bodyGyro then
        local dir = Vector3.zero
        local cf = Camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
        bodyVel.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
        bodyGyro.CFrame = cf
    end

    if state.freecam and freecamPart then
        local dir = Vector3.zero
        local cf = freecamPart.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
        freecamPart.CFrame += dir * freecamSpeed
        Camera.CFrame = freecamPart.CFrame
    end

    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = state.speed and speedValue or 16 end
    end

    if state.noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    if state.invisible then setInvisible(true) end
    if state.fov then applyFOV() end
    if state.thirdperson then applyThirdPerson() end

    updateSilentAim()
    updateAimbot()
    updateNoRecoil()
end)

for name, enabled in pairs(state) do
    if badges[name] and strokes[name] then setOn(badges[name], strokes[name], enabled) end
end
applyTheme()

print("CHack loaded up! RShift to open.")
