--[[
    ARCHITECT: Callum
    PROJECT: PHANTOM-ID v2 (Workspace Synced)
    PURPOSE: Spoof UserId/Name and redirect Workspace queries to prevent Nil errors.
    PLACEMENT: /autoexec/ folder
]]

-- CONFIGURATION
getgenv().PhantomID = {
    Enabled = true,
    TargetID = 1, 
    TargetName = "Roblox",
    SpoofName = true -- Required for Workspace sync logic
}

-- SERVICES
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer

-- HELPER: Check if an object is the LocalPlayer's Character
local function isLocalCharacter(obj)
    return obj and lp.Character and obj == lp.Character
end

-- CORE ENGINE
local function InitiatePhantomID()
    local mt = getrawmetatable(game)
    local old_index = mt.__index
    local old_namecall = mt.__namecall
    setreadonly(mt, false)

    -- 1. PROPERTY SPOOFING (__index)
    mt.__index = newcclosure(function(self, key)
        if not checkcaller() and getgenv().PhantomID.Enabled then
            -- Handle Player Object
            if typeof(self) == "Instance" and self:IsA("Player") and self == lp then
                if key == "UserId" or key == "userId" then return getgenv().PhantomID.TargetID end
                if key == "Name" or key == "name" then return getgenv().PhantomID.TargetName end
                if key == "DisplayName" then return getgenv().PhantomID.TargetName end
            end

            -- Handle Character Model Name (The Workspace Model)
            if typeof(self) == "Instance" and isLocalCharacter(self) then
                if key == "Name" or key == "name" then
                    return getgenv().PhantomID.TargetName
                end
            end
        end
        return old_index(self, key)
    end)

    -- 2. METHOD REDIRECTION (__namecall)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if not checkcaller() and getgenv().PhantomID.Enabled then
            -- Redirect Workspace queries: workspace:FindFirstChild("Roblox") -> returns your real character
            if (method == "FindFirstChild" or method == "WaitForChild" or method == "FindFirstChildOfClass") then
                if self == Workspace and args[1] == getgenv().PhantomID.TargetName then
                    return lp.Character
                end
            end

            -- Handle method-based Name/ID calls
            if typeof(self) == "Instance" and self:IsA("Player") and self == lp then
                if method == "GetFullName" then
                    return "Players." .. getgenv().PhantomID.TargetName
                end
            end
            
            if typeof(self) == "Instance" and isLocalCharacter(self) then
                if method == "GetFullName" then
                    return "Workspace." .. getgenv().PhantomID.TargetName
                end
            end
        end

        return old_namecall(self, ...)
    end)

    setreadonly(mt, true)
end

-- 3. CHARACTER PHYSICAL SYNC
-- Locally renames the character model so internal engine lookups match.
local function SyncCharacter(char)
    if not char then return end
    task.wait(0.1) -- Small delay to ensure the character is fully parented
    
    -- We use a pcall because some ACs protect the Name property
    pcall(function()
        char.Name = getgenv().PhantomID.TargetName
    end)
end

-- INITIALIZE
task.spawn(function()
    InitiatePhantomID()
    
    -- Handle existing character
    if lp.Character then SyncCharacter(lp.Character) end
    
    -- Handle future respawns
    lp.CharacterAdded:Connect(SyncCharacter)
end)

print("[VANGUARD] PhantomID v2: Synchronized. Character & Player spoofed.")
