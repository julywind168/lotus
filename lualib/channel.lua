local skynet = require "skynet"
local service = require "skynet.service"
local mc = require "skynet.multicast"


local service_addr
local M = {}
local cache = {}

local function create_channel(id)
    local subscriber = {}

    local subscribed = false
    local channel = mc.new {
        channel = id,
        dispatch = function (_, _source, ...)
            for uid, callback in pairs(subscriber) do
                callback(...)
            end
        end
    }

    local self = {}

    local uid = 0
    function self.sub(callback)
        if subscribed == false then
            channel:subscribe()
            subscribed = true
        end
        uid = uid + 1
        subscriber[uid] = callback

        return function ()
            subscriber[uid] = nil
            if next(subscriber) == nil then
                channel:unsubscribe()
                subscribed = false
            end
        end
    end

    function self.pub(...)
        channel:publish(...)
    end

    return self
end

function M.query(name)
    if not cache[name] then
        local id = skynet.call(service_addr, "lua", "query", name)
        cache[name] = create_channel(id)
    end
    return cache[name]
end

function M.delete(name)
    skynet.call(service_addr, "lua", "delete", name)
end

skynet.init(function ()
    local function channel_mgr_service()
        local skynet = require "skynet"
        local mc = require "skynet.multicast"

        local channels = {}
        local command = {}

        function command.query(name)
            if not channels[name] then
                channels[name] = mc.new()
            end
            return channels[name].channel
        end

        function command.delete(name)
            local c = channels[name]
            if c then
                c:delete()
            end
        end

        skynet.start(function()
            skynet.dispatch("lua", function(session, source, cmd, ...)
                local f = command[cmd]
                skynet.ret(skynet.pack(f(...)))
            end)
        end)
    end

    service_addr = service.new("channel-mgr-service", channel_mgr_service)
end)


return M