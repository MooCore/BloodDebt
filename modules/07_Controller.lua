qBusy = false
virtualInput = nil
virtualInputUnavailableWarned = false
executorKeyPress = type(keypress) == "function" and keypress or nil
executorKeyRelease = type(keyrelease) == "function" and keyrelease or nil
executorMouseMove = type(mousemoveabs) == "function" and mousemoveabs or nil
virtualInputOK, virtualInputResult = pcall(function()
    return UserInputService:CreateVirtualInput()
end)
if virtualInputOK then
    virtualInput = virtualInputResult
end

function raycastFromCrosshair()
    local camera = Workspace.CurrentCamera
    local center = getViewportCenter()
    if not camera or not center then
        return nil, nil
    end
    local unitRay = camera:ViewportPointToRay(center.X, center.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    if LocalPlayer.Character then
        raycastParams.FilterDescendantsInstances = { LocalPlayer.Character }
    else
        raycastParams.FilterDescendantsInstances = {}
    end
    raycastParams.IgnoreWater = true
    local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, raycastParams)
    return result, center
end

function isPlayerCharacterPart(instance)
    local current = instance
    while current and current ~= Workspace do
        if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
            return Players:GetPlayerFromCharacter(current) ~= nil
        end
        current = current.Parent
    end
    return false
end

function getPromptFromHit(hitInstance)
    local current = hitInstance
    while current and current ~= Workspace do
        local prompt = current:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            return prompt
        end
        current = current.Parent
    end
    return nil
end

function activateProximityPrompt(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then
        return false
    end
    if type(fireproximityprompt) == "function" then
        local ok = pcall(fireproximityprompt, prompt)
        if ok then
            return true
        end
    end
    local beganOK = pcall(function()
        prompt:InputHoldBegin()
    end)
    if not beganOK then
        return false
    end
    local holdTime = math.max(prompt.HoldDuration, 0.05)
    task.delay(holdTime, function()
        if prompt and prompt.Parent then
            pcall(function()
                prompt:InputHoldEnd()
            end)
        end
    end)
    return true
end

function sendQToGame(center)
    if executorKeyPress and executorKeyRelease and executorMouseMove then
        task.spawn(function()
            local ok, err = pcall(function()
                executorMouseMove(center.X, center.Y)
                RunService.RenderStepped:Wait()
                executorKeyPress(0x51)
                task.wait(0.06)
                executorKeyRelease(0x51)
            end)
            if not ok then
                warn("[BloodDebt] Executor key bridge failed: " .. tostring(err))
            end
        end)
        return true
    end
    if virtualInput then
        task.spawn(function()
            local ok, err = pcall(function()
                virtualInput:SendMousePosition(center)
                RunService.RenderStepped:Wait()
                virtualInput:SendKey(true, Enum.KeyCode.Q, false)
                task.wait(0.06)
                virtualInput:SendKey(false, Enum.KeyCode.Q, false)
            end)
            if not ok then
                warn("[BloodDebt] Could not send virtual Q input: " .. tostring(err))
            end
        end)
        return true
    end
    if not virtualInputUnavailableWarned then
        virtualInputUnavailableWarned = true
        warn("[BloodDebt] No key injection bridge is available. Controller X cannot be converted to Q in this executor/client.")
    end
    return false
end

function findDoorEventFromHit(hitInstance)
    local bloodFolder = Workspace:FindFirstChild("BloodFolder")
    if not bloodFolder or not hitInstance or not hitInstance:IsDescendantOf(bloodFolder) then
        return nil, nil
    end
    local ancestor = hitInstance
    while ancestor and ancestor ~= bloodFolder do
        if string.lower(ancestor.Name) == "lock" then
            local lockEvent = ancestor:FindFirstChild("DoorEventyer", true)
            if lockEvent and lockEvent:IsA("RemoteEvent") then
                return lockEvent, "Lock"
            end
            break
        end
        ancestor = ancestor.Parent
    end
    ancestor = hitInstance
    while ancestor and ancestor ~= bloodFolder do
        local scopeName = string.lower(ancestor.Name)
        if scopeName == "maindoor" or scopeName == "mayndoor" then
            local doorEvents = {}
            for _, descendant in ipairs(ancestor:GetDescendants()) do
                if descendant.Name == "DoorEventyer" and descendant:IsA("RemoteEvent") then
                    local insideLock = false
                    local parent = descendant.Parent
                    while parent and parent ~= ancestor do
                        if string.lower(parent.Name) == "lock" then
                            insideLock = true
                            break
                        end
                        parent = parent.Parent
                    end
                    if not insideLock then
                        table.insert(doorEvents, descendant)
                    end
                end
            end
            if #doorEvents == 1 then
                return doorEvents[1], "Door"
            end
            if #doorEvents > 1 then
                return nil, nil
            end
        end
        ancestor = ancestor.Parent
    end
    ancestor = hitInstance
    while ancestor and ancestor ~= bloodFolder do
        local candidate = ancestor:FindFirstChild("DoorEventyer")
        if candidate and candidate:IsA("RemoteEvent") then
            return candidate, "Door"
        end
        ancestor = ancestor.Parent
    end
    return nil, nil
end

function fireDoorOrLockEvent(hitInstance)
    local event, eventKind = findDoorEventFromHit(hitInstance)
    if not event then
        return false
    end
    local normalId = eventKind == "Lock" and Enum.NormalId.Front or Enum.NormalId.Back
    local ok, err = pcall(function()
        event:FireServer(normalId)
    end)
    if not ok then
        warn("[BloodDebt] " .. eventKind .. " event failed: " .. tostring(err))
        return false
    end
    return true
end

function handleControllerQ()
    if not Config.ScriptReady or qBusy then
        return
    end
    qBusy = true
    task.delay(Q_INPUT_DEBOUNCE, function()
        qBusy = false
    end)
    local result, center = raycastFromCrosshair()
    if not result or not result.Instance or not center then
        return
    end
    if isPlayerCharacterPart(result.Instance) then
        return
    end
    if fireDoorOrLockEvent(result.Instance) then
        return
    end
    if sendQToGame(center) then
        return
    end
    local prompt = getPromptFromHit(result.Instance)
    if prompt then
        activateProximityPrompt(prompt)
    end
end

function toggleAimlockFromController()
    if not Config.ScriptReady then
        return
    end
    Config.AimlockEnabled = not Config.AimlockEnabled
    if Config.AimlockEnabled then
        startAimlockHold()
    else
        stopAimlockHold()
    end
    if refreshUIButtons then
        refreshUIButtons()
    end
    notify(
        Config.AimlockEnabled and "Aimlock Enabled" or "Aimlock Disabled",
        Config.AimlockEnabled and "Aimlock is enabled. Hold L2 to activate it." or "Aimlock has been disabled.",
        Config.AimlockEnabled and Icons.Success or Icons.Info,
        Sounds.Notification
    )
end

lastDPadLeftAt = 0
lastDPadRightAt = 0
lastDPadDownAt = 0
CONTROLLER_PRESS_DEBOUNCE = 0.20

function onDPadLeftAction(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        local now = os.clock()
        if now - lastDPadLeftAt >= CONTROLLER_PRESS_DEBOUNCE then
            lastDPadLeftAt = now
            toggleAimlockFromController()
        end
    end
    return Enum.ContextActionResult.Sink
end

function onDPadRightAction(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        local now = os.clock()
        if now - lastDPadRightAt >= CONTROLLER_PRESS_DEBOUNCE then
            lastDPadRightAt = now
            teleportToGroundWeapon()
        end
    end
    return Enum.ContextActionResult.Sink
end

function onDPadDownAction(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        local now = os.clock()
        if now - lastDPadDownAt >= CONTROLLER_PRESS_DEBOUNCE then
            lastDPadDownAt = now
            teleportToKillerEscape()
        end
    end
    return Enum.ContextActionResult.Sink
end

pcall(function()
    ContextActionService:UnbindAction("BloodDebt_ToggleAimlock")
    ContextActionService:UnbindAction("BloodDebt_TeleportToGroundGun")
    ContextActionService:UnbindAction("BloodDebt_TeleportToKillerEscape")
end)

dPadLeftBound = pcall(function()
    ContextActionService:BindActionAtPriority("BloodDebt_ToggleAimlock", onDPadLeftAction, false, Enum.ContextActionPriority.High.Value + 1000, Enum.KeyCode.DPadLeft)
end)
dPadRightBound = pcall(function()
    ContextActionService:BindActionAtPriority("BloodDebt_TeleportToGroundGun", onDPadRightAction, false, Enum.ContextActionPriority.High.Value + 1000, Enum.KeyCode.DPadRight)
end)
dPadDownBound = pcall(function()
    ContextActionService:BindActionAtPriority("BloodDebt_TeleportToKillerEscape", onDPadDownAction, false, Enum.ContextActionPriority.High.Value + 1000, Enum.KeyCode.DPadDown)
end)

if not dPadLeftBound or not dPadRightBound or not dPadDownBound then
    warn("[BloodDebt] Could not bind one or more D-pad actions through ContextActionService.")
end

trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.ButtonL2 then
        aimlockTriggerDown = true
        startAimlockHold()
        return
    end
    if input.KeyCode == Enum.KeyCode.DPadLeft then
        onDPadLeftAction("BloodDebt_ToggleAimlock", Enum.UserInputState.Begin, input)
        return
    elseif input.KeyCode == Enum.KeyCode.DPadRight then
        onDPadRightAction("BloodDebt_TeleportToGroundGun", Enum.UserInputState.Begin, input)
        return
    elseif input.KeyCode == Enum.KeyCode.DPadDown then
        onDPadDownAction("BloodDebt_TeleportToKillerEscape", Enum.UserInputState.Begin, input)
        return
    end
    if input.KeyCode == Enum.KeyCode.ButtonX and Config.ScriptReady then
        handleControllerQ()
    end
end))

trackConnection(UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.ButtonL2 then
        aimlockTriggerDown = false
        stopAimlockHold()
    end
end))

trackConnection(UserInputService.WindowFocusReleased:Connect(function()
    aimlockTriggerDown = false
    stopAimlockHold()
end))

