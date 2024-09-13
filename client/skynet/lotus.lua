-- lotus skynet client
local lotus = {}
local client = require "client.skynet.socketclient"

-- addr: "127.0.0.1:8000"
-- conf: {account = "test", password = "123456", name = "gate1"}
function lotus.connect(addr, conf)
    client.init(addr, conf)
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


return lotus