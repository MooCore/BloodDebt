Toolbar = Instance.new("Frame")
Toolbar.Name = "Toolbar"
Toolbar.Size = IS_MOBILE and UDim2.fromOffset(54, 154) or UDim2.fromOffset(166, 58)
Toolbar.AnchorPoint = IS_MOBILE and Vector2.new(0, 0.5) or Vector2.new(0.5, 0)
Toolbar.Position = IS_MOBILE and UDim2.new(0, 12, 0.5, 0) or UDim2.new(0.5, 0, 0, 14)
Toolbar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Toolbar.BorderSizePixel = 0
Toolbar.Visible = false
Toolbar.ZIndex = 20
Toolbar.Parent = ScreenGui
createCorner(Toolbar, 15)
createStroke(Toolbar, Color3.fromRGB(255, 45, 65), 1.5)

ToolbarLayout = Instance.new("UIListLayout")
ToolbarLayout.FillDirection = IS_MOBILE and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
ToolbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ToolbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ToolbarLayout.Padding = UDim.new(0, IS_MOBILE and 6 or 8)
ToolbarLayout.Parent = Toolbar

function createIconButton(parent, name, icon)
    local button = Instance.new("ImageButton")
    local iconSize = IS_MOBILE and 40 or 42
    button.Name = name
    button.Size = UDim2.fromOffset(iconSize, iconSize)
    button.BackgroundColor3 = Color3.fromRGB(37, 37, 44)
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Image = icon
    button.ImageColor3 = Color3.fromRGB(255, 255, 255)
    button.ScaleType = Enum.ScaleType.Fit
    button.ZIndex = 21
    button.Parent = parent
    createCorner(button, 11)
    return button
end

SettingsIconButton = createIconButton(Toolbar, "SettingsButton", Icons.Settings)
AimlockIconButton = createIconButton(Toolbar, "AimlockButton", Icons.Crosshair)
ESPIconButton = createIconButton(Toolbar, "ESPButton", Icons.Eye)

HideToolbarButton = Instance.new("TextButton")
HideToolbarButton.Name = "HideButton"
HideToolbarButton.Size = UDim2.fromOffset(IS_MOBILE and 20 or 22, IS_MOBILE and 20 or 22)
HideToolbarButton.Position = UDim2.new(1, -8, 0, -8)
HideToolbarButton.AnchorPoint = Vector2.new(0, 0)
HideToolbarButton.BackgroundColor3 = Color3.fromRGB(170, 35, 50)
HideToolbarButton.BorderSizePixel = 0
HideToolbarButton.Text = "×"
HideToolbarButton.TextSize = 17
HideToolbarButton.TextColor3 = Color3.new(1, 1, 1)
HideToolbarButton.Font = Enum.Font.GothamBold
HideToolbarButton.ZIndex = 25
HideToolbarButton.Parent = Toolbar
createCorner(HideToolbarButton, 20)

ReopenButton = createIconButton(ScreenGui, "ReopenButton", Icons.Settings)
ReopenButton.AnchorPoint = Vector2.new(0.5, 0.5)
ReopenButton.Size = UDim2.fromOffset(IS_MOBILE and 46 or 48, IS_MOBILE and 46 or 48)
ReopenButton.Position = IS_MOBILE and UDim2.new(0, 38, 0.5, 0) or UDim2.new(0.5, 0, 0, 44)
ReopenButton.Visible = false
ReopenButton.Active = true
ReopenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ReopenButton.ZIndex = 30
createStroke(ReopenButton, Color3.fromRGB(255, 45, 65), 1.5)

viewport = getViewportSize()
panelWidth = IS_MOBILE and math.max(180, math.min(280, viewport.X - 82)) or 300
panelHeight = IS_MOBILE and 300 or 316

SettingsPanel = Instance.new("Frame")
SettingsPanel.Name = "SettingsPanel"
SettingsPanel.Size = UDim2.fromOffset(panelWidth, panelHeight)
mobilePanelX = math.min(66, math.max(8, viewport.X - panelWidth - 12))
SettingsPanel.Position = IS_MOBILE and UDim2.new(0, mobilePanelX, 0.5, -panelHeight / 2) or UDim2.new(0.5, -panelWidth / 2, 0, 82)
SettingsPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
SettingsPanel.BorderSizePixel = 0
SettingsPanel.Visible = false
SettingsPanel.ZIndex = 20
SettingsPanel.Parent = ScreenGui
createCorner(SettingsPanel, 14)
createStroke(SettingsPanel, Color3.fromRGB(255, 45, 65), 1.5)

PanelTitleIcon = Instance.new("ImageLabel")
PanelTitleIcon.Size = UDim2.fromOffset(20, 20)
PanelTitleIcon.Position = UDim2.fromOffset(14, 12)
PanelTitleIcon.BackgroundTransparency = 1
PanelTitleIcon.Image = Icons.Settings
PanelTitleIcon.ImageColor3 = Color3.fromRGB(255, 45, 65)
PanelTitleIcon.ScaleType = Enum.ScaleType.Fit
PanelTitleIcon.ZIndex = 21
PanelTitleIcon.Parent = SettingsPanel

PanelTitle = Instance.new("TextLabel")
PanelTitle.Size = UDim2.new(1, -76, 0, 28)
PanelTitle.Position = UDim2.fromOffset(42, 9)
PanelTitle.BackgroundTransparency = 1
PanelTitle.Text = "Blood Debt Settings"
PanelTitle.TextColor3 = Color3.new(1, 1, 1)
PanelTitle.TextSize = IS_MOBILE and 14 or 16
PanelTitle.Font = Enum.Font.GothamBold
PanelTitle.TextXAlignment = Enum.TextXAlignment.Left
PanelTitle.TextYAlignment = Enum.TextYAlignment.Center
PanelTitle.TextTruncate = Enum.TextTruncate.AtEnd
PanelTitle.ZIndex = 21
PanelTitle.Parent = SettingsPanel

PanelCloseButton = Instance.new("TextButton")
PanelCloseButton.Name = "ClosePanel"
PanelCloseButton.Size = UDim2.fromOffset(24, 24)
PanelCloseButton.Position = UDim2.new(1, -34, 0, 12)
PanelCloseButton.BackgroundColor3 = Color3.fromRGB(170, 35, 50)
PanelCloseButton.BorderSizePixel = 0
PanelCloseButton.Text = "×"
PanelCloseButton.TextSize = 16
PanelCloseButton.TextColor3 = Color3.new(1, 1, 1)
PanelCloseButton.Font = Enum.Font.GothamBold
PanelCloseButton.ZIndex = 22
PanelCloseButton.Parent = SettingsPanel
createCorner(PanelCloseButton, 12)

PanelDescription = Instance.new("TextLabel")
PanelDescription.Size = UDim2.new(1, -24, 0, 25)
PanelDescription.Position = UDim2.fromOffset(14, 37)
PanelDescription.BackgroundTransparency = 1
PanelDescription.Text = "D-Pad: Left=Aim | Right=Gun TP | Down=Escape TP"
PanelDescription.TextColor3 = Color3.fromRGB(190, 190, 198)
PanelDescription.TextSize = IS_MOBILE and 9 or 11
PanelDescription.Font = Enum.Font.Gotham
PanelDescription.TextXAlignment = Enum.TextXAlignment.Left
PanelDescription.TextYAlignment = Enum.TextYAlignment.Center
PanelDescription.TextTruncate = Enum.TextTruncate.AtEnd
PanelDescription.TextWrapped = false
PanelDescription.ZIndex = 21
PanelDescription.Parent = SettingsPanel

function createTextButton(parent, name, text, position)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -24, 0, IS_MOBILE and 32 or 34)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = IS_MOBILE and 10 or 12
    button.TextScaled = false
    button.Font = Enum.Font.GothamSemibold
    button.TextXAlignment = Enum.TextXAlignment.Center
    button.TextYAlignment = Enum.TextYAlignment.Center
    button.TextTruncate = Enum.TextTruncate.AtEnd
    button.TextWrapped = false
    button.AutoButtonColor = true
    button.ZIndex = 21
    button.Parent = parent
    createCorner(button, 8)
    return button
end

buttonYPositions = IS_MOBILE and { 68, 106, 144, 182, 220, 258 } or { 72, 112, 152, 192, 232, 272 }

WeaponESPToggleButton = createTextButton(SettingsPanel, "WeaponESPToggle", "Vigilante Weapon ESP: ON", UDim2.fromOffset(12, buttonYPositions[1]))
NRToggleButton = createTextButton(SettingsPanel, "NRToggle", IS_MOBILE and "No Recoil [B]: ON" or "NR (No Recoil) [Key B]: ON", UDim2.fromOffset(12, buttonYPositions[2]))
GroundGunTPButton = createTextButton(SettingsPanel, "GroundGunTP", IS_MOBILE and "Dropped Weapon TP (D-Pad Right)" or "Teleport to Dropped Vigilante Gun (D-Pad Right)", UDim2.fromOffset(12, buttonYPositions[3]))
KillerEscapeTPButton = createTextButton(SettingsPanel, "KillerEscapeTP", IS_MOBILE and "Killer Escape TP (D-Pad Down)" or "Teleport to Killer Escape (D-Pad Down)", UDim2.fromOffset(12, buttonYPositions[4]))
GunDropPreviewButton = createTextButton(SettingsPanel, "GunDropPreview", "Preview Gun Drop Sound", UDim2.fromOffset(12, buttonYPositions[5]))
NotificationPreviewButton = createTextButton(SettingsPanel, "NotificationPreview", "Preview Default Notification", UDim2.fromOffset(12, buttonYPositions[6]))

function updateIconButtonColor(button, enabled)
    button.BackgroundColor3 = enabled and Color3.fromRGB(145, 30, 48) or Color3.fromRGB(37, 37, 44)
end

function updateTextToggleColor(button, label, enabled)
    button.Text = label .. (enabled and ": ON" or ": OFF")
    button.BackgroundColor3 = enabled and Color3.fromRGB(145, 30, 48) or Color3.fromRGB(42, 42, 50)
end

refreshUIButtons = function()
    updateIconButtonColor(AimlockIconButton, Config.AimlockEnabled)
    updateIconButtonColor(ESPIconButton, Config.ESPEnabled)
    updateIconButtonColor(SettingsIconButton, SettingsPanel.Visible)
    updateTextToggleColor(WeaponESPToggleButton, "Vigilante Weapon ESP", Config.WeaponHighlight)
    updateTextToggleColor(NRToggleButton, IS_MOBILE and "No Recoil [B]" or "NR (No Recoil) [Key B]", Config.NREnabled)
end

trackConnection(SettingsIconButton.Activated:Connect(function()
    if not Config.ScriptReady then
        return
    end
    SettingsPanel.Visible = not SettingsPanel.Visible
    refreshUIButtons()
    notify("Settings", SettingsPanel.Visible and "Settings panel opened." or "Settings panel closed.", Icons.Bell, Sounds.Notification)
end))

trackConnection(PanelCloseButton.Activated:Connect(function()
    SettingsPanel.Visible = false
    refreshUIButtons()
end))

trackConnection(AimlockIconButton.Activated:Connect(function()
    if not Config.ScriptReady then
        return
    end
    Config.AimlockEnabled = not Config.AimlockEnabled
    if Config.AimlockEnabled then
        startAimlockHold()
    else
        stopAimlockHold()
    end
    refreshUIButtons()
    notify(
        Config.AimlockEnabled and "Aimlock Enabled" or "Aimlock Disabled",
        Config.AimlockEnabled and "Aimlock is enabled. Hold L2 to activate it." or "Aimlock has been disabled.",
        Config.AimlockEnabled and Icons.Success or Icons.Info,
        Sounds.Notification
    )
end))

trackConnection(ESPIconButton.Activated:Connect(function()
    if not Config.ScriptReady then
        return
    end
    Config.ESPEnabled = not Config.ESPEnabled
    refreshUIButtons()
    if not Config.ESPEnabled then
        for _, esp in pairs(ESPObjects) do
            if esp.Highlight then
                esp.Highlight.Enabled = false
            end
            if esp.Billboard then
                esp.Billboard.Enabled = false
            end
        end
    else
        updateESP()
    end
    notify(
        Config.ESPEnabled and "Player ESP Enabled" or "Player ESP Disabled",
        Config.ESPEnabled and "Player ESP is now active." or "Player ESP has been disabled.",
        Config.ESPEnabled and Icons.Success or Icons.Info,
        Sounds.Notification
    )
end))

trackConnection(WeaponESPToggleButton.Activated:Connect(function()
    if not Config.ScriptReady then
        return
    end
    Config.WeaponHighlight = not Config.WeaponHighlight
    refreshUIButtons()
    updateWeaponHighlight()
    notify(
        Config.WeaponHighlight and "Weapon ESP Enabled" or "Weapon ESP Disabled",
        Config.WeaponHighlight and "Dropped Vigilante weapon highlighting is now active." or "Dropped Vigilante weapon highlighting has been disabled.",
        Config.WeaponHighlight and Icons.Success or Icons.Info,
        Sounds.Notification
    )
end))

trackConnection(NRToggleButton.Activated:Connect(function()
    if not Config.ScriptReady then
        return
    end
    setNREnabled(not Config.NREnabled, true)
end))

trackConnection(GroundGunTPButton.Activated:Connect(function()
    if Config.ScriptReady then
        teleportToGroundWeapon()
    end
end))

trackConnection(KillerEscapeTPButton.Activated:Connect(function()
    if Config.ScriptReady then
        teleportToKillerEscape()
    end
end))

trackConnection(GunDropPreviewButton.Activated:Connect(function()
    notify("Sound Preview", "Playing the dropped-weapon alert sound.", Icons.Bell, Sounds.GunDrop)
end))

trackConnection(NotificationPreviewButton.Activated:Connect(function()
    notify("Sound Preview", "Playing the default notification sound.", Icons.BellRing, Sounds.Notification)
end))

trackConnection(HideToolbarButton.Activated:Connect(function()
    Toolbar.Visible = false
    SettingsPanel.Visible = false
    ReopenButton.Visible = true
    refreshUIButtons()
end))

activeDragInput = nil
dragStartPosition = nil
buttonStartCenter = nil
buttonWasDragged = false
buttonDragThreshold = 8

trackConnection(ReopenButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        activeDragInput = input
        dragStartPosition = input.Position
        local buttonSize = ReopenButton.AbsoluteSize
        buttonStartCenter = ReopenButton.AbsolutePosition + Vector2.new(buttonSize.X * 0.5, buttonSize.Y * 0.5)
        buttonWasDragged = false
    end
end))

trackConnection(UserInputService.InputChanged:Connect(function(input)
    if not activeDragInput then
        return
    end
    local isMouseMove = input.UserInputType == Enum.UserInputType.MouseMovement
    local isTouchMove = input.UserInputType == Enum.UserInputType.Touch
    if not isMouseMove and not isTouchMove then
        return
    end
    if isTouchMove and input ~= activeDragInput then
        return
    end
    local delta = input.Position - dragStartPosition
    if delta.Magnitude >= buttonDragThreshold then
        buttonWasDragged = true
    end
    if buttonWasDragged then
        local camera = Workspace.CurrentCamera
        local viewportSize = camera and camera.ViewportSize or Vector2.new(800, 600)
        local halfWidth = ReopenButton.AbsoluteSize.X * 0.5
        local halfHeight = ReopenButton.AbsoluteSize.Y * 0.5
        local x = math.clamp(buttonStartCenter.X + delta.X, halfWidth, viewportSize.X - halfWidth)
        local y = math.clamp(buttonStartCenter.Y + delta.Y, halfHeight, viewportSize.Y - halfHeight)
        ReopenButton.Position = UDim2.fromOffset(x, y)
    end
end))

trackConnection(UserInputService.InputEnded:Connect(function(input)
    if not activeDragInput then
        return
    end
    local samePointer = input == activeDragInput or (activeDragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
    if samePointer then
        local shouldOpen = not buttonWasDragged
        activeDragInput = nil
        dragStartPosition = nil
        buttonStartCenter = nil
        if shouldOpen then
            Toolbar.Visible = true
            ReopenButton.Visible = false
            refreshUIButtons()
            notify("Interface Restored", "The interface is now visible.", Icons.Settings, Sounds.Notification)
        else
            task.delay(0.25, function()
                buttonWasDragged = false
            end)
        end
    end
end))

