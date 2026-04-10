if getgenv().ZexAddon_Loaded then return end
getgenv().ZexAddon_Loaded = true
local set_ro = setreadonly
    or (make_writeable and function(t, v)
        if v then make_readonly(t) else make_writeable(t) end
    end)
    or function() end
local get_mt        = getrawmetatable or debug.getmetatable
local hook_meta     = hookmetamethod
local new_cc        = newcclosure or function(f) return f end
local check_caller  = checkcaller or function() return false end
local hook_fn       = hookfunction or function() end
local gc            = getgc or get_gc_objects or function() return {} end
local is_our_thread = isourclosure or function() return false end

             -- haha get owned adonis noobs!!!!1111!!!!

local Stats = {
    KickAttempts        = 0,
    RemotesBlocked      = 0,
    DetectionsCaught    = 0,
    FunctionsHooked     = 0,
    ClientChecksBlocked = 0,
    RemotesFired        = 0,
}

local HookedFunctions   = {}
local cachedACTable     = nil
local originalFunctions = {}
local isUnloaded        = false
local Services = setmetatable({}, {
    __index = function(t, k)
        local ok, s = pcall(function() return game:GetService(k) end)
        if ok and s then rawset(t, k, s) end
        return s
    end
})
local gcCache     = nil
local gcCacheTime = 0
local GC_CACHE_TTL = 30
local function getCachedGC()
    local now = os.clock()
    if gcCache and (now - gcCacheTime) < GC_CACHE_TTL then
        return gcCache
    end
    local ok, objs = pcall(gc, true)
    if ok and objs then
        gcCache     = objs
        gcCacheTime = now
    end
    return gcCache
end
local function safe(fn, ...)
    local ok, result = pcall(fn, ...)
    return ok and result or nil
end
local function safeHook(original, replacement)
    if type(original) ~= "function" then return false end
    local ok = pcall(hook_fn, original, new_cc(replacement))
    if not ok then return false end
    table.insert(HookedFunctions, original)
    Stats.FunctionsHooked += 1
    return true
end
local function dismantle_readonly(target)
    if type(target) ~= "table" then return end
    pcall(function()
        if set_ro then set_ro(target, false) end
        local mt = get_mt(target)
        if mt then pcall(set_ro, mt, false) end
    end)
end
for _, fn in ipairs({ getgenv, getrenv, getreg }) do
    if type(fn) == "function" then
        local ok, env = pcall(fn)
        if ok and type(env) == "table" then
            dismantle_readonly(env)
        end
    end
end
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = Services.Players
repeat task.wait(0.1) until Players and Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer
do
    local stackThreshold    = 195
    local stackThresholdMax = 198
    local firstError        = "C stack overflow"
    local secondError       = "cannot resume dead coroutine"
    local pack, unpack_  = table.pack, unpack
    local info, find_    = debug.info, table.find
    local luaCacheFuncs  = {}
    local StackCache     = {}
    local WrapHook
    local function checkValidity(func)
        if info(func, "s") ~= "[C]" then return false end
        return true
    end
    local function isInCache(func)
        for _, tbl in StackCache do
            if tbl.Wrapped == func or tbl.ReplacementFunc == func then
                return tbl
            end
        end
        return nil
    end
    local function insertInCache(func, wrapped)
        if type(func) ~= "function" or type(wrapped) ~= "function" then return end
        local New
        New = {
            WrapCount      = 1,
            Original       = func,
            ReplacementFunc = function(...)
                local args = pack(pcall(WrapHook(func), ...))
                if not args[1] then
                    local err = args[2]
                    if err ~= "cannot resume dead coroutine" and New.WrapCount > stackThresholdMax then
                        task.spawn(New.Gc)
                        return getrenv().error(firstError, 2)
                    elseif err == "cannot resume dead coroutine"
                        or select(2, pcall(WrapHook(wrapped))) == "cannot resume dead coroutine" then
                        task.spawn(New.Gc)
                        return getrenv().error(secondError, 2)
                    end
                    task.spawn(New.Gc)
                    return getrenv().error(err, 2)
                end
                task.spawn(New.Gc)
                return unpack_(args, 2, args.n)
            end,
            Wrapped = wrapped,
            Gc = function()
                local idx = table.find(StackCache, New)
                if idx then table.remove(StackCache, idx) end
            end,
        }
        table.insert(StackCache, New)
    end
    WrapHook = hook_fn(getrenv().coroutine.wrap, new_cc(function(...)
        local Target = ...
        if not check_caller() and type(Target) == "function" then
            local CacheTbl = isInCache(Target)
            if CacheTbl then
                local valid = checkValidity(Target)
                if not valid then
                    local res = WrapHook(...)
                    local pos = table.find(luaCacheFuncs, Target)
                    if pos then
                        luaCacheFuncs[pos] = res
                    else
                        table.insert(luaCacheFuncs, res)
                    end
                    return res
                end
                CacheTbl.WrapCount += 1
                if CacheTbl.WrapCount == stackThreshold then
                    local nf = WrapHook(CacheTbl.ReplacementFunc)
                    CacheTbl.Original, CacheTbl.ReplacementFunc = nf, nf
                    CacheTbl.Wrapped = WrapHook(CacheTbl.Wrapped)
                    return nf
                elseif CacheTbl.WrapCount < stackThreshold or CacheTbl.WrapCount > stackThresholdMax then
                    local nf = WrapHook(CacheTbl.Wrapped)
                    CacheTbl.Wrapped = nf
                    return nf
                end
                local nf = WrapHook(CacheTbl.ReplacementFunc)
                CacheTbl.Original, CacheTbl.ReplacementFunc = nf, nf
                CacheTbl.Wrapped = WrapHook(WrapHook(CacheTbl.Wrapped))
                return nf
            else
                local arg = WrapHook(...)
                insertInCache(Target, arg)
                return arg
            end
        end
        return WrapHook(...)
    end))
    print("[ZexAddon] C-stack overflow bypass: active")
end
do
    local oldDebugInfo   = debug.info
    local adonisCache    = {}
    hook_fn(debug.info, new_cc(function(target, fmt, ...)
        if check_caller() then
            return oldDebugInfo(target, fmt, ...)
        end
        if type(target) == "function" and type(fmt) == "string" and fmt:find("f") then
            if not adonisCache[target] then
                local results = table.pack(oldDebugInfo(target, fmt, ...))
                adonisCache[target] = results
                return table.unpack(results, 1, results.n)
            else
                local c = adonisCache[target]
                return table.unpack(c, 1, c.n)
            end
        end
        return oldDebugInfo(target, fmt, ...)
    end))
    print("[ZexAddon] debug.info tamper neutralizer: active")
end
do
    local testFn = new_cc(function() end)
    local s = debug.info(testFn, "s")
    local l = debug.info(testFn, "l")
    local n = debug.info(testFn, "n")
    local a = debug.info(testFn, "a")
    if s ~= "[C]" or l ~= -1 or n ~= "" or a ~= 0 then
        warn(string.format(
            "[ZexAddon] WARNING: newcclosure may not pass Adonis metamethod validity! source=%s line=%s name=%s args=%s",
            tostring(s), tostring(l), tostring(n), tostring(a)
        ))
    else
        print("[ZexAddon] newcclosure validity check: OK")
    end
end
local _require = getrenv().require
local function SanitizeCarbonModule(moduleScript)
    local success, moduleData = pcall(_require, moduleScript)
    if not success or type(moduleData) ~= "table" then return moduleData end
    for _, key in pairs({"Security","Verify","Check","AntiCheat","ExploitCheck"}) do
        if rawget(moduleData, key) ~= nil then
            rawset(moduleData, key, function() return true end)
        end
    end
    if rawget(moduleData, "Hash") or rawget(moduleData, "CheckSum") then
        rawset(moduleData, "Hash",     nil)
        rawset(moduleData, "CheckSum", nil)
    end
    return moduleData
end
local oldRequire
oldRequire = hook_fn(_require, new_cc(function(module)
    if check_caller() then return oldRequire(module) end
    if typeof(module) == "Instance" and module:IsA("ModuleScript") then
        if module.Name == "1" and module.Parent and module.Parent.Name == "Settings" then
            return SanitizeCarbonModule(module)
        end
        local name = module.Name:lower()
        if name:find("security") or name:find("anticheat") then
            return setmetatable({}, {
                __index = function() return function() return true end end
            })
        end
        if name:find("topbar") or name:find("icon") or
           name:find("adonis") or name:find("aethetic") then
            return setmetatable({}, {
                __index    = function() return function() end end,
                __newindex = function() end,
                __call     = function() return {} end,
            })
        end
    end
    return oldRequire(module)
end))
do
    local oldBind
    oldBind = hook_fn(RunService and RunService.BindToRenderStep or
        game:GetService("RunService").BindToRenderStep,
        new_cc(function(self, name, priority, callback)
            if not check_caller() then
                local lower = name:lower()
                if lower:find("ac") or lower:find("security") or lower:find("verify") then
                    return nil
                end
            end
            return oldBind(self, name, priority, callback)
        end)
    )
end
local AC_SIGNATURES = {
    { "Detected",           true,  1   },
    { "RemovePlayer",       true,  1   },
    { "CheckAllClients",    true,  1   },
    { "KickedPlayers",      false, 1   },
    { "SpoofCheckCache",    false, 1   },
    { "ClientTimeoutLimit", false, 1   },
    { "CharacterCheck",     true,  0.5 },
    { "UserSpoofCheck",     true,  0.5 },
    { "AntiCheatEnabled",   false, 1   },
    { "GetPlayer",          true,  0.5 },
}
local AC_SCORE_THRESHOLD = 3
local function scoreTable(v)
    if type(v) ~= "table" then return 0 end
    if rawget(v, "Detected") == nil and rawget(v, "RemovePlayer") == nil then
        return 0
    end
    local score = 0
    pcall(function()
        for _, sig in ipairs(AC_SIGNATURES) do
            local name, isFunc, weight = sig[1], sig[2], sig[3]
            local val = rawget(v, name)
            if val ~= nil then
                if isFunc then
                    if type(val) == "function" then score += weight end
                else
                    score += weight
                end
            end
        end
    end)
    return score
end
local function findACTable()
    local objs = getCachedGC()
    if not objs then return nil end
    for _, v in ipairs(objs) do
        local ok, isT = pcall(function() return type(v) == "table" end)
        if ok and isT and scoreTable(v) >= AC_SCORE_THRESHOLD then
            return v
        end
    end
    return nil
end
local function hookACTable(tbl)
    if not tbl then return end
    if type(tbl.Detected) == "function" then
        safeHook(tbl.Detected, function(player, action, info)
            Stats.DetectionsCaught += 1
        end)
    end
    if type(tbl.RemovePlayer) == "function" then
        safeHook(tbl.RemovePlayer, function(p, info)
            Stats.KickAttempts += 1
        end)
    end
    if type(tbl.CheckAllClients) == "function" then
        safeHook(tbl.CheckAllClients, function(...)
            Stats.ClientChecksBlocked += 1
        end)
    end
    if type(tbl.UserSpoofCheck) == "function" then
        safeHook(tbl.UserSpoofCheck, function(p, ...) return nil end)
    end
    if type(tbl.CharacterCheck) == "function" then
        safeHook(tbl.CharacterCheck, function(...) end)
    end
    if type(tbl.KickedPlayers) == "table" then
        local mt = getmetatable(tbl.KickedPlayers) or {}
        rawset(mt, "__index",    function() return false end)
        rawset(mt, "__newindex", function() end)
        rawset(mt, "__len",      function() return 0 end)
        pcall(setmetatable, tbl.KickedPlayers, mt)
    end
    if type(tbl.SpoofCheckCache) == "table" then
        local mt = {}
        rawset(mt, "__index", function(t, k)
            return {{
                Id          = k,
                Username    = LocalPlayer.Name,
                DisplayName = LocalPlayer.DisplayName,
                UserId      = LocalPlayer.UserId,
            }}
        end)
        rawset(mt, "__newindex", function() end)
        pcall(setmetatable, tbl.SpoofCheckCache, mt)
    end
    if tbl.ClientTimeoutLimit ~= nil then
        pcall(function() tbl.ClientTimeoutLimit = math.huge end)
    end
    if tbl.AntiCheatEnabled ~= nil then
        pcall(function() tbl.AntiCheatEnabled = false end)
    end
end
local function findAndPatchRemoteClients()
    local userId = tostring(LocalPlayer.UserId)
    local objs   = getCachedGC()
    if not objs then return end
    for _, v in ipairs(objs) do
        local ok2, isT = pcall(function() return type(v) == "table" end)
        if not (ok2 and isT) then continue end
        local ok3, client, hasMaxLen = pcall(function()
            return rawget(v, userId), rawget(v, "MaxLen")
        end)
        if not (ok3 and type(client) == "table") then continue end
        local ok4, hasLastUpdate = pcall(function()
            return rawget(client, "LastUpdate") ~= nil
        end)
        if ok4 and hasLastUpdate and hasMaxLen ~= nil then
            task.spawn(function()
                while not isUnloaded do
                    task.wait(8)
                    pcall(function()
                        local c = v[userId]
                        if c then
                            c.LastUpdate   = os.time()
                            c.PlayerLoaded = true
                        end
                    end)
                end
            end)
        end
    end
end
local REMOTE_BLOCK_EXACT = {
    ["__FUNCTION"]      = true,
    ["_FUNCTION"]       = true,
    ["ClientCheck"]     = true,
    ["ProcessCommand"]  = true,
    ["ClientLoaded"]    = true,
    ["ActivateCommand"] = true,
    ["Disconnect"]      = true,
}
local REMOTE_BLOCK_PATTERNS = {
    "anticheat","anti_cheat","kickplayer","banplayer",
    "reportexploit","detectclient","cheatcheck",
}
local function shouldBlockRemote(remoteName)
    if REMOTE_BLOCK_EXACT[remoteName] then return true end
    local lower = remoteName:lower()
    for _, pat in ipairs(REMOTE_BLOCK_PATTERNS) do
        if lower:find(pat, 1, true) then return true end
    end
    return false
end
local function installNamecallHook()
    local mt = get_mt(game)
    if not mt then return end
    local oldNamecall = mt.__namecall
    originalFunctions.namecall = oldNamecall
    pcall(set_ro, mt, false)
    mt.__namecall = new_cc(function(self, ...)
        if isUnloaded then return oldNamecall(self, ...) end
        local method = getnamecallmethod()
        local args   = { ... }
        if check_caller() then
            return oldNamecall(self, ...)
        end
        if method == "Kick" and self == LocalPlayer then
            local msg = tostring(args[1] or ""):lower()
            for _, kw in ipairs({"adonis","anti.?cheat","exploit","acli","detected","cheat","ban"}) do
                if msg:find(kw) then
                    Stats.KickAttempts += 1
                    return nil
                end
            end
        end
        if method == "FireServer" or method == "InvokeServer" then
            local name = (typeof(self) == "Instance" and self.Name) or ""
            if shouldBlockRemote(name) then
                Stats.RemotesBlocked += 1
                if method == "InvokeServer" then return "Pong" end
                return nil
            end
            Stats.RemotesFired += 1
        end
        return oldNamecall(self, ...)
    end)
    pcall(set_ro, mt, true)
end
local function installDebugHooks()
    local function isHooked(fn)
        for _, h in ipairs(HookedFunctions) do
            if fn == h then return true end
        end
        return false
    end
    local function wrapDebugFn(fn, fallback)
        if type(fn) ~= "function" then return end
        pcall(hook_fn, fn, new_cc(function(target, ...)
            if isHooked(target) then return fallback end
            return fn(target, ...)
        end))
    end
    wrapDebugFn(debug.info or debug.getinfo, nil)
    wrapDebugFn(debug.getupvalues,  {})
    wrapDebugFn(debug.getlocals,    {})
    wrapDebugFn(debug.getconstants, {})
end
local function protectKick()
    local origKick = LocalPlayer.Kick
    originalFunctions.kick = origKick
    safeHook(origKick, function(self, reason, ...)
        if check_caller() then
            return origKick(self, reason, ...)
        end
        if self == LocalPlayer then
            local msg = tostring(reason or ""):lower()
            for _, kw in ipairs({"adonis","anti.?cheat","exploit","acli","cheat","ban","detected"}) do
                if msg:find(kw) then
                    Stats.KickAttempts += 1
                    return nil
                end
            end
        end
        return origKick(self, reason, ...)
    end)
end
local function rescan()
    gcCache = nil
    local tbl = findACTable()
    if tbl and tbl ~= cachedACTable then
        cachedACTable = tbl
        hookACTable(tbl)
        warn("[ZexAddon] New AC table found and hooked during rescan.")
    end
    findAndPatchRemoteClients()
end
local function initialize()
    installNamecallHook()
    installDebugHooks()
    protectKick()
    cachedACTable = findACTable()
    if cachedACTable then
        hookACTable(cachedACTable)
    end
    findAndPatchRemoteClients()
    task.spawn(function()
        while not isUnloaded do
            task.wait(45)
            rescan()
        end
    end)
    task.spawn(function()
        while not isUnloaded do
            task.wait(60)
            pcall(function()
                warn(string.format(
                    "[ZexAddon] Stats | Kicks: %d | Remotes: %d | Detections: %d | ClientChecks: %d | Hooks: %d",
                    Stats.KickAttempts, Stats.RemotesBlocked, Stats.DetectionsCaught,
                    Stats.ClientChecksBlocked, Stats.FunctionsHooked
                ))
            end)
        end
    end)
end
getgenv().ZexAddon = {
    Version = "3.0",
    GetStats = function()
        return {
            KickAttempts        = Stats.KickAttempts,
            RemotesBlocked      = Stats.RemotesBlocked,
            DetectionsCaught    = Stats.DetectionsCaught,
            ClientChecksBlocked = Stats.ClientChecksBlocked,
            FunctionsHooked     = Stats.FunctionsHooked,
            RemotesFired        = Stats.RemotesFired,
        }
    end,
    PrintStats = function()
        local s = getgenv().ZexAddon.GetStats()
        for k, v in pairs(s) do
            print(string.format("  %s: %d", k, v))
        end
    end,
    Rescan = function()
        rescan()
        warn("[ZexAddon] Manual rescan complete.")
    end,
    Unload = function()
        isUnloaded = true
        getgenv().ZexAddon_Loaded = nil
        warn("[ZexAddon] Unloaded.")
    end,
    BlockRemote = function(name)
        REMOTE_BLOCK_EXACT[name] = true
        warn("[ZexAddon] Now blocking remote: " .. tostring(name))
    end,
    UnblockRemote = function(name)
        REMOTE_BLOCK_EXACT[name] = nil
        warn("[ZexAddon] Unblocked remote: " .. tostring(name))
    end,
}
initialize()
print("v3.0 ready.")
