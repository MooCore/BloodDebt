aimlockHeld = false
aimlockTriggerDown = false
aimTargetPlayer = nil
aimTargetPart = nil
smoothedAimPosition = nil
nextAimScanAt = 0
aimlockTargetWasAcquired = false
aimlockTargetLost = false
AIMLOCK_LOCKED_PLAYER = nil
AIMLOCK_LOCKED_PART_NAME = nil
AIMLOCK_IS_LOCKED = false
AIMLOCK_CAMERA_STATE = nil

function getCharacterParts(player)
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

function getClosestAimPartToCrosshair()
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
                    local screenPosition = camera:WorldToViewportPoint(targetPart.Position)
                    if screenPosition.Z > 0 then
                        local screenDistance = (Vector2.new(screenPosition.X, screenPosition.Y) - center).Magnitude
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

function getScreenDistance(part, camera)
    if not part or not part.Parent or not camera then
        return math.huge
    end
    local center = getViewportCenter()
    if not center then
        return math.huge
    end
    local screenPosition = camera:WorldToViewportPoint(part.Position)
    if screenPosition.Z <= 0 then
        return math.huge
    end
    return (Vector2.new(screenPosition.X, screenPosition.Y) - center).Magnitude
end

function isAimTargetValid()
    if not aimTargetPlayer or not aimTargetPart then
        return false
    end
    local character, humanoid = getCharacterParts(aimTargetPlayer)
    return character ~= nil and humanoid ~= nil and aimTargetPart.Parent ~= nil and aimTargetPart:IsDescendantOf(character)
end

function publishAimlockTarget()
    if aimlockHeld and isAimTargetValid() then
        AIMLOCK_LOCKED_PLAYER = aimTargetPlayer
        AIMLOCK_LOCKED_PART_NAME = aimTargetPart.Name
        AIMLOCK_IS_LOCKED = true
    else
        AIMLOCK_LOCKED_PLAYER = nil
        AIMLOCK_LOCKED_PART_NAME = nil
        AIMLOCK_IS_LOCKED = false
    end
end

function captureAimlockCamera()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    local localCharacter = LocalPlayer.Character
    local rootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    local offset = nil
    if rootPart then
        offset = rootPart.CFrame:PointToObjectSpace(camera.CFrame.Position)
    end
    AIMLOCK_CAMERA_STATE = {
        Camera = camera,
        CameraType = camera.CameraType,
        CameraSubject = camera.CameraSubject,
        CameraCFrame = camera.CFrame,
        CameraFocus = camera.Focus,
        LocalOffset = offset,
    }
end

function restoreAimlockCamera()
    local saved = AIMLOCK_CAMERA_STATE
    if not saved then
        return
    end
    local camera = Workspace.CurrentCamera
    if camera then
        if saved.Camera == camera then
            pcall(function()
                camera.CameraType = saved.CameraType or Enum.CameraType.Custom
                if saved.CameraSubject then
                    camera.CameraSubject = saved.CameraSubject
                end
                camera.CFrame = saved.CameraCFrame
                camera.Focus = saved.CameraFocus
            end)
        else
            pcall(function()
                camera.CameraType = Enum.CameraType.Custom
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    camera.CameraSubject = humanoid
                end
            end)
        end
    end
    AIMLOCK_CAMERA_STATE = nil
end

function updateAimlockCamera(targetPosition, deltaTime)
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    if not AIMLOCK_CAMERA_STATE or AIMLOCK_CAMERA_STATE.Camera ~= camera then
        if AIMLOCK_CAMERA_STATE then
            restoreAimlockCamera()
        end
        captureAimlockCamera()
    end
    local saved = AIMLOCK_CAMERA_STATE
    if not saved then
        return
    end
    local localCharacter = LocalPlayer.Character
    local rootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    local cameraPosition = camera.CFrame.Position
    if rootPart and saved.LocalOffset then
        cameraPosition = rootPart.CFrame:PointToWorldSpace(saved.LocalOffset)
    end
    local offset = targetPosition - cameraPosition
    if offset.Magnitude < 0.05 or offset.X ~= offset.X or offset.Y ~= offset.Y or offset.Z ~= offset.Z then
        return
    end
    local dt = math.clamp(tonumber(deltaTime) or 0.016, 0.0001, 0.25)
    local alpha = math.clamp(1 - math.exp(-AIMLOCK_SMOOTHING * dt), 0, 1)
    local desiredCFrame = CFrame.lookAt(cameraPosition, targetPosition, camera.CFrame.UpVector)
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = camera.CFrame:Lerp(desiredCFrame, alpha)
    camera.Focus = CFrame.new(targetPosition)
end

function startAimlockHold()
    if not Config.ScriptReady or not Config.AimlockEnabled or not aimlockTriggerDown then
        return
    end
    if aimlockHeld then
        return
    end
    aimlockHeld = true
    aimlockTargetWasAcquired = false
    aimlockTargetLost = false
    aimTargetPlayer, aimTargetPart = getClosestAimPartToCrosshair()
    aimlockTargetWasAcquired = aimTargetPlayer ~= nil and aimTargetPart ~= nil
    smoothedAimPosition = aimTargetPart and aimTargetPart.Position or nil
    if aimlockTargetWasAcquired then
        captureAimlockCamera()
    end
    publishAimlockTarget()
    nextAimScanAt = 0
end

function stopAimlockHold()
    aimlockHeld = false
    aimTargetPlayer = nil
    aimTargetPart = nil
    smoothedAimPosition = nil
    aimlockTargetWasAcquired = false
    aimlockTargetLost = false
    publishAimlockTarget()
    restoreAimlockCamera()
end

pcall(function()
    RunService:UnbindFromRenderStep("BloodDebt_AimLock")
end)

RunService:BindToRenderStep("BloodDebt_AimLock", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
    if not Config.AimlockEnabled or not Config.ScriptReady or not aimlockHeld or not ScriptAlive then
        return
    end
    if aimlockTargetLost then
        return
    end
    if aimTargetPlayer and aimlockTargetWasAcquired and not isAimTargetValid() then
        aimTargetPlayer = nil
        aimTargetPart = nil
        smoothedAimPosition = nil
        aimlockTargetLost = true
        publishAimlockTarget()
        restoreAimlockCamera()
        return
    end
    local now = os.clock()
    if not aimTargetPlayer and now >= nextAimScanAt then
        nextAimScanAt = now + AIMLOCK_RESCAN_INTERVAL
        local candidatePlayer, candidatePart = getClosestAimPartToCrosshair()
        if candidatePlayer and candidatePart then
            aimTargetPlayer = candidatePlayer
            aimTargetPart = candidatePart
            aimlockTargetWasAcquired = true
            smoothedAimPosition = candidatePart.Position
            captureAimlockCamera()
            publishAimlockTarget()
        end
    end
    if not aimTargetPlayer or not aimTargetPart then
        return
    end
    if not isAimTargetValid() then
        aimTargetPlayer = nil
        aimTargetPart = nil
        smoothedAimPosition = nil
        aimlockTargetLost = true
        publishAimlockTarget()
        restoreAimlockCamera()
        return
    end
    publishAimlockTarget()
    local targetPosition = aimTargetPart.Position
    local dt = math.clamp(tonumber(deltaTime) or 0.016, 0.0001, 0.25)
    local positionAlpha = math.clamp(1 - math.exp(-AIMLOCK_SMOOTHING * dt), 0, 1)
    if not smoothedAimPosition then
        smoothedAimPosition = targetPosition
    else
        smoothedAimPosition = smoothedAimPosition:Lerp(targetPosition, positionAlpha)
    end
    updateAimlockCamera(smoothedAimPosition, dt)
end)

