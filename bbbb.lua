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
    
    -- NEW: Advanced options
    Debug = false,  -- Enable debug logging
    SpoofAvatar = false,  -- Spoof GetUserThumbnailAsync calls
    SpoofFriendStatus = false,  -- Spoof IsFriendsWith checks
    ProtectFromDetection = true,  -- Extra anti-detection measures
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

-- Cache real data
task_spawn(function()
    task_wait(0.5)  -- Wait for game to fully load
    RealUserData.UserId = lp.UserId
    RealUserData.Name = lp.Name
    RealUserData.DisplayName = lp.DisplayName
    DebugLog("Cached real user data:", RealUserData.UserId, RealUserData.Name)
end)

-- HELPER: Check if an object is the LocalPlayer's Character
local function isLocalCharacter(obj)
    if not obj then return false end
    local char = rawget(lp, "Character") or old_index(lp, "Character")
    return obj == char
end

-- HELPER: Get target player by ID (for avatar spoofing)
local cachedTargetPlayer = nil
local function getTargetPlayer()
    if cachedTargetPlayer then return cachedTargetPlayer end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId == getgenv().PhantomID.TargetID then
            cachedTargetPlayer = player
            return player
        end
    end
    return nil
end

-- ANTI-DETECTION: Simulate realistic behavior
local antiDetectionMeasures = {
    -- Prevent instant property checks
    lastPropertyAccess = {},
    
    -- Rate limit checks (prevents scripts from spam-checking properties)
    checkRateLimit = function(self, key)
        local now = tick()
        local last = self.lastPropertyAccess[key] or 0
        self.lastPropertyAccess[key] = now
        
        -- If checked more than 10 times per second, might be a detection script
        if now - last < 0.1 then
            DebugLog("RATE LIMIT WARNING on property:", key)
            return true  -- Potentially suspicious
        end
        return false
    end
}

-- CORE ENGINE
local old_index, old_namecall  -- Forward declare for use in isLocalCharacter

local function InitiatePhantomID()
    local mt = getrawmetatable(game)
    old_index = mt.__index
    old_namecall = mt.__namecall
    
    setreadonly(mt, false)
    
    -- 1. PROPERTY GHOST (__index)
    mt.__index = newcclosure(function(self, key)
        -- Use checkcaller FIRST to short-circuit for internal calls
        if checkcaller() or not getgenv().PhantomID.Enabled then
            return old_index(self, key)
        end
        
        -- Anti-detection check
        if getgenv().PhantomID.ProtectFromDetection then
            antiDetectionMeasures:checkRateLimit(key)
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
            -- NEW: Spoof AccountAge (make it match target if possible)
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
        if checkcaller() or not getgenv().PhantomID.Enabled then
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
        
        -- NEW: Spoof GetPlayerByUserId
        if self == Players and method == "GetPlayerByUserId" then
            if args[1] == getgenv().PhantomID.TargetID then
                DebugLog("Redirecting GetPlayerByUserId ->", lp.Name)
                return lp
            end
        end
        
        -- NEW: Spoof GetPlayerFromCharacter
        if self == Players and method == "GetPlayerFromCharacter" then
            if isLocalCharacter(args[1]) then
                DebugLog("GetPlayerFromCharacter called on spoofed character")
                return lp  -- Still return the real player object
            end
        end
        
        -- NEW: Spoof IsFriendsWith
        if getgenv().PhantomID.SpoofFriendStatus and typeof(self) == "Instance" and IsA(self, "Player") and self == lp then
            if method == "IsFriendsWith" then
                local target = getTargetPlayer()
                if target then
                    DebugLog("Spoofing IsFriendsWith")
                    return old_namecall(target, ...)
                end
            end
        end
        
        -- NEW: Spoof GetUserThumbnailAsync (avatar images)
        if getgenv().PhantomID.SpoofAvatar and self == Players and method == "GetUserThumbnailAsync" then
            if args[1] == getgenv().PhantomID.TargetID or args[1] == RealUserData.UserId then
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
end

-- 3. CHARACTER PHYSICAL SYNC
local function SyncCharacter(char)
    if not char then return end
    
    task_wait(0.1)
    
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
-- Allow toggling on/off during runtime
local function Toggle(state)
    getgenv().PhantomID.Enabled = state
    print("[PhantomID]", state and "ENABLED" or "DISABLED")
end

-- Allow changing target on the fly
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

-- 5. HEARTBEAT MONITOR (optional - detect if hooks are broken)
if getgenv().PhantomID.ProtectFromDetection then
    RunService.Heartbeat:Connect(function()
        -- Verify hooks are still active
        local mt = getrawmetatable(game)
        if mt.__index == old_index or mt.__namecall == old_namecall then
            warn("[PhantomID] CRITICAL: Hooks have been restored! Re-initializing...")
            InitiatePhantomID()
        end
    end)
end

-- INITIALIZE
task_spawn(function()
    InitiatePhantomID()
    
    -- Handle existing character
    if lp.Character then 
        SyncCharacter(lp.Character) 
    end
    
    -- Handle future respawns
    lp.CharacterAdded:Connect(SyncCharacter)
    
    print("[PhantomID] ✓ Initialized successfully")
    print("[PhantomID] Target:", getgenv().PhantomID.TargetName, "(" .. getgenv().PhantomID.TargetID .. ")")
    print("[PhantomID] Commands: PhantomID.Toggle(bool), PhantomID.SetTarget(id, name)")
end)
