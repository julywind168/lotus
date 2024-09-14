-- lotus skynet client
local client = require "client.skynet.socketclient"

local lotus = {
    subscribers = {},
}

-- addr: "127.0.0.1:8000"
-- conf: {account = "test", password = "123456", name = "gate1"}
function lotus.connect(addr, conf)
    client.init(addr, conf, lotus.handle_socket_message)
end

function lotus.register(schema)
    assert(schema.typename)
    client.send{name = "register", params = {schema = schema}}
end

local state_mt = {
    __index = function (self, funcname)
        return function (...)
            client.send{name = "execute_state", params = {
                statename = self.name,
                funcname = funcname,
                params = {...}
            }}
        end
    end
}

-- init a state
function lotus.init(typename, statename, value)
    client.send{name = "init_state", params = {typename = typename, statename = statename, value = value}}
    -- pass
    return setmetatable({
        typename = typename,
        name = statename
    }, state_mt)
end

-- update a state
function lotus.update(state, ...)

end

local channel_cache = {}

function lotus.channel(ch_name)
    if not channel_cache[ch_name] then
        local ch = {}

        function ch.subscribe(callback)
            lotus.subscribers[ch_name] = callback
            client.send{name = "subscribe", params = {channel = ch_name}}
        end

        function ch.unsubscribe()
            lotus.subscribers[ch_name] = nil
            client.send{name = "unsubscribe", params = {channel = ch_name}}
        end

        function ch.publish(msg)
            client.send{name = "publish", params = {channel = ch_name, msg = msg}}
        end

        function ch.delete()
            client.send{name = "delete_channel", params = {channel = ch_name}}
        end

        channel_cache[ch_name] = ch
    end
    return channel_cache[ch_name]
end


local handle = {}

function handle:channel_message()
    local ch = self.channel
    local msg = self.msg
    local cb = lotus.subscribers[ch]
    if cb then
        cb(msg)
    else
        print("no subscriber for channel:", ch)
    end
end

function lotus.handle_socket_message(msg)
    local type = msg.type
    local f = handle[type]
    f(msg)
end


return lotus