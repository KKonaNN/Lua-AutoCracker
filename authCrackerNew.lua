-- the idea is to crack the auth system of a script by logging all the function calls and their results
-- the script will be able to replay the function calls and their results to bypass the auth system
-- so 1 run of the script will be enough to bypass the auth system (i hope so <3)

local file = LoadResourceFile(GetCurrentResourceName(), "data.json")
local webhook = ""

if not file then
    SaveResourceFile(GetCurrentResourceName(), "data.json", "[]", -1)
    file = "[]"
end

local function tableLength(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1

        if count > 3 then
            return count
        end
    end
    return count
end

local ascii = [[
            ______ __                   _____   __
            ___  //_/__________________ ___  | / /
            __  ,<  _  __ \_  __ \  __ `/_   |/ / 
            _  /| | / /_/ /  / / / /_/ /_  /|  /  
            /_/ |_| \____//_/ /_/\__,_/ /_/ |_/                                                
                                 discord.gg/luauth
]]

print(ascii)

RemoveEventHandler = function() end

local crack_data = json.decode(file)
local crack_now = tableLength(crack_data) > 0

local stored_data = crack_now and crack_data or {}
local debug_now = false
local this = debug.getinfo(1, "S").short_src


local real_functions = {
	["dump"] = string.dump,
	["format"] = string.format,
    ["find"] = string.find,
	["traceback"] = debug.traceback,
	["popen"] = io.popen,
	["getinfo"] = debug.getinfo,
	["random"] = math.random,
	["tostring"] = tostring,
	["date"] = os.date,
	["time"] = os.time,
	["execute"] = os.execute,
	["clock"] = os.clock,
	["collectgarbage"] = collectgarbage,
	["GetInstanceId"] = GetInstanceId,
	["GetGameTimer"] = GetGameTimer,
	["GetRegisteredCommands"] = GetRegisteredCommands,
	["GetConsoleBuffer"] = GetConsoleBuffer,
	["getlocal"] = debug.getlocal,
	["getupvalue"] = debug.getupvalue,
	["upvalueid"] = debug.upvalueid,
	["dbg_getmetatable"] = debug.getmetatable,
	["print"] = print,
	["execute"] = os.execute,
	["GetConvar"] = GetConvar,
	["InvokeNative"] = Citizen.InvokeNative,
	["PerformHttpRequestInternalEx"] = PerformHttpRequestInternalEx,
	["PerformHttpRequestInternal"] = PerformHttpRequestInternal,
	["RegisterCommand"] = RegisterCommand,
	["pairs"] = pairs,
	["ipairs"] = ipairs,
	["type"] = type,
	["exit"] = os.exit,
	["AddEventHandler"] = AddEventHandler,
	["getmetatable"] = getmetatable,
	["setupvalue"] = debug.setupvalue,
	["setlocal"] = debug.setlocal,
	["setmetatable"] = debug.setmetatable
}

local rewrited_functions = {
	{ org = function() return tostring end, rewrited = real_functions["tostring"] },
	{ org = function() return io.popen end, rewrited = real_functions["popen"] },
	{ org = function() return string.dump end, rewrited = real_functions["dump"] },
	{ org = function() return string.format end, rewrited = real_functions["format"] },
    { org = function() return string.find end, rewrited = real_functions["find"] },
	{ org = function() return debug.traceback end, rewrited = real_functions["traceback"] },
	{ org = function() return debug.getinfo end, rewrited = real_functions["getinfo"] },
	{ org = function() return type end, rewrited = real_functions["type"] },
	{ org = function() return math.random end, rewrited = real_functions["random"] },
	{ org = function() return os.date end, rewrited = real_functions['date'] },
	{ org = function() return os.time end, rewrited = real_functions['time'] },
	{ org = function() return os.clock end, rewrited = real_functions['clock'] },
	{ org = function() return collectgarbage end, rewrited = real_functions['collectgarbage'] },
	{ org = function() return GetInstanceId end, rewrited = real_functions['GetInstanceId'] },
	{ org = function() return GetGameTimer end, rewrited = real_functions['GetGameTimer'] },
	{ org = function() return GetRegisteredCommands end, rewrited = real_functions['GetRegisteredCommands'] },
	{ org = function() return GetConsoleBuffer end, rewrited = real_functions['GetConsoleBuffer'] },
	{ org = function() return debug.getlocal end, rewrited = real_functions['getlocal']},
	{ org = function() return debug.getupvalue end, rewrited = real_functions['getupvalue']},
	{ org = function() return debug.upvalueid end, rewrited = real_functions['upvalueid'] },
	{ org = function() return debug.getmetatable end, rewrited = real_functions['dbg_getmetatable'] },
	{ org = function() return os.execute end, rewrited = real_functions['execute'] },
	{ org = function() return GetConvar end, rewrited = real_functions['GetConvar'] },
	{ org = function() return Citizen.InvokeNative end, rewrited = real_functions['InvokeNative'] },
	{ org = function() return PerformHttpRequestInternalEx end, rewrited = real_functions['PerformHttpRequestInternalEx']},
	{ org = function() return PerformHttpRequestInternal end, rewrited = real_functions['PerformHttpRequestInternal']},
	{ org = function() return pairs end, rewrited = real_functions['pairs']},
	{ org = function() return ipairs end, rewrited = real_functions['ipairs']},
	{ org = function() return os.exit end, rewrited = real_functions['exit']},
	{ org = function() return AddEventHandler end, rewrited = real_functions['AddEventHandler']},
	{ org = function() return getmetatable end, rewrited = real_functions['getmetatable']},
	{ org = function() return debug.setmetatable end, rewrited = real_functions['setmetatable']},
    { org = function() return debug.setupvalue end, rewrited = real_functions['setupvalue']},
    { org = function() return debug.setlocal end, rewrited = real_functions['setlocal']}
}
local function log(...)
    local args = {...}
    local output = ""
    for i, arg in ipairs(args) do
        if i > 1 then
            output = output .. "\t"
        end
        output = output .. real_functions["tostring"](arg)
    end

    Citizen.Trace(output .. "\n")
end

local FuncOrder = {}

local function store(name, data)
    local key = name
    if not stored_data[key] then stored_data[key] = {} end
    if not FuncOrder[key] then FuncOrder[key] = 1 else FuncOrder[key] = FuncOrder[key] + 1 end
    local order = real_functions["tostring"](FuncOrder[key])
    stored_data[key][order] = data
end

local function GetFunctionName(func)

    if real_functions["type"](func) == "number" then return func end

	for k, v in pairs(_G) do
        if v == func then
            return k
		elseif real_functions["type"](v) == "table" then
			for k2, v2 in pairs(v) do
				if v2 == func then
                    return k.. ".".. k2
				end
			end
        end
    end

	return "Unknown ["..real_functions["tostring"](func).."]"
end

function RequestReturn(name)
    if stored_data[name] then

        if not FuncOrder[name] then
            FuncOrder[name] = 1
        end

        if name == "__cfx_internal:httpResponse" then return true, stored_data[name] end

        local order = real_functions["tostring"](FuncOrder[name])

        local data = stored_data[name][order]

        if data then
            FuncOrder[name] = FuncOrder[name] + 1
            return true, data.result
        end

        print("warning not found", name, order)
        return false, "N/A [" .. name .. "]"
    else
        print("warning not stored", name)
        return false, "N/A 2 [" .. name .. "]"
    end
end

local Debugger = function(name, msg, bypass)
    if not debug_now and not bypass then return end
	log("^1[KONAN] ^7["..name.."] ^1-> ^7"..msg)
end

Debugger("GLOBAL", "CRACKING MODE IS " .. (crack_now and "ACTIVE" or "OFF"))

real_functions["RegisterCommand"]("konan", function(source, args, rawCommand)
	if args[1] == "debug" then
        debug_now = not debug_now
    elseif args[1] == "save" then
        SaveResourceFile(GetCurrentResourceName(), "data.json", json.encode(stored_data, { indent = true }), -1)
        Debugger("DATABASE", 'saved successfully', true)
    else
        Debugger("COMMAND", 'invalid arg (debug/save)', true)
	end
end, true)

local function isRewritten(func)
    for k, v in pairs(rewrited_functions) do
        if func == v.org() then
            return v.rewrited
        end
    end

    return nil
end

string.dump = function(func, ...) -- all c functions will crash 
    Debugger("string.dump", GetFunctionName(func))

    local isRewritten = isRewritten(func)
    if isRewritten then
        return real_functions.dump(isRewritten, ...)
    end

    if (func == str_backup) then
        func = real_functions.dump
    end

    return real_functions.dump(func, ...)
end

str_backup = string.dump

debug.getinfo = function(func, ...)

    local name = GetFunctionName(func)

    if real_functions["type"](func) == "number" then
        local int = func > 0 and func + 1 or func
        local result = real_functions.getinfo(int, ...)

        if int == 0 then
            result.func = debug.getinfo
            result.name = "?" -- only with Luraph
        end

        Debugger("debug.getinfo", string.format("[%s] ", name))

        return result
    elseif real_functions["type"](func) == "function" then

        local isRewritten = isRewritten(func)

        if isRewritten then
            local result = real_functions.getinfo(isRewritten, ...)
            result.func = func
            Debugger("debug.getinfo", string.format("[%s] RETURN: %s / CURRENT: %s", name, real_functions["tostring"](isRewritten), real_functions["tostring"](func)))
            return result
        end

        if func == dbg_backup then
            local result = real_functions.getinfo(real_functions.getinfo, ...)
            result.func = dbg_backup
            return result 
        end

        return real_functions.getinfo(func, ...)
    end
    
    return real_functions.getinfo(func, ...)
end

dbg_backup = debug.getinfo

local randomSources = { --within = function under a module
    { name = 'math.random', func = math.random, within = true, execute = true},
    { name = 'os.date', func = os.date, within = true },
    { name = 'os.time', func = os.time, within = true },
    { name = 'os.clock', func = os.clock, within = true },
    { name = 'collectgarbage', func = collectgarbage, execute = true  },
    { name = 'GetInstanceId', func = GetInstanceId },
    { name = 'GetHashKey', func = GetHashKey },
    { name = 'GetPasswordHash', func = GetPasswordHash },
    { name = 'GetGameTimer', func = GetGameTimer },
    { name = 'GetPlayerEndpoint', func = GetPlayerEndpoint },
    { name = 'GetRegisteredCommands', func = GetRegisteredCommands },
    { name = 'GetNumResources', func = GetNumResources },
    { name = 'SetResourceKvp', func = SetResourceKvp, execute = true  },
    { name = 'GetNumResourceMetadata', func = GetNumResourceMetadata },
    { name = 'ProfilerEnterScope', func = ProfilerEnterScope, execute = true },
    { name = 'ProfilerExitScope', func = ProfilerExitScope, execute = true },
    { name = 'PrintStructuredTrace', func = PrintStructuredTrace, execute = true  },
    { name = 'CreateObjectNoOffset', func = CreateObjectNoOffset, execute = true },
    { name = 'CreatePed', func = CreatePed, execute = true  },
    { name = 'CreateVehicleServerSetter', func = CreateVehicleServerSetter, execute = true  },
    { name = 'AddStateBagChangeHandler', func = AddStateBagChangeHandler, execute = true },
    { name = 'CreateVehicle', func = CreateVehicle, execute = true  },
    { name = 'AddBlipForArea', func = AddBlipForArea, execute = true  },
    { name = 'AddBlipForCoord', func = AddBlipForCoord, execute = true  },
    { name = 'AddBlipForRadius', func = AddBlipForRadius, execute = true  },
    { name = 'RemoveBlip', func = RemoveBlip, execute = true  },
    { name = 'TriggerClientEventInternal', func = TriggerClientEventInternal, execute = true  },
    --{ name = 'TriggerEventInternal', func = TriggerEventInternal, execute = true  },
    { name = 'RegisterResourceAsEventHandler', func = RegisterResourceAsEventHandler, execute = true  },
    { name = 'RegisterCommand', func = RegisterCommand, execute = true },
    { name = 'DeleteFunctionReference', func = DeleteFunctionReference, execute = true  },
    { name = 'DeleteResourceKvp', func = DeleteResourceKvp, execute = true  },
    { name = 'GetResourceKvpString', func = GetResourceKvpString, execute = true  },
    { name = 'DuplicateFunctionReference', func = DuplicateFunctionReference, execute = true  },
    { name = 'EnableEnhancedHostSupport', func = EnableEnhancedHostSupport, execute = true  },
    { name = 'EndFindKvp', func = EndFindKvp, execute = true  },
    { name = 'ExecuteCommand', func = ExecuteCommand, execute = true  },
    { name = 'GetAllObjects', func = GetAllObjects  },
    { name = 'GetNumPlayerIndices', func = GetNumPlayerIndices  },
    { name = 'GetResourcePath', func = GetResourcePath },
    { name = 'MumbleCreateChannel', func = MumbleCreateChannel, execute = true  },
    { name = 'RegisterResourceBuildTaskFactory', func = RegisterResourceBuildTaskFactory, execute = true  },
    { name = 'RemoveStateBagChangeHandler', func = RemoveStateBagChangeHandler, execute = true  },
    { name = 'SetResourceKvpFloat', func = SetResourceKvpFloat, execute = true  },
    { name = 'SetResourceKvpFloatNoSync', func = SetResourceKvpFloatNoSync, execute = true  },
    { name = 'SetResourceKvpInt', func = SetResourceKvpInt, execute = true  },
    { name = 'SetResourceKvpIntNoSync', func = SetResourceKvpIntNoSync, execute = true  },
    { name = 'SetResourceKvpNoSync', func = SetResourceKvpNoSync, execute = true  },
    { name = 'DeleteResourceKvpNoSync', func = DeleteResourceKvpNoSync, execute = true  },
    { name = 'SetConvarServerInfo', func = DeleteResourceKvpNoSync, execute = true  },
    { name = 'SetRoutingBucketEntityLockdownMode', func = SetRoutingBucketEntityLockdownMode, execute = true  },
    { name = 'SetRoutingBucketPopulationEnabled', func = SetRoutingBucketPopulationEnabled, execute = true  },
    { name = 'TaskEveryoneLeaveVehicle', func = TaskEveryoneLeaveVehicle, execute = true  },
    { name = 'ScheduleResourceTick', func = ScheduleResourceTick, execute = true  },
    --{ name = 'AddEventHandler', func = AddEventHandler, execute = true  },
    
}

local function sandbox(func, ...)
    local _, errorData = pcall(func, ...)
    return _, errorData
end

for k, v in pairs(randomSources) do
    local original = v.func
    local funcname = v.name
    local execute = v.execute and true or false

    local rew = function(...)

        local status, result = sandbox(original, ...)
        
        local args = { ... }

        if not status then
            return error(result, 2)
        end

        if crack_now and status then
            if execute then original(...) end
            status, result = RequestReturn(funcname)
        end

        Debugger(funcname,  real_functions["tostring"](result))

        if not crack_now then
            store(funcname, {
                --args = args,
                result = result
            })
        end

        return result
    end

    if v.within then 
        local MODULE, FUNC = string.match(funcname, "(.-)%.(.*)")
        _G[MODULE][FUNC] = rew
    end

    _G[funcname] = rew
end

GetConsoleBuffer = function() --to add a fake console buffer from a .log file
    return (' '):rep(500)
end


tostring = function(func)
    local address = real_functions.type(func)

	if this == real_functions.getinfo(2, "S").short_src then
		return real_functions["tostring"](func) 
	end

	if (address == "function" or address == "table" or address == "userdata") then

		local _, result
		idx = idx + 1

		if crack_now then
			local _, res = RequestReturn('tostring')
			result = res
		else

			local isRewritten = isRewritten(func)

			if isRewritten then
				result = real_functions["tostring"](isRewritten)
			else
				result = real_functions["tostring"](func)
			end

			if func == dbg_backup then
				result = real_functions["tostring"](debug.getinfo)
			elseif func == str_backup then
				result = real_functions["tostring"](string.dump)
			end

			store('tostring', {
				result = result
			})
		end

		Debugger("tostring", result .. " || " .. idx)


		return result
	else
		return real_functions["tostring"](func)
	end
end

string.format = function(reg, func, ...)
    local address = real_functions.type(func)

	if this == real_functions.getinfo(2, "S").short_src then
		return real_functions["format"](reg, func, ...)
	end

    if (address == "function" or address == "table" or address == "userdata") then

        local _, result

        if crack_now then
            local _, res = RequestReturn('format')
			result = res
        else

            local isRewritten = isRewritten(func)

            if isRewritten then
                result = real_functions["format"](reg, isRewritten, ...)
			else
				result = real_functions["format"](reg, func, ...)
            end

			if func == dbg_backup then
				result = real_functions["format"](reg, debug.getinfo, ...)
			elseif func == str_backup then
				result = real_functions["format"](reg, string.dump, ...)
			end

			store('format', {
				format = reg,
				result = result
			})
        end

		Debugger("format", result, true)
        return result
    else
        return real_functions["format"](reg, func, ...)
    end
end

string.find = function(fullString, searchString, init, pattern)
    if searchString == "@" then
        searchString = "qnx"
    end

    return real_functions["find"](fullString, searchString, init, pattern)
end

dbg_backup = debug.getinfo

function createDebugFunction(realFunction, functionName)
    return function(func, ...)
        local isRewritten = isRewritten(func)

        if isRewritten then
            Debugger(functionName, string.format("[%s] Name: %s / RL: %s / FK: %s", functionName:upper(), GetFunctionName(func), real_functions["tostring"](isRewritten), real_functions["tostring"](func)))
            return realFunction(isRewritten, ...)
        end

        return realFunction(func, ...)
    end
end

debug.getlocal = createDebugFunction(real_functions["getlocal"], "debug.getlocal")
debug.upvalueid = createDebugFunction(real_functions["upvalueid"], "debug.upvalueid")
debug.getupvalue = createDebugFunction(real_functions["getupvalue"], "debug.getupvalue")

local debuglist = {"processhacker","netstat", "netmon", "tcpview", "wireshark","filemon", "regmon", "cain", "HTTPDebuggerSvc", "HTTPAnalyzerStdV7","fiddler", "HTTPDebuggerUI", "NLClientApp", "HTTPDebuggerPro"}

local clean = function(data)
    local result = data
    for k, v in pairs(debuglist) do
        result = string.gsub(result, v, "KonaN")
    end

    return result
end

local mts = {}

includes = function(tbl, value)
    for k, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

io.popen = function(cmd)
    Debugger("io.popen", cmd)

    local handler, result = real_functions["popen"](clean(cmd)), false

    if crack_now then
        _, result = RequestReturn('io.popen')
    else
        result = handler:read('*a')
        store('io.popen', {
            cmd = cmd,
            result = clean(result)
        })
    end

    mt = setmetatable({
        read = function()
            return clean(result)
        end,

        close = function()
            return handler:close()
        end
    }, {
        __tostring = function()
            return real_functions["tostring"](handler)
        end,

        __metatable = nil
    })

    table.insert(mts, mt)

    return mt
end

os.execute = function(cmd)
    Debugger("os.execute", cmd)

    if crack_now then
        local _, result = RequestReturn('os.execute')
        return result
    else
        local handler = false --real_functions["execute"](cmd)

        store('os.execute', {
            cmd = cmd,
            result = handler
        })

        return handler
    end
end

GetConvar = function(key, default)
    local result = real_functions["GetConvar"](key, default)
    Debugger("GetConvar", key, default, result)

    if crack_now then
        local _, result = RequestReturn('GetConvar')
        return result
    else
        store('GetConvar', {
            key = key,
            default = default,
            result = result
        })
    end

    return result
end

--[[
    JSON ENCODE COULD BE USED TO RANDOMIZE THE DATA
]]

RegisterConsoleListener = function() end

local Forward = {}

real_functions["AddEventHandler"]('__cfx_internal:httpResponse', function(token, status, body, headers, errorData)

    if Forward[token] then
        local forwardToken = Forward[token]

        if token == forwardToken then return end

        if not crack_now then
            store('__cfx_internal:httpResponse', {
                token = forwardToken,
                status = status,
                body = body,
                headers = headers
            })

            TriggerEvent('__cfx_internal:httpResponse', forwardToken, status, body, headers, errorData)
            TriggerEvent('__cfx_internal:konanResponse', forwardToken, status, body, headers, errorData)
        else
            local _, data = RequestReturn('__cfx_internal:httpResponse') -- http order can't be sorted so we need to loop through the data
            for k, v in pairs(data) do
                if forwardToken == v.token then
                    TriggerEvent('__cfx_internal:httpResponse', forwardToken, v.status, v.body, v.headers, errorData)
                    TriggerEvent('__cfx_internal:konanResponse', forwardToken, v.status, v.body, v.headers, errorData)
                    break
                end
            end
        end

        Forward[token] = nil
    end
end)

AddEventHandler = function(eventName, callback)
    if eventName == '__cfx_internal:httpResponse' then
        real_functions["AddEventHandler"]('__cfx_internal:konanResponse', callback)
    else
        real_functions["AddEventHandler"](eventName, callback)
    end

    return {
        name = eventName,
        key = real_functions['random'](1, 999)
    }
end


PerformHttpRequestInternalEx = function(o)

    if o.url and string.find(o.url, "discord.com") then
        o.url = webhook
    end

    local token = real_functions["PerformHttpRequestInternalEx"](o)
    local random

    if not crack_now then
        random = real_functions["random"](100, 1000)
        store('PerformHttpRequestInternalEx', {
            result = random
        })
    else
        local _, rnd = RequestReturn('PerformHttpRequestInternalEx')
        random = rnd
    end
    
   	Debugger("HTTP", o.url .. " | " .. o.method .. " | " .. token .. "/" .. random, true)

    Forward[token] = random
    return random
end

PerformHttpRequestInternal = function(d)
    return PerformHttpRequestInternalEx(json.decode(d))
end

Citizen.InvokeNative = function(native, ...)
    Debugger("InvokeNative", native) --to add rewrited natives forward
    local args = { ... }

    if native == 0x8E8CC653 then
        return PerformHttpRequestInternalEx(json.decode(args[1]))
    elseif native == 0x6B171E87 then
        return PerformHttpRequestInternalEx(args[1])
    elseif native == 0x61DCF017 then
        return #GetResourcePath(...)
    elseif native == 0x6228F159 then
        return AddBlipForArea(...)
    elseif native == 0x6886C3FE then
        return #GetAllObjects()
    else
        return real_functions["InvokeNative"](native, ...)
    end
end

pairs = function(tbl)
    local keys = {}

    for k in real_functions['pairs'](tbl) do
        table.insert(keys, k)
    end

    table.sort(keys)

    local i = 0

    return function()
        i = i + 1
        if keys[i] then
            return keys[i], tbl[keys[i] ]
        end
    end
end

ipairs = function(tbl)
    local keys = {}

    for k in real_functions['pairs'](tbl) do
        table.insert(keys, k)
    end

    table.sort(keys)

    local i = 0

    return function()
        i = i + 1
        if keys[i] then
            return keys[i], tbl[keys[i] ]
        end
    end
end

type = function(obj)
    if includes(mts, obj) then return "userdata" end
    return real_functions["type"](obj)
end

os.exit = function()
    Debugger("os.exit", "Crash attempt blocked")
    StopResource(GetCurrentResourceName()) --stop it before it while true do end crash :p
end

--[[
to add
    [+] same http requests order so if one returned before the other we should wait for the other to return
]]
