trackedWorldTools = setmetatable({}, { __mode = "k" })
highlightedWeapons = setmetatable({}, { __mode = "k" })
groundWeapons = setmetatable({}, { __mode = "k" })
lastDroppedWeapon = nil
groundWeaponScanInitialized = false
boundBloodFolder = nil
bloodFolderConnections = {}

function getHoldingPlayerFromTool(tool)
    local parent = tool and tool.Parent
    while parent and parent ~= Workspace do
        if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then
            return Players:GetPlayerFromCharacter(parent)
        end
        if parent:IsA("Backpack") and parent.Parent and parent.Parent:IsA("Player") then
            return parent.Parent
        end
        parent = parent.Parent
    end
    return nil
end

function isWeaponInHands(tool)
    return getHoldingPlayerFromTool(tool) ~= nil
end

function getGroundWeaponPart(tool)
    if not tool or not tool:IsA("Tool") or not tool:IsDescendantOf(Workspace) then
        return nil
    end
    if isWeaponInHands(tool) then
        return nil
    end
    local handle = tool:FindFirstChild("Handle", true)
    if handle and handle:IsA("BasePart") then
        return handle
    end
    for _, descendant in ipairs(tool:GetDescendants()) do
        if descendant:IsA("BasePart") then
            return descendant
        end
    end
    return nil
end

function hookVigilanteToolAncestry(tool)
    if not tool or not tool:IsA("Tool") or not isVigilanteWeapon(tool.Name) then
        return
    end
    if ToolAncestryConnections[tool] then
        return
    end
    local conn = tool.AncestryChanged:Connect(function()
        if not ScriptAlive then
            return
        end
        if not tool.Parent then
            local existingConn = ToolAncestryConnections[tool]
            if existingConn then
                ToolAncestryConnections[tool] = nil
                pcall(function()
                    existingConn:Disconnect()
                end)
            end
            return
        end
        local holder = getHoldingPlayerFromTool(tool)
        if holder then
            if everDroppedVigilanteTools[tool] then
                heroPlayers[holder] = tool.Name
            elseif not initialVigilanteOwners[tool] then
                initialVigilanteOwners[tool] = holder
            elseif initialVigilanteOwners[tool] ~= holder then
                heroPlayers[holder] = tool.Name
            end
        else
            local bloodFolder = Workspace:FindFirstChild("BloodFolder")
            if bloodFolder and tool:IsDescendantOf(bloodFolder) then
                everDroppedVigilanteTools[tool] = true
                trackedWorldTools[tool] = true
            end
        end
    end)
    ToolAncestryConnections[tool] = conn
    trackConnection(conn)
end

function registerCandidateTool(instance)
    if instance and instance:IsA("Tool") and isVigilanteWeapon(instance.Name) then
        trackedWorldTools[instance] = true
        everDroppedVigilanteTools[instance] = true
        hookVigilanteToolAncestry(instance)
    end
end

function unregisterCandidateTool(instance)
    if not instance then
        return
    end
    trackedWorldTools[instance] = nil
    groundWeapons[instance] = nil
    local hl = highlightedWeapons[instance]
    if hl then
        pcall(function()
            hl.Adornee = nil
            hl:Destroy()
        end)
        highlightedWeapons[instance] = nil
    end
    if lastDroppedWeapon == instance then
        lastDroppedWeapon = nil
    end
end

function clearAllWeaponHighlights()
    for weapon, highlight in pairs(highlightedWeapons) do
        pcall(function()
            highlight.Adornee = nil
            highlight:Destroy()
        end)
        highlightedWeapons[weapon] = nil
    end
end

function bindBloodFolderEvents(folder)
    if boundBloodFolder == folder then
        return
    end
    for _, conn in ipairs(bloodFolderConnections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(bloodFolderConnections)
    table.clear(trackedWorldTools)
    table.clear(groundWeapons)
    clearAllWeaponHighlights()
    resetRoundHeroTracking()
    boundBloodFolder = folder
    if not folder then
        return
    end
    local ok, descendants = pcall(function()
        return folder:GetDescendants()
    end)
    if ok and descendants then
        for _, inst in ipairs(descendants) do
            registerCandidateTool(inst)
        end
    end
    local addConn = folder.DescendantAdded:Connect(function(inst)
        if not ScriptAlive then
            return
        end
        if inst.Parent == folder and (inst:IsA("Model") or inst:IsA("Folder")) then
            lastMapScanClock = 0
            resetRoundHeroTracking()
            clearAllWeaponHighlights()
        end
        if inst:IsA("Tool") then
            registerCandidateTool(inst)
        elseif inst:IsA("BasePart") and inst.Parent and inst.Parent:IsA("Tool") then
            registerCandidateTool(inst.Parent)
        end
    end)
    local remConn = folder.DescendantRemoving:Connect(function(inst)
        if not ScriptAlive then
            return
        end
        if inst.Parent == folder and (inst:IsA("Model") or inst:IsA("Folder")) then
            lastMapScanClock = 0
            clearAllWeaponHighlights()
        end
        if trackedWorldTools[inst] then
            local droppedTool = inst
            task.defer(function()
                if droppedTool and droppedTool.Parent then
                    local holder = getHoldingPlayerFromTool(droppedTool)
                    if holder then
                        everDroppedVigilanteTools[droppedTool] = true
                        heroPlayers[holder] = droppedTool.Name
                    end
                end
            end)
            unregisterCandidateTool(inst)
        end
    end)
    table.insert(bloodFolderConnections, addConn)
    table.insert(bloodFolderConnections, remConn)
    trackConnection(addConn)
    trackConnection(remConn)
end

function refreshGroundWeaponRegistry()
    local bloodFolder = Workspace:FindFirstChild("BloodFolder")
    if bloodFolder ~= boundBloodFolder then
        bindBloodFolderEvents(bloodFolder)
    end
    local currentGroundWeapons = {}
    local toolsToRemove = {}
    for tool in pairs(trackedWorldTools) do
        if not tool or not tool.Parent or not tool:IsDescendantOf(Workspace) then
            local holder = tool and getHoldingPlayerFromTool(tool)
            if holder and everDroppedVigilanteTools[tool] then
                heroPlayers[holder] = tool.Name
            end
            table.insert(toolsToRemove, tool)
        elseif isWeaponInHands(tool) then
            local holder = getHoldingPlayerFromTool(tool)
            if holder and everDroppedVigilanteTools[tool] then
                heroPlayers[holder] = tool.Name
            end
            table.insert(toolsToRemove, tool)
        elseif isVigilanteWeapon(tool.Name) then
            local part = getGroundWeaponPart(tool)
            if part then
                everDroppedVigilanteTools[tool] = true
                currentGroundWeapons[tool] = part
                if groundWeaponScanInitialized and not groundWeapons[tool] then
                    lastDroppedWeapon = tool
                    notify(
                        "Dropped Weapon Detected",
                        "A Vigilante weapon was dropped: " .. tool.Name .. ". Press D-Pad Right to teleport to it.",
                        Icons.BellRing,
                        Sounds.GunDrop
                    )
                end
            end
        end
    end
    for _, tool in ipairs(toolsToRemove) do
        unregisterCandidateTool(tool)
    end
    groundWeapons = currentGroundWeapons
    groundWeaponScanInitialized = true
end

function updateWeaponHighlight()
    if not Config.WeaponHighlight then
        clearAllWeaponHighlights()
        return
    end
    local activeHighlightCount = 0
    local staleTools = {}
    for weapon, highlight in pairs(highlightedWeapons) do
        if not weapon or not weapon.Parent or not weapon:IsDescendantOf(Workspace) or isWeaponInHands(weapon) or not isVigilanteWeapon(weapon.Name) or not highlight or not highlight.Parent then
            table.insert(staleTools, weapon)
        else
            activeHighlightCount = activeHighlightCount + 1
        end
    end
    for _, weapon in ipairs(staleTools) do
        local hl = highlightedWeapons[weapon]
        if hl then
            pcall(function()
                hl.Adornee = nil
                hl:Destroy()
            end)
        end
        highlightedWeapons[weapon] = nil
    end
    for tool in pairs(groundWeapons) do
        if activeHighlightCount >= MAX_WEAPON_HIGHLIGHTS then
            break
        end
        if isVigilanteWeapon(tool.Name) and not highlightedWeapons[tool] and not isWeaponInHands(tool) then
            local highlight = Instance.new("Highlight")
            highlight.Name = "ToolESP"
            highlight.Adornee = tool
            highlight.FillColor = Color3.new(1, 1, 0)
            highlight.FillTransparency = 1
            highlight.OutlineColor = Color3.new(1, 1, 0)
            highlight.OutlineTransparency = 0.15
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = ScreenGui
            highlightedWeapons[tool] = highlight
            activeHighlightCount = activeHighlightCount + 1
        end
    end
end

function chooseGroundWeapon()
    if lastDroppedWeapon and isVigilanteWeapon(lastDroppedWeapon.Name) then
        local lastPart = groundWeapons[lastDroppedWeapon]
        if lastPart and lastPart.Parent and getGroundWeaponPart(lastDroppedWeapon) then
            return lastDroppedWeapon, lastPart
        end
        lastDroppedWeapon = nil
    end
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local chosenTool, chosenPart = nil, nil
    local closestDistance = math.huge
    for tool, part in pairs(groundWeapons) do
        if isVigilanteWeapon(tool.Name) and part and part.Parent and getGroundWeaponPart(tool) then
            local distance = rootPart and (part.Position - rootPart.Position).Magnitude or 0
            if distance < closestDistance then
                closestDistance = distance
                chosenTool, chosenPart = tool, part
            end
        end
    end
    return chosenTool, chosenPart
end

teleportToGroundWeaponBusy = false
function teleportToGroundWeapon()
    if not Config.ScriptReady or teleportToGroundWeaponBusy then
        return
    end
    teleportToGroundWeaponBusy = true
    task.delay(0.35, function()
        teleportToGroundWeaponBusy = false
    end)
    refreshGroundWeaponRegistry()
    local tool, targetPart = chooseGroundWeapon()
    if not tool or not targetPart then
        notify("Weapon Not Found", "No dropped Vigilante weapon is currently available.", Icons.Warning, Sounds.WindowsNotification)
        return
    end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not character.Parent or not humanoid or humanoid.Health <= 0 or not rootPart then
        notify("Teleport Unavailable", "Your character is not ready. Try again after respawning.", Icons.Warning, Sounds.WindowsNotification)
        return
    end
    local confirmedPart = getGroundWeaponPart(tool)
    if not confirmedPart then
        refreshGroundWeaponRegistry()
        notify("Weapon Not Found", "The selected weapon is no longer available.", Icons.Warning, Sounds.WindowsNotification)
        return
    end
    local pos = confirmedPart.Position
    if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z or pos.Magnitude > 1e6 then
        notify("Teleport Failed", "The weapon's location could not be determined.", Icons.Error, Sounds.WindowsNotification)
        return
    end
    local currentPivot = character:GetPivot()
    local destination = pos + Vector3.new(0, 3, 0)
    local targetPivot = CFrame.new(destination) * currentPivot.Rotation
    local ok, err = pcall(function()
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        character:PivotTo(targetPivot)
    end)
    if ok then
        notify("Teleport Complete", "You have been teleported to " .. tool.Name .. ".", Icons.Success, Sounds.Popup)
    else
        warn("[BloodDebt] Ground-weapon teleport failed: " .. tostring(err))
        notify("Teleport Failed", "The teleport could not be completed. Please try again.", Icons.Error, Sounds.WindowsNotification)
    end
end

killerEscapeNotifiedForInstance = nil
teleportToKillerEscapeBusy = false

function resolveEscapeTargetPosition(escapeObj)
    if not escapeObj then
        return nil, nil
    end
    if escapeObj:IsA("BasePart") then
        return escapeObj.Position, escapeObj
    end
    if escapeObj:IsA("Model") then
        if escapeObj.PrimaryPart then
            return escapeObj.PrimaryPart.Position, escapeObj.PrimaryPart
        end
        local part = escapeObj:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part.Position, part
        end
        local ok, pivot = pcall(function()
            return escapeObj:GetPivot()
        end)
        if ok and pivot then
            return pivot.Position, escapeObj
        end
    end
    local childPart = escapeObj:FindFirstChildWhichIsA("BasePart", true)
    if childPart then
        return childPart.Position, childPart
    end
    return nil, nil
end

function findKillerEscapeTarget()
    local killerEscapeFolder = Workspace:FindFirstChild("KillerEscape")
    if not killerEscapeFolder then
        local bloodFolder = Workspace:FindFirstChild("BloodFolder")
        if bloodFolder then
            killerEscapeFolder = bloodFolder:FindFirstChild("KillerEscape", true)
        end
    end
    if not killerEscapeFolder then
        return nil, nil
    end
    local escapeObj = killerEscapeFolder:FindFirstChild("Escape") or killerEscapeFolder:FindFirstChild("Escape", true)
    if escapeObj then
        local pos, targetInst = resolveEscapeTargetPosition(escapeObj)
        if pos then
            return pos, targetInst
        end
    end
    local fallbackPos, fallbackInst = resolveEscapeTargetPosition(killerEscapeFolder)
    if fallbackPos then
        return fallbackPos, fallbackInst
    end
    return nil, nil
end

function checkKillerEscapeAvailability()
    if not Config.ScriptReady or not ScriptAlive then
        return
    end
    local pos, escapeInst = findKillerEscapeTarget()
    if pos and escapeInst then
        if killerEscapeNotifiedForInstance ~= escapeInst then
            killerEscapeNotifiedForInstance = escapeInst
            notify("Escape Available", "Killer Escape is available. Press D-Pad Down to teleport to it.", Icons.BellRing, Sounds.Popup)
        end
    else
        killerEscapeNotifiedForInstance = nil
    end
end

function teleportToKillerEscape()
    if not Config.ScriptReady or teleportToKillerEscapeBusy then
        return
    end
    teleportToKillerEscapeBusy = true
    task.delay(0.35, function()
        teleportToKillerEscapeBusy = false
    end)
    local pos, escapeInst = findKillerEscapeTarget()
    if not pos or not escapeInst then
        notify("Escape Unavailable", "Killer Escape is not currently available.", Icons.Warning, Sounds.WindowsNotification)
        return
    end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not character.Parent or not humanoid or humanoid.Health <= 0 or not rootPart then
        notify("Teleport Unavailable", "Your character is not ready. Try again after respawning.", Icons.Warning, Sounds.WindowsNotification)
        return
    end
    if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z or pos.Magnitude > 1e6 then
        notify("Teleport Failed", "The escape location could not be determined.", Icons.Error, Sounds.WindowsNotification)
        return
    end
    local currentPivot = character:GetPivot()
    local destination = pos + Vector3.new(0, 3, 0)
    local targetPivot = CFrame.new(destination) * currentPivot.Rotation
    local ok, err = pcall(function()
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        character:PivotTo(targetPivot)
    end)
    if ok then
        notify("Teleport Complete", "You have been teleported to Killer Escape.", Icons.Success, Sounds.Popup)
    else
        warn("[BloodDebt] KillerEscape teleport failed: " .. tostring(err))
        notify("Teleport Failed", "The teleport could not be completed. Please try again.", Icons.Error, Sounds.WindowsNotification)
    end
end

