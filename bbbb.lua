--[[
    ARCHITECT: Callum
    PROJECT: PHANTOM-ID v2 (Workspace Synced)
    PURPOSE: Educational ID spoofing demonstration - practice only
    PLACEMENT: /autoexec/ folder
]]

-- CONFIGURATION
getgenv().PhantomID = {
    Enabled = true,
    TargetID = 1, 
    TargetName = "Roblox",
    SpoofName = true,
    
    -- Advanced options
    Debug = false,
    SpoofAvatar = false,
    SpoofFriendStatus = false,
    ProtectFromDetection = false,  -- Changed to false by default (can cause spawn issues)
}

-- SERVICES
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
if not lp then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    lp = Players.LocalPlayer
end

-- CACHED METHODS (prevents recursion)
local rawget = rawget
local typeof = typeof
local IsA = game.IsA
local pcall = pcall
local task_spawn = task.spawn
local task_wait = task.wait

-- DEBUG LOGGER
local function DebugLog(...)
    if getgenv().PhantomID.Debug then
        print("[PhantomID DEBUG]", ...)
    end
end

-- REAL ID CACHE (store before spoofing)
local RealUserData = {
    UserId = nil,
    Name = nil,
    DisplayName = nil,
    Character = nil
}

-- Forward declarations
local old_index, old_namecall

-- Cache real data BEFORE hooking
task_spawn(function()
    task_wait(0.1)
    RealUserData.UserId = lp.UserId
    RealUserData.Name = lp.Name
    RealUserData.DisplayName = lp.DisplayName
    DebugLog("Cached real user data:", RealUserData.UserId, RealUserData.Name)
end)

-- HELPER: Check if an object is the LocalPlayer's Character
local function isLocalCharacter(obj)
    if not obj then return false end
    -- Use old_index to prevent recursion
    local char = old_index(lp, "Character")
    return obj == char
end

-- HELPER: Get target player by ID (for avatar spoofing)
local cachedTargetPlayer = nil
local function getTargetPlayer()
    if cachedTargetPlayer and cachedTargetPlayer.Parent then 
        return cachedTargetPlayer 
    end
    
    -- Search for target player
    for _, player in ipairs(old_index(Players, "GetPlayers")(Players)) do
        if old_index(player, "UserId") == getgenv().PhantomID.TargetID then
            cachedTargetPlayer = player
            return player
        end
    end
    return nil
end

-- CORE ENGINE
local function InitiatePhantomID()
    local mt = getrawmetatable(game)
    old_index = mt.__index
    old_namecall = mt.__namecall
    
    setreadonly(mt, false)
    
    -- 1. PROPERTY GHOST (__index)
    mt.__index = newcclosure(function(self, key)
        -- CRITICAL: Check caller first and return immediately for internal calls
        if checkcaller() then
            return old_index(self, key)
        end
        
        if not getgenv().PhantomID.Enabled then
            return old_index(self, key)
        end
        
        -- Handle Player Object
        if typeof(self) == "Instance" and IsA(self, "Player") and self == lp then
            if key == "UserId" or key == "userId" then 
                DebugLog("Spoofing UserId ->", getgenv().PhantomID.TargetID)
                return getgenv().PhantomID.TargetID 
            end
            if key == "Name" or key == "name" then
                DebugLog("Spoofing Name ->", getgenv().PhantomID.TargetName)
                return getgenv().PhantomID.TargetName 
            end
            if key == "DisplayName" then
                DebugLog("Spoofing DisplayName ->", getgenv().PhantomID.TargetName)
                return getgenv().PhantomID.TargetName 
            end
            -- Spoof AccountAge (make it match target if possible)
            if key == "AccountAge" then
                local target = getTargetPlayer()
                if target then
                    return old_index(target, "AccountAge")
                end
            end
        end
        
        -- Handle Character Model Name
        if typeof(self) == "Instance" and isLocalCharacter(self) then
            if key == "Name" or key == "name" then
                DebugLog("Spoofing Character.Name ->", getgenv().PhantomID.TargetName)
                return getgenv().PhantomID.TargetName
            end
        end
        
        return old_index(self, key)
    end)
    
    -- 2. METHOD REDIRECTION (__namecall)
    mt.__namecall = newcclosure(function(self, ...)
        -- CRITICAL: Check caller first
        if checkcaller() then
            return old_namecall(self, ...)
        end
        
        if not getgenv().PhantomID.Enabled then
            return old_namecall(self, ...)
        end
        
        local method = getnamecallmethod()
        local args = {...}
        
        -- Redirect Workspace queries
        if self == Workspace and (method == "FindFirstChild" or method == "WaitForChild" or method == "FindFirstChildOfClass") then
            if args[1] == getgenv().PhantomID.TargetName then
                DebugLog("Redirecting Workspace:", method, "->", "LocalPlayer.Character")
                return old_index(lp, "Character")
            end
        end
        
        -- Spoof GetPlayerByUserId
        if self == Players and method == "GetPlayerByUserId" then
            if args[1] == getgenv().PhantomID.TargetID then
                DebugLog("Redirecting GetPlayerByUserId ->", lp.Name)
                return lp
            end
        end
        
        -- Spoof GetPlayerFromCharacter
        if self == Players and method == "GetPlayerFromCharacter" then
            if args[1] and isLocalCharacter(args[1]) then
                DebugLog("GetPlayerFromCharacter called on spoofed character")
                return lp
            end
        end
        
        -- Spoof IsFriendsWith
        if getgenv().PhantomID.SpoofFriendStatus and typeof(self) == "Instance" and IsA(self, "Player") and self == lp then
            if method == "IsFriendsWith" then
                local target = getTargetPlayer()
                if target then
                    DebugLog("Spoofing IsFriendsWith")
                    return old_namecall(target, ...)
                end
            end
        end
        
        -- Spoof GetUserThumbnailAsync (avatar images)
        if getgenv().PhantomID.SpoofAvatar and self == Players and method == "GetUserThumbnailAsync" then
            if args[1] == RealUserData.UserId then
                DebugLog("Spoofing GetUserThumbnailAsync")
                args[1] = getgenv().PhantomID.TargetID
                return old_namecall(self, unpack(args))
            end
        end
        
        -- Handle method-based Name/ID calls
        if typeof(self) == "Instance" and IsA(self, "Player") and self == lp then
            if method == "GetFullName" then
                return "Players." .. getgenv().PhantomID.TargetName
            end
        end
        
        if typeof(self) == "Instance" and isLocalCharacter(self) then
            if method == "GetFullName" then
                return "Workspace." .. getgenv().PhantomID.TargetName
            end
        end
        
        return old_namecall(self, ...)
    end)
    
    setreadonly(mt, true)
    DebugLog("Metatable hooks initialized")
end

-- 3. CHARACTER PHYSICAL SYNC
local function SyncCharacter(char)
    if not char then return end
    
    DebugLog("SyncCharacter called for:", char)
    
    -- Wait for character to be fully loaded
    task_wait(0.2)
    
    -- Protect against AC detection
    local success, err = pcall(function()
        char.Name = getgenv().PhantomID.TargetName
    end)
    
    if not success then
        warn("[PhantomID] Failed to sync character name:", err)
    else
        DebugLog("Character synced successfully:", char.Name)
    end
    
    -- Store reference
    RealUserData.Character = char
end

-- 4. RUNTIME CONTROLS
local function Toggle(state)
    getgenv().PhantomID.Enabled = state
    print("[PhantomID]", state and "ENABLED" or "DISABLED")
end

local function SetTarget(userId, userName)
    getgenv().PhantomID.TargetID = userId
    getgenv().PhantomID.TargetName = userName
    cachedTargetPlayer = nil  -- Reset cache
    
    -- Re-sync character if it exists
    if lp.Character then
        SyncCharacter(lp.Character)
    end
    
    print("[PhantomID] Target updated:", userName, "(" .. userId .. ")")
end

-- Expose API
getgenv().PhantomID.Toggle = Toggle
getgenv().PhantomID.SetTarget = SetTarget
getgenv().PhantomID.GetRealData = function() return RealUserData end

-- INITIALIZE
task_spawn(function()
    -- Initialize hooks FIRST
    InitiatePhantomID()
    
    -- Small delay to let game initialize
    task_wait(0.5)
    
    -- Handle existing character
    if lp.Character then 
        DebugLog("Character already exists, syncing...")
        SyncCharacter(lp.Character) 
    end
    
    -- Handle future respawns
    lp.CharacterAdded:Connect(function(char)
        DebugLog("CharacterAdded event fired")
        SyncCharacter(char)
    end)
    
    print("[PhantomID] ✓ Initialized successfully")
    print("[PhantomID] Target:", getgenv().PhantomID.TargetName, "(" .. getgenv().PhantomID.TargetID .. ")")
    print("[PhantomID] Commands: PhantomID.Toggle(bool), PhantomID.SetTarget(id, name)")
    
    if getgenv().PhantomID.Debug then
        print("[PhantomID] Debug mode enabled")
    end
end)
