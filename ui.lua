--[[
    ╔══════════════════════════════════════════════════════════╗
    ║          DEEP GUI CONVERTER  v2  (zukv2)                 ║
    ╚══════════════════════════════════════════════════════════╝
    ScreenGui : Synapse X
    Logic     : wired (open/close/drag/buttons)
    Polish    : UIStroke, sharp edges, improved contrast
    Highlight : hook ready — paste your highlighter below
--]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local _existing = playerGui:FindFirstChild("Synapse X")
if _existing then _existing:Destroy() end

-- ══════════════════════════════════════════════════════════════
--  THEME
-- ══════════════════════════════════════════════════════════════
local T = {
    -- backgrounds
    BG_DEEP     = Color3.fromRGB(22,  22,  26),   -- main frame body
    BG_MID      = Color3.fromRGB(30,  30,  35),   -- titlebar / toolbar
    BG_PANEL    = Color3.fromRGB(26,  26,  31),   -- tab bar row
    BG_EDITOR   = Color3.fromRGB(18,  18,  22),   -- code area
    BG_BTN      = Color3.fromRGB(38,  38,  45),   -- bottom buttons
    BG_BTN_HOV  = Color3.fromRGB(52,  52,  62),   -- button hover

    -- strokes / borders
    STROKE_OUTER = Color3.fromRGB(60,  60,  75),  -- outer window border
    STROKE_INNER = Color3.fromRGB(45,  45,  58),  -- inner dividers
    STROKE_BTN   = Color3.fromRGB(55,  55,  68),  -- button borders
    STROKE_ACCENT= Color3.fromRGB(80,  80, 180),  -- accent line under titlebar

    -- text
    TEXT_MAIN   = Color3.fromRGB(220, 220, 230),
    TEXT_DIM    = Color3.fromRGB(130, 130, 150),
    TEXT_TAB    = Color3.fromRGB(200, 200, 215),

    -- misc
    ICON_TINT   = Color3.fromRGB(180, 180, 200),
    CLOSE_HOV   = Color3.fromRGB(180,  50,  50),
    ATTACH_ON   = Color3.fromRGB(50,  180,  80),
}

-- ══════════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════════
local function stroke(parent, color, thickness, lineJoin)
    local s = Instance.new("UIStroke")
    s.Color         = color or T.STROKE_INNER
    s.Thickness     = thickness or 1
    s.LineJoinMode  = lineJoin or Enum.LineJoinMode.Miter   -- sharp corners
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent        = parent
    return s
end

-- NO UICorner calls anywhere — all edges stay sharp

local function flash(btn, col)
    local orig = btn.BackgroundColor3
    TweenService:Create(btn, TweenInfo.new(0.06), { BackgroundColor3 = col or T.BG_BTN_HOV }):Play()
    task.delay(0.12, function()
        if btn and btn.Parent then
            TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundColor3 = orig }):Play()
        end
    end)
end

local function hoverEffect(btn, hoverCol, normalCol)
    normalCol = normalCol or btn.BackgroundColor3
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundColor3 = hoverCol }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundColor3 = normalCol }):Play()
    end)
end

-- ══════════════════════════════════════════════════════════════
--  GUI BUILD
-- ══════════════════════════════════════════════════════════════
local function createGui()
    -- ── ScreenGui ──────────────────────────────────────────────
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name                  = "Synapse X"
    ScreenGui.ZIndexBehavior        = Enum.ZIndexBehavior.Sibling
    ScreenGui.ScreenInsets          = Enum.ScreenInsets.CoreUISafeInsets
    ScreenGui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension

    -- ── Floating toggle icon ────────────────────────────────────
    local ToggleBtn = Instance.new("ImageButton")
    ToggleBtn.Parent              = ScreenGui
    ToggleBtn.Name                = "ToggleBtn"
    ToggleBtn.Size                = UDim2.fromOffset(46, 46)
    ToggleBtn.Position            = UDim2.fromScale(0.965, 0.94)
    ToggleBtn.BackgroundColor3    = T.BG_MID
    ToggleBtn.BackgroundTransparency = 0
    ToggleBtn.BorderSizePixel     = 0
    ToggleBtn.Image               = "rbxassetid://9524079125"
    ToggleBtn.ImageColor3         = T.ICON_TINT
    ToggleBtn.ScaleType           = Enum.ScaleType.Fit
    ToggleBtn.Style               = Enum.ButtonStyle.Custom
    stroke(ToggleBtn, T.STROKE_OUTER, 1)
    hoverEffect(ToggleBtn, T.BG_BTN_HOV, T.BG_MID)

    -- ── Main frame ─────────────────────────────────────────────
    local MainFrame = Instance.new("Frame")
    MainFrame.Parent           = ScreenGui
    MainFrame.Name             = "MainFrame"
    MainFrame.Size             = UDim2.fromOffset(706, 289)
    MainFrame.Position         = UDim2.fromScale(0.062, 0.096)
    MainFrame.Visible          = false
    MainFrame.BackgroundColor3 = T.BG_DEEP
    MainFrame.BorderSizePixel  = 0
    MainFrame.ClipsDescendants = true
    stroke(MainFrame, T.STROKE_OUTER, 1)

    -- ── Title bar ──────────────────────────────────────────────
    local TitleBar = Instance.new("Frame")
    TitleBar.Parent           = MainFrame
    TitleBar.Name             = "TitleBar"
    TitleBar.Size             = UDim2.new(1, 0, 0, 28)
    TitleBar.Position         = UDim2.fromOffset(0, 0)
    TitleBar.BackgroundColor3 = T.BG_MID
    TitleBar.BorderSizePixel  = 0
    TitleBar.ZIndex           = 2

    -- icon on titlebar
    local TitleIcon = Instance.new("ImageLabel")
    TitleIcon.Parent              = TitleBar
    TitleIcon.Size                = UDim2.fromOffset(18, 18)
    TitleIcon.Position            = UDim2.fromOffset(8, 5)
    TitleIcon.BackgroundTransparency = 1
    TitleIcon.Image               = "rbxassetid://9524079125"
    TitleIcon.ImageColor3         = T.ICON_TINT
    TitleIcon.ScaleType           = Enum.ScaleType.Fit
    TitleIcon.ZIndex              = 3

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent              = TitleBar
    TitleLabel.Size                = UDim2.new(1, -110, 1, 0)
    TitleLabel.Position            = UDim2.fromOffset(32, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text                = "Synapse X"
    TitleLabel.Font                = Enum.Font.GothamBold
    TitleLabel.TextSize            = 13
    TitleLabel.TextColor3          = T.TEXT_MAIN
    TitleLabel.TextXAlignment      = Enum.TextXAlignment.Left
    TitleLabel.ZIndex              = 3

    -- accent line under titlebar
    local AccentLine = Instance.new("Frame")
    AccentLine.Parent           = MainFrame
    AccentLine.Size             = UDim2.new(1, 0, 0, 1)
    AccentLine.Position         = UDim2.fromOffset(0, 28)
    AccentLine.BackgroundColor3 = T.STROKE_ACCENT
    AccentLine.BorderSizePixel  = 0
    AccentLine.ZIndex           = 2

    -- ── Close button ───────────────────────────────────────────
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent              = TitleBar
    CloseBtn.Name                = "CloseBtn"
    CloseBtn.Size                = UDim2.fromOffset(28, 20)
    CloseBtn.Position            = UDim2.new(1, -30, 0, 4)
    CloseBtn.BackgroundColor3    = T.BG_MID
    CloseBtn.BorderSizePixel     = 0
    CloseBtn.Text                = "✕"
    CloseBtn.Font                = Enum.Font.GothamBold
    CloseBtn.TextSize            = 12
    CloseBtn.TextColor3          = T.TEXT_DIM
    CloseBtn.ZIndex              = 4
    hoverEffect(CloseBtn, T.CLOSE_HOV, T.BG_MID)
    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.08), { TextColor3 = Color3.fromRGB(255,255,255) }):Play()
    end)
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.08), { TextColor3 = T.TEXT_DIM }):Play()
    end)

    -- ── Minimize button ────────────────────────────────────────
    local MinBtn = Instance.new("TextButton")
    MinBtn.Parent           = TitleBar
    MinBtn.Name             = "MinBtn"
    MinBtn.Size             = UDim2.fromOffset(28, 20)
    MinBtn.Position         = UDim2.new(1, -60, 0, 4)
    MinBtn.BackgroundColor3 = T.BG_MID
    MinBtn.BorderSizePixel  = 0
    MinBtn.Text             = "─"
    MinBtn.Font             = Enum.Font.GothamBold
    MinBtn.TextSize         = 12
    MinBtn.TextColor3       = T.TEXT_DIM
    MinBtn.ZIndex           = 4
    hoverEffect(MinBtn, T.BG_BTN_HOV, T.BG_MID)

    -- ── Tab bar ────────────────────────────────────────────────
    local TabBar = Instance.new("Frame")
    TabBar.Parent           = MainFrame
    TabBar.Name             = "TabBar"
    TabBar.Size             = UDim2.new(1, 0, 0, 22)
    TabBar.Position         = UDim2.fromOffset(0, 29)
    TabBar.BackgroundColor3 = T.BG_PANEL
    TabBar.BorderSizePixel  = 0

    -- bottom border of tab bar
    local TabBarLine = Instance.new("Frame")
    TabBarLine.Parent           = TabBar
    TabBarLine.Size             = UDim2.new(1, 0, 0, 1)
    TabBarLine.Position         = UDim2.new(0, 0, 1, -1)
    TabBarLine.BackgroundColor3 = T.STROKE_INNER
    TabBarLine.BorderSizePixel  = 0

    -- Script 1 tab
    local Tab1 = Instance.new("Frame")
    Tab1.Parent           = TabBar
    Tab1.Name             = "Tab1"
    Tab1.Size             = UDim2.fromOffset(88, 22)
    Tab1.Position         = UDim2.fromOffset(0, 0)
    Tab1.BackgroundColor3 = T.BG_DEEP   -- active tab = same as editor bg
    Tab1.BorderSizePixel  = 0

    local Tab1Label = Instance.new("TextLabel")
    Tab1Label.Parent              = Tab1
    Tab1Label.Size                = UDim2.new(1, -20, 1, 0)
    Tab1Label.Position            = UDim2.fromOffset(6, 0)
    Tab1Label.BackgroundTransparency = 1
    Tab1Label.Text                = "Script 1"
    Tab1Label.Font                = Enum.Font.Gotham
    Tab1Label.TextSize            = 11
    Tab1Label.TextColor3          = T.TEXT_TAB
    Tab1Label.TextXAlignment      = Enum.TextXAlignment.Left

    local Tab1Close = Instance.new("TextButton")
    Tab1Close.Parent           = Tab1
    Tab1Close.Name             = "TabClose"
    Tab1Close.Size             = UDim2.fromOffset(16, 16)
    Tab1Close.Position         = UDim2.new(1, -18, 0, 3)
    Tab1Close.BackgroundColor3 = T.BG_DEEP
    Tab1Close.BorderSizePixel  = 0
    Tab1Close.Text             = "✕"
    Tab1Close.Font             = Enum.Font.Gotham
    Tab1Close.TextSize         = 9
    Tab1Close.TextColor3       = T.TEXT_DIM
    hoverEffect(Tab1Close, T.CLOSE_HOV, T.BG_DEEP)

    -- right border of active tab
    stroke(Tab1, T.STROKE_INNER, 1)

    -- New tab (+) button
    local NewTabBtn = Instance.new("TextButton")
    NewTabBtn.Parent           = TabBar
    NewTabBtn.Name             = "NewTab"
    NewTabBtn.Size             = UDim2.fromOffset(22, 22)
    NewTabBtn.Position         = UDim2.fromOffset(88, 0)
    NewTabBtn.BackgroundColor3 = T.BG_PANEL
    NewTabBtn.BorderSizePixel  = 0
    NewTabBtn.Text             = "+"
    NewTabBtn.Font             = Enum.Font.GothamBold
    NewTabBtn.TextSize         = 14
    NewTabBtn.TextColor3       = T.TEXT_DIM
    hoverEffect(NewTabBtn, T.BG_BTN_HOV, T.BG_PANEL)

    -- ── Left gutter (line numbers area) ───────────────────────
    local Gutter = Instance.new("Frame")
    Gutter.Parent           = MainFrame
    Gutter.Name             = "Gutter"
    Gutter.Size             = UDim2.fromOffset(38, 222)
    Gutter.Position         = UDim2.fromOffset(0, 51)
    Gutter.BackgroundColor3 = T.BG_PANEL
    Gutter.BorderSizePixel  = 0
    Gutter.ClipsDescendants = true
    Gutter.ZIndex           = 2

    -- gutter right border
    local GutterLine = Instance.new("Frame")
    GutterLine.Parent           = Gutter
    GutterLine.Size             = UDim2.new(0, 1, 1, 0)
    GutterLine.Position         = UDim2.new(1, -1, 0, 0)
    GutterLine.BackgroundColor3 = T.STROKE_INNER
    GutterLine.BorderSizePixel  = 0
    GutterLine.ZIndex           = 3

    local LineNumbers = Instance.new("TextLabel")
    LineNumbers.Parent              = Gutter
    LineNumbers.Name                = "LineNumbers"
    LineNumbers.Size                = UDim2.new(1, -4, 10, 0)  -- tall enough to scroll
    LineNumbers.Position            = UDim2.fromOffset(0, 4)
    LineNumbers.BackgroundTransparency = 1
    LineNumbers.Text                = "1"
    LineNumbers.Font                = Enum.Font.Code
    LineNumbers.TextSize            = 14
    LineNumbers.TextColor3          = T.TEXT_DIM
    LineNumbers.TextXAlignment      = Enum.TextXAlignment.Right
    LineNumbers.TextYAlignment      = Enum.TextYAlignment.Top
    LineNumbers.ZIndex              = 3

    -- ── Editor area ────────────────────────────────────────────
    local EditorFrame = Instance.new("ScrollingFrame")
    EditorFrame.Parent                  = MainFrame
    EditorFrame.Name                    = "EditorScroll"
    EditorFrame.Size                    = UDim2.fromOffset(668, 222)
    EditorFrame.Position                = UDim2.fromOffset(38, 51)
    EditorFrame.BackgroundColor3        = T.BG_EDITOR
    EditorFrame.BorderSizePixel         = 0
    EditorFrame.ClipsDescendants        = true
    EditorFrame.ScrollBarThickness      = 5
    EditorFrame.ScrollBarImageColor3    = T.STROKE_BTN
    EditorFrame.ScrollBarImageTransparency = 0
    EditorFrame.ScrollingDirection      = Enum.ScrollingDirection.XY
    EditorFrame.ElasticBehavior         = Enum.ElasticBehavior.WhenScrollable
    EditorFrame.CanvasSize              = UDim2.new(2, 0, 4, 0)
    EditorFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
    EditorFrame.BottomImage             = ""
    EditorFrame.MidImage                = ""
    EditorFrame.TopImage                = ""
    stroke(EditorFrame, T.STROKE_INNER, 1)

    -- Highlight overlay — sits BELOW the CodeBox, renders RichText colours
    local HighlightLabel = Instance.new("TextLabel")
    HighlightLabel.Parent              = EditorFrame
    HighlightLabel.Name                = "HighlightLabel"
    HighlightLabel.Size                = UDim2.new(1, -8, 1, 0)
    HighlightLabel.Position            = UDim2.fromOffset(6, 4)
    HighlightLabel.BackgroundTransparency = 1
    HighlightLabel.Text                = ""
    HighlightLabel.Font                = Enum.Font.Code
    HighlightLabel.TextSize            = 14
    HighlightLabel.TextColor3          = T.TEXT_MAIN
    HighlightLabel.TextXAlignment      = Enum.TextXAlignment.Left
    HighlightLabel.TextYAlignment      = Enum.TextYAlignment.Top
    HighlightLabel.TextTruncate        = Enum.TextTruncate.None
    HighlightLabel.RichText            = true
    HighlightLabel.ZIndex              = 1  -- behind CodeBox

    -- CodeBox — invisible text so HighlightLabel shows through; captures all input
    local CodeBox = Instance.new("TextBox")
    CodeBox.Parent              = EditorFrame
    CodeBox.Name                = "CodeBox"
    CodeBox.Size                = UDim2.new(1, -8, 1, 0)
    CodeBox.Position            = UDim2.fromOffset(6, 4)
    CodeBox.BackgroundTransparency = 1
    CodeBox.Text                = ""
    CodeBox.Font                = Enum.Font.Code
    CodeBox.TextSize            = 14
    CodeBox.TextColor3          = Color3.fromRGB(0, 0, 0)
    CodeBox.TextTransparency    = 1  -- invisible; colour comes from HighlightLabel
    CodeBox.TextXAlignment      = Enum.TextXAlignment.Left
    CodeBox.TextYAlignment      = Enum.TextYAlignment.Top
    CodeBox.TextTruncate        = Enum.TextTruncate.None
    CodeBox.TextStrokeTransparency = 1
    CodeBox.PlaceholderText     = "-- paste or type your script here"
    CodeBox.PlaceholderColor3   = T.TEXT_DIM
    CodeBox.ClearTextOnFocus    = false
    CodeBox.MultiLine           = true
    CodeBox.ZIndex              = 2  -- above HighlightLabel, captures input

    -- ── Bottom toolbar ─────────────────────────────────────────
    local Toolbar = Instance.new("Frame")
    Toolbar.Parent           = MainFrame
    Toolbar.Name             = "Toolbar"
    Toolbar.Size             = UDim2.new(1, 0, 0, 34)
    Toolbar.Position         = UDim2.new(0, 0, 1, -34)
    Toolbar.BackgroundColor3 = T.BG_MID
    Toolbar.BorderSizePixel  = 0

    -- top border of toolbar
    local ToolbarLine = Instance.new("Frame")
    ToolbarLine.Parent           = Toolbar
    ToolbarLine.Size             = UDim2.new(1, 0, 0, 1)
    ToolbarLine.Position         = UDim2.fromOffset(0, 0)
    ToolbarLine.BackgroundColor3 = T.STROKE_INNER
    ToolbarLine.BorderSizePixel  = 0

    -- button factory
    local btnDefs = {
        { name = "Execute",      label = "Execute",      x = 6   },
        { name = "Clear",        label = "Clear",        x = 98  },
        { name = "OpenFile",     label = "Open File",    x = 190 },
        { name = "ExecuteFile",  label = "Execute File", x = 282 },
        { name = "SaveFile",     label = "Save File",    x = 374 },
        { name = "Options",      label = "Options",      x = 466 },
        { name = "Attach",       label = "Attach",       x = 558 },
        { name = "Hub",          label = "Script Hub",   x = 620 },
    }

    local buttons = {}
    for _, def in ipairs(btnDefs) do
        local btn = Instance.new("TextButton")
        btn.Parent           = Toolbar
        btn.Name             = def.name
        btn.Size             = UDim2.fromOffset(86, 22)
        btn.Position         = UDim2.fromOffset(def.x, 6)
        btn.BackgroundColor3 = T.BG_BTN
        btn.BorderSizePixel  = 0
        btn.Text             = def.label
        btn.Font             = Enum.Font.Gotham
        btn.TextSize         = 11
        btn.TextColor3       = T.TEXT_MAIN
        btn.ZIndex           = 2
        stroke(btn, T.STROKE_BTN, 1)
        hoverEffect(btn, T.BG_BTN_HOV, T.BG_BTN)
        buttons[def.name] = btn
    end

    -- Execute gets a subtle accent stroke to stand out
    local execStroke = buttons["Execute"]:FindFirstChildOfClass("UIStroke")
    if execStroke then
        execStroke.Color = T.STROKE_ACCENT
    end

    ScreenGui.Parent = playerGui

    return {
        ScreenGui    = ScreenGui,
        ToggleBtn    = ToggleBtn,
        MainFrame    = MainFrame,
        TitleBar     = TitleBar,    -- drag handle
        CloseBtn     = CloseBtn,
        MinBtn       = MinBtn,
        CodeBox         = CodeBox,
        HighlightLabel  = HighlightLabel,
        EditorScroll    = EditorFrame,
        LineNumbers     = LineNumbers,
        TabClose     = Tab1Close,
        NewTab       = NewTabBtn,
        -- bottom buttons
        Execute      = buttons["Execute"],
        Clear        = buttons["Clear"],
        OpenFile     = buttons["OpenFile"],
        ExecuteFile  = buttons["ExecuteFile"],
        SaveFile     = buttons["SaveFile"],
        Options      = buttons["Options"],
        Attach       = buttons["Attach"],
        Hub          = buttons["Hub"],
    }
end

-- ══════════════════════════════════════════════════════════════
--  SYNTAX HIGHLIGHTING
--  Overlay approach:
--    HighlightLabel  (ZIndex 1) — RichText colored output, no interaction
--    CodeBox         (ZIndex 2) — transparent text, captures all input
--  Both sit inside EditorScroll, perfectly stacked.
-- ══════════════════════════════════════════════════════════════

-- ── Color palette ──────────────────────────────────────────
local Syntax = {
    Text          = Color3.fromRGB(204,204,204),
    Operator      = Color3.fromRGB(204,204,204),
    Number        = Color3.fromRGB(255,198,0),
    String        = Color3.fromRGB(173,241,149),
    Comment       = Color3.fromRGB(102,102,102),
    Keyword       = Color3.fromRGB(248,109,124),
    BuiltIn       = Color3.fromRGB(132,214,247),
    LocalMethod   = Color3.fromRGB(253,251,172),
    LocalProperty = Color3.fromRGB(97,161,241),
    Nil           = Color3.fromRGB(255,198,0),
    Bool          = Color3.fromRGB(255,198,0),
    Function      = Color3.fromRGB(248,109,124),
    Local         = Color3.fromRGB(248,109,124),
    Self          = Color3.fromRGB(248,109,124),
    FunctionName  = Color3.fromRGB(253,251,172),
    Bracket       = Color3.fromRGB(204,204,204),
}

local function colorToHex(c)
    return string.format("#%02x%02x%02x",
        math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end

-- ── Token lookup tables ────────────────────────────────────
local HL_KEYWORDS = {
    ["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,
    ["end"]=true,["for"]=true,["function"]=true,["if"]=true,["in"]=true,
    ["local"]=true,["not"]=true,["or"]=true,["repeat"]=true,["return"]=true,
    ["then"]=true,["until"]=true,["while"]=true,
    -- literals handled separately but kept here for keyword colour
    ["false"]=true,["true"]=true,["nil"]=true,
}
local HL_BUILTINS = {
    ["game"]=true,["Players"]=true,["TweenService"]=true,["ScreenGui"]=true,
    ["Instance"]=true,["UDim2"]=true,["Vector2"]=true,["Vector3"]=true,
    ["Color3"]=true,["Enum"]=true,["loadstring"]=true,["warn"]=true,
    ["pcall"]=true,["print"]=true,["UDim"]=true,["delay"]=true,
    ["require"]=true,["spawn"]=true,["tick"]=true,["getfenv"]=true,
    ["workspace"]=true,["setfenv"]=true,["getgenv"]=true,["script"]=true,
    ["string"]=true,["pairs"]=true,["type"]=true,["math"]=true,
    ["tonumber"]=true,["tostring"]=true,["CFrame"]=true,["BrickColor"]=true,
    ["table"]=true,["Random"]=true,["Ray"]=true,["xpcall"]=true,
    ["coroutine"]=true,["_G"]=true,["_VERSION"]=true,["debug"]=true,
    ["Axes"]=true,["assert"]=true,["error"]=true,["ipairs"]=true,
    ["rawequal"]=true,["rawget"]=true,["rawset"]=true,["select"]=true,
    ["bit32"]=true,["buffer"]=true,["task"]=true,["os"]=true,
}
local HL_METHODS = {
    ["WaitForChild"]=true,["FindFirstChild"]=true,["GetService"]=true,
    ["Destroy"]=true,["Clone"]=true,["IsA"]=true,["ClearAllChildren"]=true,
    ["GetChildren"]=true,["GetDescendants"]=true,["Connect"]=true,
    ["Disconnect"]=true,["Fire"]=true,["Invoke"]=true,["rgb"]=true,
    ["FireServer"]=true,["request"]=true,["call"]=true,
}

-- ── Tokeniser ──────────────────────────────────────────────
local function hlTokenize(line)
    local tokens, i = {}, 1
    while i <= #line do
        local c = line:sub(i,i)
        -- single-line comment
        if c == "-" and line:sub(i,i+1) == "--" then
            table.insert(tokens, {line:sub(i), "Comment"}); break
        -- long string / long comment bracket
        elseif c == "[" and line:sub(i,i+1):match("%[=*%[") then
            local eqCount, k = 0, i+1
            while line:sub(k,k) == "=" do eqCount += 1; k += 1 end
            if line:sub(k,k) == "[" then
                local close  = "]"..string.rep("=",eqCount).."]"
                local endIdx = line:find(close, k+1, true)
                local j      = endIdx and (endIdx + #close - 1) or #line
                table.insert(tokens, {line:sub(i,j), "String"}); i = j
            else
                table.insert(tokens, {c, "Operator"})
            end
        -- quoted strings
        elseif c == '"' or c == "'" then
            local q, j = c, i+1
            while j <= #line do
                if line:sub(j,j) == q and line:sub(j-1,j-1) ~= "\\" then break end
                j += 1
            end
            table.insert(tokens, {line:sub(i,j), "String"}); i = j
        -- numbers
        elseif c:match("%d") then
            local j = i
            while j <= #line and line:sub(j,j):match("[%d%.xXa-fA-F_]") do j += 1 end
            table.insert(tokens, {line:sub(i,j-1), "Number"}); i = j-1
        -- identifiers / keywords
        elseif c:match("[%a_]") then
            local j = i
            while j <= #line and line:sub(j,j):match("[%w_]") do j += 1 end
            table.insert(tokens, {line:sub(i,j-1), "Word"}); i = j-1
        else
            table.insert(tokens, {c, "Operator"})
        end
        i += 1
    end
    return tokens
end

-- ── Token classifier ───────────────────────────────────────
local function hlDetect(tokens, idx)
    local val, typ = tokens[idx][1], tokens[idx][2]
    if typ ~= "Word" then return typ end
    if val == "self"                    then return "Self"          end
    if val == "true" or val == "false"  then return "Bool"          end
    if val == "nil"                     then return "Nil"           end
    if HL_KEYWORDS[val]                 then return "Keyword"       end
    if HL_BUILTINS[val]                 then return "BuiltIn"       end
    if HL_METHODS[val]                  then return "LocalMethod"   end
    local prev = idx > 1 and tokens[idx-1][1] or ""
    if prev == "."                      then return "LocalProperty" end
    if prev == ":"                      then return "LocalMethod"   end
    -- name immediately after "function" keyword
    if prev == "function"               then return "FunctionName"  end
    return "Text"
end

-- ── Per-line highlighter ───────────────────────────────────
local function hlLine(line)
    local tokens = hlTokenize(line)
    local out    = ""
    for i, tok in ipairs(tokens) do
        local col  = Syntax[hlDetect(tokens, i)] or Syntax.Text
        local safe = tok[1]
            :gsub("&","&amp;")
            :gsub("<","&lt;")
            :gsub(">","&gt;")
        out ..= string.format('<font color="%s">%s</font>', colorToHex(col), safe)
    end
    return out
end

-- ── Full-source highlighter (called on every text change) ──
local function applySyntaxHighlight(source, overlayLabel)
    if not overlayLabel then return end
    local lines    = source:split("\n")
    local rendered = {}
    for _, ln in ipairs(lines) do
        rendered[#rendered+1] = hlLine(ln)
    end
    overlayLabel.Text = table.concat(rendered, "\n")
end

-- ══════════════════════════════════════════════════════════════
--  LINE NUMBER SYNC
-- ══════════════════════════════════════════════════════════════
local function updateLineNumbers(codeText, lineLabel)
    local count = 1
    for _ in codeText:gmatch("\n") do count += 1 end
    local lines = {}
    for i = 1, count do lines[i] = tostring(i) end
    lineLabel.Text = table.concat(lines, "\n")
end

-- ══════════════════════════════════════════════════════════════
--  INIT
-- ══════════════════════════════════════════════════════════════
local ui = createGui()

-- ── Open / Close toggle ────────────────────────────────────
ui.ToggleBtn.MouseButton1Click:Connect(function()
    local f = ui.MainFrame
    if f.Visible then
        TweenService:Create(f, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size     = UDim2.new(0, f.AbsoluteSize.X, 0, 0),
            Position = f.Position + UDim2.fromOffset(0, f.AbsoluteSize.Y / 2)
        }):Play()
        task.delay(0.18, function()
            f.Visible = false
            f.Size     = UDim2.fromOffset(706, 289)
            f.Position = UDim2.fromScale(0.062, 0.096)
        end)
    else
        f.Size    = UDim2.new(0, 706, 0, 0)
        f.Visible = true
        TweenService:Create(f, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(706, 289)
        }):Play()
    end
end)

-- ── Close button ───────────────────────────────────────────
ui.CloseBtn.MouseButton1Click:Connect(function()
    local f = ui.MainFrame
    TweenService:Create(f, TweenInfo.new(0.15), {
        Size = UDim2.new(0, f.AbsoluteSize.X, 0, 0)
    }):Play()
    task.delay(0.15, function()
        f.Visible = false
        f.Size = UDim2.fromOffset(706, 289)
    end)
end)

-- ── Minimize ───────────────────────────────────────────────
local minimized  = false
local FULL_SIZE  = UDim2.fromOffset(706, 289)
local MINI_SIZE  = UDim2.fromOffset(706, 28)

ui.MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(ui.MainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
        Size = minimized and MINI_SIZE or FULL_SIZE
    }):Play()
end)

-- ── Drag ───────────────────────────────────────────────────
do
    local dragging = false
    local dragStart, startPos = Vector2.zero, UDim2.new()
    local DRAG_TWEEN = TweenInfo.new(0.04)

    ui.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = ui.MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - dragStart
        TweenService:Create(ui.MainFrame, DRAG_TWEEN, {
            Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        }):Play()
    end)
end

-- ── CodeBox → line numbers + syntax highlight ─────────────
ui.CodeBox:GetPropertyChangedSignal("Text"):Connect(function()
    local src = ui.CodeBox.Text
    updateLineNumbers(src, ui.LineNumbers)
    applySyntaxHighlight(src, ui.HighlightLabel)
end)

-- ── Execute ────────────────────────────────────────────────
ui.Execute.MouseButton1Click:Connect(function()
    flash(ui.Execute)
    local code = ui.CodeBox.Text
    if code ~= "" then
        local fn, err = loadstring(code)
        if fn then
            local ok, runErr = pcall(fn)
            if not ok then warn("[SynapseUI] Runtime error: " .. tostring(runErr)) end
        else
            warn("[SynapseUI] Compile error: " .. tostring(err))
        end
    end
end)

-- ── Clear ──────────────────────────────────────────────────
ui.Clear.MouseButton1Click:Connect(function()
    flash(ui.Clear)
    ui.CodeBox.Text = ""
end)

-- ── Open File ──────────────────────────────────────────────
ui.OpenFile.MouseButton1Click:Connect(function()
    flash(ui.OpenFile)
    if readfile and isfile then
        local name = "autoexec.lua"
        if isfile(name) then
            ui.CodeBox.Text = readfile(name)
        else
            warn("[SynapseUI] File not found: " .. name)
        end
    else
        warn("[SynapseUI] readfile not available")
    end
end)

-- ── Execute File ───────────────────────────────────────────
ui.ExecuteFile.MouseButton1Click:Connect(function()
    flash(ui.ExecuteFile)
    if readfile and isfile then
        local name = "autoexec.lua"
        if isfile(name) then
            local fn, err = loadstring(readfile(name))
            if fn then
                local ok, e = pcall(fn)
                if not ok then warn("[SynapseUI] Runtime error: " .. tostring(e)) end
            else
                warn("[SynapseUI] Compile error: " .. tostring(err))
            end
        end
    else
        warn("[SynapseUI] readfile not available")
    end
end)

-- ── Save File ──────────────────────────────────────────────
ui.SaveFile.MouseButton1Click:Connect(function()
    flash(ui.SaveFile)
    if writefile then
        writefile("saved_script.lua", ui.CodeBox.Text)
        print("[SynapseUI] Saved to saved_script.lua")
    else
        warn("[SynapseUI] writefile not available")
    end
end)

-- ── Stubs ──────────────────────────────────────────────────
ui.Options.MouseButton1Click:Connect(function()
    flash(ui.Options)
    print("[SynapseUI] Options")
end)

ui.Attach.MouseButton1Click:Connect(function()
    flash(ui.Attach)
    -- toggle tint to show attached state
    local s = ui.Attach:FindFirstChildOfClass("UIStroke")
    if s then s.Color = T.ATTACH_ON end
    print("[SynapseUI] Attach")
end)

ui.Hub.MouseButton1Click:Connect(function()
    flash(ui.Hub)
    print("[SynapseUI] Script Hub")
end)

ui.TabClose.MouseButton1Click:Connect(function()
    ui.CodeBox.Text = ""
    print("[SynapseUI] Tab closed")
end)

ui.NewTab.MouseButton1Click:Connect(function()
    ui.CodeBox.Text = ""
    print("[SynapseUI] New tab")
end)
