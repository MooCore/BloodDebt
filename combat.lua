return function(ctx)
    local Players = ctx.Players
    local LocalPlayer = ctx.LocalPlayer
    local RunService = ctx.RunService
    local UserInputService = ctx.UserInputService
    local ContextActionService = ctx.ContextActionService
    local Workspace = ctx.Workspace
    local Config = ctx.Config
    local Icons = ctx.Icons
    local Sounds = ctx.Sounds
    local notify = ctx.notify
    local getViewportCenter = ctx.getViewportCenter
    local trackConnection = ctx.trackConnection
    local ESP = ctx.ESP

    local Combat = {}

    local AIMLOCK_RADIUS_PIXELS = math.huge
    local AIMLOCK_SMOOTHING = 14
    local AIMLOCK_RESCAN_INTERVAL = 0.035
    local AIMLOCK_SWITCH_MARGIN = 10
    local Q_INPUT_DEBOUNCE = 0.20
    local CONTROLLER_PRESS_DEBOUNCE = 0.20

    local aimlockHeld = false
    local aimlockTriggerDown = false
    local aimTargetPlayer = nil
    local aimTargetPart = nil
    local smoothedAimPosition = nil
    local nextAimScanAt = 0

    local function getCharacterParts(player)
        if not player or player == LocalPlayer then
            return nil, nil, nil, nil
        end

        local character = player.Character

        if not character or not character.Parent then
            return nil, nil, nil, nil
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local head = character:FindFirstChild("Head")
        local rootPart = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or humanoid.Health <= 0 or (not head and not rootPart) then
            return nil, nil, nil, nil
        end

        return character, humanoid, head, rootPart
    end

    local function getClosestAimPartToCrosshair()
        local camera = Workspace.CurrentCamera
        local center = getViewportCenter()

        if not camera or not center then
            return nil, nil, math.huge
        end

        local bestPlayer = nil
        local bestPart = nil
        local bestDistance = AIMLOCK_RADIUS_PIXELS

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character, _, head, rootPart = getCharacterParts(player)

                if character then
                    local candidates = {}

                    if head then
                        table.insert(candidates, head)
                    end

                    if rootPart then
                        table.insert(candidates, rootPart)
                    end

                    for _, targetPart in ipairs(candidates) do
                        local screenPosition, _ = camera:WorldToViewportPoint(targetPart.Position)

                        if screenPosition.Z > 0 then
                            local screenDistance = (
                                Vector2.new(screenPosition.X, screenPosition.Y) - center
                            ).Magnitude

                            if screenDistance < bestDistance then
                                bestDistance = screenDistance
                                bestPlayer = player
                                bestPart = targetPart
                            end
                        end
                    end
                end
            end
        end

        return bestPlayer, bestPart, bestDistance
    end

    local function getScreenDistance(part, camera)
        if not part or not part.Parent or not camera then
            return math.huge
        end

        local center = getViewportCenter()

        if not center then
            return math.huge
        end

        local screenPosition, _ = camera:WorldToViewportPoint(part.Position)

        if screenPosition.Z <= 0 then
            return math.huge
        end

        return (Vector2.new(screenPosition.X, screenPosition.Y) - center).Magnitude
    end

    local function isAimTargetValid()
        if not aimTargetPlayer or not aimTargetPart then
            return false
        end

        local character, humanoid = getCharacterParts(aimTargetPlayer)

        return character ~= nil
            and humanoid ~= nil
            and aimTargetPart.Parent ~= nil
            and aimTargetPart:IsDescendantOf(character)
    end

    local function startAimlockHold()
        if not Config.ScriptReady or not Config.AimlockEnabled or not aimlockTriggerDown then
            return
        end

        aimlockHeld = true
        aimTargetPlayer, aimTargetPart = getClosestAimPartToCrosshair()
        smoothedAimPosition = aimTargetPart and aimTargetPart.Position or nil
        nextAimScanAt = 0
    end

    local function stopAimlockHold()
        aimlockHeld = false
        aimTargetPlayer = nil
        aimTargetPart = nil
        smoothedAimPosition = nil
    end

    Combat.startAimlockHold = startAimlockHold
    Combat.stopAimlockHold = stopAimlockHold

    pcall(function()
        RunService:UnbindFromRenderStep("BloodDebt_AimLock")
    end)

    RunService:BindToRenderStep(
        "BloodDebt_AimLock",
        Enum.RenderPriority.Camera.Value + 1,
        function(deltaTime)
            if not Config.AimlockEnabled or not Config.ScriptReady or not aimlockHeld or not ctx.ScriptAlive then
                return
            end

            local camera = Workspace.CurrentCamera

            if not camera then
                return
            end

            local now = os.clock()

            if now >= nextAimScanAt then
                nextAimScanAt = now + AIMLOCK_RESCAN_INTERVAL

                local candidatePlayer, candidatePart, candidateDistance = getClosestAimPartToCrosshair()

                if candidatePlayer and candidatePart then
                    local currentDistance = getScreenDistance(aimTargetPart, camera)
                    local sameCandidate = candidatePlayer == aimTargetPlayer
                        and candidatePart == aimTargetPart

                    local switchMargin = candidatePlayer == aimTargetPlayer and 3 or AIMLOCK_SWITCH_MARGIN

                    if not isAimTargetValid()
                        or sameCandidate
                        or candidateDistance + switchMargin < currentDistance then

                        if not sameCandidate then
                            aimTargetPlayer = candidatePlayer
                            aimTargetPart = candidatePart
                        end
                    end

                elseif not isAimTargetValid() then
                    aimTargetPlayer = nil
                    aimTargetPart = nil
                end
            end

            if not isAimTargetValid() then
                aimTargetPlayer, aimTargetPart = getClosestAimPartToCrosshair()
                smoothedAimPosition = nil
            end

            if not aimTargetPart then
                return
            end

            local targetPosition = aimTargetPart.Position
            local dt = math.clamp(tonumber(deltaTime) or 0.016, 0.0001, 0.25)
            local positionAlpha = math.clamp(1 - math.exp(-AIMLOCK_SMOOTHING * dt), 0, 1)

            if not smoothedAimPosition then
                smoothedAimPosition = targetPosition
            else
                smoothedAimPosition = smoothedAimPosition:Lerp(targetPosition, positionAlpha)
            end

            local camPos = camera.CFrame.Position
            local offset = smoothedAimPosition - camPos

            if offset.Magnitude < 0.05 or offset.X ~= offset.X then
                return
            end

            local desiredCFrame = CFrame.lookAt(
                camPos,
                smoothedAimPosition,
                Vector3.yAxis
            )

            camera.CFrame = camera.CFrame:Lerp(desiredCFrame, positionAlpha)
        end
    )

    local qBusy = false
    local virtualInput = nil
    local virtualInputUnavailableWarned = false
    local executorKeyPress = type(keypress) == "function" and keypress or nil
    local executorKeyRelease = type(keyrelease) == "function" and keyrelease or nil
    local executorMouseMove = type(mousemoveabs) == "function" and mousemoveabs or nil

    local virtualInputOK, virtualInputResult = pcall(function()
        return UserInputService:CreateVirtualInput()
    end)

    if virtualInputOK then
        virtualInput = virtualInputResult
    end

    local function raycastFromCrosshair()
        local camera = Workspace.CurrentCamera
        local center = getViewportCenter()

        if not camera or not center then
            return nil, nil
        end

        local unitRay = camera:ViewportPointToRay(center.X, center.Y)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        if LocalPlayer.Character then
            raycastParams.FilterDescendantsInstances = {
                LocalPlayer.Character,
            }
        else
            raycastParams.FilterDescendantsInstances = {}
        end

        raycastParams.IgnoreWater = true

        local result = Workspace:Raycast(
            unitRay.Origin,
            unitRay.Direction * 500,
            raycastParams
        )

        return result, center
    end

    local function isPlayerCharacterPart(instance)
        local current = instance

        while current and current ~= Workspace do
            if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
                return Players:GetPlayerFromCharacter(current) ~= nil
            end

            current = current.Parent
        end

        return false
    end

    local function getPromptFromHit(hitInstance)
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

    local function activateProximityPrompt(prompt)
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

    local function sendQToGame(center)
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

            warn(
                "[BloodDebt] No key injection bridge is available. Controller X cannot be converted to Q in this executor/client."
            )
        end

        return false
    end

    local function findDoorEventFromHit(hitInstance)
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
                    if descendant.Name == "DoorEventyer"
                        and descendant:IsA("RemoteEvent") then

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

    local function fireDoorOrLockEvent(hitInstance)
        local event, eventKind = findDoorEventFromHit(hitInstance)

        if not event then
            return false
        end

        local normalId = eventKind == "Lock"
            and Enum.NormalId.Front
            or Enum.NormalId.Back

        local ok, err = pcall(function()
            event:FireServer(normalId)
        end)

        if not ok then
            warn("[BloodDebt] " .. eventKind .. " event failed: " .. tostring(err))
            return false
        end

        return true
    end

    local function handleControllerQ()
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

    local function toggleAimlockFromController()
        if not Config.ScriptReady then
            return
        end

        Config.AimlockEnabled = not Config.AimlockEnabled

        if Config.AimlockEnabled then
            startAimlockHold()
        else
            stopAimlockHold()
        end

        if ctx.refreshUIButtons then
            ctx.refreshUIButtons()
        end

        notify(
            Config.AimlockEnabled and "Aimlock Enabled" or "Aimlock Disabled",
            Config.AimlockEnabled and "Aimlock is enabled. Hold L2 to activate it." or "Aimlock has been disabled.",
            Config.AimlockEnabled and Icons.Success or Icons.Info,
            Sounds.Notification
        )
    end

    local lastDPadLeftAt = 0
    local lastDPadRightAt = 0
    local lastDPadDownAt = 0

    local function onDPadLeftAction(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            local now = os.clock()

            if now - lastDPadLeftAt >= CONTROLLER_PRESS_DEBOUNCE then
                lastDPadLeftAt = now
                toggleAimlockFromController()
            end
        end

        return Enum.ContextActionResult.Sink
    end

    local function onDPadRightAction(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            local now = os.clock()

            if now - lastDPadRightAt >= CONTROLLER_PRESS_DEBOUNCE then
                lastDPadRightAt = now
                ESP.teleportToGroundWeapon()
            end
        end

        return Enum.ContextActionResult.Sink
    end

    local function onDPadDownAction(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            local now = os.clock()

            if now - lastDPadDownAt >= CONTROLLER_PRESS_DEBOUNCE then
                lastDPadDownAt = now
                ESP.teleportToKillerEscape()
            end
        end

        return Enum.ContextActionResult.Sink
    end

    pcall(function()
        ContextActionService:UnbindAction("BloodDebt_ToggleAimlock")
        ContextActionService:UnbindAction("BloodDebt_TeleportToGroundGun")
        ContextActionService:UnbindAction("BloodDebt_TeleportToKillerEscape")
    end)

    local dPadLeftBound = pcall(function()
        ContextActionService:BindActionAtPriority(
            "BloodDebt_ToggleAimlock",
            onDPadLeftAction,
            false,
            Enum.ContextActionPriority.High.Value + 1000,
            Enum.KeyCode.DPadLeft
        )
    end)

    local dPadRightBound = pcall(function()
        ContextActionService:BindActionAtPriority(
            "BloodDebt_TeleportToGroundGun",
            onDPadRightAction,
            false,
            Enum.ContextActionPriority.High.Value + 1000,
            Enum.KeyCode.DPadRight
        )
    end)

    local dPadDownBound = pcall(function()
        ContextActionService:BindActionAtPriority(
            "BloodDebt_TeleportToKillerEscape",
            onDPadDownAction,
            false,
            Enum.ContextActionPriority.High.Value + 1000,
            Enum.KeyCode.DPadDown
        )
    end)

    if not dPadLeftBound or not dPadRightBound or not dPadDownBound then
        warn("[BloodDebt] Could not bind one or more D-pad actions through ContextActionService.")
    end

    trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.ButtonL2 then
            if not gameProcessed then
                aimlockTriggerDown = true
                startAimlockHold()
            end
            return
        end

        if gameProcessed then
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

    local nrNoActorWarned = false
    local nrInjectionQueued = false
    local nrActorAppliedState = setmetatable({}, { __mode = "k" })
    local executorRunOnActor = nil

    pcall(function()
        if type(runonactor) == "function" then
            executorRunOnActor = runonactor
        elseif type(run_on_actor) == "function" then
            executorRunOnActor = run_on_actor
        elseif type(actor) == "table" and type(actor.runonactor) == "function" then
            executorRunOnActor = actor.runonactor
        elseif type(actor) == "table" and type(actor.run_on_actor) == "function" then
            executorRunOnActor = actor.run_on_actor
        end
    end)

    local function isAliveLocalWeaponActor(obj)
        if not obj then
            return false
        end

        local ok, valid = pcall(function()
            if not obj.Parent or not obj:IsA("Actor") then
                return false
            end

            if not obj:FindFirstChild("weap_cl", true) then
                return false
            end

            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            if char and humanoid and humanoid.Health > 0 and obj:IsDescendantOf(char) then
                return true
            end

            local backpack = LocalPlayer:FindFirstChild("Backpack")

            if backpack and obj:IsDescendantOf(backpack) then
                return true
            end

            return false
        end)

        return ok and valid
    end

    local function getActiveWeaponActors()
        local actors = {}
        local seen = {}

        local function scanContainer(container)
            if not container or not container.Parent then
                return
            end

            local ok, descendants = pcall(function()
                return container:GetDescendants()
            end)

            if not ok or not descendants then
                return
            end

            for _, obj in ipairs(descendants) do
                if not seen[obj] and isAliveLocalWeaponActor(obj) then
                    seen[obj] = true
                    table.insert(actors, obj)
                end
            end
        end

        scanContainer(LocalPlayer.Character)
        scanContainer(LocalPlayer:FindFirstChild("Backpack"))

        return actors
    end

    local function makeNRActorSource()
        local recoilScale = Config.NREnabled and 0 or 1
        local disableAnims = Config.NREnabled

        return string.format([[
local RECOIL_SCALE = %f
local DISABLE_ANIMS = %s
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local success, sharedLib = pcall(function()
    local gunRes = ReplicatedStorage:FindFirstChild("gun_res")
    local lib = gunRes and gunRes:FindFirstChild("lib")
    local sharedMod = lib and lib:FindFirstChild("shared")
    return sharedMod and require(sharedMod) or nil
end)

if success and sharedLib and type(sharedLib.getStat) == "function" then
    if not sharedLib._oldGetStat then
        sharedLib._oldGetStat = sharedLib.getStat

        sharedLib.getStat = function(p1, p2, ...)
            local ok, result = pcall(sharedLib._oldGetStat, p1, p2, ...)

            if not ok then
                return nil
            end

            if p2 == "mult" or p2 == "recoilMult" then
                if type(result) == "number" then
                    return result * (sharedLib._RECOIL_SCALE or 1)
                end
            end

            if sharedLib._DISABLE_ANIMS and (p2 == "fire" or p2 == "adsFire" or p2 == "Stockedfire") then
                return ""
            end

            return result
        end
    end

    sharedLib._RECOIL_SCALE = RECOIL_SCALE
    sharedLib._DISABLE_ANIMS = DISABLE_ANIMS
end
]], recoilScale, tostring(disableAnims))
    end

    local function runNRInjection()
        if not Config.ScriptReady or not ctx.ScriptAlive then
            return 0
        end

        if not executorRunOnActor then
            if not nrNoActorWarned then
                nrNoActorWarned = true

                warn(
                    "[BloodDebt NR] This executor does not expose runonactor/run_on_actor. NR cannot inject in this client."
                )
            end

            return 0
        end

        local actors = getActiveWeaponActors()
        local source = makeNRActorSource()
        local injectedCount = 0

        for _, targetActor in ipairs(actors) do
            if isAliveLocalWeaponActor(targetActor)
                and nrActorAppliedState[targetActor] ~= Config.NREnabled then

                local ok, err = pcall(function()
                    executorRunOnActor(targetActor, source)
                end)

                if ok then
                    nrActorAppliedState[targetActor] = Config.NREnabled
                    injectedCount = injectedCount + 1
                else
                    warn("[BloodDebt NR] Actor injection failed: " .. tostring(err))
                end
            end
        end

        if injectedCount > 0 then
            nrNoActorWarned = false
        end

        return injectedCount
    end

    Combat.runNRInjection = runNRInjection

    local function scheduleNRInjection(delaySeconds)
        if nrInjectionQueued or not Config.NREnabled or not ctx.ScriptAlive then
            return
        end

        nrInjectionQueued = true

        task.delay(delaySeconds or 0.55, function()
            nrInjectionQueued = false

            if Config.NREnabled and Config.ScriptReady and ctx.ScriptAlive then
                runNRInjection()
            end
        end)
    end

    local function setNREnabled(enabled, notifyUser)
        Config.NREnabled = enabled == true

        local updatedActors = 0

        if Config.ScriptReady then
            updatedActors = runNRInjection()
        end

        if ctx.refreshUIButtons then
            ctx.refreshUIButtons()
        end

        if notifyUser then
            if Config.NREnabled then
                if updatedActors > 0 then
                    notify(
                        "No Recoil Enabled",
                        "No Recoil is enabled and ready to use.",
                        Icons.Success,
                        Sounds.Notification
                    )
                else
                    notify(
                        "No Recoil Enabled",
                        "No Recoil is enabled and will apply when a firearm is equipped.",
                        Icons.Success,
                        Sounds.Notification
                    )
                end
            else
                notify(
                    "No Recoil Disabled",
                    "No Recoil has been disabled.",
                    Icons.Info,
                    Sounds.Notification
                )
            end
        end
    end

    Combat.setNREnabled = setNREnabled

    local boundContainers = setmetatable({}, { __mode = "k" })

    local function bindNRContainer(container)
        if not container or boundContainers[container] then
            return
        end

        boundContainers[container] = true

        trackConnection(container.DescendantAdded:Connect(function(descendant)
            if not ctx.ScriptAlive then
                return
            end

            if descendant:IsA("Actor") or descendant.Name == "weap_cl" then
                scheduleNRInjection(0.55)
            end
        end))
    end

    bindNRContainer(LocalPlayer.Character)
    bindNRContainer(LocalPlayer:FindFirstChild("Backpack"))

    trackConnection(LocalPlayer.CharacterAdded:Connect(function(character)
        stopAimlockHold()

        task.delay(1.0, function()
            if not ctx.ScriptAlive or not character.Parent then
                return
            end

            bindNRContainer(character)

            local bp = LocalPlayer:FindFirstChild("Backpack")

            if bp then
                bindNRContainer(bp)
            end

            scheduleNRInjection(0.5)
        end)
    end))

    trackConnection(LocalPlayer.ChildAdded:Connect(function(child)
        if child.Name == "Backpack" then
            bindNRContainer(child)
            scheduleNRInjection(0.5)
        end
    end))

    trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not Config.ScriptReady then
            return
        end

        if input.KeyCode == Enum.KeyCode.B then
            setNREnabled(not Config.NREnabled, true)
        end
    end))

    return Combat
end
