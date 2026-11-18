return function(ctx)
    local Players = ctx.Players
    local LocalPlayer = ctx.LocalPlayer
    local Workspace = ctx.Workspace
    local Config = ctx.Config
    local ScreenGui = ctx.ScreenGui
    local Icons = ctx.Icons
    local Sounds = ctx.Sounds
    local notify = ctx.notify
    local trackConnection = ctx.trackConnection
    local trackPlayerConnection = ctx.trackPlayerConnection
    local disconnectPlayerConnections = ctx.disconnectPlayerConnections
    local ToolAncestryConnections = ctx.ToolAncestryConnections
    local Database = ctx.Database

    local isVigilanteWeapon = Database.isVigilanteWeapon
    local everDroppedVigilanteTools = Database.everDroppedVigilanteTools
    local initialVigilanteOwners = Database.initialVigilanteOwners
    local heroPlayers = Database.heroPlayers
    local resetRoundHeroTracking = Database.resetRoundHeroTracking
    local getRole = Database.getRole
    local getRoleDisplay = Database.getRoleDisplay

    local ESP = {}

    local MAX_TOTAL_HIGHLIGHTS = 26
    local MAX_WEAPON_HIGHLIGHTS = 10

    local ESPObjects = {}
    ESP.ESPObjects = ESPObjects

    local function countActivePlayerHighlights()
        local count = 0

        for _, esp in pairs(ESPObjects) do
            if esp.Highlight and esp.Highlight.Parent and esp.Highlight.Enabled then
                count = count + 1
            end
        end

        return count
    end

    local function destroyPlayerESP(player)
        local esp = ESPObjects[player]

        if esp then
            if esp.Highlight then
                pcall(function()
                    esp.Highlight.Adornee = nil
                    esp.Highlight:Destroy()
                end)
            end

            if esp.Billboard then
                pcall(function()
                    esp.Billboard.Adornee = nil
                    esp.Billboard:Destroy()
                end)
            end

            ESPObjects[player] = nil
        end
    end

    local function clearAllPlayerESP()
        for player in pairs(ESPObjects) do
            destroyPlayerESP(player)
        end
    end

    local function createESP(player)
        if not Config.ESPEnabled or not Config.ScriptReady or not ctx.ScriptAlive then
            return
        end

        if ESPObjects[player] or player == LocalPlayer then
            return
        end

        local character = player.Character

        if not character or not character:IsDescendantOf(Workspace) then
            return
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or humanoid.Health <= 0 or not rootPart then
            return
        end

        local highlight = nil

        if countActivePlayerHighlights() < (MAX_TOTAL_HIGHLIGHTS - MAX_WEAPON_HIGHLIGHTS) then
            highlight = Instance.new("Highlight")
            highlight.Name = "ESPHighlight_" .. tostring(player.UserId)
            highlight.Adornee = character
            highlight.Enabled = Config.ESPMode == "Highlight"
            highlight.FillColor = Color3.new(0, 1, 0)
            highlight.FillTransparency = 1
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.OutlineTransparency = 0.35
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = ScreenGui
        end

        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = "ESPRole_" .. tostring(player.UserId)
        billboardGui.Adornee = rootPart
        billboardGui.Size = UDim2.new(0, 260, 0, 50)
        billboardGui.AlwaysOnTop = true
        billboardGui.StudsOffset = Vector3.new(0, 3.5, 0)
        billboardGui.Parent = ScreenGui

        local roleText = Instance.new("TextLabel")
        roleText.Parent = billboardGui
        roleText.Size = UDim2.new(1, 0, 1, 0)
        roleText.Position = UDim2.new(0, 0, 0, 0)
        roleText.Text = "Innocent"
        roleText.TextColor3 = Color3.new(0, 1, 0)
        roleText.BackgroundTransparency = 1
        roleText.TextStrokeTransparency = 0
        roleText.Font = Enum.Font.SourceSansBold
        roleText.TextSize = 13

        ESPObjects[player] = {
            Highlight = highlight,
            Billboard = billboardGui,
            RoleText = roleText,
            Character = character,
            Humanoid = humanoid,
            RootPart = rootPart,
            LastUpdate = 0,
        }
    end

    local function updateESP()
        if not Config.ESPEnabled then
            for _, esp in pairs(ESPObjects) do
                if esp.Highlight then
                    esp.Highlight.Enabled = false
                end

                if esp.Billboard then
                    esp.Billboard.Enabled = false
                end
            end

            return
        end

        local currentTime = os.clock()
        local stalePlayers = {}

        for player, esp in pairs(ESPObjects) do
            local characterValid = esp.Character
                and esp.Character.Parent
                and esp.Character:IsDescendantOf(Workspace)

            local humanoidValid = esp.Humanoid
                and esp.Humanoid.Parent
                and esp.Humanoid.Health > 0

            local rootValid = esp.RootPart and esp.RootPart.Parent
            local playerValid = player.Parent == Players and player.Character == esp.Character

            if not playerValid or not characterValid or not humanoidValid or not rootValid then
                table.insert(stalePlayers, player)

            elseif currentTime - esp.LastUpdate > 0.6 then
                esp.LastUpdate = currentTime

                local role, weaponName = getRole(player)
                local roleLabel, roleColor = getRoleDisplay(role, weaponName)

                if esp.Highlight then
                    esp.Highlight.Adornee = esp.Character
                    esp.Highlight.Enabled = Config.ESPMode == "Highlight"
                    esp.Highlight.FillColor = roleColor
                    esp.Highlight.OutlineColor = roleColor
                end

                if esp.Billboard then
                    esp.Billboard.Adornee = esp.RootPart
                    esp.Billboard.Enabled = true
                end

                if esp.RoleText then
                    esp.RoleText.Text = roleLabel
                    esp.RoleText.TextColor3 = roleColor
                end
            end
        end

        for _, player in ipairs(stalePlayers) do
            destroyPlayerESP(player)

            if player.Parent == Players and player.Character then
                createESP(player)
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and not ESPObjects[player] then
                createESP(player)
            end
        end
    end

    ESP.destroyPlayerESP = destroyPlayerESP
    ESP.clearAllPlayerESP = clearAllPlayerESP
    ESP.createESP = createESP
    ESP.updateESP = updateESP

    local trackedWorldTools = setmetatable({}, { __mode = "k" })
    local highlightedWeapons = setmetatable({}, { __mode = "k" })
    local groundWeapons = setmetatable({}, { __mode = "k" })
    local lastDroppedWeapon = nil
    local groundWeaponScanInitialized = false
    local boundBloodFolder = nil
    local bloodFolderConnections = {}

    local function getHoldingPlayerFromTool(tool)
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

    local function isWeaponInHands(tool)
        return getHoldingPlayerFromTool(tool) ~= nil
    end

    local function getGroundWeaponPart(tool)
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

    local function hookVigilanteToolAncestry(tool)
        if not tool or not tool:IsA("Tool") or not isVigilanteWeapon(tool.Name) then
            return
        end

        if ToolAncestryConnections[tool] then
            return
        end

        local conn = tool.AncestryChanged:Connect(function()
            if not ctx.ScriptAlive then
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

    local function registerCandidateTool(instance)
        if instance and instance:IsA("Tool") and isVigilanteWeapon(instance.Name) then
            trackedWorldTools[instance] = true
            everDroppedVigilanteTools[instance] = true
            hookVigilanteToolAncestry(instance)
        end
    end

    local function unregisterCandidateTool(instance)
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

    local function clearAllWeaponHighlights()
        for weapon, highlight in pairs(highlightedWeapons) do
            pcall(function()
                highlight.Adornee = nil
                highlight:Destroy()
            end)

            highlightedWeapons[weapon] = nil
        end
    end

    ESP.clearAllWeaponHighlights = clearAllWeaponHighlights

    local function bindBloodFolderEvents(folder)
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
            if not ctx.ScriptAlive then
                return
            end

            if inst.Parent == folder and (inst:IsA("Model") or inst:IsA("Folder")) then
                Database.invalidateMapScanCache()
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
            if not ctx.ScriptAlive then
                return
            end

            if inst.Parent == folder and (inst:IsA("Model") or inst:IsA("Folder")) then
                Database.invalidateMapScanCache()
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

    local function refreshGroundWeaponRegistry()
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

        table.clear(groundWeapons)

        for tool, part in pairs(currentGroundWeapons) do
            groundWeapons[tool] = part
        end

        groundWeaponScanInitialized = true
    end

    ESP.refreshGroundWeaponRegistry = refreshGroundWeaponRegistry

    local function updateWeaponHighlight()
        if not Config.WeaponHighlight then
            clearAllWeaponHighlights()
            return
        end

        local activeHighlightCount = 0
        local staleTools = {}

        for weapon, highlight in pairs(highlightedWeapons) do
            if not weapon
                or not weapon.Parent
                or not weapon:IsDescendantOf(Workspace)
                or isWeaponInHands(weapon)
                or not isVigilanteWeapon(weapon.Name)
                or not highlight
                or not highlight.Parent then

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

            if isVigilanteWeapon(tool.Name)
                and not highlightedWeapons[tool]
                and not isWeaponInHands(tool) then

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

    ESP.updateWeaponHighlight = updateWeaponHighlight

    local function chooseGroundWeapon()
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
            if isVigilanteWeapon(tool.Name)
                and part
                and part.Parent
                and getGroundWeaponPart(tool) then

                local distance = rootPart and (part.Position - rootPart.Position).Magnitude or 0

                if distance < closestDistance then
                    closestDistance = distance
                    chosenTool, chosenPart = tool, part
                end
            end
        end

        return chosenTool, chosenPart
    end

    local teleportToGroundWeaponBusy = false

    local function teleportToGroundWeapon()
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
            notify(
                "Weapon Not Found",
                "No dropped Vigilante weapon is currently available.",
                Icons.Warning,
                Sounds.WindowsNotification
            )
            return
        end

        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")

        if not character or not character.Parent or not humanoid or humanoid.Health <= 0 or not rootPart then
            notify(
                "Teleport Unavailable",
                "Your character is not ready. Try again after respawning.",
                Icons.Warning,
                Sounds.WindowsNotification
            )
            return
        end

        local confirmedPart = getGroundWeaponPart(tool)

        if not confirmedPart then
            refreshGroundWeaponRegistry()

            notify(
                "Weapon Not Found",
                "The selected weapon is no longer available.",
                Icons.Warning,
                Sounds.WindowsNotification
            )
            return
        end

        local pos = confirmedPart.Position

        if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z or pos.Magnitude > 1e6 then
            notify(
                "Teleport Failed",
                "The weapon's location could not be determined.",
                Icons.Error,
                Sounds.WindowsNotification
            )
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
            notify(
                "Teleport Complete",
                "You have been teleported to " .. tool.Name .. ".",
                Icons.Success,
                Sounds.Popup
            )
        else
            warn("[BloodDebt] Ground-weapon teleport failed: " .. tostring(err))

            notify(
                "Teleport Failed",
                "The teleport could not be completed. Please try again.",
                Icons.Error,
                Sounds.WindowsNotification
            )
        end
    end

    ESP.teleportToGroundWeapon = teleportToGroundWeapon

    local killerEscapeNotifiedForInstance = nil
    local teleportToKillerEscapeBusy = false

    local function resolveEscapeTargetPosition(escapeObj)
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

    local function findKillerEscapeTarget()
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

        local escapeObj = killerEscapeFolder:FindFirstChild("Escape")
            or killerEscapeFolder:FindFirstChild("Escape", true)

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

    local function checkKillerEscapeAvailability()
        if not Config.ScriptReady or not ctx.ScriptAlive then
            return
        end

        local pos, escapeInst = findKillerEscapeTarget()

        if pos and escapeInst then
            if killerEscapeNotifiedForInstance ~= escapeInst then
                killerEscapeNotifiedForInstance = escapeInst

                notify(
                    "Escape Available",
                    "Killer Escape is available. Press D-Pad Down to teleport to it.",
                    Icons.BellRing,
                    Sounds.Popup
                )
            end
        else
            killerEscapeNotifiedForInstance = nil
        end
    end

    ESP.checkKillerEscapeAvailability = checkKillerEscapeAvailability

    local function teleportToKillerEscape()
        if not Config.ScriptReady or teleportToKillerEscapeBusy then
            return
        end

        teleportToKillerEscapeBusy = true

        task.delay(0.35, function()
            teleportToKillerEscapeBusy = false
        end)

        local pos, escapeInst = findKillerEscapeTarget()

        if not pos or not escapeInst then
            notify(
                "Escape Unavailable",
                "Killer Escape is not currently available.",
                Icons.Warning,
                Sounds.WindowsNotification
            )
            return
        end

        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")

        if not character or not character.Parent or not humanoid or humanoid.Health <= 0 or not rootPart then
            notify(
                "Teleport Unavailable",
                "Your character is not ready. Try again after respawning.",
                Icons.Warning,
                Sounds.WindowsNotification
            )
            return
        end

        if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z or pos.Magnitude > 1e6 then
            notify(
                "Teleport Failed",
                "The escape location could not be determined.",
                Icons.Error,
                Sounds.WindowsNotification
            )
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
            notify(
                "Teleport Complete",
                "You have been teleported to Killer Escape.",
                Icons.Success,
                Sounds.Popup
            )
        else
            warn("[BloodDebt] KillerEscape teleport failed: " .. tostring(err))

            notify(
                "Teleport Failed",
                "The teleport could not be completed. Please try again.",
                Icons.Error,
                Sounds.WindowsNotification
            )
        end
    end

    ESP.teleportToKillerEscape = teleportToKillerEscape

    local watchedPlayerContainers = setmetatable({}, { __mode = "k" })

    local function watchPlayerToolsForHero(player, container)
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
            if not ctx.ScriptAlive then
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

    local function bindPlayerESP(player)
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
            if not ctx.ScriptAlive then
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

            if ctx.ScriptAlive and player.Parent == Players and player ~= LocalPlayer then
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

    return ESP
end
