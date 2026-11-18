return function(ctx)
    local UserInputService = ctx.UserInputService
    local Workspace = ctx.Workspace
    local Config = ctx.Config
    local ScreenGui = ctx.ScreenGui
    local Icons = ctx.Icons
    local Sounds = ctx.Sounds
    local createCorner = ctx.createCorner
    local createStroke = ctx.createStroke
    local notify = ctx.notify
    local trackConnection = ctx.trackConnection
    local ESP = ctx.ESP
    local Combat = ctx.Combat

    local UI = {}

    local Toolbar = Instance.new("Frame")
    Toolbar.Name = "Toolbar"
    Toolbar.Size = UDim2.fromOffset(62, 180)
    Toolbar.Position = UDim2.new(0, 18, 0.5, -90)
    Toolbar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Toolbar.BorderSizePixel = 0
    Toolbar.Visible = false
    Toolbar.ZIndex = 20
    Toolbar.Parent = ScreenGui

    createCorner(Toolbar, 15)
    createStroke(Toolbar, Color3.fromRGB(255, 45, 65), 1.5)

    local ToolbarLayout = Instance.new("UIListLayout")
    ToolbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ToolbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ToolbarLayout.Padding = UDim.new(0, 8)
    ToolbarLayout.Parent = Toolbar

    local function createIconButton(parent, name, icon)
        local button = Instance.new("ImageButton")
        button.Name = name
        button.Size = UDim2.fromOffset(44, 44)
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

    local SettingsIconButton = createIconButton(Toolbar, "SettingsButton", Icons.Settings)
    local AimlockIconButton = createIconButton(Toolbar, "AimlockButton", Icons.Crosshair)
    local ESPIconButton = createIconButton(Toolbar, "ESPButton", Icons.Eye)

    local HideToolbarButton = Instance.new("TextButton")
    HideToolbarButton.Name = "HideButton"
    HideToolbarButton.Size = UDim2.fromOffset(22, 22)
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

    local ReopenButton = createIconButton(ScreenGui, "ReopenButton", Icons.Settings)
    ReopenButton.AnchorPoint = Vector2.new(0.5, 0.5)
    ReopenButton.Size = UDim2.fromOffset(52, 52)
    ReopenButton.Position = UDim2.new(0, 44, 0.5, 0)
    ReopenButton.Visible = false
    ReopenButton.Active = true
    ReopenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    ReopenButton.ZIndex = 30

    createStroke(ReopenButton, Color3.fromRGB(255, 45, 65), 1.5)

    local SettingsPanel = Instance.new("Frame")
    SettingsPanel.Name = "SettingsPanel"
    SettingsPanel.Size = UDim2.fromOffset(300, 316)
    SettingsPanel.Position = UDim2.new(0, 92, 0.5, -158)
    SettingsPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    SettingsPanel.BorderSizePixel = 0
    SettingsPanel.Visible = false
    SettingsPanel.ZIndex = 20
    SettingsPanel.Parent = ScreenGui

    createCorner(SettingsPanel, 14)
    createStroke(SettingsPanel, Color3.fromRGB(255, 45, 65), 1.5)

    local PanelTitleIcon = Instance.new("ImageLabel")
    PanelTitleIcon.Size = UDim2.fromOffset(20, 20)
    PanelTitleIcon.Position = UDim2.fromOffset(14, 14)
    PanelTitleIcon.BackgroundTransparency = 1
    PanelTitleIcon.Image = Icons.Settings
    PanelTitleIcon.ImageColor3 = Color3.fromRGB(255, 45, 65)
    PanelTitleIcon.ScaleType = Enum.ScaleType.Fit
    PanelTitleIcon.ZIndex = 21
    PanelTitleIcon.Parent = SettingsPanel

    local PanelTitle = Instance.new("TextLabel")
    PanelTitle.Size = UDim2.new(1, -76, 0, 28)
    PanelTitle.Position = UDim2.fromOffset(42, 10)
    PanelTitle.BackgroundTransparency = 1
    PanelTitle.Text = "Blood Debt Settings"
    PanelTitle.TextColor3 = Color3.new(1, 1, 1)
    PanelTitle.TextSize = 16
    PanelTitle.Font = Enum.Font.GothamBold
    PanelTitle.TextXAlignment = Enum.TextXAlignment.Left
    PanelTitle.ZIndex = 21
    PanelTitle.Parent = SettingsPanel

    local PanelCloseButton = Instance.new("TextButton")
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

    local PanelDescription = Instance.new("TextLabel")
    PanelDescription.Size = UDim2.new(1, -24, 0, 28)
    PanelDescription.Position = UDim2.fromOffset(14, 38)
    PanelDescription.BackgroundTransparency = 1
    PanelDescription.Text = "D-Pad: Left=Aim | Right=Gun TP | Down=Escape TP"
    PanelDescription.TextColor3 = Color3.fromRGB(190, 190, 198)
    PanelDescription.TextSize = 11
    PanelDescription.Font = Enum.Font.Gotham
    PanelDescription.TextXAlignment = Enum.TextXAlignment.Left
    PanelDescription.ZIndex = 21
    PanelDescription.Parent = SettingsPanel

    local function createTextButton(parent, name, text, position)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = UDim2.new(1, -24, 0, 34)
        button.Position = position
        button.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
        button.BorderSizePixel = 0
        button.Text = text
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextSize = 12
        button.Font = Enum.Font.GothamSemibold
        button.AutoButtonColor = true
        button.ZIndex = 21
        button.Parent = parent

        createCorner(button, 8)

        return button
    end

    local WeaponESPToggleButton = createTextButton(
        SettingsPanel,
        "WeaponESPToggle",
        "Vigilante Weapon ESP: ON",
        UDim2.fromOffset(12, 72)
    )

    local NRToggleButton = createTextButton(
        SettingsPanel,
        "NRToggle",
        "NR (No Recoil) [Key B]: ON",
        UDim2.fromOffset(12, 112)
    )

    local GroundGunTPButton = createTextButton(
        SettingsPanel,
        "GroundGunTP",
        "Teleport to Dropped Vigilante Gun (D-Pad Right)",
        UDim2.fromOffset(12, 152)
    )

    local KillerEscapeTPButton = createTextButton(
        SettingsPanel,
        "KillerEscapeTP",
        "Teleport to Killer Escape (D-Pad Down)",
        UDim2.fromOffset(12, 192)
    )

    local GunDropPreviewButton = createTextButton(
        SettingsPanel,
        "GunDropPreview",
        "Preview Gun Drop Sound",
        UDim2.fromOffset(12, 232)
    )

    local NotificationPreviewButton = createTextButton(
        SettingsPanel,
        "NotificationPreview",
        "Preview Default Notification",
        UDim2.fromOffset(12, 272)
    )

    local function updateIconButtonColor(button, enabled)
        button.BackgroundColor3 = enabled
            and Color3.fromRGB(145, 30, 48)
            or Color3.fromRGB(37, 37, 44)
    end

    local function updateTextToggleColor(button, label, enabled)
        button.Text = label .. (enabled and ": ON" or ": OFF")

        button.BackgroundColor3 = enabled
            and Color3.fromRGB(145, 30, 48)
            or Color3.fromRGB(42, 42, 50)
    end

    local function refreshUIButtons()
        updateIconButtonColor(AimlockIconButton, Config.AimlockEnabled)
        updateIconButtonColor(ESPIconButton, Config.ESPEnabled)
        updateIconButtonColor(SettingsIconButton, SettingsPanel.Visible)

        updateTextToggleColor(
            WeaponESPToggleButton,
            "Vigilante Weapon ESP",
            Config.WeaponHighlight
        )

        updateTextToggleColor(
            NRToggleButton,
            "NR (No Recoil) [Key B]",
            Config.NREnabled
        )
    end

    ctx.refreshUIButtons = refreshUIButtons
    UI.refreshUIButtons = refreshUIButtons
    UI.Toolbar = Toolbar
    UI.SettingsPanel = SettingsPanel
    UI.ReopenButton = ReopenButton

    trackConnection(SettingsIconButton.Activated:Connect(function()
        if not Config.ScriptReady then
            return
        end

        SettingsPanel.Visible = not SettingsPanel.Visible
        refreshUIButtons()

        notify(
            "Settings",
            SettingsPanel.Visible and "Settings panel opened." or "Settings panel closed.",
            Icons.Bell,
            Sounds.Notification
        )
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
            Combat.startAimlockHold()
        else
            Combat.stopAimlockHold()
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
            for _, esp in pairs(ESP.ESPObjects) do
                if esp.Highlight then
                    esp.Highlight.Enabled = false
                end

                if esp.Billboard then
                    esp.Billboard.Enabled = false
                end
            end
        else
            ESP.updateESP()
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
        ESP.updateWeaponHighlight()

        notify(
            Config.WeaponHighlight and "Weapon ESP Enabled" or "Weapon ESP Disabled",
            Config.WeaponHighlight
                and "Dropped Vigilante weapon highlighting is now active."
                or "Dropped Vigilante weapon highlighting has been disabled.",
            Config.WeaponHighlight and Icons.Success or Icons.Info,
            Sounds.Notification
        )
    end))

    trackConnection(NRToggleButton.Activated:Connect(function()
        if not Config.ScriptReady then
            return
        end

        Combat.setNREnabled(not Config.NREnabled, true)
    end))

    trackConnection(GroundGunTPButton.Activated:Connect(function()
        if not Config.ScriptReady then
            return
        end

        ESP.teleportToGroundWeapon()
    end))

    trackConnection(KillerEscapeTPButton.Activated:Connect(function()
        if not Config.ScriptReady then
            return
        end

        ESP.teleportToKillerEscape()
    end))

    trackConnection(GunDropPreviewButton.Activated:Connect(function()
        notify(
            "Sound Preview",
            "Playing the dropped-weapon alert sound.",
            Icons.Bell,
            Sounds.GunDrop
        )
    end))

    trackConnection(NotificationPreviewButton.Activated:Connect(function()
        notify(
            "Sound Preview",
            "Playing the default notification sound.",
            Icons.BellRing,
            Sounds.Notification
        )
    end))

    trackConnection(HideToolbarButton.Activated:Connect(function()
        Toolbar.Visible = false
        SettingsPanel.Visible = false
        ReopenButton.Visible = true
        refreshUIButtons()
    end))

    local activeDragInput = nil
    local dragStartPosition = nil
    local buttonStartCenter = nil
    local buttonWasDragged = false
    local buttonDragThreshold = 8

    trackConnection(ReopenButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            activeDragInput = input
            dragStartPosition = input.Position

            local buttonSize = ReopenButton.AbsoluteSize

            buttonStartCenter = ReopenButton.AbsolutePosition
                + Vector2.new(buttonSize.X * 0.5, buttonSize.Y * 0.5)

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
            local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
            local halfWidth = ReopenButton.AbsoluteSize.X * 0.5
            local halfHeight = ReopenButton.AbsoluteSize.Y * 0.5

            local x = math.clamp(
                buttonStartCenter.X + delta.X,
                halfWidth,
                viewport.X - halfWidth
            )

            local y = math.clamp(
                buttonStartCenter.Y + delta.Y,
                halfHeight,
                viewport.Y - halfHeight
            )

            ReopenButton.Position = UDim2.fromOffset(x, y)
        end
    end))

    trackConnection(UserInputService.InputEnded:Connect(function(input)
        if not activeDragInput then
            return
        end

        local samePointer = input == activeDragInput
            or (
                activeDragInput.UserInputType == Enum.UserInputType.MouseButton1
                and input.UserInputType == Enum.UserInputType.MouseButton1
            )

        if samePointer then
            local shouldOpen = not buttonWasDragged

            activeDragInput = nil
            dragStartPosition = nil
            buttonStartCenter = nil

            if shouldOpen then
                Toolbar.Visible = true
                ReopenButton.Visible = false
                refreshUIButtons()

                notify(
                    "Interface Restored",
                    "The interface is now visible.",
                    Icons.Settings,
                    Sounds.Notification
                )
            else
                task.delay(0.25, function()
                    buttonWasDragged = false
                end)
            end
        end
    end))

    return UI
end
