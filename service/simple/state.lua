local skynet = require "skynet"
local channel = require "channel"

-- 0.01s (time/100 = os.time())
local function gettime()
    return math.tointeger(skynet.time() * 100)
end

local S = {
    timers = {},
    timer_thread_running = false
}

function S._find_timer(name)
    for name_, timer in pairs(S.timers) do
        if name_ == name then
            return timer
        end
    end
end

local ctx = {}

function ctx.log(...)
    skynet.error(...)
end

function ctx.warn(...)
    skynet.error(...)
end

function ctx.error(...)
    skynet.error(...)
end

function ctx.exit()
    skynet.send("state-mgr", "lua", "kill_state", S._project, S._name)
end

-- timer
function ctx.timeout(name, time, callback)
    S.timers[name] = {name = name, starttime = gettime(), delay = time, count = 0, callback = callback, once = true}
    S._start_timer_thread()
end

function ctx.interval(name, time, callback)
    S.timers[name] = {name = name, starttime = gettime(), delay = time, count = 0, callback = callback, once = false}
    S._start_timer_thread()
end

function ctx.querytimer(name)
    return S.timers[name]
end

function ctx.killtimer(name)
    S.timers[name] = nil
end

-- init a state
function ctx.initstate(typename, statename, value)
    skynet.send("state-mgr", "lua", "init_state", S._project, typename, statename, value)
    return ctx.state(statename)
end

function ctx.updatestate(statename, ...)
    local keys = {...}
    local value = table.remove(keys)
    assert(value)
    skynet.send("state-mgr", "lua", "update_state", S._project, statename, keys, value)
end

local state_mt = {
    __index = function (self, funcname)
        return function (...)
            skynet.send("state-mgr", "lua", "execute_state", S._project, self.name, funcname, {...})
        end
    end
}

-- get a state proxy
local state_cache = {}

function ctx.state(name)
    if not state_cache[name] then
        state_cache[name] = setmetatable({name = name}, state_mt)
    end
    return state_cache[name]
end

-- push a msg to channel
function ctx.publish(ch_name, ...)
    channel.query(("%s.%s"):format(S._project, ch_name)).pub(...)
end


local handlers = {}
local callbacks = {}

local function load_schema(schema)
    for name, code in pairs(schema.handlers or {}) do
        local f = load("return " .. code)
        if f then
            handlers[name] = f()
        else
            error(("load handler failed: %s"):format(name))
        end
    end
    for name, code in pairs(schema.callbacks or {}) do
        local f = load("return " .. code)
        if f then
            callbacks[name] = f()
        else
            error(("load callback failed: %s"):format(name))
        end
    end
end

function S.update(keys, value)
    if keys and #keys > 0 then
        local t = S._state
        local last_key = table.remove(keys)
        for _, key in ipairs(keys) do
            t = t[key]
        end
        t[last_key] = value
    else
        S._state = value
    end
end

function S.execute(funcname, params)
    local f = handlers[funcname]
    if f then
        f(ctx, S._state, table.unpack(params))
    else
        skynet.error(("unknown handler: %s"):format(funcname))
    end
end

function S.start(project, name, schema, value)
    S._project = project
    S._name = name
    S._schema = schema
    S._state = value or schema.init or {}
    load_schema(schema)
    skynet.error(("[state: %s.%s] started"):format(project, name))
    dump(S._state)
end

function S._tick()
    local now = gettime()
    for name, timer in pairs(S.timers) do
        local t = (now - timer.starttime) - timer.delay * timer.count
        if t >= 0 then
            local cb = callbacks[timer.callback]
            timer.count = timer.count + 1
            cb(ctx, S._state, timer)
            if timer.once then
                S.timers[name] = nil
            end
        end
    end
end

function S._start_timer_thread()
    if S.timer_thread_running == false then
        S.timer_thread_running = true
        skynet.fork(function()
            while true do
                skynet.sleep(10)
                S._tick()
            end
        end)
    end
end

function S.shutdown()
    skynet.exit()
end


return S