aimlockHeld = false
aimlockTriggerDown = false
aimTargetPlayer = nil
aimTargetPart = nil
smoothedAimPosition = nil
nextAimScanAt = 0
aimlockTargetWasAcquired = false
aimlockTargetLost = false

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

function startAimlockHold()
    if not Config.ScriptReady or not Config.AimlockEnabled or not aimlockTriggerDown then
        return
    end
    aimlockHeld = true
    aimlockTargetWasAcquired = false
    aimlockTargetLost = false
    aimTargetPlayer, aimTargetPart = getClosestAimPartToCrosshair()
    aimlockTargetWasAcquired = aimTargetPlayer ~= nil and aimTargetPart ~= nil
    smoothedAimPosition = aimTargetPart and aimTargetPart.Position or nil
    nextAimScanAt = 0
end

function stopAimlockHold()
    aimlockHeld = false
    aimTargetPlayer = nil
    aimTargetPart = nil
    smoothedAimPosition = nil
    aimlockTargetWasAcquired = false
    aimlockTargetLost = false
end

pcall(function()
    RunService:UnbindFromRenderStep("BloodDebt_AimLock")
end)

RunService:BindToRenderStep("BloodDebt_AimLock", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
    if not Config.AimlockEnabled or not Config.ScriptReady or not aimlockHeld or not ScriptAlive then
        return
    end
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    if aimlockTargetLost then
        return
    end
    if aimlockTargetWasAcquired and not isAimTargetValid() then
        aimTargetPlayer = nil
        aimTargetPart = nil
        smoothedAimPosition = nil
        aimlockTargetLost = true
        return
    end
    local now = os.clock()
    if now >= nextAimScanAt then
        nextAimScanAt = now + AIMLOCK_RESCAN_INTERVAL
        local candidatePlayer, candidatePart, candidateDistance = getClosestAimPartToCrosshair()
        if candidatePlayer and candidatePart then
            if not aimTargetPlayer then
                aimTargetPlayer = candidatePlayer
                aimTargetPart = candidatePart
                aimlockTargetWasAcquired = true
                smoothedAimPosition = nil
            elseif not isAimTargetValid() then
                aimTargetPlayer = nil
                aimTargetPart = nil
                smoothedAimPosition = nil
                aimlockTargetLost = true
                return
            else
                local currentDistance = getScreenDistance(aimTargetPart, camera)
                local sameCandidate = candidatePlayer == aimTargetPlayer and candidatePart == aimTargetPart
                local switchMargin = candidatePlayer == aimTargetPlayer and 3 or AIMLOCK_SWITCH_MARGIN
                if sameCandidate or candidateDistance + switchMargin < currentDistance then
                    if not sameCandidate then
                        aimTargetPlayer = candidatePlayer
                        aimTargetPart = candidatePart
                        smoothedAimPosition = nil
                    end
                end
            end
        end
    end
    if not aimTargetPart then
        return
    end
    if not isAimTargetValid() then
        aimTargetPlayer = nil
        aimTargetPart = nil
        smoothedAimPosition = nil
        if aimlockTargetWasAcquired then
            aimlockTargetLost = true
        end
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
    local desiredCFrame = CFrame.lookAt(camPos, smoothedAimPosition, camera.CFrame.UpVector)
    camera.CFrame = camera.CFrame:Lerp(desiredCFrame, positionAlpha)
end)
