aimlockHeld = false
aimlockTriggerDown = false
aimTargetPlayer = nil
aimTargetPart = nil
nextAimScanAt = 0
aimlockTargetWasAcquired = false
aimlockTargetLost = false
AIMLOCK_LOCKED_PLAYER = nil
AIMLOCK_LOCKED_PART_NAME = nil
AIMLOCK_IS_LOCKED = false
AIMLOCK_CAMERA_STATE = nil
AIMLOCK_HUMANOID_STATE = nil

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
    return character ~= nil
        and humanoid ~= nil
        and aimTargetPart.Parent ~= nil
        and aimTargetPart:IsDescendantOf(character)
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
    if camera then
        AIMLOCK_CAMERA_STATE = camera
    end
end

function restoreAimlockCamera()
    AIMLOCK_CAMERA_STATE = nil
end

function captureAimlockHumanoid()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end
    if AIMLOCK_HUMANOID_STATE and AIMLOCK_HUMANOID_STATE.Humanoid ~= humanoid then
        local previous = AIMLOCK_HUMANOID_STATE.Humanoid
        if previous and previous.Parent then
            pcall(function()
                previous.AutoRotate = AIMLOCK_HUMANOID_STATE.AutoRotate
            end)
        end
        AIMLOCK_HUMANOID_STATE = nil
    end
    if not AIMLOCK_HUMANOID_STATE then
        AIMLOCK_HUMANOID_STATE = {
            Humanoid = humanoid,
            AutoRotate = humanoid.AutoRotate,
        }
    end
    humanoid.AutoRotate = false
    return humanoid
end

function restoreAimlockHumanoid()
    local saved = AIMLOCK_HUMANOID_STATE
    AIMLOCK_HUMANOID_STATE = nil
    if saved and saved.Humanoid and saved.Humanoid.Parent then
        pcall(function()
            saved.Humanoid.AutoRotate = saved.AutoRotate
        end)
    end
end

function updateAimlockCamera(targetPosition)
    local camera = Workspace.CurrentCamera
    if not camera or not targetPosition then
        return
    end

    captureAimlockHumanoid()

    local cameraPosition = camera.CFrame.Position
    local cameraOffset = targetPosition - cameraPosition
    if cameraOffset.Magnitude > 0.05
        and cameraOffset.X == cameraOffset.X
        and cameraOffset.Y == cameraOffset.Y
        and cameraOffset.Z == cameraOffset.Z then
        local upVector = Vector3.new(0, 1, 0)
        if math.abs(cameraOffset.Unit:Dot(upVector)) > 0.98 then
            upVector = camera.CFrame.RightVector
        end
        camera.CFrame = CFrame.lookAt(cameraPosition, targetPosition, upVector)
        camera.Focus = CFrame.new(targetPosition)
    end

    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local flatTarget = Vector3.new(targetPosition.X, rootPart.Position.Y, targetPosition.Z)
        local facingOffset = flatTarget - rootPart.Position
        if facingOffset.Magnitude > 0.05 then
            rootPart.CFrame = CFrame.lookAt(rootPart.Position, flatTarget, Vector3.new(0, 1, 0))
        end
    end
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
    if aimlockTargetWasAcquired then
        captureAimlockCamera()
        captureAimlockHumanoid()
    end
    publishAimlockTarget()
    nextAimScanAt = 0
end

function stopAimlockHold()
    aimlockHeld = false
    aimTargetPlayer = nil
    aimTargetPart = nil
    aimlockTargetWasAcquired = false
    aimlockTargetLost = false
    publishAimlockTarget()
    restoreAimlockCamera()
    restoreAimlockHumanoid()
end

pcall(function()
    RunService:UnbindFromRenderStep("BloodDebt_AimLock")
end)

RunService:BindToRenderStep("BloodDebt_AimLock", Enum.RenderPriority.Camera.Value + 1, function()
    if not Config.AimlockEnabled or not Config.ScriptReady or not aimlockHeld or not ScriptAlive then
        return
    end
    if aimlockTargetLost then
        return
    end
    if aimTargetPlayer and aimlockTargetWasAcquired and not isAimTargetValid() then
        aimTargetPlayer = nil
        aimTargetPart = nil
        aimlockTargetLost = true
        publishAimlockTarget()
        restoreAimlockCamera()
        restoreAimlockHumanoid()
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
            captureAimlockCamera()
            captureAimlockHumanoid()
            publishAimlockTarget()
        end
    end
    if not aimTargetPlayer or not aimTargetPart then
        return
    end
    if not isAimTargetValid() then
        aimTargetPlayer = nil
        aimTargetPart = nil
        aimlockTargetLost = true
        publishAimlockTarget()
        restoreAimlockCamera()
        restoreAimlockHumanoid()
        return
    end
    publishAimlockTarget()
    updateAimlockCamera(aimTargetPart.Position)
end)
