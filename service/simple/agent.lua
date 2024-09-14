local skynet = require "skynet"
local pubsub = require "pubsub"
local channel = require "channel"

local S = {}


local command = {}

function command:register()
    local schema = assert(self.schema)
    skynet.send("state-mgr", "lua", "register", S._project, schema)
end

function command:init_state()
    skynet.send("state-mgr", "lua", "init_state", S._project, self.typename, self.statename, self.value)
end

function command:execute_state()
    skynet.send("state-mgr", "lua", "execute_state", S._project, self.statename, self.funcname, self.params)
end

local subscribed = {}

-- channel-subscribe
function command:subscribe()
    local name = ("%s.%s"):format(S._project, self.channel)
    if not subscribed[name] then
        subscribed[name] =
        channel.query(name).sub(function (...)
            S.send2client{
                type = "channel_message",
                channel = self.channel,
                msg = {...}
            }
        end)
    end
end

function command:unsubscribe()
    local name = ("%s.%s"):format(S._project, self.channel)
    if subscribed[name] then
        subscribed[name]() -- unsub()
        subscribed[name] = nil
    end
end

function command:publish()
    channel.query(("%s.%s"):format(S._project, self.channel)).pub(self.msg)
end

function command:delete_channel()
    channel.delete(("%s.%s"):format(S._project, self.channel))
end


function S.send2client(msg)
    skynet.send("gateway", "lua", "send2client", S._id, msg)
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