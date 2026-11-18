if not game:IsLoaded() then
    game.Loaded:Wait()
end

TARGET_PLACE_ID = 79187287306411

if game.PlaceId ~= TARGET_PLACE_ID then
    warn(string.format("[BloodDebt] Inactive: this script is restricted to PlaceId %d (current PlaceId: %s).", TARGET_PLACE_ID, tostring(game.PlaceId)))
    return
end

Players = game:GetService("Players")
LocalPlayer = Players.LocalPlayer
RunService = game:GetService("RunService")
UserInputService = game:GetService("UserInputService")
ContextActionService = game:GetService("ContextActionService")
Workspace = game:GetService("Workspace")
ReplicatedStorage = game:GetService("ReplicatedStorage")
SoundService = game:GetService("SoundService")
CoreGui = game:GetService("CoreGui")
TweenService = game:GetService("TweenService")
IS_MOBILE = UserInputService.TouchEnabled and not (
    UserInputService.MouseEnabled and UserInputService.KeyboardEnabled
)

function getViewportSize()
    local camera = Workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return IS_MOBILE and Vector2.new(390, 844) or Vector2.new(1280, 720)
end

GamepadService = nil
pcall(function()
    GamepadService = game:GetService("GamepadService")
end)

GLOBAL_ENV = (type(getgenv) == "function" and getgenv()) or _G
if type(GLOBAL_ENV.__BloodDebtCleanup) == "function" then
    pcall(GLOBAL_ENV.__BloodDebtCleanup)
end

ActiveConnections = {}
PlayerConnections = {}
ToolAncestryConnections = setmetatable({}, { __mode = "k" })
ScriptAlive = true

function trackConnection(conn)
    if conn then
        table.insert(ActiveConnections, conn)
    end
    return conn
end

function trackPlayerConnection(player, conn)
    if not player or not conn then
        return conn
    end
    local list = PlayerConnections[player]
    if not list then
        list = {}
        PlayerConnections[player] = list
    end
    table.insert(list, conn)
    return conn
end

function disconnectPlayerConnections(player)
    local list = PlayerConnections[player]
    if list then
        for _, conn in ipairs(list) do
            pcall(function()
                conn:Disconnect()
            end)
        end
        PlayerConnections[player] = nil
    end
end

MAX_TOTAL_HIGHLIGHTS = 26
MAX_WEAPON_HIGHLIGHTS = 10

Icons = {
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

Sounds = {
    GunDrop = "rbxassetid://9114700558",
    Notification = "rbxassetid://199077102",
    WindowsNotification = "rbxassetid://225320558",
    Popup = "rbxassetid://8486683243",
}

Config = {
    ESPEnabled = false,
    ESPMode = "Highlight",
    WeaponHighlight = false,
    AimlockEnabled = false,
    NREnabled = true,
    ScriptReady = false,
}

AIMLOCK_RADIUS_PIXELS = math.huge
AIMLOCK_SMOOTHING = 14
AIMLOCK_RESCAN_INTERVAL = 0.035
AIMLOCK_SWITCH_MARGIN = 10
Q_INPUT_DEBOUNCE = 0.20

function normalizeKey(text)
    return string.lower(tostring(text or "")):gsub("[^%w]", "")
end

function normalizeWeaponName(name)
    return normalizeKey(name)
end
