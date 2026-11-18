ESPObjects = {}

LobbyOutfitSignatureCache = setmetatable({}, { __mode = "k" })

function getCharacterOutfitSignature(character)
    if not character then
        return nil
    end
    local now = os.clock()
    local cached = LobbyOutfitSignatureCache[character]
    if cached and now - cached.CheckedAt < 1.5 then
        return cached.Signature
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end
    local pieces = {}
    local function add(name, value)
        table.insert(pieces, tostring(name) .. "=" .. tostring(value or ""))
    end
    local descriptionOK, description = pcall(function()
        return humanoid:GetAppliedDescription()
    end)
    if descriptionOK and description then
        local properties = {
            "Shirt", "Pants", "GraphicTShirt", "Face", "Head", "Torso",
            "LeftArm", "RightArm", "LeftLeg", "RightLeg", "HeadColor",
            "TorsoColor", "LeftArmColor", "RightArmColor", "LeftLegColor",
            "RightLegColor", "BodyTypeScale", "ProportionScale", "HeightScale",
            "WidthScale", "DepthScale", "HeadScale", "HatAccessory",
            "HairAccessory", "FaceAccessory", "NeckAccessory", "ShouldersAccessory",
            "FrontAccessory", "BackAccessory", "WaistAccessory",
        }
        for _, propertyName in ipairs(properties) do
            local ok, value = pcall(function()
                return description[propertyName]
            end)
            if ok then
                add(propertyName, value)
            end
        end
        local accessoriesOK, accessories = pcall(function()
            return description:GetAccessories(true)
        end)
        if accessoriesOK and type(accessories) == "table" then
            local accessoryParts = {}
            for _, accessory in ipairs(accessories) do
                table.insert(accessoryParts, table.concat({
                    tostring(accessory.AssetId or ""),
                    tostring(accessory.AccessoryType or ""),
                    tostring(accessory.IsLayered or false),
                    tostring(accessory.Order or 0),
                    tostring(accessory.Puffiness or 0),
                }, ":"))
            end
            table.sort(accessoryParts)
            add("Accessories", table.concat(accessoryParts, ";"))
        end
    end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Shirt") then
            add("ShirtInstance", child.ShirtTemplate)
        elseif child:IsA("Pants") then
            add("PantsInstance", child.PantsTemplate)
        elseif child:IsA("ShirtGraphic") then
            add("GraphicInstance", child.Graphic)
        elseif child:IsA("BodyColors") then
            add("BodyColors", table.concat({
                tostring(child.HeadColor3), tostring(child.TorsoColor3),
                tostring(child.LeftArmColor3), tostring(child.RightArmColor3),
                tostring(child.LeftLegColor3), tostring(child.RightLegColor3),
            }, ":"))
        elseif child:IsA("CharacterMesh") then
            add("CharacterMesh", table.concat({
                tostring(child.BodyPart), tostring(child.MeshId), tostring(child.BaseTextureId),
            }, ":"))
        elseif child:IsA("Accessory") then
            local handle = child:FindFirstChild("Handle")
            local detail = child.Name
            if handle and handle:IsA("BasePart") then
                detail = detail .. ":" .. tostring(handle.Color) .. ":" .. tostring(handle.Material)
                local mesh = handle:FindFirstChildWhichIsA("SpecialMesh")
                if mesh then
                    detail = detail .. ":" .. tostring(mesh.MeshId) .. ":" .. tostring(mesh.TextureId)
                elseif handle:IsA("MeshPart") then
                    detail = detail .. ":" .. tostring(handle.MeshId) .. ":" .. tostring(handle.TextureID)
                end
            end
            add("AccessoryInstance", detail)
        end
    end
    local bodyPartNames = {
        "Head", "Torso", "UpperTorso", "LowerTorso", "Left Arm", "Right Arm",
        "Left Leg", "Right Leg", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg",
    }
    for _, partName in ipairs(bodyPartNames) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local detail = tostring(part.Color) .. ":" .. tostring(part.Material)
            if part:IsA("MeshPart") then
                detail = detail .. ":" .. tostring(part.MeshId) .. ":" .. tostring(part.TextureID)
            else
                local mesh = part:FindFirstChildWhichIsA("SpecialMesh")
                if mesh then
                    detail = detail .. ":" .. tostring(mesh.MeshId) .. ":" .. tostring(mesh.TextureId)
                end
            end
            add("BodyPart_" .. partName, detail)
        end
    end
    table.sort(pieces)
    local signature = table.concat(pieces, "|")
    if signature == "" then
        return nil
    end
    LobbyOutfitSignatureCache[character] = {
        Signature = signature,
        CheckedAt = now,
    }
    return signature
end

function playerHasAnyGear(player, character)
    if not player or not character then
        return true
    end
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        return true
    end
    local function hasTool(container)
        if not container then
            return false
        end
        local ok, found = pcall(function()
            return container:FindFirstChildWhichIsA("Tool", true)
        end)
        return ok and found ~= nil
    end
    return hasTool(backpack) or hasTool(character)
end

function isSharedLobbyAppearance()
    local players = Players:GetPlayers()
    if #players < 2 then
        return false
    end
    local sharedSignature = nil
    local checkedPlayers = 0
    for _, player in ipairs(players) do
        local character = player.Character
        if not character or not character:IsDescendantOf(Workspace) then
            return false
        end
        if playerHasAnyGear(player, character) then
            return false
        end
        local signature = getCharacterOutfitSignature(character)
        if not signature then
            return false
        end
        if not sharedSignature then
            sharedSignature = signature
        elseif signature ~= sharedSignature then
            return false
        end
        checkedPlayers = checkedPlayers + 1
    end
    return checkedPlayers == #players and sharedSignature ~= nil
end

function resolveExplicitRoleText(value, activeMap, activeModifier)
    if type(value) ~= "string" or value == "" then
        return nil
    end
    local normalized = normalizeWeaponName(value)
    if normalized == "" or MODIFIER_LOOKUP[normalized] then
        return nil
    end
    if normalized == "target" then
        return "Bystander"
    end
    if KNOWN_ROLE_NAMES[normalized] then
        local mapped = KNOWN_ROLE_NAMES[normalized]
        if mapped == "Vigilante" and activeModifier == "Modifier: Detectives" then
            return "Detective"
        end
        if mapped == "Juggernaut" and activeMap and activeMap.Roles and activeMap.Roles.Juggernaut then
            return activeMap.Roles.Juggernaut
        end
        return mapped
    end
    if TEAM_WAR_FACTIONS[normalized] then
        return "Team War: " .. TEAM_WAR_FACTIONS[normalized]
    end
    return string.sub(value, 1, 42)
end

function getRole(player)
    if not player then
        return "Innocent", nil
    end
    local liveMap = getActiveMatchMap()
    if not liveMap then
        return "Innocent", nil
    end
    local activeMap, activeModifier = getCurrentMapInfo()
    if not activeMap or activeMap.Key ~= liveMap.Key then
        lastMapScanClock = 0
        activeMap, activeModifier = getCurrentMapInfo()
    end
    activeMap = liveMap
    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")
    local equippedVigilanteGun = nil
    local hasBystanderProp = false
    local function checkToolsForHero(container)
        if not container then
            return
        end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local wKey = normalizeWeaponName(tool.Name)
                if ROLE_CATEGORIES.Bystander.Weapons[wKey] then
                    hasBystanderProp = true
                end
                if isVigilanteWeapon(tool.Name) and activeMap.Mode == "Debt" then
                    equippedVigilanteGun = tool.Name
                    if everDroppedVigilanteTools[tool] then
                        heroPlayers[player] = tool.Name
                    elseif not initialVigilanteOwners[tool] then
                        initialVigilanteOwners[tool] = player
                    elseif initialVigilanteOwners[tool] ~= player then
                        heroPlayers[player] = tool.Name
                    end
                end
            end
        end
    end
    checkToolsForHero(character)
    checkToolsForHero(backpack)
    if equippedVigilanteGun and (heroPlayers[player] or hasBystanderProp) then
        return "Hero", equippedVigilanteGun
    end
    local bestRole = nil
    local bestWeapon = nil
    local bestPriority = -1
    local sharedMatch = false
    local function evaluateTool(tool, isEquipped)
        if not tool or not tool:IsA("Tool") then
            return
        end
        local roleName = getRosterRoleForWeapon(tool.Name, activeMap, activeModifier)
        if not roleName then
            return
        end
        if roleName == "Shared / Mode-Dependent" then
            sharedMatch = true
            return
        end
        if roleName == "Melee / Role Unknown" or roleName == "Equipment Mayhem / Shared Equipment" or roleName == "Legacy / Admin" then
            return
        end
        local cat = ROLE_CATEGORIES[roleName]
        local priority = (cat and cat.Priority or 65) + (isEquipped and 5 or 0)
        if string.find(roleName, "Juggernaut", 1, true) then
            priority = 100 + (isEquipped and 5 or 0)
        elseif roleName == "Sharpshooter" then
            priority = 89 + (isEquipped and 5 or 0)
        end
        if priority > bestPriority then
            bestPriority = priority
            bestRole = roleName
            bestWeapon = tool.Name
        end
    end
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            evaluateTool(tool, true)
        end
    end
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            evaluateTool(tool, false)
        end
    end
    local team = player.Team
    if team and team.Name ~= "" then
        local normTeam = normalizeWeaponName(team.Name)
        if TEAM_WAR_FACTIONS[normTeam] then
            local baseTeamRole = "Team War: " .. TEAM_WAR_FACTIONS[normTeam]
            if bestRole == "Sharpshooter" then
                return baseTeamRole .. " (Sharpshooter)", bestWeapon
            end
            return baseTeamRole, bestWeapon
        end
    end
    if bestRole and bestRole ~= "Bystander" and bestRole ~= "Team War" then
        return bestRole, bestWeapon
    end
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if humanoid.MaxHealth >= 1500 then
                return "Juggernaut: Stanislav / Mstislav", bestWeapon
            elseif humanoid.MaxHealth >= 500 then
                return "Juggernaut: Former Paratrooper", bestWeapon
            elseif humanoid.MaxHealth == 250 then
                return "Juggernaut: The Bear", bestWeapon
            end
        end
        local charMatch = KNOWN_ROLE_NAMES[normalizeWeaponName(character.Name)]
        if charMatch and string.find(charMatch, "Juggernaut", 1, true) then
            return charMatch, bestWeapon
        end
    end
    if team and team.Name ~= "" then
        local normTeam = normalizeWeaponName(team.Name)
        if KNOWN_ROLE_NAMES[normTeam] then
            return resolveExplicitRoleText(team.Name, activeMap, activeModifier), bestWeapon
        end
    end
    for _, attributeName in ipairs(ROLE_ATTRIBUTE_NAMES) do
        local okP, valP = pcall(function()
            return player:GetAttribute(attributeName)
        end)
        if okP and type(valP) == "string" then
            local resolved = resolveExplicitRoleText(valP, activeMap, activeModifier)
            if resolved then
                return resolved, bestWeapon
            end
        end
        if character then
            local okC, valC = pcall(function()
                return character:GetAttribute(attributeName)
            end)
            if okC and type(valC) == "string" then
                local resolved = resolveExplicitRoleText(valC, activeMap, activeModifier)
                if resolved then
                    return resolved, bestWeapon
                end
            end
        end
    end
    for _, container in ipairs({ player, character }) do
        if container then
            for _, valueName in ipairs(ROLE_ATTRIBUTE_NAMES) do
                local valueObject = container:FindFirstChild(valueName)
                if valueObject and valueObject:IsA("StringValue") then
                    local resolved = resolveExplicitRoleText(valueObject.Value, activeMap, activeModifier)
                    if resolved then
                        return resolved, bestWeapon
                    end
                end
            end
        end
    end
    if bestRole then
        return bestRole, bestWeapon
    end
    if activeMap.Mode == "Scav War" then
        return "Scavenger", nil
    elseif activeMap.Mode == "Juggernaut" and activeMap.Roles and activeMap.Roles.Wave1 then
        return activeMap.Roles.Wave1, nil
    elseif activeMap.Mode == "Debt" then
        return "Bystander", nil
    end
    if sharedMatch then
        return "Shared / Mode-Dependent", nil
    end
    return "Innocent", nil
end

function getRoleDisplay(role, weaponName)
    local color
    if role == "Killer" then
        color = Color3.fromRGB(255, 70, 70)
    elseif role == "Hero" then
        color = Color3.fromRGB(255, 215, 65)
    elseif role == "Vigilante" or role == "Detective" or role == "Politsiya" then
        color = Color3.fromRGB(85, 150, 255)
    elseif string.find(role, "Juggernaut: The Bear", 1, true) then
        color = Color3.fromRGB(215, 90, 45)
    elseif string.find(role, "Juggernaut: Sharpshooter", 1, true) or string.find(role, "Sharpshooter", 1, true) then
        color = Color3.fromRGB(0, 230, 180)
    elseif string.find(role, "Juggernaut", 1, true) then
        color = Color3.fromRGB(195, 105, 255)
    elseif role == "Foresters" or role == "SEATO Reinforcements" or role == "NETO Reinforcements" then
        color = Color3.fromRGB(75, 210, 165)
    elseif string.find(role, "Team War", 1, true) then
        color = Color3.fromRGB(90, 220, 220)
    elseif role == "Scavenger" or role == "Robber" or role == "NETO Soldier" or role == "Survivor" then
        color = Color3.fromRGB(245, 185, 85)
    elseif role == "Bystander" or role == "Innocent" then
        color = Color3.fromRGB(100, 220, 130)
    else
        color = Color3.fromRGB(190, 195, 205)
    end
    local label = role
    if weaponName and weaponName ~= "" then
        label = string.format("%s [%s]", role, weaponName)
    end
    return label, color
end

function countActivePlayerHighlights()
    local count = 0
    for _, esp in pairs(ESPObjects) do
        if esp.Highlight and esp.Highlight.Parent and esp.Highlight.Enabled then
            count = count + 1
        end
    end
    return count
end

function destroyPlayerESP(player)
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

function clearAllPlayerESP()
    for player in pairs(ESPObjects) do
        destroyPlayerESP(player)
    end
end

function createESP(player)
    if not Config.ESPEnabled or not Config.ScriptReady or not ScriptAlive or not isMatchActive() or isSharedLobbyAppearance() then
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

function updateESP()
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
    if not isMatchActive() or isSharedLobbyAppearance() then
        clearAllPlayerESP()
        return
    end
    local currentTime = os.clock()
    local stalePlayers = {}
    for player, esp in pairs(ESPObjects) do
        local characterValid = esp.Character and esp.Character.Parent and esp.Character:IsDescendantOf(Workspace)
        local humanoidValid = esp.Humanoid and esp.Humanoid.Parent and esp.Humanoid.Health > 0
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

