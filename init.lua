if not game:IsLoaded() then
    game.Loaded:Wait()
end

local TARGET_PLACE_ID = 79187287306411

if game.PlaceId ~= TARGET_PLACE_ID then
    warn(string.format(
        "[BloodDebt] Inactive: this script is restricted to PlaceId %d (current PlaceId: %s).",
        TARGET_PLACE_ID,
        tostring(game.PlaceId)
    ))
    return
end

local REPO_BASE_URL = "https://raw.githubusercontent.com/john203221/BloodDebt/main/"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local GamepadService = nil

pcall(function()
    GamepadService = game:GetService("GamepadService")
end)

local GLOBAL_ENV = (type(getgenv) == "function" and getgenv()) or _G

if type(GLOBAL_ENV.__BloodDebtCleanup) == "function" then
    pcall(GLOBAL_ENV.__BloodDebtCleanup)
end

local ctx = {}
ctx.Players = Players
ctx.LocalPlayer = LocalPlayer
ctx.RunService = RunService
ctx.UserInputService = UserInputService
ctx.ContextActionService = ContextActionService
ctx.Workspace = Workspace
ctx.ReplicatedStorage = ReplicatedStorage
ctx.SoundService = SoundService
ctx.CoreGui = CoreGui
ctx.TweenService = TweenService
ctx.GamepadService = GamepadService
ctx.GLOBAL_ENV = GLOBAL_ENV

ctx.ActiveConnections = {}
ctx.PlayerConnections = {}
ctx.ToolAncestryConnections = setmetatable({}, { __mode = "k" })
ctx.ScriptAlive = true

function ctx.trackConnection(conn)
    if conn then
        table.insert(ctx.ActiveConnections, conn)
    end
    return conn
end

function ctx.trackPlayerConnection(player, conn)
    if not player or not conn then
        return conn
    end

    local list = ctx.PlayerConnections[player]

    if not list then
        list = {}
        ctx.PlayerConnections[player] = list
    end

    table.insert(list, conn)
    return conn
end

function ctx.disconnectPlayerConnections(player)
    local list = ctx.PlayerConnections[player]

    if list then
        for _, conn in ipairs(list) do
            pcall(function()
                conn:Disconnect()
            end)
        end

        ctx.PlayerConnections[player] = nil
    end
end

ctx.Icons = {
    Settings = "rbxassetid://10734950309",
    Crosshair = "rbxassetid://10709818534",
    Eye = "rbxassetid://10723346959",
    Bell = "rbxassetid://10709775704",
    BellRing = "rbxassetid://10709775560",
    Info = "rbxassetid://10723415903",
    Warning = "rbxassetid://10709752996",
    Success = "rbxassetid://10709790387",
    Error = "rbxassetid://10747383819",
}

ctx.Sounds = {
    GunDrop = "rbxassetid://9114700558",
    Notification = "rbxassetid://199077102",
    WindowsNotification = "rbxassetid://225320558",
    Popup = "rbxassetid://8486683243",
}

ctx.Config = {
    ESPEnabled = false,
    ESPMode = "Highlight",
    WeaponHighlight = false,
    AimlockEnabled = false,
    NREnabled = true,
    ScriptReady = false,
}

ctx.refreshUIButtons = function() end

local huiParent = (type(gethui) == "function" and gethui()) or nil

pcall(function()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")

    for _, parent in ipairs({ huiParent, CoreGui, playerGui }) do
        if parent then
            for _, guiName in ipairs({
                "BloodDebtCheat",
                "BloodDebtCrosshair",
                "BloodDebtLucideDemo",
            }) do
                local old = parent:FindFirstChild(guiName)

                if old then
                    old:Destroy()
                end
            end
        end
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloodDebtCrosshair"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local guiParent = huiParent or CoreGui
local parentedToSecuredGui = pcall(function()
    ScreenGui.Parent = guiParent
end)

if not parentedToSecuredGui then
    guiParent = LocalPlayer:WaitForChild("PlayerGui")
    ScreenGui.Parent = guiParent
end

ctx.ScreenGui = ScreenGui

function ctx.createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

function ctx.createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(255, 45, 65)
    stroke.Thickness = thickness or 1.5
    stroke.Parent = parent
    return stroke
end

function ctx.playSound(soundId)
    if not ctx.ScriptAlive or not soundId then
        return
    end

    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 0.8
        sound.Parent = SoundService
        sound:Play()

        sound.Ended:Connect(function()
            if sound and sound.Parent then
                sound:Destroy()
            end
        end)

        task.delay(10, function()
            if sound and sound.Parent then
                sound:Destroy()
            end
        end)
    end)
end

local notificationNumber = 0
local activeNotification = nil

function ctx.notify(title, message, icon, soundId)
    if not ctx.ScriptAlive or not ScreenGui.Parent then
        return
    end

    notificationNumber = notificationNumber + 1
    local currentNumber = notificationNumber

    if activeNotification then
        pcall(function()
            activeNotification:Destroy()
        end)

        activeNotification = nil
    end

    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.fromOffset(310, 82)
    notification.AnchorPoint = Vector2.new(1, 0)
    notification.Position = UDim2.new(1, 340, 0, 25)
    notification.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
    notification.BorderSizePixel = 0
    notification.ZIndex = 100
    notification.Parent = ScreenGui

    activeNotification = notification

    ctx.createCorner(notification, 12)
    ctx.createStroke(notification, Color3.fromRGB(255, 45, 65), 1.5)

    local iconImage = Instance.new("ImageLabel")
    iconImage.Size = UDim2.fromOffset(35, 35)
    iconImage.Position = UDim2.fromOffset(14, 23)
    iconImage.BackgroundTransparency = 1
    iconImage.Image = icon or ctx.Icons.Bell
    iconImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
    iconImage.ScaleType = Enum.ScaleType.Fit
    iconImage.ZIndex = 101
    iconImage.Parent = notification

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -70, 0, 24)
    titleLabel.Position = UDim2.fromOffset(60, 12)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tostring(title)
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 15
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 101
    titleLabel.Parent = notification

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -75, 0, 35)
    messageLabel.Position = UDim2.fromOffset(60, 36)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = tostring(message)
    messageLabel.TextColor3 = Color3.fromRGB(190, 190, 198)
    messageLabel.TextSize = 12
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.ZIndex = 101
    messageLabel.Parent = notification

    ctx.playSound(soundId or ctx.Sounds.Notification)

    TweenService:Create(
        notification,
        TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {
            Position = UDim2.new(1, -20, 0, 25),
        }
    ):Play()

    task.delay(3, function()
        if currentNumber ~= notificationNumber or not notification.Parent then
            return
        end

        local tween = TweenService:Create(
            notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {
                Position = UDim2.new(1, 340, 0, 25),
            }
        )

        tween:Play()
        tween.Completed:Wait()

        if currentNumber == notificationNumber and notification.Parent then
            notification:Destroy()

            if activeNotification == notification then
                activeNotification = nil
            end
        end
    end)
end

function ctx.getViewportCenter()
    local camera = Workspace.CurrentCamera

    if not camera then
        return nil
    end

    local viewport = camera.ViewportSize
    return Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
end

local CrosshairDot = Instance.new("Frame")
CrosshairDot.Name = "CentreDot"
CrosshairDot.AnchorPoint = Vector2.new(0.5, 0.5)
CrosshairDot.Size = UDim2.fromOffset(7, 7)
CrosshairDot.Position = UDim2.fromScale(0.5, 0.5)
CrosshairDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CrosshairDot.BorderSizePixel = 0
CrosshairDot.Parent = ScreenGui

local CrosshairCorner = Instance.new("UICorner")
CrosshairCorner.CornerRadius = UDim.new(1, 0)
CrosshairCorner.Parent = CrosshairDot

local CrosshairStroke = Instance.new("UIStroke")
CrosshairStroke.Color = Color3.fromRGB(0, 0, 0)
CrosshairStroke.Thickness = 1
CrosshairStroke.Parent = CrosshairDot

local LOADING_DURATION = 5.5

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingNotification"
LoadingFrame.AnchorPoint = Vector2.new(0.5, 0)
LoadingFrame.Position = UDim2.new(0.5, 0, 0, 34)
LoadingFrame.Size = UDim2.fromOffset(330, 104)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
LoadingFrame.BackgroundTransparency = 0.04
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Parent = ScreenGui

ctx.createCorner(LoadingFrame, 12)
ctx.createStroke(LoadingFrame, Color3.fromRGB(255, 45, 65), 1.5)

local LoadingTitle = Instance.new("TextLabel")
LoadingTitle.Name = "Title"
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Position = UDim2.fromOffset(16, 10)
LoadingTitle.Size = UDim2.new(1, -32, 0, 22)
LoadingTitle.Font = Enum.Font.GothamBold
LoadingTitle.Text = "BLOOD DEBT"
LoadingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingTitle.TextSize = 15
LoadingTitle.TextXAlignment = Enum.TextXAlignment.Left
LoadingTitle.Parent = LoadingFrame

local LoadingStatus = Instance.new("TextLabel")
LoadingStatus.Name = "Status"
LoadingStatus.BackgroundTransparency = 1
LoadingStatus.Position = UDim2.fromOffset(16, 35)
LoadingStatus.Size = UDim2.new(1, -82, 0, 18)
LoadingStatus.Font = Enum.Font.Gotham
LoadingStatus.Text = "Loading role categories & map database..."
LoadingStatus.TextColor3 = Color3.fromRGB(190, 190, 198)
LoadingStatus.TextSize = 11
LoadingStatus.TextXAlignment = Enum.TextXAlignment.Left
LoadingStatus.Parent = LoadingFrame

local LoadingPercent = Instance.new("TextLabel")
LoadingPercent.Name = "Percent"
LoadingPercent.BackgroundTransparency = 1
LoadingPercent.AnchorPoint = Vector2.new(1, 0)
LoadingPercent.Position = UDim2.new(1, -16, 0, 35)
LoadingPercent.Size = UDim2.fromOffset(52, 18)
LoadingPercent.Font = Enum.Font.GothamBold
LoadingPercent.Text = "0%"
LoadingPercent.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingPercent.TextSize = 11
LoadingPercent.TextXAlignment = Enum.TextXAlignment.Right
LoadingPercent.Parent = LoadingFrame

local ProgressTrack = Instance.new("Frame")
ProgressTrack.Name = "ProgressTrack"
ProgressTrack.Position = UDim2.fromOffset(16, 68)
ProgressTrack.Size = UDim2.new(1, -32, 0, 9)
ProgressTrack.BackgroundColor3 = Color3.fromRGB(37, 37, 44)
ProgressTrack.BorderSizePixel = 0
ProgressTrack.Parent = LoadingFrame

local ProgressTrackCorner = Instance.new("UICorner")
ProgressTrackCorner.CornerRadius = UDim.new(1, 0)
ProgressTrackCorner.Parent = ProgressTrack

local ProgressFill = Instance.new("Frame")
ProgressFill.Name = "Fill"
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = Color3.fromRGB(255, 45, 65)
ProgressFill.BorderSizePixel = 0
ProgressFill.Parent = ProgressTrack

local ProgressFillCorner = Instance.new("UICorner")
ProgressFillCorner.CornerRadius = UDim.new(1, 0)
ProgressFillCorner.Parent = ProgressFill

local loadingStartedAt = os.clock()

local function fetchAndRunModule(fileName, statusText)
    if LoadingStatus and LoadingStatus.Parent then
        LoadingStatus.Text = statusText
    end

    local url = REPO_BASE_URL .. fileName
    local source = nil

    for attempt = 1, 3 do
        local ok, result = pcall(function()
            return game:HttpGet(url)
        end)

        if ok and type(result) == "string" and #result > 0 then
            source = result
            break
        end

        if attempt < 3 then
            task.wait(0.4)
        end
    end

    if not source then
        error("[BloodDebt] Failed to download module: " .. tostring(fileName))
    end

    local chunk, compileErr = loadstring(source)

    if not chunk then
        error("[BloodDebt] Failed to compile " .. tostring(fileName) .. ": " .. tostring(compileErr))
    end

    local factory = chunk()

    if type(factory) == "function" then
        return factory(ctx)
    end

    return factory
end

GLOBAL_ENV.__BloodDebtCleanup = function()
    ctx.ScriptAlive = false

    if ctx.Combat and type(ctx.Combat.stopAimlockHold) == "function" then
        pcall(ctx.Combat.stopAimlockHold)
    end

    pcall(function()
        RunService:UnbindFromRenderStep("BloodDebt_AimLock")
    end)

    pcall(function()
        ContextActionService:UnbindAction("BloodDebt_ToggleAimlock")
        ContextActionService:UnbindAction("BloodDebt_TeleportToGroundGun")
        ContextActionService:UnbindAction("BloodDebt_TeleportToKillerEscape")
    end)

    for player in pairs(ctx.PlayerConnections) do
        ctx.disconnectPlayerConnections(player)
    end

    for _, conn in ipairs(ctx.ActiveConnections) do
        pcall(function()
            conn:Disconnect()
        end)
    end

    table.clear(ctx.ActiveConnections)

    if ctx.ESP then
        if type(ctx.ESP.clearAllPlayerESP) == "function" then
            pcall(ctx.ESP.clearAllPlayerESP)
        end

        if type(ctx.ESP.clearAllWeaponHighlights) == "function" then
            pcall(ctx.ESP.clearAllWeaponHighlights)
        end
    end

    if ScreenGui and ScreenGui.Parent then
        pcall(function()
            ScreenGui:Destroy()
        end)
    end
end

local modulesLoadedOk, modulesLoadErr = pcall(function()
    ctx.Database = fetchAndRunModule("database.lua", "Loading role categories & map database...")
    ctx.ESP = fetchAndRunModule("esp.lua", "Initializing player & weapon ESP...")
    ctx.Combat = fetchAndRunModule("combat.lua", "Binding combat & controller actions...")
    ctx.UI = fetchAndRunModule("ui.lua", "Building user interface...")
end)

if not modulesLoadedOk then
    warn(tostring(modulesLoadErr))

    if LoadingStatus and LoadingStatus.Parent then
        LoadingStatus.Text = "Module load failed. Check console output."
    end

    return
end

if LoadingStatus and LoadingStatus.Parent then
    LoadingStatus.Text = "Finalizing initialization..."
end

task.spawn(function()
    while ctx.ScriptAlive and ScreenGui.Parent do
        ctx.ESP.updateESP()
        ctx.ESP.updateWeaponHighlight()
        ctx.ESP.checkKillerEscapeAvailability()
        task.wait(0.25)
    end
end)

task.spawn(function()
    while ctx.ScriptAlive and ScreenGui.Parent and not ctx.Config.ScriptReady do
        task.wait(0.15)
    end

    if not ctx.ScriptAlive or not ScreenGui.Parent then
        return
    end

    ctx.ESP.refreshGroundWeaponRegistry()

    while ctx.ScriptAlive and ScreenGui.Parent do
        ctx.ESP.refreshGroundWeaponRegistry()
        task.wait(0.3)
    end
end)

local function disableDefaultGamepadCursor()
    if not GamepadService then
        return
    end

    pcall(function()
        GamepadService:DisableGamepadCursor()
    end)
end

disableDefaultGamepadCursor()

task.spawn(function()
    while ctx.ScriptAlive and ScreenGui.Parent do
        disableDefaultGamepadCursor()
        task.wait(0.5)
    end
end)

while ctx.ScriptAlive and ScreenGui.Parent do
    local elapsed = os.clock() - loadingStartedAt
    local progress = math.clamp(elapsed / LOADING_DURATION, 0, 1)

    ProgressFill.Size = UDim2.new(progress, 0, 1, 0)
    LoadingPercent.Text = string.format(
        "%d%%",
        math.floor(progress * 100 + 0.5)
    )

    if progress >= 1 then
        break
    end

    RunService.RenderStepped:Wait()
end

if not ctx.ScriptAlive then
    return
end

ctx.Config.ScriptReady = true
ctx.Config.ESPEnabled = true
ctx.Config.WeaponHighlight = true
ctx.Config.AimlockEnabled = true
ctx.Config.NREnabled = true

ctx.UI.Toolbar.Visible = true
ctx.UI.SettingsPanel.Visible = false
ctx.UI.ReopenButton.Visible = false

ctx.refreshUIButtons()

task.delay(0.6, ctx.Combat.runNRInjection)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Character then
        ctx.ESP.createESP(player)
    end
end

if LoadingFrame and LoadingFrame.Parent then
    LoadingFrame:Destroy()
end

ctx.notify(
    "Initialization Complete",
    "Blood Debt features have been initialized successfully.",
    ctx.Icons.Success,
    ctx.Sounds.Notification
)

warn(
    "Blood Debt script loaded for PlaceId 79187287306411: Lucide UI + sounds, KillerEscape D-Pad Down teleport, through-walls aimlock, BloodFolder map detection, and post-match crash prevention."
)
