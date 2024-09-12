local skynet = require "skynet"
local pubsub = require "pubsub"

local client_schema = {
    typename = "client",
    init = {},  -- optional
    handlers = {
        ping = [[
        function(ctx, client, ...)
            ctx.log("ping", ...)
        end
        ]]
    }
}

local S = {}

pubsub.sub_once("_init", function()
    local agent = skynet.newservice("simple", "agent", "game1", "gate1")
    skynet.send(agent, "lua", "client", {name = "register", params = { schema = client_schema }})
    skynet.send(agent, "lua", "client", {name = "init_state", params = {
        typename = "client",
        name = "client.1",
        value = { a = 1, b = 2 }
    }})
    skynet.send(agent, "lua", "client", {
        name = "execute_state", params = {
            statename = "client.1",
            funcname = "ping",
            params = {'A', 'B', 'C'}
        }
    })
end)



return S