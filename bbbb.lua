--[[
    ARCHITECT: Callum
    PROJECT: PHANTOM-ID v2 (Workspace Synced) + AC Bypass
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
    BypassAntiCheat = true,  -- NEW: Enable AC bypass
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
local rawset = rawset
local typeof = typeof
local type = type
local pairs = pairs
local IsA = game.IsA
local pcall = pcall
local xpcall = xpcall
local task_spawn = task.spawn
local task_wait = task.wait
local debug_validlevel = debug and debug.validlevel
local getfenv = getfenv
local setreadonly = setreadonly or make_writeable
local newcclosure = newcclosure or function(f) return f end
local hookfunction = hookfunction or function(f) return f end
local hookmetamethod = hookmetamethod or hookmethod

-- Store original require
local _require = require

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
    local char = old_index(lp, "Character")
    return obj == char
end

-- HELPER: Get target player by ID (for avatar spoofing)
local cachedTargetPlayer = nil
local function getTargetPlayer()
    if cachedTargetPlayer and cachedTargetPlayer.Parent then 
        return cachedTargetPlayer 
    end
    
    local players_list = old_index(Players, "GetPlayers")(Players)
    for _, player in ipairs(players_list) do
        if old_index(player, "UserId") == getgenv().PhantomID.TargetID then
            cachedTargetPlayer = player
            return player
        end
    end
    return nil
end

-- ============================================================================
-- ANTI-CHEAT BYPASS FUNCTIONS
-- ============================================================================

-- Sanitize Carbon/AC modules
local function SanitizeCarbonModule(moduleScript)
    local success, moduleData = pcall(_require, moduleScript)
    if not success or type(moduleData) ~= "table" then 
        DebugLog("Module sanitization failed or not a table:", moduleScript.Name)
        return moduleData 
    end
    
    DebugLog("Sanitizing AC module:", moduleScript.Name)
    
    -- Common AC flag keys
    local flagKeys = {"Security", "Verify", "Check", "AntiCheat", "ExploitCheck", "Validate", "Authenticate"}
    
    for _, key in pairs(flagKeys) do
        if rawget(moduleData, key) ~= nil then
            DebugLog("Neutralizing flag:", key)
            rawset(moduleData, key, function() return true end)
        end
    end
    
    -- Remove integrity checks
    if rawget(moduleData, "Hash") or rawget(moduleData, "CheckSum") then
        DebugLog("Removing hash/checksum")
        rawset(moduleData, "Hash", nil)
        rawset(moduleData, "CheckSum", nil)
    end
    
    return moduleData
end

-- Hook require to intercept AC modules
local function ApplyRequirementHook()
    if not hookfunction then
        warn("[PhantomID] hookfunction not available, skipping require hook")
        return
    end
    
    local oldRequire
    oldRequire = hookfunction(_require, newcclosure(function(module)
        -- Only process external calls to ModuleScripts
        if not checkcaller() and typeof(module) == "Instance" and module:IsA("ModuleScript") then
            local moduleName = module.Name
            local moduleNameLower = moduleName:lower()
            
            -- Target specific AC modules (Carbon, common AC names)
            if moduleName == "1" and module.Parent and module.Parent.Name == "Settings" then
                DebugLog("Intercepting Carbon module '1'")
                return SanitizeCarbonModule(module)
            end
            
            -- Generic AC module detection
            if moduleNameLower:find("security") or 
               moduleNameLower:find("anticheat") or 
               moduleNameLower:find("anti") or
               moduleNameLower:find("detect") or
               moduleNameLower:find("check") then
                
                DebugLog("Intercepting suspected AC module:", moduleName)
                
                -- Return a dummy table that always returns true
                return setmetatable({}, {
                    __index = function() 
                        return function() return true end 
                    end,
                    __newindex = function() end  -- Ignore writes
                })
            end
        end
        
        return oldRequire(module)
    end))
    
    DebugLog("Require hook applied")
end

-- Neutralize render step AC loops
local function NeutralizeRenderLoops()
    if not hookmetamethod then
        warn("[PhantomID] hookmetamethod not available, skipping render hook")
        return
    end
    
    local success = pcall(function()
        local oldBind
        oldBind = hookmetamethod(RunService, "BindToRenderStep", newcclosure(function(self, name, priority, callback)
            if not checkcaller() then
                local lowerName = name:lower()
                
                -- Block suspicious render step names
                if lowerName:find("ac") or 
                   lowerName:find("security") or 
                   lowerName:find("verify") or
                   lowerName:find("anticheat") or
                   lowerName:find("detect") then
                    
                    DebugLog("Blocked render step:", name)
                    return nil 
                end
            end
            
            return oldBind(self, name, priority, callback)
        end))
    end)
    
    if success then
        DebugLog("Render loop hook applied")
    else
        warn("[PhantomID] Failed to hook BindToRenderStep")
    end
end

-- Block LogService methods (prevents AC logging)
local function BlockLogServiceMethods()
    pcall(function()
        local LogService = game:GetService("LogService")
        
        -- Hook ClearOutput
        if hookmetamethod then
            hookmetamethod(LogService, "ClearOutput", newcclosure(function()
                if not checkcaller() then
                    DebugLog("Blocked ClearOutput call")
                    return nil
                end
                return old_namecall(LogService)
            end))
        end
    end)
end

-- Initialize all AC bypass features
local function InitializeACBypass()
    if not getgenv().PhantomID.BypassAntiCheat then
        DebugLog("AC bypass disabled")
        return
    end
    
    DebugLog("Initializing AC bypass features...")
    
    pcall(ApplyRequirementHook)
    pcall(NeutralizeRenderLoops)
    pcall(BlockLogServiceMethods)
    
    print("[PhantomID] AC bypass initialized")
end

-- ============================================================================
-- CORE ID SPOOFING ENGINE
-- ============================================================================

local function InitiatePhantomID()
    local mt = getrawmetatable(game)
    old_index = mt.__index
    old_namecall = mt.__namecall
    old_newindex = mt.__newindex
    
    setreadonly(mt, false)
    
    -- 1. PROPERTY GHOST (__index) with Hidden Property Support
    mt.__index = newcclosure(function(t, k)
        local is_external_call = not checkcaller()
        
        -- Internal call with hidden property support
        if not is_external_call then
            if has_hidden_props and debug_validlevel and debug_validlevel(3) then
                local caller_env = getfenv(3)
                if caller_env ~= BLEnv then
                    local success, data = pcall(function() 
                        return old_index(t, k) 
                    end)
                    
                    if success then
                        return data
                    else
                        return safeGetHiddenProperty(t, k)
                    end
                end
            end
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
                    local success = pcall(function() 
                        old_newindex(t, k, v)
                    end)
                    
                    if not success then
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
        local is_external_call = not checkcaller()
        local method = getnamecallmethod()
        
        -- Block LogService methods from external calls (AC detection)
        if is_external_call and getgenv().PhantomID.BypassAntiCheat then
            if method == "ClearOutput" or method == "GetLogHistory" then
                DebugLog("Blocked LogService method:", method)
                return nil
            end
        end
        
        -- Internal calls bypass spoofing
        if not is_external_call then
            return old_namecall(self, ...)
        end
        
        if not getgenv().PhantomID.Enabled then
            return old_namecall(self, ...)
        end
        
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

-- CHARACTER PHYSICAL SYNC
local function SyncCharacter(char)
    if not char then return end
    
    DebugLog("SyncCharacter called for:", char)
    
    task_wait(0.2)
    
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

-- RUNTIME CONTROLS
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

-- ============================================================================
-- INITIALIZE EVERYTHING
-- ============================================================================

task_spawn(function()
    -- 1. Initialize AC bypass FIRST (before spoofing)
    InitializeACBypass()
    
    -- 2. Then initialize ID spoofing
    InitiatePhantomID()
    
    task_wait(0.5)
    
    -- 3. Handle character sync
    if lp.Character then 
        DebugLog("Character already exists, syncing...")
        SyncCharacter(lp.Character) 
    end
    
    lp.CharacterAdded:Connect(function(char)
        DebugLog("CharacterAdded event fired")
        SyncCharacter(char)
    end)
    
    -- 4. Print status
    print("[PhantomID] ✓ Initialized successfully")
    print("[PhantomID] Target:", getgenv().PhantomID.TargetName, "(" .. getgenv().PhantomID.TargetID .. ")")
    print("[PhantomID] Hidden Properties:", has_hidden_props and "Supported" or "Not Available")
    print("[PhantomID] AC Bypass:", getgenv().PhantomID.BypassAntiCheat and "Enabled" or "Disabled")
    print("[PhantomID] Commands: PhantomID.Toggle(bool), PhantomID.SetTarget(id, name)")
end)
