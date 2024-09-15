local skynet = require "skynet"
local channel = require "channel"


local function gettime()
    return math.tointeger(skynet.time() * 100)
end

local ctx = {}

local S
function ctx._init(S_)
    S = S_
    return S
end

-- log
function ctx.log(...)
    skynet.error(...)
end

function ctx.warn(...)
    skynet.error(...)
end

function ctx.error(...)
    skynet.error(...)
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

-- state
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

local state_cache = {}

function ctx.state(name)
    if not state_cache[name] then
        state_cache[name] = setmetatable({name = name}, state_mt)
    end
    return state_cache[name]
end

-- channel
function ctx.publish(ch_name, ...)
    channel.query(("%s.%s"):format(S._project, ch_name)).pub(...)
end


function ctx.module(name)
    -- todo
end

-- exit
function ctx.exit()
    skynet.send("state-mgr", "lua", "kill_state", S._project, S._name)
end


return ctx