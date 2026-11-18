ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloodDebtCrosshair"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

ScreenGui.Enabled = true

guiParent = nil
parentedToPlayerGui = pcall(function()
    guiParent = LocalPlayer:WaitForChild("PlayerGui", 10)
    if not guiParent then
        error("PlayerGui is not available")
    end
    ScreenGui.Parent = guiParent
end)

if not parentedToPlayerGui or ScreenGui.Parent ~= guiParent then
    local parentedToCoreGui = pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    if not parentedToCoreGui or not ScreenGui.Parent then
        error("Unable to parent the Blood Debt interface")
    end
end

function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(255, 45, 65)
    stroke.Thickness = thickness or 1.5
    stroke.Parent = parent
    return stroke
end

function playSound(soundId)
    if not ScriptAlive or not soundId then
        return
    end
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 0.8
        sound.Parent = SoundService
        sound:Play()
        sound.Ended:Connect(function()
            if sound and sound.Parent then
                sound:Destroy()
            end
        end)
        task.delay(10, function()
            if sound and sound.Parent then
                sound:Destroy()
            end
        end)
    end)
end

notificationNumber = 0
activeNotification = nil

function notify(title, message, icon, soundId)
    if not ScriptAlive or not ScreenGui.Parent then
        return
    end
    notificationNumber = notificationNumber + 1
    local currentNumber = notificationNumber
    if activeNotification then
        pcall(function()
            activeNotification:Destroy()
        end)
        activeNotification = nil
    end
    local viewport = getViewportSize()
    local margin = IS_MOBILE and 12 or 20
    local width = math.max(180, math.min(IS_MOBILE and 286 or 330, viewport.X - margin * 2))
    local height = IS_MOBILE and 82 or 86
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.fromOffset(width, height)
    notification.AnchorPoint = Vector2.new(1, 1)
    notification.Position = UDim2.new(1, width + margin, 1, -margin)
    notification.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
    notification.BorderSizePixel = 0
    notification.ZIndex = 100
    notification.Parent = ScreenGui
    activeNotification = notification
    createCorner(notification, 12)
    createStroke(notification, Color3.fromRGB(255, 45, 65), 1.5)
    local iconSize = IS_MOBILE and 32 or 36
    local iconImage = Instance.new("ImageLabel")
    iconImage.Size = UDim2.fromOffset(iconSize, iconSize)
    iconImage.Position = UDim2.fromOffset(12, math.floor((height - iconSize) / 2))
    iconImage.BackgroundTransparency = 1
    iconImage.Image = icon or Icons.Bell
    iconImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
    iconImage.ScaleType = Enum.ScaleType.Fit
    iconImage.ZIndex = 101
    iconImage.Parent = notification
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -68, 0, 23)
    titleLabel.Position = UDim2.fromOffset(58, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tostring(title)
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = IS_MOBILE and 13 or 15
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.ZIndex = 101
    titleLabel.Parent = notification
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -68, 0, IS_MOBILE and 42 or 44)
    messageLabel.Position = UDim2.fromOffset(58, 33)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = tostring(message)
    messageLabel.TextColor3 = Color3.fromRGB(190, 190, 198)
    messageLabel.TextSize = IS_MOBILE and 11 or 12
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.ZIndex = 101
    messageLabel.Parent = notification
    playSound(soundId or Sounds.Notification)
    TweenService:Create(notification, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -margin, 1, -margin),
    }):Play()
    task.delay(3, function()
        if currentNumber ~= notificationNumber or not notification.Parent then
            return
        end
        local tween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, width + margin, 1, -margin),
        })
        tween:Play()
        tween.Completed:Wait()
        if currentNumber == notificationNumber and notification.Parent then
            notification:Destroy()
            if activeNotification == notification then
                activeNotification = nil
            end
        end
    end)
end

CrosshairDot = Instance.new("Frame")
CrosshairDot.Name = "CentreDot"
CrosshairDot.AnchorPoint = Vector2.new(0.5, 0.5)
CrosshairDot.Size = UDim2.fromOffset(7, 7)
CrosshairDot.Position = UDim2.fromScale(0.5, 0.5)
CrosshairDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CrosshairDot.BorderSizePixel = 0
CrosshairDot.Parent = ScreenGui

CrosshairCorner = Instance.new("UICorner")
CrosshairCorner.CornerRadius = UDim.new(1, 0)
CrosshairCorner.Parent = CrosshairDot

CrosshairStroke = Instance.new("UIStroke")
CrosshairStroke.Color = Color3.fromRGB(0, 0, 0)
CrosshairStroke.Thickness = 1
CrosshairStroke.Parent = CrosshairDot

LOADING_DURATION = 5.5

function getViewportCenter()
    local camera = Workspace.CurrentCamera
    if not camera then
        return nil
    end
    local viewport = camera.ViewportSize
    return Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
end

