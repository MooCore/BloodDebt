watchedPlayerContainers = setmetatable({}, { __mode = "k" })

function watchPlayerToolsForHero(player, container)
    if not container or watchedPlayerContainers[container] then
        return
    end
    watchedPlayerContainers[container] = true
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Tool") and isVigilanteWeapon(child.Name) then
            hookVigilanteToolAncestry(child)
            if everDroppedVigilanteTools[child] then
                heroPlayers[player] = child.Name
            elseif not initialVigilanteOwners[child] then
                initialVigilanteOwners[child] = player
            elseif initialVigilanteOwners[child] ~= player then
                heroPlayers[player] = child.Name
            end
        end
    end
    trackPlayerConnection(player, container.ChildAdded:Connect(function(child)
        if not ScriptAlive then
            return
        end
        if child:IsA("Tool") and isVigilanteWeapon(child.Name) then
            hookVigilanteToolAncestry(child)
            if everDroppedVigilanteTools[child] then
                heroPlayers[player] = child.Name
            elseif not initialVigilanteOwners[child] then
                initialVigilanteOwners[child] = player
            elseif initialVigilanteOwners[child] ~= player then
                heroPlayers[player] = child.Name
            end
        end
    end))
end

function bindPlayerESP(player)
    if player == LocalPlayer then
        return
    end
    disconnectPlayerConnections(player)
    if player.Character then
        watchPlayerToolsForHero(player, player.Character)
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        watchPlayerToolsForHero(player, bp)
    end
    trackPlayerConnection(player, player.ChildAdded:Connect(function(child)
        if not ScriptAlive then
            return
        end
        if child.Name == "Backpack" then
            watchPlayerToolsForHero(player, child)
        end
    end))
    trackPlayerConnection(player, player.CharacterRemoving:Connect(function()
        destroyPlayerESP(player)
    end))
    trackPlayerConnection(player, player.CharacterAdded:Connect(function(character)
        heroPlayers[player] = nil
        destroyPlayerESP(player)
        watchPlayerToolsForHero(player, character)
        task.wait(0.8)
        if ScriptAlive and player.Parent == Players and player ~= LocalPlayer then
            createESP(player)
        end
    end))
end

for _, player in ipairs(Players:GetPlayers()) do
    bindPlayerESP(player)
end

trackConnection(Players.PlayerAdded:Connect(bindPlayerESP))

trackConnection(Players.PlayerRemoving:Connect(function(player)
    heroPlayers[player] = nil
    disconnectPlayerConnections(player)
    destroyPlayerESP(player)
end))

GLOBAL_ENV.__BloodDebtCleanup = function()
    ScriptAlive = false
    stopAimlockHold()
    pcall(function()
        RunService:UnbindFromRenderStep("BloodDebt_AimLock")
    end)
    pcall(function()
        ContextActionService:UnbindAction("BloodDebt_ToggleAimlock")
        ContextActionService:UnbindAction("BloodDebt_TeleportToGroundGun")
        ContextActionService:UnbindAction("BloodDebt_TeleportToKillerEscape")
    end)
    for player in pairs(PlayerConnections) do
        disconnectPlayerConnections(player)
    end
    for _, conn in ipairs(ActiveConnections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(ActiveConnections)
    clearAllPlayerESP()
    clearAllWeaponHighlights()
    if ScreenGui and ScreenGui.Parent then
        pcall(function()
            ScreenGui:Destroy()
        end)
    end
end

task.spawn(function()
    while ScriptAlive and ScreenGui.Parent do
        updateESP()
        updateWeaponHighlight()
        checkKillerEscapeAvailability()
        task.wait(0.6)
    end
end)

task.spawn(function()
    while ScriptAlive and ScreenGui.Parent and not Config.ScriptReady do
        task.wait(0.15)
    end
    if not ScriptAlive or not ScreenGui.Parent then
        return
    end
    refreshGroundWeaponRegistry()
    while ScriptAlive and ScreenGui.Parent do
        refreshGroundWeaponRegistry()
        task.wait(0.3)
    end
end)

function disableDefaultGamepadCursor()
    if not GamepadService then
        return
    end
    pcall(function()
        GamepadService:DisableGamepadCursor()
    end)
end

disableDefaultGamepadCursor()

task.spawn(function()
    while ScriptAlive and ScreenGui.Parent do
        disableDefaultGamepadCursor()
        task.wait(0.5)
    end
end)

loadingStartedAt = os.clock()
while ScriptAlive and ScreenGui.Parent do
    local elapsed = os.clock() - loadingStartedAt
    local progress = math.clamp(elapsed / LOADING_DURATION, 0, 1)
    if type(__BloodDebtBootstrapUpdate) == "function" then
        __BloodDebtBootstrapUpdate("Finalizing player detection and interface...", progress)
    end
    if progress >= 1 then
        break
    end
    task.wait(0.03)
end

if not ScriptAlive then
    return
end

Config.ScriptReady = true
Config.ESPEnabled = true
Config.WeaponHighlight = true
Config.AimlockEnabled = true
Config.NREnabled = true
Toolbar.Visible = true
SettingsPanel.Visible = false
ReopenButton.Visible = false
refreshUIButtons()
task.delay(0.6, runNRInjection)

if isMatchActive() then
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            createESP(player)
        end
    end
end

warn("Blood Debt script loaded for PlaceId 79187287306411: responsive UI, map-aware role ESP, sound notifications, controller support, and post-match cleanup.")
