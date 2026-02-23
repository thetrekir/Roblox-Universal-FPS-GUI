local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

if not Drawing then
    warn("shitty executor detected: this script requires drawing api")
    return
end

local mouse1click = isrbxactive and mouse1click or (mouse1press and function() mouse1press() task.wait(0.1) mouse1release() end) or function() end
local mouse1press = mouse1press or function() end
local mouse1release = mouse1release or function() end

local WTVP = Camera.WorldToViewportPoint
local Vector2_new = Vector2.new
local Color3_fromRGB = Color3.fromRGB
local Math_floor = math.floor
local Math_max = math.max
local Math_abs = math.abs

local ScriptRunning = true
local ESP_Store = {}
local Connections = {}
local UI_Store = {}

local Config = {
    Global = {
        MenuOpen = true,
        Keybind = Enum.KeyCode.Insert
    },
    Aimbot = {
        Enabled = true,
        Key = Enum.KeyCode.E, 
        FOV = 100,           
        Smoothness = 0.5,
        AimPart = "Head",    
        WallCheck = true,    
        Prediction = 0.05,
    },
    Triggerbot = {
        Enabled = false,
        Key = Enum.KeyCode.T,
        Delay = 0.1,
        Randomization = 0.05,
        MaxDistance = 1000,
    },
    Visuals = {
        Enabled = true,
        TeamCheck = true,
        Box = true,
        BoxOutline = true,
        Skeleton = true,
        HeadCircle = true,
        ViewLine = true,
        Snaplines = false,
        Names = true,
        Info = true,
        RenderDistance = 2500,
        
        ColorVisible = Color3_fromRGB(0, 255, 128),    
        ColorHidden = Color3_fromRGB(255, 50, 50),     
        ColorText = Color3_fromRGB(255, 255, 255),
    },
    FOV_Circle = {
        Enabled = true,
        Color = Color3_fromRGB(255, 255, 255),
        Transparency = 0.5,
        Thickness = 1,
        NumSides = 60,
    }
}

local function SendNotification(text, color)
    local GUI = nil
    for _, v in pairs(UI_Store) do 
        if v:IsA("ScreenGui") then 
            GUI = v 
            break 
        end 
    end
    
    if not GUI then return end

    local NoteFrame = Instance.new("Frame")
    NoteFrame.Name = "Notification"
    NoteFrame.Size = UDim2.new(0, 200, 0, 40)
    NoteFrame.Position = UDim2.new(1, 20, 0.85, 0)
    NoteFrame.BackgroundColor3 = Color3_fromRGB(30, 30, 30)
    NoteFrame.BorderSizePixel = 0
    NoteFrame.Parent = GUI
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = NoteFrame
    
    local Strip = Instance.new("Frame")
    Strip.Size = UDim2.new(0, 4, 1, 0)
    Strip.BackgroundColor3 = color or Color3_fromRGB(0, 255, 128)
    Strip.BorderSizePixel = 0
    Strip.Parent = NoteFrame
    Instance.new("UICorner", Strip).CornerRadius = UDim.new(0, 6)
    
    local Label = Instance.new("TextLabel")
    Label.Text = text
    Label.Size = UDim2.new(1, -15, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3_fromRGB(255, 255, 255)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = NoteFrame

    TweenService:Create(NoteFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -220, 0.85, 0)}):Play()
    
    task.spawn(function()
        task.wait(2)
        TweenService:Create(NoteFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1, 20, 0.85, 0)}):Play()
        task.wait(0.5)
        NoteFrame:Destroy()
    end)
end

local Library = {}
local MainFrameInstance = nil

function Library:CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UniversalFPSGui_" .. math.random(1000,9999)
    ScreenGui.ResetOnSpawn = false
    
    if gethui then
        ScreenGui.Parent = gethui()
    elseif CoreGui:FindFirstChild("RobloxGui") then
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    table.insert(UI_Store, ScreenGui)

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 550, 0, 380)
    MainFrame.Position = UDim2.new(0.5, -275, 0.5, -190)
    MainFrame.BackgroundColor3 = Color3_fromRGB(25, 25, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    MainFrameInstance = MainFrame

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 6)
    MainCorner.Parent = MainFrame
    
    local Dragging, DragInput, DragStart, StartPos
    local function Update(input)
        local Delta = input.Position - DragStart
        MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
    end
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then Dragging = false end
            end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if Dragging then Update(input) end
        end
    end)

    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 30)
    TopBar.BackgroundColor3 = Color3_fromRGB(35, 35, 35)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 6)

    local Title = Instance.new("TextLabel")
    Title.Text = "Universal FPS Gui | By Thetrekir"
    Title.Size = UDim2.new(1, -20, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3_fromRGB(200, 200, 200)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(0, 120, 1, -30)
    TabContainer.Position = UDim2.new(0, 0, 0, 30)
    TabContainer.BackgroundColor3 = Color3_fromRGB(30, 30, 30)
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.Parent = TabContainer
    
    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingTop = UDim.new(0, 10)
    TabPadding.Parent = TabContainer

    local PageContainer = Instance.new("Frame")
    PageContainer.Size = UDim2.new(1, -120, 1, -30)
    PageContainer.Position = UDim2.new(0, 120, 0, 30)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = MainFrame

    local Tabs = {}
    local FirstTab = true

    function Tabs:CreateTab(Name)
        local TabButton = Instance.new("TextButton")
        TabButton.Text = Name
        TabButton.Size = UDim2.new(1, -10, 0, 30)
        TabButton.BackgroundColor3 = Color3_fromRGB(25, 25, 25)
        TabButton.TextColor3 = Color3_fromRGB(150, 150, 150)
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.TextSize = 13
        TabButton.AutoButtonColor = false
        TabButton.Parent = TabContainer
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 4)
        TabCorner.Parent = TabButton

        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, -10, 1, -10)
        Page.Position = UDim2.new(0, 5, 0, 5)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = Color3_fromRGB(0, 255, 128)
        Page.Visible = false
        Page.Parent = PageContainer
        
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 5)
        PageLayout.Parent = Page
        
        if FirstTab then
            FirstTab = false
            Page.Visible = true
            TabButton.TextColor3 = Color3_fromRGB(255, 255, 255)
            TabButton.BackgroundColor3 = Color3_fromRGB(40, 40, 40)
        end

        TabButton.MouseButton1Click:Connect(function()
            for _, v in pairs(PageContainer:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
            for _, v in pairs(TabContainer:GetChildren()) do 
                if v:IsA("TextButton") then 
                    TweenService:Create(v, TweenInfo.new(0.2), {TextColor3 = Color3_fromRGB(150,150,150), BackgroundColor3 = Color3_fromRGB(25,25,25)}):Play()
                end 
            end
            Page.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.2), {TextColor3 = Color3_fromRGB(255,255,255), BackgroundColor3 = Color3_fromRGB(40,40,40)}):Play()
        end)

        local Elements = {}
        
        function Elements:AddToggle(Text, ConfigTable, ConfigKey)
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
            ToggleFrame.BackgroundColor3 = Color3_fromRGB(35, 35, 35)
            ToggleFrame.Parent = Page
            Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0,4)
            
            local Label = Instance.new("TextLabel")
            Label.Text = Text
            Label.Size = UDim2.new(0.7, 0, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Color3_fromRGB(220, 220, 220)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ToggleFrame
            
            local Button = Instance.new("TextButton")
            Button.Text = ""
            Button.Size = UDim2.new(0, 20, 0, 20)
            Button.Position = UDim2.new(1, -30, 0.5, -10)
            Button.BackgroundColor3 = ConfigTable[ConfigKey] and Color3_fromRGB(0, 255, 128) or Color3_fromRGB(60, 60, 60)
            Button.Parent = ToggleFrame
            Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 4)
            
            Button.MouseButton1Click:Connect(function()
                ConfigTable[ConfigKey] = not ConfigTable[ConfigKey]
                TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = ConfigTable[ConfigKey] and Color3_fromRGB(0, 255, 128) or Color3_fromRGB(60, 60, 60)}):Play()
                
                if ConfigKey == "Enabled" and ConfigTable == Config.Triggerbot then
                    if ConfigTable[ConfigKey] then
                        SendNotification("Triggerbot: ENABLED", Color3_fromRGB(0, 255, 128))
                    else
                        SendNotification("Triggerbot: DISABLED", Color3_fromRGB(255, 50, 50))
                    end
                end
            end)
            return Button
        end
        
        function Elements:AddSlider(Text, ConfigTable, ConfigKey, Min, Max, IsFloat)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 45)
            SliderFrame.BackgroundColor3 = Color3_fromRGB(35, 35, 35)
            SliderFrame.Parent = Page
            Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0,4)

            local Label = Instance.new("TextLabel")
            Label.Text = Text
            Label.Size = UDim2.new(1, -20, 0, 20)
            Label.Position = UDim2.new(0, 10, 0, 5)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Color3_fromRGB(220, 220, 220)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = SliderFrame
            
            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Text = tostring(ConfigTable[ConfigKey])
            ValueLabel.Size = UDim2.new(0, 50, 0, 20)
            ValueLabel.Position = UDim2.new(1, -60, 0, 5)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.TextColor3 = Color3_fromRGB(0, 255, 128)
            ValueLabel.Font = Enum.Font.GothamBold
            ValueLabel.TextSize = 13
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.Parent = SliderFrame

            local SliderBar = Instance.new("Frame")
            SliderBar.Size = UDim2.new(1, -20, 0, 4)
            SliderBar.Position = UDim2.new(0, 10, 0, 30)
            SliderBar.BackgroundColor3 = Color3_fromRGB(60, 60, 60)
            SliderBar.BorderSizePixel = 0
            SliderBar.Parent = SliderFrame
            
            local Fill = Instance.new("Frame")
            Fill.BackgroundColor3 = Color3_fromRGB(0, 255, 128)
            Fill.BorderSizePixel = 0
            Fill.Size = UDim2.new((ConfigTable[ConfigKey] - Min) / (Max - Min), 0, 1, 0)
            Fill.Parent = SliderBar
            
            local Trigger = Instance.new("TextButton")
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.Parent = SliderBar
            
            local function UpdateSlider(Input)
                local SizeX = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local NewValue = Min + ((Max - Min) * SizeX)
                if not IsFloat then NewValue = Math_floor(NewValue) end
                
                if IsFloat then
                    NewValue = math.floor(NewValue * 100) / 100
                end
                
                ConfigTable[ConfigKey] = NewValue
                ValueLabel.Text = string.sub(tostring(NewValue), 1, 4)
                Fill.Size = UDim2.new(SizeX, 0, 1, 0)
            end
            
            local DraggingSlider = false
            Trigger.InputBegan:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then DraggingSlider = true; UpdateSlider(Input) end end)
            UserInputService.InputChanged:Connect(function(Input) if DraggingSlider and Input.UserInputType == Enum.UserInputType.MouseMovement then UpdateSlider(Input) end end)
            UserInputService.InputEnded:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then DraggingSlider = false end end)
        end
        
        function Elements:AddButton(Text, Callback)
            local ButtonFrame = Instance.new("Frame")
            ButtonFrame.Size = UDim2.new(1, 0, 0, 30)
            ButtonFrame.BackgroundColor3 = Color3_fromRGB(35, 35, 35)
            ButtonFrame.Parent = Page
            Instance.new("UICorner", ButtonFrame).CornerRadius = UDim.new(0,4)
            local Btn = Instance.new("TextButton")
            Btn.Text = Text
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.BackgroundTransparency = 1
            Btn.TextColor3 = Color3_fromRGB(255, 80, 80)
            Btn.Font = Enum.Font.GothamBold
            Btn.TextSize = 13
            Btn.Parent = ButtonFrame
            Btn.MouseButton1Click:Connect(Callback)
        end

        function Elements:AddKeybind(Text, ConfigTable, ConfigKey)
            local KeyFrame = Instance.new("Frame")
            KeyFrame.Size = UDim2.new(1, 0, 0, 30)
            KeyFrame.BackgroundColor3 = Color3_fromRGB(35, 35, 35)
            KeyFrame.Parent = Page
            Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0,4)
            local Label = Instance.new("TextLabel")
            Label.Text = Text
            Label.Size = UDim2.new(0.6, 0, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Color3_fromRGB(220, 220, 220)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = KeyFrame
            local KeyButton = Instance.new("TextButton")
            KeyButton.Text = ConfigTable[ConfigKey].Name
            KeyButton.Size = UDim2.new(0, 80, 0, 20)
            KeyButton.Position = UDim2.new(1, -90, 0.5, -10)
            KeyButton.BackgroundColor3 = Color3_fromRGB(60, 60, 60)
            KeyButton.TextColor3 = Color3_fromRGB(255, 255, 255)
            KeyButton.Font = Enum.Font.GothamBold
            KeyButton.TextSize = 12
            KeyButton.Parent = KeyFrame
            Instance.new("UICorner", KeyButton).CornerRadius = UDim.new(0, 4)
            KeyButton.MouseButton1Click:Connect(function()
                KeyButton.Text = ". . ."
                local InputConnection
                InputConnection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        ConfigTable[ConfigKey] = input.KeyCode
                        KeyButton.Text = input.KeyCode.Name
                        InputConnection:Disconnect()
                    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                        ConfigTable[ConfigKey] = Enum.UserInputType.MouseButton2
                        KeyButton.Text = "Mouse2"
                        InputConnection:Disconnect()
                    end
                end)
            end)
        end

        return Elements
    end

    return Tabs, ScreenGui
end

local Window, GUIInstance = Library:CreateUI()
local AimTab = Window:CreateTab("Aimbot")
AimTab:AddToggle("Enabled", Config.Aimbot, "Enabled")
AimTab:AddKeybind("Aim Key", Config.Aimbot, "Key") 
AimTab:AddToggle("WallCheck", Config.Aimbot, "WallCheck")
AimTab:AddSlider("FOV", Config.Aimbot, "FOV", 10, 500, false)
AimTab:AddSlider("Smoothness", Config.Aimbot, "Smoothness", 0, 1, true)
AimTab:AddSlider("Prediction", Config.Aimbot, "Prediction", 0, 1, true)
AimTab:AddToggle("Draw FOV", Config.FOV_Circle, "Enabled")

local TrigTab = Window:CreateTab("Triggerbot")
local TrigEnabledBtn = TrigTab:AddToggle("Enabled (Toggle)", Config.Triggerbot, "Enabled")
TrigTab:AddKeybind("Toggle Key", Config.Triggerbot, "Key")
TrigTab:AddSlider("Delay (Between Clicks)", Config.Triggerbot, "Delay", 0.01, 1.0, true)
TrigTab:AddSlider("Randomize (Legit)", Config.Triggerbot, "Randomization", 0.0, 0.2, true)
TrigTab:AddSlider("Max Distance", Config.Triggerbot, "MaxDistance", 50, 3000, false)

local VisTab = Window:CreateTab("Visuals")
VisTab:AddToggle("Enabled", Config.Visuals, "Enabled")
VisTab:AddToggle("TeamCheck", Config.Visuals, "TeamCheck")
VisTab:AddToggle("Box", Config.Visuals, "Box")
VisTab:AddToggle("Names", Config.Visuals, "Names")
VisTab:AddToggle("Info", Config.Visuals, "Info")
VisTab:AddToggle("Skeleton", Config.Visuals, "Skeleton")
VisTab:AddToggle("Head", Config.Visuals, "HeadCircle")
VisTab:AddToggle("ViewLine", Config.Visuals, "ViewLine")
VisTab:AddToggle("Snaplines", Config.Visuals, "Snaplines")
VisTab:AddSlider("Distance", Config.Visuals, "RenderDistance", 100, 5000, false)

local SetTab = Window:CreateTab("Settings")
SetTab:AddButton("UNLOAD THE SCRIPT", function()
    ScriptRunning = false
    for _, conn in pairs(Connections) do conn:Disconnect() end
    table.clear(Connections)
    for plr, data in pairs(ESP_Store) do
        pcall(function()
            data.Box:Remove(); data.BoxOutline:Remove(); data.Name:Remove()
            data.Info:Remove(); data.HeadCircle:Remove(); data.ViewLine:Remove()
            data.Snapline:Remove()
            for _, line in pairs(data.Skeleton) do line:Remove() end
        end)
    end
    table.clear(ESP_Store)
    if FOVCircle then FOVCircle:Remove() end
    for _, ui in pairs(UI_Store) do ui:Destroy() end
end)

table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Config.Global.Keybind then
        Config.Global.MenuOpen = not Config.Global.MenuOpen
        if MainFrameInstance then
            MainFrameInstance.Visible = Config.Global.MenuOpen
        end
    end
    
    if input.KeyCode == Config.Triggerbot.Key then
        Config.Triggerbot.Enabled = not Config.Triggerbot.Enabled
        local Color = Config.Triggerbot.Enabled and Color3_fromRGB(0, 255, 128) or Color3_fromRGB(60, 60, 60)
        TweenService:Create(TrigEnabledBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color}):Play()

        if Config.Triggerbot.Enabled then
            SendNotification("Triggerbot: ENABLED", Color3_fromRGB(0, 255, 128))
        else
            SendNotification("Triggerbot: DISABLED", Color3_fromRGB(255, 50, 50))
        end
    end
end))

local GlobalRaycastParams = RaycastParams.new()
GlobalRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalRaycastParams.IgnoreWater = true

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = Config.FOV_Circle.Enabled
FOVCircle.Thickness = Config.FOV_Circle.Thickness
FOVCircle.Color = Config.FOV_Circle.Color
FOVCircle.Transparency = Config.FOV_Circle.Transparency
FOVCircle.Filled = false
FOVCircle.NumSides = Config.FOV_Circle.NumSides

local function GetCharacterRoot(Char)
    if not Char then return nil end
    return Char.PrimaryPart 
       or Char:FindFirstChild("HumanoidRootPart") 
       or Char:FindFirstChild("Torso") 
       or Char:FindFirstChild("UpperTorso")
end

local function GetCharacterHumanoid(Char)
    if not Char then return nil end
    return Char:FindFirstChild("Humanoid") or Char:FindFirstChildWhichIsA("Humanoid")
end

local CommonAttributes = {"Team", "team", "Side", "side", "Faction", "faction", "Squad", "squad"}

local function IsEnemy(plr)
    if not Config.Visuals.TeamCheck then return true end 
    if plr == LocalPlayer then return false end 
    
    if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return false end
    
    local PColor = plr.TeamColor
    local LColor = LocalPlayer.TeamColor
    if PColor and LColor and PColor == LColor and PColor ~= BrickColor.new("White") and PColor ~= BrickColor.new("Medium stone grey") then
        return false
    end

    for i = 1, #CommonAttributes do
        local attr = CommonAttributes[i]
        local MyAttr = LocalPlayer:GetAttribute(attr)
        if MyAttr then
            local TheirAttr = plr:GetAttribute(attr)
            if TheirAttr and MyAttr == TheirAttr then
                return false
            end
        end
    end

    local PL = plr:FindFirstChild("leaderstats")
    local LL = LocalPlayer:FindFirstChild("leaderstats")
    if PL and LL then
        local MT = LL:FindFirstChild("Team") or LL:FindFirstChild("Side")
        local TT = PL:FindFirstChild("Team") or PL:FindFirstChild("Side")
        if MT and TT and MT.Value == TT.Value then return false end
    end

    return true
end

local function CheckVisibility(targetPart, targetCharacter)
    if not targetPart then return false end
    local Origin = Camera.CFrame.Position
    local Direction = targetPart.Position - Origin
    GlobalRaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera, Workspace:FindFirstChild("RaycastIgnore")}
    local Result = Workspace:Raycast(Origin, Direction, GlobalRaycastParams)
    if Result and Result.Instance and Result.Instance:IsDescendantOf(targetCharacter) then return true end
    return Result == nil 
end

local function InitializeDrawing(plr)
    if ESP_Store[plr] then return end
    local Objects = {
        BoxOutline = Drawing.new("Square"),
        Box = Drawing.new("Square"), 
        Name = Drawing.new("Text"),
        Info = Drawing.new("Text"), 
        HeadCircle = Drawing.new("Circle"), 
        ViewLine = Drawing.new("Line"),
        Snapline = Drawing.new("Line"), 
        Skeleton = {}
    }
    Objects.BoxOutline.Visible = false; Objects.BoxOutline.Filled = false; Objects.BoxOutline.Thickness = 3; Objects.BoxOutline.Color = Color3.new(0,0,0); Objects.BoxOutline.Transparency = 0.5
    Objects.Box.Visible = false; Objects.Box.Filled = false; Objects.Box.Thickness = 1
    Objects.Name.Visible = false; Objects.Name.Center = true; Objects.Name.Outline = true; Objects.Name.Font = 2
    Objects.Info.Visible = false; Objects.Info.Center = true; Objects.Info.Outline = true; Objects.Info.Font = 2
    Objects.HeadCircle.Visible = false; Objects.HeadCircle.Filled = false; Objects.HeadCircle.Thickness = 1.5
    Objects.ViewLine.Visible = false; Objects.ViewLine.Thickness = 1
    Objects.Snapline.Visible = false; Objects.Snapline.Thickness = 1.5
    for i=1, 16 do 
        local Line = Drawing.new("Line"); Line.Visible = false; Line.Thickness = 1.5
        table.insert(Objects.Skeleton, Line) 
    end
    ESP_Store[plr] = Objects
end

local function HideAll(D)
    D.Box.Visible = false; D.BoxOutline.Visible = false
    D.Name.Visible = false; D.Info.Visible = false
    D.HeadCircle.Visible = false
    D.ViewLine.Visible = false
    D.Snapline.Visible = false
    for _, line in ipairs(D.Skeleton) do line.Visible = false end
end

local function ClearDrawing(plr)
    if not ESP_Store[plr] then return end
    local D = ESP_Store[plr]
    pcall(function()
        D.Box:Remove(); D.BoxOutline:Remove(); D.Name:Remove(); D.Info:Remove(); D.HeadCircle:Remove(); D.ViewLine:Remove(); D.Snapline:Remove()
        for _, line in pairs(D.Skeleton) do line:Remove() end
    end)
    ESP_Store[plr] = nil
end

local R15_Links = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}
local R6_Links = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

task.spawn(function()
    while ScriptRunning do
        local DidFire = false
        if Config.Triggerbot.Enabled then
            local Origin = Camera.CFrame.Position
            local Direction = Camera.CFrame.LookVector * Config.Triggerbot.MaxDistance
            
            GlobalRaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera, Workspace:FindFirstChild("RaycastIgnore")}
            local Result = Workspace:Raycast(Origin, Direction, GlobalRaycastParams)
            
            if Result and Result.Instance then
                local HitModel = Result.Instance:FindFirstAncestorOfClass("Model")
                if HitModel then
                    local Plr = Players:GetPlayerFromCharacter(HitModel)
                    if Plr and IsEnemy(Plr) then
                        local Hum = GetCharacterHumanoid(HitModel)
                        if Hum and Hum.Health > 0 then
                            mouse1press()
                            task.wait(0.03) 
                            mouse1release()
                            local ShotDelay = Config.Triggerbot.Delay + (math.random() * Config.Triggerbot.Randomization)
                            task.wait(ShotDelay)
                            
                            DidFire = true
                        end
                    end
                end
            end
        end
        
        if not DidFire then
            task.wait(0.05)
        end
    end
end)

local function MainRender()
    if not ScriptRunning then return end
    
    local MouseLoc = UserInputService:GetMouseLocation()
    local ViewportSize = Camera.ViewportSize
    local ScreenBottom = Vector2_new(ViewportSize.X / 2, ViewportSize.Y) 
    
    FOVCircle.Position = MouseLoc
    FOVCircle.Radius = Config.Aimbot.FOV
    FOVCircle.Visible = Config.FOV_Circle.Enabled

    local AimbotKeyHeld = false
    if Config.Aimbot.Enabled then
        local K = Config.Aimbot.Key
        if typeof(K) == "EnumItem" then
            if K.EnumType == Enum.KeyCode then AimbotKeyHeld = UserInputService:IsKeyDown(K)
            elseif K.EnumType == Enum.UserInputType then AimbotKeyHeld = UserInputService:IsMouseButtonPressed(K) end
        end
    end

    local ClosestTarget = nil
    local MinDist = Config.Aimbot.FOV
    local AllPlayers = Players:GetPlayers()

    for i = 1, #AllPlayers do
        local plr = AllPlayers[i]
        if plr == LocalPlayer then continue end

        local D = ESP_Store[plr]
        if not D then InitializeDrawing(plr); D = ESP_Store[plr] end
        
        local Char = plr.Character
        if not Char then HideAll(D); continue end
        
        local Root = GetCharacterRoot(Char)
        local Head = Char:FindFirstChild("Head")
        
        if not Root or not Head then HideAll(D); continue end
        
        local RootPos3D = Root.Position
        local Dist = (RootPos3D - Camera.CFrame.Position).Magnitude
        
        if Dist > Config.Visuals.RenderDistance then HideAll(D); continue end

        if not IsEnemy(plr) then HideAll(D); continue end
        
        local Hum = GetCharacterHumanoid(Char)
        local HP = (Hum and Hum.Health) or 100
        if Hum and Hum.Health <= 0 then HideAll(D); continue end

        local RootPos, RootVis = WTVP(Camera, RootPos3D)
        
        if not RootVis then 
            HideAll(D)
            continue 
        end

        local TargetHead = Head
        local IsVisible = false
        
        if Config.Visuals.Enabled or (AimbotKeyHeld and Config.Aimbot.WallCheck) then
             IsVisible = CheckVisibility(Head, Char)
        end
        
        local MainColor = IsVisible and Config.Visuals.ColorVisible or Config.Visuals.ColorHidden

        if Config.Visuals.Enabled then
            local IsR15 = (Char:FindFirstChild("UpperTorso") ~= nil)
            local ScaleFactor = 1000 / Dist
            local BoxSizeY = (IsR15 and 5.5 or 5.0) * ScaleFactor
            local BoxSizeX = 3.5 * ScaleFactor
            local BoxPos = Vector2_new(RootPos.X - BoxSizeX/2, RootPos.Y - BoxSizeY/2)

            if Config.Visuals.Box then
                if Config.Visuals.BoxOutline then D.BoxOutline.Size = Vector2_new(BoxSizeX, BoxSizeY); D.BoxOutline.Position = BoxPos; D.BoxOutline.Visible = true else D.BoxOutline.Visible = false end
                D.Box.Size = Vector2_new(BoxSizeX, BoxSizeY); D.Box.Position = BoxPos; D.Box.Color = MainColor; D.Box.Visible = true
            else D.Box.Visible = false; D.BoxOutline.Visible = false end

            if Config.Visuals.Names then 
                D.Name.Text = plr.Name
                D.Name.Position = Vector2_new(RootPos.X, BoxPos.Y - 18)
                D.Name.Size = 13
                D.Name.Color = Config.Visuals.ColorText
                D.Name.Visible = true
            else D.Name.Visible = false end

            if Config.Visuals.Info then
                D.Info.Text = Math_floor(HP) .. " HP | " .. Math_floor(Dist) .. "m"
                D.Info.Position = Vector2_new(RootPos.X, BoxPos.Y + BoxSizeY + 4)
                D.Info.Size = 11
                D.Info.Color = Config.Visuals.ColorText
                D.Info.Visible = true
            else D.Info.Visible = false end

            if Config.Visuals.Snaplines then 
                D.Snapline.From = ScreenBottom
                D.Snapline.To = Vector2_new(RootPos.X, BoxPos.Y + BoxSizeY + 16)
                D.Snapline.Color = MainColor
                D.Snapline.Visible = true
            else D.Snapline.Visible = false end

            if Config.Visuals.HeadCircle then
                local HeadScreen = WTVP(Camera, Head.Position)
                local TopPoint = WTVP(Camera, Head.Position + Vector3.new(0, 0.6, 0))
                local BottomPoint = WTVP(Camera, Head.Position - Vector3.new(0, 0.6, 0))
                local ScreenHeight = Math_abs(TopPoint.Y - BottomPoint.Y)
                D.HeadCircle.Position = Vector2_new(HeadScreen.X, HeadScreen.Y)
                D.HeadCircle.Radius = Math_max(ScreenHeight / 1.8, 3)
                D.HeadCircle.Color = MainColor
                D.HeadCircle.Visible = true
            else D.HeadCircle.Visible = false end
            
            if Config.Visuals.ViewLine then
                local LookVec = Head.CFrame.LookVector
                local EndPos = Head.Position + (LookVec * 15)
                local EndScreen = WTVP(Camera, EndPos)
                local HS = WTVP(Camera, Head.Position)
                D.ViewLine.From = Vector2_new(HS.X, HS.Y)
                D.ViewLine.To = Vector2_new(EndScreen.X, EndScreen.Y)
                D.ViewLine.Color = MainColor
                D.ViewLine.Visible = true
            else D.ViewLine.Visible = false end

            if Config.Visuals.Skeleton then
                local Links = IsR15 and R15_Links or R6_Links
                for j = 1, #Links do
                    local Link = Links[j]
                    local LineObj = D.Skeleton[j]
                    if not LineObj then break end
                    
                    local P1 = Char:FindFirstChild(Link[1])
                    local P2 = Char:FindFirstChild(Link[2])
                    
                    if P1 and P2 then
                        local V1, Vis1 = WTVP(Camera, P1.Position)
                        local V2, Vis2 = WTVP(Camera, P2.Position)
                        if Vis1 or Vis2 then
                            LineObj.From = Vector2_new(V1.X, V1.Y)
                            LineObj.To = Vector2_new(V2.X, V2.Y)
                            LineObj.Color = MainColor
                            LineObj.Visible = true
                        else
                            LineObj.Visible = false
                        end
                    else
                        LineObj.Visible = false
                    end
                end
            else 
                for _, line in ipairs(D.Skeleton) do line.Visible = false end 
            end
        else
            HideAll(D)
        end

        if AimbotKeyHeld and TargetHead then
            local HeadScreen = WTVP(Camera, TargetHead.Position)
            local ScreenPos = Vector2_new(HeadScreen.X, HeadScreen.Y)
            local DistToMouse = (ScreenPos - MouseLoc).Magnitude
            
            if DistToMouse < MinDist then
                if Config.Aimbot.WallCheck then
                    if IsVisible then 
                        MinDist = DistToMouse
                        ClosestTarget = TargetHead 
                    end
                else 
                    MinDist = DistToMouse
                    ClosestTarget = TargetHead 
                end
            end
        end
    end 
    
    if ClosestTarget then
        local CurrentPos = ClosestTarget.Position
        local Velocity = ClosestTarget.AssemblyLinearVelocity
        local PredictedPos = CurrentPos + (Velocity * Config.Aimbot.Prediction)
        local ScreenPos = WTVP(Camera, PredictedPos)
        local Move = (Vector2_new(ScreenPos.X, ScreenPos.Y) - MouseLoc) * Config.Aimbot.Smoothness
        mousemoverel(Move.X, Move.Y)
    end
end

table.insert(Connections, RunService.RenderStepped:Connect(MainRender))
table.insert(Connections, Players.PlayerRemoving:Connect(function(plr) ClearDrawing(plr) end))

warn("Universal FPS Gui by Thetrekir Loaded!")
