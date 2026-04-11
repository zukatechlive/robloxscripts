--[[
    ARCHITECT: Callum
    PROJECT: PHANTOM-ID v2 (Workspace Synced) + Hidden Property Support
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
    ProtectFromDetection = false,
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

-- CACHED METHODS (prevents recursion and C stack overflow)
local rawget = rawget
local typeof = typeof
local IsA = game.IsA
local pcall = pcall
local xpcall = xpcall
local task_spawn = task.spawn
local task_wait = task.wait
local debug_validlevel = debug and debug.validlevel
local getfenv = getfenv
local setreadonly = setreadonly or make_writeable
local newcclosure = newcclosure or function(f) return f end

-- Check if hidden property functions exist
local has_hidden_props = gethiddenproperty ~= nil and sethiddenproperty ~= nil

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
local old_index, old_namecall, old_newindex
local BLEnv

-- Cache the hidden property environment ONCE to prevent repeated lookups
if has_hidden_props then
    local success, env = pcall(function()
        return getfenv(gethiddenproperty)
    end)
    BLEnv = success and env or nil
end

-- Cache real data BEFORE hooking
task_spawn(function()
    task_wait(0.1)
    RealUserData.UserId = lp.UserId
    RealUserData.Name = lp.Name
    RealUserData.DisplayName = lp.DisplayName
    DebugLog("Cached real user data:", RealUserData.UserId, RealUserData.Name)
end)

-- HELPER: Safe hidden property getter (prevents C stack overflow)
local function safeGetHiddenProperty(obj, prop)
    if not has_hidden_props then return nil end
    
    -- Use xpcall with error handler to prevent stack overflow
    local success, result = xpcall(function()
        return gethiddenproperty(obj, prop)
    end, function(err)
        DebugLog("Hidden property get error:", err)
        return nil
    end)
    
    return success and result or nil
end

-- HELPER: Safe hidden property setter (prevents C stack overflow)
local function safeSetHiddenProperty(obj, prop, value)
    if not has_hidden_props then return false end
    
    local success = xpcall(function()
        sethiddenproperty(obj, prop, value)
        return true
    end, function(err)
        DebugLog("Hidden property set error:", err)
        return false
    end)
    
    return success
end

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
    local players_list = old_index(Players, "GetPlayers")(Players)
    for _, player in ipairs(players_list) do
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
    old_newindex = mt.__newindex
    
    setreadonly(mt, false)
    
    -- 1. PROPERTY GHOST (__index) with Hidden Property Support
    mt.__index = newcclosure(function(t, k)
        -- CRITICAL: Check caller FIRST - immediate return for internal calls
        local is_external_call = not checkcaller()
        
        -- If it's an internal call, check for hidden property access
        if not is_external_call then
            -- Only attempt hidden property if valid level and not from BLEnv
            if has_hidden_props and debug_validlevel and debug_validlevel(3) then
                local caller_env = getfenv(3)
                if caller_env ~= BLEnv then
                    -- Try normal index first
                    local success, data = pcall(function() 
                        return old_index(t, k) 
                    end)
                    
                    if success then
                        return data
                    else
                        -- Fall back to hidden property
                        return safeGetHiddenProperty(t, k)
                    end
                end
            end
            -- Normal internal call
            return old_index(t, k)
        end
        
        -- External call - apply spoofing
        if not getgenv().PhantomID.Enabled then
            return old_index(t, k)
        end
        
        -- Handle Player Object spoofing
        if typeof(t) == "Instance" and IsA(t, "Player") and t == lp then
            if k == "UserId" or k == "userId" then 
                DebugLog("Spoofing UserId ->", getgenv().PhantomID.TargetID)
                return getgenv().PhantomID.TargetID 
            end
            if k == "Name" or k == "name" then
                DebugLog("Spoofing Name ->", getgenv().PhantomID.TargetName)
                return getgenv().PhantomID.TargetName 
            end
            if k == "DisplayName" then
                DebugLog("Spoofing DisplayName ->", getgenv().PhantomID.TargetName)
                return getgenv().PhantomID.TargetName 
            end
            if k == "AccountAge" then
                local target = getTargetPlayer()
                if target then
                    return old_index(target, "AccountAge")
                end
            end
        end
        
        -- Handle Character Model Name spoofing
        if typeof(t) == "Instance" and isLocalCharacter(t) then
            if k == "Name" or k == "name" then
                DebugLog("Spoofing Character.Name ->", getgenv().PhantomID.TargetName)
                return getgenv().PhantomID.TargetName
            end
        end
        
        return old_index(t, k)
    end)
    
    -- 2. PROPERTY SETTER (__newindex) with Hidden Property Support
    mt.__newindex = newcclosure(function(t, k, v)
        local is_external_call = not checkcaller()
        
        -- Internal call with hidden property support
        if not is_external_call then
            if has_hidden_props and debug_validlevel and debug_validlevel(3) then
                local caller_env = getfenv(3)
                if caller_env ~= BLEnv then
                    -- Try normal newindex first
                    local success = pcall(function() 
                        old_newindex(t, k, v)
                    end)
                    
                    if not success then
                        -- Fall back to hidden property setter
                        safeSetHiddenProperty(t, k, v)
                    end
                    return
                end
            end
            return old_newindex(t, k, v)
        end
        
        -- External calls - normal behavior
        return old_newindex(t, k, v)
    end)
    
    -- 3. METHOD REDIRECTION (__namecall)
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
        
        -- Spoof GetUserThumbnailAsync
        if getgenv().PhantomID.SpoofAvatar and self == Players and method == "GetUserThumbnailAsync" then
            if args[1] == RealUserData.UserId then
                DebugLog("Spoofing GetUserThumbnailAsync")
                args[1] = getgenv().PhantomID.TargetID
                return old_namecall(self, unpack(args))
            end
        end
        
        -- Handle GetFullName
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
    DebugLog("Metatable hooks initialized with hidden property support:", has_hidden_props)
end

-- 4. CHARACTER PHYSICAL SYNC
local function SyncCharacter(char)
    if not char then return end
    
    DebugLog("SyncCharacter called for:", char)
    
    -- Wait for character to be fully loaded
    task_wait(0.2)
    
    -- Try both normal and hidden property methods
    local success = pcall(function()
        char.Name = getgenv().PhantomID.TargetName
    end)
    
    if not success and has_hidden_props then
        DebugLog("Normal Name set failed, trying hidden property...")
        success = safeSetHiddenProperty(char, "Name", getgenv().PhantomID.TargetName)
    end
    
    if not success then
        warn("[PhantomID] Failed to sync character name")
    else
        DebugLog("Character synced successfully:", char.Name)
    end
    
    RealUserData.Character = char
end

-- 5. RUNTIME CONTROLS
local function Toggle(state)
    getgenv().PhantomID.Enabled = state
    print("[PhantomID]", state and "ENABLED" or "DISABLED")
end

local function SetTarget(userId, userName)
    getgenv().PhantomID.TargetID = userId
    getgenv().PhantomID.TargetName = userName
    cachedTargetPlayer = nil
    
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
    InitiatePhantomID()
    
    task_wait(0.5)
    
    if lp.Character then 
        DebugLog("Character already exists, syncing...")
        SyncCharacter(lp.Character) 
    end
    
    lp.CharacterAdded:Connect(function(char)
        DebugLog("CharacterAdded event fired")
        SyncCharacter(char)
    end)
    
    print("[PhantomID] ✓ Initialized successfully")
    print("[PhantomID] Target:", getgenv().PhantomID.TargetName, "(" .. getgenv().PhantomID.TargetID .. ")")
    print("[PhantomID] Hidden Properties:", has_hidden_props and "Supported" or "Not Available")
    print("[PhantomID] Commands: PhantomID.Toggle(bool), PhantomID.SetTarget(id, name)")
end)
