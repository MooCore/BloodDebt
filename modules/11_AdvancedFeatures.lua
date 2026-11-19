if Config.__AdvancedFeaturesLoaded then
    return
end
Config.__AdvancedFeaturesLoaded = true

Config.BulletRedirectEnabled = false
Config.BulletRedirectTargetRole = "Killer"
Config.BulletRedirectHitChance = 100
Config.BulletRedirectWallcheck = false
Config.BulletRedirectTargetPart = "Torso"
Config.BulletRedirectRadius = 150
Config.BulletRedirectFOVVisible = true
Config.BulletRedirectFollowAimlock = true
Config.HintESPEnabled = false

local redirectRoleOptions = { "Killer", "Vigilante", "Innocent", "All" }
local redirectHitChanceOptions = { 100, 75, 50, 25, 0 }
local redirectPartOptions = { "Head", "Torso", "HumanoidRootPart" }
local redirectRadiusOptions = { 100, 150, 250, 400, 600, 0 }
local redirectActorInjected = setmetatable({}, { __mode = "k" })
local redirectActorLastInjection = setmetatable({}, { __mode = "k" })
local hintMatchPlayers = setmetatable({}, { __mode = "k" })
local redirectWarningShown = false
local nametagMode = "Role"
local redirectPanelWasOpenedFromSettings = false
local refreshAdvancedOptions

local function isKillerRole(role)
    return role == "Killer" or (type(role) == "string" and string.find(role, "Juggernaut", 1, true) ~= nil)
end

local function isVigilanteRole(role)
    return role == "Vigilante" or role == "Detective" or role == "Hero"
end

local function isInnocentRole(role)
    return role == "Innocent" or role == "Bystander"
end

local originalGetRole = getRole
getRole = function(player)
    if player and player ~= LocalPlayer then
        local activeMap = getActiveMatchMap()
        if activeMap and activeMap.Mode == "Team War" then
            local npcsFolder = Workspace:FindFirstChild("NPCSFolder")
            local localNPC = npcsFolder and npcsFolder:FindFirstChild(LocalPlayer.Name)
            local targetNPC = npcsFolder and npcsFolder:FindFirstChild(player.Name)
            if localNPC and targetNPC then
                local localTeam = nil
                local opposingTeam = nil
                if localNPC:FindFirstChild("TEAM1") then
                    localTeam = "TEAM1"
                    opposingTeam = "TEAM2"
                elseif localNPC:FindFirstChild("TEAM2") then
                    localTeam = "TEAM2"
                    opposingTeam = "TEAM1"
                end
                if localTeam then
                    if targetNPC:FindFirstChild(localTeam) then
                        return "Innocent", nil
                    elseif targetNPC:FindFirstChild(opposingTeam) then
                        return "Killer", nil
                    end
                end
            end
        end
    end
    return originalGetRole(player)
end

local function parseHintText(text)
    local targetNumber = 1
    local content = tostring(text or "")
    local targetPrefix = content:match("^%[TARGET%s+%d+%]%s*")
    if targetPrefix then
        targetNumber = tonumber(content:match("^%[TARGET%s+(%d+)%]")) or 1
        content = content:sub(#targetPrefix + 1)
    end
    content = content:match("^%s*(.-)%s*$") or ""
    local taskValue = content:match("^Their task%s*:%s*(.*)$")
    if taskValue then
        return targetNumber, "task", taskValue:match("^%s*(.-)%s*$") or ""
    end
    return targetNumber, "trait", content
end

local function collectHintConditions()
    local rsod = LocalPlayer:FindFirstChild("RSOD")
    if not rsod then
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        rsod = playerGui and playerGui:FindFirstChild("RSOD")
    end
    local hintsFrame = rsod and rsod:FindFirstChild("HintsScrollFrame")
    if not hintsFrame then
        return nil
    end
    local conditionsByTarget = {}
    for _, child in ipairs(hintsFrame:GetChildren()) do
        if child.Name == "TextLaba" and child:IsA("TextLabel") and child.Text ~= "" then
            local targetNumber, hintType, hintValue = parseHintText(child.Text)
            if hintValue and hintValue ~= "" then
                conditionsByTarget[targetNumber] = conditionsByTarget[targetNumber] or {}
                table.insert(conditionsByTarget[targetNumber], {
                    Type = hintType,
                    Value = hintValue,
                })
            end
        end
    end
    return next(conditionsByTarget) and conditionsByTarget or nil
end

local function updateHintMatchPlayers()
    table.clear(hintMatchPlayers)
    if not Config.HintESPEnabled or not isMatchActive() then
        return
    end
    local npcsFolder = Workspace:FindFirstChild("NPCSFolder")
    local targetConditions = collectHintConditions()
    if not npcsFolder or not targetConditions then
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not isLobbyPlayer(player, player.Character) then
            local npcModel = npcsFolder:FindFirstChild(player.Name)
            if npcModel then
                local configuration = npcModel:FindFirstChild("Configuration")
                local matchesAnyTarget = false
                for _, conditions in pairs(targetConditions) do
                    local matchesEveryCondition = true
                    for _, condition in ipairs(conditions) do
                        local conditionMet = false
                        if condition.Type == "task" then
                            local assignedTask = npcModel:FindFirstChild("AssignedTask")
                            conditionMet = assignedTask and assignedTask:IsA("StringValue") and assignedTask.Value == condition.Value or false
                        elseif configuration then
                            for _, configValue in ipairs(configuration:GetChildren()) do
                                if configValue:IsA("StringValue") and configValue.Value == condition.Value then
                                    conditionMet = true
                                    break
                                end
                            end
                        end
                        if not conditionMet then
                            matchesEveryCondition = false
                            break
                        end
                    end
                    if matchesEveryCondition then
                        matchesAnyTarget = true
                        break
                    end
                end
                if matchesAnyTarget then
                    hintMatchPlayers[player] = true
                end
            end
        end
    end
end

local function getCharacterName(player)
    local npcsFolder = Workspace:FindFirstChild("NPCSFolder")
    local npcModel = npcsFolder and npcsFolder:FindFirstChild(player.Name)
    if npcModel then
        local characterName = npcModel:FindFirstChild("CharacterName")
            or npcModel:FindFirstChild("NPCName")
            or npcModel:FindFirstChild("Name")
        if characterName and characterName:IsA("StringValue") and characterName.Value ~= "" then
            return characterName.Value
        end
        local configuration = npcModel:FindFirstChild("Configuration")
        if configuration then
            local configuredName = configuration:FindFirstChild("CharacterName")
                or configuration:FindFirstChild("NPCName")
                or configuration:FindFirstChild("Name")
            if configuredName and configuredName:IsA("StringValue") and configuredName.Value ~= "" then
                return configuredName.Value
            end
        end
        local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.DisplayName ~= player.Name and humanoid.DisplayName ~= "" then
            return humanoid.DisplayName
        end
    end
    return player.Name
end

local originalUpdateESP = updateESP
updateESP = function()
    updateHintMatchPlayers()
    originalUpdateESP()
    if not Config.ESPEnabled then
        return
    end
    for player, esp in pairs(ESPObjects) do
        if player.Parent == Players and esp.RoleText and esp.RoleText.Parent then
            local role, weaponName = getRole(player)
            local roleLabel, roleColor = getRoleDisplay(role, weaponName)
            if Config.HintESPEnabled and hintMatchPlayers[player] then
                if isKillerRole(role) then
                    roleLabel = "KILLER + HINT MATCH"
                    roleColor = Color3.fromRGB(255, 165, 0)
                elseif isVigilanteRole(role) then
                    roleLabel = "VIGILANTE + HINT MATCH"
                    roleColor = Color3.fromRGB(128, 0, 128)
                else
                    roleLabel = "HINT MATCH"
                    roleColor = Color3.fromRGB(255, 255, 0)
                end
            end
            if nametagMode == "Username" then
                roleLabel = player.Name
            elseif nametagMode == "Character Name" then
                roleLabel = getCharacterName(player)
            end
            esp.RoleText.Text = roleLabel
            esp.RoleText.TextColor3 = roleColor
            if esp.Highlight then
                esp.Highlight.FillColor = roleColor
                esp.Highlight.OutlineColor = roleColor
            end
        end
    end
end

local specialKillerDropNames = {}
for _, weaponName in ipairs({
    "RY's GG-17", "AT's KAR15", "20mm", "VK's ANKM", "VA's ANKM", "RVK",
    "GZhG-7.62", "AK47 Case Hardened 1000000", "TG's JAVELIN-ZVD",
    "Mason's Machete", "Pretty Pink RVK", "Zimniy Voron", "Zimniy Tsar",
    "THE BEAR's Plaything",
}) do
    specialKillerDropNames[normalizeWeaponName(weaponName)] = true
end

local function isKillerOrJuggernautDropWeapon(weaponName)
    local key = normalizeWeaponName(weaponName)
    if specialKillerDropNames[key] then
        return true
    end
    local roles = WEAPON_ROLE_LOOKUP[key]
    if not roles then
        return false
    end
    if roles.Killer then
        return true
    end
    for roleName in pairs(roles) do
        if string.find(roleName, "Juggernaut", 1, true) then
            return true
        end
    end
    return false
end

local function isSupportedDroppedRoleWeapon(tool)
    return tool and tool:IsA("Tool")
        and (isVigilanteWeapon(tool.Name) or isKillerOrJuggernautDropWeapon(tool.Name))
end

local additionalRoleWeaponHighlights = setmetatable({}, { __mode = "k" })

local function clearAdditionalRoleWeaponHighlights()
    for tool, highlight in pairs(additionalRoleWeaponHighlights) do
        pcall(function()
            highlight.Adornee = nil
            highlight:Destroy()
        end)
        additionalRoleWeaponHighlights[tool] = nil
    end
end

local function updateAdditionalRoleWeaponHighlights()
    if not Config.WeaponHighlight or not isMatchActive() then
        clearAdditionalRoleWeaponHighlights()
        return
    end
    local bloodFolder = Workspace:FindFirstChild("BloodFolder")
    if not bloodFolder then
        clearAdditionalRoleWeaponHighlights()
        return
    end
    local activeCount = 0
    for _, highlight in pairs(highlightedWeapons) do
        if highlight and highlight.Parent and highlight.Enabled then
            activeCount = activeCount + 1
        end
    end
    for tool, highlight in pairs(additionalRoleWeaponHighlights) do
        if not tool or not tool.Parent or not tool:IsDescendantOf(bloodFolder)
            or not isSupportedDroppedRoleWeapon(tool) or isWeaponInHands(tool)
            or not highlight or not highlight.Parent then
            pcall(function()
                if highlight then
                    highlight.Adornee = nil
                    highlight:Destroy()
                end
            end)
            additionalRoleWeaponHighlights[tool] = nil
        else
            activeCount = activeCount + 1
        end
    end
    for _, instance in ipairs(bloodFolder:GetDescendants()) do
        if activeCount >= MAX_WEAPON_HIGHLIGHTS then
            break
        end
        if isSupportedDroppedRoleWeapon(instance) and not isWeaponInHands(instance)
            and not additionalRoleWeaponHighlights[instance] and not highlightedWeapons[instance] then
            local highlight = Instance.new("Highlight")
            highlight.Name = "RoleWeaponDropHighlight"
            highlight.Adornee = instance
            highlight.FillColor = Color3.fromRGB(255, 220, 65)
            highlight.FillTransparency = 1
            highlight.OutlineColor = Color3.fromRGB(255, 220, 65)
            highlight.OutlineTransparency = 0.15
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = ScreenGui
            additionalRoleWeaponHighlights[instance] = highlight
            activeCount = activeCount + 1
        end
    end
end

local previousWeaponHighlightUpdate = updateWeaponHighlight
updateWeaponHighlight = function()
    previousWeaponHighlightUpdate()
    updateAdditionalRoleWeaponHighlights()
end

local anyRoleTeleportBusy = false
teleportToGroundWeapon = function()
    if not Config.ScriptReady or anyRoleTeleportBusy then
        return
    end
    anyRoleTeleportBusy = true
    task.delay(0.35, function()
        anyRoleTeleportBusy = false
    end)
    local bloodFolder = Workspace:FindFirstChild("BloodFolder")
    if not bloodFolder then
        notify("Weapon Not Found", "No dropped role weapon is currently available.", Icons.Warning, Sounds.WindowsNotification)
        return
    end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not character.Parent or not humanoid or humanoid.Health <= 0 or not rootPart then
        notify("Teleport Unavailable", "Your character is not ready. Try again after respawning.", Icons.Warning, Sounds.WindowsNotification)
        return
    end
    local selectedTool, selectedPart
    local closestDistance = math.huge
    for _, instance in ipairs(bloodFolder:GetDescendants()) do
        if isSupportedDroppedRoleWeapon(instance) and not isWeaponInHands(instance) then
            local part = getGroundWeaponPart(instance)
            if part then
                local distance = (part.Position - rootPart.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    selectedTool = instance
                    selectedPart = part
                end
            end
        end
    end
    if not selectedTool or not selectedPart then
        notify("Weapon Not Found", "No dropped Killer, Juggernaut, or Vigilante weapon is currently available.", Icons.Warning, Sounds.WindowsNotification)
        return
    end
    local targetPosition = selectedPart.Position
    if targetPosition.X ~= targetPosition.X or targetPosition.Y ~= targetPosition.Y
        or targetPosition.Z ~= targetPosition.Z or targetPosition.Magnitude > 1e6 then
        notify("Teleport Failed", "The weapon's location could not be determined.", Icons.Error, Sounds.WindowsNotification)
        return
    end
    local currentPivot = character:GetPivot()
    local destination = targetPosition + Vector3.new(0, 3, 0)
    local ok, teleportError = pcall(function()
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        character:PivotTo(CFrame.new(destination) * currentPivot.Rotation)
    end)
    if ok then
        notify("Teleport Complete", "Teleported to " .. selectedTool.Name .. ".", Icons.Success, Sounds.Popup)
    else
        warn("[BloodDebt] Role-weapon teleport failed: " .. tostring(teleportError))
        notify("Teleport Failed", "The teleport could not be completed. Please try again.", Icons.Error, Sounds.WindowsNotification)
    end
end

local BULLET_REDIRECT_ACTOR_SOURCE = [=[
local env = (type(getgenv) == "function" and getgenv()) or _G
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local gunRes = ReplicatedStorage:FindFirstChild("gun_res")
local lib = gunRes and gunRes:FindFirstChild("lib")
local projectileHandler = lib and lib:FindFirstChild("projectileHandler")
local fastCastModule = projectileHandler and projectileHandler:FindFirstChild("FastCastRedux")
if not fastCastModule then
    return
end
local requireOK, FastCast = pcall(require, fastCastModule)
if not requireOK or type(FastCast) ~= "table" or type(FastCast.Fire) ~= "function" then
    return
end
if env.__BloodDebtRedirectFastCast == FastCast and env.__BloodDebtRedirectHookInstalled then
    return
end
local originalFire = FastCast.Fire
local function getTargetPart(character, selectedPart)
    local part = character:FindFirstChild(selectedPart)
    if part and part:IsA("BasePart") then
        return part
    end
    if selectedPart == "Torso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("Head")
end
local function hasClearLine(localCharacter, targetCharacter, targetPosition, shotOrigin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excluded = { targetCharacter }
    if localCharacter then
        table.insert(excluded, localCharacter)
    end
    params.FilterDescendantsInstances = excluded
    params.IgnoreWater = true
    local origin = typeof(shotOrigin) == "Vector3" and shotOrigin or (Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.Position)
    if not origin then
        return false
    end
    return Workspace:Raycast(origin, targetPosition - origin, params) == nil
end
local function getValidCharacter(player)
    if not player or player == Players.LocalPlayer then
        return nil, nil
    end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not character.Parent or not humanoid or humanoid.Health <= 0 then
        return nil, nil
    end
    return character, humanoid
end
local function chooseLockedAimTarget(config, shotOrigin)
    local userId = tonumber(config.LockTargetUserId) or 0
    if not config.FollowAimlock or userId <= 0 then
        return nil, nil, false
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId == userId then
            local character = getValidCharacter(player)
            if not character then
                return nil, nil, true
            end
            local part = getTargetPart(character, config.LockTargetPart or config.TargetPart or "Torso")
            if not part or not part:IsA("BasePart") then
                return nil, nil, true
            end
            if config.Wallcheck and not hasClearLine(Players.LocalPlayer.Character, character, part.Position, shotOrigin) then
                return nil, nil, true
            end
            return player, part, true
        end
    end
    return nil, nil, true
end
local function chooseRoleTarget(config, shotOrigin)
    local camera = Workspace.CurrentCamera
    local localPlayer = Players.LocalPlayer
    if not camera or not localPlayer then
        return nil, nil
    end
    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local bestPlayer = nil
    local bestPart = nil
    local bestDistance = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and config.ValidTargets and config.ValidTargets[player.Name] then
            local character = getValidCharacter(player)
            if character then
                local part = getTargetPart(character, config.TargetPart or "Torso")
                if part and part:IsA("BasePart") then
                    local screenPosition = camera:WorldToViewportPoint(part.Position)
                    if screenPosition.Z > 0 then
                        local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - center).Magnitude
                        local radius = tonumber(config.Radius) or 150
                        if (radius <= 0 or distance <= radius) and distance < bestDistance then
                            local clear = not config.Wallcheck or hasClearLine(localPlayer.Character, character, part.Position, shotOrigin)
                            if clear then
                                bestDistance = distance
                                bestPlayer = player
                                bestPart = part
                            end
                        end
                    end
                end
            end
        end
    end
    return bestPlayer, bestPart
end
local function chooseTarget(config, shotOrigin)
    local lockedPlayer, lockedPart, lockIsActive = chooseLockedAimTarget(config, shotOrigin)
    if lockIsActive then
        return lockedPlayer, lockedPart
    end
    return chooseRoleTarget(config, shotOrigin)
end
FastCast.Fire = function(self, origin, direction, velocity, behavior)
    local config = env.__BloodDebtBulletRedirectConfig
    if config and config.Enabled then
        local target, targetPart = chooseTarget(config, origin)
        local hitChance = math.clamp(tonumber(config.HitChance) or 100, 0, 100)
        if target and targetPart and math.random(1, 100) <= hitChance then
            local offset = targetPart.Position - origin
            if offset.Magnitude > 0.05 then
                local redirectedDirection = offset.Unit * 1000
                direction = redirectedDirection
                velocity = redirectedDirection * 9e9
            end
        end
    end
    return originalFire(self, origin, direction, velocity, behavior)
end
env.__BloodDebtRedirectFastCast = FastCast
env.__BloodDebtRedirectHookInstalled = true
]=]

local function serializeTargetNames(targetNames)
    local names = {}
    for name in pairs(targetNames) do
        table.insert(names, name)
    end
    table.sort(names)
    local entries = {}
    for _, name in ipairs(names) do
        table.insert(entries, "[" .. string.format("%q", name) .. "]=true")
    end
    return "{" .. table.concat(entries, ",") .. "}"
end

local function buildRedirectConfigSource(targetNames)
    local lockUserId = 0
    local lockPartName = Config.BulletRedirectTargetPart
    if Config.BulletRedirectFollowAimlock and aimlockHeld and AIMLOCK_IS_LOCKED and AIMLOCK_LOCKED_PLAYER and AIMLOCK_LOCKED_PART_NAME then
        lockUserId = tonumber(AIMLOCK_LOCKED_PLAYER.UserId) or 0
        lockPartName = tostring(AIMLOCK_LOCKED_PART_NAME)
    end
    return string.format([[
local env = (type(getgenv) == "function" and getgenv()) or _G
env.__BloodDebtBulletRedirectConfig = {
    Enabled = %s,
    HitChance = %d,
    Wallcheck = %s,
    TargetPart = %q,
    Radius = %d,
    ValidTargets = %s,
    FollowAimlock = %s,
    LockTargetUserId = %d,
    LockTargetPart = %q,
}
]],
        tostring(Config.BulletRedirectEnabled),
        math.clamp(tonumber(Config.BulletRedirectHitChance) or 100, 0, 100),
        tostring(Config.BulletRedirectWallcheck),
        tostring(Config.BulletRedirectTargetPart),
        math.max(0, math.floor(tonumber(Config.BulletRedirectRadius) or 150)),
        serializeTargetNames(targetNames),
        tostring(Config.BulletRedirectFollowAimlock),
        lockUserId,
        lockPartName
    )
end

local function targetMatchesMode(role)
    local mode = Config.BulletRedirectTargetRole
    if mode == "All" then
        return true
    elseif mode == "Killer" then
        return isKillerRole(role)
    elseif mode == "Vigilante" then
        return isVigilanteRole(role)
    elseif mode == "Innocent" then
        return isInnocentRole(role)
    end
    return false
end

local function collectValidRedirectTargets()
    local validTargets = {}
    if not isMatchActive() then
        return validTargets
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not isLobbyPlayer(player, player.Character) then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local role = getRole(player)
                if targetMatchesMode(role) then
                    validTargets[player.Name] = true
                end
            end
        end
    end
    return validTargets
end

local function runBulletRedirectSync()
    if not ScriptAlive or not Config.ScriptReady then
        return
    end
    local actorRunner = executorRunOnActor
    if type(actorRunner) ~= "function" and type(run_on_thread) == "function" then
        actorRunner = run_on_thread
    end
    if type(actorRunner) ~= "function" or type(getActiveWeaponActors) ~= "function" then
        if Config.BulletRedirectEnabled and not redirectWarningShown then
            redirectWarningShown = true
            notify("Bullet Redirect Unavailable", "This executor does not expose actor execution support. The redirect hook cannot be installed.", Icons.Warning, Sounds.WindowsNotification)
        end
        return
    end
    local actors = getActiveWeaponActors()
    if #actors == 0 then
        return
    end
    local aimlockTargetActive = Config.BulletRedirectFollowAimlock and aimlockHeld and AIMLOCK_IS_LOCKED and AIMLOCK_LOCKED_PLAYER ~= nil
    local targetNames = Config.BulletRedirectEnabled and not aimlockTargetActive and collectValidRedirectTargets() or {}
    local configSource = buildRedirectConfigSource(targetNames)
    local now = os.clock()
    for _, weaponActor in ipairs(actors) do
        if isAliveLocalWeaponActor(weaponActor) then
            local lastInjection = redirectActorLastInjection[weaponActor] or 0
            if not redirectActorInjected[weaponActor] or now - lastInjection >= 4 then
                local injected, injectionError = pcall(actorRunner, weaponActor, BULLET_REDIRECT_ACTOR_SOURCE)
                if injected then
                    redirectActorInjected[weaponActor] = true
                    redirectActorLastInjection[weaponActor] = now
                else
                    warn("[BloodDebt Redirect] Actor hook injection failed: " .. tostring(injectionError))
                end
            end
            local configOK, configError = pcall(actorRunner, weaponActor, configSource)
            if not configOK then
                warn("[BloodDebt Redirect] Could not update actor targeting configuration: " .. tostring(configError))
            end
        end
    end
end

local function setBulletRedirectEnabled(enabled, notifyUser)
    Config.BulletRedirectEnabled = enabled == true
    refreshUIButtons()
    if refreshAdvancedOptions then
        refreshAdvancedOptions()
    end
    runBulletRedirectSync()
    if notifyUser then
        notify(
            Config.BulletRedirectEnabled and "Bullet Redirect Enabled" or "Bullet Redirect Disabled",
            Config.BulletRedirectEnabled and "Redirect prioritizes your active aimlock target; otherwise it uses the selected role." or "Projectile redirection has been disabled.",
            Config.BulletRedirectEnabled and Icons.Success or Icons.Info,
            Sounds.Notification
        )
    end
end

local BulletRedirectFOVCircle = Instance.new("Frame")
BulletRedirectFOVCircle.Name = "BulletRedirectFOV"
BulletRedirectFOVCircle.AnchorPoint = Vector2.new(0, 0)
BulletRedirectFOVCircle.BackgroundTransparency = 1
BulletRedirectFOVCircle.BorderSizePixel = 0
BulletRedirectFOVCircle.Visible = false
BulletRedirectFOVCircle.ZIndex = 4
BulletRedirectFOVCircle.Parent = ScreenGui
local BulletRedirectFOVCorner = Instance.new("UICorner")
BulletRedirectFOVCorner.CornerRadius = UDim.new(1, 0)
BulletRedirectFOVCorner.Parent = BulletRedirectFOVCircle
local BulletRedirectFOVStroke = Instance.new("UIStroke")
BulletRedirectFOVStroke.Color = Color3.fromRGB(255, 255, 255)
BulletRedirectFOVStroke.Thickness = 1.5
BulletRedirectFOVStroke.Transparency = 0.2
BulletRedirectFOVStroke.Parent = BulletRedirectFOVCircle

local function updateBulletRedirectFOV()
    local radius = math.clamp(tonumber(Config.BulletRedirectRadius) or 150, 0, 600)
    local center = getViewportCenter()
    if not center then
        BulletRedirectFOVCircle.Visible = false
        return
    end
    BulletRedirectFOVCircle.Size = UDim2.fromOffset(radius * 2, radius * 2)
    BulletRedirectFOVCircle.Position = UDim2.fromOffset(center.X - radius, center.Y - radius)
    BulletRedirectFOVCircle.Visible = Config.BulletRedirectEnabled and Config.BulletRedirectFOVVisible and radius > 0
end

trackConnection(RunService.RenderStepped:Connect(updateBulletRedirectFOV))

local originalRefreshUIButtons = refreshUIButtons
refreshUIButtons = function()
    originalRefreshUIButtons()
    if BulletRedirectIconButton then
        updateIconButtonColor(BulletRedirectIconButton, Config.BulletRedirectEnabled)
    end
    if WeaponESPToggleButton then
        updateTextToggleColor(WeaponESPToggleButton, "Role Weapon ESP", Config.WeaponHighlight)
    end
    if GroundGunTPButton then
        GroundGunTPButton.Text = IS_MOBILE and "Dropped Role Weapon TP (D-Pad Right)" or "Teleport to Dropped Role Weapon (D-Pad Right)"
    end
end

local oldToolbarSize = Toolbar.Size
Toolbar.Size = IS_MOBILE and UDim2.fromOffset(54, 202) or UDim2.fromOffset(216, 58)
BulletRedirectIconButton = createIconButton(Toolbar, "BulletRedirectButton", Icons.Crosshair)

local redirectSettingsHeight = IS_MOBILE and 344 or 354
SettingsPanel.Size = UDim2.fromOffset(panelWidth, redirectSettingsHeight)
if IS_MOBILE then
    SettingsPanel.Position = UDim2.new(0, mobilePanelX, 0.5, -redirectSettingsHeight / 2)
else
    SettingsPanel.Position = UDim2.new(0.5, -panelWidth / 2, 0, 82)
end

local AdvancedOptionsButton = createTextButton(
    SettingsPanel,
    "AdvancedOptionsButton",
    "Advanced ESP and Redirect Settings",
    UDim2.fromOffset(12, IS_MOBILE and 296 or 308)
)

local currentViewport = getViewportSize()
local advancedPanelWidth = math.max(190, math.min(286, currentViewport.X - 20))
local advancedPanelHeight = math.min(380, currentViewport.Y - 24)
local AdvancedPanel = Instance.new("Frame")
AdvancedPanel.Name = "BloodDebtAdvancedPanel"
AdvancedPanel.Size = UDim2.fromOffset(advancedPanelWidth, advancedPanelHeight)
AdvancedPanel.AnchorPoint = Vector2.new(0.5, 0.5)
AdvancedPanel.Position = UDim2.fromScale(0.5, 0.5)
AdvancedPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
AdvancedPanel.BorderSizePixel = 0
AdvancedPanel.Visible = false
AdvancedPanel.ZIndex = 50
AdvancedPanel.Parent = ScreenGui
createCorner(AdvancedPanel, 14)
createStroke(AdvancedPanel, Color3.fromRGB(255, 45, 65), 1.5)

local AdvancedTitle = Instance.new("TextLabel")
AdvancedTitle.BackgroundTransparency = 1
AdvancedTitle.Position = UDim2.fromOffset(14, 10)
AdvancedTitle.Size = UDim2.new(1, -56, 0, 25)
AdvancedTitle.Font = Enum.Font.GothamBold
AdvancedTitle.Text = "Advanced Settings"
AdvancedTitle.TextColor3 = Color3.new(1, 1, 1)
AdvancedTitle.TextSize = IS_MOBILE and 13 or 15
AdvancedTitle.TextXAlignment = Enum.TextXAlignment.Left
AdvancedTitle.ZIndex = 51
AdvancedTitle.Parent = AdvancedPanel

local AdvancedCloseButton = Instance.new("TextButton")
AdvancedCloseButton.Name = "AdvancedCloseButton"
AdvancedCloseButton.Size = UDim2.fromOffset(24, 24)
AdvancedCloseButton.Position = UDim2.new(1, -34, 0, 10)
AdvancedCloseButton.BackgroundColor3 = Color3.fromRGB(170, 35, 50)
AdvancedCloseButton.BorderSizePixel = 0
AdvancedCloseButton.Text = "×"
AdvancedCloseButton.TextSize = 16
AdvancedCloseButton.TextColor3 = Color3.new(1, 1, 1)
AdvancedCloseButton.Font = Enum.Font.GothamBold
AdvancedCloseButton.ZIndex = 52
AdvancedCloseButton.Parent = AdvancedPanel
createCorner(AdvancedCloseButton, 12)

local AdvancedDescription = Instance.new("TextLabel")
AdvancedDescription.BackgroundTransparency = 1
AdvancedDescription.Position = UDim2.fromOffset(14, 35)
AdvancedDescription.Size = UDim2.new(1, -28, 0, 18)
AdvancedDescription.Font = Enum.Font.Gotham
AdvancedDescription.Text = "Prioritizes your locked aim target, then the selected role."
AdvancedDescription.TextColor3 = Color3.fromRGB(175, 180, 190)
AdvancedDescription.TextSize = IS_MOBILE and 8 or 9
AdvancedDescription.TextXAlignment = Enum.TextXAlignment.Left
AdvancedDescription.TextTruncate = Enum.TextTruncate.AtEnd
AdvancedDescription.ZIndex = 51
AdvancedDescription.Parent = AdvancedPanel

local AdvancedOptionsScroll = Instance.new("ScrollingFrame")
AdvancedOptionsScroll.Name = "AdvancedOptionsScroll"
AdvancedOptionsScroll.Position = UDim2.fromOffset(10, 57)
AdvancedOptionsScroll.Size = UDim2.new(1, -20, 1, -67)
AdvancedOptionsScroll.BackgroundTransparency = 1
AdvancedOptionsScroll.BorderSizePixel = 0
AdvancedOptionsScroll.ScrollBarThickness = 3
AdvancedOptionsScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 75, 90)
AdvancedOptionsScroll.CanvasSize = UDim2.fromOffset(0, 0)
AdvancedOptionsScroll.ZIndex = 51
AdvancedOptionsScroll.Parent = AdvancedPanel

local advancedButtons = {}
local function createAdvancedOption(name, y, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Position = UDim2.fromOffset(4, y)
    button.Size = UDim2.new(1, -12, 0, 29)
    button.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = IS_MOBILE and 9 or 11
    button.Font = Enum.Font.GothamSemibold
    button.TextXAlignment = Enum.TextXAlignment.Center
    button.TextYAlignment = Enum.TextYAlignment.Center
    button.TextTruncate = Enum.TextTruncate.AtEnd
    button.AutoButtonColor = true
    button.ZIndex = 52
    button.Parent = AdvancedOptionsScroll
    createCorner(button, 8)
    trackConnection(button.Activated:Connect(callback))
    table.insert(advancedButtons, button)
    return button
end

local function getAdvancedButton(index)
    return advancedButtons[index]
end

refreshAdvancedOptions = function()
    local texts = {
        "Bullet Redirect: " .. (Config.BulletRedirectEnabled and "ON" or "OFF"),
        "Target Role: " .. Config.BulletRedirectTargetRole,
        "Hit Chance: " .. tostring(Config.BulletRedirectHitChance) .. "%",
        "Wallcheck: " .. (Config.BulletRedirectWallcheck and "ON" or "OFF"),
        "Target Part: " .. Config.BulletRedirectTargetPart,
        "FOV Radius: " .. (Config.BulletRedirectRadius == 0 and "Unlimited" or tostring(Config.BulletRedirectRadius)),
        "FOV Visible: " .. (Config.BulletRedirectFOVVisible and "ON" or "OFF"),
        "Hint Match ESP: " .. (Config.HintESPEnabled and "ON" or "OFF"),
        "Nametag Display: " .. nametagMode,
        "Follow Aimlock Target: " .. (Config.BulletRedirectFollowAimlock and "ON" or "OFF"),
    }
    for index, text in ipairs(texts) do
        local button = getAdvancedButton(index)
        if button then
            button.Text = text
            if index == 1 and Config.BulletRedirectEnabled then
                button.BackgroundColor3 = Color3.fromRGB(145, 30, 48)
            elseif (index == 4 and Config.BulletRedirectWallcheck)
                or (index == 7 and Config.BulletRedirectFOVVisible)
                or (index == 8 and Config.HintESPEnabled)
                or (index == 10 and Config.BulletRedirectFollowAimlock) then
                button.BackgroundColor3 = Color3.fromRGB(95, 55, 65)
            else
                button.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
            end
        end
    end
    updateBulletRedirectFOV()
end

createAdvancedOption("RedirectToggle", 4, function()
    setBulletRedirectEnabled(not Config.BulletRedirectEnabled, true)
end)
createAdvancedOption("RedirectRole", 37, function()
    local index = table.find(redirectRoleOptions, Config.BulletRedirectTargetRole) or 1
    Config.BulletRedirectTargetRole = redirectRoleOptions[index % #redirectRoleOptions + 1]
    refreshAdvancedOptions()
    runBulletRedirectSync()
end)
createAdvancedOption("RedirectHitChance", 70, function()
    local index = table.find(redirectHitChanceOptions, Config.BulletRedirectHitChance) or 1
    Config.BulletRedirectHitChance = redirectHitChanceOptions[index % #redirectHitChanceOptions + 1]
    refreshAdvancedOptions()
    runBulletRedirectSync()
end)
createAdvancedOption("RedirectWallcheck", 103, function()
    Config.BulletRedirectWallcheck = not Config.BulletRedirectWallcheck
    refreshAdvancedOptions()
    runBulletRedirectSync()
end)
createAdvancedOption("RedirectTargetPart", 136, function()
    local index = table.find(redirectPartOptions, Config.BulletRedirectTargetPart) or 1
    Config.BulletRedirectTargetPart = redirectPartOptions[index % #redirectPartOptions + 1]
    refreshAdvancedOptions()
    runBulletRedirectSync()
end)
createAdvancedOption("RedirectFOVRadius", 169, function()
    local index = table.find(redirectRadiusOptions, Config.BulletRedirectRadius) or 2
    Config.BulletRedirectRadius = redirectRadiusOptions[index % #redirectRadiusOptions + 1]
    refreshAdvancedOptions()
    runBulletRedirectSync()
end)
createAdvancedOption("RedirectFOVVisible", 202, function()
    Config.BulletRedirectFOVVisible = not Config.BulletRedirectFOVVisible
    refreshAdvancedOptions()
end)
createAdvancedOption("HintESP", 235, function()
    Config.HintESPEnabled = not Config.HintESPEnabled
    if not Config.HintESPEnabled then
        table.clear(hintMatchPlayers)
    end
    refreshAdvancedOptions()
    updateESP()
end)
createAdvancedOption("NametagMode", 268, function()
    local options = { "Role", "Username", "Character Name" }
    local index = table.find(options, nametagMode) or 1
    nametagMode = options[index % #options + 1]
    refreshAdvancedOptions()
    updateESP()
end)
createAdvancedOption("FollowAimlockTarget", 301, function()
    Config.BulletRedirectFollowAimlock = not Config.BulletRedirectFollowAimlock
    refreshAdvancedOptions()
    runBulletRedirectSync()
end)
AdvancedOptionsScroll.CanvasSize = UDim2.fromOffset(0, 336)

refreshAdvancedOptions()

trackConnection(AdvancedOptionsButton.Activated:Connect(function()
    if not Config.ScriptReady then
        return
    end
    redirectPanelWasOpenedFromSettings = true
    SettingsPanel.Visible = false
    AdvancedPanel.Visible = true
    refreshAdvancedOptions()
    refreshUIButtons()
end))

trackConnection(AdvancedCloseButton.Activated:Connect(function()
    AdvancedPanel.Visible = false
    if redirectPanelWasOpenedFromSettings then
        SettingsPanel.Visible = true
    end
    refreshUIButtons()
end))

trackConnection(BulletRedirectIconButton.Activated:Connect(function()
    if not Config.ScriptReady then
        return
    end
    setBulletRedirectEnabled(not Config.BulletRedirectEnabled, true)
end))

trackConnection(HideToolbarButton.Activated:Connect(function()
    AdvancedPanel.Visible = false
end))

trackConnection(PanelCloseButton.Activated:Connect(function()
    AdvancedPanel.Visible = false
end))

refreshUIButtons()

if type(executorRunOnActor) ~= "function" and type(run_on_thread) == "function" then
    executorRunOnActor = run_on_thread
end

task.spawn(function()
    while ScriptAlive and ScreenGui and ScreenGui.Parent do
        runBulletRedirectSync()
        local lockSyncActive = Config.BulletRedirectEnabled and Config.BulletRedirectFollowAimlock and aimlockHeld
        task.wait(lockSyncActive and 0.1 or 0.35)
    end
end)

local previousCleanup = GLOBAL_ENV.__BloodDebtCleanup
GLOBAL_ENV.__BloodDebtCleanup = function()
    Config.BulletRedirectEnabled = false
    pcall(runBulletRedirectSync)
    if BulletRedirectFOVCircle and BulletRedirectFOVCircle.Parent then
        BulletRedirectFOVCircle:Destroy()
    end
    clearAdditionalRoleWeaponHighlights()
    if previousCleanup then
        previousCleanup()
    end
end
