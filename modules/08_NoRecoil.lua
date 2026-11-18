nrNoActorWarned = false
nrInjectionQueued = false
nrActorAppliedState = setmetatable({}, { __mode = "k" })
executorRunOnActor = nil

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

function isAliveLocalWeaponActor(obj)
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

function getActiveWeaponActors()
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

function makeNRActorSource()
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

function runNRInjection()
    if not Config.ScriptReady or not ScriptAlive then
        return 0
    end
    if not executorRunOnActor then
        if not nrNoActorWarned then
            nrNoActorWarned = true
            warn("[BloodDebt NR] This executor does not expose runonactor/run_on_actor. NR cannot inject in this client.")
        end
        return 0
    end
    local actors = getActiveWeaponActors()
    local source = makeNRActorSource()
    local injectedCount = 0
    for _, targetActor in ipairs(actors) do
        if isAliveLocalWeaponActor(targetActor) and nrActorAppliedState[targetActor] ~= Config.NREnabled then
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

function scheduleNRInjection(delaySeconds)
    if nrInjectionQueued or not Config.NREnabled or not ScriptAlive then
        return
    end
    nrInjectionQueued = true
    task.delay(delaySeconds or 0.55, function()
        nrInjectionQueued = false
        if Config.NREnabled and Config.ScriptReady and ScriptAlive then
            runNRInjection()
        end
    end)
end

function setNREnabled(enabled, notifyUser)
    Config.NREnabled = enabled == true
    local updatedActors = 0
    if Config.ScriptReady then
        updatedActors = runNRInjection()
    end
    if refreshUIButtons then
        refreshUIButtons()
    end
    if notifyUser then
        if Config.NREnabled then
            if updatedActors > 0 then
                notify("No Recoil Enabled", "No Recoil is enabled and ready to use.", Icons.Success, Sounds.Notification)
            else
                notify("No Recoil Enabled", "No Recoil is enabled and will apply when a firearm is equipped.", Icons.Success, Sounds.Notification)
            end
        else
            notify("No Recoil Disabled", "No Recoil has been disabled.", Icons.Info, Sounds.Notification)
        end
    end
end

boundContainers = setmetatable({}, { __mode = "k" })

function bindNRContainer(container)
    if not container or boundContainers[container] then
        return
    end
    boundContainers[container] = true
    trackConnection(container.DescendantAdded:Connect(function(descendant)
        if not ScriptAlive then
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
        if not ScriptAlive or not character.Parent then
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

