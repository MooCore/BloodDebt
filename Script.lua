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
    frame.Size = UDim2.fromOffset(width, 108)
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
    status.Size = UDim2.new(1, -94, 0, 34)
    status.Font = Enum.Font.Gotham
    status.Text = "Preparing script modules..."
    status.TextColor3 = Color3.fromRGB(205, 205, 212)
    status.TextSize = 11
    status.TextWrapped = true
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.Parent = frame

    local percent = Instance.new("TextLabel")
    percent.Name = "Percent"
    percent.BackgroundTransparency = 1
    percent.AnchorPoint = Vector2.new(1, 0)
    percent.Position = UDim2.new(1, -14, 0, 36)
    percent.Size = UDim2.fromOffset(52, 18)
    percent.Font = Enum.Font.GothamBold
    percent.Text = "0%"
    percent.TextColor3 = Color3.new(1, 1, 1)
    percent.TextSize = 11
    percent.TextXAlignment = Enum.TextXAlignment.Right
    percent.Parent = frame

    local track = Instance.new("Frame")
    track.Name = "ProgressTrack"
    track.Position = UDim2.fromOffset(14, 82)
    track.Size = UDim2.new(1, -28, 0, 8)
    track.BackgroundColor3 = Color3.fromRGB(43, 43, 51)
    track.BorderSizePixel = 0
    track.Parent = frame
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 45, 65)
    fill.BorderSizePixel = 0
    fill.Parent = track
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    return gui, status, title, percent, fill, stroke
end

local bootstrapOk, bootstrapGui, bootstrapStatus, bootstrapTitle, bootstrapPercent, bootstrapFill, bootstrapStroke = pcall(makeBootstrap)

if not bootstrapOk then
    warn("[BloodDebt] Startup interface could not be created: " .. tostring(bootstrapGui))
    bootstrapGui = nil
    bootstrapStatus = nil
    bootstrapTitle = nil
    bootstrapPercent = nil
    bootstrapFill = nil
    bootstrapStroke = nil
end

local function setStatus(message, progress, state)
    progress = math.clamp(tonumber(progress) or 0, 0, 1)
    if bootstrapStatus and bootstrapStatus.Parent then
        bootstrapStatus.Text = tostring(message)
    end
    if bootstrapPercent and bootstrapPercent.Parent then
        bootstrapPercent.Text = string.format("%d%%", math.floor(progress * 100 + 0.5))
    end
    if bootstrapFill and bootstrapFill.Parent then
        bootstrapFill.Size = UDim2.new(progress, 0, 1, 0)
    end
    if state == "error" then
        if bootstrapTitle then
            bootstrapTitle.Text = "INITIALIZATION FAILED"
        end
        if bootstrapStroke then
            bootstrapStroke.Color = Color3.fromRGB(255, 65, 65)
        end
        if bootstrapStatus then
            bootstrapStatus.TextColor3 = Color3.fromRGB(255, 160, 160)
        end
    elseif state == "complete" then
        if bootstrapTitle then
            bootstrapTitle.Text = "INITIALIZATION COMPLETE"
        end
        if bootstrapStroke then
            bootstrapStroke.Color = Color3.fromRGB(80, 210, 135)
        end
        if bootstrapFill then
            bootstrapFill.BackgroundColor3 = Color3.fromRGB(80, 210, 135)
        end
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

local currentModuleIndex = 1

if type(setfenv) ~= "function" then
    setStatus("This executor does not support setfenv, which is required by the modular loader.", 0, "error")
    warn("[BloodDebt] setfenv is unavailable. The modular loader cannot share state between components.")
    return
end

sharedState.__BloodDebtBootstrapUpdate = function(message, moduleProgress)
    local progress = (currentModuleIndex - 1 + math.clamp(tonumber(moduleProgress) or 0, 0, 1)) / #MODULES
    setStatus(message, progress)
end

for index, moduleName in ipairs(MODULES) do
    currentModuleIndex = index
    setStatus(string.format("Downloading module %d of %d: %s", index, #MODULES, moduleName), (index - 1) / #MODULES)

    local requestOk, response = pcall(function()
        return game:HttpGet(MODULE_BASE_URL .. moduleName)
    end)

    if not requestOk or type(response) ~= "string" or response == "" then
        local message = "Unable to download " .. moduleName .. ". Check executor HTTP access and the GitHub repository."
        setStatus(message, (index - 1) / #MODULES, "error")
        warn("[BloodDebt] " .. message .. " " .. tostring(response))
        return
    end

    setStatus(string.format("Compiling module %d of %d: %s", index, #MODULES, moduleName), (index - 0.45) / #MODULES)
    local compileOk, moduleFunction = pcall(function()
        return loadstring(response, "BloodDebt/" .. moduleName)
    end)

    if not compileOk or type(moduleFunction) ~= "function" then
        local message = "Compilation failed in " .. moduleName .. ": " .. tostring(moduleFunction)
        setStatus(message, (index - 0.45) / #MODULES, "error")
        warn("[BloodDebt] " .. message)
        return
    end

    setfenv(moduleFunction, moduleEnvironment)
    setStatus(string.format("Initializing module %d of %d: %s", index, #MODULES, moduleName), (index - 0.2) / #MODULES)

    local runOk, runError = pcall(moduleFunction)

    if not runOk then
        local message = "Initialization failed in " .. moduleName .. ": " .. tostring(runError)
        setStatus(message:sub(1, 700), (index - 0.2) / #MODULES, "error")
        warn("[BloodDebt] " .. tostring(runError))
        return
    end

    setStatus(string.format("Loaded module %d of %d: %s", index, #MODULES, moduleName), index / #MODULES)
end

setStatus("All Blood Debt features are ready.", 1, "complete")
if bootstrapGui and bootstrapGui.Parent then
    task.delay(1.25, function()
        if bootstrapGui and bootstrapGui.Parent then
            bootstrapGui:Destroy()
        end
    end)
end

warn("[BloodDebt] All modules loaded and initialized.")
