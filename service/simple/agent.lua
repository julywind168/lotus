local skynet = require "skynet"
local pubsub = require "pubsub"

local S = {}


local command = {}

function command:register()
    local schema = assert(self.schema)
    skynet.send("state-mgr", "lua", "register", S._project, schema)
end

function command:init_state()
    skynet.send("state-mgr", "lua", "init_state", S._project, self.typename, self.name, self.value)
end

function command:execute_state()
    skynet.send("state-mgr", "lua", "execute_state", S._project, self.statename, self.funcname, self.params)
end

function S.client(msg)
    local name = msg.name
    local params = msg.params
    local f = command[name]
    f(params)
end


pubsub.sub("_init", function(project, name)
    S._id = ("%s.%s"):format(project, name)
    S._project = project
    S._name = name
    skynet.error(("[client: %s] started"):format(S._id))
end)


return S