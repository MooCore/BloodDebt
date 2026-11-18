if not game:IsLoaded() then
    game.Loaded:Wait()
end

local TARGET_PLACE_ID = 79187287306411

if game.PlaceId ~= TARGET_PLACE_ID then
    warn(string.format("[BloodDebt] Inactive: this script is restricted to PlaceId %d (current PlaceId: %s).", TARGET_PLACE_ID, tostring(game.PlaceId)))
    return
end

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local function makeBootstrap()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    for _, parent in ipairs({ playerGui, CoreGui }) do
        if parent then
            local oldGui = parent:FindFirstChild("BloodDebtBootstrap")
            if oldGui then
                pcall(function()
                    oldGui:Destroy()
                end)
            end
        end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "BloodDebtBootstrap"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 1000000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local parented = pcall(function()
        playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
        if not playerGui then
            error("PlayerGui is not available")
        end
        gui.Parent = playerGui
    end)

    if not parented or gui.Parent ~= playerGui then
        pcall(function()
            gui.Parent = CoreGui
        end)
    end

    if not gui.Parent then
        error("Unable to display the Blood Debt startup interface")
    end

    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(390, 844)
    local width = math.max(240, math.min(320, viewport.X - 24))

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position = UDim2.new(0.5, 0, 0, 18)
    frame.Size = UDim2.fromOffset(width, 94)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 45, 65)
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(14, 10)
    title.Size = UDim2.new(1, -28, 0, 22)
    title.Font = Enum.Font.GothamBold
    title.Text = "BLOOD DEBT"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.BackgroundTransparency = 1
    status.Position = UDim2.fromOffset(14, 36)
    status.Size = UDim2.new(1, -28, 0, 48)
    status.Font = Enum.Font.Gotham
    status.Text = "Preparing script modules..."
    status.TextColor3 = Color3.fromRGB(205, 205, 212)
    status.TextSize = 11
    status.TextWrapped = true
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.Parent = frame

    return gui, status
end

local bootstrapOk, bootstrapGui, bootstrapStatus = pcall(makeBootstrap)

if not bootstrapOk then
    warn("[BloodDebt] Startup interface could not be created: " .. tostring(bootstrapGui))
    bootstrapGui = nil
    bootstrapStatus = nil
end

local function setStatus(message)
    if bootstrapStatus and bootstrapStatus.Parent then
        bootstrapStatus.Text = tostring(message)
    end
end

local MODULES = {
    "00_Core.lua",
    "01_Maps.lua",
    "02_RoleDatabase.lua",
    "03_UIFoundation.lua",
    "04_ESP.lua",
    "05_WeaponsAndEscape.lua",
    "06_Aimlock.lua",
    "07_Controller.lua",
    "08_NoRecoil.lua",
    "09_UI.lua",
    "10_Lifecycle.lua",
}

local MODULE_BASE_URL = "https://raw.githubusercontent.com/MooCore/BloodDebt/main/modules/"
local moduleBaseEnvironment = (type(getfenv) == "function" and getfenv()) or _G
local sharedState = {}
local moduleEnvironment = setmetatable({}, {
    __index = function(_, key)
        local value = sharedState[key]
        if value ~= nil then
            return value
        end
        return moduleBaseEnvironment[key]
    end,
    __newindex = function(_, key, value)
        sharedState[key] = value
    end,
})

if type(setfenv) ~= "function" then
    setStatus("This executor does not support setfenv, which is required by the modular loader.")
    warn("[BloodDebt] setfenv is unavailable. The modular loader cannot share state between components.")
    return
end

for index, moduleName in ipairs(MODULES) do
    setStatus(string.format("Downloading module %d of %d: %s", index, #MODULES, moduleName))

    local requestOk, response = pcall(function()
        return game:HttpGet(MODULE_BASE_URL .. moduleName)
    end)

    if not requestOk or type(response) ~= "string" or response == "" then
        local message = "Unable to download " .. moduleName .. ". Check executor HTTP access and the GitHub repository."
        setStatus(message)
        warn("[BloodDebt] " .. message .. " " .. tostring(response))
        return
    end

    local compileOk, moduleFunction = pcall(function()
        return loadstring(response, "BloodDebt/" .. moduleName)
    end)

    if not compileOk or type(moduleFunction) ~= "function" then
        local message = "Compilation failed in " .. moduleName .. ": " .. tostring(moduleFunction)
        setStatus(message)
        warn("[BloodDebt] " .. message)
        return
    end

    setfenv(moduleFunction, moduleEnvironment)
    setStatus(string.format("Initializing module %d of %d: %s", index, #MODULES, moduleName))

    local runOk, runError = pcall(moduleFunction)

    if not runOk then
        local message = "Initialization failed in " .. moduleName .. ": " .. tostring(runError)
        setStatus(message:sub(1, 700))
        warn("[BloodDebt] " .. tostring(runError))
        return
    end
end

if bootstrapGui and bootstrapGui.Parent then
    bootstrapGui:Destroy()
end

warn("[BloodDebt] All modules loaded and initialized.")
